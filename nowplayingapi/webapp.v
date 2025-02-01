module main

import veb
import sync
import crypto.sha256
import time

pub struct WebApp {
	veb.Middleware[WebCtx]
pub:
	is_using_cloudflare bool
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

@['/generate']
fn (mut app WebApp) web_generate(mut ctx WebCtx) veb.Result {
	if !ctx.has_allow_access {
		return ctx.create_message_response(.forbidden, 'Forbidden')
	}

	key := gen_key()

	token := key_to_token(key) or {
		return ctx.create_message_response(.internal_server_error, 'Internal error')
	}

	return ctx.text('{\n"key": "${key}",\n"token": "${token}"\n}')
}

@['/key/:key']
fn (mut app WebApp) web_key_key(mut ctx WebCtx, key string) veb.Result {
	if !ctx.has_allow_access {
		return ctx.create_message_response(.forbidden, 'Forbidden')
	}

	token := key_to_token(key) or { return ctx.create_message_response(.bad_request, err.str()) }

	return ctx.text('{\n"key": "${key}",\n"token": "${token}"\n}')
}

@['/get/:token']
fn (mut app WebApp) web_get_token(mut ctx WebCtx, token string) veb.Result {
	if !ctx.has_allow_access {
		return ctx.create_message_response(.forbidden, 'Forbidden')
	}

	mut ln_obj := app.get_listen_now_obj(token) or {
		return ctx.create_message_response(.not_found, 'Token not found')
	}

	st := ln_obj.start_timestamp.i64()
	client_time_now := time.now().unix_milli() - (ln_obj.start_timestamp_on_server - st)

	en := ln_obj.end_timestamp.i64()
	if client_time_now > en {
		ln_obj.reset()
	}

	return ctx.json[&ListenNow](ln_obj)
}

@['/set/:key']
fn (mut app WebApp) web_set_by_key(mut ctx WebCtx, key string) veb.Result {
	if !ctx.has_allow_access {
		return ctx.create_message_response(.forbidden, 'Forbidden')
	}

	token := key_to_token(key) or { return ctx.create_message_response(.bad_request, err.str()) }

	mut ln_obj := app.get_listen_now_obj(token) or {
		app.create_listen_now_obj(token) or {
			return ctx.create_message_response(.internal_server_error, 'Internal error')
		}
	}

	if ctx.query.len == 0 {
		ln_obj.reset()
		return ctx.create_message_response(.ok, 'reset')
	}

	name := (ctx.query['name']).trim_space()
	if name == '' {
		return ctx.create_message_response(.bad_request, "'name' field not found")
	}

	if name.len > 64 {
		return ctx.create_message_response(.bad_request, "'name' field too long")
	}

	author := (ctx.query['author']).trim_space()
	if author == '' {
		return ctx.create_message_response(.bad_request, "'author' field not found")
	}

	if author.len > 64 {
		return ctx.create_message_response(.bad_request, "'author' field too long")
	}

	start_timestamp := (ctx.query['start_timestamp']).trim_space()
	if start_timestamp == '' {
		return ctx.create_message_response(.bad_request, "'start_timestamp' field not found")
	}

	if !start_timestamp.is_int() {
		return ctx.create_message_response(.bad_request, "'start_timestamp' field not a number")
	}

	end_timestamp := (ctx.query['end_timestamp']).trim_space()
	if end_timestamp == '' {
		return ctx.create_message_response(.bad_request, "'end_timestamp' field not found")
	}

	if !end_timestamp.is_int() {
		return ctx.create_message_response(.bad_request, "'end_timestamp' field not a number")
	}

	st := start_timestamp.i64()
	en := end_timestamp.i64()

	if en <= st {
		return ctx.create_message_response(.bad_request, 'Illegal timestamps range')
	}

	track_url := (ctx.query['track_url']).trim_space()
	if track_url != '' {
		if track_url.len > 256 {
			return ctx.create_message_response(.bad_request, "'track_url' field too long")
		}

		ln_obj.track_url = track_url
	} else {
		ln_obj.track_url = none
	}

	album_image := (ctx.query['album_image']).trim_space()
	if album_image != '' {
		if album_image.len > 256 {
			return ctx.create_message_response(.bad_request, "'album_image' field too long (${album_image.len})")
		}

		ln_obj.album_image = album_image
	} else {
		ln_obj.album_image = none
	}

	album_name := (ctx.query['album_name']).trim_space()
	if album_name != '' {
		if album_name.len > 64 {
			return ctx.create_message_response(.bad_request, "'album_name' field too long")
		}

		ln_obj.album_name = album_name
	} else {
		ln_obj.album_name = none
	}

	service_name := (ctx.query['service_name']).trim_space()
	if service_name != '' {
		if service_name.len > 16 {
			return ctx.create_message_response(.bad_request, "'service_name' field too long")
		}

		ln_obj.service_name = service_name
	} else {
		ln_obj.service_name = 'default'
	}

	ln_obj.is_playing = true

	server_start_timestamp := time.now().unix_milli()
	ln_obj.start_timestamp_on_server = server_start_timestamp
	ln_obj.start_timestamp_on_server_str = server_start_timestamp.str()

	ln_obj.name = name
	ln_obj.author = author
	ln_obj.start_timestamp = start_timestamp
	ln_obj.end_timestamp = end_timestamp

	return ctx.create_message_response(.ok, 'ok')
}
