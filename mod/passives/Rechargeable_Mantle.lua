-- main object

local passive = {}

-- set up id info

passive.name = "Rechargeable Mantle"
passive.id = Isaac.GetItemIdByName(passive.name)

-- add description if eid mod is running

if EID then
	passive.eid = "Grants a mantle that can be recharged with batteries#It can be upgraded up to three times with mega batteries to take more hits"
	
	EID:addCollectible(passive.id, passive.eid)
end

-- define helper functions

function passive:doesPlayerHaveThisItem(player)
	return player:HasCollectible(passive.id, true) or (player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B and player:GetMainTwin():HasCollectible(passive.id, true))
end

function passive:doesPlayerHaveThisBirthright(player)
	return player:GetPlayerType() == passive.character and player:HasCollectible(passive.birthright)
end

function passive:getCapacity(player)
	if not player:GetData().mbc.rechargeableMantleLevel then
		player:GetData().mbc.rechargeableMantleLevel = 1
	end
	
	if player:GetPlayerType() == passive.character and passive:doesPlayerHaveThisBirthright(player) then
		return passive.capacities[player:GetData().mbc.rechargeableMantleLevel + 3]
	end
	
	return passive.capacities[player:GetData().mbc.rechargeableMantleLevel]
end

function passive:getCharge(player)
	if not player:GetData().mbc.rechargeableMantleCharge then
		player:GetData().mbc.rechargeableMantleCharge = passive:getCapacity(player)
	end
	
	return player:GetData().mbc.rechargeableMantleCharge
end

function passive:addCharge(player, amount)
	player:GetData().mbc.rechargeableMantleCharge = math.max(math.min(player:GetData().mbc.rechargeableMantleCharge + amount, passive:getCapacity(player)), 0)
end

function passive:doesSomeoneHaveThisItemAndBatteryPack()
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(playerIndex)
		
		if passive:doesPlayerHaveThisItem(player) and player:HasCollectible(passive.batteryPack, true) then
			return true
		end
	end
	
	return false
end

function passive:doesPlayerHaveItem(player, item)
	return player:HasCollectible(item, true) or (player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B and player:GetMainTwin():HasCollectible(item, true))
end

function passive:doesPlayerActiveNeedCharge(player)
	return player:NeedsCharge(ActiveSlot.SLOT_PRIMARY) or player:NeedsCharge(ActiveSlot.SLOT_SECONDARY) or player:NeedsCharge(ActiveSlot.SLOT_POCKET)
end

-- define callbacks

passive.character = Isaac.GetPlayerTypeByName("MBC_Golem", false)
passive.birthright = Isaac.GetItemIdByName("Birthright")
passive.sprites = {}

passive.volt45 = Isaac.GetItemIdByName("4.5 Volt")
passive.volt9 = Isaac.GetItemIdByName("9 Volt")
passive.batteryPack = Isaac.GetItemIdByName("Battery Pack")
passive.carBattery = Isaac.GetItemIdByName("Car Battery")
passive.jumperCables = Isaac.GetItemIdByName("Jumper Cables")
passive.sharpPlug = Isaac.GetItemIdByName("Sharp Plug")
passive.theBattery = Isaac.GetItemIdByName("The Battery")

passive.capacities = {
	1,
	2,
	3,
	4,
	6,
	8,
	12
}

passive.barBounds = {
	top = 3,
	bottom = 26
}

passive.mapHeartSubTypeToBatterySubType = {
	[HeartSubType.HEART_FULL] = BatterySubType.BATTERY_MICRO,
	[HeartSubType.HEART_HALF] = BatterySubType.BATTERY_MICRO,
	[HeartSubType.HEART_SOUL] = BatterySubType.BATTERY_NORMAL,
	[HeartSubType.HEART_ETERNAL] = BatterySubType.BATTERY_MEGA,
	[HeartSubType.HEART_DOUBLEPACK] = BatterySubType.BATTERY_NORMAL,
	[HeartSubType.HEART_BLACK] = BatterySubType.BATTERY_NORMAL,
	[HeartSubType.HEART_GOLDEN] = BatterySubType.BATTERY_MEGA,
	[HeartSubType.HEART_HALF_SOUL] = BatterySubType.BATTERY_MICRO,
	[HeartSubType.HEART_SCARED] = BatterySubType.BATTERY_MICRO,
	[HeartSubType.HEART_BLENDED] = BatterySubType.BATTERY_MICRO,
	[HeartSubType.HEART_BONE] = BatterySubType.BATTERY_NORMAL,
	[HeartSubType.HEART_ROTTEN] = BatterySubType.BATTERY_MICRO
}

function passive:onPlayerBatteryCollision(player, battery)
	if passive:doesPlayerHaveThisItem(player) then
		if battery.Variant == PickupVariant.PICKUP_LIL_BATTERY then
			if battery.SubType == BatterySubType.BATTERY_NORMAL or battery.SubType == BatterySubType.BATTERY_MICRO then
				if passive:getCharge(player) < passive:getCapacity(player) then
					local charge = 2
					
					if battery.SubType == BatterySubType.BATTERY_NORMAL then
						charge = 6
					end
					
					if passive:doesPlayerHaveItem(player, passive.volt9) then
						charge = charge + 1
					end
					
					if not battery:IsShopItem() then
						passive:addCharge(player, charge)
						battery:Remove()
						
						return true
					elseif player:GetNumCoins() >= battery.Price then
						player:AddCoins(-battery.Price)
						passive:addCharge(player, charge)
						battery:Remove()
						
						return true
					end
				end
			elseif battery.SubType == BatterySubType.BATTERY_MEGA then
				local shouldReturnTrue = false
				
				if not battery:IsShopItem() then
					if player:GetData().mbc.rechargeableMantleLevel < 4 then
						player:GetData().mbc.rechargeableMantleLevel = player:GetData().mbc.rechargeableMantleLevel + 1
						shouldReturnTrue = true
					end
					
					if passive:getCharge(player) < passive:getCapacity(player) then
						passive:addCharge(player, passive:getCapacity(player))
						battery:Remove()
						shouldReturnTrue = true
					end
				elseif player:GetNumCoins() >= battery.Price then
					player:AddCoins(-battery.Price)
					
					if player:GetData().mbc.rechargeableMantleLevel < 4 then
						player:GetData().mbc.rechargeableMantleLevel = player:GetData().mbc.rechargeableMantleLevel + 1
						shouldReturnTrue = true
					end
					
					if passive:getCharge(player) < passive:getCapacity(player) then
						passive:addCharge(player, passive:getCapacity(player))
						battery:Remove()
						shouldReturnTrue = true
					end
				end
				
				if shouldReturnTrue then
					return true
				end
			end
		elseif battery.Variant == PickupVariant.PICKUP_KEY and battery.SubType == KeySubType.KEY_CHARGED then
			if passive:getCharge(player) < passive:getCapacity(player) then
				local charge = 6
				
				if passive:doesPlayerHaveItem(player, passive.volt9) then
					charge = charge + 1
				end
				
				if not battery:IsShopItem() then
					player:AddKeys(1)
					passive:addCharge(player, charge)
					battery:Remove()
					
					return true
				elseif player:GetNumCoins() >= battery.Price then
					player:AddCoins(-battery.Price)
					player:AddKeys(1)
					passive:addCharge(player, charge)
					battery:Remove()
					
					return true
				end
			end
		end
	end
end

function passive:onPrePlayerCollision(player, otherEntity, isFirst)
	local pickup = otherEntity:ToPickup()
	
	if not isFirst and pickup then
		return passive:onPlayerBatteryCollision(player, pickup)
	end
end

function passive:onPrePickupCollision(battery, otherEntity, isFirst)
	local player = otherEntity:ToPlayer()
	
	if not isFirst and player then
		return passive:onPlayerBatteryCollision(player, battery:ToPickup())
	end
end

function passive:onEntityTakeDmg(victim, damage, flags, source, cooldown)
	local player = victim:ToPlayer()
	
	if player and passive:doesPlayerHaveThisItem(player) then
		if passive:getCharge(player) > 0 then
			if passive:doesPlayerHaveItem(player, passive.theBattery) then
				passive:addCharge(player, -math.ceil(damage / 2))
			else
				passive:addCharge(player, -damage)
			end
			
			if passive:doesPlayerHaveItem(player, passive.carBattery) then
				player:SetMinDamageCooldown(120)
			else
				player:SetMinDamageCooldown(60)
			end
			
			return false
		elseif passive:doesPlayerHaveItem(player, passive.sharpPlug) then
			passive:addCharge(player, damage)
		end
	end
end

function passive:onPreEntitySpawn(entityType, variant, subType, position, velocity, spawner, seed)
	if passive:doesSomeoneHaveThisItemAndBatteryPack() and entityType == EntityType.ENTITY_PICKUP and variant == PickupVariant.PICKUP_HEART and seed % 10 == 1 then
		local batterySubType = passive.mapHeartSubTypeToBatterySubType[subType]
		
		if not batterySubType then
			batterySubType = passive.mapHeartSubTypeToBatterySubType[(seed / 10) % 12 + 1]
		end
		
		return {EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LIL_BATTERY, batterySubType, seed}
	end
end

function passive:onPostNpcDeath(npc)
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(playerIndex)
		
		if player and passive:doesPlayerHaveThisItem(player) and passive:doesPlayerHaveItem(player, passive.jumperCables) and not passive:doesPlayerActiveNeedCharge(player) then
			if not player:GetData().mbc.rechargeableMantleJumperCableKills then
				player:GetData().mbc.rechargeableMantleJumperCableKills = 0
			end
			
			player:GetData().mbc.rechargeableMantleJumperCableKills = player:GetData().mbc.rechargeableMantleJumperCableKills + 1
			
			if player:GetData().mbc.rechargeableMantleJumperCableKills >= 15 then
				player:GetData().mbc.rechargeableMantleJumperCableKills = 0
				passive:addCharge(player, 1)
			end
		end
	end
end

function passive:onPostPlayerUpdate(player)
	if passive:doesPlayerHaveThisItem(player) and passive:doesPlayerHaveItem(player, passive.volt45) and not passive:doesPlayerActiveNeedCharge(player) then
		local threshold = 20 * passive.mbc:getFloor() + 40
		
		if not player:GetData().mbc.rechargeableMantle45VoltDamage then
			player:GetData().mbc.rechargeableMantle45VoltDamage = 0
		end
		
		player:GetData().mbc.rechargeableMantle45VoltDamage = player:GetData().mbc.rechargeableMantle45VoltDamage + Game():GetRoom():GetEnemyDamageInflicted()
		
		if player:GetData().mbc.rechargeableMantle45VoltDamage >= threshold then
			player:GetData().mbc.rechargeableMantle45VoltDamage = player:GetData().mbc.rechargeableMantle45VoltDamage - threshold
			passive:addCharge(player, 1)
		end
	end
end

function passive:onPostRender()
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(playerIndex)
		
		if passive:doesPlayerHaveThisItem(player) then
			local playerPos = passive.mbc:worldToScreen(player.Position)
			local charge = passive:getCharge(player)
			local maxCharge = passive:getCapacity(player)
			local cropY = (charge / maxCharge) * (passive.barBounds.top - passive.barBounds.bottom) + passive.barBounds.bottom
			
			if not passive.sprites[playerIndex] then
				passive.sprites[playerIndex] = {
					background = Sprite(),
					fill = Sprite(),
					marks = Sprite()
				}
				
				passive.sprites[playerIndex].background:Load("gfx/sprites/ui_chargebar.anm2", true)
				passive.sprites[playerIndex].background:SetAnimation("BarEmpty")
				passive.sprites[playerIndex].background:SetFrame(0)
				
				passive.sprites[playerIndex].fill:Load("gfx/sprites/ui_chargebar.anm2", true)
				passive.sprites[playerIndex].fill:SetAnimation("BarFull")
				passive.sprites[playerIndex].fill:SetFrame(0)
				
				passive.sprites[playerIndex].marks:Load("gfx/sprites/ui_chargebar.anm2", true)
				passive.sprites[playerIndex].marks:SetAnimation("BarOverlay" .. maxCharge)
				passive.sprites[playerIndex].marks:SetFrame(0)
			end
			
			if player:GetData().mbc.rechargeableMantleLevel >= 4 then
				passive.sprites[playerIndex].fill.Color = Color(1, 1, 1, 1, 1)
			else
				passive.sprites[playerIndex].fill.Color = Color(1, 1, 1, 1, 0)
			end
			
			passive.sprites[playerIndex].marks:SetAnimation("BarOverlay" .. maxCharge, false)
			
			if Game():GetHUD():IsVisible() then
				passive.sprites[playerIndex].background:Render(playerPos + Vector(21, -13))
				passive.sprites[playerIndex].fill:Render(playerPos + Vector(21, -13), Vector(0, cropY))
				passive.sprites[playerIndex].marks:Render(playerPos + Vector(21, -13))
			end
		end
	end
end

-- add callbacks to mod

function passive:addCallbacks(mbc)
	mbc.mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, passive.onPrePlayerCollision, 0)
	mbc.mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, passive.onPrePickupCollision, PickupVariant.PICKUP_LIL_BATTERY)
	mbc.mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, passive.onPrePickupCollision, PickupVariant.PICKUP_KEY)
	mbc.mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, passive.onEntityTakeDmg)
	mbc.mod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, passive.onPreEntitySpawn)
	mbc.mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, passive.onPostNpcDeath)
	mbc.mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, passive.onPostPlayerUpdate, 0)
	mbc.mod:AddCallback(ModCallbacks.MC_POST_RENDER, passive.onPostRender)
	
	passive.mbc = mbc
end

-- return object

return passive
