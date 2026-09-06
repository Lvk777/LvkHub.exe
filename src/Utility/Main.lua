return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local TeleportService=game:GetService("TeleportService")
    local HttpService=game:GetService("HttpService")
    local VirtualUser=game:GetService("VirtualUser")
    local CoreGui=game:GetService("CoreGui")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Utility

    UI.Section(page,"Utility")
    UI.Toggle(page,"AntiAFK",function() return State.Utility.AntiAFK end,function(v) State.Utility.AntiAFK=v end)
    UI.Toggle(page,"NoMenuFog",function() return State.Utility.NoMenuFog end,function(v) State.Utility.NoMenuFog=v end)

    UI.Button(page,"Rejoin current server","REJOIN",function(b)
        b.Text="REJOINING..."
        local ok=pcall(function()
            if game.JobId~="" then TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) else TeleportService:Teleport(game.PlaceId,LP) end
        end)
        if not ok then pcall(function() TeleportService:Teleport(game.PlaceId,LP) end) end
        task.wait(1); b.Text="REJOIN"
    end)

    UI.Button(page,"ServerHop","HOP",function(b)
        b.Text="SEARCHING..."
        local ok,body=pcall(function()
            return game:HttpGet(("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId))
        end)
        if ok then
            local decoded=HttpService:JSONDecode(body)
            for _,server in ipairs(decoded.data or {}) do
                if server.id~=game.JobId and tonumber(server.playing or 0)<tonumber(server.maxPlayers or 0) then
                    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId,server.id,LP) end)
                    break
                end
            end
        end
        task.wait(1); b.Text="HOP"
    end)

    LP.Idled:Connect(function()
        if not State.Utility.AntiAFK then return end
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0,0))
        end)
    end)

    task.spawn(function()
        while UI.Gui.Parent do
            task.wait(.5)
            if State.Utility.NoMenuFog then
                for _,root in ipairs({CoreGui,LP:FindFirstChildOfClass("PlayerGui")}) do
                    if root then
                        for _,d in ipairs(root:GetDescendants()) do
                            if d:IsA("BlurEffect") then d.Enabled=false end
                        end
                    end
                end
                for _,d in ipairs(game:GetService("Lighting"):GetChildren()) do
                    if d:IsA("BlurEffect") then d.Enabled=false end
                end
            end
        end
    end)
end
