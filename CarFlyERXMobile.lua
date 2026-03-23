repeat task.wait() until _G.WindUI and _G.Functions
local ok, err = pcall(function()
    if getgenv()._carfly_mobile then return warn("CarFly (Mobile) already loaded.") end
    getgenv()._carfly_mobile = true

    local WindUI = _G.WindUI
    local Window = _G.Window
    local Functions   = _G.Functions
    local Connections = _G.Connections

    local on            = false
    local stopOnDisable = false
    local currentSpeed  = 250
    local kWarningShown = false

    local hb, gy, vl, rootRef
    local function clean()
        if hb then hb:Disconnect(); hb = nil end
        if vl then
            if stopOnDisable and rootRef then
                pcall(function() rootRef.AssemblyLinearVelocity  = Vector3.new() end)
                pcall(function() rootRef.AssemblyAngularVelocity = Vector3.new() end)
            end
            pcall(function() vl:Destroy(); vl = nil end)
        end
        if gy then pcall(function() gy:Destroy(); gy = nil end) end
        rootRef = nil
    end

    local function attach()
        local p  = game.Players.LocalPlayer
        local c  = p and p.Character
        if not c then return end
        local h  = c:FindFirstChildOfClass("Humanoid")
        if not h or not h.Sit then return end
        local st = h.SeatPart
        if not st then return end
        local v  = st.Parent
        if not v or not v:FindFirstChild("Body") then return end
        local col = v.Body:FindFirstChild("CollisionPart")
        if not col then return end

        for _, d in ipairs(v:GetDescendants()) do
            if d:IsA("TouchTransmitter") then d:Destroy() end
        end

        workspace.CurrentCamera.CameraSubject = h

        local root = col.AssemblyRootPart or col
        rootRef = root

        gy = Instance.new("BodyGyro", root)
        gy.CFrame    = workspace.CurrentCamera.CFrame
        gy.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        gy.P         = 9e4

        vl = Instance.new("BodyVelocity", root)
        vl.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        vl.P        = 9e4
        vl.Velocity = Vector3.new()

        -- ControlModule is the only reliable source for the mobile on-screen joystick
        local controls
        local ok2, cm = pcall(function()
            return require(game.Players.LocalPlayer.PlayerScripts
                :WaitForChild("PlayerModule")):GetControls()
        end)
        if ok2 then controls = cm end

        local smoothVel = Vector3.new()

        hb = game:GetService("RunService").Heartbeat:Connect(function()
            if not on then if vl then vl.Velocity = Vector3.new() end return end
            if not h.Sit then clean() return end
            local cam = workspace.CurrentCamera.CFrame
            local fwd, side = 0, 0

            if controls then
                local mv = controls:GetMoveVector()
                fwd  = -mv.Z
                side =  mv.X
            end

            if gy then gy.CFrame = cam end
            local targetVel = cam.LookVector * fwd * currentSpeed
                            + cam.RightVector * side * currentSpeed
            smoothVel = smoothVel:Lerp(targetVel, 0.15)
            if vl then vl.Velocity = smoothVel end
        end)
    end

    local CarFlyTab = Window:Tab({ Title = "Car Fly", Icon = "plane" })
    CarFlyTab:Section({ Title = "Car Fly" })

    local FlyToggle = CarFlyTab:Toggle({
        Title    = "CarFly",
        Desc     = "Toggle car fly on / off (must be seated in a vehicle)",
        Icon     = "plane",
        Value    = false,
        Callback = function(state)
            if state then
                local h = game.Players.LocalPlayer.Character
                    and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if not h or not h.Sit then
                    task.delay(0, function() FlyToggle:Set(false) end)
                    WindUI:Notify({ Title = "CarFly", Content = "You must be seated in a vehicle!", Duration = 3, Icon = "alert-triangle" })
                    return
                end
                on = true
                attach()
                WindUI:Notify({ Title = "CarFly", Content = "CarFly enabled! Use the joystick to fly.", Duration = 2, Icon = "plane-takeoff" })
            else
                on = false
                clean()
                WindUI:Notify({ Title = "CarFly", Content = "CarFly disabled.", Duration = 2, Icon = "plane-landing" })
            end
        end,
    })

    CarFlyTab:Toggle({
        Title    = "Stop on Disable",
        Desc     = "Zeroes the car's velocity when CarFly is turned off",
        Icon     = "octagon",
        Value    = false,
        Callback = function(state) stopOnDisable = state end,
    })

    CarFlyTab:Paragraph({
        Title = "Controls",
        Desc  = "Use the on-screen joystick to fly in camera direction",
    })

    CarFlyTab:Section({ Title = "Speed" })

    local SpeedSlider = CarFlyTab:Slider({
        Title = "Fly Speed",
        Desc  = "Drag to adjust speed (25 - 3000)",
        Step  = 25,
        Value = { Min = 25, Max = 3000, Default = 250 },
        Callback = function(value) currentSpeed = value end,
    })

    CarFlyTab:Button({ Title = "Preset: Slow (75)",    Icon = "turtle", Callback = function() currentSpeed = 75;   SpeedSlider:Set(75);   WindUI:Notify({ Title = "Speed", Content = "Speed set to 75",   Duration = 1.5, Icon = "turtle" }) end })
    CarFlyTab:Button({ Title = "Preset: Normal (250)", Icon = "rabbit", Callback = function() currentSpeed = 250;  SpeedSlider:Set(250);  WindUI:Notify({ Title = "Speed", Content = "Speed set to 250",  Duration = 1.5, Icon = "rabbit" }) end })
    CarFlyTab:Button({ Title = "Preset: Fast (750)",   Icon = "zap",    Callback = function() currentSpeed = 750;  SpeedSlider:Set(750);  WindUI:Notify({ Title = "Speed", Content = "Speed set to 750",  Duration = 1.5, Icon = "zap"    }) end })

    CarFlyTab:Button({
        Title = "Preset: Ludicrous (3000)",
        Desc  = "WARNING: may lag your PC and cause your car to glitch!",
        Icon  = "rocket",
        Callback = function()
            if not kWarningShown then
                kWarningShown = true
                WindUI:Notify({ Title = "Warning", Content = "Speed 3000 may lag your PC and glitch your car. Press again to confirm.", Duration = 5, Icon = "alert-triangle" })
            else
                kWarningShown = false
                currentSpeed  = 3000
                SpeedSlider:Set(3000)
                WindUI:Notify({ Title = "Speed", Content = "Speed set to 3000. Good luck!", Duration = 2, Icon = "rocket" })
            end
        end,
    })

    CarFlyTab:Paragraph({ Title = "About",   Desc = "CarFly (Mobile) - fly any seated vehicle with the on-screen joystick." })
    CarFlyTab:Paragraph({ Title = "Warning", Desc = "Some vehicles will not face forwards." })
    CarFlyTab:Paragraph({ Title = "Credits", Desc = "Original script by maven and WhoAboutYT. Edited by Claude and woah679." })

end)
if not ok then warn("[CarFly Mobile] " .. tostring(err)) end
