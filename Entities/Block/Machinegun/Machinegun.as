#include "WeaponCommon.as";
#include "WaterEffects.as";
#include "DamageBooty.as";
#include "AccurateSoundPlay.as";
#include "Hitters.as";
#include "ParticleSparks.as";
#include "PlankCommon.as";

const f32 BULLET_SPREAD = 2.5f;
const f32 BULLET_RANGE = 240.0F;
const f32 MIN_FIRE_PAUSE = 2.85f; //min wait between shots
const f32 MAX_FIRE_PAUSE = 8.0f; //max wait between shots
const f32 FIRE_PAUSE_RATE = 0.08f; //higher values = higher recover

const u8 MAX_AMMO = 250;
const u8 REFILL_AMOUNT = 30;
const u8 REFILL_SECONDS = 6;
const u8 REFILL_SECONDARY_CORE_SECONDS = 1;
const u8 REFILL_SECONDARY_CORE_AMOUNT = 2;

Random _shotspreadrandom(0x11598); //clientside

BootyRewards@ booty_reward;

void onInit(CBlob@ this)
{
	if (booty_reward is null)
	{
		BootyRewards _booty_reward;
		_booty_reward.addTagReward("bomb", 1);
		_booty_reward.addTagReward("engine", 2);
		@booty_reward = _booty_reward;
	}
	
	this.Tag("weapon");
	this.Tag("machinegun");
	this.Tag("usesAmmo");
	this.Tag("fixed_gun");
	
	this.set_f32("weight", 2.0f);
	
	this.addCommandID("fire");
	this.set_string("barrel", "left");

	if (isServer())
	{
		this.set_u16("ammo", MAX_AMMO);
		this.set_u16("maxAmmo", MAX_AMMO);
		this.set_f32("fire pause", MIN_FIRE_PAUSE);

		this.Sync("fire pause", true); //-1042743405 HASH
		this.Sync("ammo", true);
		this.Sync("maxAmmo", true);
	}

	CSprite@ sprite = this.getSprite();
	{
		sprite.SetRelativeZ(2);
		Animation@ anim = sprite.addAnimation("fire left", Maths::Round(MIN_FIRE_PAUSE), false);
		anim.AddFrame(1);
		anim.AddFrame(0);

		Animation@ anim2 = sprite.addAnimation("fire right", Maths::Round(MIN_FIRE_PAUSE), false);
		anim2.AddFrame(2);
		anim2.AddFrame(0);

		Animation@ anim3 = sprite.addAnimation("default", 1, false);
		anim3.AddFrame(0);
		sprite.SetAnimation("default");
	}

	this.set_u32("fire time", 0);
}

void onTick(CBlob@ this)
{
	const int col = this.getShape().getVars().customData;
	if (col <= 0) return; //not placed yet

	const u32 gameTime = getGameTime();
	const f32 currentFirePause = this.get_f32("fire pause");
	if (currentFirePause > MIN_FIRE_PAUSE)
		this.set_f32("fire pause", currentFirePause - FIRE_PAUSE_RATE * this.getCurrentScript().tickFrequency);

	//print("Fire pause: " + currentFirePause);

	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ laser = sprite.getSpriteLayer("laser");

	//kill laser after a certain time
	if (laser !is null && this.get_u32("fire time") + 3.0f < gameTime)
		sprite.RemoveSpriteLayer("laser");

	if (isServer())
	{
		Ship@ ship = getShipSet().getShip(col);
		if (ship !is null)
		{
			checkDocked(this, ship);
			if (canShoot(this))
				refillAmmo(this, ship, REFILL_AMOUNT, REFILL_SECONDS, REFILL_SECONDARY_CORE_AMOUNT, REFILL_SECONDARY_CORE_SECONDS);
		}
	}

	//reset the random seed periodically so joining clients see the same bullet paths
	if (gameTime % 450 == 0)
		_shotspreadrandom.Reset(gameTime);
}

const bool canShoot(CBlob@ this)
{
	return (this.get_u32("fire time") + this.get_f32("fire pause") < getGameTime());
}

const bool canIncreaseFirePause(CBlob@ this)
{
	return (MIN_FIRE_PAUSE < getGameTime());
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("fire"))
	{
		if (!canShoot(this) || this.get_bool("docked"))
			return;

		u16 shooterID;
		if (!params.saferead_netid(shooterID))
			return;

		CBlob@ shooter = getBlobByNetworkID(shooterID);
		if (shooter is null)
			return;

		Ship@ ship = getShipSet().getShip(this.getShape().getVars().customData);
		if (ship is null)
			return;

		if (canIncreaseFirePause(this))
		{
			f32 currentFirePause = this.get_f32("fire pause");
			if (currentFirePause < MAX_FIRE_PAUSE)
				this.set_f32("fire pause", currentFirePause + Maths::Sqrt(currentFirePause * (ship.isMothership ? 1.1 : 1.0f) * FIRE_PAUSE_RATE));
		}

		Vec2f pos = this.getPosition();

		this.set_u32("fire time", getGameTime());

		// ammo
		u16 ammo = this.get_u16("ammo");

		if (ammo <= 0)
		{
			directionalSoundPlay("LoadingTick1", pos, 0.5f);
			return;
		}

		ammo--;
		this.set_u16("ammo", ammo);
		
		CPlayer@ attacker = shooter.getPlayer();
		if (attacker !is null && attacker !is this.getDamageOwnerPlayer())
			this.SetDamageOwnerPlayer(shooter.getPlayer());

		//effects
		CSprite@ sprite = this.getSprite();
		sprite.SetAnimation("default");

		Vec2f aimVector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());

		Vec2f barrelOffset;
		Vec2f barrelOffsetRelative;
		if (this.get_string("barrel") == "left")
		{
			barrelOffsetRelative = Vec2f(0, -2.0);
			barrelOffset = Vec2f(0, -2.0).RotateBy(-aimVector.Angle());
			this.set_string("barrel", "right");
		}
		else
		{
			barrelOffsetRelative = Vec2f(0, 2.0);
			barrelOffset = Vec2f(0, 2.0).RotateBy(-aimVector.Angle());
			this.set_string("barrel", "left");
		}

		Vec2f barrelPos = pos + aimVector*9 + barrelOffset;

		//hit stuff
		const u8 teamNum = shooter.getTeamNum();//teamNum of the player firing
		HitInfo@[] hitInfos;
		CMap@ map = getMap();
		bool killed = false;
		bool blocked = false;

		f32 offsetAngle = (_shotspreadrandom.NextFloat() - 0.5f) * BULLET_SPREAD * 2.0f;
		aimVector.RotateBy(offsetAngle);

		const f32 rangeOffset = (_shotspreadrandom.NextFloat() - 0.5f) * BULLET_SPREAD * 8.0f;

		if (map.getHitInfosFromRay(barrelPos, -aimVector.Angle(), BULLET_RANGE + rangeOffset, this, @hitInfos))
		{
			const u8 hitLength = hitInfos.length;
			for (u8 i = 0; i < hitLength; i++)
			{
				HitInfo@ hi = hitInfos[i];
				CBlob@ b = hi.blob;
				u16 tileType = hi.tile;

				if (b is null || b is this) continue;

				const int thisColor = this.getShape().getVars().customData;
				const int bColor = b.getShape().getVars().customData;
				const bool sameShip = thisColor == bColor;
				const bool isBlock = b.hasTag("block");
				
				if (b.hasTag("plank") && !CollidesWithPlank(b, aimVector))
					continue;

				if (!b.hasTag("booty") && (bColor > 0 || !isBlock))
				{
					if (isBlock || b.hasTag("rocket"))
					{
						if (b.hasTag("solid") || (b.hasTag("door") && b.getShape().getConsts().collidable) || (b.getTeamNum() != teamNum && 
						   (b.hasTag("core") || b.hasTag("weapon") || b.hasTag("rocket") || b.hasTag("bomb"))))//hit these and die
							killed = true;
						else if (sameShip && b.hasTag("weapon") && (b.getTeamNum() == teamNum)) //team weaps
						{
							killed = true;
							blocked = true;
							directionalSoundPlay("lightup", barrelPos);
							break;
						}
						else if (b.hasTag("seat"))
						{
							AttachmentPoint@ seat = b.getAttachmentPoint(0);
							if (seat !is null)
							{
								CBlob@ occupier = seat.getOccupied();
								if (occupier !is null && occupier.getName() == "human" && occupier.getTeamNum() != this.getTeamNum())
									killed = true;
								else
									continue;
							}
						}
						else
							continue;
					}
					else
					{
						if (b.getTeamNum() == teamNum || (b.hasTag("player") && b.isAttached()))
							continue;
					}

					if (isClient())//effects
					{
						sprite.RemoveSpriteLayer("laser");
						CSpriteLayer@ laser = sprite.addSpriteLayer("laser", "Beam1.png", 16, 16);
						if (laser !is null)//partial length laser
						{
							Animation@ anim = laser.addAnimation("default", 1, false);
							int[] frames = { 0, 1, 2, 3, 4, 5 };
							anim.AddFrames(frames);
							laser.SetVisible(true);
							f32 laserLength = Maths::Max(0.1f, (hi.hitpos - barrelPos).getLength() / 16.0f);
							laser.ResetTransform();
							laser.ScaleBy(Vec2f(laserLength, 0.5f));
							laser.TranslateBy(Vec2f(laserLength*8.0f + 8.0f, barrelOffsetRelative.y));
							laser.RotateBy(offsetAngle, Vec2f());
							laser.setRenderStyle(RenderStyle::light);
							laser.SetRelativeZ(1);
						}

						hitEffects(b, hi.hitpos);
					}

					if (attacker !is null)
						rewardBooty(attacker, b, booty_reward, "Pinball_"+XORRandom(4));

					if (isServer())
					{
						if (b.hasTag("engine") && b.getTeamNum() != teamNum && XORRandom(3) == 0)
							b.SendCommand(b.getCommandID("off"));
						this.server_Hit(b, hi.hitpos, Vec2f_zero, getDamage(b), Hitters::arrow, true);
					}

					if (killed) break;
				}
			}
		}

		if (!blocked)
		{
			if (isClient())
			{
				shotParticles(barrelPos, aimVector.Angle(), false);
				directionalSoundPlay("Gunshot" + (XORRandom(2) + 2), barrelPos);
			}
			if (this.get_string("barrel") == "left")
				sprite.SetAnimation("fire left");
			else if (this.get_string("barrel") == "right")
				sprite.SetAnimation("fire right");
		}

		if (!killed && isClient())
		{
			sprite.RemoveSpriteLayer("laser");
			CSpriteLayer@ laser = sprite.addSpriteLayer("laser", "Beam1.png", 16, 16);
			if (laser !is null)
			{
				Vec2f solidPos;
				bool hitStone = map.rayCastSolid(pos, pos + aimVector * (BULLET_RANGE + rangeOffset), solidPos);
				
				Animation@ anim = laser.addAnimation("default", 1, false);
				int[] frames = {0, 1, 2, 3, 4, 5};
				anim.AddFrames(frames);
				laser.SetVisible(true);
				f32 laserLength = Maths::Max(0.1f, (hitStone ? solidPos - barrelPos : (aimVector * (BULLET_RANGE + rangeOffset))).getLength() / 16.0f);
				laser.ResetTransform();
				laser.ScaleBy(Vec2f(laserLength, 0.5f));
				laser.TranslateBy(Vec2f(laserLength * 8.0f + 8.0f, barrelOffsetRelative.y));
				laser.RotateBy(offsetAngle, Vec2f());
				laser.setRenderStyle(RenderStyle::light);
				laser.SetRelativeZ(1);
				
				Vec2f endPos = barrelPos + aimVector * (BULLET_RANGE + rangeOffset);
				
				if (hitStone) hitEffects(this, solidPos);
				else if (isInWater(endPos) && !v_fastrender)
					MakeWaterParticle(endPos, Vec2f_zero);
				else if (!v_fastrender) AngledDirtParticle(endPos, this.getAngleDegrees()-90);
			}
		}
	}
}

const f32 getDamage(CBlob@ hitBlob)
{
	f32 damage = 0.01f;

	if (hitBlob.hasTag("ramengine"))
		return 0.25f;
	if (hitBlob.hasTag("propeller"))
		return 0.15f;
	if (hitBlob.hasTag("seat") || hitBlob.hasTag("plank"))
		return 0.05f;
	if (hitBlob.hasTag("decoyCore"))
		return 0.075f;
	if (hitBlob.hasTag("bomb"))
		return 0.4f;
	if (hitBlob.hasTag("rocket"))
		return 0.35f;
	if (hitBlob.hasTag("weapon"))
		return 0.075f;
	if (hitBlob.getName() == "shark" || hitBlob.getName() == "human")
		return 0.2f;

	return damage;//cores, solids
}

void hitEffects(CBlob@ hitBlob, const Vec2f&in worldPoint)
{
	if (hitBlob.hasTag("block") && isClient())
	{
		sparks(worldPoint, v_fastrender ? 1 : 4);
		directionalSoundPlay("Ricochet" + (XORRandom(3) + 1) + ".ogg", worldPoint, 0.50f);
	}
}
