#include "WaterEffects.as"
#include "BlockCommon.as"
#include "IslandsCommon.as"
#include "Booty.as"
#include "AccurateSoundPlay.as"
#include "CustomMap.as";
#include "ParticleSparks.as";

const f32 BULLET_SPREAD = 2.5f;
const f32 BULLET_RANGE = 275.0F;
const f32 MIN_FIRE_PAUSE = 2.75f; //min wait between shots
const f32 MAX_FIRE_PAUSE = 8.0f; //max wait between shots
const f32 FIRE_PAUSE_RATE = 0.08f; //higher values = higher recover

// Max amount of ammunition
const uint8 MAX_AMMO = 250;

// Amount of ammunition to refill when
// connected to motherships and stations
const uint8 REFILL_AMOUNT = 30;

// How often to refill when connected
// to motherships and stations
const uint8 REFILL_SECONDS = 1;

// How often to refill when connected
// to secondary cores
const uint8 REFILL_SECONDARY_CORE_SECONDS = 1;

// Amount of ammunition to refill when
// connected to secondary cores
const uint8 REFILL_SECONDARY_CORE_AMOUNT = 4;

Random _shotspreadrandom(0x11598); //clientside

void onInit( CBlob@ this )
{
	this.Tag("weapon");
	this.Tag("machinegun");
	this.Tag("usesAmmo");
	this.Tag("fixed_gun");
	this.addCommandID("fire");
	this.addCommandID("disable");
	this.set_string("barrel", "left");

	if ( getNet().isServer() )
	{
		this.set('ammo', MAX_AMMO);
		this.set('maxAmmo', MAX_AMMO);
		this.set_u16('ammo', MAX_AMMO);
		this.set_u16('maxAmmo', MAX_AMMO);
		this.set_f32("fire pause",MIN_FIRE_PAUSE);
		this.set_bool( "mShipDocked", false );

		this.Sync("fire pause", true );
		this.Sync('ammo', true);
		this.Sync('maxAmmo', true);
	}

	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ layer = sprite.addSpriteLayer( "weapon", 16, 16 );
    if (layer !is null)
    {
        layer.SetRelativeZ(2);
        layer.SetLighting( false );
        Animation@ anim = layer.addAnimation( "fire left", Maths::Round( MIN_FIRE_PAUSE ), false );
        anim.AddFrame(Block::MACHINEGUN_A2);
        anim.AddFrame(Block::MACHINEGUN_A1);

		Animation@ anim2 = layer.addAnimation( "fire right", Maths::Round( MIN_FIRE_PAUSE ), false );
        anim2.AddFrame(Block::MACHINEGUN_A3);
        anim2.AddFrame(Block::MACHINEGUN_A1);

		Animation@ anim3 = layer.addAnimation( "default", 1, false );
		anim3.AddFrame(Block::MACHINEGUN_A1);
        layer.SetAnimation("default");
    }

	this.set_u32("fire time", 0);
}

void onTick( CBlob@ this )
{
	if ( this.getShape().getVars().customData <= 0 )//not placed yet
		return;

	u32 gameTime = getGameTime();
	f32 currentFirePause = this.get_f32("fire pause");
	if ( currentFirePause > MIN_FIRE_PAUSE )
		this.set_f32( "fire pause", currentFirePause - FIRE_PAUSE_RATE * this.getCurrentScript().tickFrequency );

	//print( "Fire pause: " + currentFirePause );

	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ laser = sprite.getSpriteLayer( "laser" );

	//kill laser after a certain time
	if ( laser !is null && this.get_u32("fire time") + 2.5f < gameTime )
		sprite.RemoveSpriteLayer("laser");

	if (getNet().isServer())
	{
		Island@ isle = getIsland(this.getShape().getVars().customData);

		if (isle !is null)
		{
			u16 ammo, maxAmmo;
			this.get('ammo', ammo);
			this.get('maxAmmo', maxAmmo);

			if (ammo < maxAmmo)
			{
				if (isle.isMothership || isle.isStation || isle.isMiniStation )
				{
					if (gameTime % (30 * REFILL_SECONDS) == 0)
					{
						ammo = Maths::Min(maxAmmo, ammo + REFILL_AMOUNT);
					}
				}
				else if (isle.isSecondaryCore)
				{
					if (gameTime % (30 * REFILL_SECONDARY_CORE_SECONDS) == 0)
					{
						ammo = Maths::Min(maxAmmo, ammo + REFILL_SECONDARY_CORE_AMOUNT);
					}
				}

				this.set('ammo', ammo);
			}

			this.Sync('ammo', true);
			this.set_u16('ammo', ammo);
			this.Sync('ammo', true);
		}
	}

	//reset the random seed periodically so joining clients see the same bullet paths
	if ( gameTime % 450 == 0 )
		_shotspreadrandom.Reset( gameTime );
}

bool canShoot( CBlob@ this )
{
	return ( this.get_u32("fire time") + this.get_f32("fire pause") < getGameTime() );
}

bool canIncreaseFirePause( CBlob@ this )
{
	return ( MIN_FIRE_PAUSE < getGameTime() );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("fire"))
    {
		if ( !canShoot(this) )
			return;

		u16 shooterID;
		if ( !params.saferead_u16(shooterID) )
			return;

		CBlob@ shooter = getBlobByNetworkID( shooterID );
		if (shooter is null)
			return;

		bool isServer = getNet().isServer();
		Vec2f pos = this.getPosition();

		Island@ island = getIsland( this.getShape().getVars().customData );
		if ( island is null )
			return;

		if ( canIncreaseFirePause(this) )
		{
			f32 currentFirePause = this.get_f32("fire pause");
			if ( currentFirePause < MAX_FIRE_PAUSE )
				this.set_f32( "fire pause", currentFirePause + Maths::Sqrt( currentFirePause * ( island.isMothership ? 1.0 : 1.0f ) * FIRE_PAUSE_RATE ) );
		}

		this.set_u32("fire time", getGameTime());

		// ammo
		u16 ammo = this.get_u16( "ammo" );
		if ( isServer )
			this.get( "ammo", ammo );

		if ( ammo == 0 )
		{
			directionalSoundPlay( "LoadingTick1", pos, 0.5f );
			return;
		}

		ammo--;
		this.set_u16( "ammo", ammo );
		if ( isServer )
			this.set( "ammo", ammo );

		//effects
		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ layer = sprite.getSpriteLayer( "weapon" );
		layer.SetAnimation( "default" );

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

		Vec2f barrelPos = this.getPosition() + aimVector*9 + barrelOffset;

		//hit stuff
		u8 teamNum = shooter.getTeamNum();//teamNum of the player firing
		HitInfo@[] hitInfos;
		CMap@ map = this.getMap();
		bool killed = false;
		bool blocked = false;

		f32 offsetAngle = ( _shotspreadrandom.NextFloat() - 0.5f ) * BULLET_SPREAD * 2.0f;
		aimVector.RotateBy(offsetAngle);

		f32 rangeOffset = ( _shotspreadrandom.NextFloat() - 0.5f ) * BULLET_SPREAD * 8.0f;

		if( map.getHitInfosFromRay( barrelPos, -aimVector.Angle(), BULLET_RANGE + rangeOffset, this, @hitInfos ) )
			for (uint i = 0; i < hitInfos.length; i++)
			{
				HitInfo@ hi = hitInfos[i];
				CBlob@ b = hi.blob;
				u16 tileType = hi.tile;

				if( b is null || b is this ) continue;

				const int thisColor = this.getShape().getVars().customData;
				int bColor = b.getShape().getVars().customData;
				bool sameIsland = bColor != 0 && thisColor == bColor;

				const int blockType = b.getSprite().getFrame();
				const bool isBlock = b.getName() == "block";

				if ( !b.hasTag( "booty" ) && (bColor > 0 || !isBlock) )
				{
					if ( isBlock || b.hasTag("rocket") )
					{
						if ( Block::isSolid(blockType) || ( b.getTeamNum() != teamNum && ( blockType == Block::MOTHERSHIP5 || blockType == Block::DECOYCORE || b.hasTag("weapon") || b.hasTag("rocket") || blockType == Block::BOMB ) ) )//hit these and die
							killed = true;
						else if ( sameIsland && b.hasTag("weapon") && (b.getTeamNum() == teamNum) ) //team weaps
						{
							killed = true;
							blocked = true;
							directionalSoundPlay( "lightup", barrelPos );
							break;
						}
						else if ( blockType == Block::SEAT || blockType == Block::RAMCHAIR )
						{
							AttachmentPoint@ seat = b.getAttachmentPoint(0);
							if (seat !is null)
							{
								CBlob@ occupier = seat.getOccupied();
								if ( occupier !is null && occupier.getName() == "human" && occupier.getTeamNum() != this.getTeamNum() )
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
						if ( b.getTeamNum() == teamNum || ( b.hasTag("player") && b.isAttached() ) )
							continue;
					}

					if ( getNet().isClient() )//effects
					{
						sprite.RemoveSpriteLayer("laser");
						CSpriteLayer@ laser = sprite.addSpriteLayer("laser", "Beam1.png", 16, 16);
						if (laser !is null)//partial length laser
						{
							Animation@ anim = laser.addAnimation( "default", 1, false );
							int[] frames = { 0, 1, 2, 3, 4, 5 };
							anim.AddFrames(frames);
							laser.SetVisible(true);
							f32 laserLength = Maths::Max(0.1f, (hi.hitpos - barrelPos).getLength() / 16.0f);
							laser.ResetTransform();
							laser.ScaleBy( Vec2f(laserLength, 0.5f) );
							laser.TranslateBy( Vec2f(laserLength*8.0f + 8.0f, barrelOffsetRelative.y) );
							laser.RotateBy( offsetAngle, Vec2f());
							laser.setRenderStyle(RenderStyle::light);
							laser.SetRelativeZ(1);
						}

						hitEffects(b, hi.hitpos);
					}

					CPlayer@ attacker = shooter.getPlayer();
					if ( attacker !is null )
						damageBooty( attacker, shooter, b );

					if ( isServer )
					{
						f32 damage = getDamage( b, blockType );
						if ( b.hasTag( "propeller" ) && b.getTeamNum() != teamNum && XORRandom(3) == 0 )
							b.SendCommand(b.getCommandID("off"));
						this.server_Hit( b, hi.hitpos, Vec2f_zero, damage, 0, true );
					}

					if ( killed ) break;
				}
			}

		if ( !blocked )
		{
			shotParticles( barrelPos, aimVector.Angle() );
			directionalSoundPlay( "Gunshot" + ( XORRandom(2) + 2 ) + ".ogg", barrelPos );
			if (this.get_string("barrel") == "left")
				layer.SetAnimation( "fire left" );
			if (this.get_string("barrel") == "right")
				layer.SetAnimation( "fire right" );
		}

		Vec2f solidPos;
		if ( !killed && map.rayCastSolid(pos, pos + aimVector * (BULLET_RANGE + rangeOffset), solidPos) )
		{
			//print( "hit a rock" );
			if ( getNet().isClient() )//effects
			{
				sprite.RemoveSpriteLayer("laser");
				CSpriteLayer@ laser = sprite.addSpriteLayer("laser", "Beam1.png", 16, 16);
				if (laser !is null)//partial length laser
				{
					Animation@ anim = laser.addAnimation( "default", 1, false );
					int[] frames = { 0, 1, 2, 3, 4, 5 };
					anim.AddFrames(frames);
					laser.SetVisible(true);
					f32 laserLength = Maths::Max(0.1f, (solidPos - barrelPos).getLength() / 16.0f);
					laser.ResetTransform();
					laser.ScaleBy( Vec2f(laserLength, 0.5f) );
					laser.TranslateBy( Vec2f(laserLength*8.0f + 8.0f, barrelOffsetRelative.y) );
					laser.RotateBy( offsetAngle, Vec2f());
					laser.setRenderStyle(RenderStyle::light);
					laser.SetRelativeZ(1);
				}

				hitEffects(this, solidPos);
			}
		}

		else if ( !killed && getNet().isClient() )//full length 'laser'
		{
			sprite.RemoveSpriteLayer("laser");
			CSpriteLayer@ laser = sprite.addSpriteLayer("laser", "Beam1.png", 16, 16);
			if (laser !is null)
			{
				Animation@ anim = laser.addAnimation( "default", 1, false );
				int[] frames = { 0, 1, 2, 3, 4, 5 };
				anim.AddFrames(frames);
				laser.SetVisible(true);
				f32 laserLength = Maths::Max(0.1f, (aimVector * (BULLET_RANGE + rangeOffset)).getLength() / 16.0f);
				laser.ResetTransform();
				laser.ScaleBy( Vec2f(laserLength, 0.5f) );
				laser.TranslateBy( Vec2f(laserLength*8.0f + 8.0f, barrelOffsetRelative.y) );
				laser.RotateBy( offsetAngle, Vec2f());
				laser.setRenderStyle(RenderStyle::light);
				laser.SetRelativeZ(1);
			}

			MakeWaterParticle( barrelPos + aimVector * (BULLET_RANGE + rangeOffset), Vec2f_zero );
		}
    }
}

f32 getDamage( CBlob@ hitBlob, int blockType )
{
	if ( hitBlob.hasTag( "rocket" ) )
		return 1.0f;

	if ( blockType == Block::PROPELLER )
		return 0.15f;

	if ( blockType == Block::FAKERAM )
		return 0.30f;

	if ( blockType == Block::ANTIRAM )
		return 0.09f;

	if ( blockType == Block::RAMENGINE )
		return 0.25f;

	if ( hitBlob.hasTag( "weapon" ) && hitBlob.getName() != "hyperflak" )
		return 0.075f;

	if ( hitBlob.getName() == "hyperflak" )
		return 0.05f;

	if ( hitBlob.getName() == "shark" || hitBlob.getName() == "human" )
		return 0.5f;

	if ( blockType == Block::SEAT )
		return 0.05f;

	if ( blockType == Block::RAMCHAIR )
		return 0.10f;

	if ( Block::isBomb( blockType ) )
		return 0.4f;

	if ( blockType == Block::DECOYCORE )
		return 0.075f;

	return 0.01f;//cores, solids
}

void hitEffects( CBlob@ hitBlob, Vec2f worldPoint )
{
	CSprite@ sprite = hitBlob.getSprite();
	const int blockType = sprite.getFrame();

	if (hitBlob.getName() == "shark"){
		ParticleBloodSplat( worldPoint, true );
		directionalSoundPlay( "BodyGibFall", worldPoint );
	}
	else	if (hitBlob.hasTag("player") )
	{
		directionalSoundPlay( "ImpactFlesh", worldPoint );
		ParticleBloodSplat( worldPoint, true );
	}
	else	if (Block::isSolid(blockType) || blockType == Block::MOTHERSHIP5 || hitBlob.hasTag("weapon")
					|| blockType == Block::PLATFORM || blockType == Block::SEAT || blockType == Block::RAMCHAIR || blockType == Block::BOMB)
	{
		sparks(worldPoint, 4);
		directionalSoundPlay( "Ricochet" +  ( XORRandom(3) + 1 ) + ".ogg", worldPoint, 0.50f );
	}
}

void shotParticles(Vec2f pos, float angle )
{
	//muzzle flash
	CParticle@ p = ParticleAnimated( "Entities/Block/turret_muzzle_flash.png",
									 pos, Vec2f(),
									-angle, //angle
									1.0f, //scale
									3, //animtime
									0.0f, //gravity
									true ); //selflit
	if (p !is null)
	{
		p.Z = 10.0f;
	}
}

void damageBooty( CPlayer@ attacker, CBlob@ attackerBlob, CBlob@ victim )
{
	if ( victim.getName() == "block" )
	{
		const int blockType = victim.getSprite().getFrame();
		u8 teamNum = attacker.getTeamNum();
		u8 victimTeamNum = victim.getTeamNum();
		string attackerName = attacker.getUsername();
		Island@ victimIsle = getIsland( victim.getShape().getVars().customData );

		if ( victimIsle !is null && victimIsle.blocks.length > 3
			&& ( victimIsle.owner != "" || victimIsle.isMothership )
			&& victimTeamNum != teamNum
			&& ( victim.hasTag("propeller") || victim.hasTag("weapon") || Block::isBomb( blockType ) || blockType == Block::SEAT || blockType == Block::RAMCHAIR )
			)
		{
			if ( attacker.isMyPlayer() )
			{
				u8 n = XORRandom(4);
				if ( n == 3 )
					Sound::Play( "Pinball_" + XORRandom(4), attackerBlob.getPosition(), 0.5f );
				else
					Sound::Play( "Pinball_" + n, attackerBlob.getPosition(), 0.5f );
			}

			if ( getNet().isServer() )
			{
				CRules@ rules = getRules();

				u16 reward = 2;//propellers, seat
				if ( victim.hasTag( "weapon" ) || Block::isBomb( blockType ) )
					reward = 2;

				f32 bFactor = ( rules.get_bool( "whirlpool" ) ? 3.0f : 1.0f );

				reward = Maths::Round( reward * bFactor );

				server_setPlayerBooty( attackerName, server_getPlayerBooty( attackerName ) + reward );
				server_updateTotalBooty( teamNum, reward );
			}
		}
	}
}
