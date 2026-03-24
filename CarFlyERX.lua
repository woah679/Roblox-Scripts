repeat task.wait() until _G.WindUI and _G.Window and _G.Functions
local ok, err = pcall(function()
if getgenv()._carfly_windui_tab then return end
getgenv()._carfly_windui_tab = true

-- Physics runs inside loadstring to bypass ERX setfenv which breaks BodyGyro
local src = [=[
local ok,err=pcall(function()
if getgenv()._carfly_final then return end
getgenv()._carfly_final=true

local bind=Enum.KeyCode.J
local on=false
local onCooldown=false
local currentSpeed = 150
local smoothGyro=CFrame.new()
local kWarningShown = false

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

	-- Store col so clean() can zero angular velocity on both col and root
	getgenv()._carfly_col = col

	gy=Instance.new("BodyGyro",col)
	gy.CFrame=workspace.CurrentCamera.CFrame
	gy.MaxTorque=Vector3.new(9e9,9e9,9e9)
	gy.P=9e4

	vl=Instance.new("BodyVelocity",col)
	vl.MaxForce=Vector3.new(9e9,9e9,9e9)
	vl.P=9e4
	vl.Velocity=Vector3.new()

	smoothGyro=workspace.CurrentCamera.CFrame
	local smoothVel=Vector3.new()

	hb=game:GetService("RunService").Heartbeat:Connect(function()
		if not on then if vl then vl.Velocity=Vector3.new() end return end
		if not h.Sit then clean() return end
		local t=Vector3.new()
		local u=game:GetService("UserInputService")
		local cam=workspace.CurrentCamera.CFrame
		if u:IsKeyDown(Enum.KeyCode.W) then t+=cam.LookVector*currentSpeed end
		if u:IsKeyDown(Enum.KeyCode.S) then t+=cam.LookVector*-currentSpeed end
		if u:IsKeyDown(Enum.KeyCode.A) then t+=cam.RightVector*-currentSpeed end
		if u:IsKeyDown(Enum.KeyCode.D) then t+=cam.RightVector*currentSpeed end
		smoothVel=smoothVel:Lerp(t,0.15)
		if vl then vl.Velocity=smoothVel end
		-- Smooth gyro toward camera CFrame to prevent snapping
		if gy then
			smoothGyro = smoothGyro:Lerp(cam, 0.2)
			gy.CFrame = smoothGyro
		end
	end)
end

-- Expose control API via _G so the WindUI tab (outside loadstring) can drive us
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
	setKey = function(key) bind = key end,
	setStopOnDisable = function(v) stopOnDisable = v end,
	triggerPreset    = function(name)
		if getgenv()._carfly_preset_cb then
			getgenv()._carfly_preset_cb(name)
		end
	end,
}



-- Keyboard listener: calls FlyToggle:Set() via _carfly_keybind so the
-- WindUI toggle stays in sync and api.toggle() is the single call path.
-- Do NOT call attach()/clean() here - that causes double-attach freeze.
game:GetService("UserInputService").InputBegan:Connect(function(i,g)
	if g then return end
	if i.KeyCode == bind then
		if getgenv()._carfly_keybind then
			getgenv()._carfly_keybind()
		end
	end
end)

end)
if not ok then warn(err) end
]=]
loadstring(src)()

local WindUI = _G.WindUI
local Window = _G.Window
local api    = getgenv()._carfly_api

local kWarningShown = false
local flyBind = Enum.KeyCode.J

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
        WindUI:Notify({
            Title   = "CarFly",
            Content = "CarFly: " .. (state and "ON" or "OFF"),
            Duration = 1.5,
            Icon    = state and "plane-takeoff" or "plane-landing",
        })
    end,
})

-- Keybind callback: called by keyboard listener inside loadstring.
-- Calls FlyToggle:Set() so the toggle callback is the single attach path.
getgenv()._carfly_keybind = function()
    FlyToggle:Set(not api.isOn())
end

-- Notify callback so keyboard toggle can update the WindUI toggle
getgenv()._carfly_notify = function(event)
    if event == "not_seated" then
        task.delay(0, function() FlyToggle:Set(false) end)
        WindUI:Notify({ Title = "CarFly", Content = "You must be seated!", Duration = 2, Icon = "alert-triangle" })
    elseif event == "on" then
        task.delay(0, function() FlyToggle:Set(true) end)
        WindUI:Notify({ Title = "CarFly", Content = "CarFly: ON", Duration = 1.5, Icon = "plane-takeoff" })
    elseif event == "off" then
        task.delay(0, function() FlyToggle:Set(false) end)
        WindUI:Notify({ Title = "CarFly", Content = "CarFly: OFF", Duration = 1.5, Icon = "plane-landing" })
    end
end

--CarFlyTab:Toggle({
--    Title    = "Stop on Disable (BROKEN) ",
--    Desc     = " (BROKEN ) Zeroes the car's velocity when CarFly is turned off",
 --   Icon     = "octagon",
--    Value    = false,
 --   Callback = function(state) api.setStopOnDisable(state) end,
--})

CarFlyTab:Paragraph({
    Title = "Controls",
    Desc  = "W / A / S / D to fly in camera direction",
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

-- Speed preset data
local presetDefs = {
    { name = "slow",      title = "Slow (75)",       icon = "turtle", speed = 75   },
    { name = "normal",    title = "Normal (250)",    icon = "rabbit", speed = 250  },
    { name = "fast",      title = "Fast (750)",      icon = "zap",    speed = 750  },
    { name = "ludicrous", title = "Ludicrous (3000)",icon = "rocket", speed = 3000 },
}

-- Per-preset keybind state (QoL.lua pattern: toggle stores enabled, keybind stores key)
local presetKeybindEnabled = {}
local presetKeybindKey     = {}

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
                    WindUI:Notify({ Title = "Warning", Content = "Speed 3000 may lag your PC. Press again to confirm.", Duration = 5, Icon = "alert-triangle" })
                    return
                end
                kWarningShown = false
            end
            setPreset(d.speed, d.icon)
        end,
    })

    presetKeybindEnabled[d.name] = false
    presetKeybindKey[d.name]     = nil

    CarFlyTab:Toggle({
        Title    = "Enable Keybind",
        Desc     = "Activate the keybind below for this preset",
        Icon     = "toggle-right",
        Value    = false,
        Callback = function(state)
            presetKeybindEnabled[d.name] = state
        end,
    })

    CarFlyTab:Keybind({
        Title    = "Keybind",
        Desc     = "Key to instantly set speed to " .. d.speed,
        Value    = "",
        Callback = function(v)
            -- WindUI fires this on every keypress of bound key, not just rebind.
            -- Only update when the key name looks like a rebind (not a single char trigger).
            -- We store the key here; InputBegan below does the actual triggering.
            if Enum.KeyCode[v] then
                if presetKeybindKey[d.name] ~= Enum.KeyCode[v] then
                    presetKeybindKey[d.name] = Enum.KeyCode[v]
                    WindUI:Notify({ Title = "Keybind", Content = d.title .. " key set to: " .. v, Duration = 2, Icon = d.icon })
                end
            end
        end,
    })
end

-- Single InputBegan listener for all preset keybinds (QoL.lua pattern)
game:GetService("UserInputService").InputBegan:Connect(function(input, proc)
    if proc then return end
    for _, d in ipairs(presetDefs) do
        if presetKeybindEnabled[d.name] and presetKeybindKey[d.name]
            and input.KeyCode == presetKeybindKey[d.name] then
            if d.speed == 3000 then
                if not kWarningShown then
                    kWarningShown = true
                    WindUI:Notify({ Title = "Warning", Content = "Speed 3000 may lag your PC. Press again to confirm.", Duration = 5, Icon = "alert-triangle" })
                    return
                end
                kWarningShown = false
            end
            setPreset(d.speed, d.icon)
        end
    end
end)

CarFlyTab:Section({ Title = "Keybind" })

CarFlyTab:Keybind({
    Title    = "Fly Toggle Key",
    Desc     = "Key used to toggle CarFly on / off",
    Value    = "J",
    Callback = function(v)
        if Enum.KeyCode[v] and Enum.KeyCode[v] ~= flyBind then
            flyBind = Enum.KeyCode[v]
            api.setKey(flyBind)
            WindUI:Notify({ Title = "Keybind", Content = "Fly key set to: " .. v, Duration = 2, Icon = "keyboard" })
        end
    end,
})

CarFlyTab:Section({ Titile = "About" })
CarFlyTab:Paragraph({ Title = "About",   Desc = "CarFly - fly any seated vehicle with WASD." })
CarFlyTab:Paragraph({ Title = "Warning", Desc = "Some vehicles will not face forwards." })
CarFlyTab:Paragraph({ Title = "Credits", Desc = "Original script by maven and WhoAboutYou. Edited by Claude and woah679." })

end)
local _w = _G.WindUI
if _w then _w:Notify({ Title = "CarFly (Keyboard) Loaded", Content = "CarFly is ready!", Duration = 3, Icon = "plane" }) end
if not ok then warn("[CarFly ERX] " .. tostring(err)) end
