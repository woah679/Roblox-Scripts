repeat task.wait() until _G.WindUI and _G.Window and _G.Functions
local ok, err = pcall(function()
if getgenv()._carfly_mobile_tab then return end
getgenv()._carfly_mobile_tab = true

local src = [=[
local ok,err=pcall(function()
if getgenv()._carfly_final then return end
getgenv()._carfly_final=true

local on=false
local onCooldown=false
local currentSpeed = 150
local smoothGyro=CFrame.new()

local hb,gy,vl
local stopOnDisable = false

local function clean()
	if hb then hb:Disconnect() hb=nil end
	if gy then pcall(function() gy:Destroy() gy=nil end) end
	if vl then
		if stopOnDisable then
			-- Zero velocity then destroy, same frame.
			-- BodyVelocity destruction while airborne stops momentum like the original.
			pcall(function()
				vl.Velocity = Vector3.new()
			end)
			pcall(function() vl:Destroy() vl=nil end)
		else
			pcall(function() vl:Destroy() vl=nil end)
		end
	end
end

local function attach()
	local p=game.Players.LocalPlayer
	local c=p and p.Character
	if not c then return end
	local h=c:FindFirstChildOfClass("Humanoid")
	if not h or not h.Sit then return end
	local st=h.SeatPart
	if not st then return end
	local v=st.Parent
	if not v or not v:FindFirstChild("Body") then return end
	local col=v.Body:FindFirstChild("CollisionPart")
	if not col then return end

	for _,d in ipairs(v:GetDescendants()) do if d:IsA("TouchTransmitter") then d:Destroy() end end

	workspace.CurrentCamera.CameraSubject=h

	getgenv()._carfly_col = col

	gy=Instance.new("BodyGyro",col)
	gy.CFrame=workspace.CurrentCamera.CFrame
	gy.MaxTorque=Vector3.new(9e9,9e9,9e9)
	gy.P=9e4

	vl=Instance.new("BodyVelocity",col)
	vl.MaxForce=Vector3.new(9e9,9e9,9e9)
	vl.P=9e4
	vl.Velocity=Vector3.new()

	-- ControlModule for mobile joystick
	local controls
	local ok2, cm = pcall(function()
		return require(game.Players.LocalPlayer.PlayerScripts
			:WaitForChild("PlayerModule")):GetControls()
	end)
	if ok2 then controls = cm end

	smoothGyro=workspace.CurrentCamera.CFrame
	local smoothVel=Vector3.new()

	hb=game:GetService("RunService").Heartbeat:Connect(function()
		if not on then if vl then vl.Velocity=Vector3.new() end return end
		if not h.Sit then clean() return end
		local cam=workspace.CurrentCamera.CFrame
		local fwd, side = 0, 0
		if controls then
			local mv = controls:GetMoveVector()
			fwd  = -mv.Z
			side =  mv.X
		end
		local t = cam.LookVector * fwd * currentSpeed
		        + cam.RightVector * side * currentSpeed
		smoothVel=smoothVel:Lerp(t,0.15)
		if vl then vl.Velocity=smoothVel end
		-- Smooth gyro toward camera CFrame to prevent snapping
		if gy then
			smoothGyro = smoothGyro:Lerp(cam, 0.2)
			gy.CFrame = smoothGyro
		end
	end)
end

getgenv()._carfly_api = {
	toggle = function(state)
		if onCooldown then return false end
		local h=game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if state and (not h or not h.Sit) then return false end
		onCooldown = true
		task.delay(0.25, function() onCooldown = false end)
		on = state
		if on then
			attach()
		else
			-- on is already false so the heartbeat will zero vl.Velocity this frame.
			-- Use task.defer so clean() runs AFTER the current heartbeat fires,
			-- matching how the original CarFly.lua stops momentum naturally.
			task.defer(clean)
		end
		return true
	end,
	setSpeed = function(speed) currentSpeed = speed end,
	getSpeed = function() return currentSpeed end,
	isOn = function() return on end,
	setStopOnDisable = function(v) stopOnDisable = v end,
}

end)
if not ok then warn(err) end
]=]
loadstring(src)()

local WindUI = _G.WindUI
local Window = _G.Window
local api    = getgenv()._carfly_api

local kWarningShown = false

-- ── On-screen toggle button ───────────────────────────────────────────────
-- local screenGui = Instance.new("ScreenGui")
--screenGui.ResetOnSpawn = false
--screenGui.IgnoreGuiInset = true
--screenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

--local btn = Instance.new("TextButton", screenGui)
--btn.Size             = UDim2.new(0, 110, 0, 50)
--btn.Position         = UDim2.new(0.5, -55, 0.85, 0)
--btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
--btn.BackgroundTransparency = 0.3
--btn.TextColor3       = Color3.fromRGB(255, 255, 255)
--btn.Text             = "✈ CarFly: OFF"
--btn.TextSize         = 16
--btn.Font             = Enum.Font.GothamSemibold
--btn.AutoButtonColor  = false

--local corner = Instance.new("UICorner", btn)
--corner.CornerRadius = UDim.new(0, 10)

--local stroke = Instance.new("UIStroke", btn)
--stroke.Color     = Color3.fromRGB(255, 0, 0)
--stroke.Thickness = 2

--local function updateBtn(state)
--    if state then
--        btn.Text             = "✈ CarFly: ON"
--        btn.BackgroundColor3 = Color3.fromRGB(20, 80, 20)
--        stroke.Color         = Color3.fromRGB(0, 255, 80)
--    else
--        btn.Text             = "✈ CarFly: OFF"
--        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
--        stroke.Color         = Color3.fromRGB(255, 0, 0)
--    end
--end

-- Draggable + tappable: detect drag by movement distance.
-- If finger moves <10px it's a tap; if more it's a drag.
--- Using InputEnded avoids TouchTap/InputBegan conflicts.
--local dragStart, startPos, didDrag = nil, nil, false

--btn.InputBegan:Connect(function(input)
--    if input.UserInputType == Enum.UserInputType.Touch then
--        dragStart = input.Position
--        startPos  = btn.Position
--        didDrag   = false
--    end
--end)

-- btn.InputChanged:Connect(function(input)
--    if dragStart and input.UserInputType == Enum.UserInputType.Touch then
--        local delta = input.Position - dragStart
--        if delta.Magnitude > 10 then
--            didDrag = true
--        end
--        if didDrag then
--            btn.Position = UDim2.new(
--                startPos.X.Scale, startPos.X.Offset + delta.X,
--                startPos.Y.Scale, startPos.Y.Offset + delta.Y
--            )
--        end
--    end
-- end)

-- btn.InputEnded:Connect(function(input)
--    if input.UserInputType == Enum.UserInputType.Touch then
--        if not didDrag and FlyToggle then
--            FlyToggle:Set(not api.isOn())
--        end
--        dragStart = nil
--        didDrag   = false
--    end
-- end)

-- ── WindUI Tab ────────────────────────────────────────────────────────────
local CarFlyTab = Window:Tab({ Title = "Car Fly", Icon = "plane" })
CarFlyTab:Section({ Title = "Car Fly" })

local FlyToggle = CarFlyTab:Toggle({
    Title    = "CarFly",
    Desc     = "Toggle car fly on / off (must be seated in a vehicle)",
    Icon     = "plane",
    Value    = false,
    Callback = function(state)
        local ok = api.toggle(state)
        if state and not ok then
            task.delay(0, function() FlyToggle:Set(false) end)
            WindUI:Notify({ Title = "CarFly", Content = "You must be seated in a vehicle!", Duration = 3, Icon = "alert-triangle" })
            return
        end
        updateBtn(state)
        WindUI:Notify({
            Title   = "CarFly",
            Content = "CarFly: " .. (state and "ON" or "OFF"),
            Duration = 1.5,
            Icon    = state and "plane-takeoff" or "plane-landing",
        })
    end,
})

--CarFlyTab:Toggle({
--    Title    = "Stop on Disable",
--    Desc     = "Zeroes the car\'s velocity and rotation when CarFly is turned off",
--    Icon     = "octagon",
--    Value    = false,
--    Callback = function(state) api.setStopOnDisable(state) end,
--})

CarFlyTab:Paragraph({
    Title = "Controls",
    Desc  = "Use the on-screen button or this toggle to enable CarFly.\nMove with the joystick and camera.",
})

CarFlyTab:Section({ Title = "Speed" })

local SpeedSlider = CarFlyTab:Slider({
    Title = "Fly Speed",
    Desc  = "Drag to adjust speed (25 - 3000)",
    Step  = 25,
    Value = { Min = 25, Max = 3000, Default = 150 },
    Callback = function(value) api.setSpeed(value) end,
})

local function setPreset(speed, icon)
    api.setSpeed(speed)
    SpeedSlider:Set(speed)
    WindUI:Notify({ Title = "Speed", Content = "Speed set to " .. speed, Duration = 1.5, Icon = icon })
end

local presetDefs = {
    { name = "slow",      title = "Slow (75)",       icon = "turtle", speed = 75   },
    { name = "normal",    title = "Normal (250)",     icon = "rabbit", speed = 250  },
    { name = "fast",      title = "Fast (750)",       icon = "zap",    speed = 750  },
    { name = "ludicrous", title = "Ludicrous (3000)", icon = "rocket", speed = 3000 },
}

for _, def in ipairs(presetDefs) do
    local d = def
    CarFlyTab:Section({ Title = "Preset: " .. d.title })
    CarFlyTab:Button({
        Title    = "Set Speed to " .. d.speed,
        Icon     = d.icon,
        Desc     = d.speed == 3000 and "WARNING: may lag your PC!" or nil,
        Callback = function()
            if d.speed == 3000 then
                if not kWarningShown then
                    kWarningShown = true
                    WindUI:Notify({ Title = "Warning", Content = "Speed 3000 may lag. Press again to confirm.", Duration = 5, Icon = "alert-triangle" })
                    return
                end
                kWarningShown = false
            end
            setPreset(d.speed, d.icon)
        end,
    })
end

CarFlyTab:Section({ Title = "About" })
CarFlyTab:Paragraph({ Title = "About",   Desc = "CarFly (Mobile) - fly any seated vehicle with the joystick." })
CarFlyTab:Paragraph({ Title = "Warning", Desc = "Some vehicles will not face forwards." })
CarFlyTab:Paragraph({ Title = "Credits", Desc = "Original script by maven and WhoAboutYT. Edited by Claude and woah679." })

end)
local _w = _G.WindUI
if _w then _w:Notify({ Title = "CarFly (Mobile) Loaded", Content = "CarFly is ready!", Duration = 3, Icon = "plane" }) end
if not ok then warn("[CarFly ERX Mobile]" .. tostring(err)) end
