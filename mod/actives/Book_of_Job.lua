-- main object

local active = {}

-- set up id info

active.name = "Book of Job"
active.id = Isaac.GetItemIdByName(active.name)

-- add description if eid mod is running

if EID then
	active.eid = "Fully heals the player#Gives soul hearts for each red heart healed#When held, turns touched hearts into blue flies"
	
	EID:addCollectible(active.id, active.eid)
	EID:assignTransformation("collectible", active.id, EID.TRANSFORMATION.BOOKWORM)
end

-- define use item callback

function active:onUseItem(collectible, rng, player)
	local numMissingRedHp = player:GetMaxHearts() + player:GetBoneHearts() * 2 - player:GetHearts()
	
	player:AddHearts(numMissingRedHp)
	player:AddSoulHearts(numMissingRedHp)
	
	-- true: do animation
	return true
end

-- define pre collision callbacks

active.character = Isaac.GetPlayerTypeByName("MBC_Job", false)
active.birthright = Isaac.GetItemIdByName("Birthright")

active.mapHeartSubTypeToNumFlies = {
	[HeartSubType.HEART_FULL] = 2,
	[HeartSubType.HEART_HALF] = 1,
	[HeartSubType.HEART_SOUL] = 3,
	[HeartSubType.HEART_ETERNAL] = 5,
	[HeartSubType.HEART_DOUBLEPACK] = 4,
	[HeartSubType.HEART_BLACK] = 4,
	[HeartSubType.HEART_GOLDEN] = 6,
	[HeartSubType.HEART_HALF_SOUL] = 2,
	[HeartSubType.HEART_SCARED] = 2,
	[HeartSubType.HEART_BLENDED] = 2,
	[HeartSubType.HEART_BONE] = 4,
	[HeartSubType.HEART_ROTTEN] = 2
}

function active:doesPlayerHaveThisBirthright(player)
	return player:GetPlayerType() == active.character and player:HasCollectible(active.birthright)
end

function active:isRedOrRotten(heart)
	return heart == HeartSubType.HEART_FULL or heart == HeartSubType.HEART_HALF or heart == HeartSubType.HEART_DOUBLEPACK or heart == HeartSubType.HEART_SCARED or heart == HeartSubType.HEART_ROTTEN
end

function active:onPlayerHeartCollision(player, heart)
	if player:HasCollectible(active.id, true) and heart.Variant == PickupVariant.PICKUP_HEART then
		local numFlies = active.mapHeartSubTypeToNumFlies[heart.SubType] or Random() % 6 + 1
		
		if not active:doesPlayerHaveThisBirthright(player) or active:isRedOrRotten(heart.SubType) then
			-- don't let player buy hearts
			if not heart:IsShopItem() then
				player:AddBlueFlies(numFlies, player.Position, player)
				heart:Remove()
			end
			
			-- true: ignore collision (don't heal)
			return true
		elseif active:doesPlayerHaveThisBirthright(player) and heart.SubType == HeartSubType.HEART_BLENDED then
			-- don't let player buy hearts
			if not heart:IsShopItem() then
				player:AddBlueFlies(numFlies, player.Position, player)
				heart:Remove()
				
				player:AddSoulHearts(1)
			end
			
			-- true: ignore collision (don't heal)
			return true
		end
	end
end

function active:onPrePlayerCollision(player, otherEntity, isFirst)
	local pickup = otherEntity:ToPickup()
	
	if not isFirst and pickup then
		return active:onPlayerHeartCollision(player, pickup)
	end
end

function active:onPrePickupCollision(heart, otherEntity, isFirst)
	local player = otherEntity:ToPlayer()
	
	if not isFirst and player then
		return active:onPlayerHeartCollision(player, heart:ToPickup())
	end
end

-- add callbacks to mod

function active:addCallbacks(mod)
	mod:AddCallback(ModCallbacks.MC_USE_ITEM, active.onUseItem, active.id)
	mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, active.onPrePlayerCollision, 0)
	mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, active.onPrePickupCollision, PickupVariant.PICKUP_HEART)
end

-- return object

return active
