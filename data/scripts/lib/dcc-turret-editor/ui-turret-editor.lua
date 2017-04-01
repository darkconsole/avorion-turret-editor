package.path = package.path
.. ";data/scripts/lib/?.lua"
.. ";data/scripts/sector/?.lua"
.. ";data/scripts/?.lua"

require ("galaxy")
require ("utility")
require ("faction")
require ("player")
require ("randomext")
require ("stringutility")

SellableII = require("sellableinventoryitem")

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
			Weap.bouterColour = Colour
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
	local Rows = 6
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
		"Win_OnTextBoxChanged"
	)
	self.InputProjColourS = self.Window:createTextBox(
		FramedRect(TRPane,5,1,(Cols*3),Rows),
		"Win_OnTextBoxChanged"
	)
	self.InputProjColourV = self.Window:createTextBox(
		FramedRect(TRPane,6,1,(Cols*3),Rows),
		"Win_OnTextBoxChanged"
	)

	self.ApplyProjColour = self.Window:createButton(
		FramedRect(TRPane,3,1,Cols,Rows),
		"Apply",
		"Win_OnButtonClicked"
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
		"Win_OnTextBoxChanged"
	)
	self.InputCoreColourS = self.Window:createTextBox(
		FramedRect(TRPane,5,2,(Cols*3),Rows),
		"Win_OnTextBoxChanged"
	)
	self.InputCoreColourV = self.Window:createTextBox(
		FramedRect(TRPane,6,2,(Cols*3),Rows),
		"Win_OnTextBoxChanged"
	)

	self.ApplyCoreColour = self.Window:createButton(
		FramedRect(TRPane,3,2,Cols,Rows),
		"Apply",
		"Win_OnButtonClicked"
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
		"Win_OnTextBoxChanged"
	)
	self.InputGlowColourS = self.Window:createTextBox(
		FramedRect(TRPane,5,3,(Cols*3),Rows),
		"Win_OnTextBoxChanged"
	)
	self.InputGlowColourV = self.Window:createTextBox(
		FramedRect(TRPane,6,3,(Cols*3),Rows),
		"Win_OnTextBoxChanged"
	)

	self.ApplyGlowColour = self.Window:createButton(
		FramedRect(TRPane,3,3,Cols,Rows),
		"Apply",
		"Win_OnButtonClicked"
	)

	-- targeting toggle

	Cols = 8

	self.LabelTargeting = self.Window:createLabel(
		FramedRect(TRPane,1,5,Cols,Rows).topLeft,
		"On",
		FontSize1
	)
	self.LabelTargeting.color = ColorHSV(80,1,1)
	self.LabelTargeting.width = FramedRect(TRPane,1,Cols,9,Rows).width
	self.LabelTargeting.height = FramedRect(TRPane,1,Cols,9,Rows).height
	self.LabelTargeting:setRightAligned()

	self.ToggleTargeting = self.Window:createButton(
		FramedRect(TRPane,2,5,Cols,Rows),
		"Targeting",
		"Win_OnButtonClicked"
	)

	-- energy

	self.InputEnergy = self.Window:createTextBox(
		FramedRect(TRPane,4,5,Cols,Rows),
		"Win_OnTextBoxChanged"
	)

	self.ApplyEnergy = self.Window:createButton(
		FramedRect(TRPane,5,5,Cols,Rows),
		"Eng/Sec",
		"Win_OnButtonClicked"
	)

	-- heat

	self.InputHeat = self.Window:createTextBox(
		FramedRect(TRPane,7,5,Cols,Rows),
		"Win_OnTextBoxChanged"
	)

	self.ApplyHeat = self.Window:createButton(
		FramedRect(TRPane,8,5,Cols,Rows),
		"Heat",
		"Win_OnButtonClicked"
	)

	-- tracking

	self.InputTracking = self.Window:createTextBox(
		FramedRect(TRPane,1,6,Cols,Rows),
		"Win_OnTextBoxChanged"
	)

	self.ApplyTracking = self.Window:createButton(
		FramedRect(TRPane,2,6,Cols,Rows),
		"Speed",
		"Win_OnButtonClicked"
	)

	-- range

	self.InputRange = self.Window:createTextBox(
		FramedRect(TRPane,4,6,Cols,Rows),
		"Win_OnTextBoxChanged"
	)

	self.ApplyRange = self.Window:createButton(
		FramedRect(TRPane,5,6,Cols,Rows),
		"Range",
		"Win_OnButtonClicked"
	)

	-- rate

	self.InputRate = self.Window:createTextBox(
		FramedRect(TRPane,7,6,Cols,Rows),
		"Win_OnTextBoxChanged"
	)

	self.ApplyRate = self.Window:createButton(
		FramedRect(TRPane,8,6,Cols,Rows),
		"F.Rate",
		"Win_OnButtonClicked"
	)

	return
end

function Win:PopulateInventory()
-- most of the structure for this function was stolen from the vanilla research
-- station script. it reads your inventory and creates a visible list of all
-- the turrets you can drag drop.

	local ItemList = {}
	local Me = Player()

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

function Win:UpdateFields()

	Item = Player():getInventory():find(
		 self.Item:getItem(ivec2(0,0)).uvalue
	)

	self:UpdateFields_ProjectileColour(Item)
	self:UpdateFields_CoreColour(Item)
	self:UpdateFields_GlowColour(Item)
	self:UpdateFields_Targeting(Item)
	self:UpdateFields_Energy(Item)
	self:UpdateFields_Heat(Item)
	self:UpdateFields_Tracking(Item)
	self:UpdateFields_Range(Item)
	self:UpdateFields_Rate(Item)

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
	self.InputProjColourH.text = Colour.hue
	self.InputProjColourS.text = Colour.saturation
	self.InputProjColourV.text = Colour.value
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
	self.InputCoreColourH.text = Colour.hue
	self.InputCoreColourS.text = Colour.saturation
	self.InputCoreColourV.text = Colour.value
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
	self.InputGlowColourH.text = Colour.hue
	self.InputGlowColourS.text = Colour.saturation
	self.InputGlowColourV.text = Colour.value
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
		self.LabelTargeting.color = ColorHSV(55,1,1)
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

--------------------------------------------------------------------------------

function Win:OnItemAdded(SelectID, FX, FY, Item, FromIndex, ToIndex, TX, TY)

	print("=== Win:OnItemAdded ===")
	print("SelectID: " .. SelectID)
	print("FX/Y: " .. FX .. "," .. FY)
	print("TX/Y: " .. TX .. "," .. TY)
	print("From/To: " .. FromIndex .. " -> " .. ToIndex)
	print("")

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

--------------------------------------------------------------------------------

function Win_OnItemAdded(...) Win:OnItemAdded(...) end
function Win_OnItemClicked(...) Win:OnItemClicked(...) end
function Win_OnItemRemoved(...) Win:OnItemRemoved(...) end
function Win_OnInvClicked(...) Win:OnInvClicked(...) end

function Win_OnTextBoxChanged(...) end
function Win_OnButtonClicked(...) end

--------------------------------------------------------------------------------

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


