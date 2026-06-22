local base = "https://raw.githubusercontent.com/SharpieOfficial837/Carbon/main/"
local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
	Title = "Vanta",
	Center = true,
	AutoShow = true,
	TabPadding = 8,
	MenuFadeTime = 0.2
})

local Tabs = {
	Main = Window:AddTab("Main"),
	Visuals = Window:AddTab("Visuals"),
	Settings = Window:AddTab("UI Settings"),
}

local src = game:HttpGet(base .. "modules/606849621/606849621.lua")
local fn = src and loadstring(src)
if fn then
	local ok, err = pcall(function() fn()(Tabs) end)
	if not ok then warn("[Carbon] 606849621.lua error: " .. tostring(err)) end
else
	warn("[Carbon] 606849621.lua failed to fetch or compile")
end

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() Library:Unload() end)
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "End", NoUI = true, Text = "Menu keybind" })

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("Vanta")
SaveManager:SetFolder("Vanta/jailbreak")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library.ToggleKeybind = getgenv().Options and getgenv().Options.MenuKeybind
