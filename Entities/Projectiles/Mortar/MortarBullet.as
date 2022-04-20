#include "ExplosionEffects.as";;
#include "AccurateSoundPlay.as";
#include "ParticleSparks.as";
#include "Hitters.as";
#include "PlankCommon.as";

const f32 EXPLODE_RADIUS = 4.0f;
const f32 MORTAR_REACH = 50.0f;
const f32 SHELL_BASE_DAMAGE = 1.0f;

void onInit(CBlob@ this)
{
	this.Tag("mortar shell");
	this.Tag("projectile");

	this.set_f32("scale", 1.0);

	ShapeConsts@ consts = this.getShape().getConsts();
    consts.mapCollisions = false;
	consts.bullet = true;	

	this.getSprite().SetZ(550.0f);
	
	//shake screen (onInit accounts for firing latency)
	CPlayer@ localPlayer = getLocalPlayer();
	if (localPlayer !is null && localPlayer is this.getDamageOwnerPlayer())
		ShakeScreen(4, 4, this.getPosition());

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.ScaleBy(Vec2f(0.4, 0.4));
	}

	this.set_bool("left", false);
	if (XORRandom(2) == 0)
	{
		this.set_bool("left", true);
	}
}

void onTick(CBlob@ this)
{
	f32 time = this.get_f32("timeScaling");
	f32 timesince = this.getTickSinceCreated();
    f32 res;
    if (time > 0) res = (100*timesince/time) / 45; // scaling from 0 to 75
	//printf(""+res);
	f32 scale = (100.0 - res*1.0)*0.0004;
	//printf(""+scale);

	CSprite@ sprite = this.getSprite();
	if (!this.get_bool("left")) sprite.RotateByDegrees(10, Vec2f(0,0));
	else sprite.RotateByDegrees(-10, Vec2f(0,0));
	if (sprite !is null)
	{
		if (res < 20) 
		{
			sprite.ScaleBy(Vec2f(1.0f+scale, 1.0f+scale));
		}
		else if (res > 25)
		{
			sprite.ScaleBy(Vec2f(1.0f-0.025, 1.0f-0.025));
		}
	}
}

void mortar(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	CMap@ map = getMap();
	CBlob@[] blobs;
	map.getBlobsInRadius(pos, MORTAR_REACH, @blobs);
	
	if (blobs.length < 2)
		return;
		
	f32 angle = XORRandom(360);

	for (u8 s = 0; s < 12; s++)
	{
		HitInfo@[] hitInfos;
		if (map.getHitInfosFromRay(pos, angle, MORTAR_REACH, this, @hitInfos))
		{
			for (uint i = 0; i < hitInfos.length; i++)//sharpnel trail
			{
				CBlob@ b = hitInfos[i].blob;	  
				if (b is null || b is this) continue;
									
				const bool sameTeam = b.getTeamNum() == this.getTeamNum();
				if (b.hasTag("solid") || b.hasTag("door") || (!sameTeam
					&& (b.hasTag("seat") || b.hasTag("weapon") || b.hasTag("projectile") || b.hasTag("core") || b.hasTag("bomb") || (b.hasTag("player") && !b.isAttached()))))
				{
					this.server_Hit(b, hitInfos[i].hitpos, Vec2f_zero, getDamage(b), Hitters::bomb, true);
					break;
				}
			}
		}
		
		angle = (angle + 30.0f) % 360;
	}
}

void onDie(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	
	if (isClient())
	{
		directionalSoundPlay("FlakExp"+XORRandom(2), pos, 2.5f);
		for (u8 i = 0; i < (v_fastrender ? 1 : 3); i++)
		{
			makeLargeExplosionParticle(pos + getRandomVelocity(90, 12, 360));
		}
	}

	if (isServer() && !this.hasTag("noMortarBoom")) 	
		mortar(this);

	if (this.getShape().getVars().customData > 0)
    {
        this.getSprite().Gib();
		if (!this.hasTag("disabled"))
			Explode(this);
    }
}

void Explode(CBlob@ this, f32 radius = EXPLODE_RADIUS)
{
    Vec2f pos = this.getPosition();

	directionalSoundPlay("Bomb.ogg", pos);
    makeLargeExplosionParticle(pos);
    ShakeScreen(4*radius, 45, pos);

	//hit blobs
	CBlob@[] blobs;
	getMap().getBlobsInRadius(pos, radius, @blobs);

	for (uint i = 0; i < blobs.length; i++)
	{
		CBlob@ hit_blob = blobs[i];
		if (hit_blob is this)
			continue;

		if (isServer())
		{
			Vec2f hit_blob_pos = hit_blob.getPosition();  

			if (hit_blob.hasTag("block"))
			{
				if (hit_blob.getShape().getVars().customData <= 0)
					continue;
			}
		
			f32 damageFactor = (hit_blob.hasTag("mothership") || hit_blob.hasTag("player")) ? 0.15f : 0.5f;

			//hit the object
			this.server_Hit(hit_blob, hit_blob_pos, Vec2f_zero, getDamage(hit_blob), Hitters::explosion, true);
		}
	}
}

f32 getDamage(CBlob@ hitBlob)
{
	if (hitBlob.hasTag("door"))
		return 0.75f;
	if (hitBlob.getName() == "shark" || hitBlob.getName() == "human")
		return 0.25f;
	if (hitBlob.hasTag("seat") || hitBlob.hasTag("weapon") || hitBlob.hasTag("bomb") || hitBlob.hasTag("core"))
		return 0.15f;
	return 0.5f;
}