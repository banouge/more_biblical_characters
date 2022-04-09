-- main object

local character = {}

-- set up id info

character.name = "MBC_David_B"
character.isTainted = true
character.playerType = Isaac.GetPlayerTypeByName(character.name, character.isTainted)
character.hair = Isaac.GetCostumeIdByPath("gfx/characters/MBC_character_03b_david_hair.anm2")

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
character.trinket = TrinketType.TRINKET_SIGIL_OF_BAPHOMET

character.passives = {
	Isaac.GetItemIdByName("Euthanasia")
}

character.familiars = {
	{
		collectible = Isaac.GetItemIdByName("Forever alone"),
		variant = FamiliarVariant.FOREVER_ALONE
	}
}

-- add cache callback for stats

function character:onEvaluateCache(player, cacheFlag)
	if cacheFlag & CacheFlag.CACHE_SPEED == CacheFlag.CACHE_SPEED then
		player.MoveSpeed = player.MoveSpeed + character.stats.speed
	end
	
	if cacheFlag & CacheFlag.CACHE_FIREDELAY == CacheFlag.CACHE_FIREDELAY then
		player.MaxFireDelay = player.MaxFireDelay / character.stats.tearsMult
	end
	
	if cacheFlag & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
		player.Damage = player.Damage * character.stats.damageMult
	end
	
	if cacheFlag & CacheFlag.CACHE_RANGE == CacheFlag.CACHE_RANGE then
		player.TearRange = player.TearRange + character.stats.range * 40
	end
	
	if cacheFlag & CacheFlag.CACHE_SHOTSPEED == CacheFlag.CACHE_SHOTSPEED then
		player.ShotSpeed = player.ShotSpeed + character.stats.shotSpeed
	end
	
	if cacheFlag & CacheFlag.CACHE_LUCK == CacheFlag.CACHE_LUCK then
		player.Luck = player.Luck + character.stats.luck
	end
	
	if cacheFlag & CacheFlag.CACHE_FLYING == CacheFlag.CACHE_FLYING and player:HasCurseMistEffect() then
		player.CanFly = true
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
	character.mbc:addSize(player, character.stats.size)
	
	for _, familiar in pairs(character.familiars) do
		character.mbc:addFamiliar(player, familiar)
	end
	
	character.mbc.mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, character.onPostPlayerUpdate, 0)
	character.mbc.mod:AddCallback(ModCallbacks.MC_USE_ITEM, character.onUseItem)
	character.mbc.mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, character.onEntityTakeDmg)
	character.mbc.mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, character.onPostNewRoom)
end

-- add special callbacks

character.activeAlt = Isaac.GetItemIdByName("Broken Glass Cannon")
character.birthright = Isaac.GetItemIdByName("Birthright")

function character:doesNotHaveOriginalActive(player)
	return player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) ~= character.active and player:GetActiveItem(ActiveSlot.SLOT_SECONDARY) ~= character.active
end

function character:getOriginalActiveAltSlot(player)
	if player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) == character.activeAlt then
		return ActiveSlot.SLOT_PRIMARY
	end
	
	if player:GetActiveItem(ActiveSlot.SLOT_SECONDARY) == character.activeAlt then
		return ActiveSlot.SLOT_SECONDARY
	end
	
	return nil
end

function character:isDamageFromGlassCannonPenalty(damage, flags, source)
	return damage == 2.0 and flags == DamageFlag.DAMAGE_NOKILL | DamageFlag.DAMAGE_ISSAC_HEART | DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_NO_MODIFIERS and source.Type == EntityType.ENTITY_PLAYER
end

function character:onPostPlayerUpdate(player)
	-- make sure player is David B and is missing original active
	if player:GetPlayerType() == character.playerType and character:doesNotHaveOriginalActive(player) then
		local pedestals = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, character.active)
		
		player:FlushQueueItem()
		
		if #pedestals > 0 then
			-- dropped original active, move original to primary, move primary to pocket, move pocket to pedestal
			local oldPocketActive = player:GetActiveItem(ActiveSlot.SLOT_POCKET)
			local oldPrimaryActive = player:GetActiveItem(ActiveSlot.SLOT_PRIMARY)
			
			character.mbc:addActive(player, character.active)
			character.mbc:addPocketActive(player, oldPrimaryActive)
			player:DischargeActiveItem(ActiveSlot.SLOT_POCKET)
			
			if oldPocketActive == 0 then
				pedestals[1]:Remove()
			else
				local sprite = pedestals[1]:GetSprite()
				
				pedestals[1].SubType = oldPocketActive
				
				sprite:ReplaceSpritesheet(1, Isaac.GetItemConfig():GetCollectible(oldPocketActive).GfxFileName)
				sprite:LoadGraphics()
			end
		else
			-- original active is somehow lost (maybe rerolled, maybe changed to alt form)
			local originalActiveAltSlot = character:getOriginalActiveAltSlot(player)
			
			if originalActiveAltSlot then
				-- original active (Glass Cannon) changed to alt form (Broken Glass Cannon), so charge it to change it back
				player:FullCharge(originalActiveAltSlot)
			else
				-- original active is somehow lost (maybe rerolled), so replace new one with original
				character.mbc:addActive(player, character.active)
			end
		end
	end
end

function character:onUseItem(collectible, rng, player, useFlags, activeSlot)
	-- drain charge from launchable actives like glass cannon or black hole as soon as you hold them up, the game discharges the wrong active if one of these is launched from the pocket
	if player:GetPlayerType() == character.playerType and activeSlot == ActiveSlot.SLOT_POCKET then
		player:DischargeActiveItem(ActiveSlot.SLOT_POCKET)
	end
end

function character:onEntityTakeDmg(victim, damage, flags, source, cooldown)
	local player = victim:ToPlayer()
	
	if player and player:GetPlayerType() == character.playerType and player:HasCollectible(character.birthright) and character:isDamageFromGlassCannonPenalty(damage, flags, source) then
		player:SetMinDamageCooldown(60)
		
		return false
	end
end

function character:onPostNewRoom()
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(playerIndex)
		
		if player:GetPlayerType() == character.playerType and player:HasCurseMistEffect() then
			player:UseCard(Card.CARD_HANGED_MAN, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
		end
	end
end

-- add description if eid mod is running

if EID then
	character.eid = "Nullifies extra damage taken from breaking glass cannon"
	
	EID:addBirthright(character.playerType, character.eid, "Tainted " .. (character.name:sub(5):gsub("_B", "")))
end

-- return object

return character
