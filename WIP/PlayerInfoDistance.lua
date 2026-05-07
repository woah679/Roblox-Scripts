repeat task.wait() until _G.WindUI and _G.Window and _G.Tabs

local WindUI = _G.WindUI
local Tabs = _G.Tabs
local PlayersTab = Tabs.Players

local Workspace = cloneref(game:GetService("Workspace"))
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local NameDist = LocalPlayer.NameDisplayDistance
local HealthDist = LocalPlayer.HealthDisplayDistance

local Distance = 100

local function ChangeDistance(Distance)
    NameDist = Distance
    HealthDist = Distance
end


PlayersTab:Section({ Title = "Player Info Distance"})

PlayersTab:Slider({
    Title = "Distance (studs)",
    Step = 5,
    Value = {
        Min = 0,
        Max = 500,
        Default = 100,
        },
    Callback = function(value)
        Distance = value
    end
})

PlayersTab:Button({
    Title = "Change Distance",
    Callback = ChangeDistance(value)
})

WindUI:Notify({ Title = "Success" })
