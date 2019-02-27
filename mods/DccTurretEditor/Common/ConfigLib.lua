
local PrintMessage = function(Message)
	if(onServer()) then
		print("[DccTurretEditorConfig] " .. Message)
	end
end

local This = {

	OK = false,

	RarityMult = 0.0,
	CostColour = 0,
	CostTargeting = 0,
	CostCoaxial = 0,
	CostSize = 0,
	Colour1Mod = nil,
	Colour2Mod = nil,
	NearZeroFloat = 0.0,
	Debug = false,

	LoadDefault = function(self)

		PrintMessage("Loading ConfigDefault.lua")

		local IsOK, Input = pcall(
			require,
			"mods.DccTurretEditor.ConfigDefault"
		)

		if(not IsOK) then
			PrintMessage("Error loading ConfigDefault.lua")
			return false
		end

		--------

		self.RarityMult = Input.RarityMult
		self.CostColour = Input.CostColour
		self.CostTargeting = Input.CostTargeting
		self.CostCoaxial = Input.CostCoaxial
		self.CostSize = Input.CostSize
		self.Colour1Mod = Input.Colour1Mod
		self.Colour2Mod = Input.Colour2Mod
		self.NearZeroFloat = Input.NearZeroFloat
		self.Debug = Input.Debug

		--------

		self.OK = true
		PrintMessage("ConfigDefault.lua OK")
		return true
	end,

	LoadCustom = function(self)
		PrintMessage("Loading Config.lua")

		local IsOK, Input = pcall(
			require,
			"mods.DccTurretEditor.Config"
		)

		if(not IsOK) then
			PrintMessage("Config.lua not found. Skipping.")
			return
		end

		--------

		if(Input.RarityMult ~= nil)
		then self.RarityMult = Input.RarityMult end

		if(Input.CostColour ~= nil)
		then self.CostColour = Input.CostColour end

		if(Input.CostTargeting ~= nil)
		then self.CostTargeting = Input.CostTargeting end

		if(Input.CostCoaxial ~= nil)
		then self.CostCoaxial = Input.CostCoaxial end

		if(Input.CostSize ~= nil)
		then self.CostSize = Input.CostSize end

		if(Input.Colour1Mod ~= nil)
		then self.Colour1Mod = Input.Colour1Mod end

		if(Input.Colour2Mod ~= nil)
		then self.Colour2Mod = Input.Colour2Mod end

		if(Input.CostDebug ~= nil)
		then self.CostDebug = Input.CostDebug end

		if(Input.NearZeroFloat ~= nil)
		then self.NearZeroFloat = Input.NearZeroFloat end

		--------

		PrintMessage("Config.lua OK")
		return
	end

};

if(This:LoadDefault()) then
	This:LoadCustom()
end

return This;
