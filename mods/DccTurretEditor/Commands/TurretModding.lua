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

include("utility")
include("callable")

function initialize(Command,...)

	local ScriptFile = "mods/DccTurretEditor/Interface/TurretModding"
	local PlayerRef = Player()
	local Ship = Entity(Player().craftIndex)
	local Config

	-- house clean both sides of the isle.

	print("[DccTurretEditor] TURRET MODDING COMMAND LOAD")
	Ship:removeScript(ScriptFile)

	-- but from here on, do server side authority.

	if(not onServer()) then
		return
	end

	-- make sure we could load the config.

	Config = include("mods/DccTurretEditor/Common/ConfigLib")

	if(not Config.OK) then
		deferredCallback(
			0, "WeDoneHereAndThere",
			"Weapon Engineering: ConfigDefault.lua Error",
			"Did you RENAME ConfigDefault.lua? Don't do that."
		)
	end
	
	deferredCallback(
		0, "TurretEditorCommand_AllRightLetsGo",
		Uuid(PlayerRef.craftIndex).string
	)

	return
end

function TurretEditorCommand_WeDoneHereAndThere(Title,Text)
	if(onServer())
	then
		invokeClientFunction(Player(),"TurretEditorCommand_WeDoneHereAndThere",Title,Text)
		terminate()
		return
	end

	displayMissionAccomplishedText(Title,Text)
	terminate()
	return
end

function TurretEditorCommand_AllRightLetsGo(ShipUUID)

	local ScriptFile = "mods/DccTurretEditor/Interface/TurretModding"

	if(onServer())
	then
		invokeClientFunction(Player(),"TurretEditorCommand_AllRightLetsGo",ShipUUID)
	end

	if(onClient())
	then
		print("TurretEditorCommand.AllRightLetsGo " .. ShipUUID)
	end

	print("[DccTurretEditor] Adding Script To Ship " .. ShipUUID)
	Entity(Uuid(ShipUUID)):addScriptOnce(ScriptFile)
	terminate()
	return
end

callable(nil,"TurretEditorCommand_WeDoneHereAndThere")
callable(nil,"TurretEditorCommand_AllRightLetsGo")
