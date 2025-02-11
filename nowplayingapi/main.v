module main

import veb
import sync
import os

fn main() {
	// Linux cross: v -cflags "-O3" -ldflags "-s -w -static"  -d use_openssl -os linux .

	println('Starting service...')
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

	veb.run_at[WebApp, WebCtx](mut webapp, veb.RunParams{
		family:               .ip
		host:                 '0.0.0.0'
		port:                 5581 // Change port
		show_startup_message: true
		timeout_in_seconds:   8
	}) or { panic(err) }

	println('Stopped service.')
}
