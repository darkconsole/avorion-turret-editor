
local This = {};
local Config = include("mods/DccTurretEditor/Common/ConfigLib")

function This:CreatePaymentTable()

	local Key = 1
	local Payment = {}

	for Key = 1, MaterialType.Avorion+2
	do Payment[Key] = 0 end

	Payment.SetMoney = function(self,Amount)
		self[1] = Amount
		return self
	end

	Payment.SetMaterial = function(self,MatType,Amount)
		self[MatType+2] = Amount
		return self
	end

	return Payment
end

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

function This:PlayerPay(PlayerID,PaymentTable)
	if(onClient()) then
		return invokeServerFunction(
			"TurretLib_ServerCallback_PlayerPay",
			PlayerID,
			PaymentTable
		)
	end
end

function TurretLib_ServerCallback_PlayerPay(PlayerID,PaymentTable)

	Player(PlayerID):pay("",unpack(PaymentTable))
	return
end

callable(nil,"TurretLib_ServerCallback_PlayerPay")

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

--------

function This:IsFinite(Value)
-- avorion does not seem to have access to math.finite, isinf, or isnan.

	local STT = tostring(Value):lower()

	if
		STT == "inf" or STT == "nan"
		or STT == "1.#inf" or STT == "1.#ind"
		or STT == "-1.#inf" or STT == "-1.#ind"
		or STT == "#inf" or STT == "#ind"
	then
		return false
	end

	return true
end

function This:GetMaterialTypeByMaterial(Input)
-- this may seem stupid but there appears to be no way to get the MaterialType
-- out of a fucking Material object lmao.

	local MatType = 1
	local Mat = nil

	for MatType=0, MaterialType.Avorion do
		Mat = Material(MatType)

		if(Mat == Input) then
			return MatType
		end
	end

	return nil
end

--------------------------------------------------------------------------------
-- these ones need to deal with each individual weapon on the turret -----------

function This:GetWeaponType(Item)
-- returns type depending on turret

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList) do

		if(Weap.appearance == WeaponAppearance.RailGun) then
			return "projectile"
		end
		if(Weap.hullRepair > 0) or (Weap.shieldRepair > 0) then 
			return "healing" 
		end
		if(Weap.otherForce ~= 0) or (Weap.selfForce ~= 0) then 
			return "force" 
		end
		if(Weap.isProjectile) then
			return "projectile"
		else
			return "beam"
		end
		
	end

	--return
end

function This:GetWeaponRealType(Item)
-- returns apperance

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList) do
		return Weap.appearance
	end

	return
end

function This:BumpWeaponNameMark(Item)
-- bump the mark names on weapons. we do this mainly to trick the game into
-- never stacking the items.

	local WeapList = {Item:getWeapons()}
	local Mark
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do

		print("[DccTurretLib:BumpWeaponNameMark] Old: " .. Weap.name .. ", Prefix: " .. Weap.prefix)

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

function This:RenameWeapon(Item,ToFind,ToReplace)
-- do a find replace on weapon names.

	local WeapList = {Item:getWeapons()}
	local Count
	Item:clearWeapons()

	ToFind = string.gsub(ToFind,"%-","%%-")

	for WeapIter,Weap in pairs(WeapList) do
		Weap.name,Count = string.gsub(Weap.name,ToFind,ToReplace)
		Weap.prefix = string.gsub(Weap.prefix,ToFind,ToReplace)
		print("[DccTurretLib:RenameWeapon] Old: " .. Weap.name .. " (" .. Weap.prefix .. "), ToFind: " .. ToFind .. ", ToReplace: " .. ToReplace .. ", " .. Count)
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

function This:HasBeenModified(Item)
-- determine if we have edited a turret before.

	local WeapList = {Item:getWeapons()}
	local Weap
	local Mark

	for WeapIter,Weap in pairs(WeapList) do
		Mark = string.match(Weap.name," Mk (%d+)$")
		if(Mark == nil) then
			return false
		else
			return true
		end
	end
end

function This:IsDefaultTargetingNerfFixable(Item)
-- determine if this turret should be allowed to have its damage unnerfed.

	local Result = false
	local WeapList = {Item:getWeapons()}
	local Weap = nil

	if(Item.automatic) then
		if(Config.FixDefaultTargetingNerf ~= 0.0) then
			for WeapIter,Weap in pairs(WeapList) do
				Mark = string.match(Weap.name," Mk (%d+)$")
				if(Mark == nil) then
					Result = true
				end
			end
		end
	end

	if(Result == true) then
		print("[DccTurretLib:IsDefaultTargetingNerfFixable] " .. Item.weaponName .. " eligable for getting un-nerfed")
	end

	return Result
end

function This:FixDefaultTargetingNerf(Item)
-- determine if this turret should be allowed to have its damage unnerfed.

	local WeapList = {Item:getWeapons()}
	local Weap = nil
	local WeapIter = nil
	local Infos = nil
	local InfoIter = nil
	local InfoText = nil

	Item:clearWeapons()

	if(Config.FixDefaultTargetingNerf ~= 0.0) then
		for WeapIter,Weap in pairs(WeapList) do

			Mark = string.match(Weap.name," Mk (%d+)$")
			if(Mark == nil) then
				print("[DccTurretLib:FixDefaultTargetingNerf] un-nerfing " .. Weap.name .. " on " .. Item.weaponName)

				-- fix base damage.
				Weap.damage = Weap.damage * Config.FixDefaultTargetingNerf

				-- fix shield turrets.
				if Weap.shieldRepair ~= 0. then
					Weap.shieldRepair = Weap.shieldRepair * Config.FixDefaultTargetingNerf
				end

				-- fix hull turrets.
				if Weap.hullRepair ~= 0.0 then
					Weap.hullRepair = Weap.hullRepair * Config.FixDefaultTargetingNerf
				end
			end

			Item:addWeapon(Weap)
		end

		-- clear out the description they set for these now.

		Infos = Item:getDescriptions()
		Item:clearDescriptions()
		Item:addDescription("[WeapEng] Indep. Targeting Unnerfed","")

		for InfoIter,InfoText in pairs(Infos) do
			if(InfoIter ~= "Indep. Targeting: %s%% Damage"%_T) then
				Item:addDescription(InfoIter,InfoText)
			end
		end
	end

	return
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

function This:ModWeaponFireRate(Item,Per,Dont)
-- modify the fire rate by a percent

	local WeapList = {Item:getWeapons()}
	local Value = 0
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
		Value = ((Weap.fireRate * (Per / 100)) + Weap.fireRate)

		if(Value < 0) then
			Value = 0
		end

		if(Dont == true) then return Value end

		Weap.fireRate = Value
		Item:addWeapon(Weap)
	end

	return
end

function This:SetWeaponFireRate(Item,Value)
-- modify the fire rate by a percent

	local WeapList = {Item:getWeapons()}
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
		if(Value < 0) then
			Value = 0
		end

		Weap.fireRate = Value
		Item:addWeapon(Weap)
	end

	return
end

--------

function This:GetWeaponProjectileSize(Item,Value)
-- get the projectile size

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList) do
		return round(Weap.psize,3)
	end

	return
end

function This:SetWeaponProjectileSize(Item,Value)
-- set the projectile size

	local WeapList = {Item:getWeapons()}
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
		if(Value < 0) then
			Value = 0
		end

		Weap.psize = Value
		Item:addWeapon(Weap)
	end

	return
end

--------

function This:GetWeaponProjectileSpeed(Item)
-- get how fast this turret projectile flies

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList) do
		if(Weap.pvelocity == nil) then
			return nil
		end

		return round(Weap.pvelocity,3)
	end

	return
end

function This:ModWeaponProjectileSpeed(Item,Per,Dont)
--  mod how fast this turret projectile flies

	local WeapList = {Item:getWeapons()}
	local Value = 0
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
		Value = ((Weap.pvelocity * (Per / 100)) + Weap.pvelocity)

		if(Value < 0) then
			Value = 0
		end

		if(Dont == true) then return Value end

		Weap.pvelocity = Value
		Item:addWeapon(Weap)
	end

	return
end

function This:SetWeaponProjectileSpeed(Item,Value)
--  set how fast this turret projectile flies

	local WeapList = {Item:getWeapons()}
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
		if(Value < 0) then
			Value = 0
		end

		Weap.pvelocity = Value
		Item:addWeapon(Weap)
	end

	return
end

--------

function This:GetWeaponTechLevel(Item)
-- get this weapon's tech level

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList) do
		return Weap.tech
	end

	return
end

function This:ModWeaponTechLevel(Item,Per,Dont)
-- modify this weapon's tech level

	local WeapList = {Item:getWeapons()}
	local Value = 0
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
		Value = ((Weap.tech * (Per / 100)) + Weap.tech)

		if(Value < 0) then
			Value = 0
		end

		if(Dont == true) then return Value end

		Weap.tech = Value
		Item:addWeapon(Weap)
	end

	return
end

function This:SetWeaponTechLevel(Item,Value)
-- set this weapon's tech level

	local WeapList = {Item:getWeapons()}
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
		if(Value < 0) then
			Value = 0
		end

		Weap.tech = Value
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

function This:ModWeaponRange(Item,Per,Dont)
-- modify the range by a percent

	local WeapList = {Item:getWeapons()}
	local Value = 0
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
		Value = ((Weap.reach * (Per / 100)) + Weap.reach)

		if(Value < 0) then
			Value = 0
		end

		if(Dont == true) then return Value / 100 end

		Weap.reach = Value
		Item:addWeapon(Weap)
	end

	return
end

function This:SetWeaponRange(Item,Value)
-- set the range by a percent

	Value = Value * 100

	local WeapList = {Item:getWeapons()}
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
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
-- get weapon damage/force/healing
	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList)
	do
		
		if(Weap.hullRepair > 0 ) then return round(Weap.hullRepair,3) else
		if(Weap.otherForce ~= 0) then return round(Weap.otherForce,3) else
		return round(Weap.damage,3) end end
	end

	return
end

function This:ModWeaponDamage(Item,Per,Dont)
-- modify the damage/force/healing by a percent

	local WeapList = {Item:getWeapons()}
	local Value = 0
	local ValueH = 0
	local ValueF = 0
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
		Value = ((Weap.damage * (Per / 10)) + Weap.damage)
		ValueH = ((Weap.hullRepair * (Per / 10)) + Weap.hullRepair)
		ValueF = ((Weap.otherForce * (Per / 10)) + Weap.otherForce)
		
		
		if(Value < 0) then
			Value = 0
		end
		if(ValueH < 0) then
			ValueH = 0
		end

		if(Dont == true) then return Value end

		Weap.damage = Value
		Weap.hullRepair = ValueH
		Weap.otherForce = ValueF
		Item:addWeapon(Weap)
	end

	return
end

function This:SetWeaponDamage(Item,Value)
-- set the damage/force/healing by a percent

	local WeapList = {Item:getWeapons()}
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
		if(Value < 0) then
			Value = 0
		end
		if(ValueH < 0) then
			ValueH = 0
		end

		Weap.damage = Value
		Weap.hullRepair = ValueH
		Weap.otherForce = ValueF
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

function This:ModWeaponAccuracy(Item,Per,Dont)
-- modify the accuracy

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

		if(Dont == true) then return Value end

		Weap.accuracy = Value
		Item:addWeapon(Weap)
	end

	return
end

function This:SetWeaponAccuracy(Item,Value)
-- set the accuracy by a percent

	local WeapList = {Item:getWeapons()}
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do

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

function This:GetWeaponExplosion(Item)
-- get weapon explosion radius.

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList)
	do
		return round(Weap.explosionRadius,3)
	end

	return
end

function This:ModWeaponExplosion(Item,Per,Dont)
-- modify the explosion by a percent

	local WeapList = {Item:getWeapons()}
	local Value = 0
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
		Value = ((Weap.explosionRadius * (Per / 100)) + Weap.explosionRadius)

		if(Value < 0) then
			Value = 0.0
		end

		if(Dont == true) then return Value end

		Weap.explosionRadius = Value
		Item:addWeapon(Weap)
	end

	return
end

function This:SetWeaponExplosion(Item,Value)
-- set the explosion radius

	local WeapList = {Item:getWeapons()}
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do

		if(Value < 0) then
			Value = 0.0
		end

		Weap.explosionRadius = Value
		Item:addWeapon(Weap)
	end

	return
end

--------

function This:GetWeaponEfficiencyS(Item)
-- get weapon stone efficiency/healing/forceSelf

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList)do
		if(Weap.shieldRepair > 0 ) then return round(Weap.shieldRepair,3) end
		if(Weap.selfForce ~= 0) then return round(Weap.selfForce,3)	end	
		if(Weap.stoneRawEfficiency > 0) 
			then return round(Weap.stoneRawEfficiency,3)
			else return round(Weap.stoneRefinedEfficiency,3)
		end
	end
end
function This:GetWeaponEfficiencyM(Item)
-- get weapon metal efficiency

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList)do 
	if(Weap.metalRawEfficiency > 0) then
		round(Weap.metalRawEfficiency,5)
		return round(Weap.metalRawEfficiency,3)
		else round(Weap.metalRefinedEfficiency,5)
		return round(Weap.metalRefinedEfficiency,3)
	end
	end
	return
end

function This:ModWeaponEfficiencyS(Item,Per,Dont)
-- modify the stone efficiency/healing/forceSelf by a percent

	local WeapList = {Item:getWeapons()}
	local ValueS = 0
	local ValueH = 0
	local ValueF = 0
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do	
	ValueH = ((Weap.shieldRepair * (Per / 10)) + Weap.shieldRepair)
	ValueF = ((Weap.selfForce * (Per / 10)) + Weap.selfForce)
	if(Weap.stoneRawEfficiency > 0) then
		ValueS = ((Weap.stoneRawEfficiency * (Per / 10)) + Weap.stoneRawEfficiency)
		else 
		ValueS = ((Weap.stoneRefinedEfficiency * (Per / 10)) + Weap.stoneRefinedEfficiency)
		end

		if(ValueS < 0) then
			ValueS = 0.0
		elseif(ValueS > 1) then
			ValueS = 1.0
		end
		if(ValueH < 0) then
			ValueH = 0
		end
		
		if(Dont == true) then return ValueS end

		if(Weap.stoneRawEfficiency > 0) then
			print(" Modding Mining : " .. Item.weaponName .. " " .. Weap.stoneRawEfficiency .. " " .. ValueS)
			
				Weap.stoneRawEfficiency = ValueS
				else
				print(" Modding Mining : " .. Item.weaponName .. " " .. Weap.stoneRefinedEfficiency .. " " .. ValueS)
			
				Weap.stoneRefinedEfficiency = ValueS
			end
		Weap.shieldRepair = ValueH
		Weap.selfForce = ValueF
		
		Item:addWeapon(Weap)
	end
	return
end

function This:ModWeaponEfficiencyM(Item,Per,Dont)
-- modify the metal efficiency by a percent

	local WeapList = {Item:getWeapons()}
	local ValueM = 0
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList) do
	if(Weap.metalRawEfficiency > 0) then
		ValueM = ((Weap.metalRawEfficiency * (Per / 10)) + Weap.metalRawEfficiency)
		else 
		ValueM = ((Weap.metalRefinedEfficiency * (Per / 10)) + Weap.metalRefinedEfficiency)
		end

		if(ValueM < 0) then
			ValueM = 0.0
		elseif(ValueM > 1) then
			ValueM = 1.0
		end

		if(Dont == true) then return ValueM end

		if(Weap.metalRawEfficiency > 0) then
			
			print(" Modding Salvaging : " .. Item.weaponName .. " " .. Weap.metalRawEfficiency .. " " .. ValueM)
			
				Weap.metalRawEfficiency = ValueM
				else
				print(" Modding Salvaging : " .. Item.weaponName .. " " .. Weap.metalRefinedEfficiency .. " " .. ValueM)
			
				Weap.metalRefinedEfficiency = ValueM
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
-- modify the colour of this turret

	local WeapList = {Item:getWeapons()}
	local Value = 0
	Item:clearWeapons()

	-- screw with the colours the player set a little bit to create something
	-- that visually looks slightly nicer in practice.

	-- todo: ask for access to colour explosions.

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

		--if(Weap.isProjectile) then
			Weap.pcolor = Colour2
		--else
			Weap.binnerColor = Colour1
			Weap.bouterColor = Colour2
		--end

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

function This:GetWeaponRarityWord(Item)
-- fetch the word that defines this rarity.

	return Rarity(Item.rarity.value).name
end

--------

function This:GetWeaponCategory(Item)
-- returns the WeaponCategory

	return Item.category
end

--------

function This:GetWeaponHeatRate(Item)
-- get the heat per shot of this item.

	return round(Item.heatPerShot,3)
end

function This:ModWeaponHeatRate(Item,Per,Dont)
-- modify the heat per shot value by a percent.

	local Value = ((Item.heatPerShot * (Per / 100)) + Item.heatPerShot)

	if(Value < 0) then
		Value = 0
	end

	if(Dont == true) then return Value end

	This:SetWeaponHeatRate(Item,Value)
	return
end

function This:SetWeaponHeatRate(Item,Value)
-- set the heat rate for this turret.

	if(Value <= 0) then
		Value = 0
	end

	Item.heatPerShot = Value

	-- thanks to the LNCS players found the cause of a game error
	-- where fighter factories end up paying you for a turret. if
	-- heat sinks zero'd our (or near) enough but the heat
	-- generator value is still non zero their math would explode.
	-- but then when they applied the cooling system that would fix it.
	-- this was due to the vanilla scripts as of 2020-11-09 incorrectly
	-- checking for failed math and then doing more math on it. the cause
	-- was basically, "yes, this gun generates heat, but it can still
	-- "shoot forever" - so when you cross that threshold, we will correct
	-- this so vanilla scripts play nice. if it *can* shoot forever then
	-- the heat generation is pointless anyway.

	if(not This:IsFinite(Item.shootingTime)) then
		Item.heatPerShot = 0.0
		Item.coolingRate = 1.0
		Item.maxHeat = 0.0
		Item.coolingType = CoolingType.Standard
		Item:addDescription("[WeapEng] Fighter Factory Fix Applied (Heat Sinks)","")
	end

	return
end

--------

function This:GetWeaponCoolRate(Item)
-- get the cooling rate for this turret.

	return round(Item.coolingRate,3)
end

function This:ModWeaponCoolRate(Item,Per,Dont)
-- modify the cooling rate value by a percent.

	local Value = ((Item.coolingRate * (Per / 100)) + Item.coolingRate)

	if(Value < 0) then
		Value = 0
	end

	if(Dont == true) then return Value end

	Item.coolingRate = Value
	return
end

function This:SetWeaponCoolRate(Item,Value)
-- set the cooling rate for this turret.


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

function This:ModWeaponMaxHeat(Item,Per,Dont)
-- modify the max heat value by a percent.

	local Value = ((Item.maxHeat * (Per / 100)) + Item.maxHeat)

	if(Value < 0) then
		Value = 0
	end

	if(Dont == true) then return Value end

	Item.maxHeat = Value
	return
end

function This:SetWeaponMaxHeat(Item,Value)
-- set a weapon's max heat.

	if(Value < 0) then
		Value = 0
	end

	Item.maxHeat = Value
	return
end

--------

function This:GetWeaponCoolingType(Item)
-- get weapon's cooling type
	
	return Item.coolingType
end

function This:SetWeaponCoolingType(Item,Value)
-- set a weapon's cooling type

	if(Value < 0) then
		Value = 0
	end

	Item.coolingType = Value
	return
end

--------

function This:GetWeaponBaseEnergy(Item)
-- get the base energy per second.

	return round(Item.baseEnergyPerSecond,3)
end

function This:ModWeaponBaseEnergy(Item,Per,Dont)
-- modify the base energy value by a percent.

	local Value = ((Item.baseEnergyPerSecond * (Per / 100)) + Item.baseEnergyPerSecond)

	if(Value < 0) then
		Value = 0
	end

	if(Dont == true) then return Value end

	Item.baseEnergyPerSecond = Value
	return
end

function This:SetWeaponBaseEnergy(Item,Value)
-- set the base energy value by a percent.

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

function This:ModWeaponAccumEnergy(Item,Per,Dont)
-- modify the energy accumulation value by a percent.

	local Value = ((Item.energyIncreasePerSecond * (Per / 100)) + Item.energyIncreasePerSecond)

	if(Value < 0) then
		Value = 0
	end

	if(Dont == true) then return Value end

	Item.energyIncreasePerSecond = Value
	return
end

--------

function This:GetWeaponSpeed(Item)
-- get the turret tracking speed

	return round(Item.turningSpeed,3)
end

function This:ModWeaponSpeed(Item,Per,Dont)
-- modify the tracking speed value by a percent.

	local Value = ((Item.turningSpeed * (Per / 100)) + Item.turningSpeed)

	if(Value < 0) then
		Value = 0
	end

	if(Dont == true) then return Value end

	Item.turningSpeed = Value
	return
end

function This:SetWeaponSpeed(Item,Value)
-- set the turret tracking speed.

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
-- set coaxiality

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
-- set automatic targeting

	This:SetWeaponCoaxial(Item,(not Item.coaxial))

	return
end

--------

function This:GetWeaponSize(Item)
-- get this turret's size

	return Item.size
end

function This:SetWeaponSize(Item,Val)
-- set this turret's size

	Item.size = Val
	This:SetWeaponProjectileSize(Item,Val)
	return
end

--------

function This:GetWeaponSlots(Item)
-- get this turret's slots
	
	return Item.slots
end

function This:SetWeaponSlots(Item,Val)
-- set this turret's slots

	if(Val < 0) then
		-- we can totally make 0 slot turrets and it will let us mount as
		-- many as we want lol.
		Val = 0
	end

	Item.slots = Val
	return
end

--------

function This:GetWeaponTargeting(Item)
-- get turret targeting.

	return Item.automatic
end

function This:SetWeaponTargeting(Item,Val)
-- set automatic targeting.

	-- if the turret has targeting, and we want to turn it off, and it is the first time
	-- the turret has been edited, then we are going to undo the damage reduction they
	-- gave automatics by default.

	if(Val == false and This:IsDefaultTargetingNerfFixable(Item)) then
		This:FixDefaultTargetingNerf(Item)
	end

	Item.automatic = Val
	return
end

function This:ToggleWeaponTargeting(Item)
-- set automatic targeting.

	This:SetWeaponTargeting(Item,(not Item.automatic))
	return
end

--------

function This:GetWeaponMaterial(Item)
-- get the weapon material

	return Item.material
end

function This:GetWeaponMaterialType(Item)
-- get the weapon material type

	return This:GetMaterialTypeByMaterial(Item.material)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function This:GetWeaponCrew(Item)
-- get required crew. if its a civil cannon it returns the miner count and if
-- an offensive weapon it returns the gunner count.

	return Item.crew.gunners
end

function This:SetWeaponCrew(Item,Val)
-- set required crew. if a civil cannon it sets the miner count and if an
-- offensive weapon it sets the gunner count.

	local Gunners = Crew()
	Gunners:add(Val,CrewMan(CrewProfessionType.Gunner))

	Item.crew = Gunners
	return
end

return This
