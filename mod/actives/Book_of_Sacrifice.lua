-- main object

local active = {}

-- set up id info

active.name = "Book of Sacrifice"
active.id = Isaac.GetItemIdByName(active.name)

-- add description if eid mod is running

if EID then
	active.eid = "Removes a random passive item from the player#Spawns two items from the removed item's pool#May use another item pool if it doesn't know where the removed item came from"
	
	EID:addCollectible(active.id, active.eid)
	EID:assignTransformation("collectible", active.id, EID.TRANSFORMATION.BOOKWORM)
end	

-- define use item and collision callbacks and helper functions

active.defaultItemId = Isaac.GetItemIdByName("Breakfast")
active.character = Isaac.GetPlayerTypeByName("MBC_Job_B", true)
active.birthright = Isaac.GetItemIdByName("Birthright")
active.birthrightQuality = Isaac.GetItemConfig():GetCollectible(active.birthright).Quality

function active:doesPlayerHaveThisBirthright(player)
	return player:GetPlayerType() == active.character and player:HasCollectible(active.birthright)
end

function active:getMinIds(player)
	if active:doesPlayerHaveThisBirthright(player) then
		return 2
	end
	
	return 1
end

function active:getIdToSacrifice(player, ids)
	if active:doesPlayerHaveThisBirthright(player) then
		for quality = 0, 4 do
			if quality == active.birthrightQuality then
				if #ids[quality] > 1 then
					local id = ids[quality][Random() % (#ids[quality] - 1) + 1]
					
					if id == active.birthright then
						id = ids[quality][#ids[quality]]
					end
					
					return id
				end
			elseif #ids[quality] > 0 then
				return ids[quality][Random() % #ids[quality] + 1]
			end
		end
	end
	
	return ids.all[Random() % #ids.all + 1]
end

function active:isItemNonQuestPassive(item)
	-- ignore if doesn't exist, ignore if quest item, ignore if active
	return item and not item:HasTags(ItemConfig.TAG_QUEST) and item.Type ~= ItemType.ITEM_ACTIVE
end

function active:getEmptyNonQuestPassives()
	local passives = {
		all = {},
		[0] = {},
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {}
	}
	
	return passives
end

function active:updatePlayerNonQuestPassives(player, newItemId, newPool)
	local itemConfig = Isaac.GetItemConfig()
	local numItems = itemConfig:GetCollectibles().Size
	
	local mainPlayer = Isaac.GetPlayer()
	local mapItemToPool = mainPlayer:GetData().mbc.mapItemToPool or {}
	
	local oldIds = player:GetData().mbc.nonQuestPassives or active:getEmptyNonQuestPassives()
	local newIds = active:getEmptyNonQuestPassives()
	
	local oldIdIndex = 1
	
	local item = nil
	
	-- check all non-glitch items to see if player has each item
	for id = 1, numItems do
		item = itemConfig:GetCollectible(id)
		
		if player:HasCollectible(id, true) and active:isItemNonQuestPassive(item) then
			newIds.all[#newIds.all + 1] = id
			newIds[item.Quality][#newIds[item.Quality] + 1] = id
			
			if not mapItemToPool[id] then
				-- don't know the pool, need to improvise
				if oldIdIndex <= #oldIds.all then
					-- haven't found more new items than old items yet, maybe rerolled all items, use pool of item that we know the player had
					mapItemToPool[id] = mapItemToPool[oldIds.all[oldIdIndex]]
					oldIdIndex = oldIdIndex + 1
				else
					-- more items than expected, use treasure pool
					mapItemToPool[id] = ItemPoolType.POOL_TREASURE
				end
			end
		end
	end
	
	item = itemConfig:GetCollectible(newItemId or active.defaultItemId)
	
	if newItemId and active:isItemNonQuestPassive(item) then
		-- add new item
		newIds.all[#newIds.all + 1] = newItemId
		newIds[item.Quality][#newIds[item.Quality] + 1] = newItemId
		mapItemToPool[newItemId] = newPool
	end
	
	-- store mbcMapItemToPool on main player because main player should always exist
	mainPlayer:GetData().mbc.mapItemToPool = mapItemToPool
	player:GetData().mbc.nonQuestPassives = newIds
end

function active:onPlayerPickupCollision(player, pickup)
	local mapItemToPool = Isaac.GetPlayer():GetData().mbc.mapItemToPool
	
	-- ensure that pickup is pedestal containing new non-quest passive
	if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE and (not mapItemToPool or not mapItemToPool[pickup.SubType]) and active:isItemNonQuestPassive(Isaac.GetItemConfig():GetCollectible(pickup.SubType)) then
		local game = Game()
		local pool = game:GetItemPool():GetPoolForRoom(game:GetRoom():GetType(), game:GetLevel():GetCurrentRoomDesc().SpawnSeed)
		
		if pool == ItemPoolType.POOL_NULL then
			pool = ItemPoolType.POOL_TREASURE
		end
		
		-- touched item pedestal, assume player got item from current room's pool (use treasure pool if no pool)
		active:updatePlayerNonQuestPassives(player, pickup.SubType, pool)
		
		-- nil: don't ignore collision
		return
	end
end

function active:onPrePlayerCollision(player, otherEntity, isFirst)
	local pickup = otherEntity:ToPickup()
	
	if not isFirst and pickup then
		return active:onPlayerPickupCollision(player, pickup)
	end
end

function active:onPrePickupCollision(pedestal, otherEntity, isFirst)
	local player = otherEntity:ToPlayer()
	
	if not isFirst and player then
		return active:onPlayerPickupCollision(player, pedestal:ToPickup())
	end
end

function active:onUseItem(collectible, rng, player)
	local ids
	
	-- update list of items that can be sacrificed
	active:updatePlayerNonQuestPassives(player)
	ids = player:GetData().mbc.nonQuestPassives
	
	-- ensure that there are items that can be sacrificed
	if #ids.all >= active:getMinIds(player) then
		local pools = Game():GetItemPool()
		local center = Game():GetLevel():GetCurrentRoom():GetCenterPos()
		
		local mainPlayer = Isaac.GetPlayer()
		local mapItemToPool = mainPlayer:GetData().mbc.mapItemToPool
		
		local sacrificedItemId
		local sacrificedItemPool
		
		local newItemId1
		local newItemId2
		
		-- sacrifice random item
		sacrificedItemId = active:getIdToSacrifice(player, ids)
		sacrificedItemPool = mapItemToPool[sacrificedItemId]
		player:RemoveCollectible(sacrificedItemId, true)
		
		-- spawn replacement items from same pool
		newItemId1 = pools:GetCollectible(sacrificedItemPool, true, player.InitSeed, active.defaultItemId)
		newItemId2 = pools:GetCollectible(sacrificedItemPool, true, player.InitSeed, active.defaultItemId)
		Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, newItemId1, center - Vector(20, 0), Vector(0, 0), player):ToPickup().ShopItemId = -1
		Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, newItemId2, center + Vector(20, 0), Vector(0, 0), player):ToPickup().ShopItemId = -1
		
		-- set pool for new items
		mapItemToPool[newItemId1] = sacrificedItemPool
		mapItemToPool[newItemId2] = sacrificedItemPool
		mainPlayer:GetData().mbc.mapItemToPool = mapItemToPool
	end
	
	-- true: do animation
	return true
end

-- add callbacks to mod

function active:addCallbacks(mod)
	mod:AddCallback(ModCallbacks.MC_USE_ITEM, active.onUseItem, active.id)
	mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, active.onPrePlayerCollision, 0)
	mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, active.onPrePickupCollision, PickupVariant.PICKUP_COLLECTIBLE)
end

-- return object

return active
