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
