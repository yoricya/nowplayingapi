module main

struct ListenNow {
mut:
	is_playing  bool
	name        string
	author      string
	album_image ?string
	album_name  ?string

	service_name string = 'default'

	start_timestamp_on_server     i64 @[skip]
	start_timestamp_on_server_str string

	start_timestamp string
	end_timestamp   string

	track_url ?string
}

pub fn (mut l ListenNow) reset() {
	l.is_playing = false
	l.name = ''
	l.author = ''
	l.album_image = none
	l.album_name = none
	l.start_timestamp = ''
	l.end_timestamp = ''
	l.track_url = none

	l.service_name = 'default'

	l.start_timestamp_on_server_str = ''
	l.start_timestamp_on_server = 0
}

pub fn (mut l ListenNow) cp_from(src ListenNow) {
	l.is_playing = src.is_playing

	l.name = src.name
	l.author = src.author
	l.start_timestamp = src.start_timestamp
	l.end_timestamp = src.end_timestamp
	l.service_name = src.service_name

	l.start_timestamp_on_server_str = src.start_timestamp_on_server_str
	l.start_timestamp_on_server = src.start_timestamp_on_server

	l.album_image = if (src.album_image or { '' }) == '' { none } else { src.album_image }
	l.album_name = if (src.album_name or { '' }) == '' { none } else { src.album_name }

	l.track_url = if (src.track_url or { '' }) == '' { none } else { src.track_url }
}
