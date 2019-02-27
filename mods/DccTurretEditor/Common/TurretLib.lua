
local This = {};
local Config = require("mods.DccTurretEditor.Common.ConfigLib")

--------------------------------------------------------------------------------
-- these things are used by the ui to perform authoritive tasks on the server
-- and then have the server phone home to the ui.

function This:PlayerPayCredits(PlayerID,Amount)
	if(onClient()) then
		return invokeServerFunction(
			"TurretLib_ServerCallback_PlayerPayCredits",
			PlayerID,
			Amount
		)
	end
end

function TurretLib_ServerCallback_PlayerPayCredits(PlayerID,Amount)

	Player(PlayerID):pay("",Amount)
	return
end

callable(nil,"TurretLib_ServerCallback_PlayerPayCredits")

--------

function This:UpdatePlayerUI(PlayerID)

	if(onClient()) then
		return invokeServerFunction(
			"TurretLib_ServerCallback_UpdatePlayerUI",
			PlayerID
		)
	end

	return
end

function TurretLib_ServerCallback_UpdatePlayerUI(PlayerID)

	print("Ping Client UI from Server")
	invokeClientFunction(Player(PlayerID),"TurretModdingUI_Update")

	return
end

callable(nil,"TurretLib_ServerCallback_UpdatePlayerUI")

--------

function This:UpdatePlayerInventory(PlayerID,Real,Index)
-- push the command to update inventory to the server.

Real:updateStaticStats()

	if(onClient()) then
		return invokeServerFunction(
			"TurretLib_ServerCallback_UpdatePlayerInventory",
			PlayerID,
			Real,
			Index
		)
	end

	return
end

function TurretLib_ServerCallback_UpdatePlayerInventory(PlayerID,Real,Index)

	print("[DccTurretEditor] Replacing Player Item " .. Index .. " (" .. Real.weaponName .. ")")

	local Armory = Player(PlayerID):getInventory()
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
	invokeClientFunction(Player(PlayerID),"TurretModdingUI_Update",NewIndex)

	return NewIndex
end

callable(nil,"TurretLib_ServerCallback_UpdatePlayerInventory")

--------

function This:ConsumePlayerInventory(PlayerID,Index,Num)
-- push the command to consume inventory to the server.

	if(onClient()) then
		return invokeServerFunction(
			"TurretLib_ServerCallback_ConsumePlayerInventory",
			PlayerID,
			Index,
			Num
		)
	end

end

function TurretLib_ServerCallback_ConsumePlayerInventory(PlayerID,Index,Num)

	local Armory = Player(PlayerID):getInventory()
	local Item = Armory:find(Index)
	local Count = Armory:amount(Index) - Num

	if(Count < 0) then
		Count = 0
	end

	Armory:setAmount(Index,Count)
	print("[DccTurretEditor] " .. Item.weaponName .. " count to " .. Count)

	return
end

callable(nil,"TurretLib_ServerCallback_ConsumePlayerInventory")

--------------------------------------------------------------------------------
-- these ones need to deal with each individual weapon on the turret -----------

function This:GetWeaponType(Item)
-- returns "projectile" or "beam"

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList) do
		if(Weap.isProjectile) then
			return "projectile"
		else
			return "beam"
		end
	end

	return
end

function This:BumpWeaponNameMark(Item)
-- bump the mark names on weapons. we do this mainly to trick the game into
-- never stacking the items.

	local WeapList = {Item:getWeapons()}
	local Value = 0
	local Mark
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do

		print("[DccTurretEditor] Weapon Name: " .. Weap.name .. ", Prefix: " .. Weap.prefix)

		Mark = string.match(Weap.name," Mk (%d+)$")
		if(Mark == nil) then
			Weap.name = Weap.name .. " Mk 1"
			Weap.prefix = Weap.prefix .. " Mk 1"
		else
			Mark = tonumber(Mark) + 1
			Weap.name = string.gsub(Weap.name," Mk (%d+)$"," Mk " .. Mark)
			Weap.prefix = string.gsub(Weap.prefix," Mk (%d+)$"," Mk " .. Mark)
		end

		Item:addWeapon(Weap)
	end

	return
end

function This:GetWeaponCount(Item)
-- get how many guns are on this turret.

	local WeapList = {Item:getWeapons()}
	local Count = 0

	for WeapIter,Weap in pairs(WeapList) do
		Count = Count + 1
	end

	return Count
end

--------

function This:GetWeaponFireRate(Item)
-- get how fast this turret shoots

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList) do
		return round(Weap.fireRate,3)
	end

	return
end

function This:ModWeaponFireRate(Item,Per)
-- modify the fire rate by a percent

	This:BumpWeaponNameMark(Item)

	local WeapList = {Item:getWeapons()}
	local Value = 0
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
		Value = ((Weap.fireRate * (Per / 100)) + Weap.fireRate)

		if(Value < 0) then
			Value = 0
		end

		print("[DccTurretEditor] Fire Rate: " .. Weap.fireRate .. " " .. Value)

		Weap.fireRate = Value
		Item:addWeapon(Weap)
	end

	return
end

--------

function This:GetWeaponRange(Item)
-- get weapon range in km.

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList)
	do
		return round(Weap.reach / 100,3)
	end

	return
end

function This:ModWeaponRange(Item,Per)
-- modify the range by a percent

	This:BumpWeaponNameMark(Item)

	local WeapList = {Item:getWeapons()}
	local Value = 0
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
		Value = ((Weap.reach * (Per / 100)) + Weap.reach)

		if(Value < 0) then
			Value = 0
		end

		Weap.reach = Value
		Item:addWeapon(Weap)
	end

	return
end

--------

function This:GetWeaponDamage(Item)
-- get weapon range in km.

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList)
	do
		return round(Weap.damage,3)
	end

	return
end

function This:ModWeaponDamage(Item,Per)
-- modify the range by a percent

	This:BumpWeaponNameMark(Item)

	local WeapList = {Item:getWeapons()}
	local Value = 0
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
		Value = ((Weap.damage * (Per / 100)) + Weap.damage)

		if(Value < 0) then
			Value = 0
		end

		print(
			"[DccTurretEditor] Weapon Dmg: " .. Weap.damage .. " " .. Value
		)

		Weap.damage = Value
		Item:addWeapon(Weap)
	end

	return
end

--------

function This:GetWeaponAccuracy(Item)
-- get weapon accuracy.

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList)
	do
		return round(Weap.accuracy,3)
	end

	return
end

function This:ModWeaponAccuracy(Item,Per)
-- modify the accuracy by a percent

	This:BumpWeaponNameMark(Item)

	local WeapList = {Item:getWeapons()}
	local Value = 0
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
		Value = ((Weap.accuracy * (Per / 100)) + Weap.accuracy)

		if(Value < 0) then
			Value = 0.0
		elseif(Value > 1) then
			Value = 1.0
		end

		Weap.accuracy = Value
		Item:addWeapon(Weap)
	end

	return
end

--------

function This:GetWeaponEfficiency(Item)
-- get weapon accuracy, autodetecting mining or scav.

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList)
	do
		if(Item.category == WeaponCategory.Mining) then
			if(Weap.stoneRawEfficiency > 0.0) then
				return round(Weap.stoneRawEfficiency,5)
			else
				return round(Weap.stoneRefinedEfficiency,5)
			end
		elseif(Item.category == WeaponCategory.Salvaging) then
			if(Weap.metalRawEfficiency > 0.0) then
				return round(Weap.metalRawEfficiency,5)
			else
				return round(Weap.metalRefinedEfficiency,5)
			end
		else
			return 0
		end
	end

	return
end

function This:ModWeaponEfficiency(Item,Per)
-- modify the accuracy by a percent, autodetecting mining or scav.

	This:BumpWeaponNameMark(Item)

	local WeapList = {Item:getWeapons()}
	local Value = 0
	local Initial = 0
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do

		if(Item.category == WeaponCategory.Mining) then
			if(Weap.stoneRawEfficiency > 0.0) then
				Initial = Weap.stoneRawEfficiency
			else
				Initial = Weap.stoneRefinedEfficiency
			end
		elseif(Item.category == WeaponCategory.Salvaging) then
			if(Weap.metalRawEfficiency > 0.0) then
				Initial = Weap.metalRawEfficiency
			else
				Initial = Weap.metalRefinedEfficiency
			end
		end

		Value = ((Initial * (Per / 100)) + Initial)

		if(Value < 0) then
			Value = 0.0
		elseif(Value > 1) then
			Value = 1.0
		end

		-- it appears there is a bug where stone and metal eff may not be
		-- included in the decision on if items should stack or not. so,
		-- we will also include a super stupid damage increase until koon
		-- gets back with me on it.

		if(Item.category == WeaponCategory.Mining) then
			print("[DccTurretEditor] Modding Mining Gun: " .. Item.weaponName .. " " .. Initial .. " " .. Value)
			if(Weap.stoneRawEfficiency > 0.0) then
				Weap.stoneRawEfficiency = Value
			else
				Weap.stoneRefinedEfficiency = Value
			end
		elseif(Item.category == WeaponCategory.Salvaging) then
			print("[DccTurretEditor] Modding Scav Gun: " .. Item.weaponName .. " " .. Initial .. " " .. Value)
			if(Weap.metalRawEfficiency > 0.0) then
				Weap.metalRawEfficiency = Value
			else
				Weap.metalRefinedEfficiency = Value
			end
		end

		Item:addWeapon(Weap)
	end

	return
end

--------

function This:GetWeaponColour(Item)
-- get what colour this turret

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList) do
		if(Weap.isProjectile) then
			return Weap.pcolor
		else
			return Weap.binnerColor
		end
	end

	return
end

function This:SetWeaponColour(Item,Colour)
-- modify the fire rate by a percent

	This:BumpWeaponNameMark(Item)

	local WeapList = {Item:getWeapons()}
	local Value = 0
	Item:clearWeapons()

	-- screw with the colours the player set a little bit to create something
	-- that visually looks slightly nicer in practice.

	local Colour1 = Color()
	local Colour2 = Color()

	Colour1:setHSV(
		Colour.hue,
		(Colour.saturation * Config.Colour1Mod.Sat),
		(Colour.value * Config.Colour1Mod.Val)
	)

	Colour2:setHSV(
		Colour.hue,
		(Colour.saturation * Config.Colour2Mod.Sat),
		(Colour.value * Config.Colour2Mod.Val)
	)

	for WeapIter,Weap in pairs(WeapList) do

		if(Weap.isProjectile) then
			Weap.pcolor = Colour2
		else
			Weap.binnerColor = Colour1
			Weap.bouterColor = Colour2
		end

		Item:addWeapon(Weap)
	end

	return
end

--------------------------------------------------------------------------------
-- these ones need to deal with the turret as a whole --------------------------

function This:GetWeaponRarityValue(Item)
-- get the rarity value we can use for math.

	-- petty items start at -1 for some reason. i am not even sure the
	-- game drops them. oh nvm yes it does, they are dark grey i always
	-- forget that.

	local Value = 1

	if(Item.rarity.value == RarityType.Petty) then
		Value = 0.5
	elseif(Item.rarity.value == RarityType.Common) then
		Value = 1
	elseif(Item.rarity.value == RarityType.Uncommon) then
		Value = 2
	elseif(Item.rarity.value == RarityType.Rare) then
		Value = 3
	elseif(Item.rarity.value == RarityType.Exceptional) then
		Value = 4
	elseif(Item.rarity.value == RarityType.Exotic) then
		Value = 5
	elseif(Item.rarity.value == RarityType.Legendary) then
		Value = 6
	end

	return Value
end

--------

function This:GetWeaponCategory(Item)
-- returns the WeaponType

	return Item.category
end

--------

function This:GetWeaponHeatRate(Item)
-- get the heat per shot of this item.

	return round(Item.heatPerShot,3)
end

function This:ModWeaponHeatRate(Item,Per)
-- modify the heat per shot value by a percent.

	This:BumpWeaponNameMark(Item)

	local Value = ((Item.heatPerShot * (Per / 100)) + Item.heatPerShot)

	if(Value < 0) then
		Value = 0
	end

	Item.heatPerShot = Value
	return
end

--------

function This:GetWeaponCoolRate(Item)
-- get the cooling rate for this turret.

	return round(Item.coolingRate,3)
end

function This:ModWeaponCoolRate(Item,Per)
-- modify the cooling rate value by a percent.

	This:BumpWeaponNameMark(Item)

	local Value = ((Item.coolingRate * (Per / 100)) + Item.coolingRate)

	if(Value < 0) then
		Value = 0
	end

	Item.coolingRate = Value
	return
end

--------

function This:GetWeaponMaxHeat(Item)
-- get the max heat for this turret.

	return round(Item.maxHeat,3)
end

function This:ModWeaponMaxHeat(Item,Per)
-- modify the max heat value by a percent.

	This:BumpWeaponNameMark(Item)

	local Value = ((Item.maxHeat * (Per / 100)) + Item.maxHeat)

	if(Value < 0) then
		Value = 0
	end

	Item.maxHeat = Value
	return
end

--------

function This:GetWeaponBaseEnergy(Item)
-- get the base energy per second.

	return round(Item.baseEnergyPerSecond,3)
end

function This:ModWeaponBaseEnergy(Item,Per)
-- modify the base energy value by a percent.

	This:BumpWeaponNameMark(Item)

	local Value = ((Item.baseEnergyPerSecond * (Per / 100)) + Item.baseEnergyPerSecond)

	if(Value < 0) then
		Value = 0
	end

	Item.baseEnergyPerSecond = Value
	return
end

--------

function This:GetWeaponAccumEnergy(Item)
-- get the energy accumulation over time.

	return round(Item.energyIncreasePerSecond,3)
end

function This:ModWeaponAccumEnergy(Item,Per)
-- modify the energy accumulation value by a percent.

	This:BumpWeaponNameMark(Item)

	local Value = ((Item.energyIncreasePerSecond * (Per / 100)) + Item.energyIncreasePerSecond)

	if(Value < 0) then
		Value = 0
	end

	Item.energyIncreasePerSecond = Value
	return
end

--------

function This:GetWeaponSpeed(Item)
-- get the turret tracking speed

	return round(Item.turningSpeed,3)
end

function This:ModWeaponSpeed(Item,Per)
-- modify the tracking speed value by a percent.

	This:BumpWeaponNameMark(Item)

	local Value = ((Item.turningSpeed * (Per / 100)) + Item.turningSpeed)

	if(Value < 0) then
		Value = 0
	end

	Item.turningSpeed = Value
	return
end

--------

function This:GetWeaponCoaxial(Item)
--- get if this is a coaxial weapon.

	return Item.coaxial
end

function This:SetWeaponCoaxial(Item,Val)
-- set automatic targeting.

	-- this is getting done by the damage mod
	-- This:BumpWeaponNameMark(Item)

	Item.coaxial = Val

	-- from the weapon generator script:
	-- coaxialDamageScale = turret.coaxial and 3 or 1

	if(Item.coaxial) then
		-- buff damage 3x
		This:ModWeaponDamage(Item,200)
	else
		-- debuff damage 3x
		This:ModWeaponDamage(Item,-66.6666)
	end

	return
end
	
function This:ToggleWeaponCoaxial(Item)
-- set automatic targeting.

	This:SetWeaponCoaxial(Item,(not Item.coaxial))

	return
end

--------

function This:GetWeaponSize(Item)
--- get this turret's size

	return Item.size
end

function This:SetWeaponSize(Item,Val)
-- set this turret's size

	This:BumpWeaponNameMark(Item)

	Item.size = Val

	return
end

--------

function This:GetWeaponTargeting(Item)
-- get turret targeting.

	return Item.automatic
end

function This:SetWeaponTargeting(Item,Val)
-- set automatic targeting.

	This:BumpWeaponNameMark(Item)

	Item.automatic = Val
	return
end

function This:ToggleWeaponTargeting(Item)
-- set automatic targeting.

	This:BumpWeaponNameMark(Item)

	Item.automatic = not Item.automatic
	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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

return This