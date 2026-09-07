# LvkHub V2 standalone

`loader_v2.lua` is an independent entry point for the V2 local-practice runtime.

It does not call `loader.lua` and does not load `src/Restrictions/Policy.lua`.
Instead it owns its own policy at `v2/Policy.lua`, then constructs:

```text
v2/Policy.lua
      ↓
RegistryV3
      ↓
TargetProvider
      ↓
Combat / Visuals / Target Info / local practice feedback
```

## Runtime globals

The standalone runtime is exposed as:

```lua
shared.LvkHubV2
shared.LvkHubV2TargetProvider
shared.LvkHubV2Restrictions
shared.LvkHubV2TargetRestrictions
```

Compatibility aliases are also populated for modules that have not yet been migrated away from the original global names.

## Startup

Use `loader_v2.lua` in a fresh session. V2 intentionally refuses to start if the main runtime is already active, because both versions currently reuse the same GUI names and render-bind names.

## Target policy

V2 is self-contained but remains local-practice only. Its policy authorizes managed models under `Workspace.TestPlayers` and rejects actual `Player.Character` models. Session-sensitive local/solo features continue to require a LocalPlayer-only session.
