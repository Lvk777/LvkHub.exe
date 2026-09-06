-- LvkHub.exe Combat
--
-- ============================================================================
-- TEST PLAYERS / NPC DUMMIES ONLY
-- ============================================================================
-- Combat consumes Registry.Bots, which is now populated only from
-- Workspace.TestPlayers. GunTesting NPC rigs from Workspace.Players are mirrored
-- into TestPlayers as client-side ObjectValue references.
--
-- Real Roblox Player.Character models are excluded by Registry and are never
-- returned by Registry.IsBot(). Real Players joining/leaving the server do not
-- disable dummy practice; they are simply ignored as target candidates.
--
-- No __namecall/metatable hooks, kick suppression, anti-cheat bypass or evasion.
-- ============================================================================

return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")
    local Workspace=game:GetService("Workspace")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Combat

    State.Combat.SelectedBot=nil

    UI.Section(page,"TEST PLAYERS / NPC DUMMIES")
    local _,sourceLabel=UI.Row(page,"Target source: Workspace.TestPlayers")
    sourceLabel.TextColor3=Color3.fromRGB(150,200,255)
    local _,countLabel=UI.Row(page,"Test targets: 0")
    countLabel.TextColor3=Color3.fromRGB(120,220,170)

    local function allowed()
        return Registry.PracticeAllowed and Registry.PracticeAllowed() or false
    end

    local function updateCount()
        local n=Registry.CountBots and Registry.CountBots() or 0
        countLabel.Text="Test targets: "..tostring(n).." • real Players excluded"
    end
    updateCount()

    UI.Section(page,"Combat")
    local _,targetLabel=UI.Row(page,"Target dummy: AUTO")
    targetLabel.TextColor3=Color3.fromRGB(150,200,255)

    UI.Button(page,"Target Dummy","NEXT",function()
        if Registry.RefreshTargets then Registry.RefreshTargets() end
        updateCount()
        local list={}
        for model in pairs(Registry.Bots) do
            if Registry.IsBot(model) then table.insert(list,model) end
        end
        table.sort(list,function(a,b) return a.Name<b.Name end)
        if #list==0 then
            State.Combat.SelectedBot=nil
            targetLabel.Text="Target dummy: AUTO • 0 found"
            return
        end
        local idx=table.find(list,State.Combat.SelectedBot) or 0
        State.Combat.SelectedBot=list[idx%#list+1]
        targetLabel.Text="Target dummy: "..State.Combat.SelectedBot.Name
    end)

    local function setGuarded(key,v)
        State.Combat[key]=(v and allowed()) or false
    end

    UI.Toggle(page,"Aimbot",function() return State.Combat.Aimbot end,function(v) setGuarded("Aimbot",v) end)
    UI.Toggle(page,"Silent Aim",function() return State.Combat.SilentAim end,function(v) setGuarded("SilentAim",v) end)
    UI.Toggle(page,"Magic Bullets",function() return State.Combat.MagicBullets end,function(v) setGuarded("MagicBullets",v) end)
    UI.Toggle(page,"HitBoxes",function() return State.Combat.HitBoxes end,function(v) setGuarded("HitBoxes",v) end)
    UI.Number(page,"HitBox Size",function() return State.Combat.HitboxSize end,function(v) State.Combat.HitboxSize=v end,2,20)
    UI.Dropdown(page,"Aim Part",{"Head","Torso"},function() return State.Combat.AimPart or "Head" end,function(v) State.Combat.AimPart=v end)
    UI.Toggle(page,"AntiAim",function() return State.Combat.AntiAim end,function(v) State.Combat.AntiAim=v end)

    local function targetPart(model)
        if not allowed() or not model or not Registry.IsBot(model) then return nil end
        if (State.Combat.AimPart or "Head")=="Torso" then
            return model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or Registry.RootOf(model)
        end
        return model:FindFirstChild("Head") or Registry.RootOf(model)
    end

    local function referencePoint(cam)
        if UIS.MouseBehavior==Enum.MouseBehavior.LockCenter then return cam.ViewportSize/2 end
        local m=UIS:GetMouseLocation()
        return Vector2.new(m.X,m.Y)
    end

    local function selectedTarget()
        if State.Combat.SelectedBot and Registry.IsBot(State.Combat.SelectedBot) then
            local p=targetPart(State.Combat.SelectedBot)
            if p then return State.Combat.SelectedBot,p end
        end
        return nil
    end

    local function chooseScreenTarget()
        if not allowed() then return nil end
        local sm,sp=selectedTarget()
        if sm and sp then return sm,sp end

        local cam=Workspace.CurrentCamera
        if not cam then return nil end
        local ref=referencePoint(cam)
        local best,bestPart,bestPx=nil,nil,math.huge
        for model in pairs(Registry.Bots) do
            if Registry.IsBot(model) then
                local p=targetPart(model)
                if p then
                    local s,on=cam:WorldToViewportPoint(p.Position)
                    if on and s.Z>0 then
                        local px=(Vector2.new(s.X,s.Y)-ref).Magnitude
                        if px<bestPx then
                            bestPx=px
                            best=model
                            bestPart=p
                        end
                    end
                end
            end
        end
        return best,bestPart
    end

    local function chooseWorldTarget()
        if not allowed() then return nil end
        local sm,sp=selectedTarget()
        if sm and sp then return sm,sp end

        local cam=Workspace.CurrentCamera
        if not cam then return nil end
        local best,bestPart,bestDist=nil,nil,math.huge
        for model in pairs(Registry.Bots) do
            if Registry.IsBot(model) then
                local p=targetPart(model)
                if p then
                    local d=(p.Position-cam.CFrame.Position).Magnitude
                    if d<bestDist then
                        bestDist=d
                        best=model
                        bestPart=p
                    end
                end
            end
        end
        return best,bestPart
    end

    -- GunTesting local GunPlugin adapter. Direct function replacement only.
    local GunPlugin=nil
    local originalLook=nil
    local installing=false

    local function findGunPluginModule()
        local ps=LP:FindFirstChild("PlayerScripts")
        if not ps then return nil end
        local gc=ps:FindFirstChild("GunController")
        local events=gc and gc:FindFirstChild("Events")
        local exact=events and events:FindFirstChild("GunPlugin")
        if exact and exact:IsA("ModuleScript") then return exact end
        for _,d in ipairs(ps:GetDescendants()) do
            if d:IsA("ModuleScript") and d.Name=="GunPlugin" then return d end
        end
        return nil
    end

    local function installGunPlugin()
        if GunPlugin or installing or not allowed() then return GunPlugin~=nil end
        installing=true
        local mod=findGunPluginModule()
        if mod then
            local ok,g=pcall(require,mod)
            if ok and type(g)=="table" and type(g.GetWorldLookAtPos)=="function" then
                GunPlugin=g
                originalLook=g.GetWorldLookAtPos
                g.GetWorldLookAtPos=function(self,...)
                    if allowed() then
                        if State.Combat.MagicBullets then
                            local _,p=chooseWorldTarget()
                            if p then return p.Position end
                        elseif State.Combat.SilentAim then
                            local _,p=chooseScreenTarget()
                            if p then return p.Position end
                        end
                    end
                    return originalLook(self,...)
                end
            end
        end
        installing=false
        return GunPlugin~=nil
    end

    task.spawn(function()
        while UI.Gui.Parent and not GunPlugin do
            if allowed() then installGunPlugin() end
            task.wait(.5)
        end
    end)

    local originalSizes=setmetatable({}, {__mode="k"})
    local antiSpin=0
    local hitboxWas=false
    local countTimer=0

    RunService:BindToRenderStep("LvkHubBotAimbot",Enum.RenderPriority.Last.Value+500,function(dt)
        local cam=Workspace.CurrentCamera
        if allowed() and State.Combat.Aimbot and cam then
            local _,p=chooseScreenTarget()
            if p then
                local wanted=CFrame.lookAt(cam.CFrame.Position,p.Position)
                cam.CFrame=cam.CFrame:Lerp(wanted,.32)
            end
        end

        local ch=LP.Character
        if State.Combat.AntiAim and ch then
            antiSpin=(antiSpin+dt*3)%(math.pi*2)
            local root=ch:FindFirstChild("HumanoidRootPart")
            local waist=(ch:FindFirstChild("UpperTorso") and ch.UpperTorso:FindFirstChild("Waist")) or (root and root:FindFirstChild("RootJoint"))
            if waist and waist:IsA("Motor6D") then
                waist.Transform=CFrame.Angles(0,math.sin(antiSpin)*.25,0)
            end
        end
    end)

    RunService.Heartbeat:Connect(function(dt)
        countTimer+=dt
        if countTimer>=1 then
            countTimer=0
            updateCount()
        end

        if allowed() and State.Combat.HitBoxes then
            for model in pairs(Registry.Bots) do
                if Registry.IsBot(model) then
                    local p=targetPart(model)
                    if p and p:IsA("BasePart") then
                        if originalSizes[p]==nil then
                            originalSizes[p]={Size=p.Size,CanCollide=p.CanCollide}
                        end
                        local n=math.max(2,State.Combat.HitboxSize or 6)
                        p.Size=Vector3.new(n,n,n)
                        p.CanCollide=false
                    end
                end
            end
        elseif hitboxWas then
            for p,state in pairs(originalSizes) do
                if p and p.Parent then
                    p.Size=state.Size
                    p.CanCollide=state.CanCollide
                end
                originalSizes[p]=nil
            end
        end
        hitboxWas=allowed() and State.Combat.HitBoxes or false
    end)
end
