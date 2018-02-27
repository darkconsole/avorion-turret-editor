
local This = {

	RarityMult = 0.0,
	CostColour = 0,
	CostTargeting = 0,
	Colour1Mod = nil,
	Colour2Mod = nil,
	Debug = false,

	LoadDefault = function(self)
		print("[DccTurretEditor] Loading ConfigDefault.lua")

		local IsOK, Input = pcall(
			require,
			"mods.DccTurretEditor.ConfigDefault"
		)

		if(not IsOK) then
			print("[DccTurretEditor] Error loading ConfigDefault.lua")
			return false
		end

		--------

		self.RarityMult = Input.RarityMult
		self.CostColour = Input.CostColour
		self.CostTargeting = Input.CostTargeting
		self.Colour1Mod = Input.Colour1Mod
		self.Colour2Mod = Input.Colour2Mod
		self.Debug = Input.Debug

		--------

		print("[DccTurretEditor] ConfigDefault.lua OK")
		return true
	end,

	LoadCustom = function(self)
		print("[DccTurretEditor] Loading Config.lua")

		local IsOK, Input = pcall(
			require,
			"mods.DccTurretEditor.Config"
		)

		if(not IsOK) then
			print("[DccTurretEditor] Config.lua not found. Skipping.")
			return
		end

		--------

		if(Input.RarityMult ~= nil)
		then self.RarityMult = Input.RarityMult end

		if(Input.CostColour ~= nil)
		then self.CostColour = Input.CostColour end

		if(Input.CostTargeting ~= nil)
		then self.CostTargeting = Input.CostTargeting end

		if(Input.Colour1Mod ~= nil)
		then self.Colour1Mod = Input.Colour1Mod end

		if(Input.Colour2Mod ~= nil)
		then self.Colour2Mod = Input.Colour2Mod end

		if(Input.CostDebug ~= nil)
		then self.CostDebug = Input.CostDebug end

		--------

		print("[DccTurretEditor] Config.lua OK")
		return
	end

};

if(not This:LoadDefault()) then
	return nil
end

This:LoadCustom()

return This;
