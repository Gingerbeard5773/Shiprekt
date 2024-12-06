#include "WeaponCommon.as";
#include "AccurateSoundPlay.as";
#include "ParticleSpark.as";

const f32 BULLET_SPEED = 3.0f;
const int FIRE_RATE = 200;

const u8 MAX_AMMO = 8;
const u8 REFILL_AMOUNT = 1;
const u8 REFILL_SECONDS = 8;

void onInit(CBlob@ this)
{
	this.Tag("weapon");
	this.Tag("usesAmmo");
	this.Tag("machinegun"); //for seat.as
	
	this.set_f32("weight", 4.5f);
	
	this.addCommandID("client_fire");

	if (isServer())
	{
		this.set_u16("ammo", MAX_AMMO);
		this.set_u16("maxAmmo", MAX_AMMO);
	}

	CSprite@ sprite = this.getSprite();
    sprite.SetRelativeZ(2);

	this.set_u32("fire time", 0);
	
	onFireHandle@ onfire_handle = @server_onFire;
	this.set("onFire handle", @onfire_handle);
}

void onTick(CBlob@ this)
{
	const int col = this.getShape().getVars().customData;
	if (col <= 0) return; //not placed yet

	if (isServer())
	{
		Ship@ ship = getShipSet().getShip(col);
		if (ship !is null)
		{
			checkDocked(this, ship);
			if (canFire(this))
				refillAmmo(this, ship, REFILL_AMOUNT, REFILL_SECONDS);
		}
	}
}

const bool canFire(CBlob@ this)
{
	return this.get_u32("fire time") + FIRE_RATE < getGameTime();
}

const bool isObstructed(CBlob@ this)
{
	Vec2f aimVector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());
	Vec2f barrelPos = this.getPosition() + aimVector * 5.0f;
	
	HitInfo@[] hitInfos;
	if (getMap().getHitInfosFromRay(barrelPos, -aimVector.Angle(), 60.0f, this, @hitInfos))
	{
		const u8 hitLength = hitInfos.length;
		for (u8 i = 0; i < hitLength; i++)
		{
			CBlob@ b =  hitInfos[i].blob;
			if (b is null || b is this) continue;

			if (this.getShape().getVars().customData == b.getShape().getVars().customData && 
			   (b.hasTag("weapon") || b.hasTag("door") ||(b.hasTag("solid") && !b.hasTag("plank")))) //same ship
			{
				return false;
			}
		}
	}

	return true;
}

void server_onFire(CBlob@ this, CBlob@ caller)
{
	if (!canFire(this) || this.get_bool("docked")) return;
	
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

		Vec2f aimvector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());
		const Vec2f barrelPos = this.getPosition() + aimvector * 9;
		shotParticles(barrelPos, aimvector.Angle(), false);
		directionalSoundPlay("LauncherFire" + (XORRandom(2) + 1), barrelPos);
	}
}

void server_FireBlob(CBlob@ this, CBlob@ caller)
{
	Vec2f aimvector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());
	CBlob@ bullet = server_CreateBlob("rocket", this.getTeamNum(), this.getPosition() + aimvector * 8.0f);
	if (bullet is null) return;
	
	Ship@ ship = getShipSet().getShip(this.getShape().getVars().customData);
	if (ship is null) return;
	
	Vec2f velocity = aimvector * BULLET_SPEED;

	bullet.SetDamageOwnerPlayer(caller.getPlayer());
	bullet.setVelocity(velocity + ship.vel);
	bullet.setAngleDegrees(-aimvector.Angle() + 90.0f);
	bullet.server_SetTimeToDie(25);
}
