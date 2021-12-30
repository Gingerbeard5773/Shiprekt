#include "WeaponCommon.as";
#include "AccurateSoundPlay.as";
#include "ParticleSparks.as";

const f32 BULLET_SPEED = 3.0f;
const int FIRE_RATE = 200;
const f32 PROJECTILE_RANGE = 240.0f;

// Max amount of ammunition
const uint8 MAX_AMMO = 8;

// Amount of ammunition to refill when
// connected to motherships and stations
const uint8 REFILL_AMOUNT = 1;

// How often to refill when connected
// to motherships and stations
const uint8 REFILL_SECONDS = 2;

// How often to refill when connected
// to secondary cores
const uint8 REFILL_SECONDARY_CORE_SECONDS = 14;

// Amount of ammunition to refill when
// connected to secondary cores
const uint8 REFILL_SECONDARY_CORE_AMOUNT = 1;

Random _shotspreadrandom(0x11598); //clientside

void onInit(CBlob@ this)
{
	this.Tag("weapon");
	this.Tag("usesAmmo");
	this.Tag("machinegun"); //for seat.as
	
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

	this.set_u32("fire time", 0);
}

void onTick(CBlob@ this)
{
	if (this.getShape().getVars().customData <= 0)//not placed yet
		return;

	u32 gameTime = getGameTime();

	if (isServer())
	{
		refillAmmo(this, REFILL_AMOUNT, REFILL_SECONDS, REFILL_SECONDARY_CORE_AMOUNT, REFILL_SECONDARY_CORE_SECONDS);
	}
}

bool canShoot(CBlob@ this)
{
	return (this.get_u32("fire time") + FIRE_RATE < getGameTime()) ;
}

bool isClear(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	Vec2f aimVector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());
	u8 teamNum = this.getTeamNum();
	bool clear = true;
	
	CBlob@[] blobs;
	if (getMap().getBlobsAtPosition(pos + aimVector*8, @blobs))
	{
		for (uint i = 0; i < blobs.length; i++)
		{
			CBlob@ b =  blobs[i];
			if (b is null || b is this) continue;
			if (b.hasTag("solid") && b.getTeamNum() == teamNum)
			{
				clear = false;
				break;
			}
		}
	}
	
	HitInfo@[] hitInfos;
	if (getMap().getHitInfosFromRay(pos, -aimVector.Angle(), PROJECTILE_RANGE/4, this, @hitInfos))
	{
		for (uint i = 0; i < hitInfos.length; i++)
		{
			CBlob@ b =  hitInfos[i].blob;
			if (b is null || b is this) continue;

			if (b.hasTag("weapon") && b.getTeamNum() == teamNum)//team weaps
			{
				clear = false;
				break;
			}
		}
	}

	return clear;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("fire"))
    {
		if (!canShoot(this))
			return;

		u16 shooterID;
		if (!params.saferead_u16(shooterID))
			return;

		CBlob@ shooter = getBlobByNetworkID(shooterID);
		if (shooter is null)
			return;

		Island@ island = getIsland(this.getShape().getVars().customData);
		if (island is null)
			return;
			
		Vec2f pos = this.getPosition();

		if (!isClear(this))
		{
			directionalSoundPlay("lightup", pos);
			return;
		}

		//ammo
		u16 ammo = this.get_u16("ammo");

		if (ammo <= 0)
		{
			directionalSoundPlay("LoadingTick1", pos, 0.35f);
			return;
		}

		ammo--;
		this.set_u16("ammo", ammo);

		Vec2f aimvector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());
		Vec2f barrelPos = this.getPosition() + aimvector*9;
		Vec2f velocity = aimvector*BULLET_SPEED;

		if (isServer())
		{
            CBlob@ bullet = server_CreateBlob("rocket", this.getTeamNum(), pos + aimvector*8.0f);
            if (bullet !is null)
            {
            	if (shooter !is null)
				{
                	bullet.SetDamageOwnerPlayer(shooter.getPlayer());
                }
                bullet.setVelocity(velocity + ((getIsland(this) !is null) ? getIsland(this).vel : Vec2f(0, 0)));
				bullet.setAngleDegrees(-aimvector.Angle() + 90.0f);
                bullet.server_SetTimeToDie(25);
            }
    	}

		shotParticles(barrelPos, aimvector.Angle(), false);
		directionalSoundPlay("LauncherFire" + (XORRandom(2) + 1), barrelPos);

		this.set_u32("fire time", getGameTime());
    }
}
