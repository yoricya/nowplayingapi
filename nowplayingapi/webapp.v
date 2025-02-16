module main

import veb
import sync
import crypto.sha256
import time

pub struct WebApp {
	veb.Middleware[WebCtx]
pub:
	is_using_cloudflare bool
	redirect_main_page_to string
pub mut:
	cached_listen_now_rwmutex &sync.RwMutex
	cached_listen_now         map[string]?&ListenNow

	// no_ddos_cache_rwmutex &sync.RwMutex
	// no_ddos_cache         map[string]?&Anti_ddos_Context
}

fn (mut app WebApp) get_listen_now_obj(token string) ?&ListenNow {
	if token.len < sha256.block_size {
		return none
	}

	app.cached_listen_now_rwmutex.rlock()
	mut listen_now := unsafe { app.cached_listen_now[token] }
	app.cached_listen_now_rwmutex.runlock()

	return listen_now
}

fn (mut app WebApp) create_listen_now_obj(token string) ?&ListenNow {
	if token.len < sha256.block_size {
		return none
	}

	mut listen_now := &ListenNow{}

	app.cached_listen_now_rwmutex.lock()
	app.cached_listen_now[token] = listen_now
	app.cached_listen_now_rwmutex.unlock()

	return listen_now
}



// __________________ Web API Entry Points __________________

@['/']
fn (mut app WebApp) web_main(mut ctx WebCtx) veb.Result {
	if !ctx.has_allow_access {
		return ctx.create_message_response(.forbidden, 'Forbidden')
	}

	return ctx.redirect(app.redirect_main_page_to, veb.RedirectParams{typ: .temporary_redirect})
}

@['/generate']
fn (mut app WebApp) api_generate(mut ctx WebCtx) veb.Result {
	if !ctx.has_allow_access {
		return ctx.create_message_response(.forbidden, 'Forbidden')
	}

	key := gen_key()

	token := key_to_token(key) or {
		return ctx.create_message_response(.internal_server_error, 'Internal error')
	}

	ctx.content_type = "application/json"
	return ctx.text('{\n"key": "${key}",\n"token": "${token}"\n}')
}

@['/key/:key']
fn (mut app WebApp) api_key_key(mut ctx WebCtx, key string) veb.Result {
	if !ctx.has_allow_access {
		return ctx.create_message_response(.forbidden, 'Forbidden')
	}

	token := key_to_token(key) or { return ctx.create_message_response(.bad_request, err.str()) }

	ctx.content_type = "application/json"
	return ctx.text('{\n"key": "${key}",\n"token": "${token}"\n}')
}

@['/get/:token']
fn (mut app WebApp) api_get_token(mut ctx WebCtx, token string) veb.Result {
	if !ctx.has_allow_access {
		return ctx.create_message_response(.forbidden, 'Forbidden')
	}

	mut ln_obj := app.get_listen_now_obj(token) or {
		return ctx.create_message_response(.not_found, 'Token not found')
	}

	srv_time_now := time.now().unix_milli()

	st := ln_obj.start_timestamp.i64()
	client_time_now := srv_time_now - (ln_obj.start_timestamp_on_server - st)

	if !ln_obj.is_live_broadcast {

		en := (ln_obj.end_timestamp or {
			"0"
		}).i64()

		if client_time_now > en {
			ln_obj.reset()
		}

	} else if ln_obj.start_timestamp_on_server - srv_time_now > (1000 * 60 * 60 * 2) { // Если на протяжении 2х часов не было активности - сбрасываем трансляцию
		ln_obj.reset()
	}

	return ctx.json[&ListenNow](ln_obj)
}

@['/set/:key']
fn (mut app WebApp) api_set_by_key(mut ctx WebCtx, key string) veb.Result {
	if !ctx.has_allow_access {
		return ctx.create_message_response(.forbidden, 'Forbidden')
	}


	token := key_to_token(key) or { return ctx.create_message_response(.bad_request, err.str()) }
	mut src_obj := app.get_listen_now_obj(token) or {
		app.create_listen_now_obj(token) or {
			return ctx.create_message_response(.internal_server_error, 'Internal error')
		}
	}


	ctx.content_type = "application/json"

	if ctx.query.len == 0 {
		src_obj.reset()
		return ctx.create_message_response(.ok, 'reset')
	}


	// name field
	tmp_name := (ctx.query['name']).trim_space()
	if tmp_name == '' {
		return ctx.create_message_response(.bad_request, "'name' field not found")
	}

	if tmp_name.len > 256 {
		return ctx.create_message_response(.bad_request, "'name' field too long")
	}


	// author field
	tmp_author := (ctx.query['author']).trim_space()
	if tmp_author == '' {
		return ctx.create_message_response(.bad_request, "'author' field not found")
	}

	if tmp_author.len > 256 {
		return ctx.create_message_response(.bad_request, "'author' field too long")
	}


	// start_timestamp field
	tmp_start_timestamp := (ctx.query['start_timestamp']).trim_space()
	if tmp_start_timestamp == '' {
		return ctx.create_message_response(.bad_request, "'start_timestamp' field not found")
	}

	if !tmp_start_timestamp.is_int() {
		return ctx.create_message_response(.bad_request, "'start_timestamp' field not a number")
	}


	// _________ Optional fields _________


	// init is_live_broadcast field
	mut tmp_is_live_broadcast := false


	// end_timestamp field
	tmp_end_timestamp := (ctx.query['end_timestamp']).trim_space()
	if tmp_end_timestamp == '' {
		tmp_is_live_broadcast = true
	}

	if !tmp_is_live_broadcast && !tmp_end_timestamp.is_int() {
		return ctx.create_message_response(.bad_request, "'end_timestamp' field not a number")
	}


	// Check timestamps range
	if !tmp_is_live_broadcast && tmp_end_timestamp.i64() <= tmp_start_timestamp.i64() {
		return ctx.create_message_response(.bad_request, 'Illegal timestamps range')
	}


	// track_url field
	tmp_track_url := (ctx.query['track_url']).trim_space()
	if tmp_track_url.len > 384 {
		return ctx.create_message_response(.bad_request, "'track_url' field too long")
	}

	if tmp_track_url != '' && !tmp_track_url.starts_with("http://") && !tmp_track_url.starts_with("https://")  {
		return ctx.create_message_response(.bad_request, "Illegal data in 'track_url'")
	}


	// album_image field
	tmp_album_image := (ctx.query['album_image']).trim_space()
	if tmp_album_image.len > 384 {
		return ctx.create_message_response(.bad_request, "'album_image' field too long")
	}

	if tmp_album_image != '' && !tmp_album_image.starts_with("http://") && !tmp_album_image.starts_with("https://")  {
		return ctx.create_message_response(.bad_request, "Illegal data in 'track_url'")
	}


	// album_name field
	tmp_album_name := (ctx.query['album_name']).trim_space()
	if tmp_album_name.len > 256 {
		return ctx.create_message_response(.bad_request, "'album_name' field too long")
	}


	// service_name field
	tmp_service_name := (ctx.query['service_name'] or {"default"}).trim_space()
	if tmp_service_name.len > 16 {
		return ctx.create_message_response(.bad_request, "'service_name' field too long")
	}


	// activity_type field
	tmp_activity_type_str := (ctx.query['activity_type']).trim_space()
	if tmp_activity_type_str != "" && !tmp_activity_type_str.is_int() {
		return ctx.create_message_response(.bad_request, "'activity_type' must be integer")
	}


	// Server timestamp
	server_start_timestamp := time.now().unix_milli()


	// ___ Put data to src ____

	src_obj.is_playing = true

	src_obj.name = tmp_name
	src_obj.author = tmp_author
	src_obj.start_timestamp = tmp_start_timestamp

	src_obj.end_timestamp = if tmp_is_live_broadcast {
		none
	} else {
		tmp_end_timestamp
	}

	src_obj.is_live_broadcast = tmp_is_live_broadcast

	src_obj.start_timestamp_on_server = server_start_timestamp
	src_obj.start_timestamp_on_server_str = server_start_timestamp.str()

	src_obj.track_url = if tmp_track_url == '' {none} else {tmp_track_url}
	src_obj.album_image = if tmp_album_image == '' {none} else {tmp_album_image}
	src_obj.album_name = if tmp_album_name == '' {none} else {tmp_album_name}
	src_obj.activity_type = if tmp_activity_type_str == '' {none} else {tmp_activity_type_str.int()}

	src_obj.service_name = tmp_service_name

	return ctx.create_message_response(.ok, 'ok')
}
