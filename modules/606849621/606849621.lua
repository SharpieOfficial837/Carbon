local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer

local fontId = "rbxassetid://12187365364"
local fontSize = 13
local maxDist = 1000

local storage = Instance.new("Folder")
storage.Name = lp.Name
if syn and syn.protect_gui then
	syn.protect_gui(storage)
	storage.Parent = CoreGui
elseif getgui then
	storage.Parent = getgui()
else
	storage.Parent = CoreGui
end

local cache = {}
local showName, showTeam, showHealth = false, false, false

local function hpColor(hum)
	local pct = hum.Health / hum.MaxHealth
	if pct >= 0.75 then return Color3.fromRGB(0, 255, 0)
	elseif pct >= 0.35 then return Color3.fromRGB(255, 255, 0)
	else return Color3.fromRGB(255, 0, 0) end
end

local function makeLabel(parent, order)
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(0, 0, 1, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.X
	lbl.TextSize = fontSize
	lbl.TextStrokeTransparency = 0
	lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
	lbl.FontFace = Font.new(fontId, Enum.FontWeight.Bold)
	lbl.LayoutOrder = order
	lbl.Parent = parent
	return lbl
end

local function removeESP(player)
	if not cache[player] then return end
	cache[player].gui:Destroy()
	if cache[player].conn then cache[player].conn:Disconnect() end
	cache[player] = nil
end

local function updateVisibility(player)
	local e = cache[player]
	if not e then return end
	local any = showName or showTeam or showHealth
	e.gui.Enabled = any
	e.gui.MaxDistance = maxDist
	e.nameLabel.Visible = showName
	e.teamLabel.Visible = showTeam
	e.hpLabel.Visible = showHealth
end

local function applyESP(player, char)
	local head = char:WaitForChild("Head", 5)
	local hum = char:WaitForChild("Humanoid", 5)
	if not head or not hum then return end

	local bb = Instance.new("BillboardGui")
	bb.Adornee = head
	bb.Size = UDim2.new(0, 200, 0, 22)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = maxDist
	bb.ResetOnSpawn = false
	bb.Enabled = false
	bb.Parent = storage

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 100, 1, 0)
	frame.Position = UDim2.new(0.5, 0, 0, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.AutomaticSize = Enum.AutomaticSize.X
	frame.Parent = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = frame

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 3)
	list.Parent = frame

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = frame

	local nameLabel = makeLabel(frame, 1)
	nameLabel.Text = player.Name
	nameLabel.TextColor3 = Color3.fromRGB(235, 235, 235)

	local teamLabel = makeLabel(frame, 2)
	local team = player.Team
	teamLabel.Text = team and team.Name or "No Team"
	teamLabel.TextColor3 = team and team.TeamColor.Color or Color3.fromRGB(200, 200, 200)

	local hpLabel = makeLabel(frame, 3)
	hpLabel.Text = math.round(hum.Health) .. "hp"
	hpLabel.TextColor3 = hpColor(hum)

	local conn = hum:GetPropertyChangedSignal("Health"):Connect(function()
		hpLabel.TextColor3 = hpColor(hum)
		hpLabel.Text = math.round(hum.Health) .. "hp"
	end)

	cache[player] = { gui = bb, conn = conn, nameLabel = nameLabel, teamLabel = teamLabel, hpLabel = hpLabel }
	updateVisibility(player)
end

local function addESP(player)
	if player == lp then return end
	removeESP(player)
	if player.Character then task.spawn(applyESP, player, player.Character) end
	player.CharacterAdded:Connect(function(char) task.spawn(applyESP, player, char) end)
	player.CharacterRemoving:Connect(function() removeESP(player) end)
end

local function refreshAll()
	for player in pairs(cache) do updateVisibility(player) end
end

-- Scan all Heartbeat connections for a table matching a predicate
local function findUpvalue(predicate)
	for _, c in ipairs(getconnections(RunService.Heartbeat)) do
		local ok, fn = pcall(function() return c.Function end)
		if ok and fn then
			local ok2, uvs = pcall(debug.getupvalues, fn)
			if ok2 then
				for _, v in pairs(uvs) do
					if predicate(v) then return v end
				end
			end
		end
	end
end

return function(Tabs)
	local PlayerSection = Tabs.Main:AddLeftGroupbox('Player')

	-- ── Infinite Nitro ────────────────────────────────────────────────
	-- u56 is the nitro state table {Nitro, NitroLastMax, ...}
	-- The LocalScript Heartbeat drains u56.Nitro when boosting.
	-- We get a reference to u56 and overwrite Nitro each frame.
	local nitroConn
	PlayerSection:AddToggle('InfiniteNitro', {
		Text = 'Infinite Nitro',
		Default = false,
		Callback = function(enabled)
			if enabled then
				local u56 = findUpvalue(function(v)
					return type(v) == "table" and type(v.Nitro) == "number" and v.NitroLastMax ~= nil
				end)
				if u56 then
					u56.NitroLastMax = 250
					nitroConn = RunService.Heartbeat:Connect(function()
						u56.Nitro = 250
					end)
				else
					warn("[Carbon] u56 not found")
				end
			else
				if nitroConn then nitroConn:Disconnect() nitroConn = nil end
			end
		end
	})

	-- ── No Arrest ─────────────────────────────────────────────────────
	-- u5.vj4tstz2 is the stun/ragdoll function fired on arrest.
	-- We hookfunction it to a no-op while the toggle is on.
	local origStun
	PlayerSection:AddToggle('NoArrest', {
		Text = 'No Arrest',
		Default = false,
		Callback = function(enabled)
			if enabled then
				local u5 = findUpvalue(function(v)
					return type(v) == "table" and type(v.vj4tstz2) == "function"
				end)
				if u5 then
					origStun = u5.vj4tstz2
					u5.vj4tstz2 = newcclosure(function() end)
				else
					warn("[Carbon] u5 not found")
				end
			else
				if origStun then
					local u5 = findUpvalue(function(v)
						return type(v) == "table" and type(v.vj4tstz2) == "function"
					end)
					if u5 then u5.vj4tstz2 = origStun end
					origStun = nil
				end
			end
		end
	})

	local GuardSection = Tabs.Main:AddLeftGroupbox('Guards')
	local turretConns = {}
	local turretAddedConn

	local function watchTurret(turret)
		local target = turret:FindFirstChild("TurretTargetPtr")
		if not target or turretConns[turret] then return end
		target.Value = nil
		turretConns[turret] = target:GetPropertyChangedSignal("Value"):Connect(function()
			if target.Value ~= nil then target.Value = nil end
		end)
	end

	local function stopTurrets()
		if turretAddedConn then turretAddedConn:Disconnect() turretAddedConn = nil end
		for t, c in pairs(turretConns) do c:Disconnect() turretConns[t] = nil end
	end

	GuardSection:AddToggle('DisableTurrets', {
		Text = 'Disable Turrets',
		Default = false,
		Callback = function(enabled)
			if enabled then
				for _, t in ipairs(CollectionService:GetTagged("Turret2")) do watchTurret(t) end
				if turretAddedConn then turretAddedConn:Disconnect() end
				turretAddedConn = CollectionService:GetInstanceAddedSignal("Turret2"):Connect(watchTurret)
			else
				stopTurrets()
			end
		end
	})

	local VisualsSection = Tabs.Visuals:AddLeftGroupbox('Visual Features')

	VisualsSection:AddToggle('ESPName', { Text = 'Name', Default = false, Callback = function(e)
		showName = e
		if e then
			maxDist = math.huge
			if next(cache) == nil then
				for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
				Players.PlayerAdded:Connect(addESP)
				Players.PlayerRemoving:Connect(removeESP)
			end
		else
			-- only reset distance if no other ESP toggle is on
			if not showTeam and not showHealth then maxDist = 1000 end
		end
		refreshAll()
	end})

	VisualsSection:AddToggle('ESPTeam', { Text = 'Team', Default = false, Callback = function(e)
		showTeam = e
		if e and next(cache) == nil then
			for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
			Players.PlayerAdded:Connect(addESP)
			Players.PlayerRemoving:Connect(removeESP)
		end
		refreshAll()
	end})

	VisualsSection:AddToggle('ESPHealth', { Text = 'Health', Default = false, Callback = function(e)
		showHealth = e
		if e and next(cache) == nil then
			for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
			Players.PlayerAdded:Connect(addESP)
			Players.PlayerRemoving:Connect(removeESP)
		end
		refreshAll()
	end})
end
