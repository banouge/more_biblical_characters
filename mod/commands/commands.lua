-- main object

local commands = {}

-- define tables

commands.vanillaCharacters = {
	"Isaac",
	"Magdalene",
	"Cain",
	"Judas",
	"???",
	"Eve",
	"Samson",
	"Azazel",
	"Lazarus",
	"Eden",
	"The Lost",
	"Lilith",
	"Keeper",
	"Apollyon",
	"The Forgotten",
	"Bethany",
	"Jacob"
}

commands.mapMarkIdToName = {
	"Womb",
	"Cathedral",
	"Sheol",
	"Boss Rush",
	"Chest",
	"Dark Room",
	"Key",
	"Greed",
	"Hush",
	"Delirium",
	"Knife",
	"Ascent"
}

commands.mapMarkNameToId = {
	["Womb"] = 1,
	["Cathedral"] = 2,
	["Sheol"] = 3,
	["Boss Rush"] = 4,
	["Chest"] = 5,
	["Dark Room"] = 6,
	["Key"] = 7,
	["Greed"] = 8,
	["Hush"] = 9,
	["Delirium"] = 10,
	["Knife"] = 11,
	["Ascent"] = 12
}

commands.arguments = {
	difficulty = {
		normal = 1,
		hard = 2,
		both = 3
	},
	
	characters = {
		vanilla = 1,
		modded = 2,
		both = 3
	}
}

commands.isDavid = {
	[Isaac.GetPlayerTypeByName("MBC_David", false)] = true,
	[Isaac.GetPlayerTypeByName("MBC_David_B", true)] = true
}

-- define name converters

function commands:getPureName(name)
	return name:gsub("Jacob", "Jacob & Esau")
end

function commands:getTaintedName(name)
	return "Tainted " .. name:gsub("The ", "")
end

function commands:getModdedName(name)
	local characterName = name:gsub("MBC_", "")
	
	if name:sub(-2, -1) == "_B" then
		characterName = "Tainted " .. characterName:sub(1, -3)
	end
	
	return characterName
end

function commands:getGoalName(name, isHard)
	local goalName = name
	
	if isHard then
		if name == "Greed" then
			goalName = "Greedier"
		else
			goalName = "Hard " .. name
		end
	end
	
	return goalName
end

-- define callback and helper functions

function commands:getMarks()
	local marks = {}
	
	for _, name in pairs(commands.vanillaCharacters) do
		marks[commands:getPureName(name)] = PostItForAll:GetMarksForChara(name, false)
		marks[commands:getTaintedName(name)] = PostItForAll:GetMarksForChara(name, true)
	end
	
	for _, name in pairs(commands.mbc.characters.names) do
		marks[commands:getModdedName(name)] = PostItForAll:GetMarksForChara(name, name:sub(-2, -1) == "_B")
	end
	
	return marks
end

function commands:isGoalReasonable(completeMarks, character, goal, difficulty)
	-- don't recommend if mark already obtained and don't recommend hard mode if not done on normal mode
	if completeMarks[character][commands.mapMarkNameToId[goal]] ~= difficulty - 1 then
		return false
	end
	
	-- recommend post-Womb goals only if Womb already beaten
	if goal == "Cathedral" or goal == "Sheol" or goal == "Hush" then
		return completeMarks[character][commands.mapMarkNameToId["Womb"]] >= difficulty
	end
	
	-- recommend Chest only if Cathedral already beaten
	if goal == "Chest" then
		return completeMarks[character][commands.mapMarkNameToId["Cathedral"]] >= difficulty
	end
	
	-- recommend Dark Room only if Sheol already beaten
	if goal == "Dark Room" then
		return completeMarks[character][commands.mapMarkNameToId["Sheol"]] >= difficulty
	end
	
	-- recommend Key only if Chest or Dark Room already beaten
	if goal == "Key" then
		return completeMarks[character][commands.mapMarkNameToId["Chest"]] >= difficulty or completeMarks[character][commands.mapMarkNameToId["Dark Room"]] >= difficulty
	end
	
	-- recommend Delirium only if already beat a goal that has at least a 20% chance of spawning the Void portal
	if goal == "Delirium" then
		local isReasonable = completeMarks[character][commands.mapMarkNameToId["Chest"]] >= difficulty or completeMarks[character][commands.mapMarkNameToId["Dark Room"]] >= difficulty
		isReasonable = isReasonable or completeMarks[character][commands.mapMarkNameToId["Key"]] >= difficulty or completeMarks[character][commands.mapMarkNameToId["Hush"]] >= difficulty
		
		return isReasonable
	end
	
	-- Womb, Boss Rush, Greed, Knife, and Ascent have no goals before them in a run
	return true
end

function commands:addSpecificGoalToTable(completeMarks, incompleteMarks, goal, difficulty, character)
	if commands:isGoalReasonable(completeMarks, character, goal, difficulty) then
		incompleteMarks[#incompleteMarks + 1] = character .. " " .. commands:getGoalName(goal, difficulty == commands.arguments.difficulty.hard)
	end
end

function commands:addCharacterGoalsToTable(completeMarks, incompleteMarks, difficulty, character)
	if difficulty & commands.arguments.difficulty.normal == commands.arguments.difficulty.normal then
		for _, name in pairs(commands.mapMarkIdToName) do
			commands:addSpecificGoalToTable(completeMarks, incompleteMarks, name, commands.arguments.difficulty.normal, character)
		end
	end
	
	if difficulty & commands.arguments.difficulty.hard == commands.arguments.difficulty.hard then
		for _, name in pairs(commands.mapMarkIdToName) do
			commands:addSpecificGoalToTable(completeMarks, incompleteMarks, name, commands.arguments.difficulty.hard, character)
		end
	end
end

function commands:addGoalsToTable(completeMarks, incompleteMarks, difficulty, characters)
	if characters & commands.arguments.characters.vanilla == commands.arguments.characters.vanilla then
		for _, name in pairs(commands.vanillaCharacters) do
			commands:addCharacterGoalsToTable(completeMarks, incompleteMarks, difficulty, commands:getPureName(name))
			commands:addCharacterGoalsToTable(completeMarks, incompleteMarks, difficulty, commands:getTaintedName(name))
		end
	end
	
	if characters & commands.arguments.characters.modded == commands.arguments.characters.modded then
		for _, name in pairs(commands.mbc.characters.names) do
			commands:addCharacterGoalsToTable(completeMarks, incompleteMarks, difficulty, commands:getModdedName(name))
		end
	end
end

function commands:onExecuteCmd(cmd, args)
	if cmd:lower() == "mbc_r" then
		if PostItForAll then
			local completeMarks = commands:getMarks()
			local incompleteMarks = {}
			local difficulty = commands.arguments.difficulty.both
			local characters = commands.arguments.characters.both
			
			if args:lower():find("n") then
				difficulty = commands.arguments.difficulty.normal
			elseif args:lower():find("h") then
				difficulty = commands.arguments.difficulty.hard
			end
			
			if args:lower():find("v") then
				characters = commands.arguments.characters.vanilla
			elseif args:lower():find("m") then
				characters = commands.arguments.characters.modded
			end
			
			commands:addGoalsToTable(completeMarks, incompleteMarks, difficulty, characters)
			
			if #incompleteMarks > 0 then
				print(incompleteMarks[Random() % #incompleteMarks + 1])
			end
		end
	elseif cmd:lower() == "mbc_p" then
		for playerIndex = 0, Game():GetNumPlayers() - 1 do
			local player = Isaac.GetPlayer(playerIndex)
			
			if not commands.isDavid[player:GetPlayerType()] and player:GetActiveItem(ActiveSlot.SLOT_POCKET) == 0 then
				local active = player:GetActiveItem(ActiveSlot.SLOT_PRIMARY)
				
				player:RemoveCollectible(active, true, ActiveSlot.SLOT_PRIMARY)
				player:SetPocketActiveItem(active, ActiveSlot.SLOT_POCKET, false)
			end
		end
	end
end

-- return object

return commands
