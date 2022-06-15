-- main object

local passive = {}

-- set up id info

passive.name = "Sheathed Sword"
passive.id = Isaac.GetItemIdByName(passive.name)

-- add description if eid mod is running

if EID then
	passive.eid = "Tears now require ammo but tears do more damage when low on ammo#Running out of ammo hurts the player and gives Spirit Sword for the floor#Dealing and taking damage gives ammo"
	
	EID:addCollectible(passive.id, passive.eid)
end

-- define item detection function

function passive:doesPlayerHaveThisItem(player)
	return player and player:HasCollectible(passive.id, true)
end

-- define ammo functions

passive.sword = Isaac.GetItemIdByName("Spirit Sword")
passive.character = Isaac.GetPlayerTypeByName("MBC_Peter", false)
passive.birthright = Isaac.GetItemIdByName("Birthright")

passive.mapStageToMaxAmmo = {
	10,
	15,
	20,
	25,
	30,
	35,
	40,
	45
}

function passive:getMaxAmmo()
	return passive.mapStageToMaxAmmo[Game():GetLevel():GetAbsoluteStage()] or 50
end

function passive:getMinAmmo(player)
	if player:GetPlayerType() == passive.character and player:HasCollectible(passive.birthright) then
		return -passive:getMaxAmmo()
	end
	
	return 0
end

function passive:getAmmo(player)
	return player:GetData().mbc.ammo or passive:getMaxAmmo()
end

function passive:addAmmo(player, amount)
	player:GetData().mbc.ammo = math.min(passive:getAmmo(player) + amount, passive:getMaxAmmo())
end

-- define fire callback

function passive:getShooter(tear)
	local shooter = tear.SpawnerEntity
	
	if shooter then
		shooter = shooter:ToPlayer()
	end
	
	return shooter
end

function passive:onPostFireTear(tear)
	local player = passive:getShooter(tear)
	
	if passive:doesPlayerHaveThisItem(player) then
		local fullness = passive:getAmmo(player) / passive:getMaxAmmo()
		local multiplier = 2 - fullness
		
		tear.CollisionDamage = tear.CollisionDamage * multiplier
		
		if fullness < 0 then
			tear.Color = Color.Lerp(Color(1, 0, 0), Color(0, 0, 0), -fullness)
		else
			tear.Color = Color.Lerp(Color(1, 0, 0), tear.Color, fullness)
		end
		
		-- don't count shots that are fired while the temp sword is held (deals with stuff like Saturnus draining ammo, causing damage, and giving extra swords that don't get removed)
		if not player:GetData().mbc.hasTempSword then
			if passive:getAmmo(player) > passive:getMinAmmo(player) then
				passive:addAmmo(player, -1)
			else
				tear:Remove()
				player:AddCollectible(passive.sword)
				player:TakeDamage(2, DamageFlag.DAMAGE_RED_HEARTS | DamageFlag.DAMAGE_NO_MODIFIERS | DamageFlag.DAMAGE_NO_PENALTIES, EntityRef(player), 30)
				player:GetData().mbc.hasTempSword = true
			end
		end
	end
end

-- define damage callback

function passive:getPlayerFromSource(source)
	if not source or not source.Entity then
		return nil
	end
	
	if source.Type == EntityType.ENTITY_TEAR then
		return passive:getShooter(source.Entity)
	end
	
	return source.Entity:ToPlayer()
end

function passive:onEntityTakeDmg(victim, damage, flags, source, cooldown)
	local player = victim:ToPlayer()
	
	if player then
		if passive:doesPlayerHaveThisItem(player) then
			passive:addAmmo(player, damage * 10)
		end
		
		return
	end
	
	player = passive:getPlayerFromSource(source)
	
	if player then
		if passive:doesPlayerHaveThisItem(player) then
			passive:addAmmo(player, 1.5)
		end
		
		return
	end
end

-- define cleanup callback

function passive:onPostNewLevel()
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(playerIndex)
		
		if player and player:GetData().mbc and player:GetData().mbc.hasTempSword then
			player:RemoveCollectible(passive.sword, true)
			player:GetData().mbc.hasTempSword = nil
		end
	end
end

-- define text callback

passive.font = Font()
passive.font:Load("font/pftempestasevencondensed.fnt")

function passive:onPostRender()
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(playerIndex)
		
		if passive:doesPlayerHaveThisItem(player) then
			local ammoString = math.ceil(passive:getAmmo(player)) .. "/" .. math.ceil(passive:getMaxAmmo())
			local playerPos = passive.mbc:worldToScreen(player.Position)
			
			if Game():GetHUD():IsVisible() then
				passive.font:DrawString(ammoString, playerPos.X - 1, playerPos.Y, KColor(1, 1, 1, 1), 2, true)
			end
		end
	end
end

-- add callbacks to mod

function passive:addCallbacks(mbc)
	mbc.mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, passive.onPostFireTear)
	mbc.mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, passive.onEntityTakeDmg)
	mbc.mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, passive.onPostNewLevel)
	mbc.mod:AddCallback(ModCallbacks.MC_POST_RENDER, passive.onPostRender)
	
	passive.mbc = mbc
end

-- return object

return passive
