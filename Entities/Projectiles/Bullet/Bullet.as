#include "WaterEffects.as";
#include "IslandsCommon.as";
#include "Booty.as";
#include "AccurateSoundPlay.as";
#include "TileCommon.as";
#include "ParticleSparks.as";
#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.Tag("projectile");
	this.Tag("bullet");

	ShapeConsts@ consts = this.getShape().getConsts();
    consts.mapCollisions = false;
	consts.bullet = true;	

	this.getSprite().SetZ(550.0f);	
}

void onTick(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	
	if (isTouchingRock(pos))
	{
		sparks(pos, 8);
		directionalSoundPlay("Ricochet" +  (XORRandom(3) + 1 ) + ".ogg", pos, 0.50f);
		this.server_Die();
	}
}


f32 getDamage(CBlob@ hitBlob)
{
	if (hitBlob.getName() == "shark" || hitBlob.getName() == "human" || hitBlob.hasTag("weapon"))
		return 0.4f;
	if (hitBlob.hasTag("bomb"))
		return 1.35f;
	if (hitBlob.hasTag("propeller"))
		return 0.75f;
	if (hitBlob.hasTag("ramengine"))
		return 1.5f;
	if (hitBlob.hasTag("antiram"))
		return 0.5f;
	if (hitBlob.hasTag("door"))
		return 0.7f;
	if (hitBlob.hasTag("seat") || hitBlob.hasTag("decoyCore") || hitBlob.hasTag("pointdefense"))
		return 0.4f;
		
	return 0.25f; //cores | solids
}

void onCollision(CBlob@ this, CBlob@ b, bool solid, Vec2f normal, Vec2f point1)
{
	bool killed = false;

	if (b !is null)
	{
		const int color = b.getShape().getVars().customData;
		const bool isBlock = b.hasTag("block");				

		if (!b.hasTag("booty") && (color > 0 || !isBlock))
		{
			if (isBlock || b.hasTag("weapon"))
			{
				if (b.hasTag("solid") || b.hasTag("door") || (b.getTeamNum() != this.getTeamNum() && 
				(b.hasTag("mothership") || b.hasTag("secondaryCore") || b.hasTag("decoyCore") || b.hasTag("weapon") || b.hasTag("bomb"))))//hit these and die
				{
					killed = true;
					sparks(point1, 8);
					directionalSoundPlay("Ricochet" + (XORRandom(3) + 1) + ".ogg", this.getPosition(), 0.50f);
				}
				else if (b.hasTag("hasSeat"))
				{
					AttachmentPoint@ seat = b.getAttachmentPoint(0);
					CBlob@ occupier = seat.getOccupied();
					if (occupier !is null && occupier.getName() == "human" && occupier.getTeamNum() != this.getTeamNum())
					{
						killed = true;
						if (XORRandom(3) == 0)//1/3 chance to hit the driver
							@b = occupier;
					}
					else return;
				}
				else return;
			}
			else
			{
				if (b.getTeamNum() != this.getTeamNum() && !b.isAttached())
				{
					if (b.getName() == "shark" || b.hasTag("player"))
						killed = true;
				}
				else return;
			}
			
			CPlayer@ owner = this.getDamageOwnerPlayer();
			if (owner !is null)
			{
				CBlob@ blob = owner.getBlob();
				if (blob !is null)
					damageBooty(owner, blob, b, b.hasTag("engine"), 5);
			}

			this.server_Hit(b, this.getPosition(), Vec2f_zero, getDamage(b), Hitters::bomb_arrow, true);
			
			if (killed)
				this.server_Die();
		}
	}
}

void onDie(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	if (!isInWater(pos))
	{
		AngledDirtParticle(pos, -this.getVelocity().Angle() - 90.0f);
		directionalSoundPlay("Ricochet" + (XORRandom(3) + 1) + ".ogg", pos, 0.50f);
	}
	else if (this.getTouchingCount() <= 0)
	{
		MakeWaterParticle(pos, Vec2f_zero);
	}
}
