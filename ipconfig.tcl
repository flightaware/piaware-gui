
# temp
lappend auto_path /usr/local/lib
package require Itcl
package require Tk

tk_setPalette white

#font create StatusFont -family Courier -size 18 -weight bold
#font create LabelFont -family Courier -size 14 -weight bold
#font create CtrlFont -family Arial -size 12 -weight bold
#font create InputFont -family Courier -size 18 -weight bold

#set ipv4ConfigType dhcp
set ipv4ConfigType static

set ipv4ObjectList [list ip netmask default_gateway dns1 dns2]

#
# ip_entry - itcl class for Tk for entering IP addresses
#
itcl::class ip_entry {
	public variable w
	public variable state

	constructor {window args} {
		configure {*}$args

		set w $window
		frame $w -relief sunken -borderwidth 0
		entry $w.1 -width 3 -relief flat -validate all -vcmd {is_valid_octet %P} -font InputFont -disabledforeground darkgrey -disabledbackground white -justify right -selectbackground lightblue
		label $w.a -text . -background gray90 -relief flat
		entry $w.2 -width 3 -relief flat -validate all -vcmd {is_valid_octet %P} -font InputFont -disabledforeground darkgrey -disabledbackground white -justify right -selectbackground lightblue
		label $w.b -text . -background gray90 -relief flat
		entry $w.3 -width 3 -relief flat -validate all -vcmd {is_valid_octet %P} -font InputFont -disabledforeground darkgrey -disabledbackground white -justify right -selectbackground lightblue
		label $w.c -text . -background gray90 -relief flat
		entry $w.4 -width 3 -relief flat -validate all -vcmd {is_valid_octet %P} -font InputFont -disabledforeground darkgrey -disabledbackground white -justify right -selectbackground lightblue
		eval pack [winfo children $w] -side left -padx 0

		for {set i 1} {$i < 5} {incr i} {
			bind $w.$i <FocusIn> "10key_entry $this"
		}
		return $w
	}

	#
	# set_state - set_state readyonly, set_state normal
	#
	method set_state {wantState} {
		set state $wantState
		for {set i 1} {$i <= 4} {incr i} {
			$w.$i configure -state $state
		}

		if {$state == "disabled"} {
			$w configure -relief flat
		} else {
			$w configure -relief sunken
		}
	}

	#
	# get - return the IP address or an empty string depending on what we've
	# got
	#
	method get {} {
		set v1 [$w.1 get]
		set v2 [$w.2 get]
		set v3 [$w.3 get]
		set v4 [$w.4 get]

		if {$v1 == "" || $v2 == "" || $v3 == "" || $v4 == ""} {
			return ""
		}

		return "$v1.$v2.$v3.$v4"
	}

	method store {ip} {
		set i 1
		foreach v [split $ip "."] {
			#Skip if more than 4 octets
			if {$i < 5} {
				$w.$i delete 0 end
				$w.$i insert 0 $v
			}
			incr i
		}
	}

	method focus_on_me {} {
		focus $w.1
		$w.1 select range 0 end
	}
}

#
# 10key_entry - replace the IP of the specified IP_entry object
#
proc 10key_entry {id} {
	focus .config.f.dhcp_options.manually

	create_newmenu .keypad "Enter IP" "destroy .keypad" "destroy .keypad"
	frame .keypad.f
	grid .keypad.f -columnspan 3
	setup_keypad_10key .keypad.f $id
}

#
# is_valid_octet - return 1 if a string is empty or a valid integer
# between 0 and 255
#
proc is_valid_octet {str} {
	if {$str eq ""} {return 1}
	expr {[string is integer -strict $str] && $str >= 0 && $str < 256}
}


#
# ip_netmask_default_gateway - create Tk stuff to allow the user to
#   specify an IP, netmask and default gateway
#
proc ip_netmask_default_gateway {w type} {
	# ip
	#

	set row 0

	label $w.dhcp_options_label -text "Configure" -font LabelFont -foreground grey
	grid $w.dhcp_options_label -row $row -column 0

	#tk_optionMenu $w.dhcp_options dhcpSetting "Using DHCP" "Manually"

	set f $w.dhcp_options
	frame $f
	radiobutton $f.using_dhcp -variable ipv4ConfigType -value dhcp -text "Using DHCP" -font InputFont -command "ipv4_config_type_changed"
	pack $f.using_dhcp -side left -fill x -pady 10

	focus $f.using_dhcp

	radiobutton $f.manually -variable ipv4ConfigType -value static -text "Using Static" -font InputFont -command "ipv4_config_type_changed"
	pack $f.manually -side left -fill x

	grid $w.dhcp_options -row $row -column 1

	label $w.right_side_label -text "  " -font LabelFont
	grid $w.right_side_label -row $row -column 2

	incr row

	label $w.iplabel -text "IP" -font LabelFont -foreground grey
	grid $w.iplabel -row $row -column 0

	ip_entry ip $w.ip
	grid $w.ip -row $row -column 1

	incr row

	# netmask

	label $w.netmasklabel -text "Netmask" -font LabelFont -foreground grey
	grid $w.netmasklabel -row $row -column 0

	ip_entry netmask $w.netmask
	grid $w.netmask -row $row -column 1

	incr row

	# default gateway

	label $w.defaultgatewaylabel -text "Gateway" -font LabelFont -foreground grey
	grid $w.defaultgatewaylabel -row $row -column 0

	ip_entry default_gateway $w.defaultgateway
	grid $w.defaultgateway -row $row -column 1

	incr row

	# dns 1

	label $w.dns1label -text "DNS 1" -font LabelFont -foreground grey
	grid $w.dns1label -row $row -column 0

	ip_entry dns1 $w.dns1
	grid $w.dns1 -row $row -column 1

	incr row

	# dns 2

	label $w.dns2label -text "DNS 2" -font LabelFont -foreground grey
	grid $w.dns2label -row $row -column 0

	ip_entry dns2 $w.dns2
	grid $w.dns2 -row $row -column 1

	incr row

	ttk::button $w.accept -text "Accept" -style FA.TButton -command "config_accept $type"
	grid $w.accept -row $row -column 0 -columnspan 2 -sticky e

	# trigger the initial read/write or readonly state based on the dhcp
	# or manual setting of the ipv4ConfigType, which will be updated from
	# radiobutton actions after this
	ipv4_config_type_changed
}

#
# delete_ip_netmask_default_gateway - delete the Tk objects created
#

proc delete_ip_netmask_default_gateway {w} {
	foreach obj [list ip netmask default_gateway dns1 dns2] {
		itcl::delete object $obj
	}
	destroy $w
}

proc set_dhcp_fields_state {state} {
	foreach ipv4Object $::ipv4ObjectList {
		if { $ipv4Object == "dns1" || $ipv4Object == "dns2" } {
			$ipv4Object set_state normal
		} else {
			$ipv4Object set_state $state
		}
	}
}

#
# ipv4_config_type_changed - callback routine to do the needful if the user
#  siwtches between manual and dhcp config options
#
proc ipv4_config_type_changed {} {
	switch $::ipv4ConfigType {
		"static" {
			set_dhcp_fields_state normal
		}

		"dhcp" {
			set_dhcp_fields_state disabled
			focus .config.f.dhcp_options.using_dhcp
		}

		default {
			error "software error, ipv4ConfigType value of $::ipv4ConfigType not accounted for"
		}
	}
}

#
# populate_ip_fields - populate the IP widgets with real values from the
#   system
#
proc populate_ip_fields {type} {
	piawareConfig read_config
	set_dhcp_fields_state normal
	ip store [piawareConfig get $type-address]
	netmask store [piawareConfig get $type-netmask]
	default_gateway store [piawareConfig get $type-gateway]

	lassign [piawareConfig get $type-nameservers] dns1 dns2
	dns1 store $dns1
	dns2 store $dns2

	if {[piawareConfig get $type-type] == "dhcp"} {
		set ::ipv4ConfigType dhcp
	} else {
		set ::ipv4ConfigType static
	}
	ipv4_config_type_changed
}

proc config_accept {type} {
	switch $::ipv4ConfigType {
		"static" {
			piawareConfig read_config
			piawareConfig set_option $type-type $::ipv4ConfigType
			piawareConfig set_option $type-address [ip get]
			piawareConfig set_option $type-netmask [netmask get]
			piawareConfig set_option $type-gateway [default_gateway get]
			piawareConfig set_option $type-nameservers [get_dns]
			piawareConfig set_option wired-network yes
			#for some reason the wireless network conflicts with the wired so we turn wireless off
			piawareConfig set_option wireless-network no
			piawareConfig write_config
		}
		"dhcp" {
			piawareConfig read_config
			piawareConfig set_option $type-type $::ipv4ConfigType
			piawareConfig set_option wired-network yes
			#for some reason the wireless network conflicts with the wired so we turn wireless off
			piawareConfig set_option wireless-network no
			piawareConfig write_config
		}

		default {
		}
	}
	delete_ip_netmask_default_gateway .config
	change_network_status
}

proc get_dns {} {
	set dnslist {}

	set d1 [dns1 get]
	if {$d1 ne ""} {
		lappend dnslist $d1
        }

	set d2 [dns2 get]
	if {$d2 ne ""} {
		lappend dnslist $d2
	}

	return $dnslist
}

proc config_cancel {} {
	delete_ip_netmask_default_gateway .config
}


set dhcpClientID "piaware"
