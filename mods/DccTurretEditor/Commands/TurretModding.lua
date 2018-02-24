
package.path = package.path
.. ";data/scripts/lib/?.lua"
.. ";data/scripts/sector/?.lua"
.. ";data/scripts/?.lua"

require("utility")

function initialize(Command,...)

	local ScriptFile = "mods/DccTurretEditor/Interface/TurretModding"
	local PlayerRef = Player()
	local Ship = Entity(Player().craftIndex)

	Ship:removeScript(ScriptFile)

	--------

	local ConfigOK, Config = pcall(
		require,
		'mods.DccTurretEditor.Config'
	)

	if(not ConfigOK)
	then
		deferredCallback(
			1, "WeDoneHereAndThere",
			"Weapon Engineering: Config.lua Error",
			"Did you remember to copy ConfigDefault.lua?"
		)
		return
	end

	--------

	if(onServer())
	then
		print("[DccTurretEditor] Adding Turret Modding to " .. PlayerRef.name .. " on " .. Ship.name)
		Ship:addScriptOnce(ScriptFile)
	end

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
