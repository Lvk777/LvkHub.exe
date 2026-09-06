return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Local

    UI.Section(page,"Local")
    UI.Toggle(page,"HitSound",function() return State.Local.HitSound end,function(v) State.Local.HitSound=v end)
    UI.Toggle(page,"GunChams",function() return State.Local.GunChams end,function(v) State.Local.GunChams=v end)
    UI.Toggle(page,"SelfChams",function() return State.Local.SelfChams end,function(v) State.Local.SelfChams=v end)
    UI.Toggle(page,"Trail",function() return State.Local.Trail end,function(v) State.Local.Trail=v end)

    local sound=Instance.new("Sound")
    sound.Name="LvkHubHitSound"; sound.SoundId="rbxassetid://160715357"; sound.Volume=.65; sound.Parent=Workspace.CurrentCamera or Workspace

    local healthCache=setmetatable({}, {__mode="k"})
    local selfHighlight=nil
    local trailA,trailB,trail=nil,nil,nil
    local gunOriginal=setmetatable({}, {__mode="k"})

    local function ensureSelfChams()
        local ch=LP.Character
        if State.Local.SelfChams and ch then
            if not selfHighlight or selfHighlight.Parent~=ch then
                if selfHighlight then selfHighlight:Destroy() end
                selfHighlight=Instance.new("Highlight")
                selfHighlight.Name="LvkHubSelfChams"; selfHighlight.Adornee=ch; selfHighlight.DepthMode=Enum.HighlightDepthMode.Occluded
                selfHighlight.FillColor=Color3.fromRGB(125,82,235); selfHighlight.OutlineColor=Color3.fromRGB(255,255,255); selfHighlight.FillTransparency=.7; selfHighlight.OutlineTransparency=.1; selfHighlight.Parent=ch
            end
            selfHighlight.Enabled=true
        elseif selfHighlight then selfHighlight.Enabled=false end
    end

    local function ensureTrail()
        local ch=LP.Character; local root=ch and ch:FindFirstChild("HumanoidRootPart")
        if State.Local.Trail and root then
            if not trail or not trail.Parent then
                trailA=Instance.new("Attachment"); trailA.Position=Vector3.new(-1,0,0); trailA.Parent=root
                trailB=Instance.new("Attachment"); trailB.Position=Vector3.new(1,0,0); trailB.Parent=root
                trail=Instance.new("Trail"); trail.Name="LvkHubTrail"; trail.Attachment0=trailA; trail.Attachment1=trailB; trail.Lifetime=.35; trail.MinLength=.1; trail.FaceCamera=true; trail.Color=ColorSequence.new(Color3.fromRGB(125,82,235)); trail.Parent=root
            end
            trail.Enabled=true
        elseif trail then trail.Enabled=false end
    end

    local function applyGunChams()
        local cam=Workspace.CurrentCamera; if not cam then return end
        for _,d in ipairs(cam:GetDescendants()) do
            if d:IsA("BasePart") and not (LP.Character and d:IsDescendantOf(LP.Character)) then
                local n=string.lower(d.Name)
                if n:find("gun",1,true) or n:find("weapon",1,true) or n:find("viewmodel",1,true) or n:find("arm",1,true) then
                    if gunOriginal[d]==nil then gunOriginal[d]={Material=d.Material,Color=d.Color} end
                    if State.Local.GunChams then d.Material=Enum.Material.ForceField; d.Color=Color3.fromRGB(125,82,235) else local o=gunOriginal[d]; if o then d.Material=o.Material; d.Color=o.Color end end
                end
            end
        end
    end

    RunService.Heartbeat:Connect(function()
        if State.Local.HitSound then
            for model in pairs(Registry.Bots) do
                local hum=Registry.HumanoidOf(model)
                if hum then
                    local last=healthCache[hum]
                    if last and hum.Health<last then pcall(function() sound:Play() end) end
                    healthCache[hum]=hum.Health
                end
            end
        end
        ensureSelfChams(); ensureTrail()
    end)

    local acc=0
    RunService.RenderStepped:Connect(function(dt)
        acc+=dt; if acc<.2 then return end; acc=0
        applyGunChams()
    end)
end
