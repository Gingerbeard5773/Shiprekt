#include "WeaponCommon.as";
#include "AccurateSoundPlay.as";
#include "ParticleSpark.as";

const f32 PROJECTILE_RANGE = 375.0F;
const f32 PROJECTILE_SPEED = 15.0f;;
const u16 FIRE_RATE = 170;//max wait between shots

const u8 MAX_AMMO = 10;
const u8 REFILL_AMOUNT = 1;
const u8 REFILL_SECONDS = 5;

void onInit(CBlob@ this)
{
	this.Tag("weapon");
	this.Tag("cannon");
	this.Tag("usesAmmo");
	this.Tag("fixed_gun");
	
	this.set_f32("weight", 3.25f);
	
	this.addCommandID("client_fire");

	if (isServer())
	{
		this.set_u16("ammo", MAX_AMMO);
		this.set_u16("maxAmmo", MAX_AMMO);
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
	
	onFireHandle@ onfire_handle = @server_onFire;
	this.set("onFire handle", @onfire_handle);
}

void onTick(CBlob@ this)
{
	const int col = this.getShape().getVars().customData;
	if (col <= 0) return; //not placed yet

	const u32 gameTime = getGameTime();

	//fire ready
	const u32 fireTime = this.get_u32("fire time");
	this.set_bool("fire ready", (gameTime > fireTime + FIRE_RATE));
	
	if (isClient())
	{
		//sprite ready
		if (fireTime + FIRE_RATE - 15 == gameTime)
		{
			this.getSprite().animation.SetFrameIndex(0);
			directionalSoundPlay("Charging.ogg", this.getPosition(), 2.0f);
		}
	}

	if (isServer())
	{
		Ship@ ship = getShipSet().getShip(col);
		if (ship !is null)
		{
			checkDocked(this, ship);
			if (this.get_bool("fire ready"))
				refillAmmo(this, ship, REFILL_AMOUNT, REFILL_SECONDS);
		}
	}
}

bool isObstructed(CBlob@ this)
{
	Vec2f aimVector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());

	HitInfo@[] hitInfos;
	getMap().getHitInfosFromRay(this.getPosition(), -aimVector.Angle(), 60.0f, this, @hitInfos);
	const u8 hitLength = hitInfos.length;
	for (u8 i = 0; i < hitLength; i++)
	{
		CBlob@ b = hitInfos[i].blob;
		if (b is null || b is this) continue;

		if (this.getShape().getVars().customData == b.getShape().getVars().customData && (b.hasTag("weapon") || (b.hasTag("solid") && !b.hasTag("plank")))) //same ship
		{
			return false;
		}
	}

	return true;
}

void server_onFire(CBlob@ this, CBlob@ caller)
{
	if (!this.get_bool("fire ready") || this.get_bool("docked")) return;
	
	const Vec2f pos = this.getPosition();
	const bool obstructed = isObstructed(this);
	
	const u16 ammo = this.get_u16("ammo");
	this.set_u16("ammo", Maths::Max(0, ammo - 1));
	this.set_u32("fire time", getGameTime());
	
	if (ammo > 0 && obstructed)
	{
		server_FireBlob(this, caller);
	}
	
	CBitStream params;
	params.write_bool(obstructed);
	params.write_u16(ammo);
	this.SendCommand(this.getCommandID("client_fire"), params);	
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_fire") && isClient())
	{
		const bool obstructed = params.read_bool();
		const u16 ammo = params.read_u16();

		this.set_u16("ammo", Maths::Max(0, ammo - 1));
		this.set_u32("fire time", getGameTime());

		Vec2f pos = this.getPosition();
		if (!obstructed)
		{
			directionalSoundPlay("lightup", pos);
			return;
		}

		if (ammo <= 0)
		{
			directionalSoundPlay("LoadingTick1", pos, 1.0f);
			return;
		}

		Vec2f aimVector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());
		this.getSprite().animation.SetFrameIndex(1);
		shotParticles(pos + aimVector * 9, aimVector.Angle());
		directionalSoundPlay("CannonFire.ogg", pos, 7.0f);
	}
}

void server_FireBlob(CBlob@ this, CBlob@ caller)
{
	Vec2f pos = this.getPosition();
	Vec2f aimVector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());

	CBlob@ bullet = server_CreateBlob("cannonball", this.getTeamNum(), pos + aimVector * 4);
	if (bullet is null) return;

	Ship@ ship = getShipSet().getShip(this.getShape().getVars().customData);
	if (ship is null) return;

	Random rand(bullet.getNetworkID());
	const f32 variation = 0.9f + rand.NextFloat() / 5.0f;
	const f32 lifetime = 0.05f + variation * PROJECTILE_RANGE / PROJECTILE_SPEED / 32.0f;
	Vec2f vel = aimVector * PROJECTILE_SPEED;
	vel += ship.vel;

	bullet.SetDamageOwnerPlayer(caller.getPlayer());
	bullet.setVelocity(vel);
	bullet.server_SetTimeToDie(lifetime);
}
