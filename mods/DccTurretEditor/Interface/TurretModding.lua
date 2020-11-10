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

include("galaxy")
include("utility")
include("faction")
include("player")
include("randomext")
include("stringutility")
include("callable")

local This = {}
local SellableInventoryItem = include("sellableinventoryitem")
local TurretLib = include("mods/DccTurretEditor/Common/TurretLib")
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
	self.Size = vec2((self.Res.x * 0.75),(self.Res.y * 0.75))
	self.UI = ScriptUI(Player().craftIndex)

	print("[TurretModding:OnInit] Resolution: " .. self.Res.x .. " " .. self.Res.y)

	self.Window = self.UI:createWindow(Rect(
		(self.Res * 0.5 - self.Size * 0.5),
		(self.Res * 0.5 + self.Size * 0.5)
	))

	self.Window.caption = self.Title
	self.Window.showCloseButton = 1
	self.Window.moveable = 1
	self.UI:registerWindow(self.Window,self.Title)

	return
end

function Win:BuildUI()

	local Pane = UIHorizontalSplitter(
		Rect(self.Window.size),
		10, 10, 0.55
	)

	local BPane = UIHorizontalSplitter(
		Pane.top,
		0, 0, 0.35
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

	--self.Inv = self.Window:createInventorySelection(Pane.bottom,24)
	-- remove() still does not work on InventeorySelection()
	self.Inv = self.Window:createInventorySelection(Pane.bottom,24)
	self.Inv.dropIntoEnabled = 1
	self.Inv.entriesSelectable = 0
	self.Inv.onClickedFunction = "TurretModdingUI_OnInvClicked"
	self.Inv.onReceivedFunction = "TurretModdingUI_OnInvAdded"

	-- buttons don't place well so we alter their rects after creating.

	self.UpgradeFrame = self.Window:createFrame(BPane.bottom)
	local Rows = 9
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
	self.BtnHeat.tooltip = "Reduce the heat generated per shot, improve cooldown rate per second."

	self.LblHeat = self.Window:createLabel(
		Rect(),
		"$HEAT",
		FontSize3
	)
	self.LblHeat.rect = FramedRect(self.UpgradeFrame,1,2,Cols,Rows)
	self.LblHeat.centered = true

	--------

	self.BtnMaxHeat = self.Window:createButton(
		Rect(),
		"Capacitors",
		"TurretModdingUI_OnClickedBtnMaxHeat"
	)
	self.BtnMaxHeat.textSize = FontSize3
	self.BtnMaxHeat.rect = FramedRect(self.UpgradeFrame,2,1,Cols,Rows)
	self.BtnMaxHeat.tooltip = "Improve mounting heat dissipation."

	self.LblMaxHeat = self.Window:createLabel(
		Rect(),
		"$MAX_HEAT",
		FontSize3
	)
	self.LblMaxHeat.rect = FramedRect(self.UpgradeFrame,2,2,Cols,Rows)
	self.LblMaxHeat.centered = true

	--------

	self.BtnDamage = self.Window:createButton(
		Rect(),
		"Ammunition / Power",
		"TurretModdingUI_OnClickedBtnDamage"
	)
	self.BtnDamage.textSize = FontSize3
	self.BtnDamage.rect = FramedRect(self.UpgradeFrame,3,1,Cols,Rows)
	self.BtnDamage.tooltip = "Increase the firepower."

	self.LblDamage = self.Window:createLabel(
		Rect(),
		"$DAMAGE",
		FontSize3
	)
	self.LblDamage.rect = FramedRect(self.UpgradeFrame,3,2,Cols,Rows)
	self.LblDamage.centered = true

	--------

	self.BtnEfficiency = self.Window:createButton(
		Rect(),
		"Phase Filters",
		"TurretModdingUI_OnClickedBtnEfficiency"
	)
	self.BtnEfficiency.textSize = FontSize3
	self.BtnEfficiency.rect = FramedRect(self.UpgradeFrame,4,1,Cols,Rows)
	self.BtnEfficiency.tooltip = "Increase the efficiency of mining and scav lasers."

	self.LblEfficiency = self.Window:createLabel(
		Rect(),
		"$EFFICIENCY",
		FontSize3
	)
	self.LblEfficiency.rect = FramedRect(self.UpgradeFrame,4,2,Cols,Rows)
	self.LblEfficiency.centered = true

	--------

	self.BtnMounting = self.Window:createButton(
		Rect(),
		"Reinforced Mount",
		"TurretModdingUI_OnClickedBtnMounting"
	)
	self.BtnMounting.textSize = FontSize3
	self.BtnMounting.rect = FramedRect(self.UpgradeFrame,5,1,Cols,Rows)
	self.BtnMounting.tooltip = Win:GetMountingUpgradeTooltip()

	self.LblMounting = self.Window:createLabel(
		Rect(),
		"$MOUNTING",
		FontSize3
	)
	self.LblMounting.rect = FramedRect(self.UpgradeFrame,5,2,Cols,Rows)
	self.LblMounting.centered = true

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

	self.BtnProjectileSpeed = self.Window:createButton(
		Rect(),
		"Accelerators",
		"TurretModdingUI_OnClickedBtnProjectileSpeed"
	)
	self.BtnProjectileSpeed.textSize = FontSize3
	self.BtnProjectileSpeed.rect = FramedRect(self.UpgradeFrame,5,3,Cols,Rows)
	self.BtnProjectileSpeed.tooltip = "Increase the projectile velocity."

	self.LblProjectileSpeed = self.Window:createLabel(
		Rect(),
		"$PSPEED",
		FontSize3
	)
	self.LblProjectileSpeed.rect = FramedRect(self.UpgradeFrame,5,4,Cols,Rows)
	self.LblProjectileSpeed.centered = true

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
	self.NumSize.showValue = true
	self.NumSize.min = 0.5
	self.NumSize.max = 3.0
	self.NumSize.center = vec2(self.NumSize.center.x,(self.NumSize.center.y - 6))

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
	self.NumColourHue.showValue = true
	self.NumColourHue.center = vec2(self.NumColourHue.center.x,(self.NumColourHue.center.y - 6))

	self.NumColourSat = self.Window:createSlider(Rect(),0,1,10,"","TurretModdingUI_OnUpdatePreviewColour")
	self.NumColourSat.rect = FramedRect(self.UpgradeFrame,((4*3)-1),7,(Cols*3),Rows,5)
	self.NumColourSat.showValue = true
	self.NumColourSat.center = vec2(self.NumColourSat.center.x,(self.NumColourSat.center.y - 6))

	self.NumColourVal = self.Window:createSlider(Rect(),0,1,10,"","TurretModdingUI_OnUpdatePreviewColour")
	self.NumColourVal.rect = FramedRect(self.UpgradeFrame,((4*3)-0),7,(Cols*3),Rows,5)
	self.NumColourVal.showValue = true
	self.NumColourVal.center = vec2(self.NumColourVal.center.x,(self.NumColourVal.center.y - 6))

	self.BtnMkFlak = self.Window:createButton(
		Rect(),
		"Convert To Flak Cannon",
		"TurretModdingUI_OnClickedBtnMkFlak"
	)
	self.BtnMkFlak.textSize = FontSize3
	self.BtnMkFlak.rect = FramedRect(self.UpgradeFrame,1,9,Cols,Rows)
	self.BtnMkFlak.tooltip = "Convert an Anti-Fighter turret into a flak barrier turret. Requries scrapping " .. Config.FlakCountRequirement .. " other Anti-Fighter turrets for parts."

	--if(Config.Experimental) then
		self.BtnMkCool = self.Window:createButton(
			Rect(),
			"Liquid Naonite Cooling System",
			"TurretModdingUI_OnClickedBtnMkCool"
		)
		self.BtnMkCool.textSize = FontSize3
		self.BtnMkCool.rect = FramedRect(self.UpgradeFrame,2,9,Cols,Rows)
		self.BtnMkCool.tooltip = "Apply a Liquid Naonite Cooling System to this turret."
	--end

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

	-- clear the inventory inventory beacuse doing just clear on the root
	-- of the element did not seem to work right correctly, especally if
	-- there was filter text. strange things would happen and you'd see
	-- dups, or the sorting would just make no sense, or the text you filter
	-- by would not even be what is getting highlighted. even calling the
	-- root clear after the selection clear is fuckery, but this is fine.

	--self.Inv.filterTextBox:clear()
	self.Inv.selection:clear()

	-- throw everything that makes sense into a table so we can sort it.

	for Iter, Thing in pairs(Me:getInventory():getItems()) do
		if(Thing.item.itemType == InventoryItemType.Turret or Thing.item.itemType == InventoryItemType.TurretTemplate)
		then
			local Item = SellableInventoryItem(Thing.item,Iter,Me)
			table.insert(ItemList,Item)
		end
	end

	-- sort starred items to the front of the list, trash to the end.

	--[[
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
	--]]

	-- now create items in our dialog to represent the inventory items.
	-- are are unstacking items for this.

	-- self.Inv:fill(Player().index, InventoryItemType.Turret)

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

function Win:GetItemCount()
-- count how many objects we have in the item slot.

	local Count = 0
	local ItemVec
	local Item

	for ItemVec, Item in pairs(self.Item:getItems()) do
		if(Item ~= nil) then
			Count = Count + 1
		end
	end

	return Count
end

function Win:GetBinCount()
-- count how many objects we have in the bin.

	local Count = 0
	local ItemVec
	local Item

	for ItemVec, Item in pairs(self.Bin:getItems()) do
		if(Item ~= nil) then
			Count = Count + 1
		end
	end

	return Count
end

function Win:GetBinLowestRarity()
-- get the lowest rarity value current in the bin.

	local RarityLowest = 9001
	local RarityThis = 0
	local ItemVec
	local Item

	for ItemVec, Item in pairs(self.Bin:getItems()) do
		RarityThis = TurretLib:GetWeaponRarityValue(Item.item)

		if(RarityThis < RarityLowest) then
			RarityLowest = RarityThis
		end
	end

	return RarityLowest
end

function Win:GetBinTechLevel()
-- get the average tech level of the bin.

	local ItemVec
	local Item

	local TechLevel = 0
	local Count = 0

	for ItemVec, Item in pairs(self.Bin:getItems()) do
		TechLevel = TechLevel + TurretLib:GetWeaponTechLevel(Item.item)
		Count = Count + 1
	end

	return round((TechLevel / Count),0)
end

function Win:GetMountingUpgradeTooltip()
-- the tooltip for the mounting upgrade needs to be a little more dynamic than
-- the other ones need.

	local RarityWording = "equal or better quality"
	local CountWording = Config.MountingCountRequirement

	if(Config.MountingRarityRequirement == 0.5) then
		RarityWording = Rarity(-1).name
	elseif(Config.MountingRarityRequirement > 0) then
		RarityWording = Rarity(Config.MountingRarityRequirement - 1).name .. " or better "
	end


	return "Reduces the slot cost.\nRequires scrapping " .. CountWording .. " " .. RarityWording ..  " turrets."
end

function Win:CalculateBinItemsOld()
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

		--[[
		PrintDebug(
			"Bin Item: " .. Item.item.weaponName ..
			", Rarity: " .. TurretLib:GetWeaponRarityValue(Item.item) ..
			", Tech: " .. Item.item.averageTech
		)
		]]--
	end

	if(Count == 0) then
		return 0
	end

	TechLevel = TechLevel / Count
	if(TechLevel > Real.averageTech) then
		-- TechLevel = Real.averageTech
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

function Win:CalculateBinItems()
-- calculate the bin items buff value.

	local Mock, Real = self:GetCurrentItems()
	local ItemVec = nil
	local Item = nil

	local CountMax = 5
	local Count = 0
	local TechLevel = 0
	local TechPer = 0
	local RarityValue = 0
	local RarityPer = 0
	local FinalValue = 0

	for ItemVec, Item in pairs(self.Bin:getItems()) do
		Count = Count + 1
		TechLevel = TechLevel + Item.item.averageTech
		RarityValue = RarityValue + TurretLib:GetWeaponRarityValue(Item.item)
	end

	if(Count == 0) then
		return 0
	end

	-- what i actually want is the average tech value of the scrapped items and
	-- to compare it to the tech level of the turret in the machine.

	TechLevel = (TechLevel / Count) * Config.TechMult
	TechPer = (TechLevel / Real.averageTech) * (Count / CountMax)
	RarityValue = (RarityValue / Count) * Config.RarityMult
	RarityPer = (RarityValue / TurretLib:GetWeaponRarityValue(Real)) * (Count / CountMax)

	FinalValue = TechPer + RarityPer

	PrintDebug(
		"TechLevel: ".. TechLevel ..":" .. Real.averageTech ..
		", TechPercentage: " .. (TechPer * 100) .. "%" ..
		", RarityPercentage: " .. (RarityPer * 100) .. "%" ..
		", FinalValue: " .. FinalValue
	)

	return FinalValue
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

function Win:GetBinCountOfType(ThisType)
-- make sure everything in the bin is the same weapon type.

	local ItemVec
	local Item
	local Real

	local WeapList
	local WeapIter
	local Weap

	local Result = 0
	local AddResult = false

	for ItemVec, Item in pairs(self.Bin:getItems()) do
		Real = Item.item
		AddResult = false

		for WeapIter,Weap in pairs({Real:getWeapons()}) do
			--print("[DccTurretModding:GetBinCountOfType] " .. Weap.appearance .. " vs " .. ThisType)
			if(Weap.appearance == ThisType) then
				AddResult = true
			end
		end

		if(AddResult) then
			Result = Result + 1
		end
	end

	return Result
end

function Win:GetBinSlotCount()
-- count how many slots are in all the bin items total.

	local ItemVec
	local Item
	local SlotCount = 0

	for ItemVec, Item in pairs(self.Bin:getItems()) do
		SlotCount = SlotCount + TurretLib:GetWeaponSlots(Item.item)
	end

	return SlotCount
end

function Win:GetBinMountingUpgrade(Real)
-- determine how many slots we should knock off.

	local CurCount = TurretLib:GetWeaponSlots(Real)
	local SlotCount = self:GetBinSlotCount()
	local Result

	-- the more slots a turret has GENERALLY the more powerful it is too. the game
	-- theory we are using here though is that turrets that have high mounting costs
	-- will give us more materials to reinforce this turrets mount with. this is one
	-- of the few cases where scrapping something technically worse is better.

	Result = ((SlotCount / Config.MountingCountRequirement) - 1)
	--PrintDebug("[GetBinMountingUpgrade] Result: " .. Result)

	if(Result < 1) then
		Result = 1
	end

	-- using round instead of floor now to give you a small bump if you were
	-- close to the next slot number. floor was really punishing imho.

	return round(Result,0)
end

function Win:ShouldAllowMountingUpgrade(Real)
-- determine if we should allow this turret to have it mount upgraded.

	local Minimum = Config.MountingRarityRequirement
	local Lowest = self:GetBinLowestRarity()
	local BinCount = self:GetBinCount()
	local SlotCount = TurretLib:GetWeaponSlots(Real)

	-- if the turret is already at the configured minimum then no.

	if(SlotCount <= Config.TurretSlotMin) then
		return false
	end

	-- if there are not even enough itmems then no

	if(BinCount < Config.MountingCountRequirement) then
		return false
	end

	-- if config is 0 then require equal or better.
	-- if non-zero require that level or better.
	-- if a higher number than rarity exists, they will never be allowed.

	if(Minimum == 0) then
		Minimum = TurretLib:GetWeaponRarityValue(Real)
	end

	return (Lowest >= Minimum)
end

function Win:ShouldAllowFlakConversion(Real)
-- determine if we should allow this turret to be converted.

	if(TurretLib:GetWeaponRealType(Real) ~= WeaponAppearance.AntiFighter)
	then return false end

	if(Win:GetBinCountOfType(WeaponAppearance.AntiFighter) < Config.FlakCountRequirement)
	then return false end

	return true
end

function Win:ShouldAllowCoolingSystem(Real)
-- determine if we should allow this turret to be liquid cooled.

	if(Config.CostCoolingMoney == -1) then
		return false
	end

	if(TurretLib:GetWeaponHeatRate(Real) <= 0) then
		return false
	end

	return true
end

--------------------------------------------------------------------------------

function Win:UpdateItems(Mock,Real,DontConsume)

	local BinTech = self:GetBinTechLevel()
	local RealTech = TurretLib:GetWeaponTechLevel(Real)
	local NewTech = 0

	-- first for any upgrade operation we need to also bump up the tech
	-- level of the destination turret to curve our gains upon it.

	if(BinTech >= RealTech) then
		-- NewTech = RealTech + math.ceil((BinTech - RealTech) * Config.TechPostMult)
		NewTech = RealTech + 1

		if(NewTech > BinTech) then
			-- sanity check if someone brings the mult over 1 in the config.
			NewTech = BinTech
		elseif(NewTech == RealTech) then
			-- if the result didn't change it, bump it anyway. also gives us
			-- the "past max level" curve that made server admins qq.
			NewTech = RealTech + Config.TechPostLevel
		end

		TurretLib:SetWeaponTechLevel(Real,NewTech)
	end

	-- also bump the weapon mk upgrade status to the next level.

	TurretLib:BumpWeaponNameMark(Real)

	-- finally consume the items in the bin.

	if(DontConsume ~= true) then
		self:ConsumeBinItems()
	end

	--------

	print("[UpdateItems] BinTech: " .. BinTech .. "/" .. RealTech .. ", NewTech: " .. NewTech)

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

	local BuffValue = self:CalculateBinItems()
	local Item, Real = self:GetCurrentItems()
	local BackgroundColour
	local ColourDark = Color()
	local ColourLight = Color()

	local WeaponType = nil
	local WeaponRealType = nil
	local Category = 0
	local HeatRate = 0
	local CoolRate = 0
	local MaxHeat = 0
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
	local Slots = 0
	local SlotUpgrade = 0
	local PSpeed = 0
	local MountingEnable = false
	local FlakEnable = false
	local CoolingEnable = false
	local FixTargetingNerfEnable = false
	local CoolingTypeBattery = false

	local InfoFireRate = ""
	local InfoRange = ""
	local InfoDamage = ""
	local InfoAccuracy = ""
	local InfoEfficiency = ""
	local InfoHeatRate = ""
	local InfoCoolRate = ""
	local InfoSpeed = ""
	local InfoMaxHeat = ""
	local InfoSlots = ""
	local InfoPSpeed = ""

	if(Item ~= nil) then
		WeaponType = TurretLib:GetWeaponType(Item.item)
		WeaponRealType = TurretLib:GetWeaponRealType(Item.item)
		Category = TurretLib:GetWeaponCategory(Item.item)
		HeatRate = TurretLib:GetWeaponHeatRate(Item.item)
		CoolRate = TurretLib:GetWeaponCoolRate(Item.item)
		MaxHeat = TurretLib:GetWeaponMaxHeat(Item.item)
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
		Slots = TurretLib:GetWeaponSlots(Item.item)
		PSpeed = TurretLib:GetWeaponProjectileSpeed(Item.item)
		SlotUpgrade = self:GetBinMountingUpgrade(Item.item)

		MountingEnable = self:ShouldAllowMountingUpgrade(Real)
		FixTargetingNerfEnable = TurretLib:IsDefaultTargetingNerfFixable(Real)
		FlakEnable = Win:ShouldAllowFlakConversion(Real)
		CoolingEnable = Win:ShouldAllowCoolingSystem(Real)
		CoolingTypeBattery = TurretLib:GetWeaponCoolingType(Real) == CoolingType.BatteryCharge

		InfoDamage = ", " .. round((Damage * FireRate * GunCount),2) .. " DPS"

		if(BuffValue ~= 0) then
			InfoFireRate = " (+" .. round((TurretLib:ModWeaponFireRate(Item.item,BuffValue,true) - FireRate),3) .. ")"
			InfoRange = " (+" .. round((TurretLib:ModWeaponRange(Item.item,BuffValue,true) - Range),3) .. ")"
			InfoDamage = InfoDamage .. "\n (+" .. round((TurretLib:ModWeaponDamage(Item.item,BuffValue,true) - Damage),3) .. ""
			InfoDamage = InfoDamage .. ", " .. round((TurretLib:ModWeaponDamage(Item.item,BuffValue,true) * FireRate * GunCount),2) .. " DPS)"
			InfoAccuracy = " (+" .. (round((TurretLib:ModWeaponAccuracy(Item.item,BuffValue,true) - Accuracy),4) * 100) .. "%)"
			InfoEfficiency = " (+" .. (round((TurretLib:ModWeaponEfficiency(Item.item,BuffValue,true) - Efficiency),3) * 100) .. "%)"
			InfoHeatRate = "\n (-" .. round((TurretLib:ModWeaponHeatRate(Item.item,(BuffValue + Config.NearZeroFloat),true) - HeatRate),3) .. ")"
			InfoCoolRate = " (+" .. round((TurretLib:ModWeaponCoolRate(Item.item,BuffValue,true) - CoolRate),3) .. ")"
			InfoSpeed = " (+" .. round((TurretLib:ModWeaponSpeed(Item.item,BuffValue,true) - Speed),3) .. ")"
			InfoMaxHeat = " (+" .. round((TurretLib:ModWeaponMaxHeat(Item.item,BuffValue,true) - MaxHeat),3) .. ")"
			InfoSlots = " (-" .. SlotUpgrade ..  ")"

			if(PSpeed ~= nil) then
				InfoPSpeed = " (+" .. round((TurretLib:ModWeaponProjectileSpeed(Item.item,BuffValue,true) - PSpeed),3) .. ")"
			end
		end
	end

	ColourDark:setHSV(0,0,0.3)
	ColourLight:setHSV(0,0,0.8)

	-- fill in all the values.

	self.BtnTargeting.caption = "Targeting (Cr. " .. toReadableValue(Config.CostTargeting) .. ")"
	self.BtnTargeting.tooltip = "Toggle Automatic Targeting.\n(Does not consume turrets)"
	self.BtnCoaxial.caption = "Coaxial (Cr. " .. toReadableValue(Config.CostCoaxial) .. ")"
	self.BtnColour.caption = "Colour HSV (Cr. " .. toReadableValue(Config.CostColour) .. ")"
	self.BtnSize.caption = "Scale (Cr. " .. toReadableValue(Config.CostSize) .. ")"

	self.BtnHeat.caption = "Heat Sinks"
	self.LblHeat.caption = HeatRate .. " HPS, " .. CoolRate .. " CPS" .. InfoHeatRate .. InfoCoolRate
	self.LblHeat.color = ColourLight

	if(CoolingTypeBattery) then
		self.BtnMaxHeat.caption = "Battery"
		self.BtnMaxHeat.tooltip = "Increase battery capacity."
		self.LblMaxHeat.caption = MaxHeat .. InfoMaxHeat
		self.LblMaxHeat.color = ColourLight
	else
		self.BtnMaxHeat.caption = "Radiators"
		self.BtnMaxHeat.tooltip = "Improve mounting heat dissipation."
		self.LblMaxHeat.caption = MaxHeat .. " Heat Dis." .. InfoMaxHeat
		self.LblMaxHeat.color = ColourLight
	end

	self.BtnDamage.caption = "Ammunition"
	self.LblDamage.caption = Damage .. InfoDamage
	self.LblDamage.color = ColourLight

	self.BtnFireRate.caption = "Trigger Mechanisms"
	self.LblFireRate.caption = FireRate .. " RPS" .. InfoFireRate
	self.LblFireRate.color = ColourLight

	self.BtnSpeed.caption = "Drive Motors"
	self.LblSpeed.caption = Speed .. InfoSpeed
	self.LblSpeed.color = ColourLight

	self.BtnRange.caption = "Barrel"
	self.LblRange.caption = Range .. " KM" .. InfoRange
	self.LblRange.color = ColourLight

	self.BtnAccuracy.caption = "Stabilizers"
	self.LblAccuracy.caption = (Accuracy * 100) .. "%" .. InfoAccuracy
	self.LblAccuracy.color = ColourLight

	self.BtnEfficiency.caption = "Phase Filters"
	self.LblEfficiency.caption = (Efficiency * 100) .. "%" .. InfoEfficiency
	self.LblEfficiency.color = ColourLight

	self.BtnMounting.caption = "Reinforced Mount"
	self.BtnMounting.active = MountingEnable
	self.LblMounting.caption = Slots .. InfoSlots

	self.BtnProjectileSpeed.active = (PSpeed ~= nil)
	self.LblProjectileSpeed.caption = (PSpeed or "") .. InfoPSpeed

	if(FixTargetingNerfEnable) then
		self.BtnTargeting.caption = "Fix Auto Nerf (Cr. " .. toReadableValue(Config.CostTargeting) .. ")"
		self.BtnTargeting.tooltip = "Fixes automatic targeting nerf by removing targeting and fixing the damage values. You must then re-apply targeting afterwards."
	end

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

	self.NumSize.value = Size

	if(WeaponType == "beam") then
		self.BtnRange.caption = "Lenses"
		self.BtnDamage.caption = "Power Amplifiers"
	end

	self.BtnMkFlak.active = FlakEnable
	self.BtnMkCool.active = CoolingEnable

	-- show everything.

	self.BtnHeat:show()
	self.BtnMaxHeat:show()
	self.BtnDamage:show()
	self.BtnSpeed:show()
	self.BtnRange:show()
	self.BtnFireRate:show()
	self.BtnMaxHeat:show()
	self.BtnCoaxial:show()
	self.BtnSize:show()

	self.LblHeat:show()
	self.LblMaxHeat:show()
	self.LblDamage:show()
	self.LblSpeed:show()
	self.LblRange:show()
	self.LblFireRate:show()
	self.LblMaxHeat:show()
	self.LblCoaxial:show()

	self.NumSize:show()

	-- hide things that make no sense to edit for this turret.

	if(HeatRate == 0) then
		self.LblHeat.color = ColourDark
	end

	if(MaxHeat == 0) then
		self.LblMaxHeat.color = ColourDark
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

	local FromVec = ivec2(FX,FY)
	self.CurrentSelectID = SelectID

	--print("[DccTurretEditor:OnItemClicked] Click " .. Item.item.weaponName .. " Button " .. Button)

	if(Button == 3) then
		self.Inv:add(Item,0)
		self.Item:remove(FromVec)
	end

	self:UpdateFields()
	self:UpdateBinLabel()
	return
end

function Win:OnItemAdded(SelectID, FX, FY, Item, FromIndex, ToIndex, TX, TY)

	local OldItem = self.Item:getItem(ivec2(0,0))
	local FromVec = ivec2(FX,FY)
	local BackgroundColour = Color()

	if(SelectID == self.CurrentSelectID) then
		--print("[DccTurretEditor] Item was source and dest.")
		return
	end

	self.Item:clear()
	self.Item:add(Item)
	--print("[DccTurretEditor] Selected Turret: " .. Item.item.weaponName)

	--------

	if(self.CurrentSelectID == self.Bin.index) then
		self.Bin:remove(FromVec)
	elseif(self.CurrentSelectID == self.Inv.selection.index) then
		self.Inv:remove(FromVec)
	end

	--------

	if(OldItem ~= nil) then
		self.Inv:add(OldItem)
		--print("[DccTurretEditor] Replaced Turret: " .. OldItem.item.weaponName)
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

	local FromVec = ivec2(FX,FY)

	--print("[DccTurretEditor:OnBinClicked] Click " .. Item.item.weaponName .. " Button " .. Button)

	if(Button == 3) then
		self.Inv:add(Item,0)
		self.Bin:remove(FromVec)
	end

	self:UpdateFields()
	self:UpdateBinLabel()
	return
end

function Win:OnBinAdded(SelectID, FX, FY, Item, FromIndex, ToIndex, TX, TY)

	local FromVec = ivec2(FX,FY)

	if(SelectID == self.CurrentSelectID) then
		--print("[DccTurretEditor] Bin was source and dest.")
		return
	end

	if(tablelength(self.Bin:getItems()) >= 5) then
		--print("[DccTurretEditor] Bin is full.")
		return
	end

	self.Bin:add(Item)
	--print("[DccTurretEditor] Added to Bin: " .. Item.item.weaponName .. " " .. FX .. " " .. FY)

	--------

	if(self.CurrentSelectID == self.Item.index) then
		self.Item:remove(FromVec)
	elseif(self.CurrentSelectID == self.Inv.selection.index) then
		--print("[DccTurretModding:OnBinAdded] Remove from INV")
		self.Inv:remove(FromVec)
	end

	self:UpdateFields()
	self:UpdateBinLabel()
	return
end

----------------
----------------

function Win:OnInvClicked(SelectID, FX, FY, Item, Button)

	local ItemCount = self:GetItemCount()
	local BinCount = self:GetBinCount()
	local FromVec = ivec2(FX,FY)
	self.CurrentSelectID = SelectID

	--print("[DccTurretEditor:OnInvClicked] SelectID " .. SelectID .. " Click " .. Item.item.weaponName .. " Button " .. Button)

	if(Button == 3) then
		if(ItemCount == 0) then
			self.Item:add(Item,0)
			self.Inv:remove(FromVec)
		elseif(BinCount < 5) then
			self.Bin:add(Item,0)
			self.Inv:remove(FromVec)
		end
	end

	self:UpdateFields()
	self:UpdateBinLabel()
	return
end

function Win:OnInvAdded(SelectID, FX, FY, Item, FromIndex, ToIndex, TX, TY)

	local FromVec = ivec2(FX,FY)

	if(SelectID == self.CurrentSelectID) then
	--	print("[DccTurretEditor] Inv was source and dest.")
		return
	end

	self.Inv:add(Item)
	--print("[DccTurretEditor] Added to Inv: " .. Item.item.weaponName)

	--------

	if(self.CurrentSelectID == self.Item.index) then
		self.Item:remove(FromVec)
	elseif(self.CurrentSelectID == self.Bin.index) then
		self.Bin:remove(FromVec)
	end

	self:UpdateFields()
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

	self:UpdateItems(Mock,Real)
	return
end

function Win:OnClickedBtnMaxHeat()
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

	if(TurretLib:GetWeaponMaxHeat(Real) == 0) then
		PrintWarning("This turret does not take any heat.")
		return
	end

	TurretLib:ModWeaponMaxHeat(Real,BuffValue)

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

	self:UpdateItems(Mock,Real)
	return
end

function Win:OnClickedBtnMounting()
-- lower mounting cost

	local BinRarity = Win:GetBinLowestRarity()
	local Mock, Real = Win:GetCurrentItems()
	local CurrentValue = TurretLib:GetWeaponSlots(Real)
	local BinValue = Win:GetBinMountingUpgrade(Real)
	local NewValue = CurrentValue - BinValue

	if(Mock == nil) then
		PrintError("No turret selected")
		return
	end

	if(CurrentValue <= Config.TurretSlotMin) then
		PrintError("This turret is already at minimum slot use.")
		return
	end

	if(not self:ShouldAllowMountingUpgrade(Real)) then
		PrintError("Scrapping requirements not met for upgrading the mounting.")
		return
	end

	if(NewValue < Config.TurretSlotMin) then
		NewValue = Config.TurretSlotMin
	end

	TurretLib:SetWeaponSlots(Real,NewValue)

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

	self:UpdateItems(Mock,Real,true)
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

	self:UpdateItems(Mock,Real,true)
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

	self:UpdateItems(Mock,Real,true)
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

	TurretLib:SetWeaponSize(Real,(self.NumSize.value))
	TurretLib:PlayerPayCredits(PlayerRef.index, Config.CostSize)

	self:UpdateItems(Mock,Real,true)
	return
end

function Win:OnClickedBtnMkFlak()
-- change turrent size

	local Mock, Real = Win:GetCurrentItems()
	local BinCount = Win:GetBinCount()
	local BinCountType = Win:GetBinCountOfType(WeaponAppearance.AntiFighter)
	local BinBuff = Win:CalculateBinItems() / 100
	local ItemBuff = TurretLib:GetWeaponRarityValue(Real) / 100

	local Damage = 3.25
	local FireRate = 8.0
	local Range = 0.75
	local Accuracy = 0.03
	local Radius = 37
	local Speed = 2.25
	local Slots = 1
	local Crew = 1

	if(Mock == nil) then
		PrintError("No turret selected")
		return
	end

	if(BinCountType < Config.FlakCountRequirement) then
		PrintError("Requires at least " .. Config.FlakCountRequirement .. " Anti-Fighter turrets to be scrapped.")
		return
	end

	if(not self:ShouldAllowFlakConversion(Real)) then
		PrintError("Scrapping requirements not met for flak cannon conversion.")
		return
	end

	-- the better the turrets you scrap the better some of the values
	-- on the flak cannon will be. better fire rates, better range, and
	-- better blast radius.

	Damage = Damage + (((Damage * BinBuff) + (Damage * ItemBuff)) * 3)
	FireRate = FireRate + (((FireRate * BinBuff) + (FireRate * ItemBuff)) * 2)
	Range = Range + (((Range * BinBuff) + (Range * ItemBuff)) * 2)
	Radius = Radius + (((Radius * BinBuff) + (Radius * ItemBuff)) * 2)
	Speed = Speed + (((Speed * BinBuff) + (Speed * ItemBuff)) * 3)

	print("[DccTurretModding:OnClickedBtnMkFlak] BinBuff: " .. BinBuff .. ", ItemBuff: " .. ItemBuff .. ", FireRate: " .. FireRate .. ", Range: " .. Range .. ", Radius: " .. Radius)

	Win:ConsumeBinItems()
	TurretLib:SetWeaponDamage(Real,Damage)
	TurretLib:SetWeaponFireRate(Real,FireRate)
	TurretLib:SetWeaponAccuracy(Real,Accuracy)
	TurretLib:SetWeaponRange(Real,Range)
	TurretLib:SetWeaponSlots(Real,Slots)
	TurretLib:SetWeaponCrew(Real,Crew)
	TurretLib:SetWeaponExplosion(Real,Radius)
	TurretLib:SetWeaponSpeed(Real,Speed)

	if(not TurretLib:GetWeaponTargeting(Real)) then
		TurretLib:SetWeaponTargeting(Real,true)
	end

	-- allowing them to not be coaxial will probably make it easier to
	-- minimise the number of them needed.

	--if(not TurretLib:GetWeaponCoaxial(Real)) then
		--TurretLib:SetWeaponCoaxial(Real,true)
		--TurretLib:ModWeaponDamage(Real,-66.6666)
	--end

	TurretLib:RenameWeapon(Real,GetLocalizedString("Anti-Fighter"),GetLocalizedString("Flak Cannon"))

	self:UpdateItems(Mock,Real)
	return
end

function Win:OnClickedBtnMkCool()

	local Mock, Real = Win:GetCurrentItems()
	local PlayerRef = Player()
	local HeatRate = 0.0
	local Payment = nil

	Payment = (
		TurretLib:CreatePaymentTable()
		:SetMoney(Config.CostCoolingMoney)
		:SetMaterial(MaterialType.Naonite,Config.CostCoolingNaonite)
	)

	if(Mock == nil) then
		PrintError("No turret selected")
		return
	end

	local CanPay, Msg, Args = PlayerRef:canPay(unpack(Payment))

	if(not CanPay) then
		PlayerRef:sendChatMessage("",1,Msg,unpack(Args))
		return
	end

	TurretLib:PlayerPay(PlayerRef.index,Payment)

	-- costs to consider:
	-- naonite obvs.
	-- goods: high pressure tubes?
	-- credits
	-- accuracy penalties?

	TurretLib:SetWeaponHeatRate(Real,HeatRate)

	self:UpdateItems(Mock,Real)
	return
end

function Win:OnClickedBtnProjectileSpeed()
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

	if(TurretLib:GetWeaponProjectileSpeed(Real) == nil) then
		PrintWarning("This turret instantly slaps your mom.")
		return
	end

	TurretLib:ModWeaponProjectileSpeed(Real,BuffValue)

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
function TurretModdingUI_OnClickedBtnMaxHeat(...) Win:OnClickedBtnMaxHeat(...) end
function TurretModdingUI_OnClickedBtnAccumEnergy(...) Win:OnClickedBtnAccumEnergy(...) end
function TurretModdingUI_OnClickedBtnFireRate(...) Win:OnClickedBtnFireRate(...) end
function TurretModdingUI_OnClickedBtnSpeed(...) Win:OnClickedBtnSpeed(...) end
function TurretModdingUI_OnClickedBtnRange(...) Win:OnClickedBtnRange(...) end
function TurretModdingUI_OnClickedBtnDamage(...) Win:OnClickedBtnDamage(...) end
function TurretModdingUI_OnClickedBtnAccuracy(...) Win:OnClickedBtnAccuracy(...) end
function TurretModdingUI_OnClickedBtnEfficiency(...) Win:OnClickedBtnEfficiency(...) end
function TurretModdingUI_OnClickedBtnMounting(...) Win:OnClickedBtnMounting(...) end
function TurretModdingUI_OnClickedBtnTargeting(...) Win:OnClickedBtnTargeting(...) end
function TurretModdingUI_OnClickedBtnColour(...) Win:OnClickedBtnColour(...) end
function TurretModdingUI_OnClickedBtnCoaxial(...) Win:OnClickedBtnCoaxial(...) end
function TurretModdingUI_OnClickedBtnSize(...) Win:OnClickedBtnSize(...) end
function TurretModdingUI_OnClickedBtnMounting(...) Win:OnClickedBtnMounting(...) end
function TurretModdingUI_OnClickedBtnMkFlak(...) Win:OnClickedBtnMkFlak(...) end
function TurretModdingUI_OnClickedBtnMkCool(...) Win:OnClickedBtnMkCool(...) end
function TurretModdingUI_OnClickedBtnProjectileSpeed(...) Win:OnClickedBtnProjectileSpeed(...) end

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

	Win.Inv.selection:clear()
	Win.Bin:clear()
	Win.Item:clear()

	Win:UpdateFields()
	return
end

function onShowWindow()
-- reset the dialog when it is opened.

	--print("[DccTurretModding] OnShowWindow")

	Win.Item:clear()
	Win.Item:addEmpty()

	Win.Bin:clear()
	Win.Bin:addEmpty()
	Win.Bin:addEmpty()
	Win.Bin:addEmpty()
	Win.Bin:addEmpty()
	Win.Bin:addEmpty()

	--Win.Inv.filterTextBox:clear()
	--Win.Inv.selection:clear()
	--Win.Inv.selection:addEmpty()

	Win:UpdateFields()
	Win:PopulateInventory()
	return
end

--------------------------------------------------------------------------------

function TurretLib_PullConfigFromServer(ToPlayer,InputConfig)
-- handle pulling the config from the server.

	if(onServer()) then
		-- when this function runs server side we need to load the config
		-- and send it back to the client.

		print("[DccTurretEditor] Sending Config To Client " .. Player(ToPlayer).index)

		invokeClientFunction(
			Player(ToPlayer),
			"TurretLib_PullConfigFromServer",
			ToPlayer,
			Config
		)

	else
		-- when this function runs on the client side we will store the
		-- config that the server sent us.

		print("[DccTurretEditor] Received Config From Server")

		for Property,Value in pairs(Input) do
			if(Config[Property] ~= nil) then
				if(type(Value) == "table") then
					Config[Property] = table.deepcopy(Value)
				else
					Config[Property] = Value
				end
			end
		end

		Win:BuildUI()
	end

	return
end

function initialize()
-- script bootstrapping.

	print("TurretModding:initalize")

	-- script added, game loaded: executes both server and client.
	-- jump to new sector: executes on the client only and the locals
	-- get dumped...

	-- when the client runs this we will ask the server for the config
	-- to repopulate the local var.

	if(onClient()) then

	end

	return
end

function initUI()
-- ui bootstrapping.

	if(onServer())
	then return end

	Win:OnInit()
	Config = include("mods/DccTurretEditor/Common/ConfigLib")
	print("[DccTurretEditor] Asking Server For Config")
	invokeServerFunction("TurretLib_PullConfigFromServer",Player().index,nil)
	return
end

callable(nil,"TurretLib_PullConfigFromServer")
