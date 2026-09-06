-- Bot-practice Combat. Only targets Registry.Bots; real Roblox Player characters are excluded by Registry.
-- No metamethod hooks, kick suppression, anti-cheat bypass or evasion.

return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")
    local Workspace=game:GetService("Workspace")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Combat

    State.Combat.SelectedBot=nil

    UI.Section(page,"Combat • Bot Practice")
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
    UI.Toggle(page,"Aimbot (hold Mouse2)",function() return State.Combat.Aimbot end,function(v) State.Combat.Aimbot=v end)
    UI.Toggle(page,"Silent Aim (bot adapter)",function() return State.Combat.SilentAim end,function(v) State.Combat.SilentAim=v end)
    UI.Toggle(page,"HitBoxes",function() return State.Combat.HitBoxes end,function(v) State.Combat.HitBoxes=v end)
    UI.Number(page,"HitBox Size",function() return State.Combat.HitboxSize end,function(v) State.Combat.HitboxSize=v end,2,20)
    UI.Toggle(page,"AntiAim (local pose)",function() return State.Combat.AntiAim end,function(v) State.Combat.AntiAim=v end)

    local function targetPart(model)
        if not model or not Registry.IsBot(model) then return nil end
        return model:FindFirstChild(State.Combat.AimPart or "Head") or Registry.RootOf(model)
    end
    local function chooseTarget()
        if State.Combat.SelectedBot and Registry.IsBot(State.Combat.SelectedBot) then return State.Combat.SelectedBot,targetPart(State.Combat.SelectedBot) end
        local cam=Workspace.CurrentCamera; if not cam then return nil end
        local mouse=UIS:GetMouseLocation(); local best,bestPart,bestPx=nil,nil,math.huge
        for model in pairs(Registry.Bots) do
            if Registry.IsBot(model) then
                local p=targetPart(model)
                if p then
                    local s,on=cam:WorldToViewportPoint(p.Position)
                    if on and s.Z>0 then
                        local px=(Vector2.new(s.X,s.Y)-mouse).Magnitude
                        if px<bestPx then bestPx=px; best=model; bestPart=p end
                    end
                end
            end
        end
        return best,bestPart
    end

    local originalSizes=setmetatable({}, {__mode="k"})
    local mouse2=false
    UIS.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 then mouse2=true end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 then mouse2=false end end)

    -- Optional GunTesting-style adapter: direct function replacement only, no __namecall/metatable hook.
    local GunPlugin=nil
    local originalLook=nil
    local function installGunPlugin()
        if GunPlugin then return true end
        local ps=LP:FindFirstChild("PlayerScripts"); if not ps then return false end
        for _,d in ipairs(ps:GetDescendants()) do
            if d:IsA("ModuleScript") and d.Name=="GunPlugin" then
                local ok,g=pcall(require,d)
                if ok and type(g)=="table" and type(g.GetWorldLookAtPos)=="function" then
                    GunPlugin=g; originalLook=g.GetWorldLookAtPos
                    g.GetWorldLookAtPos=function(self,...)
                        if State.Combat.SilentAim then
                            local _,p=chooseTarget()
                            if p then return p.Position end
                        end
                        return originalLook(self,...)
                    end
                    return true
                end
            end
        end
        return false
    end
    task.spawn(function() for _=1,30 do if installGunPlugin() then break end; task.wait(.3) end end)

    local antiSpin=0
    RunService:BindToRenderStep("LvkHubBotAimbot",Enum.RenderPriority.Last.Value+100,function(dt)
        local cam=Workspace.CurrentCamera
        if State.Combat.Aimbot and mouse2 and cam then
            local _,p=chooseTarget()
            if p then
                local wanted=CFrame.lookAt(cam.CFrame.Position,p.Position)
                cam.CFrame=cam.CFrame:Lerp(wanted,.18)
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

    RunService.Heartbeat:Connect(function()
        if State.Combat.HitBoxes then
            for model in pairs(Registry.Bots) do
                if Registry.IsBot(model) then
                    local p=targetPart(model)
                    if p and p:IsA("BasePart") then
                        if originalSizes[p]==nil then originalSizes[p]=p.Size end
                        p.Size=Vector3.new(State.Combat.HitboxSize,State.Combat.HitboxSize,State.Combat.HitboxSize)
                        p.CanCollide=false
                    end
                end
            end
        else
            for p,size in pairs(originalSizes) do if p and p.Parent then p.Size=size end; originalSizes[p]=nil end
        end
    end)
end
