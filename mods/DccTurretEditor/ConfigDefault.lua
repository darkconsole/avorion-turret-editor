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

	Colour1Mod = { Sat = 0.50, Val = 0.90 },
	-- when the user picks a colour modify it by this amount to try and make
	-- beams look nicer. default, Sat = 0.5, Val = 0.9 strip colour from core.

	Colour2Mod = { Sat = 0.90, Val = 0.50 },
	-- when the user picks a colour modify it by this amount to try and make
	-- glows look nicer. default: Sat = 0.9, Val = 0.5 strip brightness from
	-- the glow effect of beams.

	NearZeroFloat = 0.025,
	-- when buffing values downwards its actually impossible to hit zero with
	-- percentages so when numbers get small we will include a flat value.

	Debug = true

};

return Config;
