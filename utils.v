module main

import crypto.md5
import crypto.sha256

pub fn key_to_token(key string) !string {
	if key.len < 64 {
		return error("Key length too small")
	}

	return sha256.hexhash(md5.hexhash(key[..32]) + md5.hexhash(key[32..]))
}
