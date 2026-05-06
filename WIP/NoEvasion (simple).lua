local Workspace = game:GetService("Workspace")
local EvasionDetectors = Workspace:FindFirstChild("TrafficDetections"):FindFirstChild("EvasionDetections")

if EvasionDetectors then
    EvasionDetectors:Destroy()
end
