local Config = {

	TechMult = 1.0,
	-- default value of 1.0 means the turret that is upgraded will
	-- get 1% of an upgrade (before rarity config) if all the scrapped
	-- turrets are the same tech level. as of 1.4 this is now the base
	-- metric of turret upgrading

	RarityMult = 0.20,
	-- default value of 0.2 means if all the turrets are the same
	-- rarity as the target, it will get 0.2% more in the grind.

	TechPostMult = 0.5,
	-- default value means the turret that is upgraded will have its
	-- tech level increased for half of the difference between it and
	-- the objects being scrapped.

	TechPostLevel = 1,
	-- default 1 means after a turret is max tech level, its tech level
	-- will continue to be bumped by 1 each time it is upgraded which
	-- in turns will deminish the upgrades over time unless you also
	-- grind up even more turrets past the limit to use as scrap. this
	-- also happens if the turret you upgraded is the same tech level
	-- as the turrets you scrapped as a way to suggest you actually did
	-- upgrade it.

	CostColour = 2500,
	-- how many credits to charge for a colour change.

	CostTargeting = 10000,
	-- how many credits to charge to enable auto targeting.

	CostCoaxial = 25000,
	-- how many credits to charge to enable coaxial mounting and dmg.

	CostSize = 1000,
	-- how many credits to charge to change the turret visual size.

	CostCoolingMoney = 50000,
	CostCoolingNaonite = 20000,
	-- cost to apply a liquid naonite cooling system to a turret, which will
	-- remove the heat penalties. set money to -1 to disable for your server.

	Colour1Mod = { Sat = 0.70, Val = 0.90 },
	-- when the user picks a colour modify it by this amount to try and make
	-- beams look nicer. default, Sat = 0.5, Val = 0.9 strip colour from core.

	Colour2Mod = { Sat = 0.90, Val = 0.50 },
	-- when the user picks a colour modify it by this amount to try and make
	-- glows look nicer. default: Sat = 0.9, Val = 0.5 strip brightness from
	-- the glow effect of beams.

	NearZeroFloat = 0.025,
	-- when buffing values downwards its actually impossible to hit zero with
	-- percentages so when numbers get small we will include a flat value.

	TurretSlotMin = 1,
	-- setting this to zero allows turrets to be improved all the way to require
	-- no slots which the game then lets us put infinite turrets on.

	FixDefaultTargetingNerf = 2.0,
	-- by default the game lowers the damage of turrets that come with targeting
	-- on them by half [lib/turretgenerator.lua around line 529 as of 2020-03-01]
	-- so if this is not zero, we will correct that when you take the targeting
	-- off. currently, that must be the very first thing you do because we're
	-- checking if the turret has been modded before so you cant just drive it up
	-- by going on off on off on off.

	MountingRarityRequirement = 0,
	-- setting this to a number like 4 will require you scrap 5 turrets of orange
	-- quality or better. the default is 0 which means all 5 scrap must be of equal
	-- quality or better. it is using our math values not the game enums so 0.5 would
	-- set it to the grey item requirement and 1 would be the white item, then +1
	-- for each type after that. its because grey enum is -1.

	MountingCountRequirement = 5,
	-- how many turrets must be scrapped at once to upgrade amount.

	FlakCountRequirement = 3,
	-- how many turrets required to convert an af turret to a flak cannon.

	ProjectileSpeedMax = 850,
	-- max cap for how fast players can raise the projectile speed.

	Debug = true,
	Experimental = false

};

return Config;
