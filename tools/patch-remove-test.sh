#/bin/sh

cat ../avorion-turret-editor/patches/* | patch -p2 -R --dry-run
