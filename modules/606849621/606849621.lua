local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local lp = Players.LocalPlayer

return function(Tabs)
	-- Guards
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

	-- Visuals
	local VisualsSection = Tabs.Main:AddRightGroupbox('Visuals')
	local espObjects = {}
	local espLoop, playerAddedConn, playerRemovingConn
	local useTeamColor = false

	local function getTarget(char)
		if not char then return nil end
		return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	end

	local function getLabel(player)
		if player.DisplayName ~= "" and player.DisplayName ~= player.Name then
			return ("%s (@%s)"):format(player.DisplayName, player.Name)
		end
		return player.Name
	end

	local function getSize(dist)
		if dist <= 300 then return 22 elseif dist <= 1200 then return 20 elseif dist <= 2500 then return 18 else return 17 end
	end

	local function getColor(player)
		if useTeamColor and player.TeamColor then return player.TeamColor.Color end
		return Color3.fromRGB(255, 255, 255)
	end

	local function getEdge(sp, depth, viewport)
		local margin = 18
		local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
		local offset = Vector2.new(sp.X - center.X, sp.Y - center.Y)
		if depth <= 0 then offset = -offset end
		if offset.Magnitude < 0.001 then offset = Vector2.new(0, -1) end
		local scale = math.max(math.abs(offset.X) / math.max(1, center.X - margin), math.abs(offset.Y) / math.max(1, center.Y - margin), 1)
		local pinned = center + (offset / scale)
		return Vector2.new(math.clamp(pinned.X, margin, viewport.X - margin), math.clamp(pinned.Y, margin, viewport.Y - margin))
	end

	local function setVisible(e, s) e.main.Visible = s e.shadow.Visible = s end

	local function createEntry(player)
		if espObjects[player] then return espObjects[player] end
		local function newText(color)
			local t = Drawing.new("Text")
			t.Center = true t.Outline = false t.Color = color t.Visible = false
			return t
		end
		espObjects[player] = { main = newText(Color3.fromRGB(255,255,255)), shadow = newText(Color3.new(0,0,0)) }
		return espObjects[player]
	end

	local function removeEntry(player)
		local e = espObjects[player]
		if not e then return end
		e.main:Remove() e.shadow:Remove() espObjects[player] = nil
	end

	local function update()
		local camPos = Camera.CFrame.Position
		local viewport = Camera.ViewportSize
		for player in pairs(espObjects) do if not player.Parent then removeEntry(player) end end
		for _, player in ipairs(Players:GetPlayers()) do
			if player == lp then continue end
			local e = createEntry(player)
			local target = getTarget(player.Character)
			if not target then setVisible(e, false) continue end
			local worldPos = target.Position + Vector3.new(0, 2.7, 0)
			local sp, onScreen = Camera:WorldToViewportPoint(worldPos)
			local dist = (camPos - target.Position).Magnitude
			local text = ("%s [%dm]"):format(getLabel(player), math.floor(dist + 0.5))
			local size = getSize(dist)
			local pos = (onScreen and sp.Z > 0) and Vector2.new(sp.X, sp.Y) or getEdge(sp, sp.Z, viewport)
			e.main.Text = text e.main.Size = size e.main.Color = getColor(player) e.main.Position = pos
			e.shadow.Text = text e.shadow.Size = size e.shadow.Position = pos + Vector2.new(1, 1)
			setVisible(e, true)
		end
	end

	local function stopESP()
		if espLoop then espLoop:Disconnect() espLoop = nil end
		if playerAddedConn then playerAddedConn:Disconnect() playerAddedConn = nil end
		if playerRemovingConn then playerRemovingConn:Disconnect() playerRemovingConn = nil end
		for player in pairs(espObjects) do removeEntry(player) end
	end

	local function startESP()
		stopESP()
		for _, player in ipairs(Players:GetPlayers()) do if player ~= lp then createEntry(player) end end
		playerAddedConn = Players.PlayerAdded:Connect(function(p) if p ~= lp then createEntry(p) end end)
		playerRemovingConn = Players.PlayerRemoving:Connect(removeEntry)
		espLoop = RunService.RenderStepped:Connect(update)
	end

	VisualsSection:AddToggle('NameESP', { Text = 'Name ESP', Default = false, Callback = function(e) if e then startESP() else stopESP() end end })
	VisualsSection:AddToggle('NameESPTeamColor', { Text = 'Team Color', Default = false, Callback = function(e) useTeamColor = e end })
end
