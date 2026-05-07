repeat task.wait() until _G.WindUI and _G.Window and _G.Tabs

local WindUI = _G.WindUI
local Window = _G.Window
local Tabs = _G.Tabs

local Workspace = cloneref(game:GetService("Workspace"))
local Vehicles = Workspace:WaitForChild("Vehicles")

local removed = {}
local changed = {}
local text = "woah679"

local RemovePlates = false
local ChangePlates = false

local function removePlate(car)
	if removed[car] then return end
    FindFirstChild("Body"):FindFirstChild("LicensePlate")
	if plate then
		plate:Destroy()
		removed[car] = true
	end
end

local function ChangePlate(car)
    local PlateText = FindFirstChild("Body"):FindFirstChild("LicensePlate"):FindFirstChildWhichIsA("SurfaceGui"):FindFirstChild("PlateText")
	if PlateText then
		PlateText.Text = text
        changed[car] = true
	end
end


if RemovePlates then
    for _, car in next, Vehicles:GetChildren() do
	    removePlate(car)
    end

    Vehicles.ChildAdded:Connect(function(car)
	    task.wait(0.5)
	    removePlate(car)
    end)

else 
	Vehicles.ChildAdded:Disconnect() -- check this
end

Tabs.Visuals:Input({
	Title = "Plate Text",
	Value = "",
	Placeholder = "woah679",
	Numeric = false,
	Finished = false,
	Callback = function(Value)
		platetext1 = Value
	end
})

Tabs.VehicleMods:Toggle({
	Title = "Change Plates",
	Desc = "Change License Plates to the text above",
	Value = false,
	Callback = function(Value)
		changePlates = Value
	end,
})
