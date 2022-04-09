-- main object

local character = {}

-- set up id info

character.name = "MBC_Peter_B"
character.isTainted = true
character.playerType = Isaac.GetPlayerTypeByName(character.name, character.isTainted)
character.hair = Isaac.GetCostumeIdByPath("gfx/characters/MBC_character_04b_peter_hair.anm2")

-- define stats

character.stats = {
	speed = 0.25,
	damage = -2.5,
	canFly = true
}

-- define starting inventory

character.pocketActive = Isaac.GetItemIdByName("Red Key")

character.passives = {
	Isaac.GetItemIdByName("Book of Virtues"),
	Isaac.GetItemIdByName("Mitre"),
	Isaac.GetItemIdByName("Spirit Sword")
}

-- add cache callback for stats

function character:onEvaluateCache(player, cacheFlag)
	if cacheFlag & CacheFlag.CACHE_SPEED == CacheFlag.CACHE_SPEED then
		player.MoveSpeed = player.MoveSpeed + character.stats.speed
	end
	
	if cacheFlag & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
		player.Damage = player.Damage + character.stats.damage
	end
	
	if cacheFlag & CacheFlag.CACHE_FLYING == CacheFlag.CACHE_FLYING then
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
	player:AddCostume(Isaac.GetItemConfig():GetCollectible(Isaac.GetItemIdByName("Fate")))
	
	character.mbc:addPocketActive(player, character.pocketActive)
	
	character.mbc.mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, character.onPostPlayerUpdate, 0)
	character.mbc.mod:AddCallback(ModCallbacks.MC_USE_ITEM, character.onUseItem)
	character.mbc.mod:AddCallback(ModCallbacks.MC_POST_RENDER, character.onPostRender)
	character.mbc.mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, character.onPostNewRoom)
end

-- add special callbacks

character.birthright = Isaac.GetItemIdByName("Birthright")

character.font = Font()
character.font:Load("font/pftempestasevencondensed.fnt")

function character:doesPlayerHaveThisBirthright(player)
	return player:GetPlayerType() == character.playerType and player:HasCollectible(character.birthright)
end

function character:isRoomShapeWide(shape)
	return shape >= RoomShape.ROOMSHAPE_2x1
end

function character:isRoomShapeTall(shape)
	return shape >= RoomShape.ROOMSHAPE_1x2 and (shape <= RoomShape.ROOMSHAPE_IIV or shape >= RoomShape.ROOMSHAPE_2x2)
end

function character:getRoomCoords(player)
	local level = Game():GetLevel()
	local room = level:GetCurrentRoom()
	local shape = room:GetRoomShape()
	local roomIndex = level:GetCurrentRoomDesc().GridIndex
	local position = player.Position - (room:GetTopLeftPos() * 0.5 + room:GetBottomRightPos() * 0.5)
	local x = roomIndex % 13 - 6
	local y = math.floor(roomIndex / 13) - 6
	
	if roomIndex < 0 or roomIndex > 168 then
		return ""
	end
	
	if position.X > 0 and character:isRoomShapeWide(shape) then
		x = x + 1
	end
	
	if position.Y > 0 and character:isRoomShapeTall(shape) then
		y = y + 1
	end
	
	return "( " .. x .. " , " .. -y .. " )"
end

function character:onPostPlayerUpdate(player)
	if player:GetPlayerType() == character.playerType and player:GetMaxHearts() > 0 then
		local numContainers = player:GetMaxHearts()
		
		-- replace red heart containers with soul hearts, bone hearts can still be filled with red health
		player:AddMaxHearts(-numContainers, true)
		player:AddSoulHearts(numContainers)
	end
end

function character:onUseItem(collectible, rng, player, useFlags, activeSlot)
	-- Book of Virtues normally doesn't generate wisps for pocket items, so force it, use GetCollectibleNum because HasCollectible doesn't work for passive version
	if player:GetPlayerType() == character.playerType and player:GetCollectibleNum(Isaac.GetItemIdByName("Book of Virtues")) > 0 and activeSlot == ActiveSlot.SLOT_POCKET then
		player:AddWisp(player:GetActiveItem(ActiveSlot.SLOT_POCKET), player.Position)
	end
end

function character:onPostRender()
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(playerIndex)
		
		if character:doesPlayerHaveThisBirthright(player) then
			local coordsString = character:getRoomCoords(player)
			local playerPos = character.mbc:worldToScreen(player.Position)
			
			if Game():GetHUD():IsVisible() then
				character.font:DrawString(coordsString, playerPos.X - 1, playerPos.Y, KColor(1, 1, 1, 1), 2, true)
			end
		end
	end
end

function character:onPostNewRoom()
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(playerIndex)
		
		if character:doesPlayerHaveThisBirthright(player) then
			local level = Game():GetLevel()
			local rooms = level:GetRooms()
			
			for roomIndex = 0, rooms.Size - 1 do
				local room = rooms:Get(roomIndex)
				
				if room.Data.Type == RoomType.ROOM_ULTRASECRET and room.DisplayFlags & 4 == 0 then
					level:GetRoomByIdx(room.GridIndex).DisplayFlags = room.DisplayFlags | 4
					level:UpdateVisibility()
				end
			end
			
			break
		end
		
		if player:GetPlayerType() == character.playerType and player:HasCurseMistEffect() then
			player:UseCard(Card.CARD_HANGED_MAN, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
		end
	end
end

-- add description if eid mod is running

if EID then
	character.eid = "Reveals the Ultra Secret Room#Shows room coordinates#Rooms at the level boundaries are 6 rooms away from the origin"
	
	EID:addBirthright(character.playerType, character.eid, "Tainted " .. (character.name:sub(5):gsub("_B", "")))
end

-- return object

return character
