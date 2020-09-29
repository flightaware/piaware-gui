#
# read_radio_stats - returns the parsed radio json output
#  options are rate or total
#
proc read_radio_stats {{value "message"}} {
	set jsonLog "/run/dump1090-fa/stats.json"
	try {
		set jsondict [read_json $jsonLog]

		switch $value {
			rate {
				set last1min [dict get $jsondict last1min messages]
				set last5min [dict get $jsondict last5min messages]
				set total [dict get $jsondict total messages]
				set out "In the Last 1 min you received: $last1min messages\n"
				append out "In the Last 5 min you received: $last5min messages\n"
				append out "In total you received: $total messages"
				return $out
			}
			message {
				set timeframe [list last1min last5min last15min total]
				set out ""
				foreach period $timeframe {
					switch $period {
						last1min { append out "Last minute:\n"}
						last5min { append out "Last 5 minutes:\n"}
						last15min { append out "Last 15 minutes:\n"}
						total { append out "Total:\n"}
					}
					foreach {key value} [dict get $jsondict $period local] {
						switch $key {
							accepted {
								append out "  Messages [lindex $value 0]\n"
								append out "  Messages (passed CRC)  [lindex $value 1]\n"
							}
							signal {
								append out "  Signal level $value\n"
							}
							strong_signals {
								append out "  Signal Clipped count (overloaded) $value\n"
							}
						}
					}
				}
				return $out
			}
		}
	} on error {result} {
		return "Radio stats not available."
	}
}


#
#
#
::itcl::class MessageCount {
	public variable callback puts
	public variable interval_length 3
	public variable ip localhost
	public variable port 30003
	public variable closeAfterId 0

	private variable fp
	private variable last_interval 0
	private variable total 0
	private variable life_total 0
	private variable life_start [clock milliseconds]

	constructor {args} {
		eval configure $args
	}

	method start {} {
		catch {
			set fp [socket $ip $port]
			fconfigure $fp -buffering line
			fileevent $fp readable [list $this read_channel $fp]
		}
	}

	method read_channel {chan} {
		if {[catch {gets $chan line}]} {
			return
		}
		set time [clock seconds]
		set time_ms [clock milliseconds]
		if {$time_ms > $last_interval + [expr $interval_length * 1000]} {
				if {$last_interval > 0} {
					lassign [stats $time_ms $last_interval $total] stats_rate
					$callback "$stats_rate/sec"
				}
				set total 0
				set last_interval $time_ms
			}
			incr total
	}

	method stop {} {
		after cancel $closeAfterId
		catch {close $fp}
	}

	proc stats {stop start count} {
		set interval [expr {($stop - $start)/1000}]
		set rate [format %.2f [expr $count / ${interval}.0]]

		lappend ::history $rate
		incr ::life_total $count

		return [list $rate $interval]
	}
}
# vim: set ts=4 sw=4 sts=4 noet :
