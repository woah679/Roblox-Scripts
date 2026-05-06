local Workspace   = cloneref(game:GetService("Workspace"))
local BountyVehicles = Workspace:WaitForChild("BountyVehicles", 9e9):WaitForChild("Vehicles", 9e9)
local ForSaleVehicles = Workspace:WaitForChild("ForSaleVehicles", 9e9):WaitForChild("Vehicles", 9e9)

local function IsMostValuable(vehicle)
    local val = vehicle:GetAttribute("MostValuableBountyCar")
    return val
end

print("Bounty Vehicles:")
if #BountyVehicles:GetChildren() > 0 then
    for _, vehicle in ipairs(BountyVehicles:GetChildren()) do
        IsMostValuable(vehicle)
        print(tostring(vehicle).. " - Most Valuable: " .. tostring(val))
    end
else
    print("No bounty vehicles found")
end
print(" ")

print("For Sale Vehicles:")
if #ForSaleVehicles:GetChildren() > 0 then
    for _, vehicle in ipairs(ForSaleVehicles:GetChildren()) do
        print(tostring(vehicle))
    end
else
    print("No for sale vehicles found")
end

print("done")
