repeat task.wait() until _G.WindUI and _G.Window and _G.Functions

local WindUI = _G.WindUI
local Window = _G.Window
local Tabs   = _G.Tabs

local Players         = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService      = cloneref(game:GetService("RunService"))
local LocalPlayer     = Players.LocalPlayer
local WorkSpace       = cloneref(game:GetService("Workspace"))
local Vehicles        = WorkSpace:WaitForChild("Vehicles", 9e9)

-- ─────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────

local function GetDrivenVehicle()
	local char = LocalPlayer.Character
	local hum  = char and char:FindFirstChildWhichIsA("Humanoid")
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

-- Keep one set of defaults per vehicle instance
local VehicleDefaults = {}

local DEFAULT_KEYS = {
	"Horsepower", "FinalDrive", "RevAccel", "FAntiRoll", "SteerDecay",
	"BrakeForce", "PBrakeForce", "EBrakeForce",
	"FSusStiffness", "RSusStiffness",
	"FSusDamping",  "RSusDamping",
	"FAntiRoll",    "RAntiRoll",
	"TCSThreshold", "ABSThreshold",
	"SteerRatio",   "LockToLock",
	"Config",
	"ShiftUpTime",  "ShiftDnTime",
}

local function StoreDefaults(vehicle)
	if VehicleDefaults[vehicle] then return end
	local ok, Drive = pcall(require, vehicle:FindFirstChild("Drive Controller"))
	if not ok or not Drive then return end

	VehicleDefaults[vehicle] = {}
	for _, key in ipairs(DEFAULT_KEYS) do
		VehicleDefaults[vehicle][key] = rawget(Drive, key)
	end
end

local function ApplyPreset(vehicle, mult)
	local ok, Drive = pcall(require, vehicle:FindFirstChild("Drive Controller"))
	if not ok or not Drive then return false, "Drive Controller not found" end

	StoreDefaults(vehicle)
	local def = VehicleDefaults[vehicle]
	if not def then return false, "Failed to read defaults" end

	if def.Horsepower then
		local hp = def.Horsepower * mult
		if hp < 2000 and mult > 1.2 then hp = def.Horsepower * mult * 1.3 end
		rawset(Drive, "Horsepower", hp)
	end

	if def.FinalDrive then
		rawset(Drive, "FinalDrive", def.FinalDrive / math.sqrt(mult))
	end

	if def.RevAccel    then rawset(Drive, "RevAccel",    def.RevAccel    * mult) end
	if def.FAntiRoll   then rawset(Drive, "FAntiRoll",   def.FAntiRoll   * mult) end
	if def.RAntiRoll   then rawset(Drive, "RAntiRoll",   def.RAntiRoll   * mult) end

	if def.FSusStiffness then rawset(Drive, "FSusStiffness", def.FSusStiffness * mult) end
	if def.RSusStiffness then rawset(Drive, "RSusStiffness", def.RSusStiffness * mult) end

	if def.FSusDamping then rawset(Drive, "FSusDamping", def.FSusDamping * math.sqrt(mult)) end
	if def.RSusDamping then rawset(Drive, "RSusDamping", def.RSusDamping * math.sqrt(mult)) end

	if def.SteerDecay  then rawset(Drive, "SteerDecay",  def.SteerDecay  * mult) end

	if def.BrakeForce  then rawset(Drive, "BrakeForce",  def.BrakeForce  * math.sqrt(mult)) end
	if def.PBrakeForce then rawset(Drive, "PBrakeForce", def.PBrakeForce * math.sqrt(mult)) end
	if def.EBrakeForce then rawset(Drive, "EBrakeForce", def.EBrakeForce * math.sqrt(mult)) end

	if def.TCSThreshold then rawset(Drive, "TCSThreshold", def.TCSThreshold * mult) end
	if def.ABSThreshold then rawset(Drive, "ABSThreshold", def.ABSThreshold * mult) end

	if def.ShiftUpTime then rawset(Drive, "ShiftUpTime", math.max(def.ShiftUpTime / mult, 0.015)) end
	if def.ShiftDnTime then rawset(Drive, "ShiftDnTime", math.max(def.ShiftDnTime / mult, 0.015)) end

	return true
end

local function ResetVehicle(vehicle)
	local ok, Drive = pcall(require, vehicle:FindFirstChild("Drive Controller"))
	if not ok or not Drive then return false, "Drive Controller not found" end

	local def = VehicleDefaults[vehicle]
	if not def then return false, "No stored defaults for this vehicle" end

	for key, value in pairs(def) do
		rawset(Drive, key, value)
	end
	return true
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
-- WindUI Tab
-- ─────────────────────────────────────────────

local VModTab = Window:Tab({ Title = "VMods", Icon = "car" })

-- ── Quick Presets ──────────────────────────────

VModTab:Section({ Title = "Quick Presets" })

VModTab:Paragraph({
	Title = "What does this do?",
	Desc  = "Modifies the current vehicle's drive physics (horsepower, suspension, braking, steering).\n" ..
	        "Presets: x1.2 for a mild boost, x2 for a large boost.\n" ..
	        "'Reset' restores to default values."
})

local function RunPreset(label, mult)
	local vehicle = GetDrivenVehicle() or GetLocalPlayerCar()

	if not vehicle or not vehicle:FindFirstChild("Drive Controller") then
		WindUI:Notify({
			Title   = "VMods – " .. label,
			Content = "No vehicle found! Spawn or enter your car first.",
			Duration = 5,
		})
		return
	end

	local ok, err = ApplyPreset(vehicle, mult)
	if ok then
		TryRestartVehicleUI()
		WindUI:Notify({
			Title   = "VMods – " .. label .. " applied",
			Content = "Drive values ×" .. tostring(mult) .. " for: " .. vehicle.Name,
			Duration = 4,
		})
	else
		WindUI:Notify({
			Title   = "VMods – Error",
			Content = tostring(err),
			Duration = 6,
		})
	end
end

VModTab:Button({
	Title = "Preset ×1.2  (Mild Boost)",
	Desc  = "Slight increase",
	Callback = function()
		RunPreset("×1.2", 1.2)
	end,
})

VModTab:Button({
	Title = "Preset ×2  (Large Boost)",
	Desc  = "Doubles",
	Callback = function()
		RunPreset("×2", 2)
	end,
})

VModTab:Button({
	Title = "Reset to Defaults",
	Desc  = "Restores the vehicle's original drive values.",
	Callback = function()
		local vehicle = GetDrivenVehicle() or GetLocalPlayerCar()

		if not vehicle then
			WindUI:Notify({
				Title   = "VMods – Reset",
				Content = "No vehicle found.",
				Duration = 4,
			})
			return
		end

		local ok, err = ResetVehicle(vehicle)
		if ok then
			TryRestartVehicleUI()
			WindUI:Notify({
				Title   = "VMods – Reset",
				Content = "Restored defaults for: " .. vehicle.Name,
				Duration = 4,
			})
		else
			WindUI:Notify({
				Title   = "VMods – Reset Error",
				Content = tostring(err),
				Duration = 6,
			})
		end
	end,
})

-- ── Drivetrain Config ─────────────────────────

VModTab:Section({ Title = "Drivetrain" })

VModTab:Paragraph({
	Title = "Drivetrain Config",
	Desc  = "Changes which wheels receive engine power. Takes effect immediately on your current/owned vehicle.",
})

local selectedDrivetrain = "RWD"

VModTab:Dropdown({
	Title  = "Drivetrain",
	Values = { "FWD", "RWD", "AWD" },
	Multi  = false,
	Value  = "RWD",
	Callback = function(value)
		selectedDrivetrain = value
	end,
})

VModTab:Button({
	Title = "Apply Drivetrain",
	Desc  = "Sets the drive Config value on your vehicle.",
	Callback = function()
		local vehicle = GetDrivenVehicle() or GetLocalPlayerCar()

		if not vehicle or not vehicle:FindFirstChild("Drive Controller") then
			WindUI:Notify({
				Title   = "VMods – Drivetrain",
				Content = "No vehicle found! Spawn or enter your car first.",
				Duration = 5,
			})
			return
		end

		local ok, Drive = pcall(require, vehicle:FindFirstChild("Drive Controller"))
		if not ok or not Drive then
			WindUI:Notify({
				Title   = "VMods – Drivetrain",
				Content = "Could not read Drive Controller.",
				Duration = 5,
			})
			return
		end

		if not VehicleDefaults[vehicle] then
			StoreDefaults(vehicle)
		end
		if VehicleDefaults[vehicle] and not VehicleDefaults[vehicle]["Config"] then
			VehicleDefaults[vehicle]["Config"] = rawget(Drive, "Config")
		end

		rawset(Drive, "Config", selectedDrivetrain)
		TryRestartVehicleUI()

		WindUI:Notify({
			Title   = "VMods – Drivetrain",
			Content = vehicle.Name .. " set to " .. selectedDrivetrain,
			Duration = 4,
		})
	end,
})

-- ── Final Drive ───────────────────────────────

VModTab:Section({ Title = "Final Drive" })

VModTab:Paragraph({
	Title = "Final Drive",
	Desc  = "Lower = higher top speed, less acceleration.\nHigher = more acceleration, lower top speed.\nDefault for most ERLC vehicles is around 4.",
})

local finalDriveValue = 4

VModTab:Slider({
	Title = "Final Drive",
	Desc  = "Adjust the final drive ratio (0.50 – 8.00)",
	Value = { Min = 0.50, Max = 8.00, Default = 4 },
	Step  = 0.25,
	Callback = function(v)
		finalDriveValue = tonumber(v) or 4
	end,
})

VModTab:Button({
	Title = "Apply Final Drive",
	Desc  = "Sets the FinalDrive value on your current/owned vehicle.",
	Callback = function()
		local vehicle = GetDrivenVehicle() or GetLocalPlayerCar()

		if not vehicle or not vehicle:FindFirstChild("Drive Controller") then
			WindUI:Notify({
				Title   = "VMods – Final Drive",
				Content = "No vehicle found! Spawn or enter your car first.",
				Duration = 5,
			})
			return
		end

		local ok, Drive = pcall(require, vehicle:FindFirstChild("Drive Controller"))
		if not ok or not Drive then
			WindUI:Notify({
				Title   = "VMods – Final Drive",
				Content = "Could not read Drive Controller.",
				Duration = 5,
			})
			return
		end

		if not VehicleDefaults[vehicle] then
			StoreDefaults(vehicle)
		end

		rawset(Drive, "FinalDrive", finalDriveValue)
		TryRestartVehicleUI()

		WindUI:Notify({
			Title   = "VMods – Final Drive",
			Content = string.format("FinalDrive set to %.2f on %s", finalDriveValue, vehicle.Name),
			Duration = 4,
		})
	end,
})

-- ── Horsepower ────────────────────────────────

VModTab:Section({ Title = "Horsepower" })

local horsepowerValue = 300

VModTab:Slider({
	Title = "Horsepower",
	Desc  = "Adjust the engine horsepower (50 – 2000)",
	Value = { Min = 50, Max = 2000, Default = 300 },
	Step  = 25,
	Callback = function(v)
		horsepowerValue = tonumber(v) or 300
	end,
})

VModTab:Button({
	Title = "Apply Horsepower",
	Desc  = "Sets the Horsepower value on your current/owned vehicle.",
	Callback = function()
		local vehicle = GetDrivenVehicle() or GetLocalPlayerCar()

		if not vehicle or not vehicle:FindFirstChild("Drive Controller") then
			WindUI:Notify({
				Title   = "VMods – Horsepower",
				Content = "No vehicle found! Spawn or enter your car first.",
				Duration = 5,
			})
			return
		end

		local ok, Drive = pcall(require, vehicle:FindFirstChild("Drive Controller"))
		if not ok or not Drive then
			WindUI:Notify({
				Title   = "VMods – Horsepower",
				Content = "Could not read Drive Controller.",
				Duration = 5,
			})
			return
		end

		if not VehicleDefaults[vehicle] then
			StoreDefaults(vehicle)
		end

		rawset(Drive, "Horsepower", horsepowerValue)
		TryRestartVehicleUI()

		WindUI:Notify({
			Title   = "VMods – Horsepower",
			Content = string.format("Horsepower set to %d on %s", horsepowerValue, vehicle.Name),
			Duration = 4,
		})
	end,
})

-- ── Speed Boost ───────────────────────────────

VModTab:Section({ Title = "Speed Boost" })

VModTab:Paragraph({
	Title = "Speed Boost",
	Desc  = "Instantly pushes your vehicle forward.\n" ..
	        "Works best at speed.\n" ..
	        "High boost strength may cause vehicle to spin out",
})

local boostStrength   = 150
local boostKeybind    = Enum.KeyCode.U
local boostOnCooldown = false

VModTab:Slider({
	Title = "Boost Strength",
	Desc  = "How much velocity is added per boost (50 – 500)",
	Value = { Min = 50, Max = 500, Default = 150 },
	Step  = 25,
	Callback = function(v)
		boostStrength = tonumber(v) or 150
	end,
})

local function FireBoost()
	if boostOnCooldown then return end

	local vehicle = GetDrivenVehicle()
	if not vehicle then
		WindUI:Notify({
			Title   = "VMods – Speed Boost",
			Content = "You must be driving a vehicle to boost.",
			Duration = 3,
		})
		return
	end

	local primary = vehicle.PrimaryPart
	if not primary then return end

	boostOnCooldown = true

	-- Push the car in its current look direction
	local forwardVec = primary.CFrame.LookVector
	local currentVel = primary.AssemblyLinearVelocity
	primary.AssemblyLinearVelocity = currentVel + forwardVec * boostStrength

	-- Brief cooldown so you can't spam it into orbit
	task.delay(0.5, function()
		boostOnCooldown = false
	end)
end

VModTab:Button({
	Title = "Boost!",
	Desc  = "Instantly pushes the vehicle forward.",
	Callback = FireBoost,
})

VModTab:Keybind({
	Title = "Boost Keybind",
	Desc  = "Press to fire a boost while driving.",
	Value = "U",
	Callback = function(v)
		boostKeybind = Enum.KeyCode[v] or Enum.KeyCode.U
	end,
})

-- Listen for the keybind globally
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == boostKeybind then
		FireBoost()
	end
end)

-- ── Custom Multiplier ──────────────────────────

VModTab:Section({ Title = "Custom Multiplier" })

local customMult = 1.5

VModTab:Slider({
	Title = "Multiplier",
	Desc  = "Set a custom multiplier to apply",
	Value = { Min = 1, Max = 10, Default = 1.5 },
	Step  = 0.25,
	Callback = function(v)
		customMult = tonumber(v) or 1.5
	end,
})

VModTab:Button({
	Title = "Apply Custom Multiplier",
	Desc  = "Applies the slider value above as the multiplier.",
	Callback = function()
		RunPreset("×" .. tostring(customMult), customMult)
	end,
})

VModTab:Section({ Title = "Credits" })
VModTab:Paragraph({
	Title = "Credits",
	Desc  = "Made with Claude. Made and edited by woah679",
})

WindUI:Notify({
	Title   = "VMods loaded",
	Content = "Extra Vehicle Mods tab is ready.",
	Duration = 3,
})
