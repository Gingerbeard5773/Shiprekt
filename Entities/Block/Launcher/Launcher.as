#include "WeaponCommon.as";
#include "AccurateSoundPlay.as";
#include "ParticleSparks.as";

const f32 BULLET_SPEED = 3.0f;
const int FIRE_RATE = 200;

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
	
	this.set_f32("weight", 4.5f);
	
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

		Ship@ ship = getShip(this.getShape().getVars().customData);
		if (ship is null)
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
                bullet.setVelocity(velocity + ((getShip(this) !is null) ? getShip(this).vel : Vec2f(0, 0)));
				bullet.setAngleDegrees(-aimvector.Angle() + 90.0f);
                bullet.server_SetTimeToDie(25);
            }
    	}

		shotParticles(barrelPos, aimvector.Angle(), false);
		directionalSoundPlay("LauncherFire" + (XORRandom(2) + 1), barrelPos);

		this.set_u32("fire time", getGameTime());
    }
}
