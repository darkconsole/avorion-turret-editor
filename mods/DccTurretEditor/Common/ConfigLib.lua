
include("utility")

local PrintMessage = function(Message)
	if(onServer()) then
		print("[DccTurretEditorConfig] " .. Message)
	end
end

local This = {

	OK = false,
	ConfDir = "moddata/DccWeaponEngineering",
	ConfFile = "Config.lua",

	RarityMult = 0.0,
	CostColour = 0,
	CostTargeting = 0,
	CostCoaxial = 0,
	CostSize = 0,
	Colour1Mod = { Sat=1.0, Val=1.0 },
	Colour2Mod = { Sat=1.0, Val=1.0 },
	NearZeroFloat = 0.0,
	TurretSlotMin = 0,
	FixDefaultTargetingNerf = 0.0,
	MountingRarityRequirement = 0,
	MountingCountRequirement = 5,
	Debug = false,

	LoadDefault = function(self)

		local File

		PrintMessage("Loading ConfigDefault.lua")
		IsOK, Input = pcall(function()
			return include("mods/DccTurretEditor/ConfigDefault")
		end)

		if(not IsOK) then
			PrintMessage("Error loading ConfigDefault.lua")
			return false
		end

		--------

		for Property,Value in pairs(Input) do
			if(self[Property] ~= nil) then
				if(type(Value) == "table") then
					self[Property] = table.deepcopy(Value)
				else
					self[Property] = Value
				end
			end
		end

		--------

		self.OK = true
		PrintMessage("ConfigDefault.lua OK")
		return true
	end,

	LoadCustom = function(self)

		local File
		local Data
		local Input
		local Property
		local Value

		-- cheers Rinart73

		-- make sure our config directory exists.

		createDirectory(self.ConfDir)

		-- try and open the custom config file all low level like. the default distribution
		-- does not include this file so if someone wants to customize it and have their
		-- choices not get overwritten then they can copy ConfigDefault.lua to the moddata
		-- folder and keep their choices.

		File = io.open(self.ConfDir .. "/" .. self.ConfFile,"r")
		if(File == nil) then
			PrintMessage("No " .. self.ConfDir .. "/" .. self.ConfFile .. " found. This is fine.")
			return
		end

		PrintMessage("Loading " .. self.ConfDir .. "/" .. self.ConfFile)
		Data = File:read("*all")
		File:close()
		File = nil

		-- now try to load the custom config file legit.

		if(Data == "") then
			PrintMessage("Error loading custom config. Skipping.")
			return
		end

		File = loadstring(Data)
		if(File == nil) then
			PrintMessage("Error parsing custom config. Skipping.")
			return
		end

		Input = File()

		-- now merge in the settings.

		for Property,Value in pairs(Input) do
			if(self[Property] ~= nil) then
				if(type(Value) == "table") then
					self[Property] = table.deepcopy(Value)
				else
					self[Property] = Value
				end
			end
		end

		-- some value sanity.

		if(self.TurretSlotMin < 0)
		then self.TurretSlotMin = 0 end

		if(self.FixDefaultTargetingNerf < 0.0)
		then self.FixDefaultTargetingNerf = 0.0 end

		if(self.MountingRarityRequirement < 0)
		then self.MountingRarityRequirement = 0 end

		return
	end

};

if(This:LoadDefault()) then
	if(onServer()) then
		This:LoadCustom()
	end
end

return This;
