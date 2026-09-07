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

## Failure mode

The loader uses a deny-all fallback when `Policy.lua` is absent or fails to load. Removing the restrictions folder therefore leaves the UI running but registers no combat/visual targets and blocks solo-gated mutations.
