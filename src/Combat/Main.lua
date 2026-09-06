-- Bot-practice Combat. Only targets Registry.Bots; real Roblox Player characters are
-- excluded by Registry. No metamethod hooks, kick suppression, anti-cheat bypass or evasion.

return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")
    local Workspace=game:GetService("Workspace")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Combat

    State.Combat.SelectedBot=nil

    UI.Section(page,"Combat")
    local _,targetLabel=UI.Row(page,"Target bot: AUTO")
    targetLabel.TextColor3=Color3.fromRGB(150,200,255)
    UI.Button(page,"Target Bot","NEXT",function()
        local list={}
        for model in pairs(Registry.Bots) do if Registry.IsBot(model) then table.insert(list,model) end end
        table.sort(list,function(a,b) return a.Name<b.Name end)
        if #list==0 then State.Combat.SelectedBot=nil; targetLabel.Text="Target bot: AUTO"; return end
        local idx=table.find(list,State.Combat.SelectedBot) or 0
        State.Combat.SelectedBot=list[idx%#list+1]
        targetLabel.Text="Target bot: "..State.Combat.SelectedBot.Name
    end)
    UI.Toggle(page,"Aimbot",function() return State.Combat.Aimbot end,function(v) State.Combat.Aimbot=v end)
    UI.Toggle(page,"Silent Aim",function() return State.Combat.SilentAim end,function(v) State.Combat.SilentAim=v end)
    UI.Toggle(page,"HitBoxes",function() return State.Combat.HitBoxes end,function(v) State.Combat.HitBoxes=v end)
    UI.Number(page,"HitBox Size",function() return State.Combat.HitboxSize end,function(v) State.Combat.HitboxSize=v end,2,20)
    UI.Dropdown(page,"Aim Part",{"Head","Torso"},function() return State.Combat.AimPart or "Head" end,function(v) State.Combat.AimPart=v end)
    UI.Toggle(page,"AntiAim",function() return State.Combat.AntiAim end,function(v) State.Combat.AntiAim=v end)

    local function targetPart(model)
        if not model or not Registry.IsBot(model) then return nil end
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

    local function chooseTarget()
        if State.Combat.SelectedBot and Registry.IsBot(State.Combat.SelectedBot) then
            return State.Combat.SelectedBot,targetPart(State.Combat.SelectedBot)
        end
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
                        if px<bestPx then bestPx=px; best=model; bestPart=p end
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
        if GunPlugin or installing then return GunPlugin~=nil end
        installing=true
        local mod=findGunPluginModule()
        if mod then
            local ok,g=pcall(require,mod)
            if ok and type(g)=="table" and type(g.GetWorldLookAtPos)=="function" then
                GunPlugin=g
                originalLook=g.GetWorldLookAtPos
                g.GetWorldLookAtPos=function(self,...)
                    if State.Combat.SilentAim then
                        local _,p=chooseTarget()
                        if p then return p.Position end
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
            installGunPlugin()
            task.wait(.5)
        end
    end)

    local originalSizes=setmetatable({}, {__mode="k"})
    local antiSpin=0
    RunService:BindToRenderStep("LvkHubBotAimbot",Enum.RenderPriority.Last.Value+500,function(dt)
        local cam=Workspace.CurrentCamera
        if State.Combat.Aimbot and cam then
            local _,p=chooseTarget()
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
            if waist and waist:IsA("Motor6D") then waist.Transform=CFrame.Angles(0,math.sin(antiSpin)*.25,0) end
        end
    end)

    local hitboxWas=false
    RunService.Heartbeat:Connect(function()
        if State.Combat.HitBoxes then
            for model in pairs(Registry.Bots) do
                if Registry.IsBot(model) then
                    local p=targetPart(model)
                    if p and p:IsA("BasePart") then
                        if originalSizes[p]==nil then originalSizes[p]={Size=p.Size,CanCollide=p.CanCollide} end
                        local n=math.max(2,State.Combat.HitboxSize or 6)
                        p.Size=Vector3.new(n,n,n)
                        p.CanCollide=false
                    end
                end
            end
        elseif hitboxWas then
            for p,state in pairs(originalSizes) do
                if p and p.Parent then p.Size=state.Size; p.CanCollide=state.CanCollide end
                originalSizes[p]=nil
            end
        end
        hitboxWas=State.Combat.HitBoxes
    end)
end
