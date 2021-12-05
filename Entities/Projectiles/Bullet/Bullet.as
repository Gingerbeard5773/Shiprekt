#include "WaterEffects.as";
#include "BlockCommon.as";
#include "IslandsCommon.as";
#include "Booty.as";
#include "AccurateSoundPlay.as";
#include "TileCommon.as";
#include "ParticleSparks.as";

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


f32 getDamage(CBlob@ hitBlob, int blockType)
{
	if (hitBlob.getName() == "shark" || hitBlob.getName() == "human" || hitBlob.hasTag("weapon"))
		return 0.4f;
	else if (Block::isBomb(blockType))
		return 1.35f;

	f32 dmg = 0.25f; //cores | solids
	switch (blockType)
	{
		case Block::PROPELLER:
			dmg = 0.75f;
			break;
		case Block::RAMENGINE:
			dmg = 1.5f;
			break;
		case Block::SEAT:
		case Block::DECOYCORE:
		case Block::POINTDEFENSE:
			dmg = 0.4f;
			break;
		case Block::ANTIRAM:
			dmg = 0.5f;
			break;
		case Block::FAKERAM:
			dmg = 2.0f;
			break;
		case Block::DOOR:
			dmg = 0.7f;
			break;
	}
		
	return dmg;
}

void onCollision(CBlob@ this, CBlob@ b, bool solid)
{
	bool killed = false;

	if (b !is null)
	{
		const int color = b.getShape().getVars().customData;
		const int blockType = b.getSprite().getFrame();
		const bool isBlock = b.getName() == "block";				

		if (!b.hasTag("booty") && (color > 0 || !isBlock))
		{
			if (isBlock || b.hasTag("weapon"))
			{
				if (Block::isSolid(blockType) || blockType == Block::DOOR || (b.getTeamNum() != this.getTeamNum() && 
				(blockType == Block::MOTHERSHIP5 || blockType == Block::SECONDARYCORE || blockType == Block::DECOYCORE || b.hasTag("weapon") || blockType == Block::BOMB)))//hit these and die
				{
					killed = true;
					sparks(this.getPosition() + this.getVelocity(), 8);
					directionalSoundPlay("Ricochet" + (XORRandom(3) + 1) + ".ogg", this.getPosition(), 0.50f);
				}
				else if (b.hasTag("seat") || blockType == Block::FLAK || blockType == Block::HYPERFLAK)
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
					damageBooty(owner, blob, b, b.hasTag("propeller"), 5);
			}

			this.server_Hit(b, this.getPosition(), Vec2f_zero, getDamage(b, blockType), 0, true);
			
			if (killed)
				this.server_Die();
		}
	}
}

void onDie(CBlob@ this)
{
	if (isInWater(this.getPosition()) && this.getTouchingCount() <= 0)
	{
		MakeWaterParticle(this.getPosition(), Vec2f_zero);
	}
}
