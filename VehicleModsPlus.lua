repeat task.wait() until _G.WindUI and _G.Window and _G.Functions

local WindUI  = _G.WindUI
local Window  = _G.Window
local Tabs    = _G.Tabs

local Players          = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local LocalPlayer      = Players.LocalPlayer
local WorkSpace        = cloneref(game:GetService("Workspace"))
local Vehicles         = WorkSpace:WaitForChild("Vehicles", 9e9)

-- ─────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────

local function GetDrivenVehicle()
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildWhichIsA("Humanoid")
	if hum and hum.Sit and hum.SeatPart and hum.SeatPart.Name == "DriverSeat" then
		return hum.SeatPart.Parent
	end
end

local function GetLocalPlayerCar()
	for _, v in ipairs(Vehicles:GetChildren()) do
		if v:GetAttribute("Owner") == LocalPlayer.Name then
			return v
		end
	end
end

local function GetVehicle()
	return GetDrivenVehicle() or GetLocalPlayerCar()
end

local function GetDrive(vehicle)
	if not vehicle or not vehicle:FindFirstChild("Drive Controller") then
		return false, nil
	end
	local ok, Drive = pcall(require, vehicle:FindFirstChild("Drive Controller"))
	return ok and Drive ~= nil, ok and Drive or nil
end

local function IsElectric(Drive)
	return rawget(Drive, "Electric") == true
end

local function TryRestartVehicleUI()
	local gui  = LocalPlayer.PlayerGui:FindFirstChild("GameGui")
	local vGui = gui and gui:FindFirstChild("VehicleGui")
	local vInt = vGui and vGui:FindFirstChild("Vehicle Interface")
	if vInt then
		pcall(function()
			vInt.Drive.Enabled = false
			task.wait()
			vInt.Drive.Enabled = true
		end)
	end
end

local function Fmt(v)
	if type(v) == "number" then
		return string.format(math.floor(v) == v and "%d" or "%.3g", v)
	end
	return tostring(v)
end

local function NotifyChange(title, key, oldVal, newVal)
	WindUI:Notify({
		Title   = "Vehicle Mods+ - " .. title,
		Content = key .. "\n" .. Fmt(oldVal) .. "  →  " .. Fmt(newVal),
		Duration = 5,
	})
end

local function NotifyError(title, msg)
	WindUI:Notify({
		Title   = "Vehicle Mods+ - " .. title,
		Content = tostring(msg),
		Duration = 6,
	})
end

-- ─────────────────────────────────────────────
-- Defaults store
-- ─────────────────────────────────────────────

local VehicleDefaults = {}

local DEFAULT_KEYS = {
	-- Engine
	"Horsepower", "IdleRPM", "PeakRPM", "Redline", "EqPoint", "PeakSharpness", "CurveMult",
	"RevAccel", "RevDecay", "RevBounce", "IdleThrottle", "Flywheel", "InclineComp",
	"ThrotAccel", "ThrotDecel", "BrakeAccel", "BrakeDecel",
	-- Electric
	"Electric", "E_Horsepower", "E_Torque", "E_Redline", "E_Trans1", "E_Trans2",
	"EH_FrontMult", "EH_EndMult", "EH_EndPercent", "ET_EndMult", "ET_EndPercent",
	-- Turbo/Super
	"Turbochargers", "T_Boost", "T_Efficiency", "T_Size",
	"Superchargers", "S_Boost", "S_Efficiency", "S_Sensitivity",
	-- Transmission
	"FinalDrive", "FDMult", "ShiftUpTime", "ShiftDnTime",
	"AutoUpThresh", "AutoDownThresh", "ShiftThrot",
	"ClutchEngage", "SpeedEngage", "KickMult", "KickSpeedThreshold", "KickRPMThreshold", "ClutchRPMMult",
	"RPMEngage", "NeutralRevRPM",
	-- Drivetrain
	"Config", "TorqueVector",
	"FDiffSlipThres", "FDiffLockThres", "RDiffSlipThres", "RDiffLockThres", "CDiffSlipThres", "CDiffLockThres",
	"FDiffPower", "FDiffCoast", "FDiffPreload", "RDiffPower", "RDiffCoast", "RDiffPreload",
	-- Brakes
	"BrakeForce", "BrakeBias", "PBrakeForce", "PBrakeBias", "EBrakeForce",
	"ABSThreshold", "TCSThreshold", "TCSGradient", "TCSLimit",
	-- Suspension
	"FSusDamping", "FSusStiffness", "FAntiRoll", "FSusLength",
	"FPreCompress", "FExtensionLim", "FCompressLim", "FSusAngle", "FWsBoneLen", "FWsBoneAngle",
	"RSusDamping", "RSusStiffness", "RAntiRoll", "RSusLength",
	"RPreCompress", "RExtensionLim", "RCompressLim", "RSusAngle", "RWsBoneLen", "RWsBoneAngle",
	"FGyroDamp", "RGyroDamp",
	-- Steering
	"SteerRatio", "LockToLock", "Ackerman", "SteerInner", "SteerOuter",
	"SteerSpeed", "ReturnSpeed", "SteerDecay", "MinSteer", "MSteerExp",
	"SteerD", "SteerMaxTorque", "SteerP",
	"RSteerOuter", "RSteerInner", "RSteerSpeed", "RSteerDecay", "RSteerD", "RSteerMaxTorque", "RSteerP",
	-- Weight/Wheels
	"Weight", "WeightDist", "CGHeight", "WeightScaling",
	"FWheelDensity", "RWheelDensity", "AxleSize", "AxleDensity",
	-- Alignment
	"FCamber", "RCamber", "FCaster", "RCaster", "FToe", "RToe",
	-- Fuel
	"MaxFuel",
}

-- All numeric keys exposed in the custom value editor
local ALL_VALUE_KEYS = {
	-- Engine
	"Horsepower", "IdleRPM", "PeakRPM", "Redline", "EqPoint", "PeakSharpness", "CurveMult",
	"RevAccel", "RevDecay", "RevBounce", "IdleThrottle", "Flywheel", "InclineComp",
	"ThrotAccel", "ThrotDecel", "BrakeAccel", "BrakeDecel",
	-- Electric
	"E_Horsepower", "E_Torque", "E_Redline", "E_Trans1", "E_Trans2",
	"EH_FrontMult", "EH_EndMult", "EH_EndPercent", "ET_EndMult", "ET_EndPercent",
	-- Turbo/Super
	"Turbochargers", "T_Boost", "T_Efficiency", "T_Size",
	"Superchargers", "S_Boost", "S_Efficiency", "S_Sensitivity",
	-- Transmission
	"FinalDrive", "FDMult", "ShiftUpTime", "ShiftDnTime",
	"AutoUpThresh", "AutoDownThresh", "ShiftThrot",
	"ClutchEngage", "SpeedEngage", "KickMult", "KickSpeedThreshold", "KickRPMThreshold", "ClutchRPMMult",
	"RPMEngage", "NeutralRevRPM",
	-- Drivetrain
	"TorqueVector",
	"FDiffSlipThres", "FDiffLockThres", "RDiffSlipThres", "RDiffLockThres", "CDiffSlipThres", "CDiffLockThres",
	"FDiffPower", "FDiffCoast", "FDiffPreload", "RDiffPower", "RDiffCoast", "RDiffPreload",
	-- Brakes
	"BrakeForce", "BrakeBias", "PBrakeForce", "PBrakeBias", "EBrakeForce",
	"ABSThreshold", "TCSThreshold", "TCSGradient", "TCSLimit",
	-- Suspension
	"FSusDamping", "FSusStiffness", "FAntiRoll", "FSusLength",
	"FPreCompress", "FExtensionLim", "FCompressLim", "FSusAngle", "FWsBoneLen", "FWsBoneAngle",
	"RSusDamping", "RSusStiffness", "RAntiRoll", "RSusLength",
	"RPreCompress", "RExtensionLim", "RCompressLim", "RSusAngle", "RWsBoneLen", "RWsBoneAngle",
	"FGyroDamp", "RGyroDamp",
	-- Steering
	"SteerRatio", "LockToLock", "Ackerman", "SteerInner", "SteerOuter",
	"SteerSpeed", "ReturnSpeed", "SteerDecay", "MinSteer", "MSteerExp",
	"SteerD", "SteerMaxTorque", "SteerP",
	"RSteerOuter", "RSteerInner", "RSteerSpeed", "RSteerDecay", "RSteerD", "RSteerMaxTorque", "RSteerP",
	-- Weight/Wheels
	"Weight", "WeightDist", "CGHeight", "WeightScaling",
	"FWheelDensity", "RWheelDensity", "AxleSize", "AxleDensity",
	-- Alignment
	"FCamber", "RCamber", "FCaster", "RCaster", "FToe", "RToe",
	-- Fuel
	"MaxFuel",
}

local function StoreDefaults(vehicle)
	if VehicleDefaults[vehicle] then return end
	local ok, Drive = GetDrive(vehicle)
	if not ok then return end
	VehicleDefaults[vehicle] = {}
	for _, key in ipairs(DEFAULT_KEYS) do
		VehicleDefaults[vehicle][key] = rawget(Drive, key)
	end
end

local function ResetVehicle(vehicle)
	local ok, Drive = GetDrive(vehicle)
	if not ok then return false, "Drive Controller not found" end
	local def = VehicleDefaults[vehicle]
	if not def then return false, "No stored defaults for this vehicle" end
	for key, value in pairs(def) do
		rawset(Drive, key, value)
	end
	return true
end

-- ─────────────────────────────────────────────
-- Preset logic
-- ─────────────────────────────────────────────

local function ApplyPreset(vehicle, mult)
	local ok, Drive = GetDrive(vehicle)
	if not ok then return false, "Drive Controller not found" end

	StoreDefaults(vehicle)
	local def = VehicleDefaults[vehicle]
	if not def then return false, "Failed to read defaults" end

	-- Set values
	if IsElectric(Drive) then
		if def.E_Torque  then rawset(Drive, "E_Torque", def.E_Torque * mult) end
	else
		if def.Horsepower then
			local hp = def.Horsepower * mult
			if hp < 2000 and mult > 1.2 end
			rawset(Drive, "Horsepower", hp)
		end
	end

	if def.FinalDrive    then rawset(Drive, "FinalDrive",    def.FinalDrive / math.sqrt(mult)) end
	if def.RevAccel      then rawset(Drive, "RevAccel",      def.RevAccel      * mult) end
	if def.FAntiRoll     then rawset(Drive, "FAntiRoll",     def.FAntiRoll     * mult) end
	if def.RAntiRoll     then rawset(Drive, "RAntiRoll",     def.RAntiRoll     * mult) end
	if def.FSusStiffness then rawset(Drive, "FSusStiffness", def.FSusStiffness * mult) end
	if def.RSusStiffness then rawset(Drive, "RSusStiffness", def.RSusStiffness * mult) end
	if def.FSusDamping   then rawset(Drive, "FSusDamping",   def.FSusDamping   * math.sqrt(mult)) end
	if def.RSusDamping   then rawset(Drive, "RSusDamping",   def.RSusDamping   * math.sqrt(mult)) end
	if def.SteerDecay    then rawset(Drive, "SteerDecay",    def.SteerDecay    * mult) end
	if def.SteerSpeed    then rawset(Drive, "SteerSpeed",    0.05) end
	if def.BrakeForce    then rawset(Drive, "BrakeForce",    def.BrakeForce    * math.sqrt(mult)) end
	if def.PBrakeForce   then rawset(Drive, "PBrakeForce",   def.PBrakeForce   * math.sqrt(mult)) end
	if def.EBrakeForce   then rawset(Drive, "EBrakeForce",   def.EBrakeForce   * math.sqrt(mult)) end
	if def.TCSThreshold  then rawset(Drive, "TCSThreshold",  def.TCSThreshold  * mult) end
	if def.ABSThreshold  then rawset(Drive, "ABSThreshold",  def.ABSThreshold  * mult) end
	if def.ShiftUpTime   then rawset(Drive, "ShiftUpTime",   math.max(def.ShiftUpTime / mult, 0.1)) end
	if def.ShiftDnTime   then rawset(Drive, "ShiftDnTime",   math.max(def.ShiftDnTime / mult, 0.1)) end

	return true
end

-- ─────────────────────────────────────────────
-- Persistent streaming for owned car
-- ─────────────────────────────────────────────

Vehicles.ChildAdded:Connect(function(v)
	if v:IsA("Model") then
		while not v:GetAttribute("Owner") do task.wait() end
		if v:GetAttribute("Owner") == LocalPlayer.Name then
			v.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		end
	end
end)

-- ─────────────────────────────────────────────
-- UI Tab
-- ─────────────────────────────────────────────

local VModTab = Window:Tab({ Title = "Vehicle Mods+", Icon = "car" })

-- ══════════════════════════════════════════════
-- QUICK PRESETS
-- ══════════════════════════════════════════════

VModTab:Section({ Title = "Quick Presets" })

VModTab:Paragraph({
	Title = "What does this do?",
	Desc  = "Scales the vehicle's drive physics by a multiplier.\n" ..
	        "Electric cars will have their torque scaled instead of horsepower.\n" ..
	        "'Reset' restores all original values.",
})

local function RunPreset(mult)
	local vehicle = GetVehicle()
	if not vehicle or not vehicle:FindFirstChild("Drive Controller") then
		NotifyError("Preset", "No vehicle found! Spawn or enter your car first.")
		return
	end
	local _, Drive = GetDrive(vehicle)
	local ok, err = ApplyPreset(vehicle, mult)
	if ok then
		TryRestartVehicleUI()
		WindUI:Notify({
			Title   = "Vehicle Mods+ – ×" .. tostring(mult) .. " applied",
			Content = vehicle.Name .. (Drive and IsElectric(Drive) and "  [Electric]" or ""),
			Duration = 4,
		})
	else
		NotifyError("Preset", err)
	end
end

VModTab:Button({
	Title = "Preset ×1.2  (Mild Boost)",
	Callback = function() RunPreset(1.2) end,
})

VModTab:Button({
	Title = "Preset ×2  (Large Boost)",
	Callback = function() RunPreset(2) end,
})

VModTab:Button({
	Title = "Reset to Defaults",
	Desc  = "Restores all original drive values.",
	Callback = function()
		local vehicle = GetVehicle()
		if not vehicle then NotifyError("Reset", "No vehicle found.") return end
		local ok, err = ResetVehicle(vehicle)
		if ok then
			TryRestartVehicleUI()
			WindUI:Notify({ Title = "Vehicle Mods+ - Reset", Content = "Restored defaults for: " .. vehicle.Name, Duration = 4 })
		else
			NotifyError("Reset", err)
		end
	end,
})

-- ══════════════════════════════════════════════
-- DRIVETRAIN
-- ══════════════════════════════════════════════

VModTab:Section({ Title = "Drivetrain" })

local selectedDrivetrain = "RWD"

VModTab:Dropdown({
	Title    = "Drivetrain",
	Desc     = "Changes which wheels receive engine power.",
	Values   = { "FWD", "RWD", "AWD" },
	Multi    = false,
	Value    = "RWD",
	Callback = function(value) selectedDrivetrain = value end,
})

VModTab:Button({
	Title = "Apply Drivetrain",
	Callback = function()
		local vehicle = GetVehicle()
		if not vehicle then NotifyError("Drivetrain", "No vehicle found!") return end
		local ok, Drive = GetDrive(vehicle)
		if not ok then NotifyError("Drivetrain", "Could not read Drive Controller.") return end
		if not VehicleDefaults[vehicle] then StoreDefaults(vehicle) end

		local old = rawget(Drive, "Config")
		rawset(Drive, "Config", selectedDrivetrain)
		TryRestartVehicleUI()
		NotifyChange("Drivetrain", "Config", old, selectedDrivetrain)
	end,
})

-- ══════════════════════════════════════════════
-- FINAL DRIVE
-- ══════════════════════════════════════════════

VModTab:Section({ Title = "Final Drive" })

VModTab:Paragraph({
	Title = "Final Drive",
	Desc  = "Lower = higher top speed, less acceleration.\nHigher = more acceleration, lower top speed.",
})

local finalDriveValue = 4

VModTab:Slider({
	Title = "Final Drive",
	Desc  = "Ratio (0.50 – 8.00)",
	Value = { Min = 0.50, Max = 8.00, Default = 4 },
	Step  = 0.25,
	Callback = function(v) finalDriveValue = tonumber(v) or 4 end,
})

VModTab:Button({
	Title = "Apply Final Drive",
	Callback = function()
		local vehicle = GetVehicle()
		if not vehicle then NotifyError("Final Drive", "No vehicle found!") return end
		local ok, Drive = GetDrive(vehicle)
		if not ok then NotifyError("Final Drive", "Could not read Drive Controller.") return end
		if not VehicleDefaults[vehicle] then StoreDefaults(vehicle) end

		local old = rawget(Drive, "FinalDrive")
		rawset(Drive, "FinalDrive", finalDriveValue)
		TryRestartVehicleUI()
		NotifyChange("Final Drive", "FinalDrive", old, finalDriveValue)
	end,
})

-- ══════════════════════════════════════════════
-- POWER (HP / ELECTRIC TORQUE)
-- ══════════════════════════════════════════════

VModTab:Section({ Title = "Power" })

VModTab:Paragraph({
	Title = "Power",
	Desc  = "Sets Horsepower for ICE vehicles.\n" ..
	        "Sets E_Torque for electric vehicles.",
})

local horsepowerValue = 300

VModTab:Slider({
	Title = "Power Value",
	Desc  = "HP for ICE  /  Torque (Nm) for Electric (50 – 5000)",
	Value = { Min = 50, Max = 5000, Default = 300 },
	Step  = 25,
	Callback = function(v) horsepowerValue = tonumber(v) or 300 end,
})

VModTab:Button({
	Title = "Apply Power",
	Callback = function()
		local vehicle = GetVehicle()
		if not vehicle then NotifyError("Power", "No vehicle found!") return end
		local ok, Drive = GetDrive(vehicle)
		if not ok then NotifyError("Power", "Could not read Drive Controller.") return end
		if not VehicleDefaults[vehicle] then StoreDefaults(vehicle) end

		TryRestartVehicleUI()

		if IsElectric(Drive) then
			local oldT = rawget(Drive, "E_Torque")
			rawset(Drive, "E_Torque",     horsepowerValue)
			WindUI:Notify({
				Title   = "VMods – Power (Electric)",
				Content = "E_Torque: "     .. Fmt(oldT) .. " → " .. Fmt(horsepowerValue),
				Duration = 5,
			})
		else
			local old = rawget(Drive, "Horsepower")
			rawset(Drive, "Horsepower", horsepowerValue)
			NotifyChange("Power (ICE)", "Horsepower", old, horsepowerValue)
		end
	end,
})

-- ══════════════════════════════════════════════
-- STEERING
-- ══════════════════════════════════════════════

VModTab:Section({ Title = "Steering" })

VModTab:Paragraph({
	Title = "Tighter Steering",
	Desc  = "Reduces SteerRatio and LockToLock for more direct, responsive steering.\n" ..
	        "Also widens SteerInner/SteerOuter for a tighter turning radius.\n" ..
	        "Use Reset to Defaults to undo.",
})

VModTab:Button({
	Title = "Tighter Steering",
	Desc  = "Changes SteerRatio and Ackerman for sharper turning.",
	Callback = function()
		local vehicle = GetVehicle()
		if not vehicle then NotifyError("Steering", "No vehicle found!") return end
		local ok, Drive = GetDrive(vehicle)
		if not ok then NotifyError("Steering", "Could not read Drive Controller.") return end
		if not VehicleDefaults[vehicle] then StoreDefaults(vehicle) end

		local oldRatio = rawget(Drive, "SteerRatio")
      	local oldAcker = rawget(Drive, "Ackerman")
		local oldSpeed = rawget(Drive, "SteerSpeed")

		local newRatio = 12
    	local newAcker = 1.1
		local newSpeed = 0.05

		if newRatio then rawset(Drive, "SteerRatio", newRatio)  end
		if newAcker then rawset(Drive, "Ackerman", newAcker) end
		if newAcker then rawset(Drive, "SteerSpeed", newSpeed) end
			
		TryRestartVehicleUI()

		WindUI:Notify({
			Title   = "VMods – Tighter Steering",
			Content = "SteerRatio: "  .. Fmt(oldRatio) .. " → " .. Fmt(newRatio)  ..
			          "\nAckerman: " .. Fmt(oldAcker) .. " → " .. Fmt(newAcker)  ..
			          "\nSteerSpeed: " .. Fmt(oldSpeed) .. " → " .. Fmt(newSpeed),
			Duration = 5,
		})
	end,
})

-- ══════════════════════════════════════════════
-- SPEED BOOST
-- ══════════════════════════════════════════════

VModTab:Section({ Title = "Speed Boost" })

VModTab:Paragraph({
	Title = "Speed Boost",
	Desc  = "Instantly pushes your vehicle. Works best at speed. 0.25s cooldown.",
})

local boostStrength   = 150
local boostKeybind    = Enum.KeyCode.U
local boostOnCooldown = false

VModTab:Slider({
	Title = "Boost Strength",
	Desc  = "Velocity added per boost. Over 400 is dangerous. (50 – 1000)",
	Value = { Min = 50, Max = 1000, Default = 150 },
	Step  = 25,
	Callback = function(v) boostStrength = tonumber(v) or 150 end,
})

local function FireBoost()
	if boostOnCooldown then return end
	local vehicle = GetDrivenVehicle()
	if not vehicle then
		WindUI:Notify({ Title = "VMods – Boost", Content = "You must be driving a vehicle.", Duration = 3 })
		return
	end
	local primary = vehicle.PrimaryPart
	if not primary then return end

	boostOnCooldown = true
	primary.AssemblyLinearVelocity = primary.AssemblyLinearVelocity + primary.CFrame.LookVector * boostStrength
	task.delay(0.2, function() boostOnCooldown = false end)
end

VModTab:Button({
	Title = "Boost!",
	Desc  = "Instantly pushes the vehicle forward.",
	Callback = FireBoost,
})

VModTab:Keybind({
	Title = "Boost Keybind",
	Desc  = "Press while driving to fire a boost.",
	Value = "U",
	Callback = function(v)
		boostKeybind = Enum.KeyCode[v] or Enum.KeyCode.U
	end,
})

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == boostKeybind then FireBoost() end
end)

-- ══════════════════════════════════════════════
-- CUSTOM VALUE EDITOR
-- ══════════════════════════════════════════════

VModTab:Section({ Title = "Custom Value Editor" })

VModTab:Paragraph({
	Title = "Custom Value Editor",
	Desc  = "Select any drive value, read it or apply a new value."
})

local selectedKey    = ALL_VALUE_KEYS[1]
local customRawInput = ""

VModTab:Dropdown({
	Title    = "Value to Edit",
	Values   = ALL_VALUE_KEYS,
	Multi    = false,
	Value    = ALL_VALUE_KEYS[1],
	Callback = function(v) selectedKey = v end,
})

VModTab:Button({
	Title = "Read Current Value",
	Desc  = "Shows the selected key's live value in a notification.",
	Callback = function()
		local vehicle = GetVehicle()
		if not vehicle then NotifyError("Read Value", "No vehicle found!") return end
		local ok, Drive = GetDrive(vehicle)
		if not ok then NotifyError("Read Value", "Could not read Drive Controller.") return end

		local current = rawget(Drive, selectedKey)
		WindUI:Notify({
			Title   = "VMods – " .. selectedKey,
			Content = "Current value:  " .. Fmt(current),
			Duration = 6,
		})
	end,
})

VModTab:Input({
	Title       = "New Value",
	Desc        = "Type the new numeric value to apply.",
	Value       = "",
	Placeholder = "e.g. 500",
	Numeric     = true,
	Finished    = false,
	Callback    = function(v) customRawInput = v end,
})

VModTab:Button({
	Title = "Apply Value",
	Desc  = "Sets the selected key to the value you typed.",
	Callback = function()
		local newVal = tonumber(customRawInput)
		if not newVal then
			NotifyError("Custom Value", "Invalid number: \"" .. tostring(customRawInput) .. "\"")
			return
		end

		local vehicle = GetVehicle()
		if not vehicle then NotifyError("Custom Value", "No vehicle found!") return end
		local ok, Drive = GetDrive(vehicle)
		if not ok then NotifyError("Custom Value", "Could not read Drive Controller.") return end
		if not VehicleDefaults[vehicle] then StoreDefaults(vehicle) end

		local old = rawget(Drive, selectedKey)
		rawset(Drive, selectedKey, newVal)
		TryRestartVehicleUI()
		NotifyChange("Custom Value", selectedKey, old, newVal)
	end,
})

-- ══════════════════════════════════════════════
-- CUSTOM MULTIPLIER
-- ══════════════════════════════════════════════

VModTab:Section({ Title = "Custom Multiplier" })

local customMult = 1.5

VModTab:Slider({
	Title = "Multiplier",
	Desc  = "Custom multiplier to apply to all preset values.",
	Value = { Min = 1, Max = 10, Default = 1.5 },
	Step  = 0.25,
	Callback = function(v) customMult = tonumber(v) or 1.5 end,
})

VModTab:Button({
	Title = "Apply Custom Multiplier",
	Callback = function() RunPreset(customMult) end,
})

-- ══════════════════════════════════════════════
-- CREDITS
-- ══════════════════════════════════════════════

VModTab:Section({ Title = "Credits" })
VModTab:Paragraph({
	Title = "Credits",
	Desc  = "Made with Claude. Made and edited by woah679",
})

WindUI:Notify({
	Title   = "Vehicle Mods+ loaded",
	Content = "Vehicle Mods+ is ready.",
	Duration = 3,
})
