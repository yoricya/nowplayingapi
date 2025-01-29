module main

import crypto.md5
import crypto.sha256
import rand

pub fn key_to_token(key string) !string {
	if key.len < 96 {
		return error('Key length too small')
	}

	return sha256.hexhash(md5.hexhash(key[..64])) + md5.hexhash(key[64..])
}

pub fn gen_key() string {
	k1 := rand.string(128)
	return sha256.hexhash(k1[..64]) + sha256.hexhash(k1[64..])
}
