# Weapon Engineering: Avorion Turret Editor

![Warning](https://img.shields.io/badge/BETA-Use%20At%20Your%20Own%20Risk-red.svg) ![Minimum Avorion Version](https://img.shields.io/badge/Avorion-0.20.4-lightgrey.svg)

> *By the time we reach Jupiter Station, I don't want their engineers to have a
> thing to do but give us a wash and a wax.*

No longer must you play research station lottery or the shopping list game to
fill a factory if you already have a turret you like. This mod allows you to
cannibalize other turrets to upgrade an existing one.

![Example Image](https://i.imgur.com/W6fHVUf.png)

You select the turret you want to upgrade and drag it to the big box. Then you
can select up to 5 additional turrets to destroy and drag them to the smaller
boxes. The more turrets you select, the bigger the upgrade performed to the
selected turret. The tech level of the turrets you scrap is also part of the
upgrade math, use turrets greater than or equal to the tech level of the turret
you want to upgrade for maximum effect. The rarity of the turrets you are
scrapping also affects the final result.

The better the turret you are trying to upgrade, and the better weapons you use
to upgrade it, the bigger the upgrade will be.

![Example Image](https://i.imgur.com/dZeuIlm.png)

![Example Image](https://i.imgur.com/5pEhomq.png)

Additionally, autotargeting can be added, and the colour of the projectiles and
beam can be customised for credits. You want red beams and bullets? Then get
some red beams and bullets.

## Upgrade Options

* Heat Sinks - Reduces the heat generated per shot, and increases the cooldown
  speed.
* Capacitors - Reduces the base power requirement of a turret.
* Transformers - Reduces the rate the energy use climbs.
* Ammunition / Power Amps - Increase the flat damage of the turret.
* Drive Motors - Increase how fast the turret can turn.
* Barrel / Lenses - Increase the range a turret can hit at.
* Trigger Mechanism - Increase the rate of fire.
* Stabilizers - Increase the accuracy rating.
* Phase Filters - Increase the efficiency rating of mining or scav gun.
* Targeting - Add or remove self targeting for the turret.
* Colour HSV - Drag the sliders to change the colour of the beam or projectiles.

## Install

If you don't read and follow these simple install instructions I will tell the
Xsotan where you sleep.

**Multiplayer Server Admin**

1) Copy the `data` and `mods` folder into the game directory. This must be
installed on both the client and the server, unless the players do not intend
to use it then they don't have to install it. This mod does not overwrite any
stock files at this time.

2) Copy the file `mods\DccTurretEditor\ConfigDefault.lua` to `Config.lua` and
tweak if you want.

**Single Player**

1) Copy the the `data` and `mods` folders into your game

2) Copy the file `mods\DccTurretEditor\ConfigDefault.lua` to `Config.lua` and
tweak if you want.

## Usage

While in one of your ships use the chat command `/tmod` this will attach the
Engineering Weapons Bay to your ship, adding an icon to open the main window
in the top right corner of the screen. It looks like a little turret with a
wrench on top of it.

![Example Image](https://i.imgur.com/NE8ybtU.png)

1) Drag the turret you want to upgrade to the big box.

2) Drag 1 to 5 more turrets to the smaller boxes. These are the turrets you
   will destroy to upgrade the selected turret. Each turret you add will change
   the percentage displayed above the scrap bin. For example, if this says 2%,
   and you want to upgrade a turret that does 10 damage, after it will do 10.2
   damage. If the turret does 20 damage, after it will do 20.4 damage.

3) Click one of the avaialble upgrade choices. If your weapon heats up too fast,
   then upgrade the heat sinks. If your turret fires too slow, upgrade the
   trigger mechanism. Hover over each button, the tooltip tells you what will
   happen. Clicking one of these buttons will consume the turrets in the scrap
   bin and upgrade the selected turret.

   Stats which are already maxed out, or do not apply to the selected turret,
   will be greyed out.

4) You can add targeting and change the colour of the weapon for money. If you
   if you are just doing targeting and colour, you do not need to add any
   turrets to the scrap bin.

# Notes

* Targeting only costs money because I believe if you are paying the gunners to
sit there then they can do their one job of pointing the damn gun for you.

* The colour you set will change after clicking the button. That is because the
code takes the colour you choose, and then modifies it a bit to *try* and
produce laser beams that won't look as stupid as the colour you picked.

* Item rarity and tech level are both used as part of the math to try and
keep the usage of the Weapons Bay balanced. To get a good upgrade you are going
to have to sacrifice good parts.

* If you think a turret disappeared, double and triple check your inventory
to be sure it did not stack with another. Avorion does a little bit of a dumb
with the inventory where it stacks items after rounding their values, so if
a turret is really close to another one in stats but not exact it can still be
stacked. To combat this problem, every time a turret is upgraded it will have
a Mark Number added to the name. "Double Mining Mk 2 Turret" means this is a
turret you have upgraded twice, but I've totally stacked Mk 2 turrets before. It
is not perfect.

## Future Plans

Make it a system upgrade chip that drops from combat/scavving instead of the
chat command to attach it to your ship.

## Support

I use Patreon as a tip jar if you are feeling frisky. Be warned this Patreon
page contains adult content because I'm actually a NSFW Skyrim modder at heart.

https://www.patreon.com/darkconsole
