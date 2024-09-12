#include "WeaponCommon.as";
#include "DamageBooty.as";
#include "AccurateSoundPlay.as";
#include "ParticleSpark.as";
#include "GunCommon.as";

const int FIRE_RATE = 4;

const u8 MAX_AMMO = 160;
const u8 REFILL_AMOUNT = 30;
const u8 REFILL_SECONDS = 5;

BootyRewards@ booty_reward;

void onInit(CBlob@ this)
{
	if (booty_reward is null)
	{
		BootyRewards _booty_reward;
		_booty_reward.addTagReward("bomb", 2);
		_booty_reward.addTagReward("engine", 2);
		_booty_reward.addTagReward("weapon", 1);
		@booty_reward = _booty_reward;
	}

	this.Tag("heavy machinegun");
	this.Tag("weapon");
	this.Tag("usesAmmo");
	
	this.Tag("noEnemyEntry");
	this.set_string("seat label", "Control Machinegun");
	this.set_u8("seat icon", 7);
	
	this.set_u8("TTL", 20);
	this.set_u8("speed", 20);
	
	this.set_f32("weight", 3.0f);
	
	this.addCommandID("client_fire");
	this.set_u8("barrel", 0);

	if (isServer())
	{
		this.set_u16("ammo", MAX_AMMO);
		this.set_u16("maxAmmo", MAX_AMMO);
	}

	this.set_u32("fire time", 0);

	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ layer = sprite.addSpriteLayer("weapon", "HeavyMachinegun.png", 21, 13);
	if (layer !is null)
	{
		layer.SetRelativeZ(2);
    	layer.SetLighting(false);
		layer.SetOffset(Vec2f(-4, 0));
		Animation@ anim = layer.addAnimation("fire left", Maths::Round(FIRE_RATE), false);
		anim.AddFrame(2);
		anim.AddFrame(0);

		Animation@ anim2 = layer.addAnimation("fire right", Maths::Round(FIRE_RATE), false);
		anim2.AddFrame(1);
		anim2.AddFrame(0);
	}
}

void onTick(CBlob@ this)
{
	const int col = this.getShape().getVars().customData;
	if (col <= 0) return; //not placed yet

	AttachmentPoint@ seat = this.getAttachmentPoint(0);
	CBlob@ occupier = seat.getOccupied();
	if (occupier !is null)
	{
		Manual(this, occupier);
	}

	if (isServer())
	{
		Ship@ ship = getShipSet().getShip(col);
		if (ship !is null && canShoot(this))
			refillAmmo(this, ship, REFILL_AMOUNT, REFILL_SECONDS);
	}
}

void Manual(CBlob@ this, CBlob@ caller)
{
	Vec2f aimVector = caller.getAimPos() - this.getPosition();

	// fire
	if (isServer() && caller.isKeyPressed(key_action1) && !isObstructed(this, aimVector))
	{
		server_onFire(this, caller, aimVector);
	}

	// rotate turret
	Rotate(this, aimVector);
	aimVector.y *= -1;
	caller.setAngleDegrees(aimVector.Angle());
}

void Rotate(CBlob@ this, Vec2f&in aimVector)
{
	CSpriteLayer@ layer = this.getSprite().getSpriteLayer("weapon");
	if (layer !is null)
	{
		layer.ResetTransform();
		layer.RotateBy(-aimVector.getAngleDegrees() - this.getAngleDegrees(), -layer.getOffset());
	}
}

bool canShoot(CBlob@ this)
{
	return this.get_u32("fire time") + FIRE_RATE < getGameTime();
}

const bool isObstructed(CBlob@ this, Vec2f&in aimVector)
{
	Vec2f pos = this.getPosition();
	const f32 distanceToTarget = 80.0f;
	CMap@ map = getMap();

	Vec2f barrel_one = Vec2f(11.8f, -2.0).RotateBy(-aimVector.Angle());
	Vec2f barrel_two = Vec2f(11.8f, 2.0).RotateBy(-aimVector.Angle());

	HitInfo@[] hitInfos;
	map.getHitInfosFromRay(pos + barrel_one, -aimVector.Angle(), distanceToTarget, this, @hitInfos);
	map.getHitInfosFromRay(pos + barrel_two, -aimVector.Angle(), distanceToTarget, this, @hitInfos);
	
	const u8 hitLength = hitInfos.length;
	if (hitLength > 0)
	{
		//HitInfo objects are sorted, first come closest hits
		for (u8 i = 0; i < hitLength; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;
			if (b is null || b is this) continue;
			
			const bool sameShip = this.getShape().getVars().customData == b.getShape().getVars().customData;
			if (b.hasTag("block") && b.getShape().getVars().customData > 0 && ((b.hasTag("solid") && !b.hasTag("plank")) || b.hasTag("weapon")) && sameShip)
			{
				return true;
			}
		}
	}

	return false;
}

void server_onFire(CBlob@ this, CBlob@ caller, Vec2f&in aimVector)
{
	if (!canShoot(this)) return;
	
	this.SetDamageOwnerPlayer(caller.getPlayer());
	
	const u16 ammo = this.get_u16("ammo");
	this.set_u16("ammo", Maths::Max(0, ammo - 1));
	this.set_u32("fire time", getGameTime());
	
	Vec2f barrelOffset;
	const u8 barrel = this.get_u8("barrel");
	if (barrel == 0)
	{
		barrelOffset = Vec2f(14, -2.0).RotateBy(-aimVector.Angle());
		this.set_u8("barrel", 1);
	}
	else
	{
		barrelOffset = Vec2f(14, 2.0).RotateBy(-aimVector.Angle());
		this.set_u8("barrel", 0);
	}
	
	if (ammo > 0)
	{
		server_FireBullet(this, -aimVector.Angle(), this.getPosition() + barrelOffset); //make bullets!
	}
	
	CBitStream params;
	params.write_netid(caller.getNetworkID());
	params.write_u16(ammo);
	params.write_u8(barrel);
	params.write_Vec2f(aimVector);
	this.SendCommand(this.getCommandID("client_fire"), params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_fire") && isClient())
	{
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		const u16 ammo = params.read_u16();
		const u8 barrel = params.read_u8();
		Vec2f aimVector = params.read_Vec2f();
		
		if (caller !is null)
			this.SetDamageOwnerPlayer(caller.getPlayer());

		this.set_u16("ammo", Maths::Max(0, ammo - 1));
		this.set_u32("fire time", getGameTime());
		
		Vec2f pos = this.getPosition();
		
		if (ammo <= 0)
		{
			directionalSoundPlay("LoadingTick1", pos, 1.0f);
			return;
		}
		
		Vec2f barrelOffset = Vec2f(14, barrel == 0 ? -2.0 : 2.0).RotateBy(-aimVector.Angle());
		Vec2f barrelPos = pos + barrelOffset;
		
		CSpriteLayer@ layer = this.getSprite().getSpriteLayer("weapon");
		if (layer !is null)
		{
			const string fire_anim = barrel == 1 ? "fire left" : "fire right";
			layer.SetAnimation(fire_anim);
		}

		Rotate(this, aimVector);
		shotParticles(barrelPos, aimVector.Angle(), false);
		directionalSoundPlay("AutoFire", barrelPos);
	}
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (damage <= 0.0f) return;
	
	if (isServer())
	{
		server_rewardBooty(this.getDamageOwnerPlayer(), hitBlob, booty_reward, "Pinball_"+XORRandom(4));

		if (hitBlob.hasTag("engine") && hitBlob.getTeamNum() != this.getTeamNum() && XORRandom(3) == 0)
			hitBlob.set_f32("power", 0.0f); //force turn off
	}
}
