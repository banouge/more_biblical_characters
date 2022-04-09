-- main object

local character = {}

-- set up id info

character.name = "MBC_David"
character.isTainted = false
character.playerType = Isaac.GetPlayerTypeByName(character.name, character.isTainted)
character.hair = Isaac.GetCostumeIdByPath("gfx/characters/MBC_character_03_david_hair.anm2")

-- define stats

character.stats = {
	speed = 0.3,
	tearsMult = 0.5,
	damageMult = 2.0,
	range = 6.5,
	shotSpeed = 1.0,
	luck = 5,
	size = -1
}

-- define starting inventory

character.active = Isaac.GetItemIdByName("Glass Cannon")
character.trinket = TrinketType.TRINKET_WOODEN_CROSS
character.card = Card.CARD_MAGICIAN

character.passives = {
	Isaac.GetItemIdByName("Euthanasia")
}

-- add cache callback for stats

function character:getBirthrightBonus(player, stat)
	if player:GetData().mbc then
		return player:GetData().mbc.davidBirthrightBonuses[stat]
	end
	
	return 0
end

function character:onEvaluateCache(player, cacheFlag)
	if cacheFlag & CacheFlag.CACHE_SPEED == CacheFlag.CACHE_SPEED then
		player.MoveSpeed = player.MoveSpeed + character.stats.speed
	end
	
	if cacheFlag & CacheFlag.CACHE_FIREDELAY == CacheFlag.CACHE_FIREDELAY then
		player.MaxFireDelay = player.MaxFireDelay / (character.stats.tearsMult + character:getBirthrightBonus(player, "tears") / 100)
	end
	
	if cacheFlag & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
		player.Damage = player.Damage * character.stats.damageMult + character:getBirthrightBonus(player, "damage") / 10
	end
	
	if cacheFlag & CacheFlag.CACHE_RANGE == CacheFlag.CACHE_RANGE then
		player.TearRange = player.TearRange + character.stats.range * 40
	end
	
	if cacheFlag & CacheFlag.CACHE_SHOTSPEED == CacheFlag.CACHE_SHOTSPEED then
		player.ShotSpeed = player.ShotSpeed + character.stats.shotSpeed
	end
	
	if cacheFlag & CacheFlag.CACHE_LUCK == CacheFlag.CACHE_LUCK then
		player.Luck = player.Luck + character.stats.luck + character:getBirthrightBonus(player, "luck") / 10
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
	character.mbc:addCard(player, character.card)
	character.mbc:addSize(player, character.stats.size)
	
	character.mbc.mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, character.onPostNpcDeath)
	
	player:GetData().mbc.davidBirthrightBonuses = {
		damage = 0,
		tears = 0,
		luck = 0
	}
end

-- add special callbacks

character.birthright = Isaac.GetItemIdByName("Birthright")

function character:doesPlayerHaveThisBirthright(player)
	return player:GetPlayerType() == character.playerType and player:HasCollectible(character.birthright)
end

function character:onPostNpcDeath(npc)
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(playerIndex)
		
		if character:doesPlayerHaveThisBirthright(player) then
			local stats = {"damage", "luck"}
			local boost = 0
			
			if npc:IsBoss() then
				if player:GetData().mbc.davidBirthrightBonuses.tears <= 40 then
					stats[3] = "tears"
				end
				
				boost = 10
			elseif npc:IsChampion() then
				if player:GetData().mbc.davidBirthrightBonuses.tears <= 49 then
					stats[3] = "tears"
				end
				
				boost = 1
			end
			
			if boost > 0 then
				local stat = stats[Random() % #stats + 1]
				
				player:GetData().mbc.davidBirthrightBonuses[stat] = player:GetData().mbc.davidBirthrightBonuses[stat] + boost
				
				player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY | CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_LUCK)
				player:EvaluateItems()
			end
		end
	end
end

-- add description if eid mod is running

if EID then
	character.eid = "Gain a large permanent boost to tears, damage, or luck whenever a boss dies#Gain a small permanent boost to tears, damage, or luck whenever a champion dies"
	
	EID:addBirthright(character.playerType, character.eid, character.name:sub(5))
end

-- return object

return character
