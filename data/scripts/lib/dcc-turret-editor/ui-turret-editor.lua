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

local Win = {
	Title = "Turret Editor",

	Window = nil,
	Item   = nil,
	ItemLabel = nil,
	Inv    = nil,
	CmdScroll = nil,


	UI = nil,
	Res = nil,
	Size = nil
}

function Win:OnInit()

	self.Res = getResolution()
	self.Size = vec2(800,600)
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
		10, 10, 0.5
	)

	local TPane = UIVerticalSplitter(
		Pane.top,
		0, 0, 0.5
	)

	local TLPane = UIHorizontalSplitter(
		TPane.left,
		0, 0, 0.5
	)

	local TRPane = UIHorizontalSplitter(
		TPane.right,
		0, 0, 0.5
	)

	local FontSize1 = 20
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

	self.Inv = self.Window:createSelection(Pane.bottom,11)
	self.Inv.onClickedFunction = "Win_OnInvClicked"

	-- create the list of things you can do.

	self.CmdScroll = self.Window:createScrollFrame(TPane.right)

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
	end

	return
end

--------------------------------------------------------------------------------

function Win_OnItemAdded(...) Win:OnItemAdded(...) end
function Win_OnItemClicked(...) Win:OnItemClicked(...) end
function Win_OnItemRemoved(...) Win:OnItemRemoved(...) end
function Win_OnInvClicked(...) Win:OnInvClicked(...) end

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


