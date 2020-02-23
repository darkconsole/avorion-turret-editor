#/bin/sh

cat ../avorion-turret-editor/patches/* | patch -p2
cp -rv ../avorion-turret-editor/mods/DccTurretEditor/Textures mods/DccTurretEditor
