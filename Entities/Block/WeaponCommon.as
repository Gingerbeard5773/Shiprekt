#include "ShipsCommon.as";

void refillAmmo(CBlob@ this, Ship@ ship, uint8 refillAmount, uint8 refillSeconds, uint8 refillSecondaryCore, uint8 refillSecondaryCoreSeconds)
{
	if (!isServer()) return;
	
	u16 ammo = this.get_u16("ammo");
	u16 maxAmmo = this.get_u16("maxAmmo");

	if (ammo < maxAmmo)
	{
		if (ship.isMothership || ship.isStation)
		{
			u32 dockedFactor = this.get_bool("docked") ? 1 : 2; //miniships refill faster
			if (getGameTime() % (30 * refillSeconds * dockedFactor) == 0)
			{
				ammo = Maths::Min(maxAmmo, ammo + refillAmount);
			}
		}
		else if (ship.isSecondaryCore)
		{
			if (getGameTime() % (35 * refillSecondaryCoreSeconds) == 0)
			{
				ammo = Maths::Min(maxAmmo, ammo + refillSecondaryCore);
			}
		}

		this.set_u16("ammo", ammo);
		this.Sync("ammo", true);
	}
}

void checkDocked(CBlob@ this, Ship@ ship)
{
	if (!isServer() || !this.get_bool("updateArrays")) return;
	
	u32 gameTime = getGameTime();
	if ((gameTime + this.getNetworkID() * 33) % 60 == 0)
	{
		if (ship.isMothership && !ship.isStation)
		{
			CBlob@ core = getMothership(this.getTeamNum());
			u16[] checkedIDs;
			this.set_bool("docked", core !is null ? !coreLinkedDirectional(this, checkedIDs, core.getPosition()) : false);
		}
		else
			this.set_bool("docked", false);

		this.Sync("docked", true);
		this.set_bool("updateArrays", false);
	}
}
