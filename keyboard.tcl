
# button_list - return the button list for the position in the 36 key pad
#
proc select_button_list {language type} {
	
	switch $language {
		english {
			switch $type {
				lowercase {
					return [list q w e r t y u i o p a s d f g h j k l {upper} z x c v b n m {⌫} {123} {symbol} {space} {Save} ]
				}
				uppercase {
					return [list Q W E R T Y U I O P A S D F G H J K L {lower} Z X C V B N M {⌫} {123} {symbol} {space} {Save} ]
				}
				number {
					return [list 1 2 3 4 5 6 7 8 9 0 . , {} {} {} {} {} {} {} {lower} {} {} {} {} {} {} {} {⌫} {ABC} {symbol} {space} {Save}]
				}
				symbol {
					return [list ! @ # $ % ^ & * ( ) - + {"} ' : {;} ? _ {/} {lower} "\\" = | < > "{" "}" {⌫} {123} {symbol} {space} {Save}]
				}
			}
		}
	}
}

#
# setup 36 buttons and set them to the selected list
#
proc setup_36buttons {frame buttonList} {

	#Grid out rows and then pack the buttons into the grid rows
	#Default Qwerty Keyboard is 4 rows

	grid [frame $frame.0] -row 0
	grid [frame $frame.1] -row 1
	grid [frame $frame.2] -row 2
	grid [frame $frame.3] -row 3

	set number 1
		for {set column 0} {$column < 10} {incr column} {
			set buttonText [lindex $buttonList [expr {$number - 1}]]
			36key_button $frame 0 $number $buttonText
			incr number
		}
		for {set column 0} {$column < 9} {incr column} {
			set buttonText [lindex $buttonList [expr {$number - 1}]]
			36key_button $frame 1 $number $buttonText
			incr number
		}
		for {set column 0} {$column < 9} {incr column} {
			set buttonText [lindex $buttonList [expr {$number - 1}]]
			36key_button $frame 2 $number $buttonText
			incr number
		}
		for {set column 0} {$column < 4} {incr column} {
			set buttonText [lindex $buttonList [expr {$number - 1}]]
			36key_button $frame 3 $number $buttonText
			incr number
		}
}


#
# change the 36 buttons to the selected list
#
proc change_36buttons {frame buttonType} {
	set buttonList [select_button_list english $buttonType]

	for {set number 1} {$number < 33} {incr number} {
		set buttonText [lindex $buttonList [expr {$number - 1}]]
		if {$number < 11} {set row 0}
		if {$number > 10} {set row 1}
		if {$number > 19} {set row 2}
		if {$number > 28} {set row 3}

		set buttonCommand "36key_press [list $buttonText]"

		switch $buttonText {
			"space" {$frame.$row.$number configure -text $buttonText -command {36key_press " "}}
			"Save" {$frame.$row.$number configure -text $buttonText -command "36key_ok $frame"}
			"⌫" {$frame.$row.$number configure -text "⌫" -command {36key_press "⌫"}}
			"123" {$frame.$row.$number configure -text "123" -command "change_36buttons $frame number"}
			"ABC" {$frame.$row.$number configure -text "ABC" -command "change_36buttons $frame lowercase"}
			"symbol" {$frame.$row.$number configure -text "#+=" -command "change_36buttons $frame symbol"}
			"upper" {$frame.$row.$number configure -text U -command "change_36buttons $frame uppercase"}
			"lower" {$frame.$row.$number configure -text D -command "change_36buttons $frame lowercase"}
			"default" {$frame.$row.$number configure -text $buttonText -command $buttonCommand}
		}
	}
}


#
# button for 36 keypad - define a button for the 36-key keypad
#
proc 36key_button {frame row button number} {
	set buttonCommand "36key_press [list $number]"
	set w $frame.$row

	switch $number {
		"space" {ttk::button $w.$button -text $number -command {36key_press " "} -style FAkey.TButton -width 10}
		"Save" {ttk::button $w.$button -text $number -command "36key_ok $frame" -style FAsavekey.TButton -width 4}
		"⌫" {ttk::button $w.$button -text $number -command $buttonCommand -style FAoptionkey.TButton -width 3}
		"123" {ttk::button $w.$button -text $number -command "change_36buttons $frame number" -style FAoptionkey.TButton -width 3}
		"ABC" {$frame.$row.$number configure -text "ABC" -command "change_36buttons $frame lowercase"}
		"symbol" {ttk::button $w.$button -text "#+=" -command "change_36buttons $frame symbol" -style FAoptionkey.TButton -width 3}
		"upper" {ttk::button $w.$button -image uppercaseIcon -command "change_36buttons $frame uppercase" -style FAoptionkey.TButton -width 3}
		"lower" {ttk::button $w.$button -image uppercaseIcon -command "change_36buttons $frame lowercase" -style FAoptionkey.TButton -width 3}
		"default" {ttk::button $w.$button -text $number -command $buttonCommand -style FAkey.TButton -width 2}
	}
	pack $w.$button -side left -ipadx 2 -ipadx 2

}

#
# setup_keypad_36key - setup a 36-key keypad
# w is the window to put the keypad in
# command is the command to run if save is pushed
#
proc setup_keypad_36key {w command} {
	label $w.36key_window -font KeypadFont -textvariable 36key_buffer -height 1 -padx 5 -pady 5
	set ::36key_buffer ""
	grid $w.36key_window -columnspan 3

	set k $w.keys
	frame $k -background #cfd6dc
	setup_36buttons $k [select_button_list english lowercase]
	grid $k -columnspan 3 -sticky news

	grid columnconfigure $k 0 -weight 1
	grid rowconfigure $k 0 -weight 1

	set ::36keycommand($k) $command
#	puts "::36keycommand($k) $command"
}

#
# 36key_press - handle a keypress from the 36-key keypad
#
proc 36key_press {key} {
	if {$key == "⌫"} {
		set ::36key_buffer [string range $::36key_buffer 0 end-1]
		return
	}
	append ::36key_buffer $key
}

proc 36key_cancel {frame} {
	{*}$::36keycommand($frame) cancel
	unset -nocomplain ::36keycommand($frame)
}

proc 36key_ok {frame} {
#	puts "{*}$::36keycommand($frame) ok $::36key_buffer"
	{*}$::36keycommand($frame) ok $::36key_buffer
	unset -nocomplain ::36keycommand($frame)
}

