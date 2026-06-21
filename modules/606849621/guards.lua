local CollectionService = game:GetService("CollectionService")

return function(Tabs)
	local GuardSection = Tabs.Main:AddLeftGroupbox('Guards')

	local turretConnections = {}
	local turretAddedConnection

	local function watchTurret(turret)
		local target = turret:FindFirstChild("TurretTargetPtr")
		if not target or turretConnections[turret] then return end
		target.Value = nil
		turretConnections[turret] = target:GetPropertyChangedSignal("Value"):Connect(function()
			if target.Value ~= nil then target.Value = nil end
		end)
	end

	local function stopTurretBypass()
		if turretAddedConnection then
			turretAddedConnection:Disconnect()
			turretAddedConnection = nil
		end
		for turret, conn in pairs(turretConnections) do
			conn:Disconnect()
			turretConnections[turret] = nil
		end
	end

	GuardSection:AddToggle('DisableTurrets', {
		Text = 'Disable Turrets',
		Default = false,
		Callback = function(enabled)
			if enabled then
				for _, turret in ipairs(CollectionService:GetTagged("Turret2")) do
					watchTurret(turret)
				end
				if turretAddedConnection then turretAddedConnection:Disconnect() end
				turretAddedConnection = CollectionService:GetInstanceAddedSignal("Turret2"):Connect(watchTurret)
			else
				stopTurretBypass()
			end
		end
	})
end
