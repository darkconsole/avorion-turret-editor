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

SellableInventoryItem = require("sellableinventoryitem")

TurretLib = require("mods.DccTurretEditor.TurretLib")

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

--------------------------------------------------------------------------------

local Win = {
	Title = "Engineering: Weapons Bay",

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
	InvLabel = nil,

	-- upgrade heat sinks
	BtnHeatSinks = nil,

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

	InputCrew = nil,
	ApplyCrew = nil,

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
	self.Item.onClickedFunction = "Win_OnItemClicked"
	self.Item.onReceivedFunction = "Win_OnItemAdded"
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
	self.Bin.onClickedFunction = "Win_OnBinClicked"
	self.Bin.onReceivedFunction = "Win_OnBinAdded"
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

	self.Inv = self.Window:createSelection(Pane.bottom,12)
	self.Inv.dropIntoEnabled = 1
	self.Inv.entriesSelectable = 0
	self.Inv.onClickedFunction = "Win_OnInvClicked"
	self.Inv.onReceivedFunction = "Win_OnInvAdded"

	-- buttons don't place well so we alter their rects after creating.

	self.UpgradeFrame = self.Window:createFrame(BPane.bottom)
	local Rows = 4
	local Cols = 4

	local Hint, HintLine

	--------

	self.BtnHeat = self.Window:createButton(
		Rect(),
		"Heat Sinks",
		"Win_OnClickedBtnHeat"
	)
	self.BtnHeat.textSize = FontSize2
	self.BtnHeat.rect = FramedRect(self.UpgradeFrame,1,1,Cols,Rows)
	self.BtnHeat.tooltip = "Reduce the heat generated and cooldown rate of this turret."

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
		"Win_OnClickedBtnBaseEnergy"
	)
	self.BtnBaseEnergy.textSize = FontSize2
	self.BtnBaseEnergy.rect = FramedRect(self.UpgradeFrame,2,1,Cols,Rows)
	self.BtnBaseEnergy.tooltip = "Reduce the base energy demand for this turret."

	--------

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
		"Win_OnClickedBtnAccumEnergy"
	)
	self.BtnAccumEnergy.textSize = FontSize2
	self.BtnAccumEnergy.rect = FramedRect(self.UpgradeFrame,3,1,Cols,Rows)
	self.BtnAccumEnergy.tooltip = "Reduce the increasing energy demand for this turret."

	--------

	self.LblAccumEnergy = self.Window:createLabel(
		Rect(),
		"$ACCUM_ENERGY",
		FontSize3
	)
	self.LblAccumEnergy.rect = FramedRect(self.UpgradeFrame,3,2,Cols,Rows)
	self.LblAccumEnergy.centered = true

	--------

	self.BtnFireRate = self.Window:createButton(
		Rect(),
		"Trigger Mech.",
		"Win_OnClickedBtnFireRate"
	)
	self.BtnFireRate.textSize = FontSize2
	self.BtnFireRate.rect = FramedRect(self.UpgradeFrame,4,1,Cols,Rows)
	self.BtnFireRate.tooltip = "Increase the fire rate of this turret."

	--------

	self.LblFireRate = self.Window:createLabel(
		Rect(),
		"$FIRE_RATE",
		FontSize3
	)
	self.LblFireRate.rect = FramedRect(self.UpgradeFrame,4,2,Cols,Rows)
	self.LblFireRate.centered = true

	--------

	self.BtnSpeed = self.Window:createButton(
		Rect(),
		"Drive Motors",
		"Win_OnClickedBtnSpeed"
	)
	self.BtnSpeed.textSize = FontSize2
	self.BtnSpeed.rect = FramedRect(self.UpgradeFrame,1,3,Cols,Rows)
	self.BtnSpeed.tooltip = "Increase the tracking speed of this turret."

	--------

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
		"Win_OnClickedBtnRange"
	)
	self.BtnRange.textSize = FontSize2
	self.BtnRange.rect = FramedRect(self.UpgradeFrame,2,3,Cols,Rows)
	self.BtnRange.tooltip = "Increase the range at which this turret can hit."

	--------

	self.LblRange = self.Window:createLabel(
		Rect(),
		"$RANGE",
		FontSize3
	)
	self.LblRange.rect = FramedRect(self.UpgradeFrame,2,4,Cols,Rows)
	self.LblRange.centered = true

	--------

	self.BtnColor = self.Window:createButton(
		Rect(),
		"Colour (HSV)",
		"Win_OnClickedBtnColor"
	)
	self.BtnColor.textSize = FontSize2
	self.BtnColor.rect = FramedRect(self.UpgradeFrame,4,3,Cols,Rows)
	self.BtnColor.tooltip = "Cost: $2500 (Does not consume turrets)"

	--------

	self.BgColourFrame = self.Window:createFrame(BPane.bottom)
	self.BgColourFrame.rect = FramedRect(self.UpgradeFrame,4,4,Cols,Rows)

	self.NumColourHue = self.Window:createSlider(Rect(),0,360,36,"","Win_OnUpdatePreviewColour")
	self.NumColourHue.rect = FramedRect(self.UpgradeFrame,((4*3)-2),4,(Cols*3),Rows)

	self.NumColourSat = self.Window:createSlider(Rect(),0,1,10,"","Win_OnUpdatePreviewColour")
	self.NumColourSat.rect = FramedRect(self.UpgradeFrame,((4*3)-1),4,(Cols*3),Rows)

	self.NumColourVal = self.Window:createSlider(Rect(),0,1,10,"","Win_OnUpdatePreviewColour")
	self.NumColourVal.rect = FramedRect(self.UpgradeFrame,((4*3)-0),4,(Cols*3),Rows)

	return
end

function Win:PopulateInventory()
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

	-- sort starred items to the front of the list.

	table.sort(ItemList,function(a,b)
		if(a.item.favorite and not b.item.favorite) then
			return true
		else
			return false
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

			self.Inv:add(Item)

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

	print("weapon " .. Item.item.weaponName)

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

--------------------------------------------------------------------------------

function Win:UpdateItems(Mock,Real)

	TurretLib:UpdatePlayerInventory(
		Real,
		self:GetCurrentItemIndex()
	)

	return
end

--------------------------------------------------------------------------------

function Win:UpdateFields(NewCurrentIndex)

	-- if we recieved a new index, then we need to scan the inventory widget
	-- again to find where the object moved to when it was edited last time
	-- and force that into the main box before we continue.

	local Item, Real, BackgroundColour

	if(NewCurrentIndex ~= nil)
	then
		for Iter, Thing in pairs(self.Inv:getItems()) do
			if(NewCurrentIndex == Thing.uvalue)
			then
				self.Item:clear()
				self.Item:add(Thing)
				break
			end
		end
	end

	Item, Real = self:GetCurrentItems()

	self.LblHeat.caption =
	"+" .. TurretLib:GetWeaponHeatRate(Item.item) .. " HPS, " ..
	"-" .. TurretLib:GetWeaponCoolRate(Item.item) .. " CR"

	self.LblBaseEnergy.caption =
	TurretLib:GetWeaponBaseEnergy(Item.item) .. " Base EPS"

	self.LblAccumEnergy.caption =
	TurretLib:GetWeaponAccumEnergy(Item.item) .. " Accum EPS"


	self.LblFireRate.caption =
	TurretLib:GetWeaponFireRate(Item.item) .. " RPS"

	self.LblSpeed.caption =
	TurretLib:GetWeaponSpeed(Item.item)

	self.LblRange.caption =
	round((TurretLib:GetWeaponRange(Item.item) / 100),3) .. " KM"

	BackgroundColour = TurretLib:GetWeaponColour(Item.item)
	self.NumColourHue.value = BackgroundColour.hue
	self.NumColourSat.value = BackgroundColour.saturation
	self.NumColourVal.value = BackgroundColour.value

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

--------------------------------------------------------------------------------

function Win_Update(NewCurrentIndex)

	Win:PopulateInventory()
	Win:UpdateFields(NewCurrentIndex)
	return
end

function Win_OnItemClicked(...) Win:OnItemClicked(...) end
function Win_OnItemAdded(...) Win:OnItemAdded(...) end
function Win_OnBinClicked(...) Win:OnBinClicked(...) end
function Win_OnBinAdded(...) Win:OnBinAdded(...) end
function Win_OnInvClicked(...) Win:OnInvClicked(...) end
function Win_OnInvAdded(...) Win:OnInvAdded(...) end
function Win_OnUpdatePreviewColour(...) Win:OnUpdatePreviewColour(...) end

function Win_OnClickedProjColour(...) Win:OnClickedProjColour(...) end
function Win_OnClickedCoreColour(...) Win:OnClickedCoreColour(...) end
function Win_OnClickedGlowColour(...) Win:OnClickedGlowColour(...) end
function Win_OnClickedTargeting(...) Win:OnClickedTargeting(...) end
function Win_OnClickedEnergy(...) Win:OnClickedEnergy(...) end
function Win_OnClickedHeat(...) Win:OnClickedHeat(...) end
function Win_OnClickedTracking(...) Win:OnClickedTracking(...) end
function Win_OnClickedRange(...) Win:OnClickedRange(...) end
function Win_OnClickedRate(...) Win:OnClickedRate(...) end
function Win_OnClickedSize(...) Win:OnClickedSize(...) end
function Win_OnClickedCrew(...) Win:OnClickedCrew(...) end
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

	return "mods/DccTurretEditor/Textures/Icon.png"
end

--------------------------------------------------------------------------------

function onCloseWindow()
-- do something i dunno maybe when it is closed.

	print("onCloseWindow")
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

	Win:PopulateInventory()
	return
end

--------------------------------------------------------------------------------

function initialize()
-- script bootstrapping.

	if(onServer())
	then return end

	print("TurretModding:initalize")

	return
end

function initUI()
-- ui bootstrapping.

	if(onServer())
	then return end

	print("TurretModding:initUI")
	Win:OnInit()

	return
end


