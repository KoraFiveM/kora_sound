---
title: Exports
sidebar_position: 2
---

# Exports

All exports live under the name `interact-sound` (for example `exports['interact-sound']:PlaySound(...)`). The resource also registers them through `Kora.compat.provideExport('interact-sound', ...)`, so they remain callable under that name whatever the resource folder is called.

`soundFile` is the file name without extension (see [Sounds](./sounds.md)). `volume` is optional; when `nil` the volume is resolved from [Configuration](./configuration.md). `options` is `{ loop = boolean, id = string }`. A sound only loops when both `loop` and `id` are set on the server; on the client `loop` is honoured as passed, but without `id` it cannot be stopped.

## Client

| Export | Description |
| --- | --- |
| `PlaySound(soundFile, volume?, options?)` | Plays a sound locally. Does nothing until the player is logged in (`LocalPlayer.state.isLoggedIn` or `QBCore:Client:OnPlayerLoaded`). |
| `StopSound(id)` | Stops and unloads the sound started with that `id`. Ignored if `id` is nil. |

## Server

| Export | Description |
| --- | --- |
| `PlaySound(src, soundFile, volume?, options?)` | Plays for one player. |
| `PlaySoundAll(soundFile, volume?, options?)` | Plays for every player. |
| `PlaySoundInArea(coords, radius, soundFile, volume?, options?)` | Plays for players within `radius` of `coords` (a `vector3`). `radius` defaults to `Config.defaultRange` and is capped at 300.0. Volume falls off linearly with distance, see [Configuration](./configuration.md). |
| `StopSound(id, target?)` | Stops a sound. With `target` (a player id) only that player is told. Without it, everyone who received the loop is told (everyone, if it was started with `PlaySoundAll`). |

The server exports are not rate limited and do not validate `soundFile`; they are meant for trusted server code. `PlaySoundInArea` is a snapshot: players entering range later do not get an already started loop.

## Examples

```lua
-- One-shot, volume from the sound's category
exports['interact-sound']:PlaySoundInArea(coords, 15.0, 'DoorOpen')

-- Looping alarm for everyone, stopped later
exports['interact-sound']:PlaySoundAll('security-alarm', nil, { loop = true, id = 'bank_alarm' })
exports['interact-sound']:StopSound('bank_alarm')
```
