repeat task.wait() until _G.WindUI and _G.Functions

local WindUI = _G.WindUI
local Window = _G.Window
local Tabs = _G.Tabs

local Connections = _G.Connections
local Functions = _G.Functions

local VModTab = Window:Tab({
	Title = "VMods",
	Icon = "car",
	Locked = false,
})

local Section = VModTab:Section({
	Title = "Quick Preset",
})














local Vehicles = WorkSpace:WaitForChild("Vehicles", 9e9)



Vehicles.ChildAdded:Connect(function(Vehicle)
		if Vehicle:IsA("Model") then
			while not Vehicle:GetAttribute("Owner") do
				task.wait()
			end

			if Vehicle:GetAttribute("Owner") == LocalPlayer.Name then
				Vehicle.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
			end
		end
	end)


	local VehicleData = {}
	local StoreVehicleDefaults = function(Vehicle)
		if not VehicleData[Vehicle] then
			local Drive = require(Vehicle["Drive Controller"])
			VehicleData[Vehicle] = {
				Horsepower = Drive.Horsepower,
				FinalDrive = Drive.FinalDrive,
				RevAccel = Drive.RevAccel,
				FAntiRoll = Drive.FAntiRoll,
				RBrakeForce = Drive.RBrakeForce or 1,
				FBrakeForce = Drive.FBrakeForce or 1,
				PBrakeForce = Drive.PBrakeFrce,
				SteerDecay = Drive.SteerDecay,
				BrakeForce = Drive.BrakeForce
			}
		end
	end

	local ApplySpeedMultiplier = function(Vehicle)
		local suc, err = pcall(function()
			if Vehicle and Vehicle:FindFirstChild("Drive Controller") then
				local SpeedMultiplier = _G.VehicleSpeedMultiplier2

				if not VehicleData[Vehicle] then
					table.clear(VehicleData)
					StoreVehicleDefaults(Vehicle)
				end

				local Drive = require(Vehicle["Drive Controller"])
				local Defaults = VehicleData[Vehicle]

				if not Defaults then return end 

				local NewHorsepower = math.max(rawget(Defaults, "Horsepower") * SpeedMultiplier, 2000)

				if NewHorsepower < 2160 and SpeedMultiplier > 1.2 then
					NewHorsepower = rawget(Defaults, "Horsepower") * 1.5 * SpeedMultiplier
				end

				rawset(Drive, "Horsepower", (SpeedMultiplier == 1 and rawget(Defaults, "Horsepower") or NewHorsepower))
				rawset(Drive, "FinalDrive", SpeedMultiplier > 1 and (rawget(Defaults, "FinalDrive") / math.sqrt(SpeedMultiplier)) or rawget(Defaults, "FinalDrive"))
				rawset(Drive, "RevAccel", rawget(Defaults, "RevAccel") * SpeedMultiplier)
				rawset(Drive, "FAntiRoll", rawget(Defaults, "FAntiRoll") * SpeedMultiplier)
				rawset(Drive, "SteerDecay", rawget(Defaults, "SteerDecay") * SpeedMultiplier)
			end
		end)

		if not suc then
			return false, err
		end

		return true
	end
end
