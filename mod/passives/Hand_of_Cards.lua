-- main object

local passive = {}

-- set up id info

passive.name = "Hand of Cards"
passive.id = Isaac.GetItemIdByName(passive.name)

-- add description if eid mod is running

if EID then
	passive.eid = "Spawns two groups of items at the start of each floor#Only one item can be taken per group#Prevents player from picking up other items unless they are shop items in greed mode or quest items"
	
	EID:addCollectible(passive.id, passive.eid)
end

-- define helper functions

passive.pools = {
	[ItemPoolType.POOL_TREASURE] = 6,
	[ItemPoolType.POOL_SHOP] = 5,
	[ItemPoolType.POOL_BOSS] = 6,
	[ItemPoolType.POOL_DEVIL] = 2,
	[ItemPoolType.POOL_ANGEL] = 2,
	[ItemPoolType.POOL_SECRET] = 1,
	[ItemPoolType.POOL_LIBRARY] = 1,
	[ItemPoolType.POOL_CURSE] = 1,
	[ItemPoolType.POOL_PLANETARIUM] = 1
}

passive.poolsBirthright = {
	[ItemPoolType.POOL_TREASURE] = 4,
	[ItemPoolType.POOL_SHOP] = 3,
	[ItemPoolType.POOL_BOSS] = 3,
	[ItemPoolType.POOL_DEVIL] = 4,
	[ItemPoolType.POOL_ANGEL] = 4,
	[ItemPoolType.POOL_SECRET] = 2,
	[ItemPoolType.POOL_LIBRARY] = 1,
	[ItemPoolType.POOL_CURSE] = 2,
	[ItemPoolType.POOL_PLANETARIUM] = 2
}

passive.poolsTotal = 0
passive.poolsBirthrightTotal = 0

for pool, weight in pairs(passive.pools) do
	passive.poolsTotal = passive.poolsTotal + weight
end

for pool, weight in pairs(passive.poolsBirthright) do
	passive.poolsBirthrightTotal = passive.poolsBirthrightTotal + weight
end

function passive:doesPlayerHaveThisItem(player)
	return player:HasCollectible(passive.id, true) or (player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B and player:GetMainTwin():HasCollectible(passive.id, true))
end

function passive:doesPlayerHaveThisBirthright(player)
	return player:GetPlayerType() == passive.character and player:HasCollectible(passive.birthright)
end

function passive:getPool(player)
	local pools = passive.pools
	local totalWeight = passive.poolsTotal
	
	if passive:doesPlayerHaveThisBirthright(player) then
		pools = passive.poolsBirthright
		totalWeight = passive.poolsBirthrightTotal
	end
	
	local value = Random() % totalWeight
	
	for pool, weight in pairs(pools) do
		if weight > value then
			return pool
		end
		
		value = value - weight
	end
end

function passive:isCorrectOptionsIndex(player, item)
	return item.OptionsPickupIndex > 7 and item.OptionsPickupIndex % 8 == player:GetData().mbc.index
end

function passive:isQuestItem(item)
	return item and item:HasTags(ItemConfig.TAG_QUEST)
end

function passive:isGreedShopItem(item)
	return Game():IsGreedMode() and item:IsShopItem()
end

function passive:isBossRush()
	return Game():GetRoom():GetType() == RoomType.ROOM_BOSSRUSH
end

function passive:onPlayerPickupCollision(player, pickup)
	if passive:doesPlayerHaveThisItem(player) and pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then
		if not passive:isCorrectOptionsIndex(player, pickup) then
			if not passive:isQuestItem(Isaac.GetItemConfig():GetCollectible(pickup.SubType)) and not passive:isGreedShopItem(pickup) and not passive:isBossRush() then
				return false
			end
		end
	end
end

function passive:spawnItems(player, numItems, optionsIndex, multiplier)
	local pools = Game():GetItemPool()
	local center = Game():GetLevel():GetCurrentRoom():GetCenterPos()
	local y = (player:GetData().mbc.index % 4 + 1) * 40 * multiplier
	
	if player:GetData().mbc.index < 2 then
		y = -y
	end
	
	if player and passive:doesPlayerHaveThisItem(player) then
		for itemIndex = 1, numItems do
			local pool = passive:getPool(player)
			local id = pools:GetCollectible(pool, true, player.InitSeed, passive.defaultItemId)
			local x = (itemIndex - 1) * 40 - (numItems - 1) * 20
			local item = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, id, center + Vector(x, y), Vector(0, 0), player):ToPickup()
			
			item.ShopItemId = -1
			item.OptionsPickupIndex = optionsIndex
		end
	end
end

-- define callbacks

passive.defaultItemId = Isaac.GetItemIdByName("Breakfast")
passive.character = Isaac.GetPlayerTypeByName("MBC_Adam", false)
passive.birthright = Isaac.GetItemIdByName("Birthright")

function passive:onPostNewLevel()
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(playerIndex)
		
		if player:GetData().mbc then
			passive:spawnItems(player, passive.mbc:getFloor(), 8 * passive.id + player:GetData().mbc.index, 1)
			passive:spawnItems(player, passive.mbc:getFloor(), 16 * passive.id + player:GetData().mbc.index, -1)
		end
	end
end

function passive:onPlayerSpawn(player)
	passive:spawnItems(player, passive.mbc:getFloor(), 8 * passive.id + player:GetData().mbc.index, 1)
	passive:spawnItems(player, passive.mbc:getFloor(), 16 * passive.id + player:GetData().mbc.index, -1)
end

function passive:onPrePlayerCollision(player, otherEntity, isFirst)
	local pickup = otherEntity:ToPickup()
	
	if not isFirst and pickup then
		return passive:onPlayerPickupCollision(player, pickup)
	end
end

function passive:onPrePickupCollision(pedestal, otherEntity, isFirst)
	local player = otherEntity:ToPlayer()
	
	if not isFirst and player then
		return passive:onPlayerPickupCollision(player, pedestal:ToPickup())
	end
end

-- add callbacks to mod

function passive:addCallbacks(mbc)
	mbc.mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, passive.onPostNewLevel)
	mbc.mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, passive.onPrePlayerCollision, 0)
	mbc.mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, passive.onPrePickupCollision, PickupVariant.PICKUP_COLLECTIBLE)
	
	mbc.onPlayerSpawnCallbacks[#mbc.onPlayerSpawnCallbacks + 1] = passive
	
	passive.mbc = mbc
end

-- return object

return passive
