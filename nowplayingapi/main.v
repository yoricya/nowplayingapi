module main

import veb
import sync
import os
import toml

fn main() {
	// Linux cross: v -cflags "-O3" -ldflags "-s -w -static"  -d use_openssl -os linux .

	// ____________________________________
	println('Preparing config...')
	doc := toml.parse_file('config.toml') or {
		str := 'port = 5581\nhost = "0.0.0.0"'

		os.write_file('config.toml', str) or { panic(err) }
		toml.parse_text(str) or { panic(err) }
	}

	// Get server port
	server_port := doc.value_opt('port') or { panic('Broken config: ${err.msg()}') }.int()

	if server_port < 1 || server_port > 65535 {
		panic('Illegal port value: ${server_port}')
	}

	// Get address type
	is_v6 := doc.value('is_ipv6').bool()

	// Get server host
	server_host := doc.value_opt('host') or { panic('Broken config: ${err.msg()}') }.string()

	// Get def srv timeout
	def_srv_timeout := doc.value_opt('def_srv_timeout') or { toml.Any(8) }.int()

	if def_srv_timeout < 1 {
		panic('Illegal timeout value: ${def_srv_timeout}')
	}

	// ____________________________________
	println('Preparing service...')
	os.signal_ignore(os.Signal.pipe)

	mut webapp := WebApp{
		cached_listen_now_rwmutex: sync.new_rwmutex()
		redirect_main_page_to:     'https://github.com/yoricya/nowplayingapi'
		// no_ddos_cache_rwmutex:     sync.new_rwmutex()
	}

	// Okay this not needed, because i use cloudflare (This throw segfault and idknow, how to fix it)
	// webapp.use(handler: webapp.anti_ddos_check)

	webapp.use(
		handler: fn (mut ctx WebCtx) bool {
			ctx.set_custom_header('Access-Control-Allow-Origin', '*') or {}
			return true
		}
	)

	// ____________________________________
	println('Starting service...')
	veb.run_at[WebApp, WebCtx](mut webapp, veb.RunParams{
		family: if is_v6 {
			.ip6
		} else {
			.ip
		}

		host:                 server_host
		port:                 server_port
		show_startup_message: true
		timeout_in_seconds:   8
	}) or { panic('Service error: ${err.msg()}') }

	println('Stopped service.')
}
