-- LvkHub.exe SOLO SESSION WEAPON MODS
-- ============================================================================
-- HARD SOLO-SESSION GUARD
-- These three options are allowed to change local weapon state ONLY when
-- Players contains LocalPlayer and nobody else.
--
-- IMPORTANT: this guard is intentionally isolated and easy to audit.
-- If ANY other Roblox Player is present, No Recoil / Infinite Ammo / Fast Reload
-- perform no writes and any local values/attributes previously changed by this
-- module are restored from their pre-enable snapshots.
-- ============================================================================

return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")

    local LP=Players.LocalPlayer
    local page=UI.Pages.Combat

    State.Combat.NoRecoil=State.Combat.NoRecoil==true
    State.Combat.InfiniteAmmo=State.Combat.InfiniteAmmo==true
    State.Combat.FastReload=State.Combat.FastReload==true
    State.Combat.FastReloadMultiplier=tonumber(State.Combat.FastReloadMultiplier) or 4

    -- ========================================================================
    -- >>> HARD SOLO GUARD: THIS FUNCTION CONTROLS ALL THREE FEATURES <<<
    -- ========================================================================
    local function SoloWeaponModsAllowed()
        for _,player in ipairs(Players:GetPlayers()) do
            if player~=LP then
                return false
            end
        end
        return true
    end

    shared.LvkHubSoloWeaponModsAllowed=SoloWeaponModsAllowed

    local function otherPlayerCount()
        local n=0
        for _,player in ipairs(Players:GetPlayers()) do
            if player~=LP then n+=1 end
        end
        return n
    end

    UI.Section(page,"SOLO SESSION WEAPON MODS")
    local _,guardLabel=UI.Row(page,"SOLO GUARD: checking...")
    guardLabel.TextColor3=Color3.fromRGB(255,190,85)

    local _,explain=UI.Row(page,"Hard block: any other Player = no weapon changes",42)
    explain.TextWrapped=true
    explain.TextColor3=Color3.fromRGB(150,155,170)
    explain.TextSize=12

    UI.Toggle(page,"No Recoil [SOLO]",function() return State.Combat.NoRecoil end,function(v)
        State.Combat.NoRecoil=v
    end)

    UI.Toggle(page,"Infinite Ammo [SOLO]",function() return State.Combat.InfiniteAmmo end,function(v)
        State.Combat.InfiniteAmmo=v
    end)

    UI.Toggle(page,"Fast Reload [SOLO]",function() return State.Combat.FastReload end,function(v)
        State.Combat.FastReload=v
    end)

    UI.Number(page,"Reload Multiplier",function()
        return State.Combat.FastReloadMultiplier
    end,function(v)
        State.Combat.FastReloadMultiplier=math.clamp(tonumber(v) or 4,1,10)
    end,1,10)

    -- Player attributes are the exact multipliers consumed by the current
    -- WeaponViewmodelController for recoil and reload animation speed.
    local attrOriginal={}
    local attrCaptured={}

    local function captureAttr(name)
        if attrCaptured[name] then return end
        attrCaptured[name]=true
        attrOriginal[name]={
            had=LP:GetAttribute(name)~=nil,
            value=LP:GetAttribute(name),
        }
    end

    local function restoreAttr(name)
        if not attrCaptured[name] then return end
        local snap=attrOriginal[name]
        if snap and snap.had then
            LP:SetAttribute(name,snap.value)
        else
            LP:SetAttribute(name,nil)
        end
        attrCaptured[name]=nil
        attrOriginal[name]=nil
    end

    local ammoSnapshots=setmetatable({}, {__mode="k"})

    local function snapshotValue(obj)
        if not obj or ammoSnapshots[obj]~=nil then return end
        ammoSnapshots[obj]=obj.Value
    end

    local function restoreAmmoSnapshots()
        for obj,value in pairs(ammoSnapshots) do
            if obj and obj.Parent then
                pcall(function() obj.Value=value end)
            end
            ammoSnapshots[obj]=nil
        end
    end

    local function currentWeapon()
        local char=LP.Character
        if not char then return nil end
        for _,obj in ipairs(char:GetChildren()) do
            if obj:IsA("Tool") and obj:FindFirstChild("WeaponConfig") then
                return obj
            end
        end
        return nil
    end

    local function maxOf(valueObj)
        if not valueObj then return nil end
        local ok,max=pcall(function() return valueObj.MaxValue end)
        if ok and typeof(max)=="number" then return max end
        return nil
    end

    local function applyInfiniteAmmo()
        local tool=currentWeapon()
        if not tool then return end

        local ammo=tool:FindFirstChild("Ammo")
        local mag=ammo and ammo:FindFirstChild("MagAmmo")
        local pool=ammo and ammo:FindFirstChild("ArcadeAmmoPool")
        local chambered=tool:FindFirstChild("Chambered")
        local boltReady=tool:FindFirstChild("BoltReady")

        if mag and mag:IsA("ValueBase") then
            snapshotValue(mag)
            local maximum=maxOf(mag)
            if maximum then pcall(function() mag.Value=maximum end) end
        end

        if pool and pool:IsA("ValueBase") then
            snapshotValue(pool)
            local maximum=maxOf(pool)
            if maximum then pcall(function() pool.Value=maximum end) end
        end

        if chambered and chambered:IsA("BoolValue") then
            snapshotValue(chambered)
            pcall(function() chambered.Value=true end)
        end

        if boltReady and boltReady:IsA("BoolValue") then
            snapshotValue(boltReady)
            pcall(function() boltReady.Value=true end)
        end
    end

    local wasAllowed=SoloWeaponModsAllowed()
    local timer=0

    local function restoreAllWeaponMods()
        restoreAttr("ProfessionBenefit_weaponRecoilMultiplier")
        restoreAttr("ProfessionBenefit_reloadSpeedMultiplier")
        restoreAmmoSnapshots()
    end

    local function updateGuardLabel()
        local others=otherPlayerCount()
        if others==0 then
            guardLabel.Text="SOLO GUARD: READY • only LocalPlayer"
            guardLabel.TextColor3=Color3.fromRGB(80,225,125)
        else
            guardLabel.Text="SOLO GUARD: BLOCKED • "..others.." other Player"..(others==1 and "" or "s")
            guardLabel.TextColor3=Color3.fromRGB(245,80,80)
        end
    end

    updateGuardLabel()

    RunService.Heartbeat:Connect(function(dt)
        timer+=dt
        if timer<0.06 then return end
        timer=0

        local allowed=SoloWeaponModsAllowed()
        if allowed~=wasAllowed then
            updateGuardLabel()
            if not allowed then
                -- Immediate rollback when another Player enters the session.
                restoreAllWeaponMods()
            end
            wasAllowed=allowed
        end

        if not allowed then
            -- HARD BLOCK: absolutely no weapon writes below this point.
            return
        end

        if State.Combat.NoRecoil then
            captureAttr("ProfessionBenefit_weaponRecoilMultiplier")
            if LP:GetAttribute("ProfessionBenefit_weaponRecoilMultiplier")~=0 then
                LP:SetAttribute("ProfessionBenefit_weaponRecoilMultiplier",0)
            end
        else
            restoreAttr("ProfessionBenefit_weaponRecoilMultiplier")
        end

        if State.Combat.FastReload then
            captureAttr("ProfessionBenefit_reloadSpeedMultiplier")
            local wanted=math.clamp(tonumber(State.Combat.FastReloadMultiplier) or 4,1,10)
            if LP:GetAttribute("ProfessionBenefit_reloadSpeedMultiplier")~=wanted then
                LP:SetAttribute("ProfessionBenefit_reloadSpeedMultiplier",wanted)
            end
        else
            restoreAttr("ProfessionBenefit_reloadSpeedMultiplier")
        end

        if State.Combat.InfiniteAmmo then
            applyInfiniteAmmo()
        elseif next(ammoSnapshots)~=nil then
            restoreAmmoSnapshots()
        end
    end)

    Players.PlayerAdded:Connect(function(player)
        if player~=LP then
            task.defer(function()
                updateGuardLabel()
                restoreAllWeaponMods()
                wasAllowed=false
            end)
        end
    end)

    Players.PlayerRemoving:Connect(function()
        task.defer(function()
            updateGuardLabel()
            wasAllowed=SoloWeaponModsAllowed()
        end)
    end)

    LP.CharacterAdded:Connect(function()
        -- New character: never carry snapshots from the previous rig/tool.
        restoreAmmoSnapshots()
        task.defer(updateGuardLabel)
    end)
end
