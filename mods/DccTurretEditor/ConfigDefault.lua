local Config = {

	RarityMult = 0.1669,
	-- how much the rarities get weighted. the default value of 0.1996 means
	-- scrapping 5 white turrets will buff 0.7% while scrapping 5 legendary
	-- turrets will buff 5%

	CostColour = 2500,
	-- how many credits to charge for a colour change.

	CostTargeting = 10000,
	-- how many credits to charge to enable auto targeting.

	CostCoaxial = 25000,
	-- how many credits to charge to enable coaxial mounting and dmg.

	CostSize = 1000,
	-- how many credits to charge to change the turret visual size.

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
	-- quality or better.

	MountingCountRequirement = 5,
	-- how many turrets must be scrapped at once to upgrade amount.

	Debug = true,
	Experimental = false

};

return Config;
