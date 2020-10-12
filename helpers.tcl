#
#
#

package require fa_sudo

namespace eval ::stash {
}

#
# logger - log a message
#
proc logger {text} {
       puts stderr "[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%SZ" -gmt 1] $text"
}

proc restart_network {} {
	#::fa_sudo::exec_as -root -- /bin/systemctl --quiet stop ifplugd
	::fa_sudo::exec_as -root -- /bin/systemctl --quiet stop networking
	::fa_sudo::exec_as -root -- /bin/systemctl --quiet restart set-rfkill

	# Work around to be able to turn off Wifi via FF GUI. generate-network-config will re-create it if
	# wireless-network config setting says to do so. This will be properly fixed in piaware-support
	::fa_sudo::exec_as -root -- rm -f /etc/wpa_supplicant/wpa_supplicant.conf

	::fa_sudo::exec_as -root -- /bin/systemctl --quiet restart generate-network-config
	::fa_sudo::exec_as -root -- /bin/systemctl --quiet daemon-reload
	::fa_sudo::exec_as -root -- /bin/systemctl --quiet restart dhcpcd
	::fa_sudo::exec_as -root -- /bin/systemctl --quiet restart rsyslog

	::fa_sudo::exec_as -root -- /bin/systemctl --quiet start networking
	#::fa_sudo::exec_as -root -- /bin/systemctl --quiet start ifplugd

}
#
# fullscreen - resize the wish top-level window to be full screen
#
proc fullscreen {w} {
    wm geometry $w $::fullscreenGeometry
}

# set the target top-level window size
proc size_screen {width height} {
	set ::fullscreenGeometry "${width}x${height}"
	set ::fullscreenHeight $height
	set ::fullscreenWidth $width
	if {$width == [winfo screenwidth .] && $height == [winfo screenheight .]} {
		append ::fullscreenGeometry "+0+0"
		set ::cursorStyle none
	} else {
		set ::cursorStyle arrow
	}

	fullscreen .
}

#
# comma - comma-separate a number, like 1234 becomes 1,234
#
proc comma {number} {
    while {[regsub {^([-+]?\d+)(\d{3})} $number {\1,\2} number]} {}
    return $number
}

#
# prompt_user_for_shutdown - prompts user for whether they want to shut down the
# flight feeder (after the main display program is stopped), shuts down if yes,
# does nothing otherwise.

proc prompt_user_for_shutdown {} {
	while 1 {
		puts -nonewline "\nWould you like to shut down the flight feeder (y/N)?"
		#flush stdout
		set response [ gets stdin ]
		if {[ regexp -nocase {^y} $response ]} {
			puts "okay, we're shutting down now."
			::fa_sudo::exec_as -root -- /sbin/shutdown -P
		} elseif {[ regexp -nocase {^n} $response ]} {
			exit 0
            break
		}
	}
}

# wifi_scan - return a list of wireless accesspoints ordered by highest quality connection
proc wifi_scan {interface} {
	set ssidList ""

	# interface must be up for scanning to work
	try {
		::fa_sudo::exec_as -root -- /bin/ip link set dev $interface up
	} on error {result} {
		puts stderr "caught '$result' running ip link set"
		return ""
	}

	set wifiScan [::fa_sudo::open_as -root "|iwlist $interface scan"]
	try {
		while {[gets $wifiScan line] >= 0} {
			if {[regexp {Cell \d+ - Address: ([0-9a-fA-F:]+)} $line -> newaddress]} {
				if {[info exists ssid] && [info exists address]} {
					if {[info exists quality]} {
						lappend ssidList [list $ssid $address $quality]
					} else {
						lappend ssidList [list $ssid $address 0]
					}
				}
				unset -nocomplain quality
				unset -nocomplain ssid
				set address $newaddress
			} elseif {[regexp {Quality=(\d+)} $line -> quality]} {
				# ok
			} elseif {[regexp {ESSID:"(.+)"} $line -> ssid]} {
				# ok
			}
		}

		# last cell
		if {[info exists ssid] && [info exist quality] && [info exists address]} {
			lappend ssidList [list $ssid $address $quality]
		}

		return [lsort -integer -decreasing -index 2 $ssidList]
	} on error {result} {
		puts stderr "caught '$result' running wifi scan"
		return ""
	} finally {
		catch {close $wifiscan}
	}
}


#
# bgerror - write errors to the stderr instead of to the screen
#
proc bgerror {error} {
	puts stderr "GUI error : $error"
}

set ::countryDict [dict create {Afghanistan} AF	\
{Åland Islands}	AX	\
{Albania}	AL	\
{Algeria}	DZ	\
{American Samoa}	AS	\
{Andorra}	AD	\
{Angola}	AO	\
{Anguilla}	AI	\
{Antarctica}	AQ	\
{Antigua and Barbuda}	AG	\
{Argentina}	AR	\
{Armenia}	AM	\
{Aruba}	AW	\
{Australia}	AU	\
{Austria}	AT	\
{Azerbaijan}	AZ	\
{Bahamas}	BS	\
{Bahrain}	BH	\
{Bangladesh}	BD	\
{Barbados}	BB	\
{Belarus}	BY	\
{Belgium}	BE	\
{Belize}	BZ	\
{Benin}	BJ	\
{Bermuda}	BM	\
{Bhutan}	BT	\
{Bolivia, Plurinational State of}	BO	\
{Bonaire, Sint Eustatius and Saba}	BQ	\
{Bosnia and Herzegovina}	BA	\
{Botswana}	BW	\
{Bouvet Island}	BV	\
{Brazil}	BR	\
{British Indian Ocean Territory}	IO	\
{Brunei Darussalam}	BN	\
{Bulgaria}	BG	\
{Burkina Faso}	BF	\
{Burundi}	BI	\
{Cabo Verde}	CV	\
{Cambodia}	KH	\
{Cameroon}	CM	\
{Canada}	CA	\
{Cayman Islands}	KY	\
{Central African Republic}	CF	\
{Chad}	TD	\
{Chile}	CL	\
{China}	CN	\
{Christmas Island}	CX	\
{Cocos (Keeling) Islands}	CC	\
{Colombia}	CO	\
{Comoros}	KM	\
{Congo}	CG	\
{Congo, the Democratic Republic of the}	CD	\
{Cook Islands}	CK	\
{Costa Rica}	CR	\
{Côte d'Ivoire}	CI	\
{Croatia}	HR	\
{Cuba}	CU	\
{Curaçao}	CW	\
{Cyprus}	CY	\
{Czechia}	CZ	\
{Denmark}	DK	\
{Djibouti}	DJ	\
{Dominica}	DM	\
{Dominican Republic}	DO	\
{Ecuador}	EC	\
{Egypt}	EG	\
{El Salvador}	SV	\
{Equatorial Guinea}	GQ	\
{Eritrea}	ER	\
{Estonia}	EE	\
{Eswatini}	SZ	\
{Ethiopia}	ET	\
{Falkland Islands (Malvinas)}	FK	\
{Faroe Islands}	FO	\
{Fiji}	FJ	\
{Finland}	FI	\
{France}	FR	\
{French Guiana}	GF	\
{French Polynesia}	PF	\
{French Southern Territories}	TF	\
{Gabon}	GA	\
{Gambia}	GM	\
{Georgia}	GE	\
{Germany}	DE	\
{Ghana}	GH	\
{Gibraltar}	GI	\
{Greece}	GR	\
{Greenland}	GL	\
{Grenada}	GD	\
{Guadeloupe}	GP	\
{Guam}	GU	\
{Guatemala}	GT	\
{Guernsey}	GG	\
{Guinea}	GN	\
{Guinea-Bissau}	GW	\
{Guyana}	GY	\
{Haiti}	HT	\
{Heard Island and McDonald Islands}	HM	\
{Holy See}	VA	\
{Honduras}	HN	\
{Hong Kong}	HK	\
{Hungary}	HU	\
{Iceland}	IS	\
{India}	IN	\
{Indonesia}	ID	\
{Iran, Islamic Republic of}	IR	\
{Iraq}	IQ	\
{Ireland}	IE	\
{Isle of Man}	IM	\
{Israel}	IL	\
{Italy}	IT	\
{Jamaica}	JM	\
{Japan}	JP	\
{Jersey}	JE	\
{Jordan}	JO	\
{Kazakhstan}	KZ	\
{Kenya}	KE	\
{Kiribati}	KI	\
{Korea, Democratic People's Republic of}	KP	\
{Korea, Republic of}	KR	\
{Kuwait}	KW	\
{Kyrgyzstan}	KG	\
{Lao People's Democratic Republic}	LA	\
{Latvia}	LV	\
{Lebanon}	LB	\
{Lesotho}	LS	\
{Liberia}	LR	\
{Libya}	LY	\
{Liechtenstein}	LI	\
{Lithuania}	LT	\
{Luxembourg}	LU	\
{Macao}	MO	\
{Macedonia, the former Yugoslav Republic of}	MK	\
{Madagascar}	MG	\
{Malawi}	MW	\
{Malaysia}	MY	\
{Maldives}	MV	\
{Mali}	ML	\
{Malta}	MT	\
{Marshall Islands}	MH	\
{Martinique}	MQ	\
{Mauritania}	MR	\
{Mauritius}	MU	\
{Mayotte}	YT	\
{Mexico}	MX	\
{Micronesia, Federated States of}	FM	\
{Moldova, Republic of}	MD	\
{Monaco}	MC	\
{Mongolia}	MN	\
{Montenegro}	ME	\
{Montserrat}	MS	\
{Morocco}	MA	\
{Mozambique}	MZ	\
{Myanmar}	MM	\
{Namibia}	NA	\
{Nauru}	NR	\
{Nepal}	NP	\
{Netherlands}	NL	\
{New Caledonia}	NC	\
{New Zealand}	NZ	\
{Nicaragua}	NI	\
{Niger}	NE	\
{Nigeria}	NG	\
{Niue}	NU	\
{Norfolk Island}	NF	\
{Northern Mariana Islands}	MP	\
{Norway}	NO	\
{Oman}	OM	\
{Pakistan}	PK	\
{Palau}	PW	\
{Palestine, State of}	PS	\
{Panama}	PA	\
{Papua New Guinea}	PG	\
{Paraguay}	PY	\
{Peru}	PE	\
{Philippines}	PH	\
{Pitcairn}	PN	\
{Poland}	PL	\
{Portugal}	PT	\
{Puerto Rico}	PR	\
{Qatar}	QA	\
{Réunion}	RE	\
{Romania}	RO	\
{Russian Federation}	RU	\
{Rwanda}	RW	\
{Saint Barthélemy}	BL	\
{Saint Helena, Ascension and Tristan da Cunha}	SH	\
{Saint Kitts and Nevis}	KN	\
{Saint Lucia}	LC	\
{Saint Martin (French part)}	MF	\
{Saint Pierre and Miquelon}	PM	\
{Saint Vincent and the Grenadines}	VC	\
{Samoa}	WS	\
{San Marino}	SM	\
{Sao Tome and Principe}	ST	\
{Saudi Arabia}	SA	\
{Senegal}	SN	\
{Serbia}	RS	\
{Seychelles}	SC	\
{Sierra Leone}	SL	\
{Singapore}	SG	\
{Sint Maarten (Dutch part)}	SX	\
{Slovakia}	SK	\
{Slovenia}	SI	\
{Solomon Islands}	SB	\
{Somalia}	SO	\
{South Africa}	ZA	\
{South Georgia and the South Sandwich Islands}	GS	\
{South Sudan}	SS	\
{Spain}	ES	\
{Sri Lanka}	LK	\
{Sudan}	SD	\
{Suriname}	SR	\
{Svalbard and Jan Mayen}	SJ	\
{Sweden}	SE	\
{Switzerland}	CH	\
{Syrian Arab Republic}	SY	\
{Taiwan, Province of China}	TW	\
{Tajikistan}	TJ	\
{Tanzania, United Republic of}	TZ	\
{Thailand}	TH	\
{Timor-Leste}	TL	\
{Togo}	TG	\
{Tokelau}	TK	\
{Tonga}	TO	\
{Trinidad and Tobago}	TT	\
{Tunisia}	TN	\
{Turkey}	TR	\
{Turkmenistan}	TM	\
{Turks and Caicos Islands}	TC	\
{Tuvalu}	TV	\
{Uganda}	UG	\
{Ukraine}	UA	\
{United Arab Emirates}	AE	\
{United Kingdom of Great Britain and Northern Ireland}	GB	\
{United States Minor Outlying Islands}	UM	\
{United States of America}	US	\
{Uruguay}	UY	\
{Uzbekistan}	UZ	\
{Vanuatu}	VU	\
{Venezuela, Bolivarian Republic of}	VE	\
{Viet Nam}	VN	\
{Virgin Islands, British}	VG	\
{Virgin Islands, U.S.}	VI	\
{Wallis and Futuna}	WF	\
{Western Sahara}	EH	\
{Yemen}	YE	\
{Zambia}	ZM	\
{Zimbabwe}	ZW	]


proc detect_hardware {} {
	if {![info exists ::hardware]} {
		set ::hardware {}
		catch {lappend ::hardware {*}[machine_architecture]}
		catch {lappend ::hardware {*}[detect_pi_revision]}
		catch {lappend ::hardware {*}[detect_usb_devices]}
		catch {lappend ::hardware {*}[detect_display]}
	}

	return $::hardware
}

# detect machine architecture via uname
proc machine_architecture {} {
	try {
		return [list [::fa_sudo::exec_as -- uname -m]]
	} on error {result} {
		return ""
	}
}

# detect Pi hardware based on contents of /proc/cpuinfo
# see http://elinux.org/RPi_HardwareHistory#Board_Revision_History
variable rpi_by_revision
array set rpi_by_revision {
	0002 rpi_1b
	0003 rpi_1b
	0004 rpi_1b
	0005 rpi_1b
	0006 rpi_1b

	0007 rpi_1a
	0008 rpi_1a
	0009 rpi_1a

	000d rpi_1b
	000e rpi_1b
	000f rpi_1b

	0010 rpi_1bplus
	0011 rpi_compute
	0012 rpi_1aplus

	0013 rpi_1bplus
	0014 rpi_compute
	0015 rpi_1aplus

	a01041 rpi_2b
	a21041 rpi_2b

	900092 rpi_zero
	900093 rpi_zero

	a02082 rpi_3b
	a22082 rpi_3b
}

proc detect_pi_revision {} {
	variable rpi_by_revision

	set f [open "/proc/cpuinfo" "r"]
	try {
		while {[gets $f line] >= 0} {
			if {[regexp {^Revision\s*:\s*(?:1000)?([0-9a-fA-F]+)} $line -> match]} {
				set revision $match
			}
		}
	} finally {
		catch {close $f}
	}

	if {![info exists revision]} {
		# not a Pi?
		return ""
	}

	if {[info exists rpi_by_revision($revision)]} {
		return [list $rpi_by_revision($revision) "rpi_${revision}"]
	} else {
		# we don't grok the revision
		return [list "rpi_unknown" "rpi_${revision}"]
	}
}

variable usb_by_id
array set usb_by_id {
	"0bda:2832" "rtlsdr"
	"0bda:2838" "rtlsdr"
}

variable usb_by_product
array set usb_by_product {
	"bladeRF" "bladerf"
	"Mode-S Beast GPS" "beastgps"
	"Mode-S Beast" "beast"
}

# detect USB connected receivers
# we do this directly in /sys rather than using lsusb
# as lsusb won't give us the product strings unless
# running as root
proc detect_usb_devices {} {
	set result ""

	variable usb_by_id
	variable usb_by_product

	foreach pf [glob -nocomplain "/sys/bus/usb/devices/*"] {
		if {![file readable "$pf/idVendor"] || ![file readable "$pf/idProduct"]} {
			# not a device
			continue
		}

		set f [open "$pf/idVendor" "r"]
		try {
			gets $f idVendor
		} finally {
			catch {close $f}
		}

		set f [open "$pf/idProduct" "r"]
		try {
			gets $f idProduct
		} finally {
			catch {close $f}
		}

		if {[info exists usb_by_id($idVendor:$idProduct)]} {
			lappend result $usb_by_id($idVendor:$idProduct)
			continue
		}

		if {[file readable "$pf/product"]} {
			set f [open "$pf/product" "r"]
			try {
				gets $f product
			} finally {
				catch {close $f}
			}

			if {[info exists usb_by_product($product)]} {
				lappend result $usb_by_product($product)
			}
		}
	}

	return $result
}

proc detect_display {} {
	set sysfsPath "/sys/class/graphics/fb1/device/of_node/name"
	set result ""

	if {[file exists $sysfsPath]} {
		set f [open $sysfsPath "r"]
		try {
			gets $f dtName
			set dtName [string trimright $dtName "\0"]   ;# strip trailing NUL
		} finally {
			catch {close $f}
		}

		if {$dtName ne ""} {
			lappend result "lcd_$dtName"
		}
	}

	return $result
}

#
# sshd_is_up - return 1 if sshd is active, else 0
#
proc sshd_is_up {} {
	set active 1
	set fp [open "|service ssh status"]
	while {[gets $fp line] >= 0} {
		if {[string match "*inactive*" $line]} {
			set active 0
			break
		}
	}
	close $fp
	return $active
}

#
# is_generating_ssh_keys - return 1 if ssh is currently generating ssh keys, else 0
#
proc is_generating_ssh_keys {} {
	try {
		set fp [open /var/log/regen_ssh_keys.log]
	} trap {POSIX ENOENT} {} {
		return 0
	}

	set generating 1
	while {[gets $fp line] >= 0} {
		if {[string match "finished*" $line]} {
			set generating 0
			break
		}
	}
	close $fp
	return $generating
}

#
# enable_sshd - turn on sshd to allow remote login via ssh
#
proc enable_sshd {} {
	while {[is_generating_ssh_keys]} {
		puts "ssh keys still generating, waiting..."
		sleep 5
	}

	if {[sshd_is_up]} {
		return
	}

	::fa_sudo::exec_as -root -- ssh-keygen -A
	::fa_sudo::exec_as -root -- update-rc.d ssh enable
	::fa_sudo::exec_as -root -- invoke-rc.d ssh start
}

#
# disable_ssh - turn off sshd to disable remote login via ssh
#
proc disable_ssh {} {
	::fa_sudo::exec_as -root -- update-rc.d ssh disable
	::fa_sudo::exec_as -root -- invoke-rc.d ssh stop
}

# vim: set ts=4 sw=4 sts=4 noet :
