module main

import veb
import net.http

pub struct WebCtx {
	veb.Context
mut:
	has_allow_access bool = true
}

pub fn (mut ctx WebCtx) create_message_response(code http.Status, message string) veb.Result {
	ctx.res.set_status(code)
	return ctx.text('{\n"code": ${code.int()},\n "message": "$message"\n}')
}
