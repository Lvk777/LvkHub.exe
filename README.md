# LvkHub.exe

Fresh modular Roblox/Luau project built from scratch with a Yokai-inspired layout.

## Goals

- One shared target registry for non-player bot rigs under `Workspace > Players`.
- One shared vehicle registry for `Workspace > Vehicles`.
- Independent modules for Visuals, World, Movement, Utility and Local.
- No duplicate `Workspace:GetDescendants()` polling loops.
- Persistent World overrides use change listeners + slow watchdogs instead of per-frame property spam.
- Combat adapters are limited to practice bots/NPCs; real `Players` characters are excluded.

## Planned modules

### Visuals
3D Box, Chams, Corner Box, ESP pack, FOV Changer, HealthBar, Name + Distance, Preview, Thermal Corner, Tracers, Skeleton, Car ESP.

### World
ChangeSkyDome, FullBrightness, No Fog, No Leaves, No Shadows, FPS Boost.

### Movement
CarFly, Fly, Noclip, Speed, Mouse TP.

### Combat (bot practice)
HitBoxes, AntiAim, Aimbot, Silent Aim adapter.

### Utility
AntiAFK, NoMenuFog, Rejoin, ServerHop.

### Local
HitSound, GunChams, SelfChams, Trail.

`ClientKickDisable` and anti-cheat bypass/evasion logic are intentionally not part of this codebase.
