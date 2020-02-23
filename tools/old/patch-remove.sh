#/bin/sh

cat ../avorion-turret-editor/patches/* | patch -p2 -R
rm -rfv mods/DccTurretEditor/Textures
