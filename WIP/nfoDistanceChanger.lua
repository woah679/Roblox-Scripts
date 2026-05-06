repeat task.wait() until _G.WindUI and _G.Window and _G.Tabs

local WindUI = _G.WindUI
local Window = _G.Window
local Tabs = _G.Tabs
local PlayersTab = Tabs.Players

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Distance = 100

local function ChangeDistance(Distance)
    
end

PlayersTab:Slider({
    Title = "Distance",

})

PlayersTab:Button({
    Title = "Change Distance",
    Callback = ChangeDistance
})
