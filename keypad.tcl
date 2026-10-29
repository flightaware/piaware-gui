#
#
#

#
# 10key_button - define a button for the 10-key keypad
#
proc 10key_button {w button number row column {style "FAnumkey.TButton"}} {
	#puts "10key_button $w $number $row $column"
	ttk::button $w.$button -text $number -command "10key_press $number" -style $style -width 4
	grid $w.$button -row $row -column $column
}

#
# 10key_action - define action button for the 10-key keypad
#
proc 10key_action {w button action row column id {style FAgrey.TButton}} {
	ttk::button $w.$button -text $action -command "10key_action_press $action $id" -style $style -width 4
	grid $w.$button -row $row -column $column
}

#
# setup_keypad_10key - setup a 10-key keypad to modify an ip_entry object with the supplied id 
#
proc setup_keypad_10key {w id} {
	label $w.10key_window -font KeypadFont -textvariable 10key_buffer -height 1 -padx 5 -pady 5
	grid $w.10key_window -columnspan 4
	set ::10key_buffer ""

	set k $w.keys
	frame $k -background white

	10key_button $k 1 1 0 0
	10key_button $k 2 2 0 1
	10key_button $k 3 3 0 2
#	10key_button $k "" "" 0 0
	10key_button $k 4 4 1 0
	10key_button $k 5 5 1 1
	10key_button $k 6 6 1 2
#	10key_button $k "" "" 0 0
	10key_button $k 7 7 2 0
	10key_button $k 8 8 2 1
	10key_button $k 9 9 2 2
	10key_action $k clear Clear 2 3 $id FAgrey.TButton
	10key_button $k dot . 3 0 FAgrey.TButton
	10key_button $k 0 0 3 1
	10key_button $k < < 3 2 FAgrey.TButton
	10key_action $k ok OK 3 3 $id FAsavekey.TButton

	grid $k
}

#
# 10key_press - handle a keypress from the 10-key keypad
#
proc 10key_press {key} {
	if {$key == "<"} {
		set ::10key_buffer [string range $::10key_buffer 0 end-1]
		return
	}
	append ::10key_buffer $key
}

#
# 10key_action - handle action presses from the 10-key keypad
#
proc 10key_action_press {key id} {
	switch $key {
		Clear {
			set ::10key_buffer ""
		}
		OK {
			$id store $::10key_buffer
			destroy .keypad
		}
	}
}

#frame .f
#setup_keypad_10key .f
#pack .f -fill x -fill y

# vim: set ts=4 sw=4 sts=4 noet :