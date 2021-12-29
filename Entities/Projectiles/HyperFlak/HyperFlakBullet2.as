#include "ExplosionEffects.as";
#include "WaterEffects.as";
#include "IslandsCommon.as";
#include "Booty.as";
#include "AccurateSoundPlay.as";
#include "TileCommon.as";
#include "ParticleSparks.as";
#include "Hitters.as";

const f32 EXPLODE_RADIUS = 25.0f;
const f32 FLAK_REACH = 50.0f;

void onInit( CBlob@ this )
{
	this.Tag("hyperflak shell");
	this.Tag("projectile");

	ShapeConsts@ consts = this.getShape().getConsts();
    consts.mapCollisions = false;	 // weh ave our own map collision
	consts.bullet = true;	

	this.getSprite().SetZ(550.0f);
	
	//shake screen (onInit accounts for firing latency)
	CPlayer@ localPlayer = getLocalPlayer();
	if (localPlayer !is null && localPlayer is this.getDamageOwnerPlayer())
		ShakeScreen(4, 4, this.getPosition());
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;
	
	bool killed = false;

	Vec2f pos = this.getPosition();
	const int thisColor = this.get_u32("color");
	
	if (isTouchingRock(pos))
	{
		this.server_Die();
	}

	CBlob@[] blobs;
	if (getMap().getBlobsInRadius(pos, Maths::Min(float(5 + this.getTickSinceCreated()), EXPLODE_RADIUS), @blobs))
	{
		for (uint i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			if (b is null) continue;

			const int color = b.getShape().getVars().customData;
			if (b.hasTag("block") && color > 0 && color != thisColor && b.hasTag("solid"))
				this.server_Die();
		}
	}
}

void flak(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	CMap@ map = getMap();
	CBlob@[] blobs;
	map.getBlobsInRadius(pos, FLAK_REACH, @blobs);
	
	if (blobs.length < 2)
		return;
		
	f32 angle = XORRandom(360);
	CPlayer@ owner = this.getDamageOwnerPlayer();

	for (u8 s = 0; s < 12; s++)
	{
		HitInfo@[] hitInfos;
		if (map.getHitInfosFromRay(pos, angle, FLAK_REACH, this, @hitInfos))
		{
			for (uint i = 0; i < hitInfos.length; i++)//sharpnel trail
			{
				CBlob@ b = hitInfos[i].blob;	  
				if (b is null || b is this) continue;

				const bool sameTeam = b.getTeamNum() == this.getTeamNum();
				if (b.hasTag("solid") || (!sameTeam
					&& (b.hasTag("seat") || b.hasTag("weapon") || b.hasTag("rocket") || b.hasTag("mothership") || b.hasTag("secondaryCore") || b.hasTag("decoycore") || b.hasTag("door") || b.hasTag("bomb") || (b.hasTag("player") && !b.isAttached()))))
				{
					this.server_Hit(b, hitInfos[i].hitpos, Vec2f_zero, getDamage(b), Hitters::bomb, true);
					if (owner !is null)
					{
						CBlob@ blob = owner.getBlob();
						if (blob !is null)
							damageBooty(owner, blob, b);
					}
					
					break;
				}
			}
		}
		
		angle = ( angle + 30.0f ) % 360;
	}
}

void onDie(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	
	if (isClient())
	{
		directionalSoundPlay("FlakExp"+XORRandom(2), pos, 2.0f);
		for (u8 i = 0; i < 3; i++)
			makeSmallExplosionParticle(pos + getRandomVelocity(90, 12, 360));
	}

	if (isServer()) 	
		flak(this);
}

f32 getDamage(CBlob@ hitBlob)
{
	if ( hitBlob.hasTag("rocket") )
		return 4.0f;
	if (hitBlob.hasTag("ram"))
		return 1.0f;
	if (hitBlob.hasTag("fakeram"))
		return 8.0f;
	if (hitBlob.hasTag("propeller"))
		return 0.5f;
	if (hitBlob.hasTag("antiram"))
		return 1.5f;
	if (hitBlob.hasTag("ramengine"))
		return 1.0f;
	if (hitBlob.hasTag("door"))
		return 1.0f;
	if (hitBlob.getName() == "shark" || hitBlob.getName() == "human")
		return 1.0f;
	if (hitBlob.hasTag("seat") || hitBlob.hasTag("weapon"))
		return 0.3f;
	if (hitBlob.hasTag("mothership") || hitBlob.hasTag("secondaryCore"))
		return 0.3f;
	if (hitBlob.hasTag("bomb"))
		return 4.0f;
	if (hitBlob.hasTag("decoycore"))
		return 0.3f;
	
	return 1.0f;
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (hitBlob.hasTag("block"))
	{
		Vec2f vel = worldPoint - hitBlob.getPosition();//todo: calculate real bounce angles?
		ShrapnelParticle( worldPoint, vel );
		directionalSoundPlay( "Ricochet" +  ( XORRandom(3) + 1 ) + ".ogg", worldPoint, 0.35f );
	}
}
