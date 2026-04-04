repeat task.wait() until _G.WindUI and _G.Window and _G.Functions

local WindUI = _G.WindUI
local Window = _G.Window
local Tabs = _G.Tabs
local Functions = _G.Functions
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local enabled = false
local connection = nil
local rayParams = RaycastParams.new()


local function getGroundPosition()
    local mouse = LocalPlayer:GetMouse()
    local unitRay = Camera:ScreenPointToRay(mouse.X, mouse.Y)
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local character = LocalPlayer.Character
    local vehicle = Functions:GetCurrentLocalPlayerCar()
    local excluded = {}
    if character then table.insert(excluded, character) end
    if vehicle then table.insert(excluded, vehicle) end
    rayParams.FilterDescendantsInstances = excluded

    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 2000, rayParams)
    return result and result.Position
end

local function onInputBegan(input, processed)
    if processed or not enabled then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and
       input.UserInputType ~= Enum.UserInputType.Touch then return end

    local vehicle = Functions:GetCurrentLocalPlayerCar()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")

    if not vehicle then
        WindUI:Notify({ Title = "Click TP", Content = "No vehicle found!", Duration = 2 })
        return
    end

    if not humanoid or not humanoid.SeatPart then
        WindUI:Notify({ Title = "Click TP", Content = "You must be driving a vehicle!", Duration = 2 })
        return
    end

    local pos = getGroundPosition()
    if not pos then return end

    local pivot = vehicle:GetPivot()
    -- Keep the vehicle's current rotation, just move XZ; lift slightly off ground
    local targetCF = CFrame.new(Vector3.new(pos.X, pos.Y + 2, pos.Z)) 
                   * (pivot - pivot.Position)

    vehicle:PivotTo(targetCF)
end

local Toggle = Tabs.Teleports:Toggle({
    Title = "Vehicle Click Teleport",
    Desc = "Click anywhere to teleport your driven vehicle there",
    Value = false,
    Callback = function(state)
        enabled = state
        if state then
            connection = UserInputService.InputBegan:Connect(onInputBegan)
        else
            if connection then connection:Disconnect() connection = nil end
        end
    end,
})

WindUI:Paragraph({ Title = "Credits", Desc = "Made with Claude. Made and edited by woah679"})
WindUI:Notify({ Title = "Click TP Loaded", Content = "Vehicle Click TP is ready!", Duration = 3 })
