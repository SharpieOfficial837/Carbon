local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local ok, err

local Library
ok, err = pcall(function() Library = loadstring(game:HttpGet(repo .. 'Library.lua'))() end)
if not ok then warn("[new.lua] Library failed: " .. tostring(err)) return end

local ThemeManager
ok, err = pcall(function() ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))() end)
if not ok then warn("[new.lua] ThemeManager failed: " .. tostring(err)) return end

local SaveManager
ok, err = pcall(function() SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))() end)
if not ok then warn("[new.lua] SaveManager failed: " .. tostring(err)) return end

local Window
ok, err = pcall(function()
	Window = Library:CreateWindow({
		Title = 'Vanta',
		Center = true,
		AutoShow = true,
		TabPadding = 8,
		MenuFadeTime = 0.2
	})
end)
if not ok then warn("[new.lua] CreateWindow failed: " .. tostring(err)) return end

local Tabs = {
	Main = Window:AddTab('Main'),
	Settings = Window:AddTab('UI Settings'),
}

local MenuGroup = Tabs.Settings:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })

ok, err = pcall(function()
	ThemeManager:SetLibrary(Library)
	SaveManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
	ThemeManager:SetFolder('Vanta')
	SaveManager:SetFolder('Vanta/jailbreak')
	SaveManager:BuildConfigSection(Tabs.Settings)
	ThemeManager:ApplyToTab(Tabs.Settings)
	SaveManager:LoadAutoloadConfig()
end)
if not ok then warn("[new.lua] SaveManager/ThemeManager setup failed: " .. tostring(err)) return end

Library.ToggleKeybind = getgenv().Options and getgenv().Options.MenuKeybind

return {
	Library = Library,
	Tabs = Tabs,
}
