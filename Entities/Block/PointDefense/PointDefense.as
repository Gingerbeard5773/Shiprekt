#include "WeaponCommon.as";
#include "AccurateSoundPlay.as";
#include "ParticleSparks.as";

const f32 PROJECTILE_SPEED = 9.0f;
const f32 PROJECTILE_SPREAD = 2.25;
const int FIRE_RATE = 50;
const f32 PROJECTILE_RANGE = 100.0f;
const f32 AUTO_RADIUS = 100.0f;

// Max amount of ammunition
const uint8 MAX_AMMO = 15;

// Amount of ammunition to refill when
// connected to motherships and stations
const uint8 REFILL_AMOUNT = 1;

// How often to refill when connected
// to motherships and stations
const uint8 REFILL_SECONDS = 5;

// How often to refill when connected
// to secondary cores
const uint8 REFILL_SECONDARY_CORE_SECONDS = 10;

// Amount of ammunition to refill when
// connected to secondary cores
const uint8 REFILL_SECONDARY_CORE_AMOUNT = 1;

void onInit(CBlob@ this)
{
	this.Tag("pointdefense");
	this.Tag("weapon");
	this.Tag("usesAmmo");
	this.Tag("solid");
	
	this.set_f32("weight", 3.5f);
	
	this.addCommandID("fire");

	if (isServer())
	{
		this.set_u16("ammo", MAX_AMMO);
		this.set_u16("maxAmmo", MAX_AMMO);
		this.Sync("ammo", true);
		this.Sync("maxAmmo", true);
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
	if (this.getShape().getVars().customData <= 0)
		return;

	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ laser = sprite.getSpriteLayer("laser");
	if (laser !is null && this.get_u32("fire time") + 5.0f < getGameTime())
		sprite.RemoveSpriteLayer("laser");

	if (this.get_u16("ammo") > 0)
		Auto(this);

	if (isServer())
	{
		refillAmmo(this, REFILL_AMOUNT, REFILL_SECONDS, REFILL_SECONDARY_CORE_AMOUNT, REFILL_SECONDARY_CORE_SECONDS);
	}
}

void Auto(CBlob@ this)
{
	if ((getGameTime() + this.getNetworkID() * 33) % 5 != 0)
		return;

	CBlob@[] blobsInRadius;
	Vec2f pos = this.getPosition();
	int thisColor = this.getShape().getVars().customData;
	f32 minDistance = 9999999.9f;
	bool shoot = false;
	Vec2f shootVec = Vec2f(0, 0);

	u16 hitBlobNetID = 0;
	Vec2f bPos = Vec2f(0, 0);

	if (this.getMap().getBlobsInRadius(this.getPosition(), AUTO_RADIUS, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b.getTeamNum() != this.getTeamNum()
					&& (b.getName() == "human"|| b.hasTag("projectile")))
			{
				bPos = b.getPosition();

				Ship@ targetShip;
				if (b.hasTag("block"))
					@targetShip = getShip(b.getShape().getVars().customData);
				else
				{
					@targetShip = getShip(b);
					if (b.isAttached())
					{
						AttachmentPoint@ humanAttach = b.getAttachmentPoint(0);
						CBlob@ seat = humanAttach.getOccupied();
						if (seat !is null)
							bPos = seat.getPosition();
					}
				}

				Vec2f aimVec = bPos - pos;
				f32 distance = aimVec.Length();

				int bColor = 0;

				bool merged = bColor != 0 && thisColor == bColor;

				if (b.getName() == "human")
					distance += 80.0f;//humans have lower priority

				if (distance < minDistance && isClearShot(this, aimVec, merged) && !getMap().rayCastSolid(bPos, pos))
				{
					shoot = true;
					shootVec = aimVec;
					minDistance = distance;
					hitBlobNetID = b.getNetworkID();
				}
			}
		}
	}

	if (shoot)
	{
		if (isServer() && canShootAuto(this))
		{
			Fire(this, shootVec, hitBlobNetID);
		}
	}
}

bool canShootAuto(CBlob@ this)
{
	return this.get_u32("fire time") + FIRE_RATE < getGameTime();
}

bool isClearShot(CBlob@ this, Vec2f aimVec, bool targetMerged = false)
{
	Vec2f pos = this.getPosition();
	const f32 distanceToTarget = Maths::Max(aimVec.Length() - 8.0f, 0.0f);
	HitInfo@[] hitInfos;
	CMap@ map = getMap();

	Vec2f offset = aimVec;
	offset.Normalize();
	offset *= 7.0f;

	map.getHitInfosFromRay(pos + offset.RotateBy(30), -aimVec.Angle(), distanceToTarget, this, @hitInfos);
	map.getHitInfosFromRay(pos + offset.RotateBy(-60), -aimVec.Angle(), distanceToTarget, this, @hitInfos);
	if (hitInfos.length > 0)
	{
		//HitInfo objects are sorted, first come closest hits
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;
			if (b is null || b is this) continue;

			int thisColor = this.getShape().getVars().customData;
			int bColor = b.getShape().getVars().customData;
			bool sameShip = bColor != 0 && thisColor == bColor;

			bool canShootSelf = targetMerged && hi.distance > distanceToTarget * 0.7f;

			//if (sameShip || targetMerged) print ("" + (sameShip ? "sameship; " : "") + (targetMerged ? "targetMerged; " : ""));

			if (b.hasTag("weapon") || b.hasTag("solid")
					|| (b.hasTag("block") && b.getShape().getVars().customData > 0 && (b.hasTag("solid")) && sameShip && !canShootSelf))
			{
				//print ("not clear " + (b.hasTag("block") ? " (block) " : "") + (!canShootSelf ? "!canShootSelf; " : ""));
				return false;
			}
		}
	}

	return true;
}

void Fire(CBlob@ this, Vec2f aimVector, const u16 hitBlobNetID)
{
	CBitStream params;
	params.write_netid(hitBlobNetID);
	params.write_Vec2f(aimVector);

	this.SendCommand(this.getCommandID("fire"), params);
}

void Rotate(CBlob@ this, Vec2f aimVector)
{
	CSpriteLayer@ layer = this.getSprite().getSpriteLayer("weapon");
	if (layer !is null)
	{
		layer.ResetTransform();
		layer.RotateBy(-aimVector.getAngleDegrees() - this.getAngleDegrees(), Vec2f_zero);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("fire"))
    {
		CBlob@ hitBlob = getBlobByNetworkID(params.read_netid());
		Vec2f aimVector = params.read_Vec2f();

		if (hitBlob is null)
			return;

		Vec2f pos = this.getPosition();
		Vec2f bPos = hitBlob.getPosition();

		//ammo
		u16 ammo = this.get_u16("ammo");

		if (ammo == 0)
		{
			directionalSoundPlay("LoadingTick1", pos, 1.0f);
			return;
		}

		ammo--;
		this.set_u16("ammo", ammo);

		if (hitBlob !is null)
		{
			if (isServer())
			{
				f32 damage = getDamage(hitBlob);
				this.server_Hit(hitBlob, bPos, Vec2f_zero, damage, 0, true);
			}

			Rotate(this, aimVector);
			shotParticles(pos + aimVector*9, aimVector.Angle(), false);
			directionalSoundPlay("Laser1.ogg", pos, 1.0f);

			Vec2f barrelPos = pos + Vec2f(1,0).RotateBy(aimVector.Angle())*8;
			if (isClient())//effects
			{
				CSprite@ sprite = this.getSprite();
				sprite.RemoveSpriteLayer("laser");
				CSpriteLayer@ laser = sprite.addSpriteLayer("laser", "Beam2.png", 16, 16);
				if (laser !is null)//partial length laser
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

				hitEffects(hitBlob, bPos);
			}
		}

		CSpriteLayer@ layer = this.getSprite().getSpriteLayer("weapon");
		if (layer !is null)
			layer.animation.SetFrameIndex(0);

		this.set_u32("fire time", getGameTime());
    }
}

f32 getDamage(CBlob@ hitBlob)
{
	if (hitBlob.hasTag("rocket"))
		return 0.5f;
	if (hitBlob.hasTag("projectile"))
		return 1.0f;

	return 0.01f;//cores, solids
}

void hitEffects(CBlob@ hitBlob, Vec2f worldPoint)
{
	if (hitBlob.hasTag("projectile"))
	{
		sparks(worldPoint, 4);
	}
}

