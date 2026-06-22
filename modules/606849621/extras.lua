-- extras.lua – accurate Jailbreak module (606849621)
-- Teleport: HumanoidRootPart.CFrame set directly (confirmed working)
-- Coords from GameLocations module (ground truth)
-- Robbery states: 1=OPENED 2=STARTED 3=CLOSED, shown for all 17 robberies

local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- ── Helpers ───────────────────────────────────────────────────────────────
local function getChar() return lp.Character end
local function getHum()
	local c = getChar() return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
	local c = getChar() return c and c:FindFirstChild("HumanoidRootPart")
end

-- ── Real GameLocations coords (from GameLocations module in RS) ───────────
local LOCS = {
	["Bank"]           = Vector3.new(40,    16,   786),
	["Jewelry Store"]  = Vector3.new(136,   17,   1353),
	["Museum"]         = Vector3.new(1075,  136,  1228),
	["Power Plant"]    = Vector3.new(547,   35,   2672),
	["Train"]          = Vector3.new(1701,  19,   317),
	["Cargo Ship"]     = Vector3.new(-292,  20,   2084),
	["Airport"]        = Vector3.new(-1592, 40,   2859),
	["Tomb"]           = Vector3.new(580,   30,   -462),
	["Casino"]         = Vector3.new(989,   21,   -3821),
	["Mansion"]        = Vector3.new(1261,  65,   -4826),
	["Oil Rig"]        = Vector3.new(-1259, 19,   -4282),
	["Donut Store"]    = Vector3.new(80,    19,   -1592),
	["Crim Base"]      = Vector3.new(-235,  17,   1623),
	["Police HQ"]      = Vector3.new(1250,  62,   1550),
	["Prison"]         = Vector3.new(-1218, 38,   -1575),
	["Race Track"]     = Vector3.new(-572,  125,  2462),
	["Garage"]         = Vector3.new(-348,  19,   1145),
	["Gun Shop"]       = Vector3.new(-20,   15,   -1756),
	["1M House"]       = Vector3.new(351,   20,   -1700),
}

-- Robbery ID → teleport location key (from GameLocations / LOCS)
local ROBBERY_TP = {
	[1]  = "Bank",
	[2]  = "Jewelry Store",
	[3]  = "Museum",
	[4]  = "Power Plant",
	[5]  = "Train",
	[6]  = "Train",
	[7]  = "Cargo Ship",
	[8]  = "Airport",
	[9]  = "Donut Store",   -- gas station near same block
	[10] = "Donut Store",
	[11] = "Donut Store",   -- grocery near same block
	[12] = "Bank",          -- money truck patrols near bank
	[13] = "1M House",
	[14] = "Tomb",
	[15] = "Casino",
	[16] = "Mansion",
	[17] = "Oil Rig",
}

-- Robbery display names (matches RobberyConsts.PRETTY_NAME)
local ROBBERY_NAMES = {
	[1]="Bank",[2]="Jewelry Store",[3]="Museum",[4]="Power Plant",
	[5]="Passenger Train",[6]="Cargo Train",[7]="Cargo Ship",[8]="Cargo Plane",
	[9]="Gas Station",[10]="Donut Store",[11]="Grocery Store",[12]="Money Truck",
	[13]="Home Vault",[14]="Tomb",[15]="Crown Jewel",[16]="Mansion",[17]="Oil Rig",
}

local STATE_COLOR = {
	[1] = Color3.fromRGB(60,  220, 80),   -- OPENED  (green)
	[2] = Color3.fromRGB(240, 200, 0),    -- STARTED (yellow)
	[3] = Color3.fromRGB(140, 140, 140),  -- CLOSED  (grey)
}
local STATE_LABEL = { [1]="OPEN", [2]="ACTIVE", [3]="CLOSED" }

-- ── Robbery Radar ──────────────────────────────────────────────────────────
local function makeRobberyRadar()
	local CoreGui = game:GetService("CoreGui")
	local sg = Instance.new("ScreenGui")
	sg.Name = "CarbonRobberyRadar"
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	if syn and syn.protect_gui then syn.protect_gui(sg) elseif getgui then sg.Parent = getgui() end
	sg.Parent = CoreGui

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	frame.BackgroundTransparency = 0.12
	frame.BorderSizePixel = 0
	frame.Position = UDim2.new(1, -215, 0.5, -200)
	frame.Size = UDim2.new(0, 205, 0, 10)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.Parent = sg

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
	local pad = Instance.new("UIPadding", frame)
	pad.PaddingTop  = UDim.new(0, 5) pad.PaddingBottom = UDim.new(0, 5)
	pad.PaddingLeft = UDim.new(0, 7) pad.PaddingRight  = UDim.new(0, 7)

	local list = Instance.new("UIListLayout", frame)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 2)

	local header = Instance.new("TextLabel", frame)
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 15)
	header.Text = "── ROBBERY STATUS ──"
	header.TextColor3 = Color3.fromRGB(200, 200, 200)
	header.TextSize = 11
	header.Font = Enum.Font.GothamBold
	header.LayoutOrder = 0

	-- one label per robbery
	local labels = {}
	for id = 1, 17 do
		local lbl = Instance.new("TextLabel", frame)
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1, 0, 0, 14)
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Font = Enum.Font.Gotham
		lbl.TextStrokeTransparency = 0.6
		lbl.LayoutOrder = id
		labels[id] = lbl
	end

	-- refresh function
	local stateFolder = RS:FindFirstChild("RobberyState", true)
	local function refresh()
		if not stateFolder then stateFolder = RS:FindFirstChild("RobberyState", true) end
		if not stateFolder then return end
		for id = 1, 17 do
			local val = stateFolder:FindFirstChild(tostring(id))
			local state = val and val.Value or 3
			local lbl = labels[id]
			if lbl and lbl.Parent then
				lbl.Text = string.format("[%d] %-18s %s", id, ROBBERY_NAMES[id], STATE_LABEL[state] or "?")
				lbl.TextColor3 = STATE_COLOR[state] or Color3.new(1,1,1)
			end
		end
	end

	refresh()
	local t = 0
	local conn = RunService.Heartbeat:Connect(function(dt)
		t = t + dt
		if t >= 1.5 then t = 0 refresh() end
	end)

	return sg, conn
end

-- ── Module entry ──────────────────────────────────────────────────────────
return function(Tabs)

	-- ── Robbery Radar ──────────────────────────────────────────────────
	local radarGui, radarConn
	local VisSection = Tabs.Visuals:AddLeftGroupbox("Robbery Radar")
	VisSection:AddToggle("RobberyRadar", {
		Text = "Robbery Radar (all 17)",
		Default = false,
		Callback = function(on)
			if on then
				radarGui, radarConn = makeRobberyRadar()
			else
				if radarConn then radarConn:Disconnect() radarConn = nil end
				if radarGui then radarGui:Destroy() radarGui = nil end
			end
		end
	})

	-- ── Teleport ───────────────────────────────────────────────────────
	local TpSection = Tabs.Main:AddLeftGroupbox("Teleport")

	local locNames = {}
	for k in pairs(LOCS) do table.insert(locNames, k) end
	table.sort(locNames)

	local selectedLoc = locNames[1]
	TpSection:AddDropdown("TpDrop", {
		Text = "Location",
		Values = locNames,
		Default = locNames[1],
		Callback = function(v) selectedLoc = v end
	})
	TpSection:AddButton("Teleport There", function()
		local root = getRoot()
		if not root then return end
		local pos = LOCS[selectedLoc]
		if pos then
			root.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
		end
	end)

	-- Teleport to open/active robbery by ID
	TpSection:AddButton("Go To Open Robbery", function()
		local stateFolder = RS:FindFirstChild("RobberyState", true)
		if not stateFolder then warn("[Carbon] RobberyState not found") return end
		-- prefer STARTED (2) then OPENED (1)
		local bestId, bestState = nil, 4
		for _, v in ipairs(stateFolder:GetChildren()) do
			local s = v.Value
			local id = tonumber(v.Name)
			if (s == 2 or s == 1) and s < bestState then
				bestId = id bestState = s
			end
		end
		if not bestId then warn("[Carbon] No open robberies") return end
		local locName = ROBBERY_TP[bestId]
		local pos = locName and LOCS[locName]
		if pos then
			local root = getRoot()
			if root then root.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)) end
			print("[Carbon] Teleported to " .. ROBBERY_NAMES[bestId] .. " @ " .. tostring(pos))
		else
			warn("[Carbon] No position for robbery " .. tostring(bestId))
		end
	end)

	-- ── Movement ───────────────────────────────────────────────────────
	local MoveSection = Tabs.Main:AddLeftGroupbox("Movement")

	local speedConn
	local speedVal = 28
	MoveSection:AddToggle("SpeedHack", {
		Text = "Speed Hack",
		Default = false,
		Callback = function(on)
			if speedConn then speedConn:Disconnect() speedConn = nil end
			if on then
				speedConn = RunService.Heartbeat:Connect(function()
					local h = getHum()
					if h and h.WalkSpeed > 0 then h.WalkSpeed = speedVal end
				end)
			else
				local h = getHum() if h then h.WalkSpeed = 16 end
			end
		end
	})
	MoveSection:AddSlider("SpeedVal", {
		Text = "Walk Speed", Default = 28, Min = 16, Max = 250, Rounding = 0,
		Callback = function(v) speedVal = v end
	})

	local jumpConn
	local jumpVal = 80
	MoveSection:AddToggle("JumpHack", {
		Text = "High Jump",
		Default = false,
		Callback = function(on)
			if jumpConn then jumpConn:Disconnect() jumpConn = nil end
			if on then
				jumpConn = RunService.Heartbeat:Connect(function()
					local h = getHum() if h then h.JumpPower = jumpVal end
				end)
			else
				local h = getHum() if h then h.JumpPower = 50 end
			end
		end
	})
	MoveSection:AddSlider("JumpVal", {
		Text = "Jump Power", Default = 80, Min = 50, Max = 400, Rounding = 0,
		Callback = function(v) jumpVal = v end
	})

	-- Noclip – uses MovementConsts.NO_MOVEMENT_ATTR_NAME knowledge;
	-- client-side CanCollide = false each Stepped frame
	local noclipConn
	MoveSection:AddToggle("Noclip", {
		Text = "Noclip",
		Default = false,
		Callback = function(on)
			if noclipConn then noclipConn:Disconnect() noclipConn = nil end
			if on then
				noclipConn = RunService.Stepped:Connect(function()
					local c = getChar() if not c then return end
					for _, p in ipairs(c:GetDescendants()) do
						if p:IsA("BasePart") then p.CanCollide = false end
					end
				end)
			else
				-- restore – just let Roblox re-enable naturally on respawn
				local c = getChar()
				if c then
					for _, p in ipairs(c:GetDescendants()) do
						if p:IsA("BasePart") then p.CanCollide = true end
					end
				end
			end
		end
	})

	-- Fly – uses BodyVelocity + BodyGyro, WASD + Space/Ctrl
	local flyConn, flyBV, flyBG
	local flySpeed = 60
	MoveSection:AddToggle("Fly", {
		Text = "Fly",
		Default = false,
		Callback = function(on)
			if flyConn then flyConn:Disconnect() flyConn = nil end
			if flyBV then flyBV:Destroy() flyBV = nil end
			if flyBG then flyBG:Destroy() flyBG = nil end
			local h = getHum()
			if on then
				local root = getRoot() if not root then return end
				if h then h.PlatformStand = true end
				flyBV = Instance.new("BodyVelocity")
				flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
				flyBV.Velocity = Vector3.zero
				flyBV.Parent = root
				flyBG = Instance.new("BodyGyro")
				flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
				flyBG.P = 9000
				flyBG.Parent = root
				flyConn = RunService.Heartbeat:Connect(function()
					local r = getRoot() if not r or not flyBV or not flyBV.Parent then return end
					local cam = workspace.CurrentCamera
					local d = Vector3.zero
					if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + cam.CFrame.LookVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - cam.CFrame.LookVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - cam.CFrame.RightVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + cam.CFrame.RightVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.yAxis end
					if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then d = d - Vector3.yAxis end
					flyBV.Velocity = d.Magnitude > 0 and d.Unit * flySpeed or Vector3.zero
					flyBG.CFrame = cam.CFrame
				end)
			else
				if h then h.PlatformStand = false end
			end
		end
	})
	MoveSection:AddSlider("FlySpeed", {
		Text = "Fly Speed", Default = 60, Min = 10, Max = 350, Rounding = 0,
		Callback = function(v) flySpeed = v end
	})

	-- Anti-Drown: clears DrownPercent attr on player (from DrownConsts.DROWN_PERCENT_ATTR_NAME)
	local drownConn
	MoveSection:AddToggle("AntiDrown", {
		Text = "Anti Drown",
		Default = false,
		Callback = function(on)
			if drownConn then drownConn:Disconnect() drownConn = nil end
			if on then
				drownConn = RunService.Heartbeat:Connect(function()
					lp:SetAttribute("DrownPercent", 0)
				end)
			end
		end
	})

	-- ── Misc ───────────────────────────────────────────────────────────
	local MiscSection = Tabs.Main:AddRightGroupbox("Misc")

	-- Anti NoMovement: clears NoMovement attr on character (handcuffs / stun lock)
	local noMoveConn
	MiscSection:AddToggle("AntiCuff", {
		Text = "Anti Cuff / Stun",
		Default = false,
		Tooltip = "Clears NoMovement attr every frame (DoorConsts & MovementConsts confirmed)",
		Callback = function(on)
			if noMoveConn then noMoveConn:Disconnect() noMoveConn = nil end
			if on then
				noMoveConn = RunService.Heartbeat:Connect(function()
					local c = getChar()
					if c then
						c:SetAttribute("NoMovement", nil)
						c:SetAttribute("NoMovement", false)
					end
				end)
			end
		end
	})

	-- Force Open Doors (Door2 system, TAG_NAME=Door2, OPEN_ATTR_NAME=DoorOpen)
	MiscSection:AddToggle("ForceOpenDoors", {
		Text = "Force Open Doors",
		Default = false,
		Callback = function(on)
			for _, door in ipairs(CollectionService:GetTagged("Door2")) do
				door:SetAttribute("DoorOpen", on)
			end
			CollectionService:GetInstanceAddedSignal("Door2"):Connect(function(door)
				if getgenv()._forceDoorsOn then
					door:SetAttribute("DoorOpen", true)
				end
			end)
			getgenv()._forceDoorsOn = on
		end
	})

	-- Disable Turrets (Turret2 tag, TurretTargetPtr ObjectValue – confirmed)
	local turretConns = {}
	local turretAddedConn
	local function watchTurret(t)
		local ptr = t:FindFirstChild("TurretTargetPtr")
		if not ptr or turretConns[t] then return end
		ptr.Value = nil
		turretConns[t] = ptr:GetPropertyChangedSignal("Value"):Connect(function()
			if ptr.Value ~= nil then ptr.Value = nil end
		end)
	end
	MiscSection:AddToggle("DisableTurrets", {
		Text = "Disable Turrets",
		Default = false,
		Callback = function(on)
			if on then
				for _, t in ipairs(CollectionService:GetTagged("Turret2")) do watchTurret(t) end
				turretAddedConn = CollectionService:GetInstanceAddedSignal("Turret2"):Connect(watchTurret)
			else
				if turretAddedConn then turretAddedConn:Disconnect() turretAddedConn = nil end
				for t, c in pairs(turretConns) do c:Disconnect() turretConns[t] = nil end
			end
		end
	})

	-- ── Vehicle ────────────────────────────────────────────────────────
	local VehSection = Tabs.Main:AddRightGroupbox("Vehicle")

	local VehicleUtils = require(RS:FindFirstChild("VehicleUtils", true))

	-- No Tire Pop (confirmed: VehicleUtils.setTireHealth + setTireMaxHealth)
	local tireConn
	VehSection:AddToggle("NoTirePop", {
		Text = "No Tire Pop",
		Default = false,
		Callback = function(on)
			if tireConn then tireConn:Disconnect() tireConn = nil end
			if on then
				tireConn = RunService.Heartbeat:Connect(function()
					local model = VehicleUtils.GetLocalVehicleModel()
					if not model then return end
					local max = model:GetAttribute("MaxVehicleTireHealth")
					if max then
						model:SetAttribute("VehicleTiresLastPop", 0)
						model:SetAttribute("VehicleTireHealth", max)
					end
				end)
			end
		end
	})

	-- Infinite Nitro (u56 upvalue from LocalScript heartbeat - confirmed)
	local nitroConn
	VehSection:AddToggle("InfiniteNitro", {
		Text = "Infinite Nitro",
		Default = false,
		Callback = function(on)
			if nitroConn then nitroConn:Disconnect() nitroConn = nil end
			if on then
				local u56 = (function()
					for _, c in ipairs(getconnections(RunService.Heartbeat)) do
						local ok, fn = pcall(function() return c.Function end)
						if ok and fn then
							local ok2, uvs = pcall(debug.getupvalues, fn)
							if ok2 then
								for _, v in pairs(uvs) do
									if type(v) == "table" and type(v.Nitro) == "number" and v.NitroLastMax ~= nil then
										return v
									end
								end
							end
						end
					end
				end)()
				if u56 then
					u56.NitroLastMax = 250
					nitroConn = RunService.Heartbeat:Connect(function() u56.Nitro = 250 end)
				else warn("[Carbon] u56 nitro table not found") end
			end
		end
	})
end
