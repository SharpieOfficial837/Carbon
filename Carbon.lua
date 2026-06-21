local base = "https://raw.githubusercontent.com/SharpieOfficial837/Carbon/main/Jailbreak/"

local function load(path)
	return loadstring(game:HttpGet(base .. path))()
end

local ui = load("ui/new.lua")
local Tabs = ui.Tabs

load("modules/606849621/guards.lua")(Tabs)
load("modules/606849621/visuals.lua")(Tabs)
