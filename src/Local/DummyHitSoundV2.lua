-- Reliable local TestPlayers hit sound. No real-player targeting or damage.
return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")

    local sound=Instance.new("Sound")
    sound.Name="LvkHubDummyHitSoundV2"
    sound.SoundId="rbxassetid://91546829095879"
    sound.Volume=.85
    sound.Parent=Workspace.CurrentCamera or Workspace

    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if Workspace.CurrentCamera then sound.Parent=Workspace.CurrentCamera end
    end)

    local lastPlay=0
    local function play()
        if not State.Local.HitSound then return end
        local now=os.clock()
        if now-lastPlay<.045 then return end
        lastPlay=now
        if Workspace.CurrentCamera and sound.Parent~=Workspace.CurrentCamera then sound.Parent=Workspace.CurrentCamera end
        pcall(function()
            sound.TimePosition=0
            sound:Play()
        end)
    end

    -- WeaponSystemDummyAdapter calls this function when it applies a local dummy hit.
    shared.LvkHubPlayHitSound=play

    -- Fallback: if any local practice dummy's Humanoid health drops, play once.
    local health=setmetatable({}, {__mode="k"})
    RunService.Heartbeat:Connect(function()
        if not State.Local.HitSound then return end
        for model in pairs(Registry.Bots) do
            if Registry.IsBot(model) then
                local hum=Registry.HumanoidOf(model)
                if hum then
                    local prev=health[hum]
                    if prev~=nil and hum.Health<prev then play() end
                    health[hum]=hum.Health
                end
            end
        end
    end)
end
