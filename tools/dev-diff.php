<?php

// this script will generate all the diffs that can be used for patching the
// avorion source with these modifications.

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

define('ProjectRoot','..');
define('StockDir', '/avorion-stock');
define('ModDir', '/avorion-turret-editor');
define('PatchDir', '/avorion-turret-editor/patches');

define('Files',[
	'/data/scripts/lib/dcc-turret-editor/cmd-inventory.lua'    => '/patch-lib-dcc-turret-editor-cmd-inventory.diff',
	'/data/scripts/lib/dcc-turret-editor/ui-turret-editor.lua' => '/patch-lib-dcc-turret-editor-ui-turret-editor.diff',
	'/data/scripts/commands/tedit.lua'                         => '/patch-commmands-tedit.diff',

	'/data/scripts/commands/tmod.lua'                   => '/patch-commands-tmod.diff',
	'/mods/DccTurretEditor/TurretLib.lua'               => '/Patch-Mods-DccTurretEditor-TurretLib.lua',
	'/mods/DccTurretEditor/Interface/TurretModding.lua' => '/Patch-Mods-DccTurretEditor-Interface-TurrentModding.diff'
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
		'diff -urN --strip-trailing-cr %s %s > %s',
		escapeshellarg((ProjectRoot.StockDir.$File)),
		escapeshellarg((ProjectRoot.ModDir.$File)),
		escapeshellarg(Pathify(ProjectRoot.PatchDir.$Patch))
	);

	echo $Command, PHP_EOL;
	system($Command);
}
