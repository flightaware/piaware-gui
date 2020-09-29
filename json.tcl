package require json

proc read_json {path} {
	try {
		set fp [open $path r]
		set json [read $fp]
	} finally {
		catch {close $fp}
	}

	return [::json::json2dict $json]
}
