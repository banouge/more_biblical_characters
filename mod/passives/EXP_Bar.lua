-- main object

local passive = {}

-- set up id info

passive.name = "EXP Bar"
passive.id = Isaac.GetItemIdByName(passive.name)

-- add description if eid mod is running

if EID then
	passive.eid = "Spawns an item each time the player kills a certain number of enemies#Prevents player from picking up other items unless they are shop items in greed mode or quest items"
	
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

passive.poolsTotal = 0

for pool, weight in pairs(passive.pools) do
	passive.poolsTotal = passive.poolsTotal + weight
end

function passive:doesPlayerHaveThisItem(player)
	return player:HasCollectible(passive.id, true) or (player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B and player:GetMainTwin():HasCollectible(passive.id, true))
end

function passive:doesPlayerHaveThisBirthright(player)
	return player:GetPlayerType() == passive.character and player:HasCollectible(passive.birthright)
end

function passive:getPool()
	local value = Random() % passive.poolsTotal
	
	for pool, weight in pairs(passive.pools) do
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
	if passive:doesPlayerHaveThisItem(player) and pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE and not passive:isCorrectOptionsIndex(player, pickup) then
		if not passive:isQuestItem(Isaac.GetItemConfig():GetCollectible(pickup.SubType)) and not passive:isGreedShopItem(pickup) and not passive:isBossRush() then
			return false
		end
	end
end

-- define callbacks

passive.defaultItemId = Isaac.GetItemIdByName("Breakfast")
passive.character = Isaac.GetPlayerTypeByName("MBC_Adam_B", true)
passive.birthright = Isaac.GetItemIdByName("Birthright")
passive.sprites = {}
passive.threshold = 12

function passive:onPostNpcDeath(npc)
	local pools = Game():GetItemPool()
	local center = Game():GetLevel():GetCurrentRoom():GetCenterPos()
	
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(playerIndex)
		
		if player and passive:doesPlayerHaveThisItem(player) then
			local xp = passive.mbc:getFloor()
			
			if npc:IsChampion() then
				xp = xp * 2
			end
			
			if npc:IsBoss() then
				xp = xp * 3
			end
			
			player:GetData().mbc.expBarProgress = player:GetData().mbc.expBarProgress + xp
			
			if player:GetData().mbc.expBarProgress >= player:GetData().mbc.expBarLevel * passive.threshold then
				player:GetData().mbc.expBarProgress = player:GetData().mbc.expBarProgress - player:GetData().mbc.expBarLevel * passive.threshold
				player:GetData().mbc.expBarLevel = player:GetData().mbc.expBarLevel + 1
				
				if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
					return
				end
				
				local x = (player:GetData().mbc.index % 4) * 40 - 60
				local numItems = 1
				
				if passive:doesPlayerHaveThisBirthright(player) then
					numItems = 2
				end
				
				for itemIndex = 1, numItems do
					local pool = passive:getPool(player)
					local id = pools:GetCollectible(pool, true, player.InitSeed, passive.defaultItemId)
					local y = (itemIndex - 1) * 40 - (numItems - 1) * 20
					local item = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, id, center + Vector(x, y), Vector(0, 0), player):ToPickup()
					
					item.ShopItemId = -1
					item.OptionsPickupIndex = 8 * passive.id + player:GetData().mbc.index
					
					player:UseCard(Card.CARD_HANGED_MAN, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
				end
			end
		end
	end
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

function passive:onPostRender()
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(playerIndex)
		
		if passive:doesPlayerHaveThisItem(player) then
			local playerPos = passive.mbc:worldToScreen(player.Position)
			
			if not passive.sprites[playerIndex] then
				passive.sprites[playerIndex] = Sprite()
				passive.sprites[playerIndex]:Load("gfx/sprites/MBC_EXP_Bar.anm2", true)
				passive.sprites[playerIndex]:SetAnimation(passive.sprites[playerIndex]:GetDefaultAnimation("Charge"))
			end
			
			if not player:GetData().mbc.expBarProgress then
				player:GetData().mbc.expBarProgress = 0
				player:GetData().mbc.expBarLevel = 1
			end
			
			passive.sprites[playerIndex]:SetFrame(math.floor(player:GetData().mbc.expBarProgress * 12 / (player:GetData().mbc.expBarLevel * passive.threshold)))
			
			if Game():GetHUD():IsVisible() then
				passive.sprites[playerIndex]:Render(playerPos - Vector(21, 13))
			end
		end
	end
end

-- add callbacks to mod

function passive:addCallbacks(mbc)
	mbc.mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, passive.onPostNpcDeath)
	mbc.mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, passive.onPrePlayerCollision, 0)
	mbc.mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, passive.onPrePickupCollision, PickupVariant.PICKUP_COLLECTIBLE)
	mbc.mod:AddCallback(ModCallbacks.MC_POST_RENDER, passive.onPostRender)
	
	passive.mbc = mbc
end

-- return object

return passive
