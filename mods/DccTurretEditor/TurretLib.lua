local This = {};

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function This:UpdatePlayerInventory(Real,Index)

	if(onClient())
	then
		return invokeServerFunction(
			"TurretLib_ServerCallback_UpdatePlayerInventory",
			Real,
			Index
		)
	end

	return
end

function TurretLib_ServerCallback_UpdatePlayerInventory(Real,Index)

	print("[DccTurretEditor] Replacing Item " .. Index .. " (" .. Real.weaponName .. ")")

	local Armory = Player():getInventory()
	local Old = Armory:find(Index)
	local Count = Armory:amount(Index)
	local NewIndex = 0

	Real.favorite = Old.favorite
	Real.trash = Old.trash

	-- handle stacked items.

	if(Count > 1)
	then
		Armory:setAmount(Index,(Count - 1))
	else
		Armory:removeAll(Index)
	end

	NewIndex = Armory:add(Real)
	invokeClientFunction(Player(),"Win_Update",NewIndex)

	return NewIndex
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function This:GetWeaponFireRate(Item)
-- get how fast this turret shoots

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList) do
		return round(Weap.fireRate,3)
	end

	return
end

function This:GetWeaponColour(Item)
-- get what colour this turret

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList)
	do
		if(Weap.isProjectile)
		then
			return Weap.pcolor
		else
			return Weap.binnerColor
		end
	end

	return
end

function This:GetWeaponHeatRate(Item)
-- get the heat per shot of this item.

	return round(Item.heatPerShot,3)
end

function This:GetWeaponCoolRate(Item)
-- get the cooling rate for this turret.

	return round(Item.coolingRate,3)
end

function This:GetWeaponMaxHeat(Item)
-- get the max heat for this turret.

	return round(Item.maxHeat,3)
end

function This:GetWeaponBaseEnergy(Item)
-- get the base energy per second.

	return round(Item.baseEnergyPerSecond,3)
end

function This:GetWeaponAccumEnergy(Item)
-- get the energy accumulation over time.

	return round(Item.energyIncreasePerSecond,3)
end

function This:GetWeaponRange(Item)
-- get weapon range in km.

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList)
	do
		return round(Weap.reach / 100,3)
	end

	return
end

function This:GetWeaponSpeed(Item)
-- get the turret tracking speed

	return round(Item.turningSpeed,3)
end

function This:GetWeaponRange(Item)
-- get turret weapons range

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList) do
		return round(Weap.reach,3)
	end
end

--------

function This:SetWeaponColour(Which,Item,Colour)

	local WeapList = {Item:getWeapons()}
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList)
	do
		if(Which == "projectile")
		then
			Weap.pcolor = Colour
		elseif(Which == "core")
		then
			Weap.binnerColor = Colour
		elseif(Which == "glow")
		then
			Weap.bouterColor = Colour
		end

		Item:addWeapon(Weap)
	end

	return
end


function This:SetWeaponRange(Item,Dist)
-- set weapon range in km.

	local WeapList = {Item:getWeapons()}
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList)
	do
		Weap.reach = Dist * 100
		Item:addWeapon(Weap)
	end

	return
end


function This:GetWeaponCrew(Item)
-- get required crew. if its a civil cannon it returns the miner count and if
-- an offensive weapon it returns the gunner count.



	return
end

function This:SetWeaponCrew(Item,Val)
-- set required crew. if a civil cannon it sets the miner count and if an
-- offensive weapon it sets the gunner count.

	return
end

function This:ToggleTargeting(Item)
-- toggle automatic targeting.

	Item.automatic = not Item.automatic

	return
end

return This