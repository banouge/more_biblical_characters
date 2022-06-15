-- main object

local character = {}

-- set up id info

character.name = "MBC_John_B"
character.isTainted = true
character.playerType = Isaac.GetPlayerTypeByName(character.name, character.isTainted)
character.hair = Isaac.GetCostumeIdByPath("gfx/characters/MBC_character_02b_john_hair.anm2")

-- define stats

character.stats = {
}

-- define starting inventory

character.pocketActive = Isaac.GetItemIdByName("Urn of Souls")
character.trinket = TrinketType.TRINKET_EXTENSION_CORD

character.passives = {
	Isaac.GetItemIdByName("BFFS!")
}

character.familiars = {
	{
		collectible = Isaac.GetItemIdByName("Holy Water"),
		variant = FamiliarVariant.HOLY_WATER
	}
}

-- add cache callback for stats

function character:onEvaluateCache(player, cacheFlag)
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
	
	character.mbc:addPocketActive(player, character.pocketActive)
	character.mbc:addTrinket(player, character.trinket)
	
	for _, familiar in pairs(character.familiars) do
		character.mbc:addFamiliar(player, familiar)
	end
	
	character.mbc.mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, character.onPostPlayerUpdate, 0)
	character.mbc.mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, character.onPostNewRoom)
end

-- add special callbacks

character.birthright = Isaac.GetItemIdByName("Birthright")

function character:doesPlayerHaveThisBirthright(player)
	return player:GetPlayerType() == character.playerType and player:HasCollectible(character.birthright)
end

function character:isValidUpdateFrame(player)
	return Game():GetFrameCount() % 90 == 0 and player:GetData().mbc.lastJohnBBirthrightUpdateFrame ~= Game():GetFrameCount()
end

function character:onPostPlayerUpdate(player)
	if character:doesPlayerHaveThisBirthright(player) and player:GetActiveItem(ActiveSlot.SLOT_POCKET) == character.pocketActive and character:isValidUpdateFrame(player) then
		-- spawn and kill a fly to take its soul
		Isaac.Spawn(EntityType.ENTITY_FLY, 0, 0, player.Position, Vector(0, 0), player):Die()
		player:GetData().mbc.lastJohnBBirthrightUpdateFrame = Game():GetFrameCount()
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
	character.eid = "Pocket Urn of Souls regains 1 charge every 3 seconds"
	
	EID:addBirthright(character.playerType, character.eid, "Tainted " .. (character.name:sub(5):gsub("_B", "")))
end

-- return object

return character
