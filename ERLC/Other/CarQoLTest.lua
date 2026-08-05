repeat task.wait() until _G.WindUI and _G.Window and _G.Functions

local WindUI = _G.WindUI
local Window = _G.Window
local Tabs = _G.Tabs
local Functions = _G.Functions

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function issitting(humanoid)
    return humanoid and humanoid.SeatPart ~= nil
end

local function enterCar()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")

    if not humanoid then
        WindUI:Notify({ Title = "Enter Car", Content = "No character found!", Duration = 3 })
        return
    end

    if issitting(humanoid) then
        WindUI:Notify({ Title = "Enter Car", Content = "You're already in a vehicle!", Duration = 3 })
        return
    end

    local vehicle = Functions:GetCurrentLocalPlayerCar()
    if not vehicle then
        WindUI:Notify({ Title = "Enter Car", Content = "No vehicle found — spawn your car first.", Duration = 4 })
        return
    end

    local driverSeat = vehicle:FindFirstChild("DriverSeat")
    if not driverSeat then
        WindUI:Notify({ Title = "Enter Car", Content = "Driver seat not found!", Duration = 3 })
        return
    end

    driverSeat:Sit(humanoid)
    WindUI:Notify({ Title = "Enter Car", Content = "Success!", Duration = 2 })
end

local function bringCar()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    local hrp = character and character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not hrp then
        WindUI:Notify({ Title = "Bring Car", Content = "No character found!", Duration = 3 })
        return
    end

    if issitting(humanoid) then
        WindUI:Notify({ Title = "Bring Car", Content = "You're already in a vehicle!", Duration = 3 })
        return
    end

    local vehicle = Functions:GetCurrentLocalPlayerCar()
    if not vehicle then
        WindUI:Notify({ Title = "Bring Car", Content = "No vehicle found. Spawn your car first.", Duration = 4 })
        return
    end

    local driverSeat = vehicle:FindFirstChild("DriverSeat")
    if not driverSeat then
        WindUI:Notify({ Title = "Bring Car", Content = "Driver seat not found!", Duration = 3 })
        return
    end

    local savedPosition = hrp.Position + Vector3.new(0, 3, 0)

    local camLook = Camera.CFrame.LookVector
    local flatLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
    local targetCFrame = CFrame.lookAt(savedPosition, savedPosition + flatLook)

    WindUI:Notify({ Title = "Bring Car", Content = "Bringing...", Duration = 2 })

    driverSeat:Sit(humanoid)
    task.wait(0.3)
    vehicle:PivotTo(targetCFrame)

    WindUI:Notify({ Title = "Bring Car", Content = "Success!", Duration = 3 })
end

local isFlipping = false
local function flipCar()
    if isFlipping then
        return
    end

    local vehicle = Functions:GetCurrentLocalPlayerCar()
    if not vehicle or not vehicle.PrimaryPart then
        WindUI:Notify({ Title = "Flip Car", Content = "No vehicle found - spawn your car first.", Duration = 4 })
        return
    end


local FlipWait = tick()
local FlipDB = false

function Flip()
    if FlipDB then
        return end
    local vehicle = Functions:GetCurrentLocalPlayerCar()
    if not vehicle or not vehicle.PrimaryPart then
        WindUI:Notify({ Title = "Flip Car", Content = "No vehicle found - spawn your car first.", Duration = 4 })
	-- Detect Orientation
    local car = vehicle.
	if (car.DriveSeat.CFrame*CFrame.Angles(math.pi/2,0,0)).lookVector.y > .1 or FlipDB then
		FlipWait=tick()
		
	-- Apply Flip
	else
		if tick()-FlipWait>=3 then
			FlipDB=true
			local gyro = car.DriveSeat.Flip
			gyro.maxTorque = Vector3.new(10000,0,10000)
			gyro.P=3000
			gyro.D=500
			wait(1)
			gyro.maxTorque = Vector3.new(0,0,0)
			gyro.P=0
			gyro.D=0
			FlipDB=false
		end
	end
end

Tabs.VehicleMods:Section({ Title = "Car QoL" })

Tabs.VehicleMods:Button({
    Title = "Enter Car",
    Desc = "Enters your spawned car",
    Callback = enterCar,
})

Tabs.VehicleMods:Button({
    Title = "Bring Car to Position",
    Desc = "Enters your car, teleports it to where you were standing, facing your camera direction",
    Callback = bringCar,
})

Tabs.VehicleMods:Button({
    Title = "Flip Car Upright",
    Desc = "Flips your car",
    Callback = flipCar,
})
