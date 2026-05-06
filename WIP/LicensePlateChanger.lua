repeat task.wait() until _G.WindUI and _G.Window and _G.Tabs

local Workspace = cloneref(game:GetService("Workspace"))

local WindUI = _G.WindUI
local Window = _G.Window
local Tabs = _G.Tabs

local Vehicles = cloneref(Workspace):WaitForChild("Vehicles")

local removed = {}
local changed = {}
local platetext1 = "woah679"

local removePlates = false
local changePlates = false

local function removePlate(car)
	if removed[car] then return end
    FindFirstChild("Body"):FindFirstChild("LicensePlate")
	if plate then
		plate:Destroy()
		removed[car] = true
	end
end

local function changePlate(car)
    local platetext2 = FindFirstChild("Body"):FindFirstChild("LicensePlate"):FindFirstChildWhichIsA("SurfaceGui"):FindFirstChild("PlateText")
	if platetext2 then
		platetext2.Text = platetext1
        changed[car] = true
	end
end


if removePlates then
    for _, car in next, Vehicles:GetChildren() do
	    removePlate(car)
    end
    Vehicles.ChildAdded:Connect(function(car)
	    task.wait(0.5)
	    removePlate(car)
    end)

    else 
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
		changePlate()
	end,
})
