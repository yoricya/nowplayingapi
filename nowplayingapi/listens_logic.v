module main

struct ListenNow {
mut:
	is_playing  bool
	name        string
	author      string
	album_image ?string
	album_name  ?string

	service_name  string = 'default'
	activity_type ?int

	start_timestamp_on_server     i64 @[skip]
	start_timestamp_on_server_str string

	start_timestamp string
	end_timestamp   ?string

	is_live_broadcast bool

	track_url ?string
}

pub fn (mut l ListenNow) reset() {
	l.is_playing = false
	l.name = ''
	l.author = ''
	l.album_image = none
	l.album_name = none
	l.start_timestamp = ''
	l.end_timestamp = none
	l.is_live_broadcast = false
	l.track_url = none
	l.activity_type = none

	l.service_name = 'default'

	l.start_timestamp_on_server_str = ''
	l.start_timestamp_on_server = 0
}

pub fn (mut l ListenNow) cp_from(src ListenNow) {
	l.is_playing = src.is_playing

	l.name = src.name
	l.author = src.author
	l.start_timestamp = src.start_timestamp

	l.end_timestamp = if (src.end_timestamp or { '' }) == '' { none } else { src.end_timestamp }

	l.is_live_broadcast = src.is_live_broadcast
	l.service_name = src.service_name

	l.start_timestamp_on_server_str = src.start_timestamp_on_server_str
	l.start_timestamp_on_server = src.start_timestamp_on_server

	l.album_image = if (src.album_image or { '' }) == '' { none } else { src.album_image }
	l.album_name = if (src.album_name or { '' }) == '' { none } else { src.album_name }

	l.track_url = if (src.track_url or { '' }) == '' { none } else { src.track_url }

	l.activity_type = src.activity_type
}
