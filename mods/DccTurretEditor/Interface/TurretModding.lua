--[[----------------------------------------------------------------------------
AVORION: Turret Modding UI
darkconsole <darkcee.legit@gmail.com>

This script handles the UI for the Engineering Weapons Bay.
----------------------------------------------------------------------------]]--



--------------------------------------------------------------------------------

package.path = package.path
.. ";data/scripts/lib/?.lua"
.. ";data/scripts/sector/?.lua"
.. ";data/scripts/?.lua"

require("galaxy")
require("utility")
require("faction")
require("player")
require("randomext")
require("stringutility")
require("callable")

local This = {}
local SellableInventoryItem = require("sellableinventoryitem")
local TurretLib = require("mods.DccTurretEditor.Common.TurretLib")
local Config = nil

function PrintServer(TheMessage)
-- only print this message on the server.

	if(onServer()) then
		print("[DccTurretEditor] " .. TheMessage)
	end

	return
end

function PrintDebug(TheMessage)
-- show debugging messages in the console.

	if(Config.Debug) then
		print("[DccTurretEditor] " .. TheMessage)
	end

	return
end

function PrintError(TheMessage)
-- show error messages to the user.

	displayChatMessage(TheMessage,"DccTurretEditor",1)
	return
end

function PrintInfo(TheMessage)
-- show info messages to the user.

	displayChatMessage(TheMessage,"DccTurretEditor",3)
	return
end

function PrintWarning(TheMessage)
-- show info messages to the user.

	displayChatMessage(TheMessage,"DccTurretEditor",2)
	return
end

-- utility functions.

function FramedRect(Container,X,Y,Cols,Rows,Padding)
-- for this trained rekt. give it a container you want to grid things out into
-- the column,row you are trying to put the thing in, how many columns and rows
-- there should be, and optionally padding. get a rect that will work sometimes.

	if(Padding == nil)
	then Padding = 4 end

	local TopLeft = vec2(
		(Container.rect.topLeft.x + ((Container.rect.width / Cols) * (X - 1))) + Padding,
		(Container.rect.topLeft.y + ((Container.rect.height / Rows) * (Y - 1))) + Padding
	)

	local BottomRight = vec2(
		(TopLeft.x + (Container.rect.width / Cols)) - (Padding*2),
		(TopLeft.y + (Container.rect.height / Rows)) - (Padding*2)
	)

	return Rect(TopLeft,BottomRight)
end

PrintServer("TURRET MODDING UI LOAD")
--------------------------------------------------------------------------------

local Win = {
	Title = "Engineering: Weapons Bay",
	UI = nil,
	Res = nil,
	Size = nil,

	-- click selection id.
	-- the ui api really was not expecting anyone to do more than two
	-- selections per window so i have to track where drags start from as its
	-- not sent as an argument
	CurrentSelectID = nil,

	-- the window itself.
	Window = nil,

	-- the item we wish to mod.
	Item      = nil,
	ItemLabel = nil,

	-- the items we will scrap.
	Bin      = nil,
	BinLabel = nil,

	-- the player's inventory.
	Inv      = nil,
	InvLabel = nil

}

function Win:OnInit()

	self.Res = getResolution()
	self.Size = vec2(1200,700)
	self.UI = ScriptUI(Player().craftIndex)

	self.Window = self.UI:createWindow(Rect(
		(self.Res * 0.5 - self.Size * 0.5),
		(self.Res * 0.5 + self.Size * 0.5)
	))

	self.Window.caption = self.Title
	self.Window.showCloseButton = 1
	self.Window.moveable = 1
	self.UI:registerWindow(self.Window,self.Title)

	self:BuildUI()
	return
end

function Win:BuildUI()

	local Pane = UIHorizontalSplitter(
		Rect(self.Window.size),
		10, 10, 0.6
	)

	local BPane = UIHorizontalSplitter(
		Pane.top,
		0, 0, 0.5
	)

	local TPane = UIVerticalSplitter(
		BPane.top,
		0, 0, 0.35
	)

	local TLPane = UIHorizontalSplitter(
		TPane.left,
		0, 0, 0.5
	)

	local TRPane = UIHorizontalSplitter(
		TPane.right,
		4, 0, 0.5
	)

	local TRLister = UIVerticalLister(
		TPane.left,
		0, 0
	)

	local FontSize1 = 20
	local FontSize2 = 14
	local FontSize3 = 12
	local LineHeight1 = FontSize1 + 4

	-- create the drop target for the editor.

	self.Item = self.Window:createSelection(Rect(0,0,128,128),1)
	self.Item.dropIntoEnabled = 1
	self.Item.entriesSelectable = 0
	self.Item.onClickedFunction = "TurretModdingUI_OnItemClicked"
	self.Item.onReceivedFunction = "TurretModdingUI_OnItemAdded"
	TLPane:placeElementCenter(self.Item)

	self.ItemLabel = self.Window:createLabel(
		self.Item.position,
		"Selected Turret",
		(FontSize1 - 4)
	)
	self.ItemLabel.centered = true
	self.ItemLabel.width = self.Item.width
	self.ItemLabel.position = self.Item.position - vec2(0,LineHeight1)

	-- create the scrap bin

	self.Bin = self.Window:createSelection(Rect(0,0,500,104),5)
	self.Bin.dropIntoEnabled = 1
	self.Bin.entriesSelectable = 0
	self.Bin.onClickedFunction = "TurretModdingUI_OnBinClicked"
	self.Bin.onReceivedFunction = "TurretModdingUI_OnBinAdded"
	TRPane:placeElementCenter(self.Bin)

	self.BinLabel = self.Window:createLabel(
		self.Bin.position,
		"Turrets To Scrap",
		(FontSize1 - 4)
	)
	self.BinLabel.centered = true
	self.BinLabel.width = self.Bin.width
	self.BinLabel.position = self.Bin.position - vec2(0,LineHeight1)

	-- create the list of things in your inventory

	self.Inv = self.Window:createSelection(Pane.bottom,16)
	self.Inv.dropIntoEnabled = 1
	self.Inv.entriesSelectable = 0
	self.Inv.onClickedFunction = "TurretModdingUI_OnInvClicked"
	self.Inv.onReceivedFunction = "TurretModdingUI_OnInvAdded"

	-- buttons don't place well so we alter their rects after creating.

	self.UpgradeFrame = self.Window:createFrame(BPane.bottom)
	local Rows = 7
	local Cols = 5

	local Hint, HintLine

	--------

	self.BtnHeat = self.Window:createButton(
		Rect(),
		"Heat Sinks",
		"TurretModdingUI_OnClickedBtnHeat"
	)
	self.BtnHeat.textSize = FontSize3
	self.BtnHeat.rect = FramedRect(self.UpgradeFrame,1,1,Cols,Rows)
	self.BtnHeat.tooltip = "Reduce the heat generated, increase cooldown rate."

	self.LblHeat = self.Window:createLabel(
		Rect(),
		"$HEAT",
		FontSize3
	)
	self.LblHeat.rect = FramedRect(self.UpgradeFrame,1,2,Cols,Rows)
	self.LblHeat.centered = true

	--------

	self.BtnBaseEnergy = self.Window:createButton(
		Rect(),
		"Capacitors",
		"TurretModdingUI_OnClickedBtnBaseEnergy"
	)
	self.BtnBaseEnergy.textSize = FontSize3
	self.BtnBaseEnergy.rect = FramedRect(self.UpgradeFrame,2,1,Cols,Rows)
	self.BtnBaseEnergy.tooltip = "Reduce the base energy demand."

	self.LblBaseEnergy = self.Window:createLabel(
		Rect(),
		"$BASE_ENERGY",
		FontSize3
	)
	self.LblBaseEnergy.rect = FramedRect(self.UpgradeFrame,2,2,Cols,Rows)
	self.LblBaseEnergy.centered = true

	--------

	self.BtnAccumEnergy = self.Window:createButton(
		Rect(),
		"Transformers",
		"TurretModdingUI_OnClickedBtnAccumEnergy"
	)
	self.BtnAccumEnergy.textSize = FontSize3
	self.BtnAccumEnergy.rect = FramedRect(self.UpgradeFrame,3,1,Cols,Rows)
	self.BtnAccumEnergy.tooltip = "Reduce the climbing energy demand."

	self.LblAccumEnergy = self.Window:createLabel(
		Rect(),
		"$ACCUM_ENERGY",
		FontSize3
	)
	self.LblAccumEnergy.rect = FramedRect(self.UpgradeFrame,3,2,Cols,Rows)
	self.LblAccumEnergy.centered = true

	--------

	self.BtnDamage = self.Window:createButton(
		Rect(),
		"Ammunition / Power",
		"TurretModdingUI_OnClickedBtnDamage"
	)
	self.BtnDamage.textSize = FontSize3
	self.BtnDamage.rect = FramedRect(self.UpgradeFrame,4,1,Cols,Rows)
	self.BtnDamage.tooltip = "Increase the firepower."

	self.LblDamage = self.Window:createLabel(
		Rect(),
		"$DAMAGE",
		FontSize3
	)
	self.LblDamage.rect = FramedRect(self.UpgradeFrame,4,2,Cols,Rows)
	self.LblDamage.centered = true

	--------

	self.BtnSpeed = self.Window:createButton(
		Rect(),
		"Drive Motors",
		"TurretModdingUI_OnClickedBtnSpeed"
	)
	self.BtnSpeed.textSize = FontSize3
	self.BtnSpeed.rect = FramedRect(self.UpgradeFrame,1,3,Cols,Rows)
	self.BtnSpeed.tooltip = "Increase the tracking speed."

	self.LblSpeed = self.Window:createLabel(
		Rect(),
		"$TURN_SPEED",
		FontSize3
	)
	self.LblSpeed.rect = FramedRect(self.UpgradeFrame,1,4,Cols,Rows)
	self.LblSpeed.centered = true

	--------

	self.BtnRange = self.Window:createButton(
		Rect(),
		"Barrel / Lens",
		"TurretModdingUI_OnClickedBtnRange"
	)
	self.BtnRange.textSize = FontSize3
	self.BtnRange.rect = FramedRect(self.UpgradeFrame,2,3,Cols,Rows)
	self.BtnRange.tooltip = "Increase the range."

	self.LblRange = self.Window:createLabel(
		Rect(),
		"$RANGE",
		FontSize3
	)
	self.LblRange.rect = FramedRect(self.UpgradeFrame,2,4,Cols,Rows)
	self.LblRange.centered = true

	--------

	self.BtnFireRate = self.Window:createButton(
		Rect(),
		"Trigger Mechanism",
		"TurretModdingUI_OnClickedBtnFireRate"
	)
	self.BtnFireRate.textSize = FontSize3
	self.BtnFireRate.rect = FramedRect(self.UpgradeFrame,3,3,Cols,Rows)
	self.BtnFireRate.tooltip = "Increase the fire rate."

	self.LblFireRate = self.Window:createLabel(
		Rect(),
		"$FIRE_RATE",
		FontSize3
	)
	self.LblFireRate.rect = FramedRect(self.UpgradeFrame,3,4,Cols,Rows)
	self.LblFireRate.centered = true

	--------

	self.BtnAccuracy = self.Window:createButton(
		Rect(),
		"Stabilizers",
		"TurretModdingUI_OnClickedBtnAccuracy"
	)
	self.BtnAccuracy.textSize = FontSize3
	self.BtnAccuracy.rect = FramedRect(self.UpgradeFrame,4,3,Cols,Rows)
	self.BtnAccuracy.tooltip = "Increase the accuracy."

	self.LblAccuracy = self.Window:createLabel(
		Rect(),
		"$ACCURACY",
		FontSize3
	)
	self.LblAccuracy.rect = FramedRect(self.UpgradeFrame,4,4,Cols,Rows)
	self.LblAccuracy.centered = true

	--------

	self.BtnEfficiency = self.Window:createButton(
		Rect(),
		"Phase Filters",
		"TurretModdingUI_OnClickedBtnEfficiency"
	)
	self.BtnEfficiency.textSize = FontSize3
	self.BtnEfficiency.rect = FramedRect(self.UpgradeFrame,5,1,Cols,Rows)
	self.BtnEfficiency.tooltip = "Increase the efficiency of mining and scav lasers."

	self.LblEfficiency = self.Window:createLabel(
		Rect(),
		"$EFFICIENCY",
		FontSize3
	)
	self.LblEfficiency.rect = FramedRect(self.UpgradeFrame,5,2,Cols,Rows)
	self.LblEfficiency.centered = true

	--------

	self.BtnTargeting = self.Window:createButton(
		Rect(),
		"Targeting",
		"TurretModdingUI_OnClickedBtnTargeting"
	)
	self.BtnTargeting.textSize = FontSize3
	self.BtnTargeting.rect = FramedRect(self.UpgradeFrame,1,6,Cols,Rows)
	self.BtnTargeting.tooltip = "Toggle Automatic Targeting.\n(Does not consume turrets)"

	self.LblTargeting = self.Window:createLabel(
		Rect(),
		"$TARGETING",
		FontSize3
	)
	self.LblTargeting.rect = FramedRect(self.UpgradeFrame,1,7,Cols,Rows)
	self.LblTargeting.centered = true

	--------

	self.BtnCoaxial = self.Window:createButton(
		Rect(),
		"Coaxial",
		"TurretModdingUI_OnClickedBtnCoaxial"
	)
	self.BtnCoaxial.textSize = FontSize3
	self.BtnCoaxial.rect = FramedRect(self.UpgradeFrame,2,6,Cols,Rows)
	self.BtnCoaxial.tooltip = "Toggle Coaxial Mounting.\n(Does not consume turrets)"

	self.LblCoaxial = self.Window:createLabel(
		Rect(),
		"$COAXIAL",
		FontSize3
	)
	self.LblCoaxial.rect = FramedRect(self.UpgradeFrame,2,7,Cols,Rows)
	self.LblCoaxial.centered = true

	--------

	self.BtnSize = self.Window:createButton(Rect(),"Size","TurretModdingUI_OnClickedBtnSize")
	self.BtnSize.textSize = FontSize3
	self.BtnSize.rect = FramedRect(self.UpgradeFrame,3,6,Cols,Rows)
	self.BtnSize.tooltip = "Adjust Turret Size.\n(Does not consume turrets)"

	self.NumSize = self.Window:createSlider(Rect(),5,30,25,"","TurretModdingUI_OnUpdatePreviewSize")
	self.NumSize.rect = FramedRect(self.UpgradeFrame,3,7,Cols,Rows,5)
	self.NumSize.showValue = false

	--------

	self.BtnColour = self.Window:createButton(
		Rect(),
		"Colour HSV",
		"TurretModdingUI_OnClickedBtnColour"
	)
	self.BtnColour.textSize = FontSize3
	self.BtnColour.rect = FramedRect(self.UpgradeFrame,4,6,Cols,Rows)
	self.BtnColour.tooltip = "Set Weapon Color.\n(Does not consume turrets)"

	self.BgColourFrame = self.Window:createFrame(BPane.bottom)
	self.BgColourFrame.rect = FramedRect(self.UpgradeFrame,4,7,Cols,Rows)

	self.NumColourHue = self.Window:createSlider(Rect(),0,360,18,"","TurretModdingUI_OnUpdatePreviewColour")
	self.NumColourHue.rect = FramedRect(self.UpgradeFrame,((4*3)-2),7,(Cols*3),Rows,5)
	self.NumColourHue.showValue = false

	self.NumColourSat = self.Window:createSlider(Rect(),0,1,10,"","TurretModdingUI_OnUpdatePreviewColour")
	self.NumColourSat.rect = FramedRect(self.UpgradeFrame,((4*3)-1),7,(Cols*3),Rows,5)
	self.NumColourSat.showValue = false

	self.NumColourVal = self.Window:createSlider(Rect(),0,1,10,"","TurretModdingUI_OnUpdatePreviewColour")
	self.NumColourVal.rect = FramedRect(self.UpgradeFrame,((4*3)-0),7,(Cols*3),Rows,5)
	self.NumColourVal.showValue = false

	return
end

function Win:PopulateInventory(NewCurrentIndex)
-- most of the structure for this function was stolen from the vanilla research
-- station script. it reads your inventory and creates a visible list of all
-- the turrets you can drag drop.

	local ItemList = {}
	local Me = Player()
	local Count = 0
	local Item = nil

	self.Inv:clear()

	-- throw everything that makes sense into a table so we can sort it.

	for Iter, Thing in pairs(Me:getInventory():getItems()) do
		if(Thing.item.itemType == InventoryItemType.Turret or Thing.item.itemType == InventoryItemType.TurretTemplate)
		then
			local Item = SellableInventoryItem(Thing.item,Iter,Me)
			table.insert(ItemList,Item)
		end
	end

	-- sort starred items to the front of the list, trash to the end.

	table.sort(ItemList,function(a,b)
		if(a.item.favorite and not b.item.favorite) then
			return true
		else
			if(b.item.trash and not a.item.trash) then
				return true
			else
				return false
			end
		end
	end)

	-- now create items in our dialog to represent the inventory items.
	-- are are unstacking items for this.

	for Iter, Thing in pairs(ItemList) do
		Count = Thing.amount

		while(Count > 0)
		do
			Item = InventorySelectionItem()
			Item.item = Thing.item
			Item.uvalue = Thing.index

			if((NewCurrentIndex ~= nil) and (NewCurrentIndex == Item.uvalue)) then
				-- handle when the server says an item was modded.
				self.Item:clear()
				self.Item:add(Item)
				NewCurrentIndex = nil
			else
				-- populate the normal inventory.
				self.Inv:add(Item)
			end

			Count = Count - 1
		end
	end

	-- empty the bin
	self.Bin:clear()
	self.Bin:addEmpty()
	self.Bin:addEmpty()
	self.Bin:addEmpty()
	self.Bin:addEmpty()
	self.Bin:addEmpty()

	return
end

--------------------------------------------------------------------------------

function Win:GetCurrentItemIndex()
-- get the index of the real item that this mock item is pointing to. this
-- returns the value we stored in the uvalue property.

	local Item = self.Item:getItem(ivec2(0,0))

	if(Item == nil)
	then return nil end

	return Item.uvalue
end

function Win:GetCurrentItemCount()
-- get the amount in the stack we are currently editing.

	return self.Item:getItem(ivec2(0,0)).amount
end

function Win:GetCurrentItemReal()
-- get the actual turret we are editing.

	return Player():getInventory():find(
		 self:GetCurrentItemIndex()
	)
end

function Win:GetCurrentItem()
-- get the mock turret we are editing.

	return self.Item:getItem(ivec2(0,0))
end

function Win:GetCurrentItems()
-- get the currently selected item and the real item it is a mock for.

	return self:GetCurrentItem(), self:GetCurrentItemReal()
end

--------

function Win:CalculateBinItems()
-- calculate the bin items buff value.

	local BuffValue = 0.0
	local RarityValue = 0
	local TechLevel = 0
	local TechPer = 0
	local Count = 0
	local Mock, Real = self:GetCurrentItems()

	for ItemVec, Item in pairs(self.Bin:getItems()) do
		-- count how many items we process.
		Count = Count + 1

		-- pool the tech level for average later.
		TechLevel = TechLevel + Item.item.averageTech

		-- calculate how muc the rarity is worth.
		RarityValue = round((TurretLib:GetWeaponRarityValue(Item.item) * Config.RarityMult),3)

		BuffValue = BuffValue + RarityValue

		PrintDebug(
			"Bin Item: " .. Item.item.weaponName ..
			", Rarity: " .. TurretLib:GetWeaponRarityValue(Item.item) ..
			", Tech: " .. Item.item.averageTech
		)
	end

	if(Count == 0) then
		return 0
	end

	TechLevel = TechLevel / Count
	if(TechLevel > Real.averageTech) then
		TechLevel = Real.averageTech
	end

	TechPer = (TechLevel / Real.averageTech)
	BuffValue = (BuffValue * TechPer)

	PrintDebug(
		"TechLevel: ".. TechLevel .."/" .. Real.averageTech ..
		", " .. (TechPer * 100) .. "%" ..
		", BuffValue: " .. BuffValue
	)

	return BuffValue
end

function Win:ConsumeBinItems()
-- get the items from the bin

	local Armory = Player():getInventory()
	local Real = nil
	local Count = 0

	for ItemVec, Item in pairs(self.Bin:getItems()) do
		self.Bin:remove(ItemVec)
		TurretLib:ConsumePlayerInventory(Player().index,Item.uvalue,1)
	end

	return
end

--------------------------------------------------------------------------------

function Win:UpdateItems(Mock,Real)

	TurretLib:UpdatePlayerInventory(
		Player().index,
		Real,
		self:GetCurrentItemIndex()
	)

	return
end

--------------------------------------------------------------------------------

function Win:UpdateFields()

	-- if we recieved a new index, then we need to scan the inventory widget
	-- again to find where the object moved to when it was edited last time
	-- and force that into the main box before we continue.

	local Item, Real = self:GetCurrentItems()
	local BackgroundColour
	local ColourDark = Color()
	local ColourLight = Color()

	local WeaponType = nil
	local Category = 0
	local HeatRate = 0
	local CoolRate = 0
	local BaseEnergy = 0
	local AccumEnergy = 0
	local Damage = 0
	local FireRate = 0
	local Speed = 0
	local Range = 0
	local Accuracy = 0
	local Efficiency = 0
	local Targeting = 0
	local GunCount = 0
	local Colour = Color()
	local Coaxial = false
	local Size = 0

	if(Item ~= nil) then
		WeaponType = TurretLib:GetWeaponType(Item.item)
		Category = TurretLib:GetWeaponCategory(Item.item)
		HeatRate = TurretLib:GetWeaponHeatRate(Item.item)
		CoolRate = TurretLib:GetWeaponCoolRate(Item.item)
		BaseEnergy = TurretLib:GetWeaponBaseEnergy(Item.item)
		AccumEnergy = TurretLib:GetWeaponAccumEnergy(Item.item)
		Damage = TurretLib:GetWeaponDamage(Item.item)
		FireRate = TurretLib:GetWeaponFireRate(Item.item)
		Speed = TurretLib:GetWeaponSpeed(Item.item)
		Range = TurretLib:GetWeaponRange(Item.item)
		Accuracy = TurretLib:GetWeaponAccuracy(Item.item)
		Efficiency = TurretLib:GetWeaponEfficiency(Item.item)
		Targeting = TurretLib:GetWeaponTargeting(Item.item)
		GunCount = TurretLib:GetWeaponCount(Item.item)
		Colour = TurretLib:GetWeaponColour(Item.item)
		Coaxial = TurretLib:GetWeaponCoaxial(Item.item)
		Size = TurretLib:GetWeaponSize(Item.item)
	end

	ColourDark:setHSV(0,0,0.3)
	ColourLight:setHSV(0,0,0.8)

	-- fill in all the values.

	self.BtnTargeting.caption = "Targeting (Cr. " .. toReadableValue(Config.CostTargeting) .. ")"
	self.BtnCoaxial.caption = "Coaxial (Cr. " .. toReadableValue(Config.CostCoaxial) .. ")"
	self.BtnColour.caption = "Colour HSV (Cr. " .. toReadableValue(Config.CostColour) .. ")"
	self.BtnSize.caption = "Scale (Cr. " .. toReadableValue(Config.CostSize) .. ")"

	self.BtnHeat.caption = "Heat Sinks"
	self.LblHeat.caption = HeatRate .. " Heat, " .. CoolRate .. " Cool"
	self.LblHeat.color = ColourLight

	self.BtnBaseEnergy.caption = "Capacitors"
	self.LblBaseEnergy.caption = BaseEnergy .. " Base EPS"
	self.LblBaseEnergy.color = ColourLight

	self.BtnAccumEnergy.caption = "Transformers"
	self.LblAccumEnergy.caption = AccumEnergy .. " Accum EPS"
	self.LblAccumEnergy.color = ColourLight

	self.BtnDamage.caption = "Ammunition"
	self.LblDamage.caption = Damage .. " (" .. round((Damage * FireRate * GunCount),2) .. " DPS)"
	self.LblDamage.color = ColourLight

	self.BtnFireRate.caption = "Trigger Mechanisms"
	self.LblFireRate.caption = FireRate .. " RPS"
	self.LblFireRate.color = ColourLight

	self.BtnSpeed.caption = "Drive Motors"
	self.LblSpeed.caption = Speed
	self.LblSpeed.color = ColourLight

	self.BtnRange.caption = "Barrel"
	self.LblRange.caption = Range .. " KM"
	self.LblRange.color = ColourLight

	self.BtnAccuracy.caption = "Stabilizers"
	self.LblAccuracy.caption = (Accuracy * 100) .. "%"
	self.LblAccuracy.color = ColourLight

	self.BtnEfficiency.caption = "Phase Filters"
	self.LblEfficiency.caption = (Efficiency * 100) .. "%"
	self.LblEfficiency.color = ColourLight

	if(Targeting) then self.LblTargeting.caption = "YES"
	else self.LblTargeting.caption = "NO"
	end

	self.LblCoaxial.color = ColourLight
	if(Coaxial) then self.LblCoaxial.caption = "YES"
	else self.LblCoaxial.caption = "NO"
	end

	BackgroundColour = Colour
	self.NumColourHue.value = BackgroundColour.hue
	self.NumColourSat.value = BackgroundColour.saturation
	self.NumColourVal.value = BackgroundColour.value

	self.NumSize.value = Size * 10

	if(WeaponType == "beam") then
		self.BtnRange.caption = "Lenses"
		self.BtnDamage.caption = "Power Amplifiers"
	end

	-- show everything.

	self.BtnHeat:show()
	self.BtnBaseEnergy:show()
	self.BtnAccumEnergy:show()
	self.BtnDamage:show()
	self.BtnSpeed:show()
	self.BtnRange:show()
	self.BtnFireRate:show()
	self.BtnAccumEnergy:show()
	self.BtnCoaxial:show()
	self.BtnSize:show()

	self.LblHeat:show()
	self.LblBaseEnergy:show()
	self.LblAccumEnergy:show()
	self.LblDamage:show()
	self.LblSpeed:show()
	self.LblRange:show()
	self.LblFireRate:show()
	self.LblAccumEnergy:show()
	self.LblCoaxial:show()

	self.NumSize:show()

	-- hide things that make no sense to edit for this turret.

	if(HeatRate == 0) then
		self.LblHeat.color = ColourDark
	end

	if(BaseEnergy == 0) then
		self.LblBaseEnergy.color = ColourDark
	end

	if(AccumEnergy == 0) then
		self.LblAccumEnergy.color = ColourDark
	end

	if(Damage == 0) then
		self.LblDamage.color = ColourDark
	end

	if(Speed == 0) then
		self.LblSpeed.color = ColourDark
	end

	if(Range == 0) then
		self.LblRange.color = ColourDark
	end

	if(FireRate == 0) then
		self.LblFireRate.color = ColourDark
	end

	if((Accuracy == 0) or (Accuracy == 1)) then
		self.LblAccuracy.color = ColourDark
	end

	if((Efficiency == 0) or (Efficiency == 1)) then
		self.LblEfficiency.color = ColourDark
	end

	return
end

function Win:UpdateBinLabel()

	local BuffValue = self:CalculateBinItems()

	if(BuffValue > 0) then
		self.BinLabel.caption = "Turrets To Scrap (+" .. round(BuffValue,3) .. "%)"
	else
		self.BinLabel.caption = "Turrets To Scrap"
	end

	return
end

--------------------------------------------------------------------------------

function Win:OnItemClicked(SelectID, FX, FY, Item, Button)
	self.CurrentSelectID = SelectID
	return
end

function Win:OnItemAdded(SelectID, FX, FY, Item, FromIndex, ToIndex, TX, TY)

	local OldItem = self.Item:getItem(ivec2(0,0))
	local FromVec = ivec2(FX,FY)
	local BackgroundColour = Color()

	if(SelectID == self.CurrentSelectID) then
		print("[DccTurretEditor] Item was source and dest.")
		return
	end

	self.Item:clear()
	self.Item:add(Item)
	print("[DccTurretEditor] Selected Turret: " .. Item.item.weaponName)

	--------

	if(self.CurrentSelectID == self.Bin.index) then
		self.Bin:remove(FromVec)
	elseif(self.CurrentSelectID == self.Inv.index) then
		self.Inv:remove(FromVec)
	end

	--------

	if(OldItem ~= nil) then
		self.Inv:add(OldItem)
		print("[DccTurretEditor] Replaced Turret: " .. OldItem.item.weaponName)
	end

	--------

	self:UpdateFields()
	self:UpdateBinLabel()
	return
end

----------------
----------------

function Win:OnBinClicked(SelectID, FX, FY, Item, Button)
	self.CurrentSelectID = SelectID
	return
end

function Win:OnBinAdded(SelectID, FX, FY, Item, FromIndex, ToIndex, TX, TY)

	local FromVec = ivec2(FX,FY)

	if(SelectID == self.CurrentSelectID) then
		print("[DccTurretEditor] Bin was source and dest.")
		return
	end

	if(tablelength(self.Bin:getItems()) >= 5) then
		print("[DccTurretEditor] Bin is full.")
		return
	end

	self.Bin:add(Item)
	print("[DccTurretEditor] Added to Bin: " .. Item.item.weaponName)

	--------

	if(self.CurrentSelectID == self.Item.index) then
		self.Item:remove(FromVec)
	elseif(self.CurrentSelectID == self.Inv.index) then
		self.Inv:remove(FromVec)
	end

	self:UpdateBinLabel()
	return
end

----------------
----------------

function Win:OnInvClicked(SelectID, FX, FY, Item, Button)
	self.CurrentSelectID = SelectID
	return
end

function Win:OnInvAdded(SelectID, FX, FY, Item, FromIndex, ToIndex, TX, TY)

	local FromVec = ivec2(FX,FY)

	if(SelectID == self.CurrentSelectID) then
		print("[DccTurretEditor] Inv was source and dest.")
		return
	end

	self.Inv:add(Item)
	print("[DccTurretEditor] Added to Inv: " .. Item.item.weaponName)

	--------

	if(self.CurrentSelectID == self.Item.index) then
		self.Item:remove(FromVec)
	elseif(self.CurrentSelectID == self.Bin.index) then
		self.Bin:remove(FromVec)
	end

	self:UpdateBinLabel()
	return
end

----------------
----------------

function Win:OnUpdatePreviewColour()

	local NewColour = Color()

	NewColour:setHSV(
		self.NumColourHue.value,
		self.NumColourSat.value,
		self.NumColourVal.value
	)

	self.BgColourFrame.backgroundColor = NewColour
	return
end

function Win:OnUpdatePreviewSize()

	-- lulz

	return
end

----------------
----------------

function Win:OnClickedBtnHeat()
-- lower heat generation
-- raise heat radiation

	local BuffValue = Win:CalculateBinItems()
	local Mock, Real = Win:GetCurrentItems()

	if(Mock == nil) then
		PrintError("No turret selected")
		return
	end

	if(BuffValue == 0.0) then
		PrintError("No turrets in scrap bin")
		return
	end

	if(TurretLib:GetWeaponHeatRate(Real) == 0) then
		PrintWarning("This turret is not producing any heat.")
		return
	end

	TurretLib:ModWeaponHeatRate(Real,((BuffValue + Config.NearZeroFloat) * -1))
	TurretLib:ModWeaponCoolRate(Real,BuffValue)

	self:ConsumeBinItems()
	self:UpdateItems(Mock,Real)
	return
end

function Win:OnClickedBtnBaseEnergy()
-- lower power requirement.

	local BuffValue = Win:CalculateBinItems()
	local Mock, Real = Win:GetCurrentItems()

	if(Mock == nil) then
		PrintError("No turret selected")
		return
	end

	if(BuffValue == 0.0) then
		PrintError("No turrets in scrap bin")
		return
	end

	if(TurretLib:GetWeaponBaseEnergy(Real) == 0) then
		PrintWarning("This turret does not require any power")
		return
	end

	TurretLib:ModWeaponBaseEnergy(Real,((BuffValue + Config.NearZeroFloat) * -1))

	self:ConsumeBinItems()
	self:UpdateItems(Mock,Real)
	return
end

function Win:OnClickedBtnAccumEnergy()
-- lower power useage.

	local BuffValue = Win:CalculateBinItems()
	local Mock, Real = Win:GetCurrentItems()

	if(Mock == nil) then
		PrintError("No turret selected")
		return
	end

	if(BuffValue == 0.0) then
		PrintError("No turrets in scrap bin")
		return
	end

	if(TurretLib:GetWeaponAccumEnergy(Real) == 0) then
		PrintWarning("This turret does not demand additional power")
		return
	end

	TurretLib:ModWeaponAccumEnergy(Real,((BuffValue + Config.NearZeroFloat) * -1))

	self:ConsumeBinItems()
	self:UpdateItems(Mock,Real)
	return
end

function Win:OnClickedBtnFireRate()
-- raise fire rate.

	local BuffValue = Win:CalculateBinItems()
	local Mock, Real = Win:GetCurrentItems()

	if(Mock == nil) then
		PrintError("No turret selected")
		return
	end

	if(BuffValue == 0.0) then
		PrintError("No turrets in scrap bin")
		return
	end

	if(TurretLib:GetWeaponFireRate(Real) == 0) then
		PrintWarning("This turret does not have a fire rate")
		return
	end

	TurretLib:ModWeaponFireRate(Real,BuffValue)

	self:ConsumeBinItems()
	self:UpdateItems(Mock,Real)
	return
end

function Win:OnClickedBtnSpeed()
-- raise turret speed.

	local BuffValue = Win:CalculateBinItems()
	local Mock, Real = Win:GetCurrentItems()

	if(Mock == nil) then
		PrintError("No turret selected")
		return
	end

	if(BuffValue == 0.0) then
		PrintError("No turrets in scrap bin")
		return
	end

	if(TurretLib:GetWeaponSpeed(Real) == 0) then
		PrintWarning("This turret does not turn apparently")
		return
	end

	TurretLib:ModWeaponSpeed(Real,BuffValue)

	self:ConsumeBinItems()
	self:UpdateItems(Mock,Real)
	return
end

function Win:OnClickedBtnRange()
-- raise weapon range.

	local BuffValue = Win:CalculateBinItems()
	local Mock, Real = Win:GetCurrentItems()

	if(Mock == nil) then
		PrintError("No turret selected")
		return
	end

	if(BuffValue == 0.0) then
		PrintError("No turrets in scrap bin")
		return
	end

	if(TurretLib:GetWeaponRange(Real) == 0) then
		PrintWarning("This turret has no reach apparently")
		return
	end

	TurretLib:ModWeaponRange(Real,BuffValue)

	self:ConsumeBinItems()
	self:UpdateItems(Mock,Real)
	return
end

function Win:OnClickedBtnDamage()
-- raise weapon damage

	local BuffValue = Win:CalculateBinItems()
	local Mock, Real = Win:GetCurrentItems()

	if(Mock == nil) then
		PrintError("No turret selected")
		return
	end

	if(BuffValue == 0.0) then
		PrintError("No turrets in scrap bin")
		return
	end

	if(TurretLib:GetWeaponDamage(Real) == 0) then
		PrintWarning("This turret does not do any damage")
		return
	end

	TurretLib:ModWeaponDamage(Real,BuffValue)

	self:ConsumeBinItems()
	self:UpdateItems(Mock,Real)
	return
end

function Win:OnClickedBtnAccuracy()
-- raise accuracy

	local BuffValue = Win:CalculateBinItems()
	local Mock, Real = Win:GetCurrentItems()
	local CurrentValue = TurretLib:GetWeaponAccuracy(Real)

	if(Mock == nil) then
		PrintError("No turret selected")
		return
	end

	if(BuffValue == 0.0) then
		PrintError("No turrets in scrap bin")
		return
	end

	if(CurrentValue == 0) then
		PrintWarning("This turret has no accuracy apparently")
		return
	end

	if(CurrentValue == 1) then
		PrintWarning("This turret is at max accuracy.")
		return
	end

	TurretLib:ModWeaponAccuracy(Real,BuffValue)

	self:ConsumeBinItems()
	self:UpdateItems(Mock,Real)
	return
end

function Win:OnClickedBtnEfficiency()
-- raise rifficiency

	local BuffValue = Win:CalculateBinItems()
	local Mock, Real = Win:GetCurrentItems()
	local CurrentValue = TurretLib:GetWeaponEfficiency(Real)

	if(Mock == nil) then
		PrintError("No turret selected")
		return
	end

	if(BuffValue == 0.0) then
		PrintError("No turrets in scrap bin")
		return
	end

	if(CurrentValue == 0) then
		PrintWarning("This turret has no efficiency apparently")
		return
	end

	if(CurrentValue == 1) then
		PrintWarning("This turret is at max efficiency.")
		return
	end

	TurretLib:ModWeaponEfficiency(Real,BuffValue)

	self:ConsumeBinItems()
	self:UpdateItems(Mock,Real)
	return
end

function Win:OnClickedBtnTargeting()
-- toggle targeting

	local Mock, Real = Win:GetCurrentItems()
	local PlayerRef = Player()

	if(Mock == nil) then
		PrintError("No turret selected")
		return
	end

	if(PlayerRef.money < Config.CostTargeting) then
		PrintError("You do not have enough credits")
		return
	end

	TurretLib:ToggleWeaponTargeting(Real)
	TurretLib:PlayerPayCredits(PlayerRef.index, Config.CostTargeting)

	self:UpdateItems(Mock,Real)
	return
end

function Win:OnClickedBtnColour()
-- set colour

	local Mock, Real = Win:GetCurrentItems()
	local NewColour = Color()
	local PlayerRef = Player()

	if(Mock == nil) then
		PrintError("No turret selected")
		return
	end

	if(PlayerRef.money < Config.CostColour) then
		PrintError("You do not have enough credits")
		return
	end

	NewColour:setHSV(
		self.NumColourHue.value,
		self.NumColourSat.value,
		self.NumColourVal.value
	)

	TurretLib:SetWeaponColour(Real,NewColour)
	TurretLib:PlayerPayCredits(PlayerRef.index,Config.CostColour)

	self:UpdateItems(Mock,Real)
	return
end

function Win:OnClickedBtnCoaxial()
-- toggle targeting

	local Mock, Real = Win:GetCurrentItems()
	local PlayerRef = Player()

	if(Mock == nil) then
		PrintError("No turret selected")
		return
	end

	if(PlayerRef.money < Config.CostCoaxial) then
		PrintError("You do not have enough credits")
		return
	end

	TurretLib:ToggleWeaponCoaxial(Real)
	TurretLib:PlayerPayCredits(PlayerRef.index, Config.CostCoaxial)

	self:UpdateItems(Mock,Real)
	return
end


function Win:OnClickedBtnSize()
-- change turrent size
	
	local Mock, Real = Win:GetCurrentItems()
	local PlayerRef = Player()

	if(Mock == nil) then
		PrintError("No turret selected")
		return
	end

	if(PlayerRef.money < Config.CostSize) then
		PrintError("You do not have enough credits")
		return
	end

	TurretLib:SetWeaponSize(Real,(self.NumSize.value / 10))
	TurretLib:PlayerPayCredits(PlayerRef.index, Config.CostSize)

	self:UpdateItems(Mock,Real)
	return
end

--------------------------------------------------------------------------------

function TurretModdingUI_Update(NewCurrentIndex)
	print("[DccTurretEditor] Update Turret Editor UI")
	
	Win:PopulateInventory(NewCurrentIndex)
	Win:UpdateFields()
	Win:UpdateBinLabel()
	return
end

callable(nil,"TurretModdingUI_Update")

function TurretModdingUI_OnInit(...) Win:OnInit(...) end
function TurretModdingUI_OnItemClicked(...) Win:OnItemClicked(...) end
function TurretModdingUI_OnItemAdded(...) Win:OnItemAdded(...) end
function TurretModdingUI_OnBinClicked(...) Win:OnBinClicked(...) end
function TurretModdingUI_OnBinAdded(...) Win:OnBinAdded(...) end
function TurretModdingUI_OnInvClicked(...) Win:OnInvClicked(...) end
function TurretModdingUI_OnInvAdded(...) Win:OnInvAdded(...) end
function TurretModdingUI_OnUpdatePreviewColour(...) Win:OnUpdatePreviewColour(...) end
function TurretModdingUI_OnUpdatePreviewSize(...) Win:OnUpdatePreviewSize(...) end

function TurretModdingUI_OnClickedBtnHeat(...) Win:OnClickedBtnHeat(...) end
function TurretModdingUI_OnClickedBtnBaseEnergy(...) Win:OnClickedBtnBaseEnergy(...) end
function TurretModdingUI_OnClickedBtnAccumEnergy(...) Win:OnClickedBtnAccumEnergy(...) end
function TurretModdingUI_OnClickedBtnFireRate(...) Win:OnClickedBtnFireRate(...) end
function TurretModdingUI_OnClickedBtnSpeed(...) Win:OnClickedBtnSpeed(...) end
function TurretModdingUI_OnClickedBtnRange(...) Win:OnClickedBtnRange(...) end
function TurretModdingUI_OnClickedBtnDamage(...) Win:OnClickedBtnDamage(...) end
function TurretModdingUI_OnClickedBtnAccuracy(...) Win:OnClickedBtnAccuracy(...) end
function TurretModdingUI_OnClickedBtnEfficiency(...) Win:OnClickedBtnEfficiency(...) end
function TurretModdingUI_OnClickedBtnTargeting(...) Win:OnClickedBtnTargeting(...) end
function TurretModdingUI_OnClickedBtnColour(...) Win:OnClickedBtnColour(...) end
function TurretModdingUI_OnClickedBtnCoaxial(...) Win:OnClickedBtnCoaxial(...) end
function TurretModdingUI_OnClickedBtnSize(...) Win:OnClickedBtnSize(...) end

--------------------------------------------------------------------------------

-- these are methods that the ui access of the game needs.

function interactionPossible(Player)
	return true, ""
end

function getIcon(Seed, Rarity)

	return "mods/DccTurretEditor/Textures/Icon.png"
end

--------------------------------------------------------------------------------

function onCloseWindow()
-- clear out the dialog when closed.

	Win.Inv:clear()
	Win.Bin:clear()
	Win.Item:clear()

	Win:UpdateFields()
	return
end

function onShowWindow()
-- reset the dialog when it is opened.

	Win.Item:clear()
	Win.Item:addEmpty()

	Win.Bin:clear()
	Win.Bin:addEmpty()
	Win.Bin:addEmpty()
	Win.Bin:addEmpty()
	Win.Bin:addEmpty()
	Win.Bin:addEmpty()

	Win.Inv:clear()
	Win.Inv:addEmpty()

	Win:UpdateFields()
	Win:PopulateInventory()
	return
end

--------------------------------------------------------------------------------

function PullConfigFromServer(ToPlayer,InputConfig)
-- handle pulling the config from the server.

	if(onServer()) then
		-- when this function runs server side we need to load the config
		-- and send it back to the client.

		local InputConfig = require("mods.DccTurretEditor.Common.ConfigLib")
		print("[DccTurretEditor] Sending Config To Client")
		invokeClientFunction(
			Player(ToPlayer),
			"PullConfigFromServer",
			ToPlayer,
			InputConfig
		)
	else
		-- when this function runs on the client side we will store the
		-- config that the server sent us.

		print("[DccTurretEditor] Received Config From Server")
		Config = InputConfig
	end

end

callable(nil,"PullConfigFromServer")

function initialize()
-- script bootstrapping.

	print("TurretModding:initalize")

	-- script added, game loaded: executes both server and client.
	-- jump to new sector: executes on the client only and the locals
	-- get dumped...

	-- when the client runs this we will ask the server for the config
	-- to repopulate the local var.

	if(onClient()) then
		print("[DccTurretEditor] Asking Server For Config")
		invokeServerFunction("PullConfigFromServer",Player().index,nil)
	end

	return
end

function initUI()
-- ui bootstrapping.

	if(onServer())
	then return end

	Win:OnInit()
	return
end


