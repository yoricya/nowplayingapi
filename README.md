### Now Playing API
Simple _now playing api_ :P

## Generate token

Send GET to `https://nowplayingapi.yoricya.ru/generate`

Response:
```
{
  "key": "gKeybMIRBOezSvJzLwcztGZYGuoprOaaODFHeXEkKGNkbDJPTUPdphdRYglCQMVx",
  "token": "2d27330d8c4f881fec3b831b56ae88171162e938c089a872bbbf1120144af9f9"
}
```

_key_ - Private KEY, do not spread it.

_token_ - Public token, you can be safety spread it

## Set listen status by key:

Send GET to `https://nowplayingapi.yoricya.ru/set/{key}?...`

_{key}_ - Your private key

__GET Parameters:__

`service_name` _(Optional)_ - Name of music service _(For example: VKMusic)_ 

`name` - Name of track _(For example: Dedicated)_ 

`author` - Author of track _(For example: ATB)_ 

`album_image` _(Optional)_  - Url to album image _(For example: https://i.scdn.co/image/ab67616d0000b273a968feb0cd7b6a55b434530a)_ 

`track_url` _(Optional)_  - Url to track _(For example: https://vk.com/audio-2001724620_32724620)_ 

`album_name` _(Optional)_  - Album name _(For example: Dedicated)_ 

`start_timestamp` - Start listening timestamp in __string__ _(For example: 1737819287000)_

`end_timestamp` - End listening timestamp in __string__ _(For example: 1737819542000)_  

## Get listen status by public token:

Send GET to `https://nowplayingapi.yoricya.ru/get/{token}`

_{token}_ - Your public token

Example response:
```
{
  "is_playing": true,
  "name": "Dedicated",
  "author": "ATB",
  "album_image": "https://i.scdn.co/image/ab67616d0000b273a968feb0cd7b6a55b434530a",
  "service_name": "VK Music",
  "start_timestamp_on_server_str": "1737837290440",
  "start_timestamp": "1737819287000",
  "end_timestamp": "1737819542000",
  "track_url": "https://vk.com/audio-2001724620_32724620"
}
```

If token not found:
```
{
  "code": 404,
  "message": "Token not found"
}
```

If nothing playing now:
```
{
  "is_playing": false,
  "name": "",
  "author": "",
  "service_name": "default",
  "start_timestamp_on_server_str": "",
  "start_timestamp": "",
  "end_timestamp": ""
}
```

> Optional fields my be undefined!

## Get token by key
If you lost token but you know key, you can be convert key to token:

Send GET to `https://nowplayingapi.yoricya.ru/key/{key}`

Response:
```
{
  "key": "{key}",
  "token": "{token}"
}
```

Minimum key length: __64__! Otherwise:
```
{
 "code": 400,
 "message": "Key length too small"
}
```
