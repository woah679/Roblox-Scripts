repeat task.wait() until _G.WindUI and _G.Window and _G.Functions

local WindUI  = _G.WindUI
local Window  = _G.Window
local Tabs    = _G.Tabs

local Players          = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService      = cloneref(game:GetService("HttpService"))
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
-- File system helpers
-- ─────────────────────────────────────────────

local ROOT_FOLDER   = "ERX"
local CONFIG_FOLDER = ROOT_FOLDER .. "/config/VehicleModsPlus"

local function EnsureFolder(path)
	if not isfolder(path) then
		makefolder(path)
	end
end

local function VehicleFolder(vehicleName)
	-- Sanitise vehicle name for use as a folder name
	local safe = vehicleName:gsub("[^%w%s%-_]", ""):gsub("%s+", "_")
	return CONFIG_FOLDER .. "/" .. safe, safe
end

local function ConfigPath(vehicleName, configName)
	local folder = VehicleFolder(vehicleName)
	local safeName = configName:gsub("[^%w%s%-_]", ""):gsub("%s+", "_")
	return folder .. "/" .. safeName .. ".json"
end

local function AutoloadPath(vehicleName)
	local folder = VehicleFolder(vehicleName)
	return folder .. "/__autoload.txt"
end

-- Returns list of config names (without .json) for a given vehicle
local function ListConfigs(vehicleName)
	local folder = VehicleFolder(vehicleName)
	if not isfolder(folder) then return {} end

	local configs = {}
	-- ERX exposes listfiles() as part of the exploit environment
	local ok, files = pcall(listfiles, folder)
	if not ok then return {} end

	for _, path in ipairs(files) do
		local name = path:match("([^/\\]+)%.json$")
		if name then
			table.insert(configs, name)
		end
	end
	return configs
end

local function GetAutoload(vehicleName)
	local path = AutoloadPath(vehicleName)
	if isfile(path) then
		local content = readfile(path)
		return content ~= "" and content or nil
	end
	return nil
end

local function SetAutoload(vehicleName, configName)
	EnsureFolder(ROOT_FOLDER)
	EnsureFolder(CONFIG_FOLDER)
	local folder = VehicleFolder(vehicleName)
	EnsureFolder(folder)
	writefile(AutoloadPath(vehicleName), configName or "")
end

-- ─────────────────────────────────────────────
-- Defaults / drive key lists
-- ─────────────────────────────────────────────

local VehicleDefaults = {}

local DEFAULT_KEYS = {
	"Horsepower", "IdleRPM", "PeakRPM", "Redline", "EqPoint", "PeakSharpness", "CurveMult",
	"RevAccel", "RevDecay", "RevBounce", "IdleThrottle", "Flywheel", "InclineComp",
	"ThrotAccel", "ThrotDecel", "BrakeAccel", "BrakeDecel",
	"Electric", "E_Horsepower", "E_Torque", "E_Redline", "E_Trans1", "E_Trans2",
	"EH_FrontMult", "EH_EndMult", "EH_EndPercent", "ET_EndMult", "ET_EndPercent",
	"Turbochargers", "T_Boost", "T_Efficiency", "T_Size",
	"Superchargers", "S_Boost", "S_Efficiency", "S_Sensitivity",
	"FinalDrive", "FDMult", "ShiftUpTime", "ShiftDnTime",
	"AutoUpThresh", "AutoDownThresh", "ShiftThrot",
	"ClutchEngage", "SpeedEngage", "KickMult", "KickSpeedThreshold", "KickRPMThreshold", "ClutchRPMMult",
	"RPMEngage", "NeutralRevRPM",
	"Config", "TorqueVector",
	"FDiffSlipThres", "FDiffLockThres", "RDiffSlipThres", "RDiffLockThres", "CDiffSlipThres", "CDiffLockThres",
	"FDiffPower", "FDiffCoast", "FDiffPreload", "RDiffPower", "RDiffCoast", "RDiffPreload",
	"BrakeForce", "BrakeBias", "PBrakeForce", "PBrakeBias", "EBrakeForce",
	"ABSThreshold", "TCSThreshold", "TCSGradient", "TCSLimit",
	"FSusDamping", "FSusStiffness", "FAntiRoll", "FSusLength",
	"FPreCompress", "FExtensionLim", "FCompressLim", "FSusAngle", "FWsBoneLen", "FWsBoneAngle",
	"RSusDamping", "RSusStiffness", "RAntiRoll", "RSusLength",
	"RPreCompress", "RExtensionLim", "RCompressLim", "RSusAngle", "RWsBoneLen", "RWsBoneAngle",
	"FGyroDamp", "RGyroDamp",
	"SteerRatio", "LockToLock", "Ackerman", "SteerInner", "SteerOuter",
	"SteerSpeed", "ReturnSpeed", "SteerDecay", "MinSteer", "MSteerExp",
	"SteerD", "SteerMaxTorque", "SteerP",
	"RSteerOuter", "RSteerInner", "RSteerSpeed", "RSteerDecay", "RSteerD", "RSteerMaxTorque", "RSteerP",
	"Weight", "WeightDist", "CGHeight", "WeightScaling",
	"FWheelDensity", "RWheelDensity", "AxleSize", "AxleDensity",
	"FCamber", "RCamber", "FCaster", "RCaster", "FToe", "RToe",
	"MaxFuel",
}

local ALL_VALUE_KEYS = {
	"Horsepower", "IdleRPM", "PeakRPM", "Redline", "EqPoint", "PeakSharpness", "CurveMult",
	"RevAccel", "RevDecay", "RevBounce", "IdleThrottle", "Flywheel", "InclineComp",
	"ThrotAccel", "ThrotDecel", "BrakeAccel", "BrakeDecel",
	"E_Horsepower", "E_Torque", "E_Redline", "E_Trans1", "E_Trans2",
	"EH_FrontMult", "EH_EndMult", "EH_EndPercent", "ET_EndMult", "ET_EndPercent",
	"T_Boost", "T_Efficiency", "T_Size",
	"S_Boost", "S_Efficiency", "S_Sensitivity",
	"FinalDrive", "FDMult", "ShiftUpTime", "ShiftDnTime",
	"AutoUpThresh", "AutoDownThresh", "ShiftThrot",
	"ClutchEngage", "SpeedEngage", "KickMult", "KickSpeedThreshold", "KickRPMThreshold", "ClutchRPMMult",
	"RPMEngage", "NeutralRevRPM",
	"TorqueVector",
	"FDiffSlipThres", "FDiffLockThres", "RDiffSlipThres", "RDiffLockThres", "CDiffSlipThres", "CDiffLockThres",
	"FDiffPower", "FDiffCoast", "FDiffPreload", "RDiffPower", "RDiffCoast", "RDiffPreload",
	"BrakeForce", "BrakeBias", "PBrakeForce", "PBrakeBias", "EBrakeForce",
	"ABSThreshold", "TCSThreshold", "TCSGradient", "TCSLimit",
	"FSusDamping", "FSusStiffness", "FAntiRoll", "FSusLength",
	"FPreCompress", "FExtensionLim", "FCompressLim", "FSusAngle", "FWsBoneLen", "FWsBoneAngle",
	"RSusDamping", "RSusStiffness", "RAntiRoll", "RSusLength",
	"RPreCompress", "RExtensionLim", "RCompressLim", "RSusAngle", "RWsBoneLen", "RWsBoneAngle",
	"FGyroDamp", "RGyroDamp",
	"SteerRatio", "LockToLock", "Ackerman", "SteerInner", "SteerOuter",
	"SteerSpeed", "ReturnSpeed", "SteerDecay", "MinSteer", "MSteerExp",
	"SteerD", "SteerMaxTorque", "SteerP",
	"RSteerOuter", "RSteerInner", "RSteerSpeed", "RSteerDecay", "RSteerD", "RSteerMaxTorque", "RSteerP",
	"Weight", "WeightDist", "CGHeight", "WeightScaling",
	"FWheelDensity", "RWheelDensity", "AxleSize", "AxleDensity",
	"FCamber", "RCamber", "FCaster", "RCaster", "FToe", "RToe",
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
-- Config save / load
-- ─────────────────────────────────────────────

-- Snapshot every key from the Drive Controller into a table
local function SnapshotDrive(Drive)
	local snap = {}
	for _, key in ipairs(DEFAULT_KEYS) do
		local v = rawget(Drive, key)
		-- Only serialise primitives (number, string, boolean)
		local t = type(v)
		if t == "number" or t == "string" or t == "boolean" then
			snap[key] = v
		end
	end
	return snap
end

-- Write snapshot to ERX_ERLC/VehicleModsPlus/<vehicle>/<name>.json
local function SaveConfig(vehicleName, configName, Drive)
	EnsureFolder(ROOT_FOLDER)
	EnsureFolder(CONFIG_FOLDER)
	local folder = VehicleFolder(vehicleName)
	EnsureFolder(folder)

	local snap = SnapshotDrive(Drive)
	local path = ConfigPath(vehicleName, configName)
	local ok, err = pcall(writefile, path, HttpService:JSONEncode(snap))
	return ok, err
end

-- Read a config and rawset all values back onto the Drive
local function LoadConfig(vehicleName, configName, Drive)
	local path = ConfigPath(vehicleName, configName)
	if not isfile(path) then
		return false, "Config file not found: " .. path
	end

	local raw = readfile(path)
	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or type(data) ~= "table" then
		return false, "Failed to parse config JSON"
	end

	for key, value in pairs(data) do
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

	if IsElectric(Drive) then
		if def.E_Torque  then rawset(Drive, "E_Torque",  def.E_Torque  * mult) end
		if def.E_Horsepower then rawset(Drive, "E_Horsepower", def.E_Horsepower * mult) end
	else
		if def.Horsepower then
			local hp = def.Horsepower * mult
			if hp < 2000 and mult > 1.2 then hp = hp * 1.3 end
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
-- Ensure base folders exist on load
-- ─────────────────────────────────────────────
EnsureFolder(ROOT_FOLDER)
EnsureFolder(CONFIG_FOLDER)

-- ─────────────────────────────────────────────
-- UI
-- ─────────────────────────────────────────────

local VModTab = Window:Tab({ Title = "Vehicle Mods+", Icon = "car" })

-- ══════════════════════════════════════════════
-- RESET
-- ══════════════════════════════════════════════

VModTab:Section({ Title = "General" })

VModTab:Button({
	Title = "Reset to Default",
	Desc  = "Restores all original drive values for your current vehicle.",
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
-- QUICK PRESETS
-- ══════════════════════════════════════════════

VModTab:Section({ Title = "Quick Presets" })

VModTab:Paragraph({
	Title = "Quick Presets",
	Desc  = "Scales the vehicle's drive physics by a multiplier.\n" ..
	        "Electric cars have their torque scaled instead of HP.\n" ..
	        "'Reset to Default' restores all original values.",
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
	Title    = "Preset ×1.2  (Mild Boost)",
	Callback = function() RunPreset(1.2) end,
})

VModTab:Button({
	Title    = "Preset ×2  (Large Boost)",
	Callback = function() RunPreset(2) end,
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
	Desc  = "Lower = higher top speed, less acceleration.\nHigher = more acceleration, lower top speed.\nMost vehicles around 4, EVs are higher.",
})

local finalDriveValue = 4

VModTab:Slider({
	Title    = "Final Drive",
	Desc     = "Ratio (0.50 – 15.00)",
	Value    = { Min = 0.50, Max = 15.00, Default = 4 },
	Step     = 0.25,
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
-- POWER
-- ══════════════════════════════════════════════

VModTab:Section({ Title = "Power" })

VModTab:Paragraph({
	Title = "Power",
	Desc  = "Sets Horsepower for ICE vehicles.\n" ..
	        "Sets E_Torque for electric vehicles.\n" ..
	        "Detected automatically.",
})

local horsepowerValue = 300

VModTab:Slider({
	Title    = "Power Value",
	Desc     = "HP for ICE  /  Torque for Electric (50 – 5000)",
	Value    = { Min = 50, Max = 5000, Default = 300 },
	Step     = 25,
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
			rawset(Drive, "E_Torque", horsepowerValue)
			WindUI:Notify({
				Title   = "Vehicle Mods+ – Power (Electric)",
				Content = "E_Torque: " .. Fmt(oldT) .. " → " .. Fmt(horsepowerValue),
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
	Title = "Sharper Steering",
	Desc  = "Reduces SteerRatio and increases SteerSpeed & Ackerman.\n" ..
	        "Use 'Reset to Default' to undo.",
})

VModTab:Button({
	Title = "Apply Sharper Steering",
	Callback = function()
		local vehicle = GetVehicle()
		if not vehicle then NotifyError("Steering", "No vehicle found!") return end
		local ok, Drive = GetDrive(vehicle)
		if not ok then NotifyError("Steering", "Could not read Drive Controller.") return end
		if not VehicleDefaults[vehicle] then StoreDefaults(vehicle) end

		local oldRatio = rawget(Drive, "SteerRatio")
		local oldAcker = rawget(Drive, "Ackerman")
		local oldSpeed = rawget(Drive, "SteerSpeed")

		local newRatio, newAcker, newSpeed = 13, 1.1, 0.05

		rawset(Drive, "SteerRatio",  newRatio)
		rawset(Drive, "Ackerman",    newAcker)
		rawset(Drive, "SteerSpeed",  newSpeed)

		TryRestartVehicleUI()

		WindUI:Notify({
			Title   = "Vehicle Mods+ – Sharper Steering",
			Content = "SteerRatio: "  .. Fmt(oldRatio) .. " → " .. Fmt(newRatio)  ..
			          "\nAckerman: "  .. Fmt(oldAcker)  .. " → " .. Fmt(newAcker)  ..
			          "\nSteerSpeed: " .. Fmt(oldSpeed)  .. " → " .. Fmt(newSpeed),
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
	Title    = "Boost Strength",
	Desc     = "Velocity added per boost. Over 400 is dangerous. (50 – 1000)",
	Value    = { Min = 50, Max = 1000, Default = 150 },
	Step     = 25,
	Callback = function(v) boostStrength = tonumber(v) or 150 end,
})

local function FireBoost()
	if boostOnCooldown then return end
	local vehicle = GetDrivenVehicle()
	if not vehicle then
		WindUI:Notify({ Title = "Vehicle Mods+ – Boost", Content = "You must be driving a vehicle.", Duration = 3 })
		return
	end
	local primary = vehicle.PrimaryPart
	if not primary then return end

	boostOnCooldown = true
	primary.AssemblyLinearVelocity = primary.AssemblyLinearVelocity + primary.CFrame.LookVector * boostStrength
	task.delay(0.2, function() boostOnCooldown = false end)
end

VModTab:Button({
	Title    = "Boost!",
	Desc     = "Instantly pushes your vehicle forward.",
	Callback = FireBoost,
})

VModTab:Keybind({
	Title    = "Boost Keybind",
	Desc     = "Press while driving to fire a boost.",
	Value    = "U",
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
	Desc  = "Select any drive value, read it or set it to a new number.",
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
	Desc  = "Shows the live value of the selected key.",
	Callback = function()
		local vehicle = GetVehicle()
		if not vehicle then NotifyError("Read Value", "No vehicle found!") return end
		local ok, Drive = GetDrive(vehicle)
		if not ok then NotifyError("Read Value", "Could not read Drive Controller.") return end

		local current = rawget(Drive, selectedKey)
		WindUI:Notify({
			Title   = "VehicleMods+ – " .. selectedKey,
			Content = "Current value: " .. Fmt(current),
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
	Desc  = "Sets the selected key to the typed value.",
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
	Title    = "Multiplier",
	Desc     = "Custom multiplier to apply to all preset values.",
	Value    = { Min = 1, Max = 10, Default = 1.5 },
	Step     = 0.25,
	Callback = function(v) customMult = tonumber(v) or 1.5 end,
})

VModTab:Button({
	Title    = "Apply Custom Multiplier",
	Callback = function() RunPreset(customMult) end,
})

-- ══════════════════════════════════════════════
-- CONFIG SYSTEM
-- ══════════════════════════════════════════════

VModTab:Section({ Title = "Config System" })

VModTab:Paragraph({
	Title = "Config System",
	Desc  = "Save and load drive configurations per vehicle.\n" ..
	        "Configs are stored at:\n" ..
	        "ERX_ERLC/VehicleModsPlus/<VehicleName>/<ConfigName>.json\n\n" ..
	        "You can set one config to auto-load whenever you spawn that vehicle.",
})

-- Tracks the currently selected config name in the load dropdown
local selectedLoadConfig = nil

-- Holds a reference to the load dropdown so we can refresh it
local ConfigLoadDropdown = nil

-- Refresh the load dropdown for the current vehicle
local function RefreshConfigDropdown()
	if not ConfigLoadDropdown then return end
	local vehicle = GetVehicle()
	if not vehicle then return end

	local configs = ListConfigs(vehicle.Name)
	if #configs == 0 then
		configs = { "(none)" }
	end

	ConfigLoadDropdown:Refresh(configs, true)
	selectedLoadConfig = configs[1] ~= "(none)" and configs[1] or nil
end

-- ── Save config ───────────────────────────────

local saveConfigNameInput = ""

VModTab:Input({
	Title       = "Config Name",
	Desc        = "Name for this config (letters, numbers, dashes, spaces).",
	Value       = "",
	Placeholder = "e.g. MaxSpeed",
	Numeric     = false,
	Finished    = false,
	Callback    = function(v) saveConfigNameInput = v end,
})

VModTab:Button({
	Title = "Save Config",
	Desc  = "Saves the vehicle's current drive values under the typed name.",
	Callback = function()
		local vehicle = GetVehicle()
		if not vehicle then NotifyError("Save Config", "No vehicle found!") return end

		local name = saveConfigNameInput:match("^%s*(.-)%s*$") -- trim
		if name == "" then
			NotifyError("Save Config", "Please type a config name first.")
			return
		end

		local ok, Drive = GetDrive(vehicle)
		if not ok then NotifyError("Save Config", "Could not read Drive Controller.") return end

		local saved, err = SaveConfig(vehicle.Name, name, Drive)
		if saved then
			WindUI:Notify({
				Title   = "Vehicle Mods+ – Config Saved",
				Content = "[" .. vehicle.Name .. "] \"" .. name .. "\" saved.",
				Duration = 5,
			})
			RefreshConfigDropdown()
		else
			NotifyError("Save Config", tostring(err))
		end
	end,
})

-- ── Load config ───────────────────────────────

VModTab:Paragraph({
	Title = "Load Config",
	Desc  = "Select a saved config from the dropdown, then press Load.\n" ..
	        "Press Refresh if the list looks outdated.",
})

ConfigLoadDropdown = VModTab:Dropdown({
	Title    = "Saved Configs",
	Values   = { "(none)" },
	Multi    = false,
	Value    = "(none)",
	Callback = function(v)
		selectedLoadConfig = (v ~= "(none)") and v or nil
	end,
})

VModTab:Button({
	Title = "Refresh Config List",
	Desc  = "Reloads the config list for your current vehicle.",
	Callback = function()
		RefreshConfigDropdown()
		WindUI:Notify({
			Title   = "Vehicle Mods+ – Config List",
			Content = "Config list refreshed.",
			Duration = 3,
		})
	end,
})

VModTab:Button({
	Title = "Load Config",
	Desc  = "Applies the selected config to your vehicle.",
	Callback = function()
		if not selectedLoadConfig then
			NotifyError("Load Config", "No config selected. Refresh the list or save one first.")
			return
		end

		local vehicle = GetVehicle()
		if not vehicle then NotifyError("Load Config", "No vehicle found!") return end

		local ok, Drive = GetDrive(vehicle)
		if not ok then NotifyError("Load Config", "Could not read Drive Controller.") return end

		-- Store defaults before first load so Reset still works
		if not VehicleDefaults[vehicle] then StoreDefaults(vehicle) end

		local loaded, err = LoadConfig(vehicle.Name, selectedLoadConfig, Drive)
		if loaded then
			TryRestartVehicleUI()
			WindUI:Notify({
				Title   = "Vehicle Mods+ – Config Loaded",
				Content = "[" .. vehicle.Name .. "] \"" .. selectedLoadConfig .. "\" applied.",
				Duration = 5,
			})
		else
			NotifyError("Load Config", tostring(err))
		end
	end,
})

-- ── Delete config ─────────────────────────────

VModTab:Button({
	Title = "Delete Selected Config",
	Desc  = "Permanently deletes the selected config file.",
	Callback = function()
		if not selectedLoadConfig then
			NotifyError("Delete Config", "No config selected.")
			return
		end

		local vehicle = GetVehicle()
		if not vehicle then NotifyError("Delete Config", "No vehicle found!") return end

		local path = ConfigPath(vehicle.Name, selectedLoadConfig)
		if isfile(path) then
			local ok, err = pcall(delfile, path)
			if ok then
				WindUI:Notify({
					Title   = "Vehicle Mods+ – Config Deleted",
					Content = "\"" .. selectedLoadConfig .. "\" deleted.",
					Duration = 4,
				})
				selectedLoadConfig = nil
				RefreshConfigDropdown()
			else
				NotifyError("Delete Config", tostring(err))
			end
		else
			NotifyError("Delete Config", "File not found.")
		end
	end,
})

-- ── Auto-load setting ─────────────────────────

VModTab:Section({ Title = "Auto-Load" })

VModTab:Paragraph({
	Title = "Auto-Load",
	Desc  = "Set one config per vehicle to load automatically\nwhenever you spawn that vehicle (character added).\n" ..
	        "First select a config in the dropdown above, then press Set.",
})

VModTab:Button({
	Title = "Set Auto-Load Config",
	Desc  = "Marks the selected config as the auto-load for this vehicle.",
	Callback = function()
		if not selectedLoadConfig then
			NotifyError("Auto-Load", "No config selected. Pick one from the dropdown first.")
			return
		end

		local vehicle = GetVehicle()
		if not vehicle then NotifyError("Auto-Load", "No vehicle found!") return end

		SetAutoload(vehicle.Name, selectedLoadConfig)
		WindUI:Notify({
			Title   = "Vehicle Mods+ – Auto-Load Set",
			Content = "[" .. vehicle.Name .. "] will auto-load \"" .. selectedLoadConfig .. "\" on spawn.",
			Duration = 5,
		})
	end,
})

VModTab:Button({
	Title = "Clear Auto-Load",
	Desc  = "Removes the auto-load setting for the current vehicle.",
	Callback = function()
		local vehicle = GetVehicle()
		if not vehicle then NotifyError("Auto-Load", "No vehicle found!") return end

		SetAutoload(vehicle.Name, "")
		WindUI:Notify({
			Title   = "Vehicle Mods+ – Auto-Load Cleared",
			Content = "[" .. vehicle.Name .. "] will no longer auto-load a config.",
			Duration = 4,
		})
	end,
})

VModTab:Button({
	Title = "Show Auto-Load Setting",
	Desc  = "Shows which config, if any, auto-loads for the current vehicle.",
	Callback = function()
		local vehicle = GetVehicle()
		if not vehicle then NotifyError("Auto-Load", "No vehicle found!") return end

		local current = GetAutoload(vehicle.Name)
		WindUI:Notify({
			Title   = "Vehicle Mods+ – Auto-Load",
			Content = "[" .. vehicle.Name .. "] auto-load: " .. (current or "(none)"),
			Duration = 5,
		})
	end,
})

-- ─────────────────────────────────────────────
-- Auto-load runner — fires on character added
-- Waits for the player to enter their owned vehicle,
-- then applies the autoload config for that vehicle.
-- ─────────────────────────────────────────────

local function TryAutoLoad(vehicleName)
	local autoConfig = GetAutoload(vehicleName)
	if not autoConfig or autoConfig == "" then return end

	-- Give the vehicle a moment to fully stream in
	task.delay(2, function()
		local vehicle = GetLocalPlayerCar()
		if not vehicle or vehicle.Name ~= vehicleName then return end

		local ok, Drive = GetDrive(vehicle)
		if not ok then return end

		if not VehicleDefaults[vehicle] then StoreDefaults(vehicle) end

		local loaded, err = LoadConfig(vehicleName, autoConfig, Drive)
		if loaded then
			TryRestartVehicleUI()
			WindUI:Notify({
				Title   = "Vehicle Mods+ – Auto-Load",
				Content = "[" .. vehicleName .. "] auto-loaded \"" .. autoConfig .. "\"",
				Duration = 5,
			})
		end
	end)
end

-- When a vehicle spawns for the local player, check for an auto-load config
Vehicles.ChildAdded:Connect(function(v)
	if v:IsA("Model") then
		task.spawn(function()
			while not v:GetAttribute("Owner") do task.wait() end
			if v:GetAttribute("Owner") == LocalPlayer.Name then
				TryAutoLoad(v.Name)
			end
		end)
	end
end)

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

-- Populate the dropdown for whatever vehicle is currently spawned
task.delay(1, RefreshConfigDropdown)
