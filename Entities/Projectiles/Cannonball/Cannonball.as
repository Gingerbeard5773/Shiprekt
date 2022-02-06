#include "WaterEffects.as";
#include "IslandsCommon.as";
#include "Booty.as";
#include "AccurateSoundPlay.as";
#include "TileCommon.as";
#include "ParticleSparks.as";
#include "Hitters.as";

const f32 SPLASH_RADIUS = 8.0f;
const f32 SPLASH_DAMAGE = 0.0f;
const f32 MAX_PIERCED = 2;

void onInit(CBlob@ this)
{
	this.Tag("cannonball");
	this.Tag("projectile");

	ShapeConsts@ consts = this.getShape().getConsts();
    consts.mapCollisions = false; // we have our own map collision
	consts.bullet = true;	
	
	this.set_u16("pierced count", 0);
    u32[] piercedBlobIDs;
    this.set("pierced blob IDs", piercedBlobIDs);

	this.getSprite().SetZ(550.0f);	
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;

	Vec2f pos = this.getPosition();
	
	if (isTouchingRock(pos))
	{
		this.server_Die();
		sparks(pos, v_fastrender ? 5 : 15, 2.5f, 20);
		directionalSoundPlay("MetalImpact" + (XORRandom(2) + 1), pos);
	}
}

void onCollision(CBlob@ this, CBlob@ b, bool solid, Vec2f normal, Vec2f point1)
{
	if (b is null || b is this) return;

	if (!isServer()) return;
	
	int piercedCount = this.get_u16("pierced count");
    u32[]@ piercedBlobIDs;
    this.get("pierced blob IDs", @piercedBlobIDs);
	bool killed = false;
	
	u32 bID = b.getNetworkID();
	
	if (piercedBlobIDs.find(bID) >= 0) return;

	const int color = b.getShape().getVars().customData;
	const bool isBlock = b.hasTag("block");
	const bool sameTeam = b.getTeamNum() == this.getTeamNum();
	if (color > 0 || !isBlock)
	{
		if (isBlock)
		{
			if (b.hasTag("solid") || b.hasTag("door") || ((b.hasTag("core") || b.hasTag("weapon")) && !sameTeam))
			{
				if (piercedCount >= MAX_PIERCED)
					killed = true;
				else
				{
					this.push("pierced blob IDs", bID);
					piercedCount++;
					this.setVelocity(this.getVelocity() * 0.5f);
				}
			}
			else if (b.hasTag("seat"))
			{
				AttachmentPoint@ seat = b.getAttachmentPoint(0);
				CBlob@ occupier = seat.getOccupied();
				if (occupier !is null && occupier.getName() == "human" && occupier.getTeamNum() != this.getTeamNum())
				{
					if (piercedCount >= MAX_PIERCED)
						killed = true;
					else
					{
						this.push("pierced blob IDs", bID);
						piercedCount++;
						this.setVelocity(this.getVelocity() * 0.5f);
					}
				}
				else return;
			}
			else return;
		}
		else
		{
			if (sameTeam || (b.hasTag("player") && b.isAttached()) || b.hasTag("projectile"))//don't hit
				return;
		}
		
		this.set_u16("pierced count", piercedCount);
		
		CPlayer@ owner = this.getDamageOwnerPlayer();
		if (owner !is null)
		{
			CBlob@ blob = owner.getBlob();
			if (blob !is null) damageBooty(owner, blob, b, b.hasTag("solid"), 4);
		}
		
		this.server_Hit(b, point1, Vec2f_zero, getDamage(this, b), Hitters::ballista, true);
		
		if (killed) 
		{
			this.server_Die(); 
			return;
		}
	}
}

f32 getDamage(CBlob@ this, CBlob@ hitBlob)
{
	int piercedCount = this.get_u16("pierced count");
	f32 damageFactor = 1.0f;
	
	if (piercedCount > 1)
		damageFactor *= 0.7f;
	if (piercedCount > 2)
		damageFactor *= 0.5f;
	
	if (hitBlob.hasTag("antiram"))
		return 10.0f * damageFactor;
	if (hitBlob.hasTag("ramengine"))
		return 4.3f * damageFactor;
	if (hitBlob.hasTag("propeller"))
		return 2.15f * damageFactor;
	if (hitBlob.hasTag("door"))
		return 5.0f * damageFactor;
	if (hitBlob.hasTag("seat"))
		return 1.0f * damageFactor;
	if (hitBlob.hasTag("decoyCore"))
		return 1.75f * damageFactor;
	if (hitBlob.hasTag("weapon"))
		return 1.75f * damageFactor;
	if (hitBlob.getName() == "shark" || hitBlob.getName() == "human")
		return 0.75f * damageFactor;

	return 0.7f *damageFactor;
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{	
	if (customData == 9 || damage <= 0.0f) return;

	if (hitBlob.hasTag("solid") || hitBlob.hasTag("core") || hitBlob.hasTag("door") || hitBlob.hasTag("seat") || hitBlob.hasTag("weapon"))
	{
		sparksDirectional(worldPoint + this.getVelocity(), this.getVelocity(), v_fastrender ? 4 : 7);
		directionalSoundPlay("Pierce1.ogg", worldPoint);
			
		if (hitBlob.hasTag("mothership"))
			directionalSoundPlay("Entities/Characters/Knight/ShieldHit.ogg", worldPoint);
	}
}

void onDie(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	
	if (!isInWater(pos))
	{
		sparks(pos + this.getVelocity(), v_fastrender ? 5 : 15, 2.5, 20);
		directionalSoundPlay("MetalImpact" + (XORRandom(2) + 1), pos);
	}
	else if (this.getTouchingCount() <= 0)
	{
		MakeWaterParticle(pos, Vec2f_zero);
		directionalSoundPlay("WaterSplashBall.ogg", pos);
	}
		
	if (!isServer()) return;
		
	//splash damage
	CBlob@[] blobsInRadius;
	if (getMap().getBlobsInRadius(pos, SPLASH_RADIUS, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (!b.hasTag("hasSeat") && b.hasTag("block") && b.getShape().getVars().customData > 0)
				this.server_Hit(b, Vec2f_zero, Vec2f_zero, SPLASH_DAMAGE, 9, false);
		}
	}
}

void sparksDirectional(Vec2f pos, Vec2f blobVel, int amount)
{
	Random _sprk_r;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 5.0f, 0);
        vel.RotateBy((-blobVel.getAngle() + 180.0f) + _sprk_r.NextFloat() * 30.0f - 15.0f);

        CParticle@ p = ParticlePixel(pos, vel, SColor( 255, 255, 128+_sprk_r.NextRanged(128), _sprk_r.NextRanged(128)), true);
        if (p is null) return; //bail if we stop getting particles

        p.timeout = 20 + _sprk_r.NextRanged(20);
        p.scale = 1.0f + _sprk_r.NextFloat();
        p.damping = 0.85f;
		p.Z = 550.0f;
    }
}
