repeat task.wait() until _G.WindUI and _G.Window

local WindUI = _G.WindUI
local Tabs = _G.Tabs
local Functions = _G.Functions

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local character = LocalPlayer.Character
local Humanoid = character and character:FindFirstChildWhichIsA("Humanoid")


_G.SusStrength = 1500
_G.SusSpeed = 1
    
function Susseh()
    while _G.Sus do
        local PlayerCar = Functions:GetCurrentLocalPlayerCar()
            
        local speedFactor = math.clamp(1.0 - (_G.SusSpeed - 1) / 19 * 0.8, 0.05, 2)
            
        if PlayerCar and Humanoid.SeatPart and Humanoid.Sit then
            local primary = PlayerCar.PrimaryPart
            if primary then
                local impulseForce = primary.CFrame.RightVector * -_G.SusStrength -- left
                local impulsePos = primary.Position + Vector3.new(0, 3, 0) -- 3 Studs above Center

                    primary:ApplyImpulseAtPosition(impulseForce, impulsePos)

                task.wait(1.5 * speedFactor)

                if not _G.Sus then break end
                    
                impulseForce = primary.CFrame.RightVector * _G.SusStrength -- Right

                    primary:ApplyImpulseAtPosition(impulseForce, impulsePos)
                task.wait(1.5 * speedFactor)
            end
        end
        task.wait()
    end
end


Tabs.VehicleMods:Section({ Title = "Sus 🥵" })

Tabs.VehicleMods:Slider({
        Title = "Push Strength",
        Desc = "Adjust Side Strength",
        Value = {
            Min = 10,
            Max = 3000,
            Default = 1500,
        },
        Callback = function(Value)
            _G.SusStrength = tonumber(Value)
        end
    })
    
Tabs.VehicleMods:Slider({
    Title = "Speed",
    Desc = "Adjust The Super cool speed",
    Value = {
        Min = 1,
        Max = 30,
        Default = 1,
    },
    Callback = function(Value)
        _G.SusSpeed = tonumber(Value)
    end
})

Tabs.VehicleMods:Toggle({
    Title = "🥵   👑",
    Value = false,
    Callback = function(Value)
        _G.Sus = Value
        task.spawn(Susseh)
    end,
})
