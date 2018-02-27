--[[----------------------------------------------------------------------------
AVORION: Turret Modding Command: /tmod
darkconsole <darkcee.legit@gmail.com>

This script handles applying and updating the weapons bay on the players ship.
----------------------------------------------------------------------------]]--

package.path = package.path
.. ";data/scripts/lib/?.lua"
.. ";data/scripts/sector/?.lua"
.. ";data/scripts/?.lua"

require("utility")

function initialize(Command,...)

	print("[DccTurretEditor] TURRET MODDING COMMAND LOAD")

	local ScriptFile = "mods/DccTurretEditor/Interface/TurretModding"
	local PlayerRef = Player()
	local Ship = Entity(Player().craftIndex)

	-- house clean both sides of the isle.

	Ship:removeScript(ScriptFile)

	-- but from here on, do server side authority.

	if(not onServer()) then
		return terminate()
	end

	-- make sure we could load the config.

	local Config = require("mods.DccTurretEditor.Common.ConfigLib")

	if(not Config.OK) then
		deferredCallback(
			0, "WeDoneHereAndThere",
			"Weapon Engineering: ConfigDefault.lua Error",
			"Did you RENAME ConfigDefault.lua? Don't do that."
		)
		return
	end

	--------

	Ship:addScriptOnce(ScriptFile)
	return terminate()
end

function WeDoneHereAndThere(Title,Text)
	if(onServer())
	then
		invokeClientFunction(Player(),"WeDoneHereAndThere",Title,Text)
		terminate()
		return
	end

	displayMissionAccomplishedText(Title,Text)
	terminate()
	return
end
