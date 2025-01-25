module main

struct ListenNow {
mut:
	is_playing bool
	name string
	author string
	album_image ?string
	album_name ?string

	service_name string = "default"

	start_timestamp_on_server i64 @[skip]
	start_timestamp_on_server_str string

	start_timestamp string
	end_timestamp string

	track_url ?string
}

pub fn (mut l ListenNow) reset()  {
	l.is_playing = false
	l.name = ""
	l.author = ""
	l.album_image = none
	l.album_name = none
	l.start_timestamp = ""
	l.end_timestamp = ""
	l.track_url = none

	l.service_name = "default"

	l.start_timestamp_on_server_str = ""
	l.start_timestamp_on_server = 0
}
