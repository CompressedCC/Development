getgenv().Config = {
    SilentAim = {
        Enabled = true,  
        Keybind = Enum.KeyCode.E,  
        Prediction = 0.12,  
        DynamicPrediction = true,  
        Mode = "Target", 
        HitPart = "Head", 
        StickyTarget = true 
    },
    Aimbot = {
        Enabled = true,  
        Keybind = Enum.KeyCode.Q,  
        Prediction = 0.12,  
        Smoothness = 0.2,  
        HitPart = "Head" 
    },
    Visuals = {
        Enabled = true,  
        Tracer = true,  
        BoxESP = true,  
        NameESP = true,  
        Highlight = true,  
        Color = Color3.fromRGB(255, 0, 0),  
        Thickness = 2,  
        TextSize = 13  
    },

    Shared = {
        FOV = 600,  
        TeamCheck = false,  
        NakedCheck = false,  
        VisibilityCheck = false 
    }
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/CompressedCC/OpenAC/refs/heads/main/Bypass.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Script = {
    Functions = {},
    Targeting = {
        enabled = false,  
        position = nil,  
        current_target = nil  
    },
    Connections = {},
    Utility = {},
    Drawing = {},
    Hooks = {}
}

local original_index = nil
original_index = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if checkcaller() then
        return original_index(self, key)
    end
    if Script.Targeting.enabled and Script.Targeting.position and self:IsA("Mouse") and key == "Hit" then
        return Script.Targeting.position  
    end
    return original_index(self, key)
end))
Script.Hooks.mouse_hook_backup = original_index

function Script.Targeting:get_closest_to_mouse()
    local closest_player = nil
    local shortest_distance = math.huge
    local camera = workspace.CurrentCamera

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")

            if getgenv().Config.Shared.TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end

            if getgenv().Config.Shared.NakedCheck and not player.Character:FindFirstChildWhichIsA("Accessory") then
                continue
            end

            if getgenv().Config.Shared.VisibilityCheck then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {LocalPlayer.Character, camera}
                rayParams.FilterType = Enum.RaycastFilterType.Blacklist

                local ray = workspace:Raycast(camera.CFrame.Position, (hrp.Position - camera.CFrame.Position).Unit * 1000, rayParams)
                if ray and ray.Instance and not player.Character:IsAncestorOf(ray.Instance) then
                    continue  
                end
            end

            local screen_pos, on_screen = camera:WorldToViewportPoint(hrp.Position)
            if on_screen then
                local mouse_pos = Vector2.new(Mouse.X, Mouse.Y)
                local distance = (mouse_pos - Vector2.new(screen_pos.X, screen_pos.Y)).Magnitude
                if distance < shortest_distance and (not getgenv().Config.Aimbot.Enabled or distance <= getgenv().Config.Shared.FOV) then
                    shortest_distance = distance
                    closest_player = player
                end
            end
        end
    end

    return closest_player  
end

function Script.Targeting:update()
    local cfg = getgenv().Config.SilentAim
    local closest = nil

    if cfg.Mode == "Fov" or not Script.Targeting.current_target or not cfg.StickyTarget then
        closest = Script.Targeting:get_closest_to_mouse()
    else
        closest = Script.Targeting.current_target
    end

    if closest and closest.Character and closest.Character:FindFirstChild(cfg.HitPart) then
        local part = closest.Character:FindFirstChild(cfg.HitPart)
        local prediction = cfg.DynamicPrediction and (part.Position + part.Velocity * cfg.Prediction) or (part.Position + Vector3.zero)
        Script.Targeting.enabled = true
        Script.Targeting.current_target = closest
        Script.Targeting.position = CFrame.new(prediction)
    else
        Script.Targeting.enabled = false
        Script.Targeting.current_target = nil
        Script.Targeting.position = nil
    end
end

Script.Connections.heartbeat_connection = RunService.Heartbeat:Connect(function()
    if getgenv().Config.SilentAim.Enabled then
        Script.Targeting:update()
    end
end)

Script.Connections.keybind_connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or input.KeyCode ~= getgenv().Config.SilentAim.Keybind then return end
    local cfg = getgenv().Config.SilentAim
    if cfg.Mode == "Target" then
        if Script.Targeting.enabled then
            Script.Targeting.enabled = false
            Script.Targeting.current_target = nil
            Script.Targeting.position = nil
        else
            local target = Script.Targeting:get_closest_to_mouse()
            if target then
                Script.Targeting.current_target = target
                Script.Targeting:update()
            end
        end
    end
end)

function Script.Functions:aimbot()
    local cfg = getgenv().Config.Aimbot
    if not cfg.Enabled then return end

    local closest = Script.Targeting:get_closest_to_mouse()
    if closest and closest.Character and closest.Character:FindFirstChild(cfg.HitPart) then
        local part = closest.Character:FindFirstChild(cfg.HitPart)
        local prediction = part.Position + part.Velocity * cfg.Prediction
        local camera = workspace.CurrentCamera
        local dir = (prediction - camera.CFrame.Position).Unit
        local targetCFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + dir)

        camera.CFrame = camera.CFrame:Lerp(targetCFrame, cfg.Smoothness)
    end
end

Script.Drawing.TargetESP = {
    Tracer = Drawing.new("Line"),
    Box = Drawing.new("Square"),
    Name = Drawing.new("Text"),
    Highlight = Instance.new("Highlight")
}

for _, obj in pairs(Script.Drawing.TargetESP) do
    if typeof(obj) == "Instance" then
        obj.Enabled = false
        obj.FillColor = getgenv().Config.Visuals.Color
        obj.OutlineColor = Color3.new()
        obj.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        obj.FillTransparency = 0.5
        obj.OutlineTransparency = 0
    elseif typeof(obj) == "Drawing" then
        obj.Visible = false
        if obj.ClassName == "Text" then
            obj.Center = true
            obj.Size = getgenv().Config.Visuals.TextSize
            obj.Color = getgenv().Config.Visuals.Color
        elseif obj.ClassName == "Line" or obj.ClassName == "Square" then
            obj.Color = getgenv().Config.Visuals.Color
            obj.Thickness = getgenv().Config.Visuals.Thickness
        end
    end
end

Script.Connections.heartbeat_connection = RunService.Heartbeat:Connect(function()
    local visuals = getgenv().Config.Visuals
    local cfg = getgenv().Config

    if cfg.SilentAim.Enabled then
        Script.Targeting:update()
    end

    if cfg.Aimbot.Enabled and UserInputService:IsKeyDown(cfg.Aimbot.Keybind) then
        Script.Functions:aimbot()
    end

    local camera = workspace.CurrentCamera
    local target = Script.Targeting.current_target

    if visuals.Enabled and target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        local head = target.Character:FindFirstChild("Head")

        local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)

        if visuals.Tracer then
            local tracer = Script.Drawing.TargetESP.Tracer
            tracer.Visible = onScreen
            if onScreen then
                tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                tracer.To = Vector2.new(screenPos.X, screenPos.Y)
            end
        end

        if visuals.BoxESP then
            local box = Script.Drawing.TargetESP.Box
            box.Visible = onScreen
            if onScreen then
                local size = Vector2.new(150, 150)  
                box.Position = Vector2.new(screenPos.X - size.X / 2, screenPos.Y - size.Y / 2)
                box.Size = size
            end
        end

        if visuals.NameESP then
            local name = Script.Drawing.TargetESP.Name
            name.Visible = onScreen
            if onScreen then
                name.Text = target.Name
                name.Position = Vector2.new(screenPos.X, screenPos.Y - 20)
            end
        end

        if visuals.Highlight then
            visuals.Highlight.Enabled = true
            visuals.Highlight.Adornee = target.Character
        end

    end
end)
