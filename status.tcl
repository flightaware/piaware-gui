package require fa_sysinfo
package require piaware

#
# configure_statics - configure static values that don't change.
#
proc configure_statics {} {
	set ::ethernetmac [::fa_sysinfo::mac_address]
	set ::wlandev [::fa_sysinfo::wireless_interface]
}

#
# Set the field from piaware-config.txt into the interface
#   Call this everytime a change to the config file is made
#   Piaware config settings can be accessed using [piawareConfig get name]
#   PiAware config settings can be updated with [piawareConfig option name value]
proc load_piaware_config {} {
	change_network_status
}


# Set the network fields from piaware-config.txt into the interface
#
proc change_network_status {} {
	set ::wiredenable [piawareConfig get wired-network]
	set ::wirelessenable [piawareConfig get wireless-network]

	#Set wired status
	if {[piawareConfig get wired-network]} {
		if {[piawareConfig get wired-type] == "dhcp"} {
			set ::staticipaddress ""
			set ::staticnetmask ""
			set ::staticbroadcast ""
			set ::staticgateway ""
		} elseif {[piawareConfig get wired-type] == "static"} {
			set ::staticipaddress [piawareConfig get wired-address]
			set ::staticnetmask [piawareConfig get wired-netmask]
			set ::staticbroadcast [piawareConfig get wired-broadcast]
			set ::staticgateway [piawareConfig get wired-gateway]
		} else {
			log "Invalid settings in piaware-config.txt for wired-type. Must be dhcp or static."
		}
	} else {

	}

	if {[piawareConfig exists wireless-ssid]} {
		set ::wifissid [piawareConfig get wireless-ssid]
	} else {
		set ::wifissid "    "
	}

	if {[piawareConfig exists wireless-password]} {
		set ::wifipassword "password set"
	} else {
		set ::wifipassword "password not set"
	}
}

proc change_to_dhcp {} {
        toggle networkstatic 0

}

proc change_to_static {} {
        toggle networkdhcp 0

}

#
# update_ethernet_status - get the ethernet link status, speed, IP and
#   default gateway and setindicators accordingly.
#
proc update_network_status {} {
	set ethernetState [::fa_sysinfo::interface_state eth0]
	set wifiState [::fa_sysinfo::interface_state $::wlandev]
	set ::ipaddress [::fa_sysinfo::interface_ip_address eth0]
	set ::wifiaddress [::fa_sysinfo::interface_ip_address $::wlandev]
	set ::ethernetspeed [::fa_sysinfo::interface_speed eth0]
	set ::wifispeed [::fa_sysinfo::interface_speed $::wlandev]

	#Set the icons on the Network screen (wired, builtin_wireless, usb_wireless) and the network on the device status screen
	#ethernetState is up if a cable is connected ethernet port. This doesn't mean there is an IP
	if {$::ipaddress != ""} {
		set_status_icon wired green
		set ::ethernetstatus "Ethernet Connected"
	} else {
		if {[piawareConfig get wired-network]} {
			if {$ethernetState == "up"} {
				set_status_icon wired yellow
				set ::ethernetstatus "Cable connected no IP"
			} else {
				set_status_icon wired yellow
				set ::ethernetstatus "On but not connected"
			}
		} else {
			set_status_icon wired red
			set ::ethernetstatus "Ethernet Off"
		}
	}
	if {$wifiState == "up" ? 1 : 0}  {
		if {[piawareConfig get rfkill]} {
			set_status_icon usb_wireless green
			set ::wifistatus "USB Wifi Connected"
		} else {
			set_status_icon builtin_wireless green
			set ::wifistatus "Wifi Connected"
		}
	} else {
		set_status_icon builtin_wireless red
		set_status_icon usb_wireless red
		if {[piawareConfig get wireless-network]} {
			set ::wifistatus "On but not connected"
		} else {
			set ::wifistatus "Wifi OFF"
		}
	}

	#Update the ip address on the wired and wireless screens
	#If wired IP address is blank set it to the wireless IP address
	if {$::ipaddress != ""} {
		set ::ipaddress_mainmenu "$::ipaddressText $::ipaddress"
	} else {
		set ::ipaddress_mainmenu "$::ipaddressText $::wifiaddress"
	}

	#Update the network icon on the main screen
	if {$ethernetState == "up" && $::ipaddress != "" ||  $wifiState == "up" && $::wifiaddress != ""} {
		set_status_icon_style mainmenu_network green
	} else {
		set ::urlhint ""
		set_status_icon_style mainmenu_network red
	}

	#Update the map link
	::fa_sysinfo::route_to_flightaware ::defaultgateway iface ip
	if {$::defaultgateway ne ""} {
		set ::dhcpnetmask [::fa_sysinfo::interface_netmask $iface]

		if {[status radio] == "statusGreenIcon"} {
			grid .bottom.4
			set ::urlhint "To see a map of aircraft positions, go to this link in a web browser: http://$ip/dump1090-fa"
		} elseif {[status uat_radio] == "statusGreenIcon"} {
			grid .bottom.4
			set ::urlhint "To see a map of aircraft positions, go to this link in a web browser: http://$ip/skyaware978"
		} else {
			set ::urlhint ""
			grid remove .bottom.4
		}
	} else {
		set ::dhcpnetmask ""
		set ::urlhint ""
		grid remove .bottom.4
	}
}

#
# periodically_update_ethernet_status - check to see if the Ethernet is
#   up or down, etc, every few seconds
#
proc periodically_update_network_status {} {
	after 15000 periodically_update_network_status

	update_network_status
	set temp [::fa_sysinfo::cpu_temperature]
	if {$temp ne ""} {
		set ::cputemperature [format "%.1fC / %.1fF" $temp [expr {$temp * 1.8 + 32}]]
	} else {
		set ::cputemperature "unknown"
	}
	set load [::fa_sysinfo::cpu_load]
	if {$load ne ""} {
		set ::cpuload "$load%"
	} else {
		set ::cpuload "unknown"
	}
}

proc total_tx_bytes {} {
	return [expr {[::fa_sysinfo::interface_tx_bytes eth0] + [::fa_sysinfo::interface_tx_bytes $::wlandev]}]
}

proc total_rx_bytes {} {
	return [expr {[::fa_sysinfo::interface_rx_bytes eth0] + [::fa_sysinfo::interface_rx_bytes $::wlandev]}]
}

#
# init_transfer_statistics - initialize Ethernet transfer statistics
#
proc init_transfer_statistics {} {
	set ::txbytes [total_tx_bytes]
	set ::rxbytes [total_rx_bytes]
}

#
# update_transfer_statistics - update Ethernet trasfer statistics
#
proc update_transfer_statistics {} {
	set priorBytesSent $::txbytes
	set ::txbytes [total_tx_bytes]
	set ::bytessent [comma $::txbytes]

	set ::txkbsec [format "%.1f" [expr {($::txbytes - $priorBytesSent) * 8 / (5 * 1000.0)}]]

	set priorBytesReceived $::rxbytes
	set ::rxbytes [total_rx_bytes]
	set ::bytesreceived [comma $::rxbytes]

	set ::rxkbsec [format "%.1f" [expr {($::rxbytes - $priorBytesReceived) * 8 / (5 * 1000.0)}]]
}

#
# periodically_update_transfer_statistics - update Ethernet transfer stats
#   every few seconds
#
proc periodically_update_transfer_statistics {} {
        after 5000 periodically_update_transfer_statistics

        update_transfer_statistics
}

#
# Read PiAware status from Json file and update the status
#
proc periodically_update_piaware_status {} {
	try {
		set interval [update_piaware_status]
	} on error {result} {
		puts stderr "Caught '$result' reading piaware status file"
		set interval 5000

		set value [dict create "status" "red" "message" "Couldn't read status file"]
		set ::piawareStatus $value
		set_status_indicator piaware $value
		set_status_indicator mlat $value
		set_status_indicator flightaware $value
		set_status_indicator network $value
		set_status_indicator gps $value
		set_status_indicator radio $value
	} finally {
		after $interval periodically_update_piaware_status
	}
}

proc update_piaware_status {} {
	set jsondict [read_json "/run/piaware/status.json"]

	#Check if valid time has expired
	if {[expr {[dict get $jsondict expiry] < [clock milliseconds]}]} {
		error "status file is out of date"
	}

	foreach {name value} $jsondict {
		switch $name {
			piaware {
				set ::piawareStatus $value
				set_status_indicator piaware $value
			}
			mlat {
				set_status_indicator mlat $value
			}
			adept {
				set_status_indicator flightaware $value
			}
			gps {
				set_status_indicator gps $value
			}
			radio {
				set_status_indicator radio $value
			}
			uat_radio {
				set_status_indicator uat_radio $value
			}
			no_radio {
				set_status_indicator no_radio $value
			}
		}
	}

	# Determine what radio indicator is active; default to 1090
	if {[info exists ::indicator_path(uat_radio)]} {
		set active_radio uat_radio
	} else {
		set active_radio radio
	}

	# Set the status indicator on the main menu depending on the Device status indicators
	# if any are red, set main menu Status to red
	# if all are green, set main menu Status to green
	# else set main menu Status to yellow
        if {[status flightaware] == "statusRedIcon" || [status $active_radio] == "statusRedIcon"} {
		set_status_icon_style mainmenu_status red
	} elseif {[status flightaware] == "statusGreenIcon" && [status $active_radio] == "statusGreenIcon"} {
		set_status_icon_style mainmenu_status green
	} else {
		set_status_icon_style mainmenu_status yellow
	}

	return [dict get $jsondict interval]
}

# Take a json status message and sets the indicator
proc set_status_indicator {indicator json} {
	set status [dict get $json status]
	set message [dict get $json message]

	switch $status {
		red - amber - green {
			set_status_icon $indicator $status
		}

		default {
			set_status_icon $indicator red
		}
	}

	if {[info exists ::indicator_path($indicator)]} {
		append indicatortext $::indicator_path($indicator) text
		$indicatortext configure -text $message
	}
}

# Sets the icon for the status indicator (green, yellow, red)
proc set_status_icon {indicator icon} {

	switch $icon {
		green {
			set icon statusGreenIcon
		}
		yellow - amber {
			set icon statusYellowIcon
		}
		red {
			set icon statusRedIcon
		}
		default {
			set icon $icon
		}
	}

	set ::indicators($indicator) $icon
	if {[info exists ::indicator_path($indicator)]} {
		$::indicator_path($indicator) configure -image $icon
	}
}

#set the icon inside of a style indicator
proc set_status_icon_style {indicator icon} {

	switch $icon {
		green {
			set style mainMenuGreen.TButton
		}
		yellow - amber {
			set style mainMenuYellow.TButton
		}
		red {
			set style mainMenuRed.TButton
		}
		default {
			set style mainMenuRed.TButton
		}
	}

	set ::indicators($indicator) $icon
	if {[info exists ::indicator_path($indicator)]} {
		$::indicator_path($indicator) configure -style $style
	}
}

#
# status - update one of the status indicators by name,
# possible states are green (up) / amber (possible problem) / red (down)
#
# if state isn't specified, returns the current status
#
proc status {item {state ""}} {
	# if they asked only for the status without specifying the state to set
	# it to, return the status and if there isn't a status yet, return red
	if {$state == ""} {
		if {[info exists ::indicators($item)]} {
			return $::indicators($item)
		}

		return "red"
	}

	# configure the indicator color accordingly
	# and normalize the state
	switch $state {
		green - 1 {
			set state green
			set color green3
			set icon statusGreenIcon
		}
		amber {
			set state amber
			set color gold2
			set icon statusYellowIcon
		}
		red - 0 {
			set state red
			set color red
			set icon statusRedIcon
		}
		default {
			error "unknown status indicator state: $state"
		}
	}

	# update indicator array with item state
	set ::indicators($item) $state

	if {[info exists ::indicator_path($item)]} {
		$::indicator_path($item) configure -image $icon
	}
}

proc toggle {item toggle} {
	#disable or enable indicator
	if {$toggle} {
		$::indicator_path($item).$item configure -state normal
		$::indicator_path($item).$item configure -background blue
	} else {
		$::indicator_path($item).$item configure -state disabled
		$::indicator_path($item).$item configure -background grey
	}
}


# Open a Message Box with the set indicator message
#  If no message is set use a default message
proc create_indicator_messagebox {indicator} {
	if {![info exist ::indicators($indicator)]} {
		if {$::piawareStatus == "red"} {
			tk_messageBox -type ok -message "PiAware is not active. Check System logs for more information."
			return
		}
		tk_messageBox -type ok -message "Indicator not active."
		return
	}

	if {![info exist ::indicator_message($indicator)]} {
		tk_messageBox -type ok -message "No status message set. Please try again later."
		return
	}
	tk_messageBox -type ok -message "$::indicator_message($indicator)"
}

#
# load_logo - create a photo object image of the FA logo and put it on the
#   display
#
proc load_logo {} {
    namespace eval ::images {}
        image create photo ::images::logo -file FA_logo_CMYK_with_tag_360.gif
        label .f.logo.logo -image ::images::logo
        pack .f.logo.logo -side left
}
#
# setup_tod - setup a time of day field
#
proc setup_tod {w} {
        label $w.tod -textvariable tod -font LabelFont -relief sunken -width 10
        pack $w.tod -side right
        label $w.todlabel -text "time" -font LabelFont -foreground grey -width 6
        pack $w.todlabel -side right

        periodically_update_time
}

#
# periodically_update_time - once a minute update the displayed time
#
proc periodically_update_time {} {
        set clock [clock seconds]
        after [expr {60000 - ($clock % 60) * 1000}] periodically_update_time
        set ::tod [clock format $clock -format "%H:%M %Z"]

        update_uptime
}

proc setup_uptime {w} {
        label $w.uptime -textvariable uptime -font LabelFont -relief sunken -width 16
        pack $w.uptime -side right
        label $w.uptimelabel -text "up" -font LabelFont -foreground grey -width 6
        pack $w.uptimelabel -side right
}

proc update_uptime {} {
        set uptime [::fa_sysinfo::uptime]
        set uptime_minutes [expr {$uptime / 60}]
        set minutes [expr {$uptime_minutes % 60}]
        set uptime_hours [expr {$uptime_minutes / 60}]
        set hours [expr {$uptime_hours % 24}]
        set days [expr {$uptime_hours / 24}]

        set uptimeString ""
        if {$days > 0} {
                if {$days == 1} {
                        append uptimeString "1 day, "
                } else {
                        append uptimeString "$days days, "
                }
        }

        append uptimeString [format "%d:%02d" $hours $minutes]
        set ::uptime $uptimeString
}

# Parse each line of netstat for ports we care about
proc process_netstat_line {line} {
	lassign $line proto recvq sendq localAddress foreignAddress state pidProg
	set port [lindex [split $foreignAddress :] 1]

	if {$pidProg eq "-"} {
		set pid "unknown"
		set prog "unknown progress"
	} else {
		lassign [split $pidProg "/"] pid prog
	}

	switch -glob $prog {
		"piaware" {
			if {[string match "*:1200" $foreignAddress] && $state == "ESTABLISHED"} {
				set ::tcp_port_status green
			}
		}
	}
}
