#include "WeaponCommon.as";
#include "AccurateSoundPlay.as";
#include "ParticleSpark.as";

const f32 PROJECTILE_SPEED = 9.0f;
const f32 PROJECTILE_SPREAD = 2.25;
const int FIRE_RATE = 50;
const f32 PROJECTILE_RANGE = 100.0f;
const f32 AUTO_RADIUS = 100.0f;

const u8 MAX_AMMO = 15;
const u8 REFILL_AMOUNT = 1;
const u8 REFILL_SECONDS = 5;

void onInit(CBlob@ this)
{
	this.Tag("pointdefense");
	this.Tag("weapon");
	this.Tag("usesAmmo");
	this.Tag("solid");
	
	this.set_f32("weight", 3.5f);
	
	this.addCommandID("client_fire");

	if (isServer())
	{
		this.set_u16("ammo", MAX_AMMO);
		this.set_u16("maxAmmo", MAX_AMMO);
	}

	this.set_u32("fire time", 0);

	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ layer = sprite.addSpriteLayer("weapon", "PointDefense.png", 16, 16);
	if (layer !is null)
	{
		layer.SetRelativeZ(2);
		layer.SetLighting(false);
		Animation@ anim = layer.addAnimation("fire", 15, false);
		anim.AddFrame(1);
		anim.AddFrame(0);
		layer.SetAnimation("fire");
	}
}

void onTick(CBlob@ this)
{
	const int col = this.getShape().getVars().customData;
	if (col <= 0) return; //not placed yet

	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ laser = sprite.getSpriteLayer("laser");
	if (laser !is null && this.get_u32("fire time") + 5.0f < getGameTime())
		sprite.RemoveSpriteLayer("laser");

	if (this.get_u16("ammo") > 0)
		Auto(this);

	if (isServer())
	{
		Ship@ ship = getShipSet().getShip(col);
		if (ship !is null && canShootAuto(this))
			refillAmmo(this, ship, REFILL_AMOUNT, REFILL_SECONDS);
	}
}

void Auto(CBlob@ this)
{
	if ((getGameTime() + this.getNetworkID() * 33) % 5 != 0) return;

	const Vec2f pos = this.getPosition();
	f32 minDistance = 9999999.9f;
	CBlob@ hitBlob;

	CBlob@[] blobsInRadius;
	if (getMap().getBlobsInRadius(pos, AUTO_RADIUS, @blobsInRadius))
	{
		const u8 blobsLength = blobsInRadius.length;
		for (u8 i = 0; i < blobsLength; i++)
		{
			CBlob@ b = blobsInRadius[i];
			if (b.getTeamNum() != this.getTeamNum()
					&& (b.getName() == "human"|| b.hasTag("projectile")))
			{
				Vec2f bPos = b.getPosition();

				Vec2f aimVector = bPos - pos;
				f32 distance = aimVector.Length();

				if (b.getName() == "human")
					distance += 80.0f;//humans have lower priority

				if (distance < minDistance && !isObstructed(this, aimVector) && !getMap().rayCastSolid(bPos, pos))
				{
					minDistance = distance;
					@hitBlob = b;
				}
			}
		}
	}

	if (isServer() && hitBlob !is null && canShootAuto(this))
	{
		server_onFire(this, hitBlob);
	}
}

const bool canShootAuto(CBlob@ this)
{
	return this.get_u32("fire time") + FIRE_RATE < getGameTime();
}

const bool isObstructed(CBlob@ this, Vec2f&in aimVector)
{
	const f32 distanceToTarget = Maths::Max(aimVector.Length() - 8.0f, 0.0f);
	HitInfo@[] hitInfos;
	getMap().getHitInfosFromRay(this.getPosition(), -aimVector.Angle(), distanceToTarget, this, @hitInfos);
	
	const u8 hitLength = hitInfos.length;
	if (hitLength > 0)
	{
		for (u8 i = 0; i < hitLength; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;
			if (b is null || b is this) continue;

			if ((b.hasTag("weapon") || b.hasTag("solid") || (b.hasTag("door") && b.getShape().getConsts().collidable))
				&& b.getShape().getVars().customData > 0)
			{
				return true;
			}
		}
	}

	return false;
}

void server_onFire(CBlob@ this, CBlob@ hitBlob)
{
	u16 ammo = this.get_u16("ammo");
	this.set_u16("ammo", Maths::Max(0, ammo - 1));
	this.set_u32("fire time", getGameTime());
	
	if (ammo > 0)
	{
		this.server_Hit(hitBlob, hitBlob.getPosition(), Vec2f_zero, getDamage(hitBlob), 0, true);
	}

	CBitStream stream;
	stream.write_netid(hitBlob.getNetworkID());
	stream.write_u16(ammo);
	this.SendCommand(this.getCommandID("client_fire"), stream);
}

void Rotate(CBlob@ this, Vec2f&in aimVector)
{
	CSpriteLayer@ layer = this.getSprite().getSpriteLayer("weapon");
	if (layer !is null)
	{
		layer.ResetTransform();
		layer.RotateBy(-aimVector.Angle() - this.getAngleDegrees(), Vec2f_zero);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_fire") && isClient())
	{
		CBlob@ hitBlob = getBlobByNetworkID(params.read_netid());
		if (hitBlob is null) return;
		
		const u16 ammo = params.read_u16();
		this.set_u16("ammo", Maths::Max(0, ammo - 1));
		this.set_u32("fire time", getGameTime());

		Vec2f pos = this.getPosition();

		if (ammo <= 0)
		{
			directionalSoundPlay("LoadingTick1", pos, 1.0f);
			return;
		}
		
		Vec2f bPos = hitBlob.getPosition();
		Vec2f aimVector = bPos - pos;

		Rotate(this, aimVector);
		directionalSoundPlay("Laser1.ogg", pos, 1.0f);

		const Vec2f barrelPos = pos + Vec2f(1,0).RotateBy(aimVector.Angle()) * 8;
		CSprite@ sprite = this.getSprite();
		sprite.RemoveSpriteLayer("laser");
		CSpriteLayer@ laser = sprite.addSpriteLayer("laser", "Beam2.png", 16, 16);
		if (laser !is null) //partial length laser
		{
			Animation@ anim = laser.addAnimation("default", 1, false);
			int[] frames = { 0, 1, 2, 3, 4, 5 };
			anim.AddFrames(frames);
			laser.SetVisible(true);
			f32 laserLength = Maths::Max(0.1f, (bPos - barrelPos).getLength() / 16.0f);
			laser.ResetTransform();
			laser.ScaleBy(Vec2f(laserLength, 0.5f));
			laser.TranslateBy(Vec2f(laserLength*8.0f, 0.0f));
			laser.RotateBy(-this.getAngleDegrees() - aimVector.Angle(), Vec2f());
			laser.setRenderStyle(RenderStyle::light);
			laser.SetRelativeZ(1);
		}

		if (hitBlob.hasTag("projectile"))
		{
			sparks(bPos, 4);
		}

		CSpriteLayer@ layer = this.getSprite().getSpriteLayer("weapon");
		if (layer !is null)
			layer.animation.SetFrameIndex(0);
    }
}

const f32 getDamage(CBlob@ hitBlob)
{
	if (hitBlob.hasTag("rocket"))
		return 0.5f;
	if (hitBlob.hasTag("projectile"))
		return 1.0f;

	return 0.01f;//cores, solids
}
