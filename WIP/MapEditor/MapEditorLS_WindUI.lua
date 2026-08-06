local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
LocalPlayer:WaitForChild("PlayerGui")
local Character = LocalPlayer.Character
local Deployables = ReplicatedStorage:WaitForChild("Assets").Deployables
local DeployableClient = require(LocalPlayer:WaitForChild("PlayerScripts").Modules.DeployableClient)

if not (Character and Character.Parent) then
	LocalPlayer.CharacterAdded:Wait()
end

local Parent = script.Parent
local Main = Parent:WaitForChild("Main")
local Info = Main:WaitForChild("Info")
local Left = Main:WaitForChild("Left")
local DeleteButton = Main:WaitForChild("DeleteButton")
local MoveButton = Main:WaitForChild("MoveButton")
local Holder = Left:WaitForChild("Holder")
local FilterButtons = Holder:WaitForChild("FilterButtons")
local List = Holder:WaitForChild("List")
local SearchBar = Holder:WaitForChild("SearchBar")
local Assets = script:WaitForChild("Assets")
local LayoutInfo = Holder:WaitForChild("LayoutInfo")
local CreateNew = List:WaitForChild("CreateNew")
local LoadLayout = List:WaitForChild("LoadLayout")
local MapEditor = ReplicatedStorage.FE.MapEditor
local DisplayMsg = Main:WaitForChild("DisplayMsg")
local ExitButton = Holder:WaitForChild("Buttons"):WaitForChild("ExitButton")
local BackButton = Holder:WaitForChild("Buttons"):WaitForChild("BackButton")
local CopyCode = Parent:WaitForChild("CopyCode")
local MapLayouts = workspace:WaitForChild("MapLayouts")
local mouse = LocalPlayer:GetMouse()
local SelectionBox = Assets:WaitForChild("SelectionBox")
local SelectedBox = Assets:WaitForChild("SelectedBox")
local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = { MapLayouts }
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.CollisionGroup = "PlaceableObject"

-- ============================================================================
-- NEW FEATURES: Toggles and State
-- ============================================================================

local SnapEnabled = false
local RotationMode = false  -- true = free rotation with mouse wheel, false = default placement
local CollisionEnabled = true  -- when false, raycast ignores map layout parts for selection

-- Mouse wheel rotation state
local lastMouseWheelDelta = 0
local ROTATION_SPEED = 45  -- degrees per wheel tick

-- ============================================================================
-- Helper to show messages
-- ============================================================================

local function showMessage(type, message)
	DisplayMsg.TextColor3 = type == "Error" and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
	DisplayMsg.Text = message
	DisplayMsg.Visible = true
	task.delay(2, function()
		DisplayMsg.Visible = false
	end)
end

-- ============================================================================
-- Helper to restore part transparency
-- ============================================================================

local function restoreTransparency(part, dimOpacity)
	for _, descendant in ipairs(part:GetDescendants()) do
		if not (descendant:IsA("Seat") or descendant:IsA("VehicleSeat")) and descendant:IsA("BasePart") then
			local origPropT = descendant:GetAttribute("OrigPropT")
			if not origPropT then
				descendant:SetAttribute("OrigPropT", descendant.Transparency)
			end
			descendant.Transparency = dimOpacity and 0.5 or origPropT
		end
	end
end

-- ============================================================================
-- Helper to rebuild list buttons
-- ============================================================================

local function rebuildList()
	for _, child in ipairs(List:GetChildren()) do
		if child:IsA("TextButton") and child.Name ~= "LoadLayout" and child.Name ~= "CreateNew" then
			child:Destroy()
		end
	end
	
	local buttons = {}
	for _, child in ipairs(List:GetChildren()) do
		if child:IsA("TextButton") and child.Name ~= "LoadLayout" and child.Name ~= "CreateNew" then
			table.insert(buttons, child)
		end
	end
	
	table.sort(buttons, function(a, b)
		return a.DisplayName.Text:lower() < b.DisplayName.Text:lower()
	end)

	for i, button in ipairs(buttons) do
		button.LayoutOrder = i
	end
end

-- ============================================================================
-- Helper to update button styling
-- ============================================================================

local function styleButton(button, isSelected)
	if not (button and button.Parent) then return end
	
	local asset = isSelected and Assets.SelectedButton or Assets.DeselectedButton
	button.UIStroke.Color = asset.UIStroke.Color
	button.UIStroke.Transparency = asset.UIStroke.Transparency
	button.UIStroke.UIGradient.Color = asset.UIStroke.UIGradient.Color
	button.UIGradient.Color = asset.UIGradient.Color
end

-- ============================================================================
-- Helper to update tab styling
-- ============================================================================

local function styleTab(tab, isSelected)
	if not (tab and tab.Parent) then return end
	
	local asset = isSelected and Assets.SelectedTab or Assets.DeselectedTab
	tab.UIStroke.Color = asset.UIStroke.Color
	tab.UIStroke.Transparency = asset.UIStroke.Transparency
	tab.UIStroke.UIGradient.Color = asset.UIStroke.UIGradient.Color
	tab.UIGradient.Color = asset.UIGradient.Color
end

-- ============================================================================
-- Helper to update layout info auto-load status
-- ============================================================================

local function updateAutoLoadStatus(layoutData)
	if not layoutData then return end
	
	local autoLoad = layoutData.AutoLoad
	LayoutInfo:WaitForChild("AutoLoad")
	LayoutInfo.AutoLoad.Title.Text = autoLoad and "AUTO LOADED" or "NOT AUTO LOADED"
	LayoutInfo.AutoLoad.Title.TextColor3 = autoLoad and Color3.fromRGB(235, 243, 204) or Color3.fromRGB(243, 217, 214)
	LayoutInfo.AutoLoad.UIStroke.Color = autoLoad and Color3.fromRGB(178, 221, 53) or Color3.fromRGB(210, 42, 27)
end

-- ============================================================================
-- Helper to stop placement and cleanup selection
-- ============================================================================

local function cleanupSelection()
	DeployableClient.stopPlacement()
	isPlacing = false
	
	if selectedModel then
		restoreTransparency(selectedModel, false)
		SelectedBox.Adornee = selectedModel
	end
end

-- ============================================================================
-- Helper to update move/delete button visibility
-- ============================================================================

local function updateInfoVisibility(hasSelection)
	MoveButton.Visible = hasSelection
	DeleteButton.Visible = hasSelection
	Info.Visible = hasSelection
	
	if Info.Visible and selectedModel then
		Info.Frame.Layout.LayoutName.Text = selectedModel.Parent.Parent:GetAttribute("LayoutName") or "--"
		Info.Frame.Prop.PropName.Text = selectedModel:GetAttribute("DisplayName") or selectedModel.Name
	end
end

-- ============================================================================
-- Helper to handle item placement (with snapping and rotation support)
-- ============================================================================

local function onItemPlaced(prefab, cframe)
	if not prefab then return end
	
	if isEditing then
		if isRunningAction then
			showMessage("Error", "Another action is running")
			return
		end
		
		isRunningAction = true
		local result = MapEditor.EditProp:InvokeServer("Edit", selectedModel:GetAttribute("LayoutId"), selectedModel:GetAttribute("PropId"), { CFrame = cframe })
		isRunningAction = false
		
		if result ~= "Success" then
			showMessage("Error", "Error: " .. tostring(result))
			return
		end
		
		restoreTransparency(selectedModel, false)
		cleanupSelection()
	elseif selectedModel and prefab.Name == selectedModel.Name then
		if not currentLayoutId then
			showMessage("No current layout")
			return
		end
		
		if isRunningAction then
			showMessage("Error", "Another action is running")
			return
		end
		
		isRunningAction = true
		local result = MapEditor.EditProp:InvokeServer("Add", currentLayoutId, nil, { objName = prefab.Name, CFrame = cframe })
		isRunningAction = false
		
		if result == "Success" then return end
		
		showMessage("Error", "Error: " .. tostring(result))
	end
end

-- ============================================================================
-- Helper to start placement for a prefab (with rotation support)
-- ============================================================================

local function startPlacement(prefabName, initialRotation)
	SelectedBox.Adornee = nil
	DeployableClient.startPlacement({
		maxItems = 999,
		placeSound = "WoodPlace",
		maxPlacementDistance = 100,
		showPlacementGui = false,
		bypassTool = true,
		prefabName = prefabName,
		onPlaceCallback = function(prefab, cframe)
			-- Apply rotation if in rotation mode and initial rotation was set
			if RotationMode and initialRotation ~= 0 then
				cframe = CFrame.new(cframe.Position) * CFrame.Angles(0, initialRotation / 180, 0)
			end
			onItemPlaced(prefab, cframe)
		end
	})
	isPlacing = true
end

-- ============================================================================
-- Helper to handle filter button clicks
-- ============================================================================

local function handleFilterClick(filterType)
	local layoutsTab = FilterButtons.Layouts
	local propsTab = FilterButtons.Props
	
	if layoutsTab and layoutsTab.Parent then
		styleTab(layoutsTab, filterType == "Layouts")
	end
	
	if propsTab and propsTab.Parent then
		styleTab(propsTab, filterType == "Props")
	end
	
	List.LayoutName.Visible = true
	List.CreateNew.Visible = false
	List.LoadLayout.Visible = false
	rebuildList()
	List.Visible = true
	LayoutInfo.Visible = false
	BackButton.Visible = true
	currentLayoutId = nil
	cleanupSelection()

	if selectedModel then
		restoreTransparency(selectedModel, false)
		SelectedBox.Adornee = selectedModel
	end
	
	for _, child in ipairs(Deployables:GetChildren()) do
		if child:IsA("Model") then
			local button = Assets.ItemButton:Clone()
			button.Name = child.Name
			button.DisplayName.Text = child:GetAttribute("DisplayName") or child.Name
			button.Parent = List
			button.Activated:Connect(function()
				styleButton(button, false)
				
				if selectedButton == button then
					currentLayoutId = nil
					cleanupSelection()
					return
				end
				
				cleanupSelection()
				selectedModel = nil
				selectedButton = button
				
				styleButton(button, true)
				local prefabName = button.Name
				SelectedBox.Adornee = nil
				startPlacement(prefabName)
			end)
		end
	end
	
	rebuildList()
end

-- ============================================================================
-- Helper to handle layout list display
-- ============================================================================

local function showLayoutsList(loadData)
	local layoutsTab = FilterButtons.Layouts
	local propsTab = FilterButtons.Props
	
	if layoutsTab and layoutsTab.Parent then
		styleTab(layoutsTab, true)
	end
	
	if propsTab and propsTab.Parent then
		styleTab(propsTab, false)
	end
	
	List.LayoutName.Visible = false
	List.CreateNew.Visible = true
	List.LoadLayout.Visible = true
	LayoutInfo.Delete.Title.Text = "DELETE"
	rebuildList()
	List.Visible = true
	LayoutInfo.Visible = false
	BackButton.Visible = false
	currentLayoutId = nil
	cleanupSelection()

	if selectedModel then
		restoreTransparency(selectedModel, false)
		SelectedBox.Adornee = selectedModel
	end
	
	if loadData then
		isRunningAction = true
		allLayouts = MapEditor.GetLayouts:InvokeServer()
		isRunningAction = false
	end
	
	if not allLayouts then return end

	for i, layoutData in ipairs(allLayouts) do
		local button = Assets.ItemButton:Clone()
		button.Name = i
		button.DisplayName.Text = layoutData.Name
		button.Parent = List
		button.Activated:Connect(function()
			List.Visible = false
			LayoutInfo.LayoutName.InputText.Text = layoutData.Name or "Unnamed Layout"
			List.LayoutName.Text = "Layout: " .. (layoutData.Name or "Unnamed Layout")
			LayoutInfo.Visible = true
			BackButton.Visible = true
			currentLayoutId = i
			handleFilterClick("Layouts")
			updateAutoLoadStatus(layoutData)
		end)
	end
	
	rebuildList()
end


local function getTopModel(instance)
	if not instance then return end
	
	local model = instance:FindFirstAncestorWhichIsA("Model")
	if not model then return end
	
	if model.Parent:IsA("Folder") and model.Parent.Parent and model.Parent.Parent.Parent == MapLayouts then
		return model
	end
	
	if model:IsDescendantOf(MapLayouts) then
		return getTopModel(model)
	end
end


local function onMouseMove()
	isPlacing or return
	
	-- If collision is disabled, skip raycasting entirely
	if not CollisionEnabled then return end
	
	local instance = raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction * 200, raycastParams)
	
	if not instance then return end
	
	local model = getTopModel(instance)
	if model == selectedModel then
		model = nil
	end
	
	SelectedBox.Adornee = model
end


local function onLeftClick()
	isPlacing or return
	
	-- If collision is disabled, skip raycasting entirely
	if not CollisionEnabled then return end
	
	local instance = raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction * 200, raycastParams)
	
	if not instance then return end
	
	local model = getTopModel(instance)
	if not model then
		cleanupSelection()
		return
	end
	
	selectedModel = model
	SelectedBox.Adornee = nil
	SelectedBox.Adornee = model
	updateInfoVisibility(true)
end


local function onExitButtonClicked()
	
	if selectedModel then
		restoreTransparency(selectedModel, false)
	end
	
	cleanupSelection()
	Parent:Destroy()
end

-- ============================================================================
-- Helper to handle back button
-- ============================================================================

local function onBackButtonClicked()
	if not LayoutInfo.Visible then
		if List.Visible then
			local layoutsTab = FilterButtons.Layouts
			local propsTab = FilterButtons.Props
			
			if layoutsTab and layoutsTab.Parent then
				styleTab(layoutsTab, true)
			end
			
			if propsTab and propsTab.Parent then
				styleTab(propsTab, false)
			end
			
			LayoutInfo.Visible = true
			List.Visible = false
		else
			return
		end
	else
		LayoutInfo.Visible = false
		showLayoutsList(allLayouts)
	end
end

-- ============================================================================
-- Helper to handle delete button
-- ============================================================================

local function onDeleteButtonClicked()
	if not selectedModel then return end
	
	if isRunningAction then
		showMessage("Error", "Another action is running")
		return
	end
	
	isRunningAction = true
	local result = MapEditor.EditProp:InvokeServer("Delete", selectedModel:GetAttribute("LayoutId"), selectedModel:GetAttribute("PropId"))
	isRunningAction = false
	
	if result ~= "Success" then
		showMessage("Error", "Error: " .. tostring(result))
		return
	end
	
	cleanupSelection()
end

-- ============================================================================
-- Helper to handle layout delete confirmation
-- ============================================================================

local function onLayoutDeleteConfirmed()
	if LayoutInfo.Delete.Title.Text == "DELETE" then
		LayoutInfo.Delete.Title.Text = "CONFIRM DELETE?"
		
		task.delay(5, function()
			if LayoutInfo.Delete.Title.Text ~= "DELETE" then return end
			
			if deleteConfirmTriggered then return end
			LayoutInfo.Delete.Title.Text = "DELETE"
		end)
		
		deleteConfirmTriggered = true
		LayoutInfo.Delete.Title:GetPropertyChangedSignal("Text"):Wait()
	else
		return
	end
end

-- ============================================================================
-- Helper to handle layout load button
-- ============================================================================

local function onLoadLayoutButtonClicked()
	if isRunningAction then
		showMessage("Error", "Another action is running")
		return
	end
	
	isRunningAction = true
	local success, result = MapEditor.EditLayout:InvokeServer("LoadShared", List.LoadLayout.ID.Text)
	isRunningAction = false
	
	if success ~= "Success" then
		showMessage("Error", "Error: " .. tostring(success))
		return
	end
	
	List.LoadLayout.ID.Text = ""
	allLayouts = result
	showMessage("Success", "Layout imported!")
	showLayoutsList(result)
end

-- ============================================================================
-- Helper to handle layout unload button
-- ============================================================================

local function onUnloadLayoutButtonClicked()
	if isRunningAction then
		showMessage("Error", "Another action is running")
		return
	end
	
	isRunningAction = true
	local result = MapEditor.EditLayout:InvokeServer("Unload", currentLayoutId)
	isRunningAction = false
	
	if result == "Success" then
		showMessage("Success", "Layout unloaded")
	else
		showMessage("Error", "Error: " .. tostring(result))
	end
end

-- ============================================================================
-- Helper to handle layout edit button
-- ============================================================================

local function onEditLayoutButtonClicked()
	if MapLayouts:FindFirstChild(currentLayoutId) then
		handleFilterClick("Props")
	else
		showMessage("Error", "Layout must be loaded first")
	end
end

-- ============================================================================
-- Helper to handle layout share button
-- ============================================================================

local function onShareLayoutButtonClicked()
	if isRunningAction then
		showMessage("Error", "Another action is running")
		return
	end
	
	isRunningAction = true
	local success, code = MapEditor.EditLayout:InvokeServer("Share", currentLayoutId)
	isRunningAction = false
	
	if success == "Success" then
		CopyCode.Message.Input.TextBox.Text = code
		CopyCode.Visible = true
	else
		showMessage("Error", "Error: " .. tostring(success))
	end
end

-- ============================================================================
-- Helper to handle layout auto-load button
-- ============================================================================

local function onAutoLoadLayoutButtonClicked()
	if isRunningAction then
		showMessage("Error", "Another action is running")
		return
	end
	
	isRunningAction = true
	local success, result = MapEditor.EditLayout:InvokeServer("AutoLoad", currentLayoutId)
	isRunningAction = false
	
	if success ~= "Success" then
		showMessage("Error", "Error: " .. tostring(success))
		return
	end
	
	allLayouts = result
	local autoLoadStatus = allLayouts[currentLayoutId].AutoLoad and "" or " not"
	showMessage("Success", `Layout is{autoLoadStatus} auto-loaded.`)
	updateAutoLoadStatus(allLayouts[currentLayoutId])
end

-- ============================================================================
-- Helper to handle layout load button (in-game)
-- ============================================================================

local function onLoadInGameButtonClicked()
	if isRunningAction then
		showMessage("Error", "Another action is running")
		return
	end
	
	isRunningAction = true
	local result = MapEditor.EditLayout:InvokeServer("Load", currentLayoutId)
	isRunningAction = false
	
	if result == "Success" then
		showMessage("Success", "Layout loaded in-game")
	else
		showMessage("Error", "Error: " .. tostring(result))
	end
end

-- ============================================================================
-- Helper to handle layout create button
-- ============================================================================

local function onCreateNewButtonClicked()
	if isRunningAction then
		showMessage("Error", "Another action is running")
		return
	end
	
	isRunningAction = true
	local success, result = MapEditor.EditLayout:InvokeServer("Create")
	isRunningAction = false
	
	if success ~= "Success" then
		showMessage("Error", "Error: " .. tostring(success))
		return
	end
	
	allLayouts = result
	showMessage("Success", "New layout created")
	showLayoutsList(result)
end


local function onRenameLayoutButtonClicked()
	if isRunningAction then
		showMessage("Error", "Another action is running")
		return
	end
	
	isRunningAction = true
	local success, result = MapEditor.EditLayout:InvokeServer("ChangeName", currentLayoutId, LayoutInfo.LayoutName.InputText.Text)
	isRunningAction = false
	
	if success == "Success" then
		showMessage("Success", "Layout renamed")
		allLayouts = result
	else
		showMessage("Error", "Error: " .. tostring(success))
	end
end


local function onSearchTextChanged()
	local query = string.lower(SearchBar.SearchText.Text)
	
	for _, child in ipairs(List:GetChildren()) do
		if child:IsA("TextButton") and child.Name ~= "LoadLayout" and child.Name ~= "CreateNew" then
			if query == "" then
				child.Visible = true
			elseif string.match(string.lower(child.DisplayName.Text), query) then
				child.Visible = true
			else
				child.Visible = false
			end
		end
	end
end

-- ============================================================================
-- Helper to handle mouse button down (raycast for selection)
-- ============================================================================

local function onMouseButtonDown()
	isPlacing or return
	
	-- If collision is disabled, skip raycasting entirely
	if not CollisionEnabled then return end
	
	local instance = raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction * 200, raycastParams)
	
	if not instance then return end
	
	local model = getTopModel(instance)
	if not model then
		cleanupSelection()
		return
	end
	
	selectedModel = model
	SelectedBox.Adornee = nil
	SelectedBox.Adornee = model
	updateInfoVisibility(true)
end

-- ============================================================================
-- Helper to handle keyboard input (collision toggle support)
-- ============================================================================

local function onKeyPress(keyCode)
	if _G.IgnoreInput then return end
	
	if keyCode == Enum.KeyCode.Delete or keyCode == Enum.KeyCode.Backspace then
		if selectedModel then
			if not isPlacing then
				onDeleteButtonClicked()
				return
			end
			
			cleanupSelection()
			selectedModel = nil
		elseif isPlacing and selectedButton then
			styleButton(selectedButton, false)
			currentLayoutId = nil
			cleanupSelection()
		end
	end
	
	-- Toggle collision with Ctrl + C (or just C if you prefer)
	if keyCode == Enum.KeyCode.C then
		CollisionEnabled = not CollisionEnabled
		showMessage(CollisionEnabled and "Success" or "Error", `Collision{CollisionEnabled and " enabled" or " disabled"}`)
	end
	
	-- Toggle snapping with Ctrl + S (or just S if you prefer)
	if keyCode == Enum.KeyCode.S then
		SnapEnabled = not SnapEnabled
		showMessage(SnapEnabled and "Success" or "Error", `Snapping{SnapEnabled and " enabled" or " disabled"}`)
	end
	
	-- Toggle rotation mode with Ctrl + R (or just R if you prefer)
	if keyCode == Enum.KeyCode.R then
		RotationMode = not RotationMode
		showMessage(RotationMode and "Success" or "Error", `Rotation Mode{RotationMode and " enabled" or " disabled"}`)
	end
end

-- ============================================================================
-- Helper to handle mouse wheel for rotation (when in rotation mode)
-- ============================================================================

local function onMouseWheel()
	if RotationMode then
		local delta = math.floor(mouse.Delta.Y / 120) * ROTATION_SPEED
		lastMouseWheelDelta += delta
	end
end

-- ============================================================================
-- Helper to apply grid snapping to CFrame (when snapping is enabled)
-- ============================================================================

local function applySnapping(cframe)
	if not SnapEnabled then return cframe end
	
	local pos = cframe.Position
	local rot = cframe.Rotation
	local scale = cframe.Scale
	
	-- Snap position to nearest 1 unit grid
	local snappedPos = Vector3.new(
		math.floor(pos.X + 0.5),
		math.floor(pos.Y + 0.5),
		math.floor(pos.Z + 0.5)
	)
	
	return CFrame.new(snappedPos, pos + rot * scale)
end

-- ============================================================================
-- Initialize state variables
-- ============================================================================

local isPlacing = false
local isEditing = false
local isRunningAction = false
local selectedModel = nil
local selectedButton = nil
local currentLayoutId = nil
local allLayouts = nil
local deleteConfirmTriggered = false

-- ============================================================================
-- Connect events
-- ============================================================================

Parent:WaitForChild("Open").OnClientEvent:Connect(function(data)
	allLayouts = data
	handleFilterClick("Props")
end)

for _, child in ipairs(FilterButtons:GetChildren()) do
	if child:IsA("TextButton") then
		child.Activated:Connect(function()
			if child.Name == "Props" then
				handleFilterClick("Props")
			elseif child.Name == "Layouts" then
				showLayoutsList(true)
			end
		end)
	end
end

ExitButton.Activated:Connect(onExitButtonClicked)
BackButton.Activated:Connect(onBackButtonClicked)
DeleteButton.Activated:Connect(onDeleteButtonClicked)
MoveButton.Activated:Connect(function()
	if not selectedModel then return end
	
	restoreTransparency(selectedModel, true)
	local prefabName = selectedModel:GetAttribute("PropName")
	SelectedBox.Adornee = nil
	startPlacement(prefabName)
	isPlacing = true
end)

List.LoadLayout.Enter.Activated:Connect(onLoadLayoutButtonClicked)
LayoutInfo.Unload.Activated:Connect(onUnloadLayoutButtonClicked)
LayoutInfo.Delete.Activated:Connect(function()
	if LayoutInfo.Delete.Title.Text == "DELETE" then
		onLayoutDeleteConfirmed()
	else
		showMessage("Error", "Another action is running")
	end
end)

LayoutInfo.Edit.Activated:Connect(onEditLayoutButtonClicked)
LayoutInfo.Share.Activated:Connect(onShareLayoutButtonClicked)
CopyCode.Close.Activated:Connect(function()
	CopyCode.Visible = false
end)

LayoutInfo.AutoLoad.Activated:Connect(onAutoLoadLayoutButtonClicked)
LayoutInfo.Load.Activated:Connect(onLoadInGameButtonClicked)
CreateNew.Activated:Connect(onCreateNewButtonClicked)
LayoutInfo.LayoutName.Enter.Activated:Connect(onRenameLayoutButtonClicked)
SearchBar.SearchText.Changed:Connect(onSearchTextChanged)

-- ============================================================================
-- Connect input events (with collision toggle support)
-- ============================================================================

mouse.Button1Down:Connect(function()
	isPlacing or return
	
	-- If collision is disabled, skip raycasting entirely
	if not CollisionEnabled then return end
	
	local instance = raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction * 200, raycastParams)
	
	if not instance then return end
	
	local model = getTopModel(instance)
	if not model then
		cleanupSelection()
		return
	end
	
	selectedModel = model
	SelectedBox.Adornee = nil
	SelectedBox.Adornee = model
	updateInfoVisibility(true)
end)

UserInputService.InputBegan:Connect(onKeyPress)

-- Mouse wheel for rotation mode
mouse.Move:Connect(function() onMouseWheel() end)

-- ============================================================================
-- Connect map layout events (collision toggle support)
-- ============================================================================

MapLayouts.ChildAdded:Connect(function() 
	if CollisionEnabled then handleFilterClick("Layouts") end
end)

MapLayouts.ChildRemoved:Connect(function() 
	if CollisionEnabled then handleFilterClick("Layouts") end
end)

-- ============================================================================
-- Connect mouse move for selection (collision toggle support)
-- ============================================================================

mouse.Move:Connect(onMouseMove)
