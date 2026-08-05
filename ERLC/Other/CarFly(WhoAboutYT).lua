-- WhoAboutYT's Car fly

local ok, err = pcall(function()
    if getgenv()._carfly_simple then return end
    getgenv()._carfly_simple = true

    local bind = Enum.KeyCode.LeftAlt
    local minSpeed = 50
    local maxSpeed = 500
    local defaultSpeed = 150
    local on = false
    local flySpeed = defaultSpeed

    local uis = game:GetService("UserInputService")
    local runService = game:GetService("RunService")

    local ui = Instance.new("ScreenGui")
    ui.Name = "CarFlySimple"
    ui.ResetOnSpawn = false
    ui.Parent = (gethui and gethui()) or game.CoreGui

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 200, 0, 80)
    panel.Position = UDim2.new(1, -210, 1, -90)
    panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    panel.BackgroundTransparency = 0.1
    panel.BorderSizePixel = 0
    panel.Parent = ui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 6)

    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, -16, 0, 24)
    statusFrame.Position = UDim2.new(0, 8, 0, 2)
    statusFrame.BackgroundTransparency = 1
    statusFrame.Parent = panel

    local led = Instance.new("Frame")
    led.Size = UDim2.new(0, 8, 0, 8)
    led.Position = UDim2.new(0, 0, 0.5, -4)
    led.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    led.BorderSizePixel = 0
    led.Parent = statusFrame
    Instance.new("UICorner", led).CornerRadius = UDim.new(1, 0)

    local glow = Instance.new("UIStroke")
    glow.Color = Color3.fromRGB(255, 80, 80)
    glow.Thickness = 6
    glow.Transparency = 0.7
    glow.Parent = led

    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, -20, 1, 0)
    statusText.Position = UDim2.new(0, 16, 0, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "OFF"
    statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusText.TextSize = 13
    statusText.Font = Enum.Font.Gotham
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.TextYAlignment = Enum.TextYAlignment.Center
    statusText.Parent = statusFrame

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -16, 0, 30)
    sliderFrame.Position = UDim2.new(0, 8, 0, 38)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = panel

    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(0, 45, 1, 0)
    speedLabel.Position = UDim2.new(1, -45, 0, 0)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = tostring(flySpeed)
    speedLabel.TextColor3 = Color3.fromRGB(0, 180, 255)
    speedLabel.TextSize = 16
    speedLabel.Font = Enum.Font.GothamBold
    speedLabel.TextXAlignment = Enum.TextXAlignment.Center
    speedLabel.TextYAlignment = Enum.TextYAlignment.Center
    speedLabel.Parent = sliderFrame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -55, 0, 4)
    track.Position = UDim2.new(0, 0, 0.5, -2)
    track.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    track.BorderSizePixel = 0
    track.Parent = sliderFrame
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.Position = UDim2.new(0, -7, 0.5, -7)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 10
    thumb.Parent = track
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    local dragging = false

    local function updateSlider(x)
        local trackStart = track.AbsolutePosition.X
        local trackWidth = track.AbsoluteSize.X
        local relative = (x - trackStart) / trackWidth
        relative = math.clamp(relative, 0, 1)

        fill.Size = UDim2.new(relative, 0, 1, 0)
        thumb.Position = UDim2.new(relative, -7, 0.5, -7)

        flySpeed = minSpeed + (maxSpeed - minSpeed) * relative
        speedLabel.Text = tostring(math.floor(flySpeed))
    end

    thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    uis.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(uis:GetMouseLocation().X)
        end
    end)

    uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    task.wait()
    updateSlider(track.AbsolutePosition.X + track.AbsoluteSize.X * ((defaultSpeed - minSpeed) / (maxSpeed - minSpeed)))

    local hb, gy, vl

    local function clean()
        if hb then hb:Disconnect() hb = nil end
        if vl then vl:Destroy() vl = nil end
        if gy then gy:Destroy() gy = nil end
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

        workspace.CurrentCamera.CameraSubject = h

        gy = Instance.new("BodyGyro", col)
        gy.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        gy.P = 9e4

        vl = Instance.new("BodyVelocity", col)
        vl.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        vl.P = 9e4

        hb = runService.Heartbeat:Connect(function()
            if not on then
                vl.Velocity = Vector3.new()
                return
            end

            local t = Vector3.new()
            local cam = workspace.CurrentCamera.CFrame

            if uis:IsKeyDown(Enum.KeyCode.W) then t += cam.LookVector * flySpeed end
            if uis:IsKeyDown(Enum.KeyCode.S) then t += cam.LookVector * -flySpeed end
            if uis:IsKeyDown(Enum.KeyCode.A) then t += cam.RightVector * -flySpeed end
            if uis:IsKeyDown(Enum.KeyCode.D) then t += cam.RightVector * flySpeed end

            vl.Velocity = t
            gy.CFrame = cam
        end)
    end

    uis.InputBegan:Connect(function(i, gpe)
        if gpe then return end
        if i.KeyCode == bind then
            on = not on
            if on then
                led.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
                glow.Color = Color3.fromRGB(0, 255, 100)
                statusText.Text = "ON"
                attach()
            else
                led.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                glow.Color = Color3.fromRGB(255, 80, 80)
                statusText.Text = "OFF"
                clean()
            end
        end
    end)
end)

if not ok then warn(err) end
