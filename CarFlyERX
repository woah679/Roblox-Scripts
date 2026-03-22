repeat task.wait() until _G.WindUI and _G.Functions
local ok, err = pcall(function()
    if getgenv()._carfly_windui then return warn("CarFly already loaded.") end
    getgenv()._carfly_windui = true

 

	local WindUI = _G.WindUI
	local Window = _G.Window
	local Tabs = _G.Tabs
	local Functions    = _G.Functions
	local Connections  = _G.Connections

    -- ── State ─────────────────────────────────────────────────────────────────
    local on            = false
    local currentSpeed  = 250
    local kWarningShown = false
    local flyBind       = Enum.KeyCode.J

    -- ── Physics handles ───────────────────────────────────────────────────────
    local hb, gy, vl
    local function clean()
        if hb then hb:Disconnect(); hb = nil end
        if vl then pcall(function() vl:Destroy(); vl = nil end) end
        if gy then pcall(function() gy:Destroy(); gy = nil end) end
    end

    local function attach()
        local p = game.Players.LocalPlayer
        local c = p and p.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        if not h or not h.Sit then return end
        local st = h.SeatPart
        if not st then return end
        local v = st.Parent
        if not v or not v:FindFirstChild("Body") then return end
        local col = v.Body:FindFirstChild("CollisionPart")
        if not col then return end

        for _, d in ipairs(v:GetDescendants()) do
            if d:IsA("TouchTransmitter") then d:Destroy() end
        end

        workspace.CurrentCamera.CameraSubject = h

        gy = Instance.new("BodyGyro", col)
        gy.CFrame    = workspace.CurrentCamera.CFrame
        gy.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        gy.P         = 9e4

        vl = Instance.new("BodyVelocity", col)
        vl.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        vl.P        = 9e4
        vl.Velocity = Vector3.new()

        -- Cache ControlModule once so we can read the mobile joystick MoveVector
        local controls
        local ok2, cm = pcall(function()
            return require(game.Players.LocalPlayer.PlayerScripts
                :WaitForChild("PlayerModule")):GetControls()
        end)
        if ok2 then controls = cm end

        hb = game:GetService("RunService").Heartbeat:Connect(function()
            if not on then if vl then vl.Velocity = Vector3.new() end return end
            if not h.Sit then clean() return end
            local u   = game:GetService("UserInputService")
            local cam = workspace.CurrentCamera.CFrame

            -- Keyboard
            local fwd  = (u:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
                       - (u:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
            local side = (u:IsKeyDown(Enum.KeyCode.D) and 1 or 0)
                       - (u:IsKeyDown(Enum.KeyCode.A) and 1 or 0)

            -- Mobile joystick: Roblox routes the on-screen thumbstick through
            -- the ControlModule's MoveVector (X = strafe, Z = forward/back).
            -- This is the only reliable cross-platform source for mobile input.
            if fwd == 0 and side == 0 and controls then
                local mv = controls:GetMoveVector()
                fwd  = -mv.Z  -- negative Z = forward in camera space
                side =  mv.X
            end

            local t = cam.LookVector * fwd * currentSpeed
                    + cam.RightVector * side * currentSpeed
            if vl then vl.Velocity = t end
            if gy then gy.CFrame   = cam end
        end)
    end

    -- ── WindUI Tab ─────────────────────────────────────────────────────────

    local CarFlyTab = Window:Tab({ Title = "Car Fly", Icon = "plane" })

    -- ══════════════════════════════════════════════════════════════════════════
    --  CAR FLY SECTION
    -- ══════════════════════════════════════════════════════════════════════════
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
                    -- Revert the toggle after WindUI finishes its own state update
                    task.delay(0, function() FlyToggle:Set(false) end)
                    WindUI:Notify({
                        Title    = "CarFly",
                        Content  = "You must be seated in a vehicle!",
                        Duration = 3,
                        Icon     = "alert-triangle",
                    })
                    return
                end
                on = true
                attach()
                WindUI:Notify({
                    Title    = "CarFly",
                    Content  = "CarFly enabled! Use WASD to fly.",
                    Duration = 2,
                    Icon     = "plane-takeoff",
                })
            else
                on = false
                clean()
                WindUI:Notify({
                    Title    = "CarFly",
                    Content  = "CarFly disabled.",
                    Duration = 2,
                    Icon     = "plane-landing",
                })
            end
        end,
    })

    CarFlyTab:Paragraph({
        Title = "Controls",
        Desc  = "W A S D / Mobile joystick  →  fly in camera direction\n"
              .."Use the Speed section below to adjust fly speed\n"
              .."Use the Keybind section to change the fly toggle key",
    })

    -- ══════════════════════════════════════════════════════════════════════════
    --  SPEED SECTION
    -- ══════════════════════════════════════════════════════════════════════════
    CarFlyTab:Section({ Title = "Speed" })

    local SpeedSlider = CarFlyTab:Slider({
        Title = "Fly Speed",
        Desc  = "Drag to adjust speed (25 – 750)",
        Step  = 25,
        Value = {
            Min     = 25,
            Max     = 1000,
            Default = 250,
        },
        Callback = function(value)
            currentSpeed = value
        end,
    })

    CarFlyTab:Button({
        Title    = "Preset: Slow (75)",
        Desc     = "Set speed to 75",
        Icon     = "turtle",
        Callback = function()
            currentSpeed = 75
			SpeedSlider:SetMax(1000)
            SpeedSlider:Set(75)
            WindUI:Notify({ Title = "Speed", Content = "Speed set to 75", Duration = 1.5, Icon = "turtle" })
        end,
    })

    CarFlyTab:Button({
        Title    = "Preset: Normal (250)",
        Desc     = "Set speed to 250",
        Icon     = "rabbit",
        Callback = function()
            currentSpeed = 250
			SpeedSlider:SetMax(1000)
            SpeedSlider:Set(250)
            WindUI:Notify({ Title = "Speed", Content = "Speed set to 250", Duration = 1.5, Icon = "rabbit" })
        end,
    })

    CarFlyTab:Button({
        Title    = "Preset: Fast (750)",
        Desc     = "Set speed to 750",
        Icon     = "zap",
        Callback = function()
            currentSpeed = 750
			SpeedSlider:SetMax(1000)
            SpeedSlider:Set(750)
            WindUI:Notify({ Title = "Speed", Content = "Speed set to 750", Duration = 1.5, Icon = "zap" })
        end,
    })

    CarFlyTab:Button({
        Title    = "Preset: Ludicrous (3000) ⚠️",
        Desc     = "WARNING: may lag your PC and cause your car to glitch!",
        Icon     = "rocket",
        Callback = function()
            if not kWarningShown then
                kWarningShown = true
                WindUI:Notify({
                    Title    = "⚠️ Warning",
                    Content  = "Speed 3000 may lag your PC and cause your car to glitch. Press again to confirm.",
                    Duration = 5,
                    Icon     = "alert-triangle",
                })
            else
                kWarningShown = false
                currentSpeed  = 3000
                SpeedSlider:SetMax(3000)
                SpeedSlider:Set(3000)
                WindUI:Notify({
                    Title    = "Speed",
                    Content  = "Speed set to 3000. Good luck!",
                    Duration = 2,
                    Icon     = "rocket",
                })
            end
        end,
    })

    -- ══════════════════════════════════════════════════════════════════════════
    --  KEYBIND SECTION
    -- ══════════════════════════════════════════════════════════════════════════
    CarFlyTab:Section({ Title = "Keybind" })

    CarFlyTab:Keybind({
        Title    = "Fly Toggle Key",
        Desc     = "Key used to toggle CarFly on / off",
        Value    = "J",
        Callback = function(v)
            if Enum.KeyCode[v] then
                flyBind = Enum.KeyCode[v]
                WindUI:Notify({
                    Title    = "Keybind",
                    Content  = "Fly key set to: " .. v,
                    Duration = 2,
                    Icon     = "keyboard",
                })
            end
        end,
    })

    CarFlyTab:Paragraph({
        Title = "About",
        Desc  = "CarFly lets you fly any vehicle you can drive.\n"
              .."Attach is automatic when you enable the toggle while seated.\n"
              .."Physics objects (BodyGyro / BodyVelocity) are cleaned up on disable.",
    })

	CarFlyTab:Paragraph({
		Title = "Warning",
		Desc = "Some vehicles will not face forwards."
	})

	CarFlyTab:Paragraph({
		Title = "Credits",
		Desc = "Original script made by maven and WhoAboutYT. Edited by Claude and woah679."
	})


    -- ── Keyboard listener (fly toggle via keybind) ────────────────────────────
    game:GetService("UserInputService").InputBegan:Connect(function(i, g)
        if g then return end
        if i.KeyCode == flyBind then
            local h = game.Players.LocalPlayer.Character
                and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if not h or not h.Sit then
                WindUI:Notify({
                    Title    = "CarFly",
                    Content  = "You must be seated in a vehicle!",
                    Duration = 2,
                    Icon     = "alert-triangle",
                })
				return
            end
            on = not on
            FlyToggle:Set(on)
            if on then attach() else clean() end
            WindUI:Notify({
                Title    = "CarFly",
                Content  = "CarFly: " .. (on and "ON" or "OFF"),
                Duration = 1.5,
                Icon     = on and "plane-takeoff" or "plane-landing",
            })
        end
    end)

end) -- pcall end
if not ok then warn("[CarFly WindUI] " .. tostring(err)) end
