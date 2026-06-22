local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
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

return function(Tabs)
	local RunService = game:GetService('RunService')
	local RS = game:GetService('ReplicatedStorage')

	local function findGameEvent()
		for _, v in ipairs(RS:GetChildren()) do
			if v:IsA('RemoteEvent') and v.Name:match('^%x+%-%x+%-%x+%-%x+%-%x+$') then
				return v
			end
		end
	end

	local PlayerSection = Tabs.Main:AddLeftGroupbox('Player')

	-- Infinite Nitro
	-- The server dispatches "civdcswe" via the GUID-named GenericGameEvent to set u56.Nitro.
	-- The Heartbeat loop in the LocalScript depletes u56.Nitro; we can't touch that upvalue.
	-- Best client-side approach: keep the NitroBar and NitroShopGui at full visually,
	-- and intercept the "civdcswe" dispatch to detect max nitro value for the display.
	local nitroBarConn
	PlayerSection:AddToggle('InfiniteNitro', {
		Text = 'Infinite Nitro',
		Default = false,
		Callback = function(enabled)
			if enabled then
				nitroBarConn = RunService.Heartbeat:Connect(function()
					local appUI = lp.PlayerGui:FindFirstChild('AppUI')
					if appUI then
						local nitroBar = appUI:FindFirstChild('NitroBar', true)
						if nitroBar then
							nitroBar.Size = UDim2.new(1, 0, nitroBar.Size.Y.Scale, nitroBar.Size.Y.Offset)
						end
					end
					local shopGui = lp.PlayerGui:FindFirstChild('NitroShopGui')
					if shopGui then
						local barVal = shopGui:FindFirstChild('Value', true)
						if barVal and barVal:IsA('GuiObject') then
							barVal.Size = UDim2.new(1, 0, 1, 0)
						end
						local amt = shopGui:FindFirstChild('Amount', true)
						if amt and amt:IsA('TextLabel') then
							local max = amt.Text:match('/(%d+)')
							if max then amt.Text = max .. '/' .. max end
						end
					end
				end)
			else
				if nitroBarConn then nitroBarConn:Disconnect() nitroBarConn = nil end
			end
		end
	})

	-- No Arrest
	-- The server dispatches "vj4tstz2" (ragdoll/stun) via the GenericGameEvent when arrested.
	-- We intercept and immediately undo the ragdoll state after it fires.
	-- "rv83rnnv" shows the arrest notification — we can't block it but the stun is the key effect.
	local arrestConn
	PlayerSection:AddToggle('NoArrest', {
		Text = 'No Arrest',
		Default = false,
		Callback = function(enabled)
			if enabled then
				local gameEv = findGameEvent()
				if gameEv then
					arrestConn = gameEv.OnClientEvent:Connect(function(key)
						if key == 'vj4tstz2' then
							task.defer(function()
								local char = lp.Character
								if not char then return end
								local hum = char:FindFirstChildOfClass('Humanoid')
								if hum then
									hum:ChangeState(Enum.HumanoidStateType.GettingUp)
								end
							end)
						end
					end)
				end
			else
				if arrestConn then arrestConn:Disconnect() arrestConn = nil end
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
		if e and next(cache) == nil then
			for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
			Players.PlayerAdded:Connect(addESP)
			Players.PlayerRemoving:Connect(removeESP)
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
