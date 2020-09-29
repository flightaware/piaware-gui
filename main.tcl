#
# piaware gui - wish program that runs on piaware to put some
#   Tk graphical stuff on the HDMI port
#

if {[info exists launchdir]} {
    cd $launchdir
}

# set scriptdir to the load all the local scripts
set scriptdir [file dirname [info script]]

package require Tk
package require cmdline
package require fa_piaware_config

source [file join $scriptdir "helpers.tcl"]
source [file join $scriptdir "grid.tcl"]
source [file join $scriptdir "indicators.tcl"]
source [file join $scriptdir "status.tcl"]
source [file join $scriptdir "json.tcl"]
source [file join $scriptdir "fa_tailer.tcl"]
source [file join $scriptdir "radio.tcl"]
source [file join $scriptdir "keyboard.tcl"]
source [file join $scriptdir "ipconfig.tcl"]

# Load touch screen interface (3.2" LCD, 320x240)
proc setup_tft_32 {} {
	size_screen 320 240
	set ::cursorStyle none
	setup_font_common
	setup_font_32tft
	setup_main

	#Wait for the GUI to load and then move mouse pointer out of the way to prevent button mouseover
	after 800 "event generate . <Motion> -warp 1 -x 0 -y 100"
}

# Load touch screen interface (3.5" LCD, 480x320)
proc setup_tft_35 {} {
	size_screen 480 320
	set ::cursorStyle none
	setup_font_common
	setup_font_35tft
	setup_main
}

# Load HDMI screen interface
proc setup_hdmi {} {
	size_screen 1024 768
	set ::cursorStyle arrow
	setup_font_common
	setup_font_hdmi
	setup_main
}


# Init all the things
proc setup_screen {type} {
	tk_setPalette white

	if {$type eq "auto"} {
		set dimensions "[winfo screenwidth .]x[winfo screenheight .]"
		switch -- $dimensions {
			320x240 { set type "touch_32" }
			480x320 { set type "touch_35" }
			default { set type "hdmi" }
		}
	}

	switch -- $type {			
		touch_32 { setup_tft_32 }
		touch_35 { setup_tft_35 }
		hdmi     { setup_hdmi }
		default {
			error "unrecognized display type '$type'"
		}
	}

	configure_statics
	load_piaware_config
	init_transfer_statistics
	periodically_update_transfer_statistics
	periodically_update_piaware_status
	periodically_update_network_status
	periodically_update_time

	# Pop-up/Splash screen support
	#after 500 periodically_read_notify_file
}

#
# main - the main program
#
proc main {{argv ""}} {
	set opts {
		{display.arg ":0.0" "Specify the display to output. Default :0.0"}
		{type.arg "auto" "Specify the display type as auto, hdmi, touch_32, touch_35. Default auto."}
	}

	set usage ": $::argv0 ?-display? ?-type?"

	if {[catch {array set params [::cmdline::getoptions argv $opts $usage]} catchResult] == 1} {
		puts stderr $catchResult
		exit 1
	}

	set ::basedirectory [file dirname [info script]]
	set ::lang english

	#initial load of the config files.
	::fa_piaware_config::new_combined_config piawareConfig
	piawareConfig read_config

	detect_hardware
	detect_mode
	setup_screen $params(type)
}


if {!$tcl_interactive} {
	main $argv
}

# vim: set ts=4 sw=4 sts=4 noet :
