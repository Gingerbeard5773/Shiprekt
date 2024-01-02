#include "ShipsCommon.as";

// Refill ammunition for weapons
shared void refillAmmo(CBlob@ this, Ship@ ship, const u8&in refillAmount, const u8&in refillSeconds)
{
	if (!isServer()) return;
	
	const u16 ammo = this.get_u16("ammo");
	const u16 maxAmmo = this.get_u16("maxAmmo");

	if (ammo < maxAmmo)
	{
		u16 refill = ammo;
		if (ship.isMothership || ship.isStation)
		{
			const f32 dockedFactor = this.get_bool("docked") ? 0.5f : 2.0f; //docked miniships refill fast
			if (getGameTime() % Maths::Ceil(30 * refillSeconds * dockedFactor) == 0)
			{
				refill = Maths::Min(maxAmmo, ammo + refillAmount);
			}
		}
		else if (ship.isSecondaryCore)
		{
			const f32 secondaryCoreFactor = 2.3f; //add additional delay for secondary core ships
			if (getGameTime() % Maths::Ceil(30 * refillSeconds * secondaryCoreFactor) == 0)
			{
				refill = Maths::Min(maxAmmo, ammo + refillAmount);
			}
		}

		if (refill != ammo)
		{
			this.set_u16("ammo", refill);
			this.Sync("ammo", true);
		}
	}
}

// Check if the weapon is connected to a mothership through couplings (docked miniship)
shared void checkDocked(CBlob@ this, Ship@ ship)
{
	if (!isServer() || !this.get_bool("updateBlock")) return;
	
	if ((getGameTime() + this.getNetworkID() * 33) % 30 == 0)
	{
		if (ship.isMothership && !ship.isStation)
		{
			CBlob@ core = getMothership(this.getTeamNum());
			u16[] checked, unchecked;
			this.set_bool("docked", core !is null ? !shipLinked(this, core, checked, unchecked) : false);
		}
		else
			this.set_bool("docked", false);

		this.Sync("docked", true); //-169657557 HASH
		this.set_bool("updateBlock", false);
	}
}
