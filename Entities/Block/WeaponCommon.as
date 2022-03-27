#include "ShipsCommon.as";

void refillAmmo(CBlob@ this, uint8 refillAmount, uint8 refillSeconds, uint8 refillSecondaryCore, uint8 refillSecondaryCoreSeconds)
{
	if (isServer())
	{
		Ship@ ship = getShip(this.getShape().getVars().customData);

		if (ship !is null)
		{
			u16 ammo = this.get_u16("ammo");
			u16 maxAmmo = this.get_u16("maxAmmo");

			if (ammo < maxAmmo)
			{
				if (ship.isMothership || ship.isStation)
				{
					if (getGameTime() % (30 * refillSeconds) == 0)
					{
						ammo = Maths::Min(maxAmmo, ammo + refillAmount);
					}
				}
				else if (ship.isSecondaryCore)
				{
					if (getGameTime() % (30 * refillSecondaryCoreSeconds) == 0)
					{
						ammo = Maths::Min(maxAmmo, ammo + refillSecondaryCore);
					}
				}

				this.set_u16("ammo", ammo);
				this.Sync("ammo", true);
			}
		}
	}
}
