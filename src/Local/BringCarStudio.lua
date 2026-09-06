-- Vehicle helper for Workspace.Vehicles > vehicle > ... > Seat1.
-- Works outside Studio when the session contains only the local real Player.

return function(Registry, UI)
    local Players=game:GetService("Players")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Local

    UI.Section(page,"Vehicle")
    local _,status=UI.Row(page,"BringCar: ready")
    status.TextColor3=Color3.fromRGB(160,170,200)

    local selected=nil
    UI.Button(page,"Select vehicle","NEXT",function()
        local list={}
        for model in pairs(Registry.Vehicles) do
            if model and model.Parent then table.insert(list,model) end
        end
        table.sort(list,function(a,b) return a.Name<b.Name end)
        if #list==0 then selected=nil; status.Text="BringCar: no vehicles found"; return end
        local i=table.find(list,selected) or 0
        selected=list[i%#list+1]
        status.Text="BringCar: "..selected.Name
    end)

    UI.Button(page,"Bring selected car","BRING",function(b)
        -- Keep this bot-practice only: if another real Roblox Player is present,
        -- do not move a replicated vehicle in their session.
        if #Players:GetPlayers()>1 then
            status.Text="BringCar: bot-only session required"
            return
        end
        if not selected or not selected.Parent then status.Text="Select a vehicle first"; return end

        local ch=LP.Character
        local hum=ch and ch:FindFirstChildOfClass("Humanoid")
        local root=ch and ch:FindFirstChild("HumanoidRootPart")
        if not ch or not hum or not root then return end

        local old=root.CFrame
        local seat=selected:FindFirstChild("Seat1",true)
            or selected:FindFirstChildWhichIsA("VehicleSeat",true)
            or selected:FindFirstChildWhichIsA("Seat",true)
        if not seat or not seat:IsA("BasePart") then status.Text="Seat1/seat not found"; return end

        local vehicleRoot=selected.PrimaryPart or seat or selected:FindFirstChildWhichIsA("BasePart",true)
        if not vehicleRoot then status.Text="Vehicle root not found"; return end

        if selected.PrimaryPart then
            selected:PivotTo(old*CFrame.new(0,0,-8))
        else
            vehicleRoot.CFrame=old*CFrame.new(0,0,-8)
        end

        task.wait(.15)
        root.CFrame=seat.CFrame*CFrame.new(0,2,0)
        task.wait(.15)
        pcall(function() seat:Sit(hum) end)
        task.wait(.35)
        if root.Parent then root.CFrame=old end

        status.Text="BringCar: "..selected.Name
        b.Text="DONE"; task.wait(.6); b.Text="BRING"
    end)
end
