-- main object

local character = {}

-- set up id info

character.name = "MBC_Peter"
character.isTainted = false
character.playerType = Isaac.GetPlayerTypeByName(character.name, character.isTainted)
character.hair = Isaac.GetCostumeIdByPath("gfx/characters/MBC_character_04_peter_hair.anm2")

-- define stats

character.stats = {
}

-- define starting inventory

character.trinket = TrinketType.TRINKET_CRYSTAL_KEY

character.passives = {
	Isaac.GetItemIdByName("Sheathed Sword"),
	Isaac.GetItemIdByName("Rock Bottom")
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
	
	character.mbc:addTrinket(player, character.trinket)
end

-- add description if eid mod is running

if EID then
	character.eid = "Ammo can go negative#Effectively double ammo#Damage continues to increase when ammo drops below 0"
	
	EID:addBirthright(character.playerType, character.eid, character.name:sub(5))
end

-- return object

return character
