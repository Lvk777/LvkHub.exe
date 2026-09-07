-- LvkHub.exe Visual runtime consistency fixes
-- Applies only to LvkHub-owned local TestPlayers/vehicle overlays.
return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local Players=game:GetService("Players")

    local LP=Players.LocalPlayer
    local crossNames={CrossL=true,CrossR=true,CrossT=true,CrossB=true}

    ------------------------------------------------------------------------
    -- Crosshair must never render over/inside the Visuals Preview card.
    ------------------------------------------------------------------------
    local function pointInside(frame,point)
        if not frame or not frame.Visible then return false end
        local p=frame.AbsolutePosition
        local s=frame.AbsoluteSize
        return point.X>=p.X and point.X<=p.X+s.X and point.Y>=p.Y and point.Y<=p.Y+s.Y
    end

    local function fixCrosshairPreview()
        local preview=UI.Gui:FindFirstChild("LvkHubUnifiedPreviewV4")
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local center=cam.ViewportSize/2
        local covered=preview and pointInside(preview,center) or false

        for name in pairs(crossNames) do
            local line=UI.Gui:FindFirstChild(name)
            if line and line:IsA("GuiObject") then
                -- Preview uses ZIndex >= 70; keep the real crosshair behind it.
                line.ZIndex=60
                if covered then line.Visible=false end
            end
        end

        -- Defensive cleanup in case an older preview module copied crosshair pieces.
        if preview then
            for _,obj in ipairs(preview:GetDescendants()) do
                if crossNames[obj.Name] and obj:IsA("GuiObject") then obj.Visible=false end
            end
        end
    end

    ------------------------------------------------------------------------
    -- Car ESP: when OFF, every Lvk/Yokai car marker is forced OFF, including
    -- markers inherited by cars that spawn after the toggle was disabled.
    ------------------------------------------------------------------------
    local function isOurCarMarker(obj)
        local n=obj.Name
        return n=="YokaiPreservedCarESP"
            or n=="YokaiPreservedCarLabel"
            or n:match("^LvkHubCarESP")~=nil
            or n:match("^LvkHubCarLabel")~=nil
    end

    local function forceCarEspOff()
        if State.Visuals.CarESP==true then return end
        local vf=Workspace:FindFirstChild("Vehicles")
        if not vf then return end
        for _,obj in ipairs(vf:GetDescendants()) do
            if isOurCarMarker(obj) then
                if obj:IsA("Highlight") or obj:IsA("BillboardGui") then
                    obj.Enabled=false
                elseif obj:IsA("GuiObject") then
                    obj.Visible=false
                end
            end
        end
    end

    ------------------------------------------------------------------------
    -- Chams wall-check from the character, not the camera.
    -- Visible = configured green, obstructed = configured red.
    -- Current combat focus remains blue.
    ------------------------------------------------------------------------
    local function characterOrigin()
        local ch=LP.Character
        if not ch then return nil end
        return ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChildWhichIsA("BasePart")
    end

    local function visibleFromCharacter(model)
        local originPart=characterOrigin()
        if not originPart or not model then return false end

        local candidates={
            model:FindFirstChild("Head"),
            model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso"),
            Registry.RootOf and Registry.RootOf(model) or nil,
        }

        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        local exclude={model}
        if LP.Character then table.insert(exclude,LP.Character) end
        if Workspace.CurrentCamera then table.insert(exclude,Workspace.CurrentCamera) end
        params.FilterDescendantsInstances=exclude
        params.IgnoreWater=true

        for _,part in ipairs(candidates) do
            if part and part:IsA("BasePart") then
                local dir=part.Position-originPart.Position
                if dir.Magnitude<.05 or Workspace:Raycast(originPart.Position,dir,params)==nil then
                    return true
                end
            end
        end
        return false
    end

    local function fixDummyChams()
        local cfg=State.Visuals._V5Config
        if type(cfg)~="table" then return end

        for model in pairs(Registry.Bots or {}) do
            if Registry.IsBot and Registry.IsBot(model) then
                local h=model:FindFirstChild("LvkHubUnifiedV5Chams")
                if h and h:IsA("Highlight") and h.Enabled then
                    local focused=State.Combat
                        and State.Combat.SelectedBot==model
                        and (State.Combat.Aimbot or State.Combat.SilentAim or State.Combat.MagicBullets or State.Combat.HitBoxes)

                    local color
                    if focused then
                        color=UI.Accent
                    elseif cfg.ESPWallCheck==true and (State.Visuals.Chams or State.Visuals.ESP) then
                        color=visibleFromCharacter(model) and cfg.ESPVisibleColor or cfg.ESPHiddenColor
                    elseif State.Visuals.Chams and not State.Visuals.ESP then
                        color=cfg.ChamsColor
                    end

                    if color then
                        h.FillColor=color
                        h.OutlineColor=color
                    end
                end
            end
        end
    end

    local carTimer=0
    RunService.RenderStepped:Connect(function(dt)
        fixCrosshairPreview()
        fixDummyChams()

        carTimer+=dt
        if carTimer>=.15 then
            carTimer=0
            forceCarEspOff()
        end
    end)
end
