
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

	if(onServer())
	then
		print("[DccTurretEditor] Adding Turret Modding to " .. PlayerRef.name .. " on " .. Ship.name)
		Ship:addScriptOnce(ScriptFile)
	end

	return terminate()
end
