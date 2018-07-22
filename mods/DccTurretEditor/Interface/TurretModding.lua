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

function PrintClient(TheMessage, MessageType)
	if onServer() then
		local player = Player(callingPlayer)
		if player then
			Player(callingPlayer):sendChatMessage("", MessageType, TheMessage)
		end
	else
		displayChatMessage(TheMessage,"DccTurretEditor", MessageType)
	end
end

function PrintError(TheMessage)
	PrintClient(TheMessage, 1)
end

function PrintInfo(TheMessage)
	PrintClient(TheMessage, 3)
end

function PrintWarning(TheMessage)
	PrintClient(TheMessage, 2)
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

--PrintServer("TURRET MODDING UI LOAD")
--------------------------------------------------------------------------------

local Win = {
	Title = "Engineering: Weapons Bay",
	UI = nil,
	Res = nil,
	Size = nil,

	-- Flag used to force the client for the server to respond with the upgraded turret to prevent racing conditions
	waitingForServer = false,

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
	self.Size = vec2(900,700)
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
		10, 10, 0.65
	)

	local BPane = UIHorizontalSplitter(
		Pane.top,
		0, 0, 0.5
	)

	local TPane = UIVerticalSplitter(
		BPane.top,
		0, 0, 0.25
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

	self.Inv = self.Window:createInventorySelection(Pane.bottom,12)
	self.Inv.dropIntoEnabled = 1
	self.Inv.entriesSelectable = 0
	--self.Inv.onClickedFunction = "TurretModdingUI_OnInvClicked"
	self.Inv.onReceivedFunction = "TurretModdingUI_OnInvAdded"

	-- buttons don't place well so we alter their rects after creating.

	self.UpgradeFrame = self.Window:createFrame(BPane.bottom)
	local Rows = 7
	local Cols = 4

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
	self.BtnEfficiency.rect = FramedRect(self.UpgradeFrame,4,5,Cols,Rows)
	self.BtnEfficiency.tooltip = "Increase the efficiency of mining and scav lasers."

	self.LblEfficiency = self.Window:createLabel(
		Rect(),
		"$EFFICIENCY",
		FontSize3
	)
	self.LblEfficiency.rect = FramedRect(self.UpgradeFrame,4,6,Cols,Rows)
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

	self.BtnColour = self.Window:createButton(
		Rect(),
		"Colour HSV",
		"TurretModdingUI_OnClickedBtnColour"
	)
	self.BtnColour.textSize = FontSize3
	self.BtnColour.rect = FramedRect(self.UpgradeFrame,2,6,Cols,Rows)
	self.BtnColour.tooltip = "Set Weapon Color.\n(Does not consume turrets)"

	self.BgColourFrame = self.Window:createFrame(BPane.bottom)
	self.BgColourFrame.rect = FramedRect(self.UpgradeFrame,2,7,Cols,Rows)

	self.NumColourHue = self.Window:createSlider(Rect(),0,360,18,"","TurretModdingUI_OnUpdatePreviewColour")
	self.NumColourHue.rect = FramedRect(self.UpgradeFrame,((2*3)-2),7,(Cols*3),Rows,10)
	self.NumColourHue.showValue = false

	self.NumColourSat = self.Window:createSlider(Rect(),0,1,10,"","TurretModdingUI_OnUpdatePreviewColour")
	self.NumColourSat.rect = FramedRect(self.UpgradeFrame,((2*3)-1),7,(Cols*3),Rows,10)
	self.NumColourSat.showValue = false

	self.NumColourVal = self.Window:createSlider(Rect(),0,1,10,"","TurretModdingUI_OnUpdatePreviewColour")
	self.NumColourVal.rect = FramedRect(self.UpgradeFrame,((2*3)-0),7,(Cols*3),Rows,10)
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
	self.Inv:fill(Player().index)

	-- throw everything that makes sense into a table so we can sort it.

	for Iter, Thing in pairs(self.Inv:getItems()) do
		if(Thing.item.itemType == InventoryItemType.Turret or Thing.item.itemType == InventoryItemType.TurretTemplate)
		then
			table.insert(ItemList,Thing)
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
	self.Inv:clear()

	for _, item in pairs(ItemList) do
		self.Inv:add(item)
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

function Win:GetTurrets(player, scrapTurretIndices)
	local inventory = player:getInventory()
	local turrets = {}

	for index, amount in pairs(scrapTurretIndices) do
		local inventoryItem = inventory:find(index)
		if inventoryItem then
			turrets[index] = {amount=amount, inventoryItem=inventoryItem}
		end
	end

	return turrets
end

function Win:CalculateBinItems(upgradeTurretIndex, scrapTurretIndices)
	local player
	if onServer() then
		player = Player(callingPlayer)
		if not player then return 0 end
	else
		player = Player()
	end

	local BuffValue = 1.0
	local RarityValue = 0
	local TechLevel = 0
	local TechPer = 0
	local Count = 0
	local Real = player:getInventory():find(upgradeTurretIndex)
	if not Real or (Real.itemType ~= InventoryItemType.Turret and Real.itemType ~= InventoryItemType.TurretTemplate) then return 0 end

	for index, ingredient in pairs(Win:GetTurrets(player, scrapTurretIndices)) do
		local Item = ingredient.inventoryItem

		-- count how many items we process.
		Count = Count + ingredient.amount

		-- pool the tech level for average later.
		TechLevel = TechLevel + Item.averageTech * ingredient.amount

		-- calculate how muc the rarity is worth.
		RarityValue = 1.0 + (round((TurretLib:GetWeaponRarityValue(Item) * Config.RarityMult),3) / 10)

		for i=1,ingredient.amount do
			BuffValue = BuffValue * RarityValue
			--PrintDebug("BUFF_VALUE_INC: "..BuffValue)
		end

		PrintDebug(
			"Bin Item: " .. Item.weaponName ..
			", Rarity: " .. TurretLib:GetWeaponRarityValue(Item) ..
			", Tech: " .. Item.averageTech
		)
	end

	BuffValue = (BuffValue - 1.0) * 10

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
	end

	ColourDark:setHSV(0,0,0.3)
	ColourLight:setHSV(0,0,0.8)

	-- fill in all the values.

	self.BtnTargeting.caption = "Targeting (Cr. " .. toReadableValue(Config.CostTargeting) .. ")"
	self.BtnColour.caption = "Colour HSV (Cr. " .. toReadableValue(Config.CostColour) .. ")"

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

	BackgroundColour = Colour
	self.NumColourHue.value = BackgroundColour.hue
	self.NumColourSat.value = BackgroundColour.saturation
	self.NumColourVal.value = BackgroundColour.value

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

	self.LblHeat:show()
	self.LblBaseEnergy:show()
	self.LblAccumEnergy:show()
	self.LblDamage:show()
	self.LblSpeed:show()
	self.LblRange:show()
	self.LblFireRate:show()
	self.LblAccumEnergy:show()

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

	local BuffValue = self:CalculateBinItems(Win:Client_GetUpgradeTurretIndex(), Win:Client_GetScrapTurretIndices())

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

function Win:OnItemAdded(selectionIndex, fkx, fky, item, fromIndex, toIndex, tkx, tky)
	if not item then return end

	-- Only allow items from inventory
	if fromIndex == self.Item.index or fromIndex == self.Bin.index then
		--print("NOT FROM INV")
		return
	end

	Win:moveItem(item, self.Inv, Selection(selectionIndex), ivec2(fkx, fky), ivec2(tkx, tky))

	--print("[DccTurretEditor] Selected Turret: " .. item.item.weaponName)

	self:UpdateFields()
	self:UpdateBinLabel()
	return
end

----------------
----------------

function Win:addItemToMainSelection(item)
	if not item then return end
	local inventory = self.Inv

	if item.item.stackable then
		-- find the item and increase the amount
		for k, v in pairs(inventory:getItems()) do
			if v.item == item.item then
				v.amount = v.amount + 1

				inventory:remove(k)
				inventory:add(v, k)
				return
			end
		end

		item.amount = 1
	end

	-- when not found or not stackable, add it
	inventory:add(item)
end

function Win:removeItemFromMainSelection(key)
	local inventory = self.Inv
	local item = inventory:getItem(key)
	if not item then return end

	if item.amount then
		item.amount = item.amount - 1
		if item.amount == 0 then item.amount = nil end
	end

	inventory:remove(key)

	if item.amount then
		inventory:add(item, key)
	end
end

function Win:moveItem(item, from, to, fkey, tkey)
	if not item then return end

	if from.index == self.Inv.index then -- move from inventory to a selection
		-- first, move the item that might be in place back to the inventory
		if tkey then
			Win:addItemToMainSelection(to:getItem(tkey))
			to:remove(tkey)
		end

		Win:removeItemFromMainSelection(fkey)

		-- fix item amount, we don't want numbers in the upper selections
		item.amount = nil
		to:add(item, tkey)

	elseif to.index == self.Inv.index then
		-- move from selection to inventory

		Win:addItemToMainSelection(item)
		from:remove(fkey)
	end
end

function Win:OnBinClicked(SelectID, FX, FY, Item, Button)
	self.CurrentSelectID = SelectID
	return
end

function Win:OnBinAdded(selectionIndex, fkx, fky, item, fromIndex, toIndex, tkx, tky)

	if not item then return end

	-- don't allow dragging from/into the left hand selections
	if fromIndex == self.Item.index or fromIndex == self.Bin.index then
		print("NOT FROM INV")
		return
	end

	Win:moveItem(item, self.Inv, Selection(selectionIndex), ivec2(fkx, fky), ivec2(tkx, tky))

	print("[DccTurretEditor] Added to Bin: " .. item.item.weaponName)

	self:UpdateBinLabel()
	return
end

----------------
----------------

function Win:OnInvClicked(SelectID, FX, FY, Item, Button)
	self.CurrentSelectID = SelectID
	return
end

function Win:OnInvAdded(selectionIndex, fkx, fky, item, fromIndex, toIndex, tkx, tky)
	if(fromIndex == toIndex) then
		print("[DccTurretEditor] Inv was source and dest.")
		return
	end

	Win:moveItem(item, Selection(fromIndex), self.Inv, ivec2(fkx, fky), ivec2(tkx, tky))

	print("[DccTurretEditor] Added to Inv: " .. item.item.weaponName)

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

----------------
----------------

function Win:OnClickedBtnHeat()
	Win:Client_ApplyBuff("heat")
end

function Win:OnClickedBtnBaseEnergy()
	Win:Client_ApplyBuff("baseEnergy")
end

function Win:OnClickedBtnAccumEnergy()
	Win:Client_ApplyBuff("accumulatedEnergy")
end

function Win:OnClickedBtnDamage()
	Win:Client_ApplyBuff("damage")
end

function Win:OnClickedBtnAccuracy()
	Win:Client_ApplyBuff("accuracy")
end

function Win:OnClickedBtnFireRate()
	Win:Client_ApplyBuff("fireRate")
end

function Win:OnClickedBtnSpeed()
	Win:Client_ApplyBuff("tracking")
end

function Win:OnClickedBtnRange()
	Win:Client_ApplyBuff("range")
end

function Win:Client_GetUpgradeTurretIndex()
	local item = Win:GetCurrentItem()
	if not item then return nil end
	return item.index
end

function Win:Client_GetScrapTurretIndices()
	local itemIndices = {}
	for _, item in pairs(self.Bin:getItems()) do
		local amount = itemIndices[item.index] or 0
		amount = amount + 1
		itemIndices[item.index] = amount
	end
	return itemIndices
end

function Client_ErrorRefresh(message)
	Win.waitingForServer = false
	PrintError(message)
end

function Client_Refresh(newIndex)
	onShowWindow()
	Win.waitingForServer = false
	local newItem
	local newPos

	for position, item in pairs(Win.Inv:getItems()) do
		if item.index == newIndex then
			newPos = position
			newItem = item
			break
		end
	end

	if newItem ~= nil and newPos ~= nil then
		Win:moveItem(newItem, Win.Inv, Win.Item, newPos, ivec2(0, 0))
	end

	Win:UpdateFields()
	Win:UpdateBinLabel()
end

function Win:Client_ApplyBuff(buffType)
	if self.waitingForServer then return PrintInfo("Processing, please wait") end

	local upgradeTurret = Win:GetCurrentItem()
	if not upgradeTurret then return PrintError("No turret selected") end

	local scrapTurretIndices = Win:Client_GetScrapTurretIndices()
	if tablelength(scrapTurretIndices) < 1 then return PrintError("No scrap turrets provided") end

	self.waitingForServer = true
	invokeServerFunction("Server_ApplyBuff", buffType, upgradeTurret.index, scrapTurretIndices)
end

function Win:OnClickedBtnEfficiency()
	Win:Client_ApplyBuff("efficiency")
end

function Win:OnClickedBtnTargeting()
	if self.waitingForServer then return PrintInfo("Processing, please wait") end

	local upgradeTurret = Win:GetCurrentItem()
	if not upgradeTurret then return PrintError("No turret selected") end

	invokeServerFunction("Server_ToggleTargeting", upgradeTurret.index)
end

function Win:OnClickedBtnColour()
	if self.waitingForServer then return PrintInfo("Processing, please wait") end

	local upgradeTurret = Win:GetCurrentItem()
	if not upgradeTurret then return PrintError("No turret selected") end

	local newColour = Color()
	newColour:setHSV(
		self.NumColourHue.value,
		self.NumColourSat.value,
		self.NumColourVal.value
	)

	invokeServerFunction("Server_SetColour", upgradeTurret.index, newColour)
end

--------------------------------------------------------------------------------

function TurretModdingUI_Update(NewCurrentIndex)

	Win:PopulateInventory(NewCurrentIndex)
	Win:UpdateFields()
	Win:UpdateBinLabel()
	return
end

function TurretModdingUI_OnInit(...) Win:OnInit(...) end
function TurretModdingUI_OnItemClicked(...) Win:OnItemClicked(...) end
function TurretModdingUI_OnItemAdded(...) Win:OnItemAdded(...) end
function TurretModdingUI_OnBinClicked(...) Win:OnBinClicked(...) end
function TurretModdingUI_OnBinAdded(...) Win:OnBinAdded(...) end
function TurretModdingUI_OnInvClicked(...) Win:OnInvClicked(...) end
function TurretModdingUI_OnInvAdded(...) Win:OnInvAdded(...) end
function TurretModdingUI_OnUpdatePreviewColour(...) Win:OnUpdatePreviewColour(...) end

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

function initialize()
	-- script bootstrapping.

	-- print("TurretModding:initalize")

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

function PullConfigFromServer(ToPlayer,InputConfig)
	-- handle pulling the config from the server.

	if(onServer()) then
		-- when this function runs server side we need to load the config
		-- and send it back to the client.

		Config = require("mods.DccTurretEditor.Common.ConfigLib")
		local InputConfig = Config
		-- print("[DccTurretEditor] Sending Config To Client")
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

function initUI()
	-- ui bootstrapping.

	if(onServer())
	then return end

	Win:OnInit()
	return
end

-------- Server Logic ---------
if not onServer() then return end

function Server_GetUpgradeTurret(player, upgradeTurretIndex)
	local turret = player:getInventory():find(upgradeTurretIndex)
	if not turret then
		Server_RefreshErrorClient(player, "The selected upgrade turret is not in your inventory anymore.")
		return nil
	end
	return turret
end

function Server_GetRequiredIngredients(upgradeTurretIndex, scrapTurretIndices)
	local ingredients = {}

	-- All scrap turrets will be consumed
	for index, required in pairs(scrapTurretIndices) do
		ingredients[index] = required
	end

	-- Also the upgraded turret
	local amount = ingredients[upgradeTurretIndex] or 0
	ingredients[upgradeTurretIndex] = amount + 1

	return ingredients
end

function Server_HasAllIngredients(player, requiredIngredients)
	local inventory = player:getInventory()

	for index, required in pairs(requiredIngredients) do
		if inventory:amount(index) < required then
			Server_RefreshErrorClient(player, "One of the selected scrap turrets is not in your inventory anymore.")
			return false
		end
	end

	return true
end

function Server_GetPlayer()
	local player
	if callingPlayer then player = Player(callingPlayer) end
	if not player then PrintDebug("NOT A PLAYER") end
	return player
end

function Server_CheckCost(player, cost)
	if(player.money < cost) then
		Server_RefreshErrorClient(player, "You need "..cost.." credits to perform this upgrade")
		return false
	end
	return true
end

function Server_AddNewTurret(player, newTurret)
	local playerInventory = player:getInventory()

	playerInventory:add(newTurret)

	local newIndex = -1

	for index, items in pairs(playerInventory:getItemsByType(InventoryItemType.Turret)) do
		if newTurret:__eq(items.item) then
			newIndex = index
			break
		end
	end

	Server_RefreshClient(player, newIndex)
end

function Server_RefreshErrorClient(player, errorMessage)
	invokeClientFunction(player, "Client_ErrorRefresh", errorMessage)
end

function Server_RefreshClient(player, newIndex)
	invokeClientFunction(player, "Client_Refresh", newIndex)
end

function Server_ToggleTargeting(upgradeTurretIndex)
	local player = Server_GetPlayer()
	if not player then return end

	local upgradeTurret = Server_GetUpgradeTurret(player, upgradeTurretIndex)
	if not upgradeTurret then return end

	local cost = Config.CostTargeting
	if not Server_CheckCost(player, cost) then return end

	local newTurret = InventoryTurret(upgradeTurret:template())

	TurretLib:ToggleWeaponTargeting(newTurret)

	player:pay("", cost)
	player:getInventory():remove(index)
	Server_AddNewTurret(player, newTurret)
end

function Server_SetColour(upgradeTurretIndex, newColour)
	local player = Server_GetPlayer()
	if not player then return end

	local upgradeTurret = Server_GetUpgradeTurret(player, upgradeTurretIndex)
	if not upgradeTurret then return end

	local cost = Config.CostColour
	if not Server_CheckCost(player, cost) then return end

	local newTurret = InventoryTurret(upgradeTurret:template())

	TurretLib:SetWeaponColour(newTurret, newColour)

	player:pay("", cost)
	player:getInventory():remove(index)
	Server_AddNewTurret(player, newTurret)
end

function Server_ApplyBuff(buffType, upgradeTurretIndex, scrapTurretIndices)
	local player = Server_GetPlayer()
	if not player then return end

	if tablelength(scrapTurretIndices) < 1 then return Server_RefreshErrorClient(player, "No scrap turrets provided") end

	local playerInventory = player:getInventory()

	local upgradeTurret = Server_GetUpgradeTurret(player, upgradeTurretIndex)
	if not upgradeTurret then return end

	local ingredients = Server_GetRequiredIngredients(upgradeTurretIndex, scrapTurretIndices)
	if not Server_HasAllIngredients(player, ingredients) then end

	local buff = Win:CalculateBinItems(upgradeTurretIndex, scrapTurretIndices)

	local template = upgradeTurret:template()
	local newTurret = InventoryTurret(template)

	if buffType == "damage" then
		if TurretLib:GetWeaponDamage(newTurret) == 0 then return Server_RefreshErrorClient(player, "This turret does not do any damage") end
		TurretLib:ModWeaponDamage(newTurret, buff)
	elseif buffType == "heat" then
		if TurretLib:GetWeaponHeatRate(newTurret) == 0 then return Server_RefreshErrorClient(player, "This turret does not produce any heat") end
		TurretLib:ModWeaponHeatRate(newTurret, buff)
	elseif buffType == "accuracy" then
		if TurretLib:GetWeaponAccuracy(newTurret) == 0 then return Server_RefreshErrorClient(player, "This turret does not have accuracy") end
		TurretLib:ModWeaponAccuracy(newTurret, buff)
	elseif buffType == "fireRate" then
		if TurretLib:GetWeaponFireRate(newTurret) == 0 then return Server_RefreshErrorClient(player, "This turret does not have a fire rate") end
		TurretLib:ModWeaponFireRate(newTurret, buff)
	elseif buffType == "range" then
		if TurretLib:GetWeaponRange(newTurret) == 0 then return Server_RefreshErrorClient(player, "This turret has no reach apparently") end
		TurretLib:ModWeaponRange(newTurret, buff)
	elseif buffType == "tracking" then
		if TurretLib:GetWeaponSpeed(newTurret) == 0 then return Server_RefreshErrorClient(player, "This turret has no tracking speed") end
		TurretLib:ModWeaponSpeed(newTurret, buff)
	elseif buffType == "baseEnergy" then
		if TurretLib:GetWeaponBaseEnergy(newTurret) == 0 then return Server_RefreshErrorClient(player, "This turret does not require any power") end
		TurretLib:ModWeaponBaseEnergy(newTurret, buff)
	elseif buffType == "accumulatedEnergy" then
		if TurretLib:GetWeaponAccumEnergy(newTurret) == 0 then return Server_RefreshErrorClient(player, "This turret does not demand additional power") end
		TurretLib:ModWeaponAccumEnergy(newTurret, buff)
	elseif buffType == "efficiency" then
		local eff = TurretLib:GetWeaponEfficiency(newTurret)
		if eff == 0 then return Server_RefreshErrorClient(player, "This turret has no efficiency") end
		if eff >= 1 then return Server_RefreshErrorClient(player, "This turret is at maximum efficiency") end
		TurretLib:ModWeaponEfficiency(newTurret, buff)
	else
		return Server_RefreshErrorClient(player, "Invalid buff type: " .. buffType)
	end

	-- Consume all ingredients (upgrade turret + scrap turrets)
	for index, amount in pairs(ingredients) do
		for i=1,amount do
			playerInventory:remove(index)
		end
	end

	Server_AddNewTurret(player, newTurret)
end