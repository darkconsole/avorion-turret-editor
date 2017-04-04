package.path = package.path
.. ";data/scripts/lib/?.lua"
.. ";data/scripts/sector/?.lua"
.. ";data/scripts/?.lua"

-- vscode-fold=1

require ("galaxy")
require ("utility")
require ("faction")
require ("player")
require ("randomext")
require ("stringutility")

SellableII = require("sellableinventoryitem")

--------------------------------------------------------------------------------

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

function GetWeaponColour(Which,Item)

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList)
	do
		if(Which == "projectile")
		then
			return Weap.pcolor
		elseif(Which == "core")
		then
			return Weap.binnerColor
		elseif(Which == "glow")
		then
			return Weap.bouterColor
		end
	end

	return
end

function SetWeaponColour(Which,Item,Colour)

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

function GetWeaponRange(Item)
-- get weapon range in km.

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList)
	do
		return Weap.reach / 100
	end

	return
end

function SetWeaponRange(Item,Dist)
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

function GetWeaponRate(Item)
-- get weapon range in km.

	local WeapList = {Item:getWeapons()}

	for WeapIter,Weap in pairs(WeapList)
	do
		return Weap.fireRate
	end

	return
end

function SetWeaponRate(Item,Val)
-- set weapon range in km.

	local WeapList = {Item:getWeapons()}
	Item:clearWeapons()

	for WeapIter,Weap in pairs(WeapList)
	do
		Weap.fireRate = Val
		Item:addWeapon(Weap)
	end

	return
end

function ReplaceInventoryItem(Index,Item,Count)
-- replace the inventory item at the specified index with the specified thing.
-- this hot swaps the thing with the updated version.

	if(onClient())
	then
		invokeServerFunction("ReplaceInventoryItem",Index,Item,Count)
		return
	end

	print("replacing item "..Index)

	local Armory = Player():getInventory()
	Armory:removeAll(Index)
	Armory:addAt(Item,Index,Count)

	invokeClientFunction(Player(),"Win_Update")
	return
end

--------------------------------------------------------------------------------

local Win = {
	Title = "Turret Editor",

	Window = nil,
	Item   = nil,
	ItemLabel = nil,
	Inv    = nil,

	LabelProjColour = nil,
	InputProjColourH = nil,
	InputProjColourS = nil,
	InputProjColourV = nil,
	ApplyProjColour = nil,

	LabelCoreColour = nil,
	InputCoreColourH = nil,
	InputCoreColourS = nil,
	InputCoreColourV = nil,
	ApplyCoreColour = nil,

	LabelGlowColour = nil,
	InputGlowColourH = nil,
	InputGlowColourS = nil,
	InputGlowColourV = nil,
	ApplyGlowColour = nil,

	InputRange = nil,
	ApplyRange = nil,

	InputRate = nil,
	ApplyRate = nil,

	InputHeat = nil,
	ApplyHeat = nil,

	InputEnergy = nil,
	ApplyEnergy = nil,

	InputTracking = nil,
	ApplyTracking = nil,

	LabelTargeting = nil,
	ToggleTargeting = nil,

	InputSize = nil,
	ApplySize = nil,

	UI = nil,
	Res = nil,
	Size = nil
}

function Win:OnInit()

	self.Res = getResolution()
	self.Size = vec2(900,600)
	self.UI = ScriptUI()

	self.Window = self.UI:createWindow(Rect(
		(self.Res * 0.5 - self.Size * 0.5),
		(self.Res * 0.5 + self.Size * 0.5)
	))

	self.Window.caption = self.Title
	self.Window.showCloseButton = 1
	self.Window.moveable = 1
	self.UI:registerWindow(self.Window,self.Title)

	self:BuildUI()
	self:PopulateInventory()
	return
end

function Win:BuildUI()

	local Pane = UIHorizontalSplitter(
		Rect(self.Window.size),
		10, 10, 0.6
	)

	local TPane = UIVerticalSplitter(
		Pane.top,
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
	local LineHeight1 = FontSize1 + 4

	-- create the drop target for the editor.

	self.Item = self.Window:createSelection(Rect(0,0,128,128),1)
	self.Item.dropIntoEnabled = 1
	self.Item.entriesSelectable = 0
	self.Item.onClickedFunction = "Win_OnItemClicked"
	self.Item.onReceivedFunction = "Win_OnItemAdded"
	self.Item.onDroppedFunction = "Win_OnItemRemoved"
	TLPane:placeElementCenter(self.Item)

	self.ItemLabel = self.Window:createLabel(self.Item.position,"Current Turret",FontSize1-4)
	self.ItemLabel.centered = true
	self.ItemLabel.width = self.Item.width
	self.ItemLabel.position = self.Item.position - vec2(0,LineHeight1)

	-- create the list of things in your inventory

	self.Inv = self.Window:createSelection(Pane.bottom,12)
	self.Inv.onClickedFunction = "Win_OnInvClicked"

	-- create the list of things you can do.

	local Frame = self.Window:createFrame(TRPane.rect)
	local Element
	local Rows = 8
	local Cols = 3

	-- projectile colour

	self.LabelProjColour = self.Window:createLabel(
		FramedRect(TRPane,1,1,Cols,Rows).topLeft,
		"Projectile Colour HSV:",
		FontSize1
	)
	self.LabelProjColour.centered = true
	self.LabelProjColour.width = FramedRect(TRPane,1,1,Cols,Rows).width
	self.LabelProjColour.height = FramedRect(TRPane,1,1,Cols,Rows).height
	self.LabelProjColour:setRightAligned()

	self.InputProjColourH = self.Window:createTextBox(
		FramedRect(TRPane,4,1,(Cols*3),Rows),
		"Win_OnChangedProjColour"
	)
	self.InputProjColourS = self.Window:createTextBox(
		FramedRect(TRPane,5,1,(Cols*3),Rows),
		"Win_OnChangedProjColour"
	)
	self.InputProjColourV = self.Window:createTextBox(
		FramedRect(TRPane,6,1,(Cols*3),Rows),
		"Win_OnChangedProjColour"
	)

	self.ApplyProjColour = self.Window:createButton(
		FramedRect(TRPane,3,1,Cols,Rows),
		"Apply",
		"Win_OnClickedProjColour"
	)

	-- core colour

	self.LabelCoreColour = self.Window:createLabel(
		FramedRect(TRPane,1,2,Cols,Rows).topLeft,
		"Core Colour HSV:",
		FontSize1
	)
	self.LabelCoreColour.width = FramedRect(TRPane,1,2,Cols,Rows).width
	self.LabelCoreColour.height = FramedRect(TRPane,1,2,Cols,Rows).height
	self.LabelCoreColour:setRightAligned()

	self.InputCoreColourH = self.Window:createTextBox(
		FramedRect(TRPane,4,2,(Cols*3),Rows),
		"Win_OnChangedCoreColour"
	)
	self.InputCoreColourS = self.Window:createTextBox(
		FramedRect(TRPane,5,2,(Cols*3),Rows),
		"Win_OnChangedCoreColour"
	)
	self.InputCoreColourV = self.Window:createTextBox(
		FramedRect(TRPane,6,2,(Cols*3),Rows),
		"Win_OnChangedCoreColour"
	)

	self.ApplyCoreColour = self.Window:createButton(
		FramedRect(TRPane,3,2,Cols,Rows),
		"Apply",
		"Win_OnClickedCoreColour"
	)

	-- glow colour

	self.LabelGlowColour = self.Window:createLabel(
		FramedRect(TRPane,1,3,Cols,Rows).topLeft,
		"Glow Colour HSV:",
		FontSize1
	)
	self.LabelGlowColour.width = FramedRect(TRPane,1,3,Cols,Rows).width
	self.LabelGlowColour.height = FramedRect(TRPane,1,3,Cols,Rows).height
	self.LabelGlowColour:setRightAligned()

	self.InputGlowColourH = self.Window:createTextBox(
		FramedRect(TRPane,4,3,(Cols*3),Rows),
		"Win_OnChangedGlowColour"
	)
	self.InputGlowColourS = self.Window:createTextBox(
		FramedRect(TRPane,5,3,(Cols*3),Rows),
		"Win_OnChangedGlowColour"
	)
	self.InputGlowColourV = self.Window:createTextBox(
		FramedRect(TRPane,6,3,(Cols*3),Rows),
		"Win_OnChangedGlowColour"
	)

	self.ApplyGlowColour = self.Window:createButton(
		FramedRect(TRPane,3,3,Cols,Rows),
		"Apply",
		"Win_OnClickedGlowColour"
	)

	-- targeting toggle

	Cols = 8

	self.LabelTargeting = self.Window:createLabel(
		FramedRect(TRPane,1,5,Cols,Rows).topLeft,
		"n/a",
		FontSize1
	)
	self.LabelTargeting.width = FramedRect(TRPane,1,Cols,9,Rows).width
	self.LabelTargeting.height = FramedRect(TRPane,1,Cols,9,Rows).height
	self.LabelTargeting:setRightAligned()

	self.ToggleTargeting = self.Window:createButton(
		FramedRect(TRPane,2,5,Cols,Rows),
		"Targeting",
		"Win_OnClickedTargeting"
	)

	-- energy

	self.InputEnergy = self.Window:createTextBox(
		FramedRect(TRPane,4,5,Cols,Rows),
		"Win_OnTextBoxChanged"
	)

	self.ApplyEnergy = self.Window:createButton(
		FramedRect(TRPane,5,5,Cols,Rows),
		"Eng/Sec",
		"Win_OnClickedEnergy"
	)

	-- heat

	self.InputHeat = self.Window:createTextBox(
		FramedRect(TRPane,7,5,Cols,Rows),
		"Win_OnTextBoxChanged"
	)

	self.ApplyHeat = self.Window:createButton(
		FramedRect(TRPane,8,5,Cols,Rows),
		"Heat",
		"Win_OnClickedHeat"
	)

	-- tracking

	self.InputTracking = self.Window:createTextBox(
		FramedRect(TRPane,1,6,Cols,Rows),
		"Win_OnTextBoxChanged"
	)

	self.ApplyTracking = self.Window:createButton(
		FramedRect(TRPane,2,6,Cols,Rows),
		"Speed",
		"Win_OnClickedTracking"
	)

	-- range

	self.InputRange = self.Window:createTextBox(
		FramedRect(TRPane,4,6,Cols,Rows),
		"Win_OnTextBoxChanged"
	)

	self.ApplyRange = self.Window:createButton(
		FramedRect(TRPane,5,6,Cols,Rows),
		"Range",
		"Win_OnClickedRange"
	)

	-- rate

	self.InputRate = self.Window:createTextBox(
		FramedRect(TRPane,7,6,Cols,Rows),
		"Win_OnTextBoxChanged"
	)

	self.ApplyRate = self.Window:createButton(
		FramedRect(TRPane,8,6,Cols,Rows),
		"F.Rate",
		"Win_OnClickedRate"
	)

	-- size

	self.InputSize = self.Window:createTextBox(
		FramedRect(TRPane,1,8,Cols,Rows),
		"Win_OnTextBoxChanged"
	)

	self.ApplyRate = self.Window:createButton(
		FramedRate(TRPane,2,8,Cols,Rows),
		"Size",
		"Win_OnClickedSize"
	)

	return
end

function Win:PopulateInventory()
-- most of the structure for this function was stolen from the vanilla research
-- station script. it reads your inventory and creates a visible list of all
-- the turrets you can drag drop.

	local ItemList = {}
	local Me = Player()

	self.Inv:clear()

	-- throw everything that makes sense into a table so we can sort it.

	for Iter, Thing in pairs(Me:getInventory():getItems()) do
		if(Thing.item.itemType == InventoryItemType.Turret or Thing.item.itemType == InventoryItemType.TurretTemplate)
		then
			local Item = SellableII(Thing.item,Iter,Me)
			table.insert(ItemList,Item)
		end
	end

	-- @todo
	-- sorting

	-- now create items in our dialog to represent the inventory items.

	for Iter, Thing in pairs(ItemList) do
		local Item = SelectionItem()

		Item.item = Thing.item

		-- this is our link to the exact item in the actual inventory. we will
		-- use this value to delete the original since we have to recreate it
		-- with the modifications applied.
		Item.uvalue = Thing.index

		if(Thing.item.stackable)
		then
			Item.amount = Thing.amount
		end

		self.Inv:add(Item)
	end

	return
end

function Win:GetCurrentItemIndex()

	local Item = self.Item:getItem(ivec2(0,0))

	if(Item == nil)
	then return nil end

	print("weapon " .. Item.item.weaponName)

	return Item.uvalue
end

function Win:GetCurrentItemCount()

	return self.Item:getItem(ivec2(0,0)).amount
end

function Win:GetCurrentItemReal()
-- get the turret we are trying to edit.

	return Player():getInventory():find(
		 self:GetCurrentItemIndex()
	)
end

function Win:GetCurrentItem()
-- get the turret we are trying to edit.

	return self.Item:getItem(ivec2(0,0))
end

function Win:GetCurrentItems()

	return self:GetCurrentItem(), self:GetCurrentItemReal()
end

function Win:UpdateItem(Item)

	self.Item:clear()
	self.Item:add(Item)
	self:UpdateFields()
	return
end

function Win:UpdateItemReal(Item)

	print("update item real " .. Index)

	ReplaceInventoryItem(
		self:GetCurrentItemIndex(),
		Item,
		self:GetCurrentItemCount()
	)

	return
end

function Win:UpdateItems(Item,Real)
	Item.item = Real

	self:UpdateItem(Item)
	self:UpdateItemReal(Real)
	return
end

function Win:UpdateFields()

	Item = self:GetCurrentItemReal()

	self:UpdateFields_ProjectileColour(Item)
	self:UpdateFields_CoreColour(Item)
	self:UpdateFields_GlowColour(Item)
	self:UpdateFields_Targeting(Item)
	self:UpdateFields_Energy(Item)
	self:UpdateFields_Heat(Item)
	self:UpdateFields_Tracking(Item)
	self:UpdateFields_Range(Item)
	self:UpdateFields_Rate(Item)
	self:UpdateFields_Size(Item)

	self:OnChangedProjColour()
	self:OnChangedCoreColour()
	self:OnChangedGlowColour()

	return
end

function Win:UpdateFields_ProjectileColour(Item)

	if(Item == nil or GetWeaponColour("projectile",Item) == nil)
	then
		self.InputProjColourH.text = ""
		self.InputProjColourS.text = ""
		self.InputProjColourV.text = ""
		self.ApplyProjColour.caption = "n/a"
		return
	end

	local Colour = GetWeaponColour("projectile",Item)
	self.InputProjColourH.text = round(Colour.hue,2)
	self.InputProjColourS.text = round(Colour.saturation,2)
	self.InputProjColourV.text = round(Colour.value,2)
	self.ApplyProjColour.caption = "Apply"

	return
end

function Win:UpdateFields_CoreColour(Item)

	if(Item == nil or GetWeaponColour("core",Item) == nil)
	then
		self.InputCoreColourH.text = ""
		self.InputCoreColourS.text = ""
		self.InputCoreColourV.text = ""
		self.ApplyCoreColour.caption = "n/a"
		return
	end

	local Colour = GetWeaponColour("core",Item)
	self.InputCoreColourH.text = round(Colour.hue,2)
	self.InputCoreColourS.text = round(Colour.saturation,2)
	self.InputCoreColourV.text = round(Colour.value,2)
	self.ApplyCoreColour.caption = "Apply"

	return
end

function Win:UpdateFields_GlowColour(Item)

	if(Item == nil or GetWeaponColour("glow",Item) == nil)
	then
		self.InputGlowColourH.text = ""
		self.InputGlowColourS.text = ""
		self.InputGlowColourV.text = ""
		self.ApplyGlowColour.caption = "n/a"
		return
	end

	local Colour = GetWeaponColour("glow",Item)
	self.InputGlowColourH.text = round(Colour.hue,2)
	self.InputGlowColourS.text = round(Colour.saturation,2)
	self.InputGlowColourV.text = round(Colour.value,2)
	self.ApplyGlowColour.caption = "Apply"

	return
end

function Win:UpdateFields_Targeting(Item)

	if(Item == nil or not Item.automatic)
	then
		self.LabelTargeting.caption = "Off"
		self.LabelTargeting.color = ColorHSV(12,1,1)
	else
		self.LabelTargeting.caption = "On"
		self.LabelTargeting.color = ColorHSV(80,1,1)
	end

	return
end

function Win:UpdateFields_Energy(Item)

	if(Item == nil)
	then
		self.InputEnergy.text = ""
		return
	end

	self.InputEnergy.text = Item.energyIncreasePerSecond
	return
end

function Win:UpdateFields_Heat(Item)

	if(Item == nil)
	then
		self.InputHeat.text = ""
		return
	end

	self.InputHeat.text = Item.heatPerShot
	return
end

function Win:UpdateFields_Tracking(Item)

	if(Item == nil)
	then
		self.InputTracking.text = ""
		return
	end

	self.InputTracking.text = Item.turningSpeed
	return
end

function Win:UpdateFields_Range(Item)

	if(Item == nil)
	then
		self.InputRange.text = ""
		return
	end

	self.InputRange.text = GetWeaponRange(Item)
	return
end

function Win:UpdateFields_Rate(Item)

	if(Item == nil)
	then
		self.InputRate.text = ""
		return
	end

	self.InputRate.text = GetWeaponRate(Item)
	return
end

function Win:UpdateFields_Size(Item)

	if(Item == nil)
	then
		self.InputSize.text = ""
		return
	end

	self.InputSize.text = Item.size
	return
end

--------------------------------------------------------------------------------

function Win:OnItemAdded(SelectID, FX, FY, Item, FromIndex, ToIndex, TX, TY)

	print("=== Win:OnItemAdded ===")
	print("SelectID: " .. SelectID)
	print("FX/Y: " .. FX .. "," .. FY)
	print("TX/Y: " .. TX .. "," .. TY)
	print("From/To: " .. FromIndex .. " -> " .. ToIndex)
	print("")

	print("selected " .. Item.uvalue)

	self.Item:clear()
	self.Item:add(Item)
	self:UpdateFields()

	return
end

function Win:OnItemRemoved(SelectID, FX, FY)

	print("=== Win:OnItemRemoved ===")
	print("SelectID: " .. SelectID)
	print("FX/Y: " .. FX .. "," .. FY)
	print("")

	self.Item:clear()
	self:UpdateFields()
	return
end

function Win:OnItemClicked(SelectID, FX, FY, Item, Button)

	print("=== Win:OnItemClicked ===")
	print("SelectID: " .. SelectID)
	print("FX/Y: " .. FX .. "," .. FY)
	print("Button: " .. Button)
	print("")

	-- emulate the dialogs that already exist in the game, when the item is
	-- right clicked clear it from the selection place.

	if(Button == 3)
	then
		self.Item:clear()
		return
	end

	return
end

function Win:OnInvClicked(SelectID, FX, FY, Item, Button)

	print("=== Win:OnInvClicked ===")
	print("SelectID: " .. SelectID)
	print("FX/Y: " .. FX .. "," .. FY)
	print("Button: " .. Button)
	print("")

	-- emulate the dialogs that already exist in the game, when the item is
	-- right clicked add it to the selection place.

	if(Button == 3)
	then
		self.Item:clear()
		self.Item:add(Item)
		self:UpdateFields()
	end

	return
end

function Win:OnClickedProjColour(Btn)

	if(not self:GetCurrentItemIndex())
	then return end

	local Item, Real = self:GetCurrentItems()
	local H = tonumber(self.InputProjColourH.text) or 0
	local S = tonumber(self.InputProjColourS.text) or 1
	local V = tonumber(self.InputProjColourV.text) or 1

	print("Projectile Colour: "..H..","..S..","..V)
	SetWeaponColour("projectile",Real,ColorHSV(H,S,V))

	self:UpdateItems(Item,Real)
	return
end

function Win:OnClickedCoreColour(Btn)

	if(not self:GetCurrentItemIndex())
	then return end

	local Item, Real = self:GetCurrentItems()
	local H = tonumber(self.InputCoreColourH.text) or 0
	local S = tonumber(self.InputCoreColourS.text) or 1
	local V = tonumber(self.InputCoreColourV.text) or 1

	print("Core Colour: "..H..","..S..","..V)
	SetWeaponColour("core",Real,ColorHSV(H,S,V))

	self:UpdateItems(Item,Real)
	return
end

function Win:OnClickedGlowColour(Btn)

	if(not self:GetCurrentItemIndex())
	then return end

	local Item, Real = self:GetCurrentItems()
	local H = tonumber(self.InputGlowColourH.text) or 0
	local S = tonumber(self.InputGlowColourS.text) or 1
	local V = tonumber(self.InputGlowColourV.text) or 1

	print("Glow Colour: "..H..","..S..","..V)
	SetWeaponColour("glow",Real,ColorHSV(H,S,V))

	self:UpdateItems(Item,Real)
	return
end

function Win:OnClickedTargeting()

	if(not self:GetCurrentItemIndex())
	then return end

	print("Toggle Targeting")
	local Item, Real = self:GetCurrentItems()

	Real.automatic = not Real.automatic

	self:UpdateItems(Item,Real)
	return
end

function Win:OnClickedEnergy()

	if(not self:GetCurrentItemIndex())
	then return end

	print("Set Energy Buildup")
	local Item, Real = self:GetCurrentItems()

	Real.energyIncreasePerSecond = round(tonumber(self.InputEnergy.text),2)

	self:UpdateItems(Item,Real)
end

function Win:OnClickedHeat()

	if(not self:GetCurrentItemIndex())
	then return end

	print("Set Heat Buildup")
	local Item, Real = self:GetCurrentItems()

	Real.heatPerShot = round(tonumber(self.InputHeat.text),2)

	self:UpdateItems(Item,Real)
end

function Win:OnClickedTracking()

	if(not self:GetCurrentItemIndex())
	then return end

	print("Set Tracking Speed")
	local Item, Real = self:GetCurrentItems()

	Real.turningSpeed = round(tonumber(self.InputTracking.text),2)

	self:UpdateItems(Item,Real)
end

function Win:OnClickedRange()

	if(not self:GetCurrentItemIndex())
	then return end

	print("Set Range")
	local Item, Real = self:GetCurrentItems()

	SetWeaponRange(Real,round(tonumber(self.InputRange.text),2))

	self:UpdateItems(Item,Real)
end

function Win:OnClickedRate()

	if(not self:GetCurrentItemIndex())
	then return end

	print("Set Fire Rate")
	local Item, Real = self:GetCurrentItems()

	SetWeaponRate(Real,round(tonumber(self.InputRate.text),2))

	self:UpdateItems(Item,Real)
end

function Win:OnClickedSize()

	if(not self:GetCurrentItemIndex())
	then return end

	print("Set Turret Size")
	local Item, Real = self:GetCurrentItems()

	Real.size = round(tonumber(self.InputSize.text),2)

	self:UpdateItems(Item,Real)
end

function Win:OnChangedProjColour()

	self.LabelProjColour.color = ColorHSV(
		round(tonumber(self.InputProjColourH.text) or 0),
		round(tonumber(self.InputProjColourS.text) or 1),
		round(tonumber(self.InputProjColourV.text) or 1)
	)

	return
end

function Win:OnChangedCoreColour()

	self.LabelCoreColour.color = ColorHSV(
		round(tonumber(self.InputCoreColourH.text) or 1),
		round(tonumber(self.InputCoreColourS.text) or 1),
		round(tonumber(self.InputCoreColourV.text) or 1)
	)

	return
end

function Win:OnChangedGlowColour()

	self.LabelGlowColour.color = ColorHSV(
		round(tonumber(self.InputGlowColourH.text) or 1),
		round(tonumber(self.InputGlowColourS.text) or 1),
		round(tonumber(self.InputGlowColourV.text) or 1)
	)

	return
end

--------------------------------------------------------------------------------

function Win_Update(...)

	Win:PopulateInventory()
	Win:UpdateFields()
	return
end

function Win_OnItemAdded(...) Win:OnItemAdded(...) end
function Win_OnItemClicked(...) Win:OnItemClicked(...) end
function Win_OnItemRemoved(...) Win:OnItemRemoved(...) end
function Win_OnInvClicked(...) Win:OnInvClicked(...) end

function Win_OnClickedProjColour(...) Win:OnClickedProjColour(...) end
function Win_OnClickedCoreColour(...) Win:OnClickedCoreColour(...) end
function Win_OnClickedGlowColour(...) Win:OnClickedGlowColour(...) end
function Win_OnClickedTargeting(...) Win:OnClickedTargeting(...) end
function Win_OnClickedEnergy(...) Win:OnClickedEnergy(...) end
function Win_OnClickedHeat(...) Win:OnClickedHeat(...) end
function Win_OnClickedTracking(...) Win:OnClickedTracking(...) end
function Win_OnClickedRange(...) Win:OnClickedRange(...) end
function Win_OnClickedRate(...) Win:OnClickedRate(...) end
function Win_OnChangedProjColour(...) Win:OnChangedProjColour(...) end
function Win_OnChangedCoreColour(...) Win:OnChangedCoreColour(...) end
function Win_OnChangedGlowColour(...) Win:OnChangedGlowColour(...) end

function Win_OnTextBoxChanged(...) end
function Win_OnButtonClicked(...) end

--------------------------------------------------------------------------------

-- these are methods that the ui access of the game needs.

function interactionPossible(Player)
	return true, ""
end

function getIcon(Seed, Rarity)
	return "data/textures/icons/cash.png"
end

function onCloseWindow()
	print("onCloseWindow")
	return
end

function onShowWindow()
	print("onShowWindow")

	Win.Item:clear()
	Win.Inv:clear()

	Win:PopulateInventory()
	return
end

function initialize()
-- script bootstrapping.

	if(onServer())
	then return end

	print("initialize")

	return
end

function initUI()
-- ui bootstrapping.

	if(onServer())
	then return end

	print("initUI()")
	Win:OnInit()

	return
end


