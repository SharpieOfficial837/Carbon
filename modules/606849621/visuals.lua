local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local lp = Players.LocalPlayer

return function(Tabs)
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
		if dist <= 300 then return 22
		elseif dist <= 1200 then return 20
		elseif dist <= 2500 then return 18
		else return 17 end
	end

	local function getColor(player)
		if useTeamColor and player.TeamColor then
			return player.TeamColor.Color
		end
		return Color3.fromRGB(255, 255, 255)
	end

	local function getEdge(screenPoint, depth, viewport)
		local margin = 18
		local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
		local offset = Vector2.new(screenPoint.X - center.X, screenPoint.Y - center.Y)
		if depth <= 0 then offset = -offset end
		if offset.Magnitude < 0.001 then offset = Vector2.new(0, -1) end
		local maxX = math.max(1, center.X - margin)
		local maxY = math.max(1, center.Y - margin)
		local scale = math.max(math.abs(offset.X) / maxX, math.abs(offset.Y) / maxY, 1)
		local pinned = center + (offset / scale)
		return Vector2.new(math.clamp(pinned.X, margin, viewport.X - margin), math.clamp(pinned.Y, margin, viewport.Y - margin))
	end

	local function setVisible(entry, state)
		entry.main.Visible = state
		entry.shadow.Visible = state
	end

	local function createEntry(player)
		if espObjects[player] then return espObjects[player] end
		local shadow = Drawing.new("Text")
		shadow.Center = true
		shadow.Outline = false
		shadow.Color = Color3.new(0, 0, 0)
		shadow.Visible = false

		local main = Drawing.new("Text")
		main.Center = true
		main.Outline = false
		main.Color = Color3.fromRGB(255, 255, 255)
		main.Visible = false

		espObjects[player] = { main = main, shadow = shadow }
		return espObjects[player]
	end

	local function removeEntry(player)
		local entry = espObjects[player]
		if not entry then return end
		entry.main:Remove()
		entry.shadow:Remove()
		espObjects[player] = nil
	end

	local function update()
		local camPos = Camera.CFrame.Position
		local viewport = Camera.ViewportSize

		for player in pairs(espObjects) do
			if not player.Parent then removeEntry(player) end
		end

		for _, player in ipairs(Players:GetPlayers()) do
			if player == lp then continue end
			local entry = createEntry(player)
			local target = getTarget(player.Character)
			if not target then setVisible(entry, false) continue end

			local worldPos = target.Position + Vector3.new(0, 2.7, 0)
			local sp, onScreen = Camera:WorldToViewportPoint(worldPos)
			local dist = (camPos - target.Position).Magnitude
			local text = ("%s [%dm]"):format(getLabel(player), math.floor(dist + 0.5))
			local size = getSize(dist)
			local pos = (onScreen and sp.Z > 0) and Vector2.new(sp.X, sp.Y) or getEdge(sp, sp.Z, viewport)

			entry.main.Text = text
			entry.main.Size = size
			entry.main.Color = getColor(player)
			entry.main.Position = pos
			entry.shadow.Text = text
			entry.shadow.Size = size
			entry.shadow.Position = pos + Vector2.new(1, 1)
			setVisible(entry, true)
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
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= lp then createEntry(player) end
		end
		playerAddedConn = Players.PlayerAdded:Connect(function(p)
			if p ~= lp then createEntry(p) end
		end)
		playerRemovingConn = Players.PlayerRemoving:Connect(removeEntry)
		espLoop = RunService.RenderStepped:Connect(update)
	end

	VisualsSection:AddToggle('NameESP', {
		Text = 'Name ESP',
		Default = false,
		Callback = function(enabled)
			if enabled then startESP() else stopESP() end
		end
	})

	VisualsSection:AddToggle('NameESPTeamColor', {
		Text = 'Team Color',
		Default = false,
		Callback = function(enabled)
			useTeamColor = enabled
		end
	})
end
