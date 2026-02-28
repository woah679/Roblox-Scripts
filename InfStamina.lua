local FillStaminaRemote = FE:WaitForChild("FillStaminaBought", 9e9)
local Vehicles = WorkSpace:WaitForChild("Vehicles", 9e9)



InfiniteStamina = (function()
		while _G.InfiniteStamina do
			local FillStaminaFunc
			for _, v in ipairs(GetConnections(FillStaminaRemote.OnClientEvent)) do
				if v and v.Function then
					FillStaminaFunc = v.Function
					setfenv(FillStaminaFunc, {debug = {
						info = function()
							return false
						end,
					}})
				end
			end

			local StartTick = tick()
			while FillStaminaFunc and (tick() - StartTick) < 2 do
				task.spawn(pcall, FillStaminaFunc)
				task.wait()
			end

			if not FillStaminaFunc then
				task.wait(0.5)
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
				local SpeedMultiplier = _G.VehicleSpeedMultiplier

				if not VehicleData[Vehicle] then
					table.clear(VehicleData)
					StoreVehicleDefaults(Vehicle)
				end

				local Drive = require(Vehicle["Drive Controller"])
				local Defaults = VehicleData[Vehicle]

				if not Defaults then return end 

				local NewHorsepower = math.max(rawget(Defaults, "Horsepower") * SpeedMultiplier, 2000)

				if NewHorsepower < 2160 and SpeedMultiplier > 1.5 then
					NewHorsepower = rawget(Defaults, "Horsepower") * 1.7 * SpeedMultiplier
				end

				rawset(Drive, "Horsepower", (SpeedMultiplier == 1 and rawget(Defaults, "Horsepower") or NewHorsepower))
				rawset(Drive, "FinalDrive", SpeedMultiplier > 1 and (rawget(Defaults, "FinalDrive") / math.sqrt(SpeedMultiplier)) or rawget(Defaults, "FinalDrive"))
				rawset(Drive, "RevAccel", rawget(Defaults, "RevAccel") * SpeedMultiplier)
				rawset(Drive, "FAntiRoll", rawget(Defaults, "FAntiRoll") * SpeedMultiplier)
				rawset(Drive, "SteerDecay", rawget(Defaults, "SteerDecay") * SpeedMultiplier)
			end
		end)
