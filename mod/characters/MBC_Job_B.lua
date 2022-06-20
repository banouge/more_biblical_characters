-- main object

local character = {}

-- set up id info

character.name = "MBC_Job_B"
character.isTainted = true
character.playerType = Isaac.GetPlayerTypeByName(character.name, character.isTainted)
character.hair = Isaac.GetCostumeIdByPath("gfx/characters/MBC_character_01b_job_hair.anm2")

-- define stats

character.stats = {
	speed = -0.15,
	damage = -1.0,
	luck = -1.0
}

-- define starting inventory

character.pocketActive = Isaac.GetItemIdByName("Book of Sacrifice")
character.trinket = TrinketType.TRINKET_TELESCOPE_LENS

-- add cache callback for stats

function character:onEvaluateCache(player, cacheFlag)
	if cacheFlag & CacheFlag.CACHE_SPEED == CacheFlag.CACHE_SPEED then
		player.MoveSpeed = player.MoveSpeed + character.stats.speed
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
	
	character:onPlayerReload(player)
end

function character:onPlayerReload(player)
end

-- add description if eid mod is running

if EID then
	character.eid = "Book of Sacrifice will destroy low quality items before high quality items#Birthright will not be sacrificed"
	
	EID:addBirthright(character.playerType, character.eid, "Tainted " .. (character.name:sub(5):gsub("_B", "")))
end

-- return object

return character
