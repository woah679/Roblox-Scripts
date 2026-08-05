repeat task.wait() until _G.WindUI and _G.Functions

local WindUI = _G.WindUI
local Window = _G.Window
local Tabs = _G.Tabs

local Connections = _G.Connections
local Functions = _G.Functions


Tabs.Teleports:Button({
	Title = "Springfield Modshop",
	Desc = "TP to Springfield Modshop",
	Locked = false,
	Callback = function()
		Functions:TeleportTo(CFrame.new(-749, 85, 713)) -- CFrame or a Position (Vector3)
	end,
})
