-- Carbon | Jailbreak 606849621
-- Tabs: Player, Vehicle, Combat, Visuals, Settings

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RS = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- ── Helpers ───────────────────────────────────────────────────────────────
local function getChar() return lp.Character end
local function getHum()  local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end

local function findUpvalue(pred)
	for _, c in ipairs(getconnections(RunService.Heartbeat)) do
		local ok, fn = pcall(function() return c.Function end)
		if ok and fn then
			local ok2, uvs = pcall(debug.getupvalues, fn)
			if ok2 then for _, v in pairs(uvs) do if pred(v) then return v end end end
		end
	end
end

-- ── Data ──────────────────────────────────────────────────────────────────
local VehicleUtils = require(RS:FindFirstChild("VehicleUtils", true))
local RobberyConsts = require(RS:FindFirstChild("RobberyConsts", true))

local ROBBERY_NAMES = {
	[1]="Bank",[2]="Jewelry Store",[3]="Museum",[4]="Power Plant",
	[5]="Passenger Train",[6]="Cargo Train",[7]="Cargo Ship",[8]="Cargo Plane",
	[9]="Gas Station",[10]="Donut Store",[11]="Grocery Store",[12]="Money Truck",
	[13]="Home Vault",[14]="Tomb",[15]="Crown Jewel",[16]="Mansion",[17]="Oil Rig",
}

-- ESP storage
local espStorage = Instance.new("Folder")
espStorage.Name = "CarbonESP"
if syn and syn.protect_gui then syn.protect_gui(espStorage) espStorage.Parent = CoreGui
elseif getgui then espStorage.Parent = getgui()
else espStorage.Parent = CoreGui end

-- ── ESP ───────────────────────────────────────────────────────────────────
local espCache = {}
local espFlags = { name=false, team=false, health=false, distance=false }

local function hpColor(h) local p = h.Health/h.MaxHealth return p>=0.75 and Color3.fromRGB(0,220,0) or p>=0.35 and Color3.fromRGB(255,200,0) or Color3.fromRGB(255,50,50) end

local function removeESP(player)
	if not espCache[player] then return end
	espCache[player].gui:Destroy()
	if espCache[player].conn then espCache[player].conn:Disconnect() end
	espCache[player] = nil
end

local function updateVis(player)
	local e = espCache[player]
	if not e then return end
	local any = espFlags.name or espFlags.team or espFlags.health or espFlags.distance
	e.gui.Enabled = any
	e.gui.MaxDistance = any and math.huge or 0
	e.nameLabel.Visible  = espFlags.name
	e.teamLabel.Visible  = espFlags.team
	e.hpLabel.Visible    = espFlags.health
	e.distLabel.Visible  = espFlags.distance
end

local function applyESP(player, char)
	local head = char:WaitForChild("Head", 5)
	local hum  = char:WaitForChild("Humanoid", 5)
	if not head or not hum then return end

	local bb = Instance.new("BillboardGui")
	bb.Adornee = head bb.Size = UDim2.new(0,200,0,22) bb.StudsOffset = Vector3.new(0,2.5,0)
	bb.AlwaysOnTop = true bb.ResetOnSpawn = false bb.Enabled = false bb.Parent = espStorage

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0,100,1,0) frame.Position = UDim2.new(0.5,0,0,0)
	frame.AnchorPoint = Vector2.new(0.5,0) frame.BackgroundColor3 = Color3.fromRGB(15,15,15)
	frame.BackgroundTransparency = 0.1 frame.BorderSizePixel = 0
	frame.AutomaticSize = Enum.AutomaticSize.X frame.Parent = bb
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0,5)

	local list = Instance.new("UIListLayout", frame)
	list.FillDirection = Enum.FillDirection.Horizontal list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0,3)
	local pad = Instance.new("UIPadding", frame)
	pad.PaddingLeft = UDim.new(0,6) pad.PaddingRight = UDim.new(0,6)

	local function makeLabel(order)
		local l = Instance.new("TextLabel", frame)
		l.BackgroundTransparency = 1 l.Size = UDim2.new(0,0,1,0) l.AutomaticSize = Enum.AutomaticSize.X
		l.TextSize = 13 l.TextStrokeTransparency = 0 l.TextStrokeColor3 = Color3.new()
		l.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold) l.LayoutOrder = order
		return l
	end

	local nameLabel = makeLabel(1) nameLabel.Text = player.Name nameLabel.TextColor3 = Color3.fromRGB(235,235,235)
	local teamLabel = makeLabel(2)
	local team = player.Team
	teamLabel.Text = team and team.Name or "?" teamLabel.TextColor3 = team and team.TeamColor.Color or Color3.fromRGB(180,180,180)
	local hpLabel = makeLabel(3) hpLabel.Text = math.round(hum.Health).."hp" hpLabel.TextColor3 = hpColor(hum)
	local distLabel = makeLabel(4) distLabel.TextColor3 = Color3.fromRGB(180,220,255)

	local conn = hum:GetPropertyChangedSignal("Health"):Connect(function()
		hpLabel.TextColor3 = hpColor(hum)
		hpLabel.Text = math.round(hum.Health).."hp"
	end)

	-- distance update
	local distConn = RunService.Heartbeat:Connect(function()
		local myRoot = getRoot()
		local theirRoot = char:FindFirstChild("HumanoidRootPart")
		if myRoot and theirRoot then
			distLabel.Text = math.round((myRoot.Position - theirRoot.Position).Magnitude).."m"
		end
	end)

	espCache[player] = { gui=bb, conn=conn, distConn=distConn, nameLabel=nameLabel, teamLabel=teamLabel, hpLabel=hpLabel, distLabel=distLabel }
	updateVis(player)
end

local espInited = false
local function initESP()
	if espInited then return end espInited = true
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp then
			if p.Character then task.spawn(applyESP, p, p.Character) end
			p.CharacterAdded:Connect(function(c) task.spawn(applyESP, p, c) end)
			p.CharacterRemoving:Connect(function() removeESP(p) end)
		end
	end
	Players.PlayerAdded:Connect(function(p)
		if p.Character then task.spawn(applyESP, p, p.Character) end
		p.CharacterAdded:Connect(function(c) task.spawn(applyESP, p, c) end)
		p.CharacterRemoving:Connect(function() removeESP(p) end)
	end)
	Players.PlayerRemoving:Connect(removeESP)
end

local function setESPFlag(key, val)
	espFlags[key] = val
	if val then initESP() end
	for player in pairs(espCache) do updateVis(player) end
end

-- ── Robbery Radar GUI ─────────────────────────────────────────────────────
local radarGui, radarConn

local function buildRadar()
	if radarGui then return end
	local sg = Instance.new("ScreenGui")
	sg.Name = "CarbonRadar" sg.ResetOnSpawn = false sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	if syn and syn.protect_gui then syn.protect_gui(sg) end sg.Parent = CoreGui

	local frame = Instance.new("Frame", sg)
	frame.BackgroundColor3 = Color3.fromRGB(12,12,12) frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0 frame.Position = UDim2.new(1,-215,0.5,-165)
	frame.Size = UDim2.new(0,205,0,10) frame.AutomaticSize = Enum.AutomaticSize.Y
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6)
	local p = Instance.new("UIPadding", frame)
	p.PaddingTop = UDim.new(0,5) p.PaddingBottom = UDim.new(0,5)
	p.PaddingLeft = UDim.new(0,7) p.PaddingRight = UDim.new(0,7)
	local list = Instance.new("UIListLayout", frame)
	list.SortOrder = Enum.SortOrder.LayoutOrder list.Padding = UDim.new(0,2)

	local hdr = Instance.new("TextLabel", frame)
	hdr.BackgroundTransparency = 1 hdr.Size = UDim2.new(1,0,0,15)
	hdr.Text = "Robbery Status" hdr.TextColor3 = Color3.fromRGB(200,200,200)
	hdr.TextSize = 11 hdr.Font = Enum.Font.GothamBold hdr.LayoutOrder = 0

	local labels = {}
	for id = 1, 17 do
		local lbl = Instance.new("TextLabel", frame)
		lbl.BackgroundTransparency = 1 lbl.Size = UDim2.new(1,0,0,14)
		lbl.TextSize = 12 lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Font = Enum.Font.Gotham lbl.TextStrokeTransparency = 0.6
		lbl.LayoutOrder = id labels[id] = lbl
	end

	local stateFolder = RS:FindFirstChild("RobberyState", true)
	local STATE_COLOR = { [1]=Color3.fromRGB(60,220,80), [2]=Color3.fromRGB(240,200,0), [3]=Color3.fromRGB(200,50,50) }
	local STATE_LABEL = { [1]="OPEN", [2]="ACTIVE", [3]="CLOSED" }

	local function refresh()
		if not stateFolder then stateFolder = RS:FindFirstChild("RobberyState", true) end
		if not stateFolder then return end
		for id = 1, 17 do
			local val = stateFolder:FindFirstChild(tostring(id))
			local s = val and val.Value or 3
			local lbl = labels[id]
			if lbl and lbl.Parent then
				lbl.Text = string.format("[%d] %-18s %s", id, ROBBERY_NAMES[id] or "?", STATE_LABEL[s] or "?")
				lbl.TextColor3 = STATE_COLOR[s] or Color3.new(1,1,1)
			end
		end
	end

	refresh()
	local t = 0
	radarConn = RunService.Heartbeat:Connect(function(dt) t=t+dt if t>=1.5 then t=0 refresh() end end)
	radarGui = sg
end

local function destroyRadar()
	if radarConn then radarConn:Disconnect() radarConn = nil end
	if radarGui then radarGui:Destroy() radarGui = nil end
end

-- ── Module ────────────────────────────────────────────────────────────────
return function(Tabs)

	-- ══════════════════════════════════════════════════════════════════
	-- PLAYER TAB
	-- ══════════════════════════════════════════════════════════════════
	local MovSection = Tabs.Player:AddLeftGroupbox("Movement")

	-- Speed Hack
	local speedConn local speedVal = 28
	MovSection:AddToggle("SpeedHack", {
		Text = "Speed Hack", Default = false,
		Callback = function(on)
			if speedConn then speedConn:Disconnect() speedConn = nil end
			if on then
				speedConn = RunService.Heartbeat:Connect(function()
					local h = getHum() if h and h.WalkSpeed > 0 then h.WalkSpeed = speedVal end
				end)
			else local h = getHum() if h then h.WalkSpeed = 16 end end
		end
	})
	MovSection:AddSlider("SpeedVal", { Text="Walk Speed", Default=28, Min=16, Max=250, Rounding=0, Callback=function(v) speedVal=v end })

	-- Fly
	local flyConn, flyBV, flyBG local flySpeed = 60
	MovSection:AddToggle("Fly", {
		Text = "Fly", Default = false,
		Callback = function(on)
			if flyConn then flyConn:Disconnect() flyConn = nil end
			if flyBV then flyBV:Destroy() flyBV = nil end
			if flyBG then flyBG:Destroy() flyBG = nil end
			local h = getHum()
			if on then
				local root = getRoot() if not root then return end
				if h then h.PlatformStand = true end
				flyBV = Instance.new("BodyVelocity") flyBV.MaxForce = Vector3.new(1e5,1e5,1e5) flyBV.Velocity = Vector3.zero flyBV.Parent = root
				flyBG = Instance.new("BodyGyro") flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5) flyBG.P = 9000 flyBG.Parent = root
				flyConn = RunService.Heartbeat:Connect(function()
					local r = getRoot() if not r or not flyBV or not flyBV.Parent then return end
					local cam = workspace.CurrentCamera local d = Vector3.zero
					if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + cam.CFrame.LookVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - cam.CFrame.LookVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - cam.CFrame.RightVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + cam.CFrame.RightVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.yAxis end
					if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then d = d - Vector3.yAxis end
					flyBV.Velocity = d.Magnitude > 0 and d.Unit * flySpeed or Vector3.zero
					flyBG.CFrame = cam.CFrame
				end)
			else if h then h.PlatformStand = false end end
		end
	})
	MovSection:AddSlider("FlySpeed", { Text="Fly Speed", Default=60, Min=10, Max=350, Rounding=0, Callback=function(v) flySpeed=v end })

	-- Anti Cuff / Stun (clears NoMovement attr – MovementConsts.NO_MOVEMENT_ATTR_NAME)
	local antiCuffConn
	MovSection:AddToggle("AntiCuff", {
		Text = "Anti Cuff / Stun", Default = false,
		Callback = function(on)
			if antiCuffConn then antiCuffConn:Disconnect() antiCuffConn = nil end
			if on then
				antiCuffConn = RunService.Heartbeat:Connect(function()
					local c = getChar() if c then c:SetAttribute("NoMovement", nil) end
				end)
			end
		end
	})

	-- No Arrest (hook u5.vj4tstz2 to noop)
	local origStun
	Tabs.Player:AddLeftGroupbox("Arrest"):AddToggle("NoArrest", {
		Text = "No Arrest", Default = false,
		Callback = function(on)
			if on then
				local u5 = findUpvalue(function(v) return type(v)=="table" and type(v.vj4tstz2)=="function" end)
				if u5 then origStun = u5.vj4tstz2 u5.vj4tstz2 = newcclosure(function() end)
				else warn("[Carbon] u5 not found") end
			else
				if origStun then
					local u5 = findUpvalue(function(v) return type(v)=="table" and type(v.vj4tstz2)=="function" end)
					if u5 then u5.vj4tstz2 = origStun end origStun = nil
				end
			end
		end
	})

	-- ══════════════════════════════════════════════════════════════════
	-- VEHICLE TAB
	-- ══════════════════════════════════════════════════════════════════
	local VehSection = Tabs.Vehicle:AddLeftGroupbox("Vehicle")

	-- Infinite Nitro (u56 upvalue)
	local nitroConn
	VehSection:AddToggle("InfiniteNitro", {
		Text = "Infinite Nitro", Default = false,
		Callback = function(on)
			if nitroConn then nitroConn:Disconnect() nitroConn = nil end
			if on then
				local u56 = findUpvalue(function(v) return type(v)=="table" and type(v.Nitro)=="number" and v.NitroLastMax~=nil end)
				if u56 then u56.NitroLastMax = 250 nitroConn = RunService.Heartbeat:Connect(function() u56.Nitro = 250 end)
				else warn("[Carbon] u56 not found") end
			end
		end
	})

	-- No Tire Pop
	local tireConn
	VehSection:AddToggle("NoTirePop", {
		Text = "No Tire Pop", Default = false,
		Callback = function(on)
			if tireConn then tireConn:Disconnect() tireConn = nil end
			if on then
				tireConn = RunService.Heartbeat:Connect(function()
					local model = VehicleUtils.GetLocalVehicleModel() if not model then return end
					local max = model:GetAttribute("MaxVehicleTireHealth")
					if max then model:SetAttribute("VehicleTiresLastPop",0) model:SetAttribute("VehicleTireHealth",max) end
				end)
			end
		end
	})

	-- Speed Boost (direct vehicle velocity multiplier via AssemblyLinearVelocity)
	local vehBoostConn local vehBoostMult = 2
	VehSection:AddToggle("VehicleBoost", {
		Text = "Vehicle Speed Boost", Default = false,
		Callback = function(on)
			if vehBoostConn then vehBoostConn:Disconnect() vehBoostConn = nil end
			if on then
				vehBoostConn = RunService.Heartbeat:Connect(function()
					local model = VehicleUtils.GetLocalVehicleModel() if not model then return end
					local engine = model:FindFirstChild("Engine")
					if engine and engine:IsA("BasePart") then
						local vel = engine.AssemblyLinearVelocity
						if vel.Magnitude > 5 then
							engine.AssemblyLinearVelocity = vel.Unit * math.min(vel.Magnitude * vehBoostMult, 300)
						end
					end
				end)
			end
		end
	})
	VehSection:AddSlider("VehBoostMult", { Text="Boost Mult", Default=2, Min=1, Max=5, Rounding=1, Callback=function(v) vehBoostMult=v end })

	-- ══════════════════════════════════════════════════════════════════
	-- COMBAT TAB
	-- ══════════════════════════════════════════════════════════════════

	-- Disable Turrets (Turret2 tag, TurretTargetPtr ObjectValue)
	local turretConns = {} local turretAddedConn
	local function watchTurret(t)
		local ptr = t:FindFirstChild("TurretTargetPtr")
		if not ptr or turretConns[t] then return end
		ptr.Value = nil
		turretConns[t] = ptr:GetPropertyChangedSignal("Value"):Connect(function() if ptr.Value ~= nil then ptr.Value = nil end end)
	end
	Tabs.Combat:AddLeftGroupbox("Guards"):AddToggle("DisableTurrets", {
		Text = "Disable Turrets", Default = false,
		Callback = function(on)
			if on then
				for _, t in ipairs(CollectionService:GetTagged("Turret2")) do watchTurret(t) end
				turretAddedConn = CollectionService:GetInstanceAddedSignal("Turret2"):Connect(watchTurret)
			else
				if turretAddedConn then turretAddedConn:Disconnect() turretAddedConn = nil end
				for t,c in pairs(turretConns) do c:Disconnect() turretConns[t]=nil end
			end
		end
	})

	-- Auto Arrest (Police only – fires arrest remote when criminal is close)
	-- Arrest fires u8 FireServer with the arrest event key; we look for it via ItemSystem remotes
	-- The per-player Handcuffs remote is in Players.<name>.Folder.Handcuffs.Shoot
	local autoArrestConn
	local ARREST_RANGE = 8
	Tabs.Combat:AddLeftGroupbox("Auto Arrest"):AddToggle("AutoArrest", {
		Text = "Auto Arrest", Default = false,
		Tooltip = "Police only. Fires Handcuffs Shoot remote when a criminal is in range.",
		Callback = function(on)
			if autoArrestConn then autoArrestConn:Disconnect() autoArrestConn = nil end
			if on then
				autoArrestConn = RunService.Heartbeat:Connect(function()
					local myRoot = getRoot() if not myRoot then return end
					-- Only run if we're Police
					local teamVal = lp:FindFirstChild("TeamValue")
					if not teamVal or teamVal.Value ~= "Police" then return end

					local handcuffsRemote = lp:FindFirstChild("Folder") and
						lp.Folder:FindFirstChild("Handcuffs") and
						lp.Folder.Handcuffs:FindFirstChild("Shoot")
					if not handcuffsRemote then return end

					for _, p in ipairs(Players:GetPlayers()) do
						if p == lp then continue end
						local pTeam = p:FindFirstChild("TeamValue")
						if not pTeam then continue end
						-- Target criminals and prisoners (not police)
						if pTeam.Value == "Police" then continue end
						local pChar = p.Character
						local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
						local pHum = pChar and pChar:FindFirstChildOfClass("Humanoid")
						if not pRoot or not pHum or pHum.Health <= 0 then continue end
						if (myRoot.Position - pRoot.Position).Magnitude <= ARREST_RANGE then
							handcuffsRemote:FireServer(pRoot, pRoot.Position, 0)
							break -- one per frame
						end
					end
				end)
			end
		end
	})
	Tabs.Combat:AddLeftGroupbox("Auto Arrest"):AddSlider("ArrestRange", {
		Text="Arrest Range", Default=8, Min=4, Max=20, Rounding=0,
		Callback=function(v) ARREST_RANGE=v end
	})

	-- ══════════════════════════════════════════════════════════════════
	-- VISUALS TAB
	-- ══════════════════════════════════════════════════════════════════
	local ESPSection = Tabs.Visuals:AddLeftGroupbox("Player ESP")

	ESPSection:AddToggle("ESPName",     { Text="Name",        Default=false, Callback=function(v) setESPFlag("name",v)     end })
	ESPSection:AddToggle("ESPTeam",     { Text="Team",        Default=false, Callback=function(v) setESPFlag("team",v)     end })
	ESPSection:AddToggle("ESPHealth",   { Text="Health",      Default=false, Callback=function(v) setESPFlag("health",v)   end })
	ESPSection:AddToggle("ESPDistance", { Text="Distance",    Default=false, Callback=function(v) setESPFlag("distance",v) end })

	-- Chams: colour criminals/police by setting character part colours client-side
	local chamsConn local chamsEnabled = false
	local CRIM_COLOR  = Color3.fromRGB(255, 80,  80)
	local POLICE_COLOR= Color3.fromRGB(80,  140, 255)
	local origColors  = {} -- [part] = original color

	local function applyCham(char, col)
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				if not origColors[p] then origColors[p] = p.Color end
				p.Color = col
			end
		end
	end
	local function clearChams()
		for part, col in pairs(origColors) do
			if part and part.Parent then part.Color = col end
		end
		origColors = {}
	end

	local VisMiscSection = Tabs.Visuals:AddRightGroupbox("World")
	VisMiscSection:AddToggle("Chams", {
		Text = "Chams (Team Colors)", Default = false,
		Callback = function(on)
			chamsEnabled = on
			if chamsConn then chamsConn:Disconnect() chamsConn = nil end
			if on then
				chamsConn = RunService.Heartbeat:Connect(function()
					for _, p in ipairs(Players:GetPlayers()) do
						if p == lp then continue end
						local char = p.Character if not char then continue end
						local tv = p:FindFirstChild("TeamValue")
						if not tv then continue end
						local col = tv.Value == "Police" and POLICE_COLOR or CRIM_COLOR
						applyCham(char, col)
					end
				end)
			else
				clearChams()
			end
		end
	})

	-- Full-bright
	local origAmbient, origOutdoor, origBrightness
	VisMiscSection:AddToggle("Fullbright", {
		Text = "Fullbright", Default = false,
		Callback = function(on)
			local L = game:GetService("Lighting")
			if on then
				origAmbient    = L.Ambient
				origOutdoor    = L.OutdoorAmbient
				origBrightness = L.Brightness
				L.Ambient         = Color3.new(1,1,1)
				L.OutdoorAmbient  = Color3.new(1,1,1)
				L.Brightness      = 2
			else
				if origAmbient then
					L.Ambient = origAmbient L.OutdoorAmbient = origOutdoor L.Brightness = origBrightness
				end
			end
		end
	})

	-- Robbery Radar
	local RadarSection = Tabs.Visuals:AddLeftGroupbox("Robbery Status")
	RadarSection:AddToggle("RobberyRadar", {
		Text = "Robbery Status", Default = false,
		Callback = function(on)
			if on then buildRadar() else destroyRadar() end
		end
	})
end
