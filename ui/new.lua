local base = "https://raw.githubusercontent.com/SharpieOfficial837/Carbon/main/"
local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
	Title = "Carbon",
	Center = true,
	AutoShow = true,
	TabPadding = 8,
	MenuFadeTime = 0.2
})

local Tabs = {
	Player  = Window:AddTab("Player"),
	Vehicle = Window:AddTab("Vehicle"),
	Combat  = Window:AddTab("Combat"),
	Visuals = Window:AddTab("Visuals"),
	Settings = Window:AddTab("Settings"),
}

local src = game:HttpGet(base .. "modules/606849621/606849621.lua")
local fn = src and loadstring(src)
if fn then
	local ok, err = pcall(function() fn()(Tabs) end)
	if not ok then warn("[Carbon] error: " .. tostring(err)) end
end

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() Library:Unload() end)
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "End", NoUI = true, Text = "Menu keybind" })

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("Carbon")
SaveManager:SetFolder("Carbon/jailbreak")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library.ToggleKeybind = getgenv().Options and getgenv().Options.MenuKeybind
