#include "WeaponCommon.as";
#include "DamageBooty.as";
#include "AccurateSoundPlay.as";
#include "ParticleSpark.as";
#include "PlankCommon.as";
#include "GunCommon.as";

const f32 MIN_FIRE_PAUSE = 2.85f; //min wait between shots
const f32 MAX_FIRE_PAUSE = 8.0f; //max wait between shots
const f32 FIRE_PAUSE_RATE = 0.08f; //higher values = higher recover

const u8 MAX_AMMO = 250;
const u8 REFILL_AMOUNT = 30;
const u8 REFILL_SECONDS = 6;

BootyRewards@ booty_reward;

void onInit(CBlob@ this)
{
	if (booty_reward is null)
	{
		BootyRewards _booty_reward;
		_booty_reward.addTagReward("bomb", 1);
		_booty_reward.addTagReward("engine", 1);
		@booty_reward = _booty_reward;
	}
	
	this.Tag("weapon");
	this.Tag("machinegun");
	this.Tag("usesAmmo");
	this.Tag("fixed_gun");
	
	this.set_u8("TTL", 14);
	this.set_u8("speed", 25);
	
	this.set_f32("weight", 2.0f);
	
	this.addCommandID("client_fire");
	this.set_u8("barrel", 0);

	if (isServer())
	{
		this.set_u16("ammo", MAX_AMMO);
		this.set_u16("maxAmmo", MAX_AMMO);
		this.set_f32("fire pause", MIN_FIRE_PAUSE);
	}

	CSprite@ sprite = this.getSprite();
	{
		sprite.SetRelativeZ(2);
		Animation@ anim = sprite.addAnimation("fire left", Maths::Round(MIN_FIRE_PAUSE), false);
		anim.AddFrame(2);
		anim.AddFrame(0);

		Animation@ anim2 = sprite.addAnimation("fire right", Maths::Round(MIN_FIRE_PAUSE), false);
		anim2.AddFrame(1);
		anim2.AddFrame(0);
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
	const f32 currentFirePause = this.get_f32("fire pause");
	if (currentFirePause > MIN_FIRE_PAUSE)
		this.set_f32("fire pause", currentFirePause - FIRE_PAUSE_RATE * this.getCurrentScript().tickFrequency);

	if (isServer())
	{
		Ship@ ship = getShipSet().getShip(col);
		if (ship !is null)
		{
			checkDocked(this, ship);
			if (canShoot(this))
				refillAmmo(this, ship, REFILL_AMOUNT, REFILL_SECONDS);
		}
	}
}

const bool canShoot(CBlob@ this)
{
	return (this.get_u32("fire time") + this.get_f32("fire pause") < getGameTime());
}

void server_onFire(CBlob@ this, CBlob@ caller)
{
	if (!canShoot(this) || this.get_bool("docked")) return;
	
	Ship@ ship = getShipSet().getShip(this.getShape().getVars().customData);
	if (ship is null) return;

	f32 currentFirePause = this.get_f32("fire pause");
	if (currentFirePause < MAX_FIRE_PAUSE)
	{
		currentFirePause += Maths::Sqrt(currentFirePause * (ship.isMothership ? 1.1 : 1.0f) * FIRE_PAUSE_RATE);
		this.set_f32("fire pause", currentFirePause);
	}
	
	const u16 ammo = this.get_u16("ammo");
	this.set_u16("ammo", Maths::Max(0, ammo - 1));
	this.set_u32("fire time", getGameTime());

	this.SetDamageOwnerPlayer(caller.getPlayer());

	Vec2f aimVector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());
	Vec2f barrelOffset;
	const u8 barrel = this.get_u8("barrel");
	if (barrel == 0)
	{
		barrelOffset = Vec2f(0, -2.0).RotateBy(-aimVector.Angle());
		this.set_u8("barrel", 1);
	}
	else
	{
		barrelOffset = Vec2f(0, 2.0).RotateBy(-aimVector.Angle());
		this.set_u8("barrel", 0);
	}
	
	Vec2f barrelPos = this.getPosition() + aimVector * 9 + barrelOffset;
	const bool obstructed = isObstructed(this, barrelPos, aimVector);

	if (ammo > 0 && !obstructed)
	{
		server_FireBullet(this, -aimVector.Angle(), barrelPos); //make bullets!
	}
	
	CBitStream params;
	params.write_bool(obstructed);
	params.write_u16(ammo);
	params.write_u8(barrel);
	this.SendCommand(this.getCommandID("client_fire"), params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_fire") && isClient())
	{
		const bool obstructed = params.read_bool();
		const u16 ammo = params.read_u16();
		const u8 barrel = params.read_u8();

		this.set_u16("ammo", Maths::Max(0, ammo - 1));
		this.set_u32("fire time", getGameTime());

		Vec2f pos = this.getPosition();
		if (obstructed)
		{
			directionalSoundPlay("lightup", pos);
			return;
		}

		if (ammo <= 0)
		{
			directionalSoundPlay("LoadingTick1", pos, 1.0f);
			return;
		}
		
		//effects
		CSprite@ sprite = this.getSprite();

		Vec2f aimVector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());
		Vec2f barrelOffset = Vec2f(0, barrel == 0 ? -2.0 : 2.0).RotateBy(-aimVector.Angle());
		Vec2f barrelPos = pos + aimVector * 9 + barrelOffset;

		shotParticles(barrelPos, aimVector.Angle(), false);
		directionalSoundPlay("Gunshot" + (XORRandom(2) + 2), barrelPos, 1.8f);
		
		const string fire_anim = barrel == 1 ? "fire left" : "fire right";
		sprite.SetAnimation(fire_anim);
	}
}

bool isObstructed(CBlob@ this, Vec2f&in barrelPos, Vec2f&in aimVector)
{
	HitInfo@[] hitInfos;
	if (getMap().getHitInfosFromRay(barrelPos, -aimVector.Angle(), 100.0f, this, @hitInfos))
	{
		const u8 hitLength = hitInfos.length;
		for (u8 i = 0; i < hitLength; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;
			if (b is null || (b.hasTag("plank") && !CollidesWithPlank(b, aimVector))) continue;
			
			const bool sameShip = b.getShape().getVars().customData == this.getShape().getVars().customData;
			if (sameShip && (b.hasTag("weapon") || b.getShape().getConsts().collidable) && b.getTeamNum() == this.getTeamNum())
				return true;
		}
	}
	return false;
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (damage <= 0.0f) return;

	CPlayer@ player = this.getDamageOwnerPlayer();
	if (player !is null)
		rewardBooty(player, hitBlob, booty_reward, "Pinball_"+XORRandom(4));
	
	if (isServer())
	{
		if (hitBlob.hasTag("engine") && hitBlob.getTeamNum() != this.getTeamNum() && XORRandom(3) == 0)
			hitBlob.SendCommand(hitBlob.getCommandID("off")); //force turn off
	}
}
