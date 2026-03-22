local ok, err = pcall(function()
    if getgenv()._carfly_windui then return warn("CarFly already loaded.") end
    getgenv()._carfly_windui = true

    -- ── Load WindUI ──────────────────────────────────────────────────────────
    local WindUI = loadstring(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
    ))()

    -- ── State ─────────────────────────────────────────────────────────────────
    local on           = false
    local currentSpeed = 150
    local kWarningShown = false
    local flyBind      = Enum.KeyCode.J

    -- ── Physics handles ───────────────────────────────────────────────────────
    local hb, gy, vl
    local function clean()
        if hb  then hb:Disconnect(); hb = nil end
        if vl  then pcall(function() vl:Destroy(); vl = nil end) end
        if gy  then pcall(function() gy:Destroy(); gy = nil end) end
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

        hb = game:GetService("RunService").Heartbeat:Connect(function()
            if not on then if vl then vl.Velocity = Vector3.new() end return end
            if not h.Sit then clean() return end
            local t   = Vector3.new()
            local u   = game:GetService("UserInputService")
            local cam = workspace.CurrentCamera.CFrame
            if u:IsKeyDown(Enum.KeyCode.W) then t += cam.LookVector  *  currentSpeed end
            if u:IsKeyDown(Enum.KeyCode.S) then t += cam.LookVector  * -currentSpeed end
            if u:IsKeyDown(Enum.KeyCode.A) then t += cam.RightVector * -currentSpeed end
            if u:IsKeyDown(Enum.KeyCode.D) then t += cam.RightVector *  currentSpeed end
            if vl then vl.Velocity = t end
            if gy then gy.CFrame   = cam end
        end)
    end

    -- ── WindUI Window ─────────────────────────────────────────────────────────
    local Window = WindUI:CreateWindow({
        Title       = "CarFly",
        Icon        = "car",
        Author      = "CarFly Script",
        Folder      = "CarFly",
        Size        = UDim2.fromOffset(540, 400),
        Transparent = true,
        Theme       = "Dark",
        Resizable   = false,
    })

    -- ── Tab ──────────────────────────────────────────────────────────────────
    local CarFlyTab = Window:Tab({ Title = "Car Fly",     Icon = "airplane" })
  

    -- ══════════════════════════════════════════════════════════════════════════
    --  MAIN TAB
    -- ══════════════════════════════════════════════════════════════════════════
    		local Section = CarFlyTab:Section({
			Title = "Car Fly",
		})

		CarFlyTab:Toggle({
        Title    = "CarFly",
        Desc     = "Toggle car fly on / off  (must be seated in a vehicle)",
        Icon     = "plane",
        Value    = false,
        Callback = function(state)
            local h = game.Players.LocalPlayer.Character
                and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if state and (not h or not h.Sit) then
                WindUI:Notify({
                    Title    = "CarFly",
                    Content  = "You must be seated in a vehicle!",
                    Duration = 3,
                    Icon     = "alert-triangle",
                })
                -- revert the toggle visually on the next frame
                task.defer(function()
                    -- we can't call :Set() here directly since we don't store the ref above;
                    -- the toggle callback will fire again with false which is fine.
                end)
                on = false
                clean()
                return
            end
            on = state
            if on then
                attach()
                WindUI:Notify({
                    Title    = "CarFly",
                    Content  = "CarFly enabled! Use WASD to fly.",
                    Duration = 2,
                    Icon     = "airplaneDeparture",
                })
            else
                clean()
                WindUI:Notify({
                    Title    = "CarFly",
                    Content  = "CarFly disabled.",
                    Duration = 2,
                    Icon     = "airplaneArrival",
                })
            end
        end,
    })

    CarFlyTab:Paragraph({
        Title   = "Controls",
        Content = "W / A / S / D  →  fly in camera direction\n"
                .."Speed tab  →  adjust fly speed\n"
                .."Settings tab  →  change fly keybind",
    })

    -- ══════════════════════════════════════════════════════════════════════════
    --  SPEED TAB
    -- ══════════════════════════════════════════════════════════════════════════
 	local Section = CarFlyTab:Section({
		Title = "Speed",
		})
		
    -- Slider covers the sane range; the 3000 preset is handled separately.
    local SpeedSlider = CarFlyTab:Slider({
        Title = "Fly Speed",
        Desc  = "Drag to adjust speed (25 – 750)",
        Step  = 25,
        Value = {
            Min     = 25,
            Max     = 750,
            Default = 200,
        },
        Callback = function(value)
            currentSpeed = value
        end,
    })

    -- Quick-preset buttons
    CarFlyTab:Button({
        Title    = "Preset: Slow (75)",
        Desc     = "Set speed to 75",
        Icon     = "turtle",
        Callback = function()
            currentSpeed = 75
            SpeedSlider:Set(75)
            WindUI:Notify({ Title = "Speed", Content = "Speed set to 75", Duration = 1.5, Icon = "turtle" })
        end,
    })

    CarFlyTab:Button({
        Title    = "Preset: Fast (250)",
        Desc     = "Set speed to 250",
        Icon     = "rabbit",
        Callback = function()
            currentSpeed = 250
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
            SpeedSlider:Set(750)
            WindUI:Notify({ Title = "Speed", Content = "Speed set to 750", Duration = 1.5, Icon = "zap" })
        end,
    })

    CarFlyTab:Button({
        Title    = "Preset: Ludicrous (3000) ⚠️",
        Desc     = "WARNING: may lag your PC and cause bugs!",
        Icon     = "rocket",
        Callback = function()
            if not kWarningShown then
                kWarningShown = true
                WindUI:Notify({
                    Title    = "⚠️ Warning",
                    Content  = "Speed 3000 may lag your PC and cause bugs. Press again to confirm.",
                    Duration = 5,
                    Icon     = "alert-triangle",
                })
            else
                kWarningShown = false
                currentSpeed  = 3000
                -- slider max is 500, so just clamp display
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
    --  SETTINGS TAB
    -- ══════════════════════════════════════════════════════════════════════════
		local Section = CarFlyTab:Section({
			Title = "Keybind",
		})

	CarFlyTab:Keybind({
        Title    = "Fly Toggle Key",
        Desc     = "Key used to toggle CarFly on / off",
        Value    = "J",
        Callback = function(v)
            if Enum.KeyCode[v] then
                flyBind = Enum.KeyCode[v]
                WindUI:Notify({
                    Title   = "Keybind",
                    Content = "Fly key set to: " .. v,
                    Duration = 2,
                    Icon    = "keyboard",
                })
            end
        end,
    })

    CarFlyTab:Paragraph({
        Title   = "About",
        Content = "CarFly lets you pilot any seated vehicle through the air.\n"
                .."Attach is automatic when you enable the toggle while seated.\n"
                .."Physics objects (BodyGyro / BodyVelocity) are cleaned up on disable.",
    })

    -- ── Keyboard listener (fly toggle via keybind) ─────────────────────────
    -- WindUI's Keybind element only fires a callback; the actual flying toggle
    -- is handled by the Toggle element above.  We keep a secondary InputBegan
    -- listener so the flyBind key still works while the window is hidden.
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
            if on then attach() else clean() end
            WindUI:Notify({
                Title    = "CarFly",
                Content  = "CarFly: " .. (on and "ON" or "OFF"),
                Duration = 1.5,
                Icon     = on and "sfsymbols:airplaneDeparture" or "sfsymbols:airplaneArrival",
            })
        end
    end)

end) -- pcall end
		WindUI:Notify({
                Title    = "test",
                Content  = "testt",
                Duration = 1.5,
                Icon     = "sfsymbols:airplaneDeparture",
		}) 
if not ok then warn("[CarFly WindUI] " .. tostring(err)) end
