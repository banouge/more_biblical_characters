-- main object

local character = {}

-- set up id info

character.name = "MBC_Golem"
character.isTainted = false
character.playerType = Isaac.GetPlayerTypeByName(character.name, character.isTainted)
character.hair = Isaac.GetCostumeIdByPath("gfx/characters/MBC_character_06_golem_hair.anm2")

-- define stats

character.stats = {
}

-- define starting inventory

character.trinket = TrinketType.TRINKET_OLD_CAPACITOR
character.pill = PillEffect.PILLEFFECT_48HOUR_ENERGY

character.passives = {
	Isaac.GetItemIdByName("Rechargeable Mantle")
}

-- add cache callback for stats

function character:onEvaluateCache(player, cacheFlag)
end

-- add player spawn callback for starting inventory

function character:onPlayerSpawn(player)
	for _, passive in pairs(character.passives) do
		character.mbc:addPassive(player, passive)
	end
	
	character.mbc:addPassive(player, character.techItems[Random() % #character.techItems + 1])
	
	player:ClearCostumes()
	player:AddNullCostume(character.hair)
	
	character.mbc:addTrinket(player, character.trinket)
	character.mbc:addPill(player, character.pill)
	
	player:GetData().mbc.maxSoulHearts = 12
	
	character:onPlayerReload(player)
end

function character:onPlayerReload(player)
	character.mbc.mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, character.onPostPlayerUpdate, 0)
	character.mbc.mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, character.onPostNewLevel)
	character.mbc.mod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, character.onPreEntitySpawn)
end

-- add special callbacks

character.birthright = Isaac.GetItemIdByName("Birthright")

character.techItems = {
	Isaac.GetItemIdByName("Tech.5"),
	Isaac.GetItemIdByName("Technology"),
	Isaac.GetItemIdByName("Technology 2"),
	Isaac.GetItemIdByName("Tech X"),
	Isaac.GetItemIdByName("Technology Zero")
}

character.batteryItems = {
	Isaac.GetItemIdByName("4.5 Volt"),
	Isaac.GetItemIdByName("9 Volt"),
	Isaac.GetItemIdByName("Battery Pack"),
	Isaac.GetItemIdByName("Car Battery"),
	Isaac.GetItemIdByName("Jumper Cables"),
	Isaac.GetItemIdByName("Sharp Plug"),
	Isaac.GetItemIdByName("The Battery")
}

function character:onPostPlayerUpdate(player)
	if player:GetPlayerType() == character.playerType then
		if player:GetData().mbc and player:GetData().mbc.maxSoulHearts and player:GetSoulHearts() < player:GetData().mbc.maxSoulHearts then
			player:GetData().mbc.maxSoulHearts = math.max(player:GetSoulHearts(), 1)
		end
		
		if player:GetMaxHearts() > 0 then
			player:AddMaxHearts(-player:GetMaxHearts(), true)
		end
		
		if player:GetBoneHearts() > 0 then
			player:AddBoneHearts(-player:GetBoneHearts())
		end
		
		if player:GetEternalHearts() > 0 then
			player:AddEternalHearts(-player:GetEternalHearts())
		end
		
		if player:GetBlackHearts() > 0 then
			local numHearts = player:GetSoulHearts()
			
			player:AddSoulHearts(-numHearts)
			player:AddSoulHearts(numHearts)
		end
		
		if player:GetData().mbc and player:GetData().mbc.maxSoulHearts and player:GetSoulHearts() > player:GetData().mbc.maxSoulHearts then
			player:AddSoulHearts(player:GetData().mbc.maxSoulHearts - player:GetSoulHearts())
		end
		
		if player:GetData().mbc and not player:GetData().mbc.gotBirthrightPickupEffect and player:HasCollectible(character.birthright, true) then
			player:GetData().mbc.gotBirthrightPickupEffect = true
			character.mbc:addPassive(player, character.batteryItems[Random() % #character.batteryItems + 1])
		end
	end
end

function character:onPostNewLevel(player)
	local center = Game():GetLevel():GetCurrentRoom():GetCenterPos()
	
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(playerIndex)
		
		if player:GetPlayerType() == character.playerType and player:HasCollectible(character.birthright, true) then
			Isaac.Spawn(EntityType.ENTITY_SLOT, 13, 0, center - Vector(0, 80), Vector(0, 0), player)
		end
	end
end

function character:isGolemPlaying()
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(playerIndex)
		
		if player:GetPlayerType() == character.playerType then
			return true
		end
	end
	
	return false
end

function character:onPreEntitySpawn(entityType, variant, subType, position, velocity, spawner, seed)
	if character:isGolemPlaying() and entityType == EntityType.ENTITY_PICKUP and variant == PickupVariant.PICKUP_LIL_BATTERY and subType == BatterySubType.BATTERY_NORMAL and seed % 10 == 0 then
		return {EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LIL_BATTERY, BatterySubType.BATTERY_MEGA, seed}
	end
end

-- add description if eid mod is running

if EID then
	character.eid = "Rechargeable Mantle's capacity is greatly increased#Grants a random battery-related item#Spawns a Battery Bum at the start of each floor"
	
	EID:addBirthright(character.playerType, character.eid, character.name:sub(5))
end

-- return object

return character
