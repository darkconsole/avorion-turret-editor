
function execute(PlayerID, Command, Action, ...)

	if(onServer())
	then
		Player(PlayerID):addScriptOnce("lib/dcc-turret-editor/cmd-inventory",Action,...)
	end

	return 0, "", ""
end

