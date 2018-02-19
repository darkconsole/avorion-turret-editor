# Avorion Turret Editor

![Warning](https://img.shields.io/badge/Work%20In%20Progress-Use%20At%20Your%20Own%20Risk-red.svg)

![Minimum Avorion Version](https://img.shields.io/badge/Avorion-0.15.8.10262-lightgrey.svg)

This mod allows you to upgrade turrets you have and may like, by cannibalizing
parts from turrets you are probably just going to throw away.

![Example Image](https://cdn.discordapp.com/attachments/231654495950602242/415010470584647691/unknown.png)

You select the turret you want to upgrade and drag it to the big box. Then you
can select up to 5 additional turrets to destroy and drag them to the smaller
boxes. The more turrets you select, the bigger the upgrade performed to the
selected turret. The tech level of the turrets you scrap is also part of the
upgrade math, use turrets greater than or equal to the tech level of the turret
you want to upgrade for maximum effect. The rarity of the turrets you are
scrapping also affects the final result.

The upgrades are small, but if you scav a lot of turrets you dont want and get
none of the ones you do want, this can be a nice way to boost what you have. For
example: if it says "Turrets To Scrap (+2%)" and you want to upgrade damage
currently at 10, that means 2% of the current value, so that turret would be
upgraded to 10.2 damage. Because it is percentage based, the better the turret
you are trying to upgrade and the better the turrets you scrap, the bigger the
upgrade will be.

The upgrade percentages will be able to be tweaked via a config file to better
suit what you want.

Additionally, autotargeting can be added, and the colour of the projectiles and
beam can be customised for credits.

## Install

Copy the `data` and `mods` folder into the game directory. This must be
installed on both the client and the server, unless the players do not intend
to use it then they don't have to install it. Single player, you just copy it
into the game directory.

## Usage

While in one of your ships use the chat command `/tmod` this will attach the
Engineering Weapons Bay to your ship, adding an icon to open the main window
in the top right corner of the screen. It looks like a little turret with a
wrench on top of it.