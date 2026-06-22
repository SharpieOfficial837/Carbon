local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- ── Helpers ───────────────────────────────────────────────────────────────
local function getHum()
	local c = lp.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
	local c = lp.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function findUpvalue(pred)
	for _, conn in ipairs(getconnections(RunService.Heartbeat)) do
		local ok, fn = pcall(function() return conn.Function end)
		if ok and fn then
			local ok2, uvs = pcall(debug.getupvalues, fn)
			if ok2 then
				for _, v in pairs(uvs) do
					if pred(v) then return v end
				end
			end
		end
	end
end

-- Robbery state names (IntValue names 1-17 in RobberyState folder)
local ROBBERY_NAMES = {
	[1]="Bank",[2]="Jewelry",[3]="Museum",[4]="Power Plant",[5]="Passenger Train",
	[6]="Cargo Train",[7]="Cargo Ship",[8]="Cargo Plane",[9]="Gas Station",[10]="Donut Store",
	[11]="Grocery Store",[12]="Money Truck",[13]="Home Vault",[14]="Tomb",[15]="Casino",
	[16]="Mansion",[17]="Oil Rig",
}
-- State values: 1=OPEN, 2=ACTIVE, 3=CLOSED
local STATE_COLORS = { [1]=Color3.fromRGB(80,220,80), [2]=Color3.fromRGB(240,200,0), [3]=Color3.fromRGB(180,50,50) }
local STATE_LABELS = { [1]="OPEN", [2]="ACTIVE", [3]="CLOSED" }

return function(Tabs)
	-- ── Movement Section ─────────────────────────────────────────────────
	local MoveSection = Tabs.Main:AddRightGroupbox("Movement")

	-- Speed
	local speedConn
	local customSpeed = 28
	MoveSection:AddToggle("SpeedHack", {
		Text = "Speed Hack",
		Default = false,
		Tooltip = "Overrides WalkSpeed every frame",
		Callback = function(on)
			if speedConn then speedConn:Disconnect() speedConn = nil end
			if on then
				speedConn = RunService.Heartbeat:Connect(function()
					local h = getHum()
					if h and h.WalkSpeed > 0 then h.WalkSpeed = customSpeed end
				end)
			else
				local h = getHum()
				if h then h.WalkSpeed = 16 end
			end
		end
	})
	MoveSection:AddSlider("SpeedValue", {
		Text = "Speed Value",
		Default = 28, Min = 16, Max = 200, Rounding = 0,
		Callback = function(v) customSpeed = v end
	})

	-- Jump
	local jumpConn
	local customJump = 80
	MoveSection:AddToggle("JumpHack", {
		Text = "High Jump",
		Default = false,
		Callback = function(on)
			if jumpConn then jumpConn:Disconnect() jumpConn = nil end
			if on then
				jumpConn = RunService.Heartbeat:Connect(function()
					local h = getHum()
					if h then h.JumpPower = customJump end
				end)
			else
				local h = getHum()
				if h then h.JumpPower = 50 end
			end
		end
	})
	MoveSection:AddSlider("JumpValue", {
		Text = "Jump Power",
		Default = 80, Min = 50, Max = 300, Rounding = 0,
		Callback = function(v) customJump = v end
	})

	-- Noclip
	local noclipConn
	MoveSection:AddToggle("Noclip", {
		Text = "Noclip",
		Default = false,
		Callback = function(on)
			if noclipConn then noclipConn:Disconnect() noclipConn = nil end
			if on then
				noclipConn = RunService.Stepped:Connect(function()
					local c = lp.Character
					if not c then return end
					for _, p in ipairs(c:GetDescendants()) do
						if p:IsA("BasePart") then p.CanCollide = false end
					end
				end)
			else
				local c = lp.Character
				if c then
					for _, p in ipairs(c:GetDescendants()) do
						if p:IsA("BasePart") then p.CanCollide = true end
					end
				end
			end
		end
	})

	-- Fly
	local flyConn, flyBodyVel, flyBodyGyro
	local FLY_SPEED = 60
	MoveSection:AddToggle("Fly", {
		Text = "Fly",
		Default = false,
		Callback = function(on)
			if flyConn then flyConn:Disconnect() flyConn = nil end
			if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
			if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end

			if on then
				local root = getRootPart()
				if not root then return end
				local h = getHum()
				if h then h.PlatformStand = true end

				flyBodyVel = Instance.new("BodyVelocity")
				flyBodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
				flyBodyVel.Velocity = Vector3.zero
				flyBodyVel.Parent = root

				flyBodyGyro = Instance.new("BodyGyro")
				flyBodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
				flyBodyGyro.P = 9000
				flyBodyGyro.Parent = root

				flyConn = RunService.Heartbeat:Connect(function()
					local r2 = getRootPart()
					if not r2 or not flyBodyVel or not flyBodyVel.Parent then return end
					local cam = workspace.CurrentCamera
					local dir = Vector3.zero
					if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
					if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.yAxis end
					flyBodyVel.Velocity = dir.Magnitude > 0 and dir.Unit * FLY_SPEED or Vector3.zero
					flyBodyGyro.CFrame = cam.CFrame
				end)
			else
				local h = getHum()
				if h then h.PlatformStand = false end
			end
		end
	})
	MoveSection:AddSlider("FlySpeed", {
		Text = "Fly Speed", Default = 60, Min = 10, Max = 300, Rounding = 0,
		Callback = function(v) FLY_SPEED = v end
	})

	-- ── Vehicle Section ───────────────────────────────────────────────────
	local VehSection = Tabs.Main:AddRightGroupbox("Vehicle")

	-- Infinite Health (no damage to vehicle)
	local VehicleUtils = require(game:GetService("ReplicatedStorage"):FindFirstChild("VehicleUtils", true))
	local vehHealthConn
	VehSection:AddToggle("VehicleGodmode", {
		Text = "Vehicle God Mode",
		Default = false,
		Tooltip = "Keeps vehicle body parts at max health each frame",
		Callback = function(on)
			if vehHealthConn then vehHealthConn:Disconnect() vehHealthConn = nil end
			if on then
				vehHealthConn = RunService.Heartbeat:Connect(function()
					local model = VehicleUtils.GetLocalVehicleModel()
					if not model then return end
					for _, p in ipairs(model:GetDescendants()) do
						if p:IsA("BasePart") then
							p:SetAttribute("Health", p:GetAttribute("MaxHealth") or 100)
						end
					end
				end)
			end
		end
	})

	-- Invisible Vehicle (transparency 1 for hiding from cops)
	local origTransparencies = {}
	VehSection:AddToggle("VehicleInvis", {
		Text = "Vehicle Invisible",
		Default = false,
		Callback = function(on)
			local model = VehicleUtils.GetLocalVehicleModel()
			if not model then return end
			if on then
				for _, p in ipairs(model:GetDescendants()) do
					if p:IsA("BasePart") then
						origTransparencies[p] = p.Transparency
						p.Transparency = 1
					end
				end
			else
				for p, t in pairs(origTransparencies) do
					if p and p.Parent then p.Transparency = t end
				end
				origTransparencies = {}
			end
		end
	})

	-- ── Robbery Radar ──────────────────────────────────────────────────────
	local WorldSection = Tabs.Visuals:AddLeftGroupbox("Robbery Radar")

	local robberyGui = nil
	local robberyConn = nil

	local function removeRobberyGui()
		if robberyGui then robberyGui:Destroy() robberyGui = nil end
		if robberyConn then robberyConn:Disconnect() robberyConn = nil end
	end

	local function buildRobberyGui()
		removeRobberyGui()
		local CoreGui = game:GetService("CoreGui")
		local sg = Instance.new("ScreenGui")
		sg.Name = "CarbonRobbery"
		sg.ResetOnSpawn = false
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		if syn and syn.protect_gui then syn.protect_gui(sg) end
		sg.Parent = CoreGui

		local frame = Instance.new("Frame")
		frame.BackgroundColor3 = Color3.fromRGB(15,15,15)
		frame.BackgroundTransparency = 0.15
		frame.BorderSizePixel = 0
		frame.Position = UDim2.new(1, -210, 0.5, -160)
		frame.Size = UDim2.new(0, 200, 0, 20) -- auto-sized by list
		frame.AutomaticSize = Enum.AutomaticSize.Y
		frame.Parent = sg

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = frame

		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 4)
		pad.PaddingBottom = UDim.new(0, 4)
		pad.PaddingLeft = UDim.new(0, 6)
		pad.PaddingRight = UDim.new(0, 6)
		pad.Parent = frame

		local list = Instance.new("UIListLayout")
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, 2)
		list.Parent = frame

		local labels = {}

		local function refresh()
			local RS = game:GetService("ReplicatedStorage")
			local folder
			for _, v in ipairs(RS:GetChildren()) do
				if v:FindFirstChild("RobberyState") then folder = v:FindFirstChild("RobberyState") break end
			end
			if not folder then
				-- fallback: search all RS descendants
				folder = RS:FindFirstChild("RobberyState", true)
			end
			if not folder then return end

			for _, intVal in ipairs(folder:GetChildren()) do
				local id = tonumber(intVal.Name)
				if not id then continue end
				local state = intVal.Value
				local name = ROBBERY_NAMES[id] or ("Robbery "..id)
				local lbl = labels[id]
				if not lbl then
					lbl = Instance.new("TextLabel")
					lbl.BackgroundTransparency = 1
					lbl.Size = UDim2.new(1, 0, 0, 16)
					lbl.TextSize = 12
					lbl.TextXAlignment = Enum.TextXAlignment.Left
					lbl.Font = Enum.Font.GothamBold
					lbl.TextStrokeTransparency = 0.5
					lbl.LayoutOrder = id
					lbl.Parent = frame
					labels[id] = lbl
				end
				lbl.Text = name .. "  •  " .. (STATE_LABELS[state] or "?")
				lbl.TextColor3 = STATE_COLORS[state] or Color3.new(1,1,1)
				lbl.Visible = (state == 1 or state == 2) -- only show open/active
			end
		end

		refresh()

		-- update every 2 seconds
		local t = 0
		robberyConn = RunService.Heartbeat:Connect(function(dt)
			t = t + dt
			if t >= 2 then t = 0 refresh() end
		end)

		robberyGui = sg
	end

	WorldSection:AddToggle("RobberyRadar", {
		Text = "Robbery Radar",
		Default = false,
		Tooltip = "Shows open/active robberies on screen",
		Callback = function(on)
			if on then buildRobberyGui() else removeRobberyGui() end
		end
	})

	-- ── Teleport Section ──────────────────────────────────────────────────
	local TpSection = Tabs.Main:AddLeftGroupbox("Teleport")

	-- Waypoint locations (confirmed from workspace and RS scan)
	local LOCATIONS = {
		["Prison Yard"]   = Vector3.new(272, 5, -550),
		["Police HQ"]     = Vector3.new(-1440, 6, 270),
		["Bank"]          = Vector3.new(570, 17, -450),
		["Jewelry Store"] = Vector3.new(55, 6, 120),
		["Casino"]        = Vector3.new(1170, 6, -210),
		["Oil Rig"]       = Vector3.new(2350, 6, 1050),
		["Mansion"]       = Vector3.new(-400, 200, -1900),
		["Museum"]        = Vector3.new(-1100, 6, -660),
		["Power Plant"]   = Vector3.new(1800, 6, -1100),
		["Cargo Ship"]    = Vector3.new(2800, 6, -200),
		["Airport"]       = Vector3.new(1550, 50, 2200),
	}
	local locationNames = {}
	for k in pairs(LOCATIONS) do table.insert(locationNames, k) end
	table.sort(locationNames)

	local selectedLocation = locationNames[1]
	TpSection:AddDropdown("TpLocation", {
		Text = "Location",
		Values = locationNames,
		Default = locationNames[1],
		Callback = function(v) selectedLocation = v end
	})
	TpSection:AddButton("Teleport", function()
		local root = getRootPart()
		if root and selectedLocation then
			root.CFrame = CFrame.new(LOCATIONS[selectedLocation] + Vector3.new(0, 3, 0))
		end
	end)

	-- Teleport to nearest open robbery
	TpSection:AddButton("Go To Open Robbery", function()
		local RS = game:GetService("ReplicatedStorage")
		local folder = RS:FindFirstChild("RobberyState", true)
		if not folder then warn("[Carbon] RobberyState not found") return end
		-- Find first open (1) or active (2) robbery
		local target = nil
		for _, v in ipairs(folder:GetChildren()) do
			if v.Value == 1 or v.Value == 2 then
				target = tonumber(v.Name)
				break
			end
		end
		if not target then
			warn("[Carbon] No open robberies found") return
		end
		-- Search workspace for the robbery folder
		local robFolder = workspace:FindFirstChild("RobberyFolder", true)
		if robFolder then
			local root = getRootPart()
			if root then
				root.CFrame = CFrame.new(robFolder.Position + Vector3.new(0, 5, 0))
				return
			end
		end
		-- Fallback: use known coordinates from RobberyConsts names
		local name = ROBBERY_NAMES[target] or ""
		for locName, pos in pairs(LOCATIONS) do
			if locName:lower():find(name:lower():sub(1,4)) then
				local root = getRootPart()
				if root then root.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end
				return
			end
		end
		warn("[Carbon] Could not find location for: " .. name)
	end)

	-- ── Misc Section ──────────────────────────────────────────────────────
	local MiscSection = Tabs.Main:AddRightGroupbox("Misc")

	-- Infinite Stamina (prevent sprint depletion - u58 is isSprinting, sprint drain managed server-side but we can keep walkspeed up)
	-- The real gain here is preventing the NoMovement attribute from being applied (CrawlOnly, etc.)
	MiscSection:AddToggle("AntiNoMovement", {
		Text = "Anti No-Movement",
		Default = false,
		Tooltip = "Removes NoMovement attribute on character each frame (prevents cuffs/stun movement lock)",
		Callback = function(on)
			-- We'll just use a heartbeat to clear the attribute
			if on then
				RunService.Heartbeat:Connect(function()
					if not getgenv().AntiNoMovementEnabled then return end
					local c = lp.Character
					if c then c:SetAttribute("NoMovement", nil) end
				end)
				getgenv().AntiNoMovementEnabled = true
			else
				getgenv().AntiNoMovementEnabled = false
			end
		end
	})

	-- Always Sprint
	MiscSection:AddToggle("AlwaysSprint", {
		Text = "Always Sprint",
		Default = false,
		Tooltip = "Keeps sprint walkspeed even when not pressing shift",
		Callback = function(on)
			if on then
				RunService.Heartbeat:Connect(function()
					if not getgenv().AlwaysSprintEnabled then return end
					local h = getHum()
					if h and h.WalkSpeed > 0 and h.WalkSpeed < 24 then
						h.WalkSpeed = 24 -- sprint speed in Jailbreak
					end
				end)
				getgenv().AlwaysSprintEnabled = true
			else
				getgenv().AlwaysSprintEnabled = false
				local h = getHum()
				if h then h.WalkSpeed = 16 end
			end
		end
	})

	-- Kill Aura (fires damage remote for nearby enemies) — only fires when toggled
	-- Uses per-player Damage remote in Players service
	MiscSection:AddToggle("DamageTeleport", {
		Text = "Teleport to Kill",
		Default = false,
		Tooltip = "When enabled, right-click a player to teleport behind them",
		Callback = function(on)
			getgenv().DamageTpEnabled = on
		end
	})
	-- Connect right-click tp once
	if not getgenv()._damageTpConnected then
		getgenv()._damageTpConnected = true
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if not getgenv().DamageTpEnabled then return end
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				-- find the player the mouse is pointing at
				local mouse = lp:GetMouse()
				local target = mouse.Target
				if target then
					local char = target:FindFirstAncestorOfClass("Model")
					if char then
						local p = Players:GetPlayerFromCharacter(char)
						if p and p ~= lp then
							local root = getRootPart()
							local tRoot = char:FindFirstChild("HumanoidRootPart")
							if root and tRoot then
								root.CFrame = tRoot.CFrame * CFrame.new(0, 0, -3)
							end
						end
					end
				end
			end
		end)
	end
end
