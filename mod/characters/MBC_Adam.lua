-- main object

local character = {}

-- set up id info

character.name = "MBC_Adam"
character.isTainted = false
character.playerType = Isaac.GetPlayerTypeByName(character.name, character.isTainted)
character.hair = Isaac.GetCostumeIdByPath("gfx/characters/MBC_character_05_adam_hair.anm2")

-- define stats

character.stats = {
}

-- define starting inventory

character.passives = {
	Isaac.GetItemIdByName("Hand of Cards")
}

-- add cache callback for stats

function character:onEvaluateCache(player, cacheFlag)
end

-- add player spawn callback for starting inventory

function character:onPlayerSpawn(player)
	for _, passive in pairs(character.passives) do
		character.mbc:addPassive(player, passive)
	end
	
	player:ClearCostumes()
	player:AddNullCostume(character.hair)
	
	character:onPlayerReload(player)
end

function character:onPlayerReload(player)
end

-- add description if eid mod is running

if EID then
	character.eid = "Hand of Cards will spawn items from better pools more often"
	
	EID:addBirthright(character.playerType, character.eid, character.name:sub(5))
end

-- return object

return character
