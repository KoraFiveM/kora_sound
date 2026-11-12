---
title: Configuration
sidebar_position: 4
---

# Configuration

Settings are in `config.lua` (shared, loaded on both sides).

| Option | Default | Description |
| --- | --- | --- |
| `Config.defaultVolume` | `0.3` | Volume for sounds with no explicit volume and no category. |
| `Config.defaultRange` | `30.0` | Radius used by `PlaySoundInArea` and `InteractSound_SV:PlayWithinDistance` when none is given. |
| `Config.minFalloffVolume` | `0.05` | Minimum volume at the edge of an area; a floor, not a cutoff. |
| `Config.cooldownMs` | `150` | Per-player cooldown on the `InteractSound_SV:*` events only. |
| `Config.categories` | see below | Category name to volume. |
| `Config.soundCategory` | see below | Sound file name to category. |

## Categories

| Category | Volume |
| --- | --- |
| `ui` | `0.25` |
| `interaction` | `0.3` |
| `alarm` | `0.6` |
| `ambient` | `0.4` |

No default sound is mapped to `ui`. Mapped sounds:

- `interaction`: `Cuff`, `Uncuff`, `handcuff`, `ziptie`, `DoorOpen`, `DoorClose`, `lockpick`, `unlock`, `lock`, `keys`, `keydoors`
- `alarm`: `Alert`, `security-alarm`, `warehousealert`, `warehousealert2`, `panic`, `beltalarm`, `RumbleStart`
- `ambient`: `radiostatic1`, `radiostatic2`, `radiostatic3`, `ventilator`, `coffee_machine`, `vending_machine`

Sounds not listed use `Config.defaultVolume`.

## Volume resolution

`Config.resolveVolume(soundFile, explicitVolume)` returns the explicit volume if given, otherwise the category volume, otherwise `Config.defaultVolume`. The server resolves the volume before sending, and the client resolves again (a value already resolved is passed through unchanged).

## Falloff

`Config.falloffVolume(volume, distance, radius)` scales `volume` by `1 - distance / radius` and never goes below `Config.minFalloffVolume`.
