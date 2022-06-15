-- main object

local mbc = {}

-- register mod

mbc.mod = RegisterMod("More Biblical Characters", 1)

-- require json for save data

local json = require("json")

-- define import function to use include (require without caching) when possible to let luamod command work properly

local function import(moduleName)
	local wasSuccess, moduleScript = pcall(include, moduleName)
	
	if not wasSuccess then
		moduleScript = require(moduleName)
	end
	
	return moduleScript
end

-- define replaceSpacesWithUnderscores function to help with item module loading

local function replaceSpacesWithUnderscores(str)
	return str:gsub(" ", "_")
end

-- define roundTo function to help with rounding

local function roundTo(value, increment)
	return math.floor(value / increment + 0.5) * increment
end

-- define saveData reset function

local function resetSaveData()
	local oldData = mbc.saveData or {}
	
	if mbc.mod:HasData() and not mbc.saveData then
		oldData = json.decode(mbc.mod:LoadData())
	end
	
	mbc.saveData = {
		shouldGetHandOfCards = oldData.shouldGetHandOfCards or false,
		shouldGetExpBar = oldData.shouldGetExpBar or false,
		birthrightStage = oldData.birthrightStage or 4,
		birthrightChance = oldData.birthrightChance or 0
	}
end

-- add support for custom callbacks

mbc.onPlayerSpawnCallbacks = {}

-- load character scripts

mbc.characters = {
	names = {
		"MBC_Job",
		"MBC_Job_B",
		"MBC_John",
		"MBC_John_B",
		"MBC_David",
		"MBC_David_B",
		"MBC_Peter",
		"MBC_Peter_B",
		"MBC_Adam",
		"MBC_Adam_B",
		"MBC_Golem",
		"MBC_Golem_B"
	},
	
	modules = {}
}

for _, name in pairs(mbc.characters.names) do
	local characterModule = import("mod.characters." .. name)
	mbc.characters.modules[characterModule.playerType] = characterModule
	characterModule.mbc = mbc
end

-- load active item scripts

mbc.actives = {
	names = {
		"Book of Job",
		"Book of Sacrifice"
	},
	
	modules = {}
}

for _, name in pairs(mbc.actives.names) do
	local itemModule = import("mod.actives." .. replaceSpacesWithUnderscores(name))
	mbc.actives.modules[itemModule.id] = itemModule
	itemModule:addCallbacks(mbc.mod)
end

-- load passive item scripts

mbc.passives = {
	names = {
		"Sheathed Sword",
		"Hand of Cards",
		"EXP Bar",
		"Rechargeable Mantle",
		"Makeshift Mantle"
	},
	
	modules = {}
}

for _, name in pairs(mbc.passives.names) do
	local itemModule = import("mod.passives." .. replaceSpacesWithUnderscores(name))
	mbc.passives.modules[itemModule.id] = itemModule
	itemModule:addCallbacks(mbc)
end

-- load commands script

mbc.commands = import("mod.commands.commands")
mbc.commands.mbc = mbc
mbc.mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, mbc.commands.onExecuteCmd)

-- add cache callback for stats

function mbc:onEvaluateCache(player, cacheFlag)
	local playerType = player:GetPlayerType()
	
	if mbc.characters.modules[playerType] then
		mbc.characters.modules[playerType]:onEvaluateCache(player, cacheFlag)
	end
end

mbc.mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mbc.onEvaluateCache)

-- add player init, game start, and game exit callback for starting inventory and save data

mbc.shouldGiveStartingInventory = false
mbc.numPlayers = 0

function mbc:onPlayerSpawn(player)
	local playerType = player:GetPlayerType()
	
	player:GetData().mbc = {
		index = mbc.numPlayers
	}
	
	mbc.numPlayers = mbc.numPlayers + 1
	
	if mbc.characters.modules[playerType] then
		mbc.characters.modules[playerType]:onPlayerSpawn(player)
	end
	
	if mbc.saveData.shouldGetHandOfCards then
		mbc:addPassiveToMainTwinAndEsau(player, Isaac.GetItemIdByName("Hand of Cards"))
	end
	
	if mbc.saveData.shouldGetExpBar then
		mbc:addPassiveToMainTwinAndEsau(player, Isaac.GetItemIdByName("EXP Bar"))
	end
	
	for _, callback in ipairs(mbc.onPlayerSpawnCallbacks) do
		callback:onPlayerSpawn(player)
	end
	
	if player:GetPlayerType() == PlayerType.PLAYER_JACOB then
		mbc:onPlayerSpawn(player:GetOtherTwin())
	elseif player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN_B then
		player:GetOtherTwin():GetData().mbc = {
			index = player:GetData().mbc.index
		}
	end
end

function mbc:onPostPlayerInit(player)
	-- player 1 is initialized before run officially starts, so trying to do certain things (e.g., spawning pickups, which giving items can do) can crash the game
	-- onPostGameStarted will give player 1 starting inventory and set shouldGiveStartingInventory so that player 2 (etc.) can get starting inventory when they spawn
	-- shouldGiveStartingInventory will be false before leaving the starting room only if the user saves and continues before leaving the starting room
	-- this may mess with player 2 (etc.), if they can even spawn, but who would do that?
	if mbc.shouldGiveStartingInventory then
		mbc:onPlayerSpawn(player)
	end
end

function mbc:onPostGameStarted(didContinue)
	if not didContinue then
		-- new run, so give starting inventory to player 1, who has already spawned
		mbc.numPlayers = 0
		mbc.shouldGiveStartingInventory = true
		mbc:onPlayerSpawn(Isaac.GetPlayer())
	else
		-- old run, load data
		resetSaveData()
		
		if mbc.mod:HasData() then
			mbc.saveData = json.decode(mbc.mod:LoadData())
			
			for playerIndex = 0, Game():GetNumPlayers() - 1 do
				Isaac.GetPlayer(playerIndex):GetData().mbc = mbc.saveData["" .. playerIndex]
			end
		end
	end
end

function mbc:onPreGameExit()
	resetSaveData()
	
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		mbc.saveData["" .. playerIndex] = Isaac.GetPlayer(playerIndex):GetData().mbc
	end
	
	mbc.mod:SaveData(json.encode(mbc.saveData))
	
	-- exiting to menu, so suspect that run can continue
	mbc.shouldGiveStartingInventory = false
end

mbc.mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mbc.onPostPlayerInit)
mbc.mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mbc.onPostGameStarted)
mbc.mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mbc.onPreGameExit)

-- add other stat functions

function mbc:addSize(player, size)
	local roundedSize = roundTo(size, 1)
	
	if roundedSize > 0 then
		for i = 1, roundedSize do
			player:UsePill(PillEffect.PILLEFFECT_LARGER, PillColor.PILL_NULL, UseFlag.USE_NOANIM | UseFlag.USE_NOCOSTUME | UseFlag.USE_NOANNOUNCER)
		end
	else
		for i = 1, -roundedSize do
			player:UsePill(PillEffect.PILLEFFECT_SMALLER, PillColor.PILL_NULL, UseFlag.USE_NOANIM | UseFlag.USE_NOCOSTUME | UseFlag.USE_NOANNOUNCER)
		end
	end
end

-- add other inventory functions

function mbc:addPassive(player, passive)
	player:AddCollectible(passive)
end

function mbc:addPassiveToMainTwinAndEsau(player, passive)
	if player:GetMainTwin():GetPlayerType() == player:GetPlayerType() then
		player:AddCollectible(passive)
		
		if player:GetPlayerType() == PlayerType.PLAYER_JACOB then
			player:GetOtherTwin():AddCollectible(passive)
		end
	end
end

function mbc:addFamiliar(player, familiar)
	player:AddCollectible(familiar.collectible)
	player:CheckFamiliar(familiar.variant, 1, player:GetCollectibleRNG(familiar.collectible))
end

function mbc:addActive(player, active)
	player:AddCollectible(active)
	player:FullCharge()
end

function mbc:addPocketActive(player, pocketActive)
	player:SetPocketActiveItem(pocketActive, ActiveSlot.SLOT_POCKET, false)
end

function mbc:addTrinket(player, trinket)
	player:AddTrinket(trinket)
end

function mbc:addPill(player, pill)
	local pools = Game():GetItemPool()
	local pillColor = pools:ForceAddPillEffect(pill)
	
	pools:IdentifyPill(pillColor)
	player:SetPill(0, pillColor)
end

function mbc:addCard(player, card)
	player:SetCard(0, card)
end

function mbc:getFloor()
	local level = Game():GetLevel():GetAbsoluteStage()
	
	if Game():GetLevel():GetAbsoluteStage() < 1 then
		level = Game():GetLevel():GetStage() + 5
	end
	
	return level
end

-- add rendering stuff

function mbc:worldToScreen(position)
	local pos = Isaac.WorldToScreen(position)
	
	if Game():GetRoom():IsMirrorWorld() then
		return Vector(Isaac.GetScreenWidth() - pos.X, pos.Y)
	end
	
	return pos
end

-- add mod config stuff

resetSaveData()

function mbc:giveBirthright()
	local currentLevel = mbc:getFloor()
	local shouldGiveBirthright = false
	
	if currentLevel == LevelStage.STAGE8 then
		shouldGiveBirthright = mbc.saveData.birthrightStage == 4
	elseif mbc.saveData.birthrightStage <= 5 then
		shouldGiveBirthright = mbc.saveData.birthrightStage == (currentLevel + 1) / 2
	else
		shouldGiveBirthright = mbc.saveData.birthrightStage == currentLevel - 4
	end
	
	shouldGiveBirthright = shouldGiveBirthright and Random() % 20 < mbc.saveData.birthrightChance
	
	if shouldGiveBirthright then
		for playerIndex = 0, Game():GetNumPlayers() - 1 do
			mbc:addPassiveToMainTwinAndEsau(Isaac.GetPlayer(playerIndex), Isaac.GetItemIdByName("Birthright"))
		end
	end
end

if ModConfigMenu then
	local category = "More Biblical Characters"
	
	local handOfCardsSetting = {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		Default = mbc.saveData.shouldGetHandOfCards,
		
		CurrentSetting = function()
			return mbc.saveData.shouldGetHandOfCards
		end,
		
		Display = function()
			if mbc.saveData.shouldGetHandOfCards then
				return "Start run with Hand of Cards: Yes"
			end
			
			return "Start run with Hand of Cards: No"
		end,
		
		OnChange = function(value)
			mbc.saveData.shouldGetHandOfCards = value
		end
	}
	
	local expBarSetting = {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		Default = mbc.saveData.shouldGetExpBar,
		
		CurrentSetting = function()
			return mbc.saveData.shouldGetExpBar
		end,
		
		Display = function()
			if mbc.saveData.shouldGetExpBar then
				return "Start run with EXP Bar: Yes"
			end
			
			return "Start run with EXP Bar: No"
		end,
		
		OnChange = function(value)
			mbc.saveData.shouldGetExpBar = value
		end
	}
	
	local birthrightStageSetting = {
		Type = ModConfigMenu.OptionType.NUMBER,
		Default = mbc.saveData.birthrightStage,
		Minimum = 1,
		Maximum = 8,
		
		CurrentSetting = function()
			return mbc.saveData.birthrightStage
		end,
		
		Display = function()
			local settingToStage = {
				[1] = "Basement",
				[2] = "Caves",
				[3] = "Depths",
				[4] = "Womb/Corpse/Home",
				[5] = "???",
				[6] = "Sheol/Cathedral",
				[7] = "Dark Room/Chest/Shop",
				[8] = "Void/Ultra Greed"
			}
			
			return "When to get free Birthright: " .. settingToStage[mbc.saveData.birthrightStage]
		end,
		
		OnChange = function(value)
			mbc.saveData.birthrightStage = value
		end
	}
	
	local birthrightChanceSetting = {
		Type = ModConfigMenu.OptionType.NUMBER,
		Default = mbc.saveData.birthrightChance,
		Minimum = 0,
		Maximum = 20,
		
		CurrentSetting = function()
			return mbc.saveData.birthrightChance
		end,
		
		Display = function()
			return "Chance to get free Birthright: " .. mbc.saveData.birthrightChance * 5 .. "%"
		end,
		
		OnChange = function(value)
			mbc.saveData.birthrightChance = value
		end
	}
	
	ModConfigMenu.RemoveCategory(category)
	ModConfigMenu.SetCategoryInfo(category, "")
	
	ModConfigMenu.AddSetting(category, nil, handOfCardsSetting)
	ModConfigMenu.AddSetting(category, nil, expBarSetting)
	ModConfigMenu.AddSetting(category, nil, birthrightStageSetting)
	ModConfigMenu.AddSetting(category, nil, birthrightChanceSetting)
	
	mbc.mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mbc.giveBirthright)
end
