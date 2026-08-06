repeat task.wait() until _G.WindUI and _G.Tabs

local WindUI = _G.WindUI
local Tabs = _G.Tabs

if CustomMapEditor then 
	WindUI:Notify({
		Title = "Map Editor Already Loaded",
		Duration = 5
	})
end

local MapEditorScript = loadstring(readfile("erlc/MapEditorLS_WindUI.lua"))
MapEditorScript()
  
if not MapEditorScript then
	WindUI:Notify({
		Title = "Map Editor",
		Content = "Failed to load Map Editor Script"
	})
	return
end


local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Create the Props tab (this is where all our Map Editor functionality lives)
local PropsTab = Window:Tab({
	Title = "Map Editor",
	Icon = "solar:box-2-bold",
	Border = true,
})

-- Add a section for filter controls
local FilterSection = PropsTab:Section({
	Title = "Filter",
	Desc = "Select a category to browse",
	TextSize = 14,
})

-- Create placeholder buttons that will be replaced by the actual filter system
-- These are just visual placeholders until the original script's filter logic kicks in
local LayoutsButton = FilterSection:Button({
	Title = "Layouts",
	Icon = "solar:layout-grid-bold",
	Callback = function()
		if MapEditorScript.showLayoutsList then
			MapEditorScript.showLayoutsList(true)
		end
	end,
})

local PropsButton = FilterSection:Button({
	Title = "Props",
	Icon = "solar:box-2-bold",
	Callback = function()
		if MapEditorScript.handleFilterClick then
			MapEditorScript.handleFilterClick("Props")
		end
	end,
})



-- Add a section for layout info (shown when a layout is selected)
local InfoSection = PropsTab:Section({
	Title = "Layout Info",
	Desc = "Details about the currently selected layout",
	TextSize = 14,
})

InfoSection:Paragraph({
	Title = "Status",
	Text = "Select a layout from the list to view details here.",
	FontWeight = Enum.FontWeight.Medium,
})


local ActionsSection = PropsTab:Section({
	Title = "Actions",
	Desc = "Manage your selected item",
	TextSize = 14,
})

ActionsSection:Paragraph({
	Title = "Selected Item",
	Desc = "Select an item in the workspace to see available actions.",
})

-- Add a section for tips
PropsTab:Divider()

:Paragraph({
	Title = "Keyboard Shortcuts",
	Desc =  "C - Toggle collision detection\n" ..
			"S - Toggle grid snapping\n" ..
			"R - Enable free rotation mode"
})

WindUI:Notify({ 
	Title = " Map Editor Loaded"
})

if not MapEditorScript then
	_G.CustomMapEditor = false
else
	_G.CustomMapEditor = true
end
