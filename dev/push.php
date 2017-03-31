<?php

// this script will copy the files to our server via my remote ssh mount.

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

define('ProjectRoot','..');
define('StockDir', '/avorion-0.11.0.7844/data/scripts');
define('ModDir', '/avorion-turret-editor/data/scripts');
define('RemoteDir','Z:\home\avorion\steamcmd\avorion\data\scripts');
define('LocalDir','D:\Games\Steam\steamapps\common\Avorion\data\scripts');

define('Files',[
	'/commands/turretupgrade.lua'               => '/patch-commands-turretupgrade.diff',
	'/lib/dcc-turret-editor/cmd-inventory.lua' => '/patch-lib-dcc-turrent-editor-cmd-inventory.diff',
	'/lib/dcc-turret-editor/ui-turret-editor.lua' => '/patch-lib-dcc-turrent-editor-ui-turret-editor.diff'
]);

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

function
Pathify(String $Filepath):
String {
/*//
generate proper file paths for the os given that we are writing the code for
forward slashes in mind. seems to be needed for some windows commands.
//*/

	$Filepath = str_replace('%VERSION%','Version',$Filepath);

	return str_replace('/',DIRECTORY_SEPARATOR,$Filepath);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

$File;
$Patch;
$Command;

foreach(Files as $File => $Patch) {
	$Command = sprintf(
		'xcopy /R /Y %s %s',
		escapeshellarg(Pathify(ProjectRoot.ModDir.$File)),
		escapeshellarg(Pathify(RemoteDir.$File))
	);

	//echo $Command, PHP_EOL;
	system($Command);

	$Command = sprintf(
		'xcopy /R /Y %s %s',
		escapeshellarg(Pathify(ProjectRoot.ModDir.$File)),
		escapeshellarg(Pathify(LocalDir.$File))
	);

	//echo $Command, PHP_EOL;
	system($Command);
}
