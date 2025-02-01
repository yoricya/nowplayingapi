module main

import time
import sync

pub struct Anti_ddos_Context {
mut:
	mutex          &sync.Mutex
	last_req       i64
	ban_time       i64 = 50
	temporally_ban bool
}

pub fn (mut app WebApp) anti_ddos_check(mut ctx WebCtx) bool {
	ip := if !app.is_using_cloudflare {
		ctx.ip() + '!' + ctx.req.method.str()
	} else {
		ctx.get_custom_header('X-Forwarded-For') or {
			ctx.get_custom_header('Cf-Connecting-IP') or { ctx.ip() }
		} + '!' + ctx.req.method.str()
	}

	println('CONN:${ip}')

	app.no_ddos_cache_rwmutex.rlock()
	mut addos_ctx_opt := unsafe { app.no_ddos_cache[ip] }
	app.no_ddos_cache_rwmutex.runlock()

	now := time.now().unix_milli()

	mut addos_ctx := if addos_ctx_opt == none {
		mut a := &Anti_ddos_Context{
			mutex: sync.new_mutex()
		}

		app.no_ddos_cache_rwmutex.lock()
		app.no_ddos_cache[ip] = a
		app.no_ddos_cache_rwmutex.unlock()

		a
	} else {
		addos_ctx_opt
	}

	addos_ctx.mutex.lock()
	if addos_ctx.temporally_ban {
		addos_ctx.mutex.unlock()
		ctx.has_allow_access = false
		return false
	}

	if (now - addos_ctx.last_req) < addos_ctx.ban_time {
		addos_ctx.ban_time += 60
		ctx.has_allow_access = false

		if addos_ctx.ban_time >= 2000 {
			addos_ctx.temporally_ban = true
			println('[aDDOS] Temp ban: ${ip}')
		}
	} else {
		addos_ctx.ban_time = 50
	}

	addos_ctx.last_req = now
	addos_ctx.mutex.unlock()

	return true
}
