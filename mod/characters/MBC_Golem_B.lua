-- main object

local character = {}

-- set up id info

character.name = "MBC_Golem_B"
character.isTainted = true
character.playerType = Isaac.GetPlayerTypeByName(character.name, character.isTainted)
character.hair = Isaac.GetCostumeIdByPath("gfx/characters/MBC_character_06b_golem_hair.anm2")

-- define stats

character.stats = {
}

-- define starting inventory

character.pill = PillEffect.PILLEFFECT_BOMBS_ARE_KEYS

character.passives = {
	Isaac.GetItemIdByName("Makeshift Mantle"),
	Isaac.GetItemIdByName("Pyromaniac")
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
	
	character.mbc:addPill(player, character.pill)
	
	player:GetData().mbc.maxSoulHearts = 12
	
	character.mbc.mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, character.onPostPlayerUpdate, 0)
	character.mbc.mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, character.onPostNewLevel)
end

-- add special callbacks

character.birthright = Isaac.GetItemIdByName("Birthright")
character.dadsKey = Isaac.GetItemIdByName("Dad's Key")
character.drFetus = Isaac.GetItemIdByName("Dr. Fetus")

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
		
		if player:GetData().mbc and player:GetData().mbc.maxSoulHearts and player:GetSoulHearts() > player:GetData().mbc.maxSoulHearts then
			player:AddSoulHearts(player:GetData().mbc.maxSoulHearts - player:GetSoulHearts())
		end
		
		if (player:GetData().mbc and player:GetData().mbc.makeshiftMantleBombs and player:GetData().mbc.makeshiftMantleBombs > 1) or player:HasCollectible(character.birthright, true) then
			if not player:HasCollectible(character.drFetus, true) then
				character.mbc:addPassive(player, character.drFetus)
			end
		else
			if player:HasCollectible(character.drFetus, true) then
				player:RemoveCollectible(character.drFetus, true)
			end
		end
		
		if (player:GetData().mbc and player:GetData().mbc.makeshiftMantleKeys and player:GetData().mbc.makeshiftMantleKeys > 1) or player:HasCollectible(character.birthright, true) then
			if player:GetActiveItem(ActiveSlot.SLOT_POCKET) ~= character.dadsKey then
				character.mbc:addPocketActive(player, character.dadsKey)
			end
		else
			if player:GetActiveItem(ActiveSlot.SLOT_POCKET) == character.dadsKey then
				player:RemoveCollectible(character.dadsKey, true, ActiveSlot.SLOT_POCKET)
			end
		end
	end
end

function character:onPostNewLevel(player)
	local center = Game():GetLevel():GetCurrentRoom():GetCenterPos()
	
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(playerIndex)
		
		if player:GetPlayerType() == character.playerType and player:HasCollectible(character.birthright, true) then
			Isaac.Spawn(EntityType.ENTITY_SLOT, 9, 0, center - Vector(80, 0), Vector(0, 0), player)
			Isaac.Spawn(EntityType.ENTITY_SLOT, 7, 0, center + Vector(80, 0), Vector(0, 0), player)
		end
	end
end

-- add description if eid mod is running

if EID then
	character.eid = "Player will always have both Dr. Fetus and Dad's Key#Spawns a Bomb Bum and a Key Master at the start of each floor"
	
	EID:addBirthright(character.playerType, character.eid, "Tainted " .. (character.name:sub(5):gsub("_B", "")))
end

-- return object

return character
