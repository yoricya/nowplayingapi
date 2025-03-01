### Chrome plugin for vkmusic in vk.com
> I dont know, how long it will work, perhaps until they radically change any functions on their page, but... it working

> Aaand, it seems to me that it is possible to place Discord integration in the Chrome plugin, and I will try to do this, but for now VKMusic integration in discord requires 3 services (Chrome plugin -> nowPlayingApi -> Discord integration app)

__Todo:__

 - [ ] - Embedded discord integration

### Discord rich presence apps
> Yes, this is _pobeda_, i make two Rich Presence app
 - NodeJS Crossplatformed, _well, sort of_
 - Swift Native for macOS (11+), _it seems to work_

### Now Playing API
Simple _now playing api_ :P

> Any response codes sent in http headers, in case of errors they are also transmitted along with json for convenience.

__Todo:__

 - [X] - Support live broadcast _(optional `end_timestamp` field)_
 - [X] - Add field for activity type _(Listening, Watching or other)_
 - [ ] - Functional field for callbacks
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

`name` - Name of track _(For example: Dedicated)_

`author` - Author of track _(For example: ATB)_

`start_timestamp` - Start listening timestamp in __string__ _(For example: 1737819287000)_

`service_name` _(Optional)_ - Name of music service _(For example: VKMusic)_

`album_image` _(Optional)_  - Url to album image _(For example: https://i.scdn.co/image/ab67616d0000b273a968feb0cd7b6a55b434530a)_

`track_url` _(Optional)_  - Url to track _(For example: https://vk.com/audio-2001724620_32724620)_

`album_name` _(Optional)_  - Album name _(For example: Dedicated)_

`end_timestamp` _(Optional)_ - End listening timestamp in __string__, <ins>do not specify to set live broadcast</ins> _(For example: 1737819542000)_

`activity_type` _(Optional)_ - Activity type in __integer__, defaults: <ins>(0 - Listening, 1 - Watching)</ins> _(For example: 0)_

## Reset listen status by key:

Send GET to `https://nowplayingapi.yoricya.ru/set/{key}`

_{key}_ - Your private key

> No GET parameters

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
  "track_url": "https://vk.com/audio-2001724620_32724620",
  "is_live_broadcast": false,
  "activity_type": 0
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

Minimum key length: __96__! Otherwise:
```
{
 "code": 400,
 "message": "Key length too small"
}
```
