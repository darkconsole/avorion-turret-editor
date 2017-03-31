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

	-- create the drop target for the editor.

	self.Item = self.Window:createSelection(Rect(0,0,64,64),1)
	self.Item.dropIntoEnabled = 1
	self.Item.entriesSelectable = 0
	self.Item.onReceivedFunction = "Win_OnItemAdded"
	self.Item.onDroppedFunction = "Win_OnItemDropped"
	self.Item.onClickedFunction = "Win_OnItemClicked"
	TLPane:placeElementCenter(self.Item)

	self.ItemLabel = self.Window:createLabel(self.Item.upper,"Turret",50)
	self.ItemLabel:setTopLeftAligned()
	--TLPane:placeElementCenter(self.ItemLabel)

	-- create the list of things in your inventory

	self.Inv = self.Window:createSelection(Pane.bottom,11)

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

function Win_OnItemAdded() print("Win_OnItemAdded") end
function Win_OnItemDropped() print("Win_OnItemDropped") end
function Win_OnItemClicked() print("Win_OnItemClicked") end

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


