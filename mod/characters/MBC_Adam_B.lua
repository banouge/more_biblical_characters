-- main object

local character = {}

-- set up id info

character.name = "MBC_Adam_B"
character.isTainted = true
character.playerType = Isaac.GetPlayerTypeByName(character.name, character.isTainted)
character.hair = Isaac.GetCostumeIdByPath("gfx/characters/MBC_character_05b_adam_hair.anm2")

-- define stats

character.stats = {
}

-- define starting inventory

character.passives = {
	Isaac.GetItemIdByName("EXP Bar")
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
end

-- add description if eid mod is running

if EID then
	character.eid = "EXP Bar will spawn two items at a time#Only one item can be taken"
	
	EID:addBirthright(character.playerType, character.eid, "Tainted " .. (character.name:sub(5):gsub("_B", "")))
end

-- return object

return character
