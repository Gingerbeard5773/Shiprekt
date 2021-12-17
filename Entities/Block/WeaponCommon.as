#include "IslandsCommon.as";

void refillAmmo(CBlob@ this, uint8 refillAmount, uint8 refillSeconds, uint8 refillSecondaryCore, uint8 refillSecondaryCoreSeconds)
{
	if (isServer())
	{
		Island@ isle = getIsland(this.getShape().getVars().customData);

		if (isle !is null)
		{
			u16 ammo = this.get_u16("ammo");
			u16 maxAmmo = this.get_u16("maxAmmo");

			if (ammo < maxAmmo)
			{
				if (isle.isMothership || isle.isStation || isle.isMiniStation)
				{
					if (getGameTime() % (30 * refillSeconds) == 0)
					{
						ammo = Maths::Min(maxAmmo, ammo + refillAmount);
					}
				}
				else if (isle.isSecondaryCore)
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
