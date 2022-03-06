#include "WeaponCommon.as";
#include "AccurateSoundPlay.as";
#include "ParticleSparks.as";

const f32 PROJECTILE_RANGE = 375.0F;
const f32 PROJECTILE_SPEED = 15.0f;;
const u16 FIRE_RATE = 170;//max wait between shots

// Max amount of ammunition
const uint8 MAX_AMMO = 12;

// Amount of ammunition to refill when
// connected to motherships and stations
const uint8 REFILL_AMOUNT = 3;

// How often to refill when connected
// to motherships and stations
const uint8 REFILL_SECONDS = 2;

// How often to refill when connected
// to secondary cores
const uint8 REFILL_SECONDARY_CORE_SECONDS = 12;

// Amount of ammunition to refill when
// connected to secondary cores
const uint8 REFILL_SECONDARY_CORE_AMOUNT = 1;

Random _shotrandom(0x15125); //clientside

void onInit(CBlob@ this)
{
	this.Tag("weapon");
	this.Tag("cannon");
	this.Tag("usesAmmo");
	this.Tag("fixed_gun");
	
	this.set_f32("weight", 3.25f);
	
	this.addCommandID("fire");

	if (isServer())
	{
		this.set_u16("ammo", MAX_AMMO);
		this.set_u16("maxAmmo", MAX_AMMO);
		this.Sync("ammo", true);
		this.Sync("maxAmmo", true);
	}

	CSprite@ sprite = this.getSprite();
    sprite.SetRelativeZ(2);
	{
		//shoot anim
     	Animation@ anim = sprite.addAnimation("fire", 0, false);
        anim.AddFrame(0);
        anim.AddFrame(1);
        sprite.SetAnimation("fire");
	}
	this.set_u32("fire time", 0);
}

void onTick(CBlob@ this)
{
	if (this.getShape().getVars().customData <= 0)
		return;

	u32 gameTime = getGameTime();

	//fire ready
	u32 fireTime = this.get_u32("fire time");
	this.set_bool("fire ready", (gameTime > fireTime + FIRE_RATE));
	//sprite ready
	if (fireTime + FIRE_RATE - 15 == gameTime)
	{
		this.getSprite().animation.SetFrameIndex(0);

		directionalSoundPlay("Charging.ogg", this.getPosition(), 2.0f);
	}

	if (isServer())
	{
		refillAmmo(this, REFILL_AMOUNT, REFILL_SECONDS, REFILL_SECONDARY_CORE_AMOUNT, REFILL_SECONDARY_CORE_SECONDS);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("fire"))
	{
		if (!this.get_bool("fire ready")) return;

		Vec2f pos = this.getPosition();

		this.set_u32("fire time", getGameTime());

		if (!isClear(this))
		{
			directionalSoundPlay("lightup", pos);
			return;
		}

		//ammo
		u16 ammo = this.get_u16("ammo");

		if (ammo <= 0)
		{
			directionalSoundPlay("LoadingTick1", pos, 1.0f);
			return;
		}

		ammo--;
		this.set_u16("ammo", ammo);

		u16 shooterID;
		if (!params.saferead_u16(shooterID))
			return;

		CBlob@ shooter = getBlobByNetworkID(shooterID);
		if (shooter is null)
			return;

		Fire(this, shooter);

		this.getSprite().animation.SetFrameIndex(1);
	}
}

void Fire(CBlob@ this, CBlob@ shooter)
{
	Vec2f pos = this.getPosition();
	Vec2f aimVector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());

	if (isServer())
	{
		f32 variation = 0.9f + _shotrandom.NextFloat()/5.0f;
		f32 _lifetime = 0.05f + variation*PROJECTILE_RANGE/PROJECTILE_SPEED/32.0f;

		CBlob@ cannonball = server_CreateBlob("cannonball", this.getTeamNum(), pos + aimVector*4);
		if (cannonball !is null)
		{
			Vec2f vel = aimVector * PROJECTILE_SPEED;

			Ship@ ship = getShip(this.getShape().getVars().customData);
			if (ship !is null)
			{
				vel += ship.vel;

				if (shooter !is null)
				{
					CPlayer@ attacker = shooter.getPlayer();
					if (attacker !is null)
						cannonball.SetDamageOwnerPlayer(attacker);
				}

				cannonball.setVelocity(vel);
				cannonball.server_SetTimeToDie(_lifetime);
			}
		}
	}

	this.getSprite().animation.SetFrameIndex(0);

	shotParticles(pos + aimVector*9, aimVector.Angle());

	directionalSoundPlay("CannonFire.ogg", pos, 7.0f);
}

bool isClear(CBlob@ this)
{
	Vec2f aimVector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());

	HitInfo@[] hitInfos;
	if (getMap().getHitInfosFromRay(this.getPosition(), -aimVector.Angle(), 60.0f, this, @hitInfos))
	{
		for (uint i = 0; i < hitInfos.length; i++)
		{
			CBlob@ b =  hitInfos[i].blob;
			if (b is null || b is this) continue;

			if (this.getShape().getVars().customData == b.getShape().getVars().customData && (b.hasTag("weapon") || b.hasTag("solid"))) //same ship
			{
				return false;
			}
		}
	}

	return true;
}
