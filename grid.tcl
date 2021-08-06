#
#
#

package require fa_sudo

wm geometry . 800x800
set ethernetstatus down
set ethernetspeed 100
set ethernetduplex full
set ipaddress none
set defaultgateway none


#
# shutdown_action - perform shutdown actions
#
proc shutdown_action {} {
	.button_bar.offswitch flash
	::fa_sudo::exec_as -root -- /sbin/shutdown -h now
	after idle exit
}

#
# reboot_action - perform reboot actions
#
proc reboot_action {} {
	.button_bar.rebootswitch flash
	::fa_sudo::exec_as -root -- /sbin/shutdown -r now
	after idle exit
}

proc load_icons {scale} {
	image create photo hideIcon -file [file join $::basedirectory "icons/accordian-hide-icon.png"]
	image create photo showLargeIcon -file [file join $::basedirectory "icons/dropdown-icon.png"]
	image create photo showIcon -file [file join $::basedirectory "icons/accordian-show-icon.png"]
	image create photo backIcon -file [file join $::basedirectory "icons/back-icon.png"]
	image create photo closeIcon -file [file join $::basedirectory "icons/close-icon.png"]
	image create photo homeGreenIcon -file [file join $::basedirectory "icons/home-green-icon.png"]
	image create photo homeRedIcon -file [file join $::basedirectory "icons/home-red-icon.png"]
	image create photo homeYellowIcon -file [file join $::basedirectory "icons/home-yellow-icon.png"]
	image create photo arrowIcon -file [file join $::basedirectory "icons/menu-arrow-icon.png"]
	image create photo radioOffIcon -file [file join $::basedirectory "icons/radio-normal.png"]
	image create photo radioOnIcon -file [file join $::basedirectory "icons/radio-selected.png"]
	image create photo statusGreenIcon -file [file join $::basedirectory "icons/status-green-icon.png"]
	image create photo statusRedIcon -file [file join $::basedirectory "icons/status-red-icon.png"]
	image create photo statusYellowIcon -file [file join $::basedirectory "icons/status-yellow-icon.png"]
	image create photo loadingIcon -file [file join $::basedirectory "icons/Loading-min.gif"]
	image create photo editIcon -file [file join $::basedirectory "icons/icon-edit.png"]
	image create photo backspaceIcon -file [file join $::basedirectory "icons/icon-key-backspace.png"]
	image create photo symbolIcon -file [file join $::basedirectory "icons/icon-key-symbol.png"]
	image create photo uppercaseIcon -file [file join $::basedirectory "icons/icon-key-uppercase.png"]


	scaleImage hideIcon $scale
	scaleImage showLargeIcon $scale
	scaleImage showIcon $scale
	scaleImage backIcon $scale
	scaleImage closeIcon $scale
	scaleImage homeGreenIcon $scale
	scaleImage homeRedIcon $scale
	scaleImage homeYellowIcon $scale
	scaleImage arrowIcon $scale
	scaleImage radioOffIcon $scale
	scaleImage radioOnIcon $scale
	scaleImage statusGreenIcon $scale
	scaleImage statusRedIcon $scale
	scaleImage statusYellowIcon $scale
	scaleImage loadingIcon $scale
}

proc load_ttk_styles {} {
	#normal tk button don't allow layout styles so using ttk buttons
	#create the elements and layouts of the elements into a FA buttons styles
	ttk::style element create up.TButton.indicator image showIcon
	ttk::style element create down.TButton.indicator image hideIcon
	ttk::style element create showLarge.TButton.indicator image showLargeIcon
	ttk::style element create green.TButton.indicator image statusGreenIcon
	ttk::style element create yellow.TButton.indicator image statusYellowIcon
	ttk::style element create red.TButton.indicator image statusRedIcon

	ttk::style layout statusDown.TButton {
		Button.border -sticky nswe -border 1 -children {
			Button.focus -sticky nswe -children {
				Button.padding -sticky nswe -children {
					Button.label -side left
					down.TButton.indicator -side left -sticky e}}}}

	ttk::style layout statusUp.TButton {
		Button.border -sticky nswe -border 1 -children {
			Button.focus -sticky nswe -children {
				Button.padding -sticky nswe -children {
					Button.label -side left
					up.TButton.indicator -side left -sticky e}}}}

	ttk::style layout FAkey.TButton {
		Button.border -sticky nswe -border 1 -children {
					Button.label}}

	ttk::style layout mainMenuGreen.TButton {
		Button.border -sticky nswe -border 1 -children {
			Button.focus -sticky nswe -children {
				Button.padding -sticky nswe -children {
					Button.label  -side left
					green.TButton.indicator -side left -sticky e}}}}
	ttk::style layout mainMenuYellow.TButton {Button.border -sticky nswe -border 1 -children {
			Button.focus -sticky nswe -children {
				Button.padding -sticky nswe -children {
					Button.label  -side left
					yellow.TButton.indicator -side left -sticky e}}}}
	ttk::style layout mainMenuRed.TButton {Button.border -sticky nswe -border 1 -children {
			Button.focus -sticky nswe -children {
				Button.padding -sticky nswe -children {
					Button.label  -side left
					red.TButton.indicator -side left -sticky e}}}}
	ttk::style layout mainMenu.TButton {Button.border -sticky nswe -border 1 -children {
			Button.focus -sticky nswe -children {
				Button.padding -sticky nswe -children {
					Button.label  -side left
					}}}}

	ttk::style layout FA.TCombobox {
		Combobox.field -sticky nswe -children {
			showLarge.TButton.indicator -side right -sticky ns
			Combobox.padding -expand 1 -sticky nswe -children {
				Combobox.textarea -sticky nswe
			}
		}
	}
}

proc setup_font_common {} {
	set ::FADarkBlue #002f5d
	set ::FALightBlue #00a0e2
	set ::MenuBackground $::FADarkBlue
}

#
# setup fonts for different screens sizes
#
proc setup_font_35tft {} {
	load_icons 1

	font create KeypadFontLabel -family Lato -size 24 -weight bold
	font create KeypadFontActionButton -size 14
	font create KeypadFontButton -family Lato -size 14 -weight bold
	font create StatusFont -family Lato -size 14 -weight bold
	font create MenuFont -family Lato -size 18 -weight bold
	font create LabelFont -family Lato -size 18 -weight bold
	font create CtrlFont -family Lato -size 12 -weight bold
	font create TabFont -family Lato -size 25 -weight bold
	font create TextFont -family Lato -size 11
	font create KeypadFont -family Lato -size 24 -weight bold
	font create KeypadLetter -family Lato -size 23 -weight bold
	font create InputFont -family Lato -size 12

	font create MenuTopLabel -family Lato -size 18 -weight bold
	font create MenuLabel -family Lato -size 16 -weight normal

	set ::keypadButtonWidth 4
	set ::menuBorderWidth 5

	#load common styles
	load_ttk_styles

	#load specific styles for 3.5" TFT
	ttk::style configure mainMenuGreen.TButton -relief flat -font MenuTopLabel -background $::FALightBlue -foreground white -padding 5
	ttk::style configure mainMenuYellow.TButton -relief flat -font MenuTopLabel -background $::FALightBlue -foreground white -padding 5
	ttk::style configure mainMenuRed.TButton -relief flat -font MenuTopLabel -background $::FALightBlue -foreground white -padding 5
	ttk::style configure mainMenu.TButton -relief flat -font MenuTopLabel -background $::FALightBlue -foreground white -padding 5

	ttk::style configure FA.TButton -relief flat -background #00a0e2 -foreground white -font {MenuFont} -padding 5
	ttk::style configure FAwhite.TButton -relief sunken -background white -foreground $::FADarkBlue -font {MenuFont} -padding 5
	ttk::style configure FAdark.TButton -relief flat -background $::FADarkBlue -foreground white -font {MenuFont} -padding 10
	ttk::style configure FAgrey.TButton -relief flat -background grey90 -foreground white -font {MenuFont} -padding 10
	ttk::style configure FAkey.TButton -relief flat -borderwidth 1 -background white -foreground black -font {KeypadLetter}
	ttk::style configure FAnumkey.TButton -relief flat -borderwidth 1 -background white -foreground black -font {KeypadFont}
	ttk::style configure FAoptionkey.TButton -relief flat -borderwidth 1 -background #a7b3bf -foreground black -font {KeypadFont}
	ttk::style configure FAsavekey.TButton -relief flat -borderwidth 1 -background $::FALightBlue -foreground white -font {KeypadFont}

	ttk::style configure status.Tbutton -activebackground orange -background white -font {MenuFont}
	ttk::style configure statusDown.TButton -relief flat -foreground $::MenuBackground -height 20 -borderwidth 0 -highlightthickness 0 -padx 10 -pady 8 \
											-activebackground orange -background white -font {MenuFont} -anchor w -justify left
	ttk::style configure statusUp.TButton -relief flat -foreground $::MenuBackground -height 20 -borderwidth 0 -highlightthickness 0 -padx 10 -pady 8 \
											-activebackground orange -background white -font {MenuFont} -anchor w -justify left


	ttk::style map FAdark.TButton -background [list pressed $::FADarkBlue]

}

proc setup_font_32tft {} {
	load_icons 1

	font create KeypadFontLabel -family Lato -size 10 -weight bold
	font create KeypadFontActionButton -size 6
	font create KeypadFontButton -size 6 -weight bold
	font create StatusFont -family Lato -size 11 -weight bold
	font create MenuFont -family Lato -size 12 -weight bold
	font create LabelFont -family Lato -size 8 -weight bold
	font create CtrlFont -family Lato -size 8 -weight bold
	font create TabFont -family Lato -size 12 -weight bold
	font create TextFont -family Lato -size 8
	font create KeypadFont -family Lato -size 15 -weight bold
	font create KeypadLetter -family Lato -size 14 -weight bold
	font create InputFont -family Lato -size 10
	set ::keypadButtonWidth 2
	set ::menuBorderWidth 3

	font create MenuTopLabel -family Lato -size 13 -weight bold
	font create MenuLabel -family Lato -size 10 -weight normal

	#load common styles
	load_ttk_styles

	#load specific styles for 3.2" TFT
	ttk::style configure mainMenuGreen.TButton -relief flat -font MenuTopLabel -background $::FALightBlue -foreground white -padding 1
	ttk::style configure mainMenuYellow.TButton -relief flat -font MenuTopLabel -background $::FALightBlue -foreground white -padding 1
	ttk::style configure mainMenuRed.TButton -relief flat -font MenuTopLabel -background $::FALightBlue -foreground white -padding 2
	ttk::style configure mainMenu.TButton -relief flat -font MenuTopLabel -background $::FALightBlue -foreground white -padding 2

	ttk::style configure FA.TButton -relief flat -background #00a0e2 -foreground white -font {MenuTopLabel} -padding 5
	ttk::style configure FAwhite.TButton -relief sunken -background white -foreground $::FADarkBlue -font {MenuTopLabel} -padding 5
	ttk::style configure FAdark.TButton -relief flat -background $::FADarkBlue -foreground white -font {MenuTopLabel} -padding 10
	ttk::style configure FAgrey.TButton -relief flat -background grey90 -foreground white -font {MenuTopLabel} -padding 10
	ttk::style configure FAkey.TButton -relief flat -borderwidth 1 -background white -foreground black -font {KeypadLetter}
	ttk::style configure FAnumkey.TButton -relief flat -borderwidth 1 -background white -foreground black -font {KeypadFont}
	ttk::style configure FAoptionkey.TButton -relief flat -borderwidth 1 -background #a7b3bf -foreground black -font {KeypadFont}
	ttk::style configure FAsavekey.TButton -relief flat -borderwidth 1 -background $::FALightBlue -foreground white -font {KeypadFont}

	ttk::style configure status.Tbutton -activebackground orange -background white -font {MenuFont}
	ttk::style configure statusDown.TButton -relief flat -foreground $::MenuBackground -height 20 -borderwidth 0 -highlightthickness 0 -padx 10 -pady 8 \
											-activebackground orange -background white -font {MenuFont} -anchor w -justify left
	ttk::style configure statusUp.TButton -relief flat -foreground $::MenuBackground -height 20 -borderwidth 0 -highlightthickness 0 -padx 10 -pady 8 \
											-activebackground orange -background white -font {MenuFont} -anchor w -justify left
	ttk::style map FAdark.TButton -background [list pressed $::FADarkBlue]
}

proc setup_font_hdmi {} {
	load_icons 1

	font create KeypadFontLabel -family Lato -size 24 -weight bold
	font create KeypadFontActionButton -size 14
	font create KeypadFontButton -family Lato -size 14 -weight bold
	font create StatusFont -family Lato -size 23 -weight bold
	font create MenuFont -family Lato -size 20 -weight bold
	font create LabelFont -family Lato -size 18 -weight bold
	font create CtrlFont -family Lato -size 18 -weight bold
	font create TabFont -family Lato -size 18 -weight bold
	font create TextFont -family Lato -size 13
	font create KeypadFont -family Lato -size 24 -weight bold
	font create KeypadLetter -family Lato -size 23 -weight bold
	font create InputFont -family Lato -size 15
	set ::keypadButtonWidth 4
	set ::menuBorderWidth 5

	font create MenuTopLabel -family Lato -size 20 -weight bold
	font create MenuLabel -family Lato -size 16 -weight normal

	#load common styles
	load_ttk_styles

	#load specific styles for 3.2" TFT
	ttk::style configure mainMenuGreen.TButton -relief flat -font MenuTopLabel -background $::FALightBlue -foreground white -padding 5
	ttk::style configure mainMenuYellow.TButton -relief flat -font MenuTopLabel -background $::FALightBlue -foreground white -padding 5
	ttk::style configure mainMenuRed.TButton -relief flat -font MenuTopLabel -background $::FALightBlue -foreground white -padding 5
	ttk::style configure mainMenu.TButton -relief flat -font MenuTopLabel -background $::FALightBlue -foreground white -padding 5

	ttk::style configure FA.TButton -relief flat -background #00a0e2 -foreground white -font {MenuFont} -padding 5
	ttk::style configure FAwhite.TButton -relief sunken -background white -foreground $::FADarkBlue -font {MenuFont} -padding 5
	ttk::style configure FAdark.TButton -relief flat -background $::FADarkBlue -foreground white -font {MenuFont} -padding 10
	ttk::style configure FAgrey.TButton -relief flat -background grey90 -foreground white -font {MenuFont} -padding 10
	ttk::style configure FAkey.TButton -relief flat -borderwidth 1 -background white -foreground black -font {KeypadLetter}
	ttk::style configure FAnumkey.TButton -relief flat -borderwidth 1 -background white -foreground black -font {KeypadFont}
	ttk::style configure FAoptionkey.TButton -relief flat -borderwidth 1 -background #a7b3bf -foreground black -font {KeypadFont}
	ttk::style configure FAsavekey.TButton -relief flat -borderwidth 1 -background $::FALightBlue -foreground white -font {KeypadFont}

	ttk::style configure status.Tbutton -activebackground orange -background white -font {MenuFont}
	ttk::style configure statusDown.TButton -relief flat -foreground $::MenuBackground -height 20 -borderwidth 0 -highlightthickness 0 -padx 10 -pady 8 \
											-activebackground orange -background white -font {MenuFont} -anchor w -justify left
	ttk::style configure statusUp.TButton -relief flat -foreground $::MenuBackground -height 20 -borderwidth 0 -highlightthickness 0 -padx 10 -pady 8 \
											-activebackground orange -background white -font {MenuFont} -anchor w -justify left
	ttk::style map FAdark.TButton -background [list pressed $::FADarkBlue]
}

proc FA_messagebox {parentwindow icon type message} {
	global msgBoxButton
	set p $parentwindow
	set w $p.__tk__messagebox
	set grey $p.grey
	toplevel $w -class Dialog -cursor $::cursorStyle
	wm protocol $w WM_DELETE_WINDOW { }

	frame $w.bot
	pack $w.bot -side bottom -fill both
	frame $w.top
	pack $w.top -side top -fill both -expand 1
	$w.bot configure -relief raised -bd 1
	$w.top configure -relief raised -bd 1

	set wraplength [expr ([winfo screenwidth $p] * .8)]
	label $w.label -text $message -font MenuFont -wraplength $wraplength
	pack $w.label -in $w.top

	switch $type {
		yesno {
			ttk::button $w.yes -text Yes -command {set msgBoxButton Yes} -style FA.TButton
			ttk::button $w.no -text No -command {set msgBoxButton No} -style FAwhite.TButton
			pack $w.yes -in $w.bot -side left -padx 3m -pady 2m
			pack $w.no -in $w.bot -side left -padx 3m -pady 2m

			#sometimes TCL will have these button selected. So deselect the buttons
			$w.yes state !selected
			$w.no state !selected
		}
		ok {
			ttk::button $w.ok -text Ok -command {set msgBoxButton Ok} -style FA.TButton
			pack $w.ok -in $w.bot -side bottom -padx 3m -pady 2m
			$w.ok state !selected
		}
		default {
			ttk::button $w.ok -text Ok -command {set msgBoxButton Ok} -style FA.TButton
			pack $w.ok -in $w.bot -side bottom -padx 3m -pady 2m
			$w.ok state !selected
		}
	}

	#move the window to the center of the parent
	wm withdraw $w
	update idletasks
	set pw [winfo width $p]
	set ph [winfo height $p]
	set x [expr {($pw - [winfo reqwidth $w])/2}]
	set y [expr {($ph - [winfo reqheight $w])/2}]
	if {$x<0} {set x 0}
	if {$y<0} {set y 0}
	wm geom $w +$x+$y
	wm deiconify $w

	#grab the focus
	set oldFocus [focus]
	set oldGrab [grab current $w]
	if {$oldGrab != ""} {
	set grabStatus [grab status $oldGrab]
	}
	grab $w
	focus $w

	#wait for a button to be pushed
	tkwait variable msgBoxButton
	catch {focus $oldFocus}
	destroy $w
	event generate . <Motion> -warp 1 -x 0 -y 0
	if {$oldGrab != ""} {
		if {$grabStatus == "global"} {
			grab -global $oldGrab
		} else {
			grab $oldGrab
		}
	}
	return $msgBoxButton
}

proc setup_main {} {
	set t .top
	set b .bottom
	frame $t -cursor $::cursorStyle
	frame $b -cursor $::cursorStyle
	pack $t -expand 0 -fill x
	pack $b -expand 1 -fill both

	#grid the top with widget
	set ::ipaddressText "Local IP Address:"
	label $t.iplabel -textvariable ipaddress_mainmenu -font MenuTopLabel -bg $::MenuBackground -fg white -anchor center
	pack $t.iplabel -expand 1 -fill x

	piawareConfig read_config
	if {"beastgps" in $::hardware} {
		set menuList {radio "1090 Radio" mlat "MLAT" gps "GPS" flightaware "FlightAware Connection"}
	} elseif {[piawareConfig get receiver-type] ne "none"} {
                set menuList {radio "1090 Radio" piaware "PiAware" mlat "MLAT" flightaware "FlightAware Connection"}
	} elseif {[piawareConfig get uat-receiver-type] ne "none"} {
		set menuList {uat_radio "978 UAT Radio" flightaware "FlightAware Connection"}
	} else {
		set menuList {no_radio "Radio" flightaware "FlightAware Connection"}
	}

	set wraplength [expr ([winfo screenwidth $b] * .8)]

	foreach {menuName menuText} $menuList {
		set textpath ""
		append textpath $b.$menuName text
		ttk::button $b.$menuName -text $menuText -style statusUp.TButton -compound left -image statusRedIcon -width 20 -command "expand_device_status $b.$menuName $textpath"
		label $textpath -text "No status information" -justify center -font MenuLabel -wraplength $wraplength
		grid $b.$menuName -columnspan 5 -pady 2
		grid $textpath -columnspan 5
		set ::indicator_path($menuName) $b.$menuName
	}

	#Hide all the text fields
	foreach {menuName menuText} $menuList {
		set textpath ""
		append textpath $b.$menuName text
		grid remove $textpath
	}

	ttk::button $b.2 -text "Network Settings" -command "view_frame .network" -style mainMenu.TButton
	ttk::button $b.3 -text "System Settings" -command "button_system" -style mainMenu.TButton
	ttk::button $b.4 -text "SkyAware Map" -command "button_map" -style mainMenu.TButton

	grid $b.2 -row 8 -column 0 -padx 10 -pady 5
	grid $b.3 -row 8 -column 1 -columnspan 2 -padx 10 -pady 5
	grid $b.4 -row 9 -columnspan 2 -padx 10 -pady 5

	grid rowconfigure $b {0 1} -weight 0
	grid columnconfigure $b {0 1} -weight 1

	#Set up network menu frames
	setup_network_menu
}

proc setup_status_menu {} {
	piawareConfig read_config
	if {"beastgps" in $::hardware} {
		set menuList {radio "1090 Radio" mlat "MLAT" gps "GPS" flightaware "FlightAware"}
	} elseif {[piawareConfig get receiver-type] ne "none"} {
                set menuList {radio "1090 Radio" mlat "MLAT"  flightaware "FlightAware"}
	} elseif {[piawareConfig get uat-receiver-type] ne "none"} {
		set menuList {uat_radio "978 UAT Radio" flightaware "FlightAware"}
	} else {
		set menuList {no_radio "Radio" flightaware "FlightAware"}
	}

	set f .status

	create_newmenu $f "Device Status" "none" "view_frame ."

	#Options require hidden text fields so can't use standard create_newmenu_options
	set b "$f.bottom"

	#set text wrappping to 80% of screen
	set wraplength [expr ([winfo screenwidth $f] * .8)]

	grid [frame $b] -row 1 -columnspan 3 -sticky snew
	foreach {menuName menuText} $menuList {
		set textpath ""
		append textpath $b.$menuName text
		ttk::button $b.$menuName -text $menuText -style statusUp.TButton -compound left -image statusRedIcon -width [winfo screenwidth .] -command "expand_device_status $b.$menuName $textpath"
		label $textpath -text "No status information" -justify left -font MenuLabel -wraplength $wraplength
		grid $b.$menuName -sticky we
		grid $textpath -sticky w

		#Set the indicator path so it can be update with "status menuname green"
		set ::indicator_path($menuName) $b.$menuName
		#puts "::indicator_path($menuName) $b.$menuName"
	}

	#Hide all the text fields
	foreach {menuName menuText} $menuList {
		set textpath ""
		append textpath $b.$menuName text
		grid remove $textpath
	}

	grid rowconfigure $f $f.bottom -weight 0

	# Create a new frame for system information under Device Status page
	set c "$f.status_sysinfo"
	grid [frame $c] -columnspan 3 -sticky news
	grid columnconfigure $c 1 -weight 1

	grid [ttk::separator $c.seperator -orient horizontal] -sticky ew -columnspan 3
	label $c.cputemplabel -text "CPU Temperature: " -font LabelFont -bg white -fg $::FADarkBlue -justify left
	label $c.cputemp -textvariable ::cputemperature -font LabelFont -bg white -fg $::FADarkBlue -justify left
	grid $c.cputemplabel $c.cputemp -sticky w

	label $c.cpuloadlabel -text "CPU Load: " -font LabelFont -bg white -fg $::FADarkBlue -justify left
	label $c.cpuload -textvariable ::cpuload -font LabelFont -bg white -fg $::FADarkBlue -justify left
	grid $c.cpuloadlabel $c.cpuload -sticky w

	label $c.uptimeLabel -text "System Uptime: " -font LabelFont -bg white -fg $::FADarkBlue -justify left
	label $c.uptime -textvariable ::uptime -font LabelFont -bg white -fg $::FADarkBlue -justify left
	grid $c.uptimeLabel $c.uptime -sticky w

	grid rowconfigure $f $f.status_sysinfo -weight 0
}

proc expand_device_status {name option} {
	if {[$name cget -style] == "statusUp.TButton"} {
		grid $option
		$name configure -style statusDown.TButton
	} else {
		grid remove $option
		$name configure -style statusUp.TButton
	}
}

proc setup_network_menu {} {
	set menuList {wired "Wired Connection" builtin_wireless "Built-in Wireless Connection" usb_wireless "USB wifi Adapter"}
	create_newmenu .network "Network" "view_frame ." "view_frame ."

	#Options require a status icon so can't use create_newmenu_options
	set b ".network.bottom"
	grid [frame $b] -row 1 -columnspan 3 -sticky snew
	foreach {menuName menuText} $menuList {
		button $b.$menuName -text $menuText -font MenuLabel -relief flat -overrelief flat -anchor w -borderwidth 0 -highlightthickness 0 -padx 20 -pady 8 \
							-foreground $::MenuBackground -activebackground orange -background white -compound left -image statusRedIcon \
							-command "check_enabled button_$menuName"
		pack $b.$menuName -expand 1 -fill x
		set sep [ttk::separator $b.seperator"$menuName" -orient horizontal]
		pack $sep -expand 1 -fill x

		#Set the indicator path so it can be update with "status menuname green"
		set ::indicator_path($menuName) $b.$menuName
		#puts "::indicator_path($menuName) $b.$menuName"
	}
}

proc check_enabled {button} {
	switch $button {
		button_wired {
			#wired is always enabled so just run the button
			eval $button
		}
		button_builtin_wireless {
			#check piaware_config if rfkill is NOT enabled
			piawareConfig read_config
			if {[piawareConfig get rfkill]} {
				#ask user if they want to switch to built-in wireless
				set message "Turning on the Builtin Wireless will turn off external USB Wireless. This will require a reboot. Continue?"
				set answer [FA_messagebox .network "question" "yesno" "$message"]
				if {$answer == "Yes"} {
					piawareConfig read_config
					piawareConfig set_option rfkill no
					piawareConfig set_option wireless-network yes
					piawareConfig write_config

					::fa_sudo::exec_as -root -- /sbin/shutdown -r now
					after idle exit
				}
			} else {
				eval $button
			}
		}
		button_usb_wireless {
			#check piaware_config if rfkill is enabled
			piawareConfig read_config
			if {![piawareConfig get rfkill]} {
				#ask user if they want to switch to built-in wireless
				set message "Turning on the external USB Wireless will turn off Builtin Wireless. This will require a reboot. Continue?"
				set answer [FA_messagebox .network "question" "yesno" "$message"]
				if {$answer == "Yes"} {
					piawareConfig read_config
					piawareConfig set_option rfkill yes
					piawareConfig set_option wireless-network yes
					piawareConfig write_config

					::fa_sudo::exec_as -root -- /sbin/shutdown -r now
					after idle exit
				}
			} else {
				eval $button
			}
		}
		default {
			eval $button
		}
	}

}

proc view_frame {frame} {
	raise $frame
}

# vim: set ts=4 sw=4 sts=4 noet :
