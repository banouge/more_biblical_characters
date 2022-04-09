-- main object

local character = {}

-- set up id info

character.name = "MBC_Job"
character.isTainted = false
character.playerType = Isaac.GetPlayerTypeByName(character.name, character.isTainted)
character.hair = Isaac.GetCostumeIdByPath("gfx/characters/MBC_character_01_job_hair.anm2")

-- define stats

character.stats = {
	speed = -0.15,
	tearsMult = 1.5,
	damage = -1.0,
	luck = -1.0
}

-- define starting inventory

character.pocketActive = Isaac.GetItemIdByName("Book of Job")
character.trinket = TrinketType.TRINKET_TEARDROP_CHARM

-- add cache callback for stats

function character:onEvaluateCache(player, cacheFlag)
	if cacheFlag & CacheFlag.CACHE_SPEED == CacheFlag.CACHE_SPEED then
		player.MoveSpeed = player.MoveSpeed + character.stats.speed
	end
	
	if cacheFlag & CacheFlag.CACHE_FIREDELAY == CacheFlag.CACHE_FIREDELAY then
		player.MaxFireDelay = player.MaxFireDelay / character.stats.tearsMult
	end
	
	if cacheFlag & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
		player.Damage = player.Damage + character.stats.damage
	end
	
	if cacheFlag & CacheFlag.CACHE_LUCK == CacheFlag.CACHE_LUCK then
		player.Luck = player.Luck + character.stats.luck
	end
end

-- add player spawn callback for starting inventory

function character:onPlayerSpawn(player)
	player:ClearCostumes()
	player:AddNullCostume(character.hair)
	
	character.mbc:addPocketActive(player, character.pocketActive)
	character.mbc:addTrinket(player, character.trinket)
end

-- add description if eid mod is running

if EID then
	character.eid = "Hearts that are not red or rotten can be picked up with Book of Job#Blended hearts count as half a red heart and half a soul heart"
	
	EID:addBirthright(character.playerType, character.eid, character.name:sub(5))
end

-- return object

return character
