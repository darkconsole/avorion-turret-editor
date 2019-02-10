--[[----------------------------------------------------------------------------
AVORION: Turret Modding Command: /tmod
darkconsole <darkcee.legit@gmail.com>

This script handles applying and updating the weapons bay on the players ship.
----------------------------------------------------------------------------]]--

local TurretEditorCommand = {}

package.path = package.path
.. ";data/scripts/lib/?.lua"
.. ";data/scripts/sector/?.lua"
.. ";data/scripts/?.lua"

require("utility")
require("callable")

function initialize(Command,...)

	local ScriptFile = "mods/DccTurretEditor/Interface/TurretModding"
	local PlayerRef = Player()
	local Ship = Entity(Player().craftIndex)

	-- house clean both sides of the isle.

	print("[DccTurretEditor] TURRET MODDING COMMAND LOAD")
	Ship:removeScript(ScriptFile)

	-- but from here on, do server side authority.

	if(not onServer()) then
		return
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

function TurretEditorCommand.WeDoneHereAndThere(Title,Text)
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

callable(TurretEditorCommand,"WeDoneHereAndThere")
