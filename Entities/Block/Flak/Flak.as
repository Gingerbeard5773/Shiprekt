#include "WeaponCommon.as";
#include "AccurateSoundPlay.as";
#include "ParticleSparks.as";

const f32 PROJECTILE_SPEED = 9.0f;
const f32 PROJECTILE_SPREAD = 2.25;
const int FIRE_RATE = 60;
const f32 PROJECTILE_RANGE = 460.0f;
const f32 CLONE_RADIUS = 20.0f;
const f32 AUTO_RADIUS = 380.0f;

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
const uint8 REFILL_SECONDARY_CORE_SECONDS = 8;

// Amount of ammunition to refill when
// connected to secondary cores
const uint8 REFILL_SECONDARY_CORE_AMOUNT = 1;

Random _shotspreadrandom(0x11598); //clientside

void onInit(CBlob@ this)
{
	this.Tag("flak");
	this.Tag("weapon");
	this.Tag("usesAmmo");
	
	this.Tag("noEnemyEntry");
	this.set_string("seat label", "Control Flak");
	this.set_u8("seat icon", 7);
	
	this.set_f32("weight", 2.5f);
	
	this.addCommandID("fire");

	if (isServer())
	{
		this.set_u16("ammo", MAX_AMMO);
		this.set_u16("maxAmmo", MAX_AMMO);
		this.Sync("ammo", true);
		this.Sync("maxAmmo", true);
	}

	this.set_u32("fire time", 0);
	this.set_u16("parentID", 0);
	this.set_u16("childID", 0);

	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ layer = sprite.addSpriteLayer("weapon", "Flak.png", 16, 16);
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

	u32 gameTime = getGameTime();
	AttachmentPoint@ seat = this.getAttachmentPoint(0);
	CBlob@ occupier = seat.getOccupied();
	u16 thisID = this.getNetworkID();
	if (occupier !is null)
	{
		u32 gameTime = getGameTime();
		this.set_u16("parentID", 0);
		Manual(this, occupier);

		CBlob@ childFlak = getBlobByNetworkID(this.get_u16("childID"));
		if (childFlak !is null)
		{
			if (!childFlak.hasAttached() && childFlak.getDistanceTo(this) < CLONE_RADIUS)
				Clone(childFlak, this, occupier);
			else
				this.set_u16("childID", 0);
		}
		else if (gameTime % 20 == 0)
		{
			@childFlak = findFlakChild(this);
			if (childFlak !is null)
			{
				this.set_u16("childID", childFlak.getNetworkID());
				childFlak.set_u16("parentID", thisID);
			}
		}
	}
	else if (this.get_u16("childID") != 0)//free child; parent
	{
		CBlob@ childFlak = getBlobByNetworkID(this.get_u16("childID"));
		if (childFlak !is null)
			childFlak.set_u16("parentID", 0);

		this.set_u16("childID", 0);
	}
	else if (this.get_u16("ammo") > 0)
	{
		Auto(this);
	}

	if (isServer())
	{
		refillAmmo(this, REFILL_AMOUNT, REFILL_SECONDS, REFILL_SECONDARY_CORE_AMOUNT, REFILL_SECONDARY_CORE_SECONDS);
	}
}

void Manual(CBlob@ this, CBlob@ controller)
{
	Vec2f aimpos = controller.getAimPos();
	Vec2f pos = this.getPosition();
	Vec2f aimVec = aimpos - pos;
	CPlayer@ player = controller.getPlayer();

	// fire
	if (controller.isMyPlayer() && controller.isKeyPressed(key_action1) && canShootManual(this) && isClearShot(this, aimVec))
	{
		Ship@ ship = getShip(this.getShape().getVars().customData);
		u16 netID = 0;
		if (ship !is null && player !is null && (!ship.isMothership || ship.owner != player.getUsername()))
			netID = controller.getNetworkID();
		Fire(this, aimVec, netID);
	}

	// rotate turret
	Rotate(this, aimVec);
	aimVec.y *= -1;
	controller.setAngleDegrees(aimVec.Angle());
}

void Auto(CBlob@ this)
{
	if (!isServer())
		return;
	
	if ((getGameTime() + this.getNetworkID() * 33) % 20 != 0)
		return;

	CBlob@[] blobsInRadius;
	Vec2f pos = this.getPosition();
	int thisColor = this.getShape().getVars().customData;
	f32 minDistance = 9999999.9f;
	bool shoot = false;
	Vec2f shootVec = Vec2f(0, 0);

	if (getMap().getBlobsInRadius(pos, AUTO_RADIUS, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b.getTeamNum() != this.getTeamNum()
					&& (b.getName() == "human"|| b.hasTag("mothership") ||  b.hasTag("rocket") || (b.hasTag("weapon") && b.getShape().getVars().customData > 0)))
			{
				Vec2f bPos = b.getPosition();

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
				if (targetShip !is null)
				{
					bColor = b.getShape().getVars().customData;

					//prediction compensation
					//aimVec += targetShip.vel * distance /PROJECTILE_SPEED * 0.9f;//poor man's kinematics
					aimVec += targetShip.vel * Maths::FastSqrt(distance) * 13.0f/PROJECTILE_SPEED;
					distance = aimVec.Length();//account for compensation
				}
				else if (b.hasTag("rocket"))
				{
					aimVec += b.getVelocity() * distance /PROJECTILE_SPEED * 0.9f;//poor man's kinematics
					distance = aimVec.Length();//account for compensation
				}

				bool merged = bColor != 0 && thisColor == bColor;

				if (b.getName() == "human")
					distance += 80.0f;//humans have lower priority

				if (distance < minDistance && isClearShot(this, aimVec, merged))
				{
					shoot = true;
					shootVec = aimVec;
					minDistance = distance;
				}
			}
		}
	}

	if (shoot)
	{
		if (canShootAuto(this))
		{
			u16 netID = 0;
			Ship@ ship = getShip(this.getShape().getVars().customData);
			if (ship !is null)
			{
				CPlayer@ shipOwner = getPlayerByUsername(ship.owner);
				if (shipOwner !is null)
				{
					CBlob@ pBlob = shipOwner.getBlob();
					if (pBlob !is null)
						netID = pBlob.getNetworkID();
				}
			}
			Fire(this, shootVec, netID);
		}
	}
}

void Clone(CBlob@ this, CBlob@ parent, CBlob@ controller)
{
	Vec2f aimpos = controller.getAimPos();
	Vec2f pos = parent.getPosition();
	Vec2f aimVec = aimpos - pos;
	CPlayer@ player = controller.getPlayer();
	// fire
	if (isClearShot(this, aimVec))
	{
		Rotate(this, aimVec);
		if (controller.isMyPlayer() && controller.isKeyPressed(key_action1) && canShootManual(this) && (getGameTime() - parent.get_u32("fire time") == FIRE_RATE/2))
		{
			Ship@ ship = getShip(this.getShape().getVars().customData);
			u16 netID = 0;
			if (ship !is null && player !is null && (!ship.isMothership || ship.owner != player.getUsername()))
				netID = controller.getNetworkID();
			Fire(this, aimVec, netID);
		}
	}
	else if (getGameTime() - this.get_u32("fire time") > 50)//free it so it tries to find another
	{
		parent.set_u16("childID", 0);
		this.set_u16("parentID", 0);
	}
}

CBlob@ findFlakChild(CBlob@ this)
{
	int color = this.getShape().getVars().customData;
	CBlob@[] flak;
	CBlob@[] radBlobs;
	getMap().getBlobsInRadius(this.getPosition(), CLONE_RADIUS, @radBlobs);
	for (uint i = 0; i < radBlobs.length; i++)
	{
		CBlob@ b = radBlobs[i];
		if (b.hasTag("flak") && !b.hasAttached() && b.get_u16("parentID") == 0 && color == b.getShape().getVars().customData)
			flak.push_back(b);
	}

	if (flak.length > 0)
		return flak[getGameTime() % flak.length];

	return null;
}

bool canShootAuto(CBlob@ this)
{
	return this.get_u32("fire time") + FIRE_RATE < getGameTime();
}

bool canShootManual(CBlob@ this)
{
	return this.get_u32("fire time") + FIRE_RATE/2 < getGameTime();
}

bool isClearShot(CBlob@ this, Vec2f aimVec, bool targetMerged = false)
{
	Vec2f pos = this.getPosition();
	const f32 distanceToTarget = Maths::Max(aimVec.Length(), 80.0f);
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

			if (b.hasTag("block") && b.getShape().getVars().customData > 0 && (b.hasTag("solid") || b.hasTag("weapon")) && sameShip && !canShootSelf)
			{
				//print ("not clear " + (b.hasTag("block") ? " (block) " : "") + (!canShootSelf ? "!canShootSelf; " : ""));
				return false;
			}
		}
	}
	
	//check to make sure we aren't shooting through rock
	Vec2f solidPos;
	if (map.rayCastSolid(pos, pos + aimVec, solidPos))
	{
		AttachmentPoint@ seat = this.getAttachmentPoint(0);
		CBlob@ occupier = seat.getOccupied();

		if (occupier is null)
			return false;
	}

	return true;
}

void Fire(CBlob@ this, Vec2f aimVector, const u16 netid)
{
	const f32 aimdist = Maths::Min(aimVector.Normalize(), PROJECTILE_RANGE);

	Vec2f offset(_shotspreadrandom.NextFloat() * PROJECTILE_SPREAD,0);
	offset.RotateBy(_shotspreadrandom.NextFloat() * 360.0f, Vec2f());

	Vec2f _vel = (aimVector * PROJECTILE_SPEED) + offset;

	f32 _lifetime = Maths::Max(0.05f + aimdist/PROJECTILE_SPEED/32.0f, 0.25f);

	CBitStream params;
	params.write_netid(netid);
	params.write_Vec2f(_vel);
	params.write_f32(_lifetime);
	this.SendCommand(this.getCommandID("fire"), params);
	this.set_u32("fire time", getGameTime());
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
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		Vec2f pos = this.getPosition();

		//ammo
		u16 ammo = this.get_u16("ammo");

		if (ammo == 0)
		{
			directionalSoundPlay("LoadingTick1", pos, 1.0f);
			return;
		}

		ammo--;
		this.set_u16("ammo", ammo);

		Vec2f velocity = params.read_Vec2f();
		Vec2f aimVector = velocity;		aimVector.Normalize();
		const f32 time = params.read_f32();

		if (isServer())
		{
            CBlob@ bullet = server_CreateBlob("flakbullet", this.getTeamNum(), pos + aimVector*9);
            if (bullet !is null)
            {
            	if (caller !is null)
                	bullet.SetDamageOwnerPlayer(caller.getPlayer());

                bullet.setVelocity(velocity);
                bullet.server_SetTimeToDie(time);
				bullet.setAngleDegrees(-aimVector.Angle());
            }
    	}

		if (isClient())
		{
			Rotate(this, aimVector);
			shotParticles(pos + aimVector*9, velocity.Angle());
			directionalSoundPlay("FlakFire.ogg", pos, 0.50f);

			CSpriteLayer@ layer = this.getSprite().getSpriteLayer("weapon");
			if (layer !is null)
				layer.animation.SetFrameIndex(0);
		}
    }
}
