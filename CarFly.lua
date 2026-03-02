local ok,err=pcall(function()
if getgenv()._carfly_final then return end
getgenv()._carfly_final=true

local bind=Enum.KeyCode.J
local rbind=Enum.KeyCode.RightAlt
local on=false
local waitreb=false
local currentSpeed = 150
local kWarningShown = false
local kWarningActive = false      -- lock: warning on screen

local ui=Instance.new("ScreenGui")
ui.ResetOnSpawn=false
ui.Parent=(gethui and gethui()) or game.CoreGui

local m=Instance.new("TextLabel",ui)
m.Size=UDim2.new(0,240*1.5,0,38*1.5)
m.Position=UDim2.new(.5,-120*1.5,.42,0)
m.BackgroundTransparency=1
m.Text=""
m.TextColor3=Color3.fromRGB(255,0,0)
m.TextSize=14*1.5
m.Font=Enum.Font.GothamSemibold
local mStroke=Instance.new("UIStroke",m)
mStroke.Color=Color3.fromRGB(0,0,0)
mStroke.Thickness=mStroke.Thickness*1.5

-- ON/OFF label: same size as Keys list
local s=Instance.new("TextLabel",ui)
s.Size=UDim2.new(0,170*1.5,0,32*1.5)
s.Position=UDim2.new(1,-185*1.5,1,-45*1.5)
s.BackgroundTransparency=1
s.Text="CarFly: OFF"
s.TextColor3=Color3.fromRGB(255,0,0)
s.TextSize=14*1.5               -- MATCHED to Keys
s.Font=Enum.Font.GothamSemibold
local sStroke=Instance.new("UIStroke",s)
sStroke.Color=Color3.fromRGB(0,0,0)
sStroke.Thickness=sStroke.Thickness*1.5

-- Keys list: original 14*1.5
local keysList=Instance.new("TextLabel",ui)
keysList.Size=UDim2.new(0,300*1.5,0,90*1.5)
keysList.Position=UDim2.new(1,-310*1.5,1,-175*1.5)
keysList.BackgroundTransparency=1
keysList.Text="Keys:"..
"\n1. \"-\"  -25 speed"..
"\n2. \"=\"  +25 speed"..
"\n3. \"[\"  75 speed"..
"\n4. \"]\"  250 speed"..
"\n5. \"k\"  3000 speed (buggy)"
keysList.TextColor3=Color3.fromRGB(255,0,0)
keysList.TextSize=14*1.5
keysList.Font=Enum.Font.GothamSemibold
keysList.TextXAlignment=Enum.TextXAlignment.Left
local keysStroke=Instance.new("UIStroke",keysList)
keysStroke.Color=Color3.fromRGB(0,0,0)
keysStroke.Thickness=keysStroke.Thickness*1.5

-- Speed display: same size as Keys list
local speedDisplay=Instance.new("TextLabel",ui)
speedDisplay.Size=UDim2.new(0,120*1.5,0,25*1.5)
speedDisplay.Position=UDim2.new(1,-135*1.5,1,-75*1.5)
speedDisplay.BackgroundTransparency=1
speedDisplay.Text="Speed: 150"
speedDisplay.TextColor3=Color3.fromRGB(255,0,0)
speedDisplay.TextSize=14*1.5      -- MATCHED to Keys
speedDisplay.Font=Enum.Font.GothamSemibold
local speedStroke=Instance.new("UIStroke",speedDisplay)
speedStroke.Color=Color3.fromRGB(0,0,0)
speedStroke.Thickness=speedStroke.Thickness*1.5

local TS=game:GetService("TweenService")
local function fade()
	TS:Create(s,TweenInfo.new(.17),{TextTransparency=.4}):Play()
	task.wait(.17)
	TS:Create(s,TweenInfo.new(.17),{TextTransparency=0}):Play()
end

local function updateSpeedDisplay()
	speedDisplay.Text="Speed: "..currentSpeed
end

local hb,gy,vl
local function clean()
	if hb then hb:Disconnect() hb=nil end
	if vl then pcall(function() vl:Destroy() vl=nil end) end
	if gy then pcall(function() gy:Destroy() gy=nil end) end
end

local function attach()
	local p=game.Players.LocalPlayer
	local c=p and p.Character
	if not c then return end
	local h=c:FindFirstChildOfClass("Humanoid")
	if not h or not h.Sit then return end
	local st=h.SeatPart
	if not st then return end
	local v=st.Parent
	if not v or not v:FindFirstChild("Body") then return end
	local col=v.Body:FindFirstChild("CollisionPart")
	if not col then return end

	for _,d in ipairs(v:GetDescendants()) do if d:IsA("TouchTransmitter") then d:Destroy() end end

	workspace.CurrentCamera.CameraSubject=h

	gy=Instance.new("BodyGyro",col)
	gy.CFrame=workspace.CurrentCamera.CFrame
	gy.MaxTorque=Vector3.new(9e9,9e9,9e9)
	gy.P=9e4

	vl=Instance.new("BodyVelocity",col)
	vl.MaxForce=Vector3.new(9e9,9e9,9e9)
	vl.P=9e4
	vl.Velocity=Vector3.new()

	hb=game:GetService("RunService").Heartbeat:Connect(function()
		if not on then if vl then vl.Velocity=Vector3.new() end return end
		if not h.Sit then clean() return end
		local t=Vector3.new()
		local u=game:GetService("UserInputService")
		local cam=workspace.CurrentCamera.CFrame
		if u:IsKeyDown(Enum.KeyCode.W) then t+=cam.LookVector*currentSpeed end
		if u:IsKeyDown(Enum.KeyCode.S) then t+=cam.LookVector*-currentSpeed end
		if u:IsKeyDown(Enum.KeyCode.A) then t+=cam.RightVector*-currentSpeed end
		if u:IsKeyDown(Enum.KeyCode.D) then t+=cam.RightVector*currentSpeed end
		if vl then vl.Velocity=t end
		if gy then gy.CFrame=cam end
	end)
end

--------------------------------------------------------------------
--  NEW HOLD-TO-REPEAT SPEED CONTROL  (minus / equal)
--------------------------------------------------------------------
local repeatConn = nil          -- heartbeat connection
local repeatKey  = nil          -- which key is repeating
local repeatStart= 0            -- tick() when key went down
local repeatLast = 0            -- tick() of last step
local repeatDelay= 0.4          -- initial repeat interval
local repeatAcc  = 0            -- total amount added this hold

local function stopRepeat()
	if repeatConn then repeatConn:Disconnect(); repeatConn=nil end
	repeatKey=nil
	repeatAcc=0
	task.wait(0.8)
	if not repeatKey then m.Text="" end   -- fade message if nothing else running
end

local function doRepeat()
	local now=tick()
	if now-repeatLast >= repeatDelay then
		repeatLast=now
		if repeatKey==Enum.KeyCode.Minus then
			currentSpeed=math.max(25,currentSpeed-25)
			repeatAcc=repeatAcc-25
		else -- Equal
			currentSpeed=currentSpeed+25
			repeatAcc=repeatAcc+25
		end
		updateSpeedDisplay()
		m.Text=(repeatAcc>0 and "+" or "")..tostring(repeatAcc).."  (speed "..currentSpeed..")"
		m.TextColor3=Color3.fromRGB(255,0,0)
		-- accelerate repeat
		repeatDelay=math.max(0.05,repeatDelay-0.03)
	end
end
--------------------------------------------------------------------

-- Input handler ----------------------------------------------------------
game:GetService("UserInputService").InputBegan:Connect(function(i,g)
	if g then return end
	local code=i.KeyCode

	-- Speed-control keys cancel warning too
	local speedKeys={
		[Enum.KeyCode.Minus]=true,
		[Enum.KeyCode.Equals]=true,
		[Enum.KeyCode.LeftBracket]=true,
		[Enum.KeyCode.RightBracket]=true,
		[Enum.KeyCode.K]=true
	}
	if kWarningActive and speedKeys[code] then
		m.Text=""
		kWarningActive=false
		-- let the normal handler run afterwards
	end

	if waitreb then
		local new=code
		if new==Enum.KeyCode.Unknown then return end
		if new==rbind then
			m.Text="Cant use rebind key"
			task.wait(1.4)
			m.Text="Press Key To Rebind"
			return
		end
		bind=new
		waitreb=false
		m.Text="Rebinded to "..new.Name
		task.wait(2)
		m.Text=""
		return
	end

	if code==bind then
		local h=game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if not h or not h.Sit then
			local oc=s.TextColor3
			local ot=s.Text
			s.Text="CarFly: NOT SEATED"
			s.TextColor3=Color3.fromRGB(255,0,0)
			task.wait(.4)
			s.TextColor3=oc
			s.Text=ot
			return
		end
		on=not on
		s.Text="CarFly: "..(on and"ON"or"OFF")
		fade()
		if on then attach() else clean() end

	elseif code==rbind then
		waitreb=true
		m.Text="Press Key To Rebind"

	elseif code==Enum.KeyCode.Minus then
		repeatStart=tick(); repeatLast=tick(); repeatAcc=0; repeatDelay=0.4; repeatKey=code
		if repeatConn then repeatConn:Disconnect() end
		repeatConn=game:GetService("RunService").Heartbeat:Connect(doRepeat)

	elseif code==Enum.KeyCode.Equals then
		repeatStart=tick(); repeatLast=tick(); repeatAcc=0; repeatDelay=0.4; repeatKey=code
		if repeatConn then repeatConn:Disconnect() end
		repeatConn=game:GetService("RunService").Heartbeat:Connect(doRepeat)

	elseif code==Enum.KeyCode.LeftBracket then
		currentSpeed=75; updateSpeedDisplay()
		m.Text="Speed set to 75"; m.TextColor3=Color3.fromRGB(255,0,0); task.wait(1); m.Text=""

	elseif code==Enum.KeyCode.RightBracket then
		currentSpeed=250; updateSpeedDisplay()
		m.Text="Speed set to 250"; m.TextColor3=Color3.fromRGB(255,0,0); task.wait(1); m.Text=""

	elseif code==Enum.KeyCode.K then
		if not kWarningShown then
			m.Text="Warning: This may lag your PC and may have a lot of bugs. Click \"K\" one more to use this! If you want to not use this set your speed to 60 or 250."
			m.TextColor3=Color3.fromRGB(255,0,0); m.TextSize=16*1.5; kWarningShown=true; kWarningActive=true
		else
			currentSpeed=3000; updateSpeedDisplay()
			m.Text="Speed set to 3000"; m.TextColor3=Color3.fromRGB(255,0,0); kWarningShown=false; kWarningActive=false; task.wait(1); m.Text=""
		end
	end
end)

-- stop repeat on key release
game:GetService("UserInputService").InputEnded:Connect(function(i,g)
	if g then return end
	local code=i.KeyCode
	if (code==Enum.KeyCode.Minus or code==Enum.KeyCode.Equals) and code==repeatKey then
		stopRepeat()
	end
end)

end) -- pcall end
if not ok then warn(err) end

