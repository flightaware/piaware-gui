#
# FlightAware FileTailer - Itcl class for tailing files in an event loop-aware
#  manner
#

package require Tclx
package require Itcl

::itcl::class FileTailer {
    public variable callback puts
	public variable look_interval_ms 1000

    protected variable tailfp
    protected variable tailfile
    protected variable lastActionClock
    protected variable tailLink ""
    protected variable inode
    protected variable size
    protected variable iteration 0
    protected variable seekBack 2048
    protected variable firstPass 1
	protected variable afterID

    constructor {args} {
        eval configure $args

		must_have_set callback
    }

    #
    # must_have_set - the specified variables must have been set
    #
    method must_have_set {args} {
		foreach var $args {
			if {![info exists $var]} {
				error "you must specify -$var when creating this object type"
			}
		}
    }

    method debug {text} {
        puts "$this: debug: $text"
    }

    #
    # follow_file - open a file to be tailed, file handle will be tailfp
    # and we will fconfigure the file nonblocking
    #
    method follow_file {file args} {
		configure {*}$args
	
		if {[info exists tailfp]} {
			close $tailfp
		}

		#debug "open_tail_file: $file"
		set tailfp [open $file r]
		fconfigure $tailfp -blocking 0 -encoding binary -buffering line
		set tailfile $file

		set statlist [fstat $tailfp]
		set inode [keylget statlist ino]
		set size [keylget statlist size]

		# if it's the first pass, seek back a bit
		if {$firstPass} {
			set seekWhere [expr {$size - $seekBack}]
			if {$seekWhere < 0} {
				set seekWhere 0
			}
			seek $tailfp $seekWhere
			gets $tailfp
		}

		set firstPass 0
		follow_file_async
    }


    method follow_file_async {} {
		set newWhere [tell $tailfp]
		set statlist [fstat $tailfp]
		set mySize [keylget statlist size]

		# if the size shrank, the file was truncated
		if {$mySize < $size} {
			# file was truncated
			puts stderr "$this file shrank, new size $mySize, seeking to 0"
			set size $mySize
			seek $tailfp 0
			set newWhere 0
		}
		set size $mySize


		# periodically see if the inode has changed out from underneath us
		incr iteration
		if {$iteration % 5 == 0} {
			file stat $tailfile fileStat
			if {$fileStat(ino) != $inode} {
				# inode changed
				puts stderr "$this inode changed from $inode to $fileStat(ino), reopening $tailfile and seeking to 0"
				follow_file $tailfile
				return
			}
		}

		# if we're at end of file, look again in a second
		if {$newWhere == $mySize} {
			set afterID [after $look_interval_ms [list $this follow_file_async]]
			return
		}

		#
		# while there's unread data in the file, read some and invoke the
		# callback.  
		# invoke update periodically to keep the event loop alive.
		#
		while {[gets $tailfp line] >= 0} {
			# invoke "update" to keep the event loop alive
			$callback $line
			update
			set lastActionClock [clock seconds]
		}

		# no data, look again in a second
		set afterID [after $look_interval_ms [list $this follow_file_async]]
    }

	method close_file {} {
		after cancel $afterID
		close $tailfp
	}
}

# vim: set ts=4 sw=4 sts=4 noet :
