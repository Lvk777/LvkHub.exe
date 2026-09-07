# LvkHub restrictions

All active targeting/session restrictions are centralized in `Policy.lua`.

## Target policy

- `Policy.Targets.IsRealPlayerCharacter(model)` rejects Roblox `Player.Character` models.
- `Policy.Targets.IsAllowedTarget(model)` only accepts LvkHub-managed models under `Workspace.TestPlayers`.
- `Policy.Targets.CanCloneSource(model)` controls which source rigs may be copied into local practice dummies.

## Session policy

- `Policy.SoloWeaponModsAllowed()` permits the solo-only weapon modifiers only when no other Roblox Player is present.
- `Policy.VehicleBringAllowed()` applies the same solo-session gate to BringCar.
- `Policy.RealPlayerInSeat(seat)` prevents moving a vehicle whose driver seat belongs to a real Player.

## Loader behavior

`Policy.lua` is a required module. The loader no longer creates a `DENY_ALL`/`FailClosed` fallback table. If the required policy cannot be loaded, initialization stops instead of silently selecting a different target source.
