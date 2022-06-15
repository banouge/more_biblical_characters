-- main object

local character = {}

-- set up id info

character.name = "MBC_John"
character.isTainted = false
character.playerType = Isaac.GetPlayerTypeByName(character.name, character.isTainted)
character.hair = Isaac.GetCostumeIdByPath("gfx/characters/MBC_character_02_john_hair.anm2")

-- define stats

character.stats = {
	tearsMult = 0.75
}

-- define starting inventory

character.active = Isaac.GetItemIdByName("Free Lemonade")
character.trinket = TrinketType.TRINKET_LOST_CORK
character.pill = PillEffect.PILLEFFECT_LEMON_PARTY

character.passives = {
	Isaac.GetItemIdByName("Aquarius"),
	Isaac.GetItemIdByName("Holy Water")
}

-- add cache callback for stats

function character:onEvaluateCache(player, cacheFlag)
	if cacheFlag & CacheFlag.CACHE_FIREDELAY == CacheFlag.CACHE_FIREDELAY then
		player.MaxFireDelay = player.MaxFireDelay / character.stats.tearsMult
	end
end

-- add player spawn callback for starting inventory

function character:onPlayerSpawn(player)
	for _, passive in pairs(character.passives) do
		character.mbc:addPassive(player, passive)
	end
	
	player:ClearCostumes()
	player:AddNullCostume(character.hair)
	
	character.mbc:addActive(player, character.active)
	character.mbc:addTrinket(player, character.trinket)
	character.mbc:addPill(player, character.pill)
	
	character.mbc.mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, character.onPostFireTear)
	character.mbc.mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, character.onPostTearUpdate)
end

-- add special callbacks

character.birthright = Isaac.GetItemIdByName("Birthright")

function character:doesPlayerHaveThisBirthright(player)
	return player:GetPlayerType() == character.playerType and player:HasCollectible(character.birthright)
end

function character:getShooter(tear)
	local shooter = tear.SpawnerEntity
	
	if shooter then
		shooter = shooter:ToPlayer()
	end
	
	return shooter
end

function character:onPostFireTear(tear)
	local player = character:getShooter(tear)
	
	if character:doesPlayerHaveThisBirthright(player) then
		tear:GetData().mbcBirthrightJohn = player
	end
end

function character:onPostTearUpdate(tear)
	if tear:GetData().mbcBirthrightJohn and Game():GetFrameCount() % 2 == 0 and tear:GetData().mbcLastJohnBirthrightFrame ~= Game():GetFrameCount() then
		local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL, 0, tear.Position, Vector(0, 0), player):ToEffect()
		
		creep:SetTimeout(60)
		
		tear:GetData().mbcLastJohnBirthrightFrame = Game():GetFrameCount()
	end
end

-- add description if eid mod is running

if EID then
	character.eid = "Tears leave a trail of creep"
	
	EID:addBirthright(character.playerType, character.eid, character.name:sub(5))
end

-- return object

return character
