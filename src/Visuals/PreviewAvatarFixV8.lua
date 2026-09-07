-- Robust Visuals Preview avatar renderer for vitor250407.
-- Preview-only: never inserted into Registry or used by Combat/ESP targeting.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")

    local wanted="vitor250407"
    local busy=false
    local lastAttempt=0

    local function sanitize(model)
        for _,d in ipairs(model:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Tool") then
                d:Destroy()
            elseif d:IsA("BasePart") then
                d.Anchored=true
                d.CanCollide=false
                d.CanTouch=false
                d.CastShadow=false
                d.LocalTransparencyModifier=0
            end
        end
    end

    local function fallback()
        local m=Instance.new("Model")
        m.Name="LvkHubPreviewAvatarV8"
        local skin=Color3.fromRGB(226,188,151)
        local function part(name,size,pos,color)
            local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=CFrame.new(pos);p.Anchored=true;p.CanCollide=false;p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Parent=m
        end
        part("Head",Vector3.new(1.6,1.3,1.3),Vector3.new(0,3.15,0),skin)
        part("Torso",Vector3.new(2.2,2.1,1.05),Vector3.new(0,1.45,0),Color3.fromRGB(55,72,105))
        part("Left Arm",Vector3.new(.82,2.05,.86),Vector3.new(-1.52,1.45,0),skin)
        part("Right Arm",Vector3.new(.82,2.05,.86),Vector3.new(1.52,1.45,0),skin)
        part("Left Leg",Vector3.new(.95,2.15,.98),Vector3.new(-.6,-.7,0),Color3.fromRGB(31,35,43))
        part("Right Leg",Vector3.new(.95,2.15,.98),Vector3.new(.6,-.7,0),Color3.fromRGB(31,35,43))
        return m
    end

    local function build()
        local plr=Players:FindFirstChild(wanted)
        if plr and plr.Character then
            local old=plr.Character.Archivable;plr.Character.Archivable=true
            local ok,m=pcall(function() return plr.Character:Clone() end)
            plr.Character.Archivable=old
            if ok and m then return m end
        end
        local okId,id=pcall(function() return Players:GetUserIdFromNameAsync(wanted) end)
        if okId and id then
            local okDesc,desc=pcall(function() return Players:GetHumanoidDescriptionFromUserId(id) end)
            if okDesc and desc then
                local okModel,m=pcall(function() return Players:CreateHumanoidModelFromDescription(desc,Enum.HumanoidRigType.R15) end)
                if okModel and m then return m end
            end
        end
        return fallback()
    end

    local function install()
        if busy then return end
        local frame=UI.Gui:FindFirstChild("LvkHubVisualsDummyPreview")
        if not frame then return end
        local vp=frame:FindFirstChildWhichIsA("ViewportFrame",true)
        if not vp then return end
        local world=vp:FindFirstChildWhichIsA("WorldModel")
        local cam=vp.CurrentCamera or vp:FindFirstChildWhichIsA("Camera")
        if not world or not cam then return end

        local existing=world:FindFirstChild("LvkHubPreviewAvatarV8")
        local visiblePart=existing and existing:FindFirstChildWhichIsA("BasePart",true)
        if existing and visiblePart then return end

        busy=true
        task.spawn(function()
            local model=build()
            if model then
                for _,x in ipairs(world:GetChildren()) do if x:IsA("Model") then x:Destroy() end end
                model.Name="LvkHubPreviewAvatarV8"
                sanitize(model)
                model.Parent=world

                -- Translate the model so its bounding-box center is the viewport origin.
                local ok,boxCF,size=pcall(function() return model:GetBoundingBox() end)
                if ok then
                    local pivot=model:GetPivot()
                    model:PivotTo(CFrame.new(-boxCF.Position)*pivot)
                    local ok2,centerCF,size2=pcall(function() return model:GetBoundingBox() end)
                    if ok2 then boxCF,size=centerCF,size2 end
                else
                    size=Vector3.new(4,6,2)
                end

                local center=boxCF and boxCF.Position or Vector3.zero
                local d=math.max(7.2,size.Y*1.25,size.X*2.15,size.Z*3)
                cam.FieldOfView=31
                cam.CFrame=CFrame.lookAt(center+Vector3.new(0,size.Y*.02,-d),center+Vector3.new(0,size.Y*.02,0))
                vp.CurrentCamera=cam
                vp.Ambient=Color3.fromRGB(225,225,232)
                vp.LightColor=Color3.fromRGB(255,255,255)
                vp.LightDirection=Vector3.new(-1,-1,-1)
                vp.Visible=true
            end
            lastAttempt=os.clock()
            busy=false
        end)
    end

    task.delay(.35,install)
    RunService.Heartbeat:Connect(function()
        if os.clock()-lastAttempt>1.2 then lastAttempt=os.clock();install() end
    end)
end
