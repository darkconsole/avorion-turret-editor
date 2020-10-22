
function execute(PlayerID, Command, Action, ...)

	local ScriptFile = "mods/DccTurretEditor/Commands/TurretModding"

	if(not onServer())
	then return end

	if(Player(PlayerID):hasScript(ScriptFile))
	then
		print("[DccTurretEditor] Clearing Old Instance...")
		Player(PlayerID):removeScript(ScriptFile)
	end

	print("[DccTurretEditor] Adding New Instance...")
	Player(PlayerID):addScriptOnce(ScriptFile,Action,...)

	return 0, "", ""
end

function getDescription()
	return "Activates turret editor"
end

function getHelp()
	return "Activates turret editor. Usage:\n/tmod\n"
end
