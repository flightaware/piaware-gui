#
#
#

package require fa_sudo
package require fa_services

#
# detect_mode - detect whether FF in 1090 or 978 mode and
# sets global variables to allow the syste to determine
# whether to show 1090 or 978 GUI elements
#
proc detect_mode {} {
	piawareConfig read_config

	if {[piawareConfig get uat-receiver-type] ne "none"} {
		set ::receiver_mode uat
		set ::gain_option uat-sdr-gain
	} else {
		set ::receiver_mode adsb
		set ::gain_option rtlsdr-gain
	}
}

#
# create_topframe - create a topframe and make it full screen
#
proc create_topframe {name} {
	toplevel $name -cursor $::cursorStyle
	fullscreen $name
}

proc scaleImage {im xfactor {yfactor 0}} {

	set newwidth [expr int($xfactor * [image width $im])]
	if {$yfactor == 0} {
		set newheight [expr int($xfactor * [image height $im])]
	} else {
		set newheight [expr int($yfactor * [image height $im])]
	}

	set mode -subsample
	if {abs($xfactor) < 1} {
		set xfactor [expr round(1./$xfactor)]
	} elseif {$xfactor>=0 && $yfactor>=0} {
		set mode -zoom
	}

	if {$yfactor == 0} {set yfactor $xfactor}
	set t [image create photo]
	$t copy $im
	$im blank
	$im configure -width $newwidth -height $newheight
	$im copy $t -shrink $mode $xfactor $yfactor
	image delete $t
}

proc create_newmenu {currentFrame currentName back closeall} {
	set f $currentFrame
	create_topframe $f

	#grid the top with widgets
	if {$back == "none"} {
		#This is a blank label to replace the back button
		grid [label $f.back -bg $::MenuBackground -highlightthickness 0 -bd 0 ] -row 0 -column 0 -sticky snew
	} else {
		grid [ttk::button $f.back -image backIcon -command "$back" -style FAdark.TButton] -row 0 -column 0 -sticky snew
	}
	grid [label $f.label -text $currentName -font MenuTopLabel -anchor center -bg $::MenuBackground -fg white] -row 0 -column 1 -sticky snew
	grid [ttk::button $f.close -image closeIcon -command "$closeall" -style FAdark.TButton] -row 0 -column 2 -sticky snew

	#Allow the menu to expand to full width
	grid columnconfigure $f 1 -weight 1

}

proc create_newmenu_options {frame menuList} {
	set b $frame

	pack [ttk::separator $b.seperatorA -orient horizontal] -expand 1 -fill x
	foreach {menuName menuText} $menuList {
		button $b.$menuName -text $menuText -font MenuLabel -relief flat -overrelief flat -anchor w -borderwidth 0 -highlightthickness 0 -padx 20 -pady 8 \
							-foreground $::MenuBackground -activebackground orange -background white \
							-command "button_$menuName"
		pack $b.$menuName -expand 1 -fill x
		set sep [ttk::separator $b.seperator"$menuName" -orient horizontal]
		pack $sep -expand 1 -fill x
	}
}

proc create_textbox {frame} {
	#need to create a subframe to be able to set the size of the scrollbar
	set f $frame.sub
	grid [frame $f] -columnspan 3 
	grid rowconfigure $frame 0 -weight 0
	grid rowconfigure $frame 1 -weight 1
	grid rowconfigure $frame 2 -weight 0

	text $f.t -font TextFont -borderwidth 0 -cursor $::cursorStyle -fg $::FADarkBlue -spacing1 1 -spacing3 1
	scrollbar $f.sby -orient vert -cursor $::cursorStyle -width 25 -troughcolor $::FALightBlue
	$f.t conf -yscrollcommand "$f.sby set"
	$f.sby conf -command "$f.t yview"

	pack $f.sby -side right -fill y
	pack $f.t -side top -fill both
}

##################################
# Button procs for System commands
##################################

proc periodically_update_systemstatus {} {
	if {![winfo exist .systemstatus]} {
		return
	}

	set swversion [exec -ignorestderr dpkg-query --show --showformat {${Version}} piaware-release]
	set mac $::ethernetmac

	catch {
		set jsondict [read_json "/run/piaware/status.json"]
		if {[dict exists $jsondict unclaimed_feeder_id]} {
			set unclaimed_feeder_id [dict get $jsondict unclaimed_feeder_id]
		}
	}

	catch {
		set f [open "/var/cache/piaware/feeder_id" r]
		try {
			set feeder_id [read $f]
		} finally {
			catch {close $f}
		}
	}

	if {[info exists unclaimed_feeder_id]} {
                set feeder_id_text "UNCLAIMED \nTo associate this receiver with your FlightAware account, visit https://flightaware.com/adsb/piaware/claim/$unclaimed_feeder_id or enter the receiver's IP address in a web browser and follow the claim instructions.\n"
	} elseif {[info exists feeder_id]} {
		set feeder_id_text $feeder_id
	} else {
		set feeder_id_text "N/A"
	}

	set data "PiAware Version ${swversion}\n"
	append data "MAC address: $mac\n\n"

	append data "Feeder ID: $feeder_id_text\n"
	append data "System Status: \n"
	append data "Local time: $::tod\nUp time: $::uptime\n\n"
	append data "OS name: [exec -ignorestderr grep PRETTY_NAME /etc/os-release | cut -d "=" -f2]\n"
	append data "CPU temperature: $::cputemperature\n\n"
	append data "Transfer Status:\n"
	append data "Bytes sent: $::bytessent \n  outgoing data rate $::txkbsec kbits/sec \n"
	append data "Bytes received: $::bytesreceived \n  incoming data rate $::rxkbsec kbits/sec \n"

	.systemstatus.sub.t configure -state normal
	.systemstatus.sub.t delete 0.0 end
	.systemstatus.sub.t insert end $data
	.systemstatus.sub.t configure -state disable

	after 2000 periodically_update_systemstatus
}

proc periodically_update_radiostatus {} {
	if { ![winfo exist .radiostatus] } {
		return
	}

	set t .radiostatus.sub.t
	$t configure -state normal
    $t delete 0.0 end
	set data "Radio Status \n"
	append data [read_radio_stats message]
	$t insert end $data
	$t configure -state disable

	after 5000 periodically_update_radiostatus
}

proc button_radio {} {
	create_newmenu .radio "Radio" "destroy .radio" "destroy .radio"
	grid [frame .radio.bottom] -columnspan 3 -sticky news

	if {"beastgps" in $::hardware} {
		set menuList {radiostatus "Radio Status"}
	} elseif {$::receiver_mode eq "uat"} {
		# Radio stats not available in UAT mode currently. TODO: generate stats.json in dump978
		set menuList {radiogain "Radio Gain"}
	} else {
		set menuList {radiostatus "Radio Status" radiogain "Radio Gain"}
	}
	create_newmenu_options .radio.bottom $menuList
}

proc button_radiostatus {} {
	create_newmenu .radiostatus "Radio Status" "destroy .radiostatus" "destroy .radiostatus"

	create_textbox .radiostatus

	periodically_update_radiostatus
}

proc button_radiogain {} {
	create_newmenu .radiogain "Radio Gain" "button_close_gain" "button_close_gain"

	set b .radiogain.bottom
	grid [frame $b] -columnspan 3

	set wraplength [expr ([winfo screenwidth $b] * .95)]
	label $b.t -font TextFont -justify left -wraplength $wraplength
	grid $b.t -columnspan 2 -sticky w

	label $b.rate -textvariable messageRate -font TextFont -justify left -cursor $::cursorStyle
	grid $b.rate -columnspan 2 -sticky w

	radiobutton $b.maxgain -text "Use Max Gain" -variable gainType -value "max" -justify left -indicatoron 0 -offrelief flat -offrelief flat \
							-font StatusFont -compound left -image radioOffIcon -justify left -command "select_gain_type"
	grid $b.maxgain -columnspan 2 -sticky w
	radiobutton $b.manualgain -text "Set Radio Gain" -variable gainType -value "manual" -indicatoron 0 -offrelief flat -offrelief flat \
							-font StatusFont -compound left -image radioOnIcon -justify left -command "select_gain_type"
	scale $b.slider -orient horizontal -from 0 -to 50 -tickinterval 0
	grid $b.manualgain $b.slider -sticky w

	ttk::button $b.accept -text "Accept" -style FA.TButton -command "button_accept_gain"
	grid $b.accept -columnspan 2 -sticky w

	if { [catch {set gain [piawareConfig get $::gain_option]}] } {
		set gain max
		$b.maxgain select
	}

	if {$gain == "max"} {
		$b.maxgain select
		$b.slider set 50
		set ::rtl_gain "Max Gain. \n Turn off Max Gain to use lower values. "
	} else {
		$b.manualgain select
		$b.slider set $gain
		set ::rtl_gain $gain
	}
	select_gain_type

	MessageCount mc
	mc configure -callback message_rate_callback
	mc start
	after 1500 periodically_update_messagerate

	#automatically close screen after 5 minutes
	mc configure -closeAfterId [after [expr 5*60*1000] button_close_gain]
}

proc select_gain_type {} {
	set b .radiogain.bottom
	switch $::gainType {
		max {
			$b.maxgain select
			$b.maxgain configure -image radioOnIcon
			$b.manualgain configure -image radioOffIcon
		}

		manual {
			$b.manualgain select
			$b.maxgain configure -image radioOffIcon
			$b.manualgain configure -image radioOnIcon
		}
	}
}

proc periodically_update_messagerate {} {
	if { ![winfo exist .radiogain] } {
		return
	}
	set data "Gain is set to $::rtl_gain \n"
	append data [read_radio_stats rate]
	.radiogain.bottom.t configure -text $data

	after 1000 periodically_update_messagerate
}

proc message_rate_callback {data} {
	set ::messageRate "Currently you have $data "

}

proc change_gain {} {
	piawareConfig read_config
	if {$::gainType == "max"} {
		piawareConfig set_option $::gain_option max
	} else {
		piawareConfig set_option $::gain_option [.radiogain.bottom.slider get]
	}
	piawareConfig write_config
	catch {::fa_services::attempt_service_restart dump1090 restart}
}

proc button_accept_gain {} {
	change_gain

	mc stop
	itcl::delete object mc
	destroy .radiogain
}

proc button_close_gain {} {
	mc stop
	itcl::delete object mc
	destroy .radiogain
}

proc button_networksetup {} {
	create_topframe .network

	lappend menu networkedit "Ethernet Settings"

	if {"rpi_3b" in $::hardware && "beastgps" ni $::hardware} {
		if {[piawareConfig get rfkill]} {
			lappend menu wifikill "Enable Internal Wifi"
		} else {
			lappend menu wifikill "Disable Internal Wifi"
		}
	}

	if {[::fa_sysinfo::wireless_interface] ne ""} {
		lappend menu wifiedit "Wifi Settings"
	}

	lappend menu destroy Back

	create_menu .network $menu blue
}

proc button_shutdown {} {
	set message "Do you really want to Shutdown?"
	set answer [FA_messagebox .bottom "question" "yesno" "$message"]
	if {$answer == "Yes"} {
		::fa_sudo::exec_as -root -- /sbin/shutdown -h now
		after idle exit
	}
}

proc button_reboot {} {
	set message "Do you really want to Reboot?"
	set answer [FA_messagebox .bottom "question" "yesno" "$message"]
	if {$answer == "Yes"} {
		::fa_sudo::exec_as -root -- /sbin/shutdown -r now
		after idle exit
	}

}

proc button_log {} {
	create_newmenu .log "Logs" "close_log" "close_log"

	set pathPiawareLog "/var/log/piaware.log"
	if [catch {open $pathPiawareLog r} f] {
		FA_messagebox .log "question" "ok" "Could not open log file $pathPiawareLog. Try again later."
		return 0
	}

	create_textbox .log

	FileTailer ft
	ft configure -callback log_callback
	ft follow_file $pathPiawareLog

	.log.sub.t yview moveto 1
}

proc log_callback {data} {
	.log.sub.t insert end $data\n
}

proc close_log {} {
	ft close_file
	itcl::delete object ft
	destroy .log
}

####################################
# Buttons procs for Network commands
####################################
proc button_wired_network_settings {} {
	create_newmenu .config "Wired Network Settings" "config_cancel" "config_cancel"
	frame .config.f
	grid .config.f -columnspan 3
	ip_netmask_default_gateway .config.f wired
	populate_ip_fields wired
}

proc button_wireless_network_settings {} {
	create_newmenu .config "Wireless Network Settings" "config_cancel" "config_cancel"
	frame .config.f
	grid .config.f -columnspan 3
	ip_netmask_default_gateway .config.f wireless
	populate_ip_fields wireless
}

proc toggle_wired {} {
	#prevent multiple pushes by disabling the button
	.wired.status.wiredState state disabled

	#toggle the wired networking on/off and then restart the network
	piawareConfig read_config
	if {[piawareConfig get wired-network]} {
		piawareConfig set_option wired-network no
	} else {
		piawareConfig set_option wired-network yes
	}
	piawareConfig write_config
	catch {restart_network}
	change_network_status

	.wired.status.wiredState state !disabled
	update_wired_status
}

proc toggle_wireless_builtin {} {
	#prevent multiple pushes by disabling the button
	.wireless.status.wirelessState state disabled

	#toggle the wifi networking on/off and then restart the network
        piawareConfig read_config
        if {[piawareConfig get wireless-network]} {
                piawareConfig set_option wireless-network no
        } else {
                piawareConfig set_option wireless-network yes
        }
        piawareConfig write_config
	catch {restart_network}
	change_network_status

	.wireless.status.wirelessState state !disabled
	update_builtin_wireless_status
}

proc toggle_wireless_external {} {
	#prevent multiple pushes of the button
	.usbwireless.status.wirelessState state disabled

	#toggle the wifi networking on/off and then restart the network
        piawareConfig read_config
        if {[piawareConfig get wireless-network]} {
                piawareConfig set_option wireless-network no
        } else {
                piawareConfig set_option wireless-network yes
        }
        piawareConfig write_config
	catch {restart_network}
	change_network_status

	.usbwireless.status.wirelessState state !disabled
	update_usb_wireless_status
}


proc button_wired {} {
	set f .wired
	set a .wired.status
	set b .wired.status.bottom
	create_newmenu $f "Wired" "destroy .wired" "destroy .wired"

	grid [frame $a] -columnspan 3 -sticky news

	label $a.statuslabel -text "Status:" -font MenuFont -justify left
	label $a.status -textvariable ::ethernetstatus -font MenuFont -justify left
	grid $a.statuslabel $a.status -sticky w
	#This will expand the menu to the full width of the screen
	grid columnconfigure $a 1 -weight 1

	label $a.ipaddresslabel -text "Ethernet IP:" -font MenuFont -justify left
	label $a.ipaddress -textvariable ipaddress -font MenuFont -justify left
	grid $a.ipaddresslabel $a.ipaddress -sticky w

	label $a.netmasklabel -text "Netmask:" -font MenuFont -justify left
	label $a.netmask -textvariable ::dhcpnetmask -font MenuFont -justify left
	grid $a.netmasklabel $a.netmask -sticky w

	label $a.defaultgatewaylabel -text "Gateway:" -font MenuFont -justify left
	label $a.defaultgateway -textvariable defaultgateway -font MenuFont -justify left
	grid $a.defaultgatewaylabel $a.defaultgateway -sticky w

	label $a.ethernetmaclabel -text "MAC:" -font MenuFont -justify left
	label $a.ethernetmac -textvariable ethernetmac -font MenuFont -justify left
	grid $a.ethernetmaclabel $a.ethernetmac -sticky w

	ttk::button $a.wiredState -text "Turn Off" -style FAwhite.TButton -command toggle_wired
	ttk::button $a.wiredRenew -text "Renew" -style FA.TButton -command "button_renew_network $a.wiredRenew"
	grid $a.wiredState $a.wiredRenew
	update_wired_status

	grid [frame $b -padx 0 -pady 0] -columnspan 3 -sticky news
	grid rowconfigure $b 0 -weight 1
	grid columnconfigure $b 0 -weight 1
	set menuList {wired_network_settings "Network Settings"}
	create_newmenu_options $b $menuList
}

proc button_builtin_wireless {} {
	set f .wireless
	set a .wireless.status
	set b .wireless.status.bottom
	create_newmenu .wireless "Built-in Wireless" "destroy .wireless" "destroy .wireless"

	grid [frame $a] -columnspan 3 -sticky news

	label $a.statuslabel -text "Status:" -font MenuFont
	label $a.status -textvariable ::wifistatus -font MenuFont
	grid $a.statuslabel $a.status -stick w

	label $a.wirelessaddresslabel -text "IP Address:" -font MenuFont
	label $a.wirelessaddress -textvariable ::wifiaddress -font MenuFont
	grid $a.wirelessaddresslabel $a.wirelessaddress -sticky w

	label $a.ssidlabel -text "SSID:" -font MenuFont
	label $a.ssid -textvariable ::wifissid -font MenuFont
	ttk::button $a.ssidchange -image editIcon -style FAwhite.TButton -command button_wireless_ssid
	grid $a.ssidlabel $a.ssid $a.ssidchange -sticky w
	#This will expand the menu to the full width of the screen
	grid columnconfigure $a 2 -weight 1

	ttk::button $a.wirelessState -text "Turn Off" -style FAwhite.TButton -command toggle_wireless_builtin
	ttk::button $a.wirelessRenew -text "Renew" -style FA.TButton -command "button_renew_network $a.wirelessRenew"
	grid $a.wirelessState $a.wirelessRenew
	update_builtin_wireless_status

	grid [frame $b -padx 0 -pady 0] -columnspan 3 -sticky news
	set menuList {wireless_scan "Scan for Wireless Network" wireless_network_settings "Network Settings"}
	create_newmenu_options $b $menuList
}

proc button_usb_wireless {} {
	set f .usbwireless
	set a .usbwireless.status
	set b .usbwireless.status.bottom

	create_newmenu .usbwireless "USB Wireless" "destroy .usbwireless" "destroy .usbwireless"

	grid [frame $a] -columnspan 3 -sticky news
	grid rowconfigure $a 0 -weight 1
	grid columnconfigure $a 0 -weight 1

	label $a.statuslabel -text "Status:" -font MenuFont
	label $a.status -textvariable ::wifistatus -font MenuFont
	grid $a.statuslabel $a.status -sticky w

	label $a.wirelessaddresslabel -text "IP Address:" -font MenuFont
	label $a.wirelessaddress -textvariable ::wifiaddress -font MenuFont
	grid $a.wirelessaddresslabel $a.wirelessaddress -sticky w

	label $a.ssidlabel -text "SSID:" -font MenuFont
	label $a.ssid -textvariable ::wifissid -font MenuFont
	ttk::button $a.ssidchange -image editIcon -command button_wireless_ssid
	grid $a.ssidlabel $a.ssid $a.ssidchange -sticky w

	ttk::button $a.wirelessState -text "Turn Off" -style FAwhite.TButton -command toggle_wireless_external
	ttk::button $a.wiredRenew -text "Renew" -style FA.TButton -command "button_renew_network $a.wiredRenew"
	grid $a.wirelessState $a.wiredRenew -sticky w
	update_usb_wireless_status

	grid [frame $b] -columnspan 3 -sticky news
	set menuList {wireless_scan "Scan for Wireless Network" wireless_network_settings "Network Settings"}
	create_newmenu_options $b $menuList
}

proc button_renew_network {button} {
	$button state disabled
	restart_network
	$button state !disabled

	#deselect the button after restarting network
	$button state "!pressed !active"
}

proc update_wired_status {} {
	update_network_status
	if {$::wiredenable} {
		.wired.status.wiredState configure -text "Turn Off"
	} else {
		.wired.status.wiredState configure -text "Turn On"
	}

	#unselect the button
	.wired.status.wiredState state "!pressed !active"
}

proc update_builtin_wireless_status {} {
	update_network_status
	if {$::wirelessenable} {
		.wireless.status.wirelessState configure -text "Turn Off"
	} else {
		.wireless.status.wirelessState configure -text "Turn On"
	}

	#unselect the button
	.wireless.status.wirelessState state "!pressed !active"
}

proc update_usb_wireless_status {} {
	update_network_status
	if {$::wirelessenable} {
		.usbwireless.status.wirelessState configure -text "Turn Off"
	} else {
		.usbwireless.status.wirelessState configure -text "Turn On"
	}

	#unselect the button
	.usbwireless.status.wirelessState state "!pressed !active"	
}

proc button_system {} {
	#deselect button after being pushed
	.bottom.3 state "!selected !active"

	set menuList {system_settings "System Settings" radio "Radio" localization "Localization" reboot "Reboot" shutdown "Shut Down"}
	create_newmenu .system "System" "destroy .system" "destroy .system"

	grid [frame .system.bottom] -row 1 -columnspan 3 -sticky snew
	create_newmenu_options .system.bottom $menuList

}

proc button_system_settings {} {
#	removed some options for initial version
	set menuList {status "System Status" log "Log" ssh_configuration "SSH Configuration" calibrate_touchscreen "Calibrate Touchscreen"}
	create_newmenu .systemsettings "System Settings" "destroy .systemsettings" "destroy .systemsettings"

	grid [frame .systemsettings.bottom] -row 1 -columnspan 3 -sticky snew
	create_newmenu_options .systemsettings.bottom $menuList
}

proc button_localization {} {
	set menuList {wificountry "Wifi Country"}
	create_newmenu .localization "System" "destroy .localization" "destroy .localization"

	grid [frame .localization.bottom] -row 1 -columnspan 3 -sticky snew
	create_newmenu_options .localization.bottom $menuList

}

proc button_map {} {
	#deselect button after being pushed
	.bottom.3 state "!selected !active"
	.bottom.4 state "!selected !active"

	if {$::urlhint == ""} {
		set message "SkyAware not running"
	} else {
		set message "$::urlhint"
	}
	FA_messagebox .bottom "question" "ok" "$message"
}

proc button_status {} {
	create_newmenu .systemstatus "System Status" "destroy .systemstatus" "destroy .systemstatus"

	create_textbox .systemstatus

	periodically_update_systemstatus
}

proc button_ssh_configuration {} {
	set menuList {ssh_enable "Enable" ssh_disable "Disable"}
	if {[sshd_is_up]} {
		set prompt "SSH Configuration (sshd is UP)"
	} else {
		set prompt "SSH Configuration (sshd is DOWN)"
	}
	create_newmenu .sshconfig $prompt "destroy .sshconfig" "destroy .sshconfig"

	grid [frame .sshconfig.bottom] -row 1 -columnspan 3 -sticky snew
	create_newmenu_options .sshconfig.bottom $menuList
}

proc button_ssh_enable {} {
	set message "Remote login via ssh will be enabled.  Please change the password of the 'pi' user if you haven't. Continue?"
	set answer [FA_messagebox .bottom "question" "yesno" "$message"]
	if {$answer == "Yes"} {
	enable_sshd
	destroy .sshconfig
}

proc button_ssh_disable {} {
	set message "All active ssh sessions will remain.  No new ones will be allowed.  Continue?"
	set answer [FA_messagebox .bottom "question" "yesno" "$message"]
	if {$answer == "Yes"} {
		try {
			disable_sshd
		} on error {x y} {
			puts stderr "button_ssh_disable: x $x, y $y"
		}
	}
	destroy .sshconfig
}

#
# button_calibrate_touchscreen - perform touchscreen calibration
#
proc button_calibrate_touchscreen {} {
	set fp [open "|xinput_calibrator" r]
	set copying 0
	while {[gets $fp line] >= 0} {
		if {!$copying && [string match "Section*" $line]} {
			set copying 1
			set ofp [open "/etc/X11/xorg.conf.d/99-flightaware-touchscreen-calibration.conf" w]
		}

		if {$copying} {
			puts $ofp $line
		}
	}
	close $fp
	if {$copying} {
		close $ofp
	}
}

######################
# Procs for Wireless Setup
#####################

proc button_wireless_scan {} {
	set f .wireless_scan
	set b .wireless_scan.bottom
	set scanFrame .wireless_scan.scan
	set buttonFrame .wireless_scan.button
	create_newmenu $f "Scan for a Network" "destroy $f" "destroy $f"

	grid [frame $scanFrame] -columnspan 3
	grid [frame $buttonFrame] -columnspan 3

	#grow the middle to the full window size (this is where we will display the SSID)
	grid rowconfigure $f 0 -weight 0
	grid rowconfigure $f 1 -weight 1
	grid rowconfigure $f 2 -weight 0

	text $scanFrame.t -font MenuFont -borderwidth 0 -cursor $::cursorStyle -fg $::FADarkBlue -spacing1 1 -spacing3 1
	scrollbar $scanFrame.sby -orient vert -cursor $::cursorStyle -width 25 -troughcolor $::FALightBlue
	$scanFrame.t conf -yscrollcommand "$scanFrame.sby set"
	$scanFrame.sby conf -command "$scanFrame.t yview"

	label $buttonFrame.space -text "    "
	ttk::button $buttonFrame.rescan -text "Rescan" -command button_rescan_.wireless_scan -style FA.TButton
	ttk::button $buttonFrame.enterSSID -text "Enter SSID" -command button_wireless_ssid -style FA.TButton
	pack $buttonFrame.rescan -side left
	pack $buttonFrame.space -side left
	pack $buttonFrame.enterSSID -side left

	pack $scanFrame.sby -side right -fill y
	pack $scanFrame.t -side top -fill both
	pack [ttk::separator $scanFrame.seperatorA -orient horizontal] -side bottom -expand 1 -fill x

	#first scan for wifi networks
	button_rescan_.wireless_scan
}

proc button_dialog_ssid {ssid} {
	set message "$ssid?"
	set answer [FA_messagebox .wireless_scan "question" "yesno" "$message"]
	if {$answer == "Yes"} {
		piawareConfig read_config
		piawareConfig set_option wireless-ssid $ssid
		piawareConfig write_config
		destroy .wireless_scan

		change_network_status

		button_wireless_password
	}
}

proc button_rescan_.wireless_scan {} {
	set frame .wireless_scan.scan
	set i 1
	set wifiList ""

	#set rescan button to active
	.wireless_scan.button.rescan state "active focus hover pressed"

	#The delete command will return an error if there is nothing to delete.
	$frame.t insert 0.0 " "
	$frame.t delete 0.0 end

	#Check if wifi is present
	set interface [::fa_sysinfo::wireless_interface]
	if {$interface eq ""} {
		$frame.t insert end "No enabled wifi networks found\n"
	} else {
		$frame.t insert 0.0 "Select Network:\n"
		set wifiList [wifi_scan $interface]
		if {$wifiList ne ""} {
			foreach ssidInfo $wifiList {
				lassign $ssidInfo ssid address quality
				set b [button $frame.t.$i -text "$ssid" -font CtrlFont -command [list button_dialog_ssid $ssid] -bd 0 -fg $::FADarkBlue -bg white \
									 -padx 1 -pady 1]
				$frame.t window create end -window $b
				$frame.t insert end "\n"
				incr i
			}
		} else {
			$frame.t insert end "Wifi device not working or not near wifi access points\n"
		}
	}

	#deselect the scan button after scan
	.wireless_scan.button.rescan state !active
}

proc button_cancel_.wireless_scan {} {
	destroy .wireless_scan
}

proc button_wireless_ssid {} {
	create_newmenu .wireless-ssid "Enter SSID Network Name" "destroy .wireless-ssid" "destroy .wireless-ssid"
	setup_keypad_36key .wireless-ssid "update_wireless_config .wireless-ssid wireless-ssid"
}

proc button_wireless_password {} {
	create_newmenu .wireless-password "Enter Wireless Password" "destroy .wireless-password" "destroy .wireless-password"
	setup_keypad_36key .wireless-password "update_wireless_config .wireless-password wireless-password"

}

proc update_wireless_config {frame key action {value ""}} {
	switch -- $action {
		"cancel" {
			destroy $frame
		}

		"ok" {
			destroy $frame
			piawareConfig read_config
			piawareConfig set_option $key $value
			piawareConfig write_config
			change_network_status

			#If we just saved the SSID we continue onto the wifi password entry
			if {$key == "wireless-ssid"} {button_wireless_password}

			#If we just entered the wireless password we need to restart the network. Show popup that the network is restarting.
			if {$key == "wireless-password"} {
				set message "Restarting network. This will take some time."
				FA_messagebox .bottom "question" "ok" "$message"

				#check if we need to turn on the wireless network
				if (![piawareConfig get wireless-network]) {
					if ([piawareConfig get rfkill]) {
							#usb external wifi needs to be turned on
							toggle_wireless_external
					} else {
							#builtin wifi needs to be turned on
							toggle_wireless_builtin
					}
				} else {
					#Wifi already on so we just restart the network
					restart_network
				}
			}

		}
	}
}

proc button_wireless_edit {} {
	create_topframe .config
	ip_netmask_default_gateway .config wireless
	populate_ip_fields wired
}

proc create_language_selection {} {
	create_topframe .l

	label .l.label -text "Select your Language" -font MenuFont

	set mylist [list English Spanish French]
	ttk::combobox .l.cb  -textvariable combovalue -values $mylist -font MenuFont -background blue -foreground green -width 20 -justify center
	set combovalue "English"

	button .l.b -text "save" -font MenuFont -command "button_language" -relief flat
	pack .l.label .l.cb .l.b -expand 1

}

proc button_language {} {
	create_newmenu  .language "Language" "destroy .language" "destroy .language"
	set l .language.bottom
	grid [frame $l] -columnspan 3 -sticky news

	label $l.label -text "Select your Language" -font MenuFont

	set mylist [list English Spanish French]
	ttk::combobox $l.cb  -textvariable combovalue -values $mylist -font MenuFont -background blue -foreground green -width 20 -justify center
	set combovalue "English"

	ttk::button $l.b -text "save" -style FA.TButton -command ""
	pack $l.label $l.cb $l.b -expand 1
}

proc button_wificountry {} {
	set countryList [dict key $::countryDict]

	create_newmenu  .wificountry "Wifi Country" "destroy .wificountry" "destroy .wificountry"
	set b .wificountry.bottom
	grid [frame $b] -columnspan 3 -sticky news

	#This will change the font of the combobox Listbox
	option add *Listbox.font StatusFont

	label $b.label -text "Select your Wifi Country" -font MenuFont
	ttk::combobox $b.cb  -textvariable combovalue -values $countryList -font MenuFont -style FA.TCombobox -background blue -foreground black -width 20 -height 7 -justify center -cursor $::cursorStyle

	ttk::button $b.b -text "save" -style FA.TButton -command "save_wifi_country"
	pack $b.label $b.cb
	pack $b.b -pady 10 -side bottom

	#grab the current country from piaware-config and set the comobo to it
	set currentCountryCode [piawareConfig get wireless-country]
	foreach country [dict key $::countryDict] {
		if {[dict get $::countryDict $country] == $currentCountryCode} {
			set ::combovalue $country
		}
    }
}

proc save_wifi_country {} {
	piawareConfig read_config

	#grab the country name from the combobox and look up the country Code
	set selectedCountry [.wificountry.bottom.cb get]
	if {$selectedCountry == ""} {
		destroy .wificountry
		return
	}
	set countryCode [dict get $::countryDict $selectedCountry]

	piawareConfig set_option wireless-country $countryCode
	piawareConfig write_config

	set message "Restarting network. This will take some time."
	FA_messagebox .bottom "question" "ok" "$message"

	restart_network

	destroy .wificountry
}

proc button_location {} {
	create_newmenu  .location "Location Coordinates" "destroy .location" "destroy .location"
	set b .location.bottom
	grid [frame $b] -columnspan 3 -sticky news

	label $b.l -text "Location of the antenna is needed for MLAT tracking." -font InputFont -justify center
	grid $b.l -columnspan 2
	label $b.lat -text "Latitude: " -font MenuFont -justify left
	label $b.latvalue -textvariable latvalue -font MenuFont
	grid $b.lat $b.latvalue

	label $b.lon -text "Longitude: " -font MenuFont -justify left
	label $b.lonvalue -textvariable lonvalue -font MenuFont
	grid $b.lon $b.lonvalue

	label $b.alt -text "Elevation: " -font MenuFont -justify left
	label $b.altvalue -textvariable altvalue -font MenuFont
	grid $b.alt $b.altvalue
}

proc button_diagnostics {} {
	create_newmenu  .diagnostics "Diagnostics" "destroy .diagnostics" "destroy .diagnostics"
	set b .diagnostics.bottom
	grid [frame $b] -columnspan 3 -sticky news

	label $b.l -text "Diagnostics not available at this time." -font InputFont
	pack $b.l
}

# vim: set ts=4 sw=4 sts=4 noet :
