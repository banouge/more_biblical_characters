-- main object

local passive = {}

-- set up id info

passive.name = "Makeshift Mantle"
passive.id = Isaac.GetItemIdByName(passive.name)

-- add description if eid mod is running

if EID then
	passive.eid = "Grants a mantle that can be recharged with bombs and keys#It can hold 2 bombs and 2 keys#Taking a hit removes either a bomb or a key"
	
	EID:addCollectible(passive.id, passive.eid)
end

-- define helper functions

function passive:doesPlayerHaveThisItem(player)
	return player:HasCollectible(passive.id, true) or (player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B and player:GetMainTwin():HasCollectible(passive.id, true))
end

function passive:doesPlayerHaveThisBirthright(player)
	return player:GetPlayerType() == passive.character and player:HasCollectible(passive.birthright)
end

function passive:getBombHealth(player)
	if not player:GetData().mbc.makeshiftMantleBombs then
		player:GetData().mbc.makeshiftMantleBombs = 2
	end
	
	return player:GetData().mbc.makeshiftMantleBombs
end

function passive:getKeyHealth(player)
	if not player:GetData().mbc.makeshiftMantleKeys then
		player:GetData().mbc.makeshiftMantleKeys = 2
	end
	
	return player:GetData().mbc.makeshiftMantleKeys
end

function passive:addBombHealth(player, amount)
	player:GetData().mbc.makeshiftMantleBombs = math.max(math.min(player:GetData().mbc.makeshiftMantleBombs + amount, 2), 0)
end

function passive:addKeyHealth(player, amount)
	player:GetData().mbc.makeshiftMantleKeys = math.max(math.min(player:GetData().mbc.makeshiftMantleKeys + amount, 2), 0)
end

-- define callbacks

passive.character = Isaac.GetPlayerTypeByName("MBC_Golem_B", true)
passive.birthright = Isaac.GetItemIdByName("Birthright")
passive.sprites = {}

function passive:onPlayerPickupCollision(player, pickup)
	if passive:doesPlayerHaveThisItem(player) then
		if pickup.Variant == PickupVariant.PICKUP_BOMB then
			if passive:getBombHealth(player) < 2 then
				if pickup.SubType == BombSubType.BOMB_NORMAL or pickup.SubType == BombSubType.BOMB_DOUBLEPACK then
					player:AddBombs(math.max(0, pickup.SubType - (2 - passive:getBombHealth(player))))
					
					passive:addBombHealth(player, pickup.SubType)
					pickup:Remove()
					
					return false
				elseif pickup.SubType == BombSubType.BOMB_GOLDEN or pickup.SubType == BombSubType.BOMB_GIGA then
					passive:addBombHealth(player, 2)
				end
			end
		else
			if passive:getKeyHealth(player) < 2 then
				if pickup.SubType == KeySubType.KEY_NORMAL then
					passive:addKeyHealth(player, 1)
					pickup:Remove()
					
					return false
				elseif pickup.SubType == KeySubType.KEY_DOUBLEPACK then
					if passive:getKeyHealth(player) > 0 then
						player:AddKeys(1)
					end
					
					passive:addKeyHealth(player, 2)
					pickup:Remove()
					
					return false
				elseif pickup.SubType == KeySubType.KEY_GOLDEN then
					passive:addKeyHealth(player, 2)
				elseif pickup.SubType == KeySubType.KEY_CHARGED then
					Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LIL_BATTERY, BatterySubType.BATTERY_NORMAL, pickup.Position, Vector(0, 0), player)
					
					passive:addKeyHealth(player, 1)
					pickup:Remove()
					
					return false
				end
			end
		end
	end
end

function passive:onPrePlayerCollision(player, otherEntity, isFirst)
	local pickup = otherEntity:ToPickup()
	
	if not isFirst and pickup and (pickup.Variant == PickupVariant.PICKUP_BOMB or pickup.Variant == PickupVariant.PICKUP_KEY) then
		return passive:onPlayerPickupCollision(player, pickup)
	end
end

function passive:onPrePickupCollision(pickup, otherEntity, isFirst)
	local player = otherEntity:ToPlayer()
	
	if not isFirst and player then
		return passive:onPlayerPickupCollision(player, pickup:ToPickup())
	end
end

function passive:onEntityTakeDmg(victim, damage, flags, source, cooldown)
	local player = victim:ToPlayer()
	
	if player and passive:doesPlayerHaveThisItem(player) and damage > 0 then
		local shouldLoseBomb = Random() % 2 == 0
		
		if shouldLoseBomb then
			if passive:getBombHealth(player) > 0 then
				passive:addBombHealth(player, -1)
				player:SetMinDamageCooldown(60)
				
				return false
			end
		else
			if passive:getKeyHealth(player) > 0 then
				passive:addKeyHealth(player, -1)
				player:SetMinDamageCooldown(60)
				
				return false
			end
		end
	end
end

function passive:onUsePill(pill, player, flags)
	if passive:doesPlayerHaveThisItem(player) then
		local oldBombs = player:GetData().mbc.makeshiftMantleBombs
		
		player:GetData().mbc.makeshiftMantleBombs = player:GetData().mbc.makeshiftMantleKeys
		player:GetData().mbc.makeshiftMantleKeys = oldBombs
	end
end

function passive:onPostRender()
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(playerIndex)
		
		if passive:doesPlayerHaveThisItem(player) then
			local playerPos = passive.mbc:worldToScreen(player.Position)
			local bombs = passive:getBombHealth(player)
			local keys = passive:getKeyHealth(player)
			
			if not passive.sprites[playerIndex] then
				passive.sprites[playerIndex] = {
					bombs = {},
					keys = {}
				}
				
				for index = 1, 2 do
					passive.sprites[playerIndex].bombs[index] = Sprite()
					passive.sprites[playerIndex].bombs[index]:Load("gfx/sprites/ui_crafting.anm2", true)
					passive.sprites[playerIndex].bombs[index]:SetAnimation("Idle")
					passive.sprites[playerIndex].bombs[index]:SetFrame(15)
					
					passive.sprites[playerIndex].keys[index] = Sprite()
					passive.sprites[playerIndex].keys[index]:Load("gfx/sprites/ui_crafting.anm2", true)
					passive.sprites[playerIndex].keys[index]:SetAnimation("Idle")
					passive.sprites[playerIndex].keys[index]:SetFrame(12)
				end
			end
			
			for index = 1, 2 do
				local x = index * 12 - 6
				local y = 6
				
				if index <= bombs then
					passive.sprites[playerIndex].bombs[index].Color = Color(1, 1, 1, 1)
				else
					passive.sprites[playerIndex].bombs[index].Color = Color(0, 0, 0, 0.5)
				end
				
				if index <= keys then
					passive.sprites[playerIndex].keys[index].Color = Color(1, 1, 1, 1)
				else
					passive.sprites[playerIndex].keys[index].Color = Color(0, 0, 0, 0.5)
				end
				
				if Game():GetHUD():IsVisible() then
					passive.sprites[playerIndex].bombs[index]:Render(playerPos + Vector(-x, y))
					passive.sprites[playerIndex].keys[index]:Render(playerPos + Vector(x, y))
				end
			end
		end
	end
end

-- add callbacks to mod

function passive:addCallbacks(mbc)
	mbc.mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, passive.onPrePlayerCollision, 0)
	mbc.mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, passive.onPrePickupCollision, PickupVariant.PICKUP_KEY)
	mbc.mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, passive.onPrePickupCollision, PickupVariant.PICKUP_BOMB)
	mbc.mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, passive.onEntityTakeDmg)
	mbc.mod:AddCallback(ModCallbacks.MC_USE_PILL, passive.onUsePill, PillEffect.PILLEFFECT_BOMBS_ARE_KEYS)
	mbc.mod:AddCallback(ModCallbacks.MC_POST_RENDER, passive.onPostRender)
	
	passive.mbc = mbc
end

-- return object

return passive
