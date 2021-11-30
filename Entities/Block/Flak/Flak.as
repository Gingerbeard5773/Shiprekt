#include "BlockCommon.as"
#include "IslandsCommon.as"
#include "AccurateSoundPlay.as"

const f32 PROJECTILE_SPEED = 9.0f;
const f32 PROJECTILE_SPREAD = 2.25;
const int FIRE_RATE = 60;
const f32 PROJECTILE_RANGE = 450.0f;
const f32 CLONE_RADIUS = 20.0f;
const f32 AUTO_RADIUS = 400.0f;

// Max amount of ammunition
const uint8 MAX_AMMO = 30;

// Amount of ammunition to refill when
// connected to motherships and stations
const uint8 REFILL_AMOUNT = 4;

// How often to refill when connected
// to motherships and stations
const uint8 REFILL_SECONDS = 1;

// How often to refill when connected
// to secondary cores
const uint8 REFILL_SECONDARY_CORE_SECONDS = 4;

// Amount of ammunition to refill when
// connected to secondary cores
const uint8 REFILL_SECONDARY_CORE_AMOUNT = 1;

Random _shotspreadrandom(0x11598); //clientside

void onInit( CBlob@ this )
{
	this.Tag("flak");
	this.Tag("weapon");
	this.Tag("usesAmmo");
	this.addCommandID("fire");
	this.addCommandID("clear attached");

	if ( getNet().isServer() )
	{
		this.set('ammo', MAX_AMMO);
		this.set('maxAmmo', MAX_AMMO);
		this.set_u16('ammo', MAX_AMMO);
		this.set_u16('maxAmmo', MAX_AMMO);

		this.Sync('ammo', true);
		this.Sync('maxAmmo', true);
	}

	this.set_u32("fire time", 0);
	this.set_u16("parentID", 0);
	this.set_u16("childID", 0);

	if ( getNet().isServer() )
	{
		this.set_bool( "seatEnabled", true );
		this.Sync( "seatEnabled", true );
	}

	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ layer = sprite.addSpriteLayer( "weapon", 16, 16 );
    if (layer !is null)
    {
    	layer.SetRelativeZ(2);
    	layer.SetLighting( false );
     	Animation@ anim = layer.addAnimation( "fire", 15, false );
        anim.AddFrame(Block::FLAK_A2);
        anim.AddFrame(Block::FLAK_A1);
        layer.SetAnimation("fire");
    }
}

void onTick( CBlob@ this )
{
	if ( this.getShape().getVars().customData <= 0 )
		return;

	u32 gameTime = getGameTime();
	AttachmentPoint@ seat = this.getAttachmentPoint(0);
	CBlob@ occupier = seat.getOccupied();
	u16 thisID = this.getNetworkID();
	if ( occupier !is null )
	{
		u32 gameTime = getGameTime();
		this.set_u16( "parentID", 0 );
		Manual( this, occupier );

		CBlob@ childFlak = getBlobByNetworkID( this.get_u16( "childID" ) );
		if ( childFlak !is null )
		{
			if ( !childFlak.hasAttached() && childFlak.getDistanceTo( this ) < CLONE_RADIUS )
				Clone( childFlak, this, occupier );
			else
				this.set_u16( "childID", 0 );
		}
		else if ( gameTime % 20 == 0 )
		{
			@childFlak = findFlakChild( this );
			if ( childFlak !is null )
			{
				this.set_u16( "childID", childFlak.getNetworkID() );
				childFlak.set_u16( "parentID", thisID );
			}
		}

		//owned repulsors managing
		if ( occupier.isKeyJustPressed( key_action3 ) )
		{
			CPlayer@ player = occupier.getPlayer();
			if ( player !is null )
			{
				string occupierName = player.getUsername();
				CBlob@[] repulsors;
				getBlobsByTag( "repulsor", @repulsors );
				for (uint b_iter = 0; b_iter < repulsors.length; ++b_iter)
				{
					CBlob@ r = repulsors[b_iter];
					if ( r.getShape().getVars().customData > 0 && r.isOnScreen() && !r.hasTag("activated" ) && r.get_string( "playerOwner" ) == occupierName )
					{
						CButton@ button = occupier.CreateGenericButton( 8, Vec2f(0.0f, 0.0f), r, r.getCommandID("chainReaction"), "Activate" );

						if ( button !is null )
							button.enableRadius = 999.0f;
					}
				}
			}
		}
		else if ( occupier.isKeyJustReleased( key_action3 ) )
			occupier.ClearButtons();
	}
	else if ( this.get_u16( "childID" ) != 0 )//free child; parent
	{
		CBlob@ childFlak = getBlobByNetworkID( this.get_u16( "childID" ) );
		if ( childFlak !is null  )
			childFlak.set_u16( "parentID", 0 );

		this.set_u16( "childID", 0 );
	}
	else
	{
		Auto( this );
	}

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
}

void Manual( CBlob@ this, CBlob@ controller )
{
	Vec2f aimpos = controller.getAimPos();
	Vec2f pos = this.getPosition();
	Vec2f aimVec = aimpos - pos;
	CPlayer@ player = controller.getPlayer();

	// fire
	if ( controller.isMyPlayer() && controller.isKeyPressed( key_action1 ) && canShootManual( this, true ) && isClearShot( this, aimVec ) )
	{
		Island@ isle = getIsland( this.getShape().getVars().customData );
		u16 netID = 0;
		if ( isle !is null && player !is null && ( !isle.isMothership || isle.owner != player.getUsername() ) )
			netID = controller.getNetworkID();
		Fire( this, aimVec, netID );
	}

	// rotate turret
	Rotate( this, aimVec );
	aimVec.y *= -1;
	controller.setAngleDegrees( aimVec.Angle() );
}

void Auto( CBlob@ this )
{
	if ( ( getGameTime() + this.getNetworkID() * 33 ) % 20 != 0 )
		return;

	CBlob@[] blobsInRadius;
	Vec2f pos = this.getPosition();
	int thisColor = this.getShape().getVars().customData;
	f32 minDistance = 9999999.9f;
	bool shoot = false;
	Vec2f shootVec = Vec2f(0, 0);

	if ( getNet().isServer() && this.getMap().getBlobsInRadius( this.getPosition(), AUTO_RADIUS, @blobsInRadius ) )
	{
		for ( uint i = 0; i < blobsInRadius.length; i++ )
		{
			CBlob @b = blobsInRadius[i];
			if ( b.getTeamNum() != this.getTeamNum()
					&& ( b.getName() == "human"|| b.hasTag( "mothership" ) ||  b.hasTag( "rocket" ) || ( b.hasTag( "weapon" ) && b.getShape().getVars().customData > 0 ) ) )
			{
				Vec2f bPos = b.getPosition();

				Island@ targetIsland;
				if ( b.getName() == "block" )
					@targetIsland = getIsland( b.getShape().getVars().customData );
				else
				{
					@targetIsland = getIsland(b);
					if ( b.isAttached() )
					{
						AttachmentPoint@ humanAttach = b.getAttachmentPoint(0);
						CBlob@ seat = humanAttach.getOccupied();
						if ( seat !is null )
							bPos = seat.getPosition();
					}
				}

				Vec2f aimVec = bPos - pos;
				f32 distance = aimVec.Length();

				int bColor = 0;
				if ( targetIsland !is null )
				{
					bColor = b.getShape().getVars().customData;

					//prediction compensation
					//aimVec += targetIsland.vel * distance /PROJECTILE_SPEED * 0.9f;//poor man's kinematics
					aimVec += targetIsland.vel * Maths::FastSqrt( distance ) * 13.0f/PROJECTILE_SPEED;
					distance = aimVec.Length();//account for compensation
				}
				else if ( b.hasTag( "rocket" ) )
				{
					aimVec += b.getVelocity() * distance /PROJECTILE_SPEED * 0.9f;//poor man's kinematics
					distance = aimVec.Length();//account for compensation
				}

				bool merged = bColor != 0 && thisColor == bColor;

				if ( b.getName() == "human" )
					distance += 80.0f;//humans have lower priority

				if ( distance < minDistance && isClearShot( this, aimVec, merged ) )
				{
					shoot = true;
					shootVec = aimVec;
					minDistance = distance;
				}
			}
		}
	}

	if ( shoot )
	{
		if ( getNet().isServer() && canShootAuto( this ) )
		{
			u16 netID = 0;
			Island@ island = getIsland( this.getShape().getVars().customData );
			if ( island !is null )
			{
				CPlayer@ islandOwner = getPlayerByUsername( island.owner );
				if ( islandOwner !is null )
				{
					CBlob@ pBlob = islandOwner.getBlob();
					if ( pBlob !is null )
						netID = pBlob.getNetworkID();
				}
			}
			Fire( this, shootVec, netID );
		}
	}
}

void Clone( CBlob@ this, CBlob@ parent, CBlob@ controller )
{
	Vec2f aimpos = controller.getAimPos();
	Vec2f pos = parent.getPosition();
	Vec2f aimVec = aimpos - pos;
	CPlayer@ player = controller.getPlayer();
	// fire
	if ( isClearShot( this, aimVec ) )
	{
		Rotate( this, aimVec );
		if ( controller.isMyPlayer() && controller.isKeyPressed( key_action1 ) && canShootManual( this, true ) && ( getGameTime() - parent.get_u32("fire time") == FIRE_RATE/2 ) )
		{
			Island@ isle = getIsland( this.getShape().getVars().customData );
			u16 netID = 0;
			if ( isle !is null && player !is null && ( !isle.isMothership || isle.owner != player.getUsername() ) )
				netID = controller.getNetworkID();
			Fire( this, aimVec, netID );
		}
	}
	else if ( getGameTime() - this.get_u32("fire time") > 50 )//free it so it tries to find another
	{
		parent.set_u16( "childID", 0 );
		this.set_u16( "parentID", 0 );
	}
}

CBlob@ findFlakChild( CBlob@ this )
{
	int color = this.getShape().getVars().customData;
	CBlob@[] flak;
	CBlob@[] radBlobs;
	getMap().getBlobsInRadius( this.getPosition(), CLONE_RADIUS, @radBlobs );
	for ( uint i = 0; i < radBlobs.length; i++ )
	{
		CBlob@ b = radBlobs[i];
		if ( b.hasTag( "flak" ) && !b.hasAttached() && b.get_u16( "parentID" ) == 0 && color == b.getShape().getVars().customData )
			flak.push_back(b);
	}

	if ( flak.length > 0 )
		return flak[ getGameTime() % flak.length ];

	return null;
}

bool canShootAuto( CBlob@ this, bool manual = false )
{
	return this.get_u32("fire time") + FIRE_RATE < getGameTime();
}

bool canShootManual( CBlob@ this, bool manual = false )
{
	return this.get_u32("fire time") + FIRE_RATE/2 < getGameTime();
}

bool isClearShot( CBlob@ this, Vec2f aimVec, bool targetMerged = false )
{
	Vec2f pos = this.getPosition();
	const f32 distanceToTarget = Maths::Max( aimVec.Length(), 80.0f );
	HitInfo@[] hitInfos;
	CMap@ map = getMap();

	Vec2f offset = aimVec;
	offset.Normalize();
	offset *= 7.0f;

	map.getHitInfosFromRay( pos + offset.RotateBy(30), -aimVec.Angle(), distanceToTarget, this, @hitInfos );
	map.getHitInfosFromRay( pos + offset.RotateBy(-60), -aimVec.Angle(), distanceToTarget, this, @hitInfos );
	if ( hitInfos.length > 0 )
	{
		//HitInfo objects are sorted, first come closest hits
		for ( uint i = 0; i < hitInfos.length; i++ )
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;
			if( b is null || b is this ) continue;

			int thisColor = this.getShape().getVars().customData;
			int bColor = b.getShape().getVars().customData;
			bool sameIsland = bColor != 0 && thisColor == bColor;

			const int blockType = b.getSprite().getFrame();

			bool canShootSelf = targetMerged && hi.distance > distanceToTarget * 0.7f;

			bool isOwnCore = Block::isCore( blockType ) && this.getTeamNum() == b.getTeamNum();

			//if ( sameIsland || targetMerged ) print ( "" + ( sameIsland ? "sameisland; " : "" ) + ( targetMerged ? "targetMerged; " : "" ) );

			if ( b.getName() == "block" && b.getShape().getVars().customData > 0 && ( Block::isSolid( blockType ) || isOwnCore || b.hasTag("weapon") ) && sameIsland && !canShootSelf )
			{
				//print ( "not clear " + ( b.getName() == "block" ? " (block) " : "" ) + ( !canShootSelf ? "!canShootSelf; " : "" )  );
				return false;
			}
		}
	}

	Vec2f solidPos;
	if ( map.rayCastSolid(pos, pos + aimVec, solidPos) )
	{
		AttachmentPoint@ seat = this.getAttachmentPoint(0);
		CBlob@ occupier = seat.getOccupied();

		if ( occupier is null)
			return false;
	}

	return true;
}

void Fire( CBlob@ this, Vec2f aimVector, const u16 netid )
{
	const f32 aimdist = Maths::Min( aimVector.Normalize(), PROJECTILE_RANGE );

	Vec2f offset(_shotspreadrandom.NextFloat() * PROJECTILE_SPREAD,0);
	offset.RotateBy(_shotspreadrandom.NextFloat() * 360.0f, Vec2f());

	Vec2f _vel = (aimVector * PROJECTILE_SPEED) + offset;

	f32 _lifetime = Maths::Max( 0.05f + aimdist/PROJECTILE_SPEED/32.0f, 0.25f);

	CBitStream params;
	params.write_netid( netid );
	params.write_Vec2f( _vel );
	params.write_f32( _lifetime );
	this.SendCommand( this.getCommandID("fire"), params );
	this.set_u32("fire time", getGameTime());
}

void Rotate( CBlob@ this, Vec2f aimVector )
{
	CSpriteLayer@ layer = this.getSprite().getSpriteLayer("weapon");
	if(layer !is null)
	{
		layer.ResetTransform();
		layer.RotateBy( -aimVector.getAngleDegrees() - this.getAngleDegrees(), Vec2f_zero );
	}
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	if ( this.getDistanceTo(caller) > 3 * Block::BUTTON_RADIUS_FLOOR
		|| this.getShape().getVars().customData <= 0
		|| this.hasAttached()
		|| this.getTeamNum() != caller.getTeamNum() )
		return;

	CBitStream params;
	params.write_u16( caller.getNetworkID() );

	caller.CreateGenericButton( 7, Vec2f(0.0f, 0.0f), this, this.getCommandID("get in seat"), "Control Flak", params );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("fire"))
    {
		CBlob@ caller = getBlobByNetworkID( params.read_netid() );
		Vec2f pos = this.getPosition();
		bool isServer = getNet().isServer();
		//ammo
		u16 ammo = this.get_u16( "ammo" );
		if ( isServer )
			this.get( "ammo", ammo );

		if ( ammo == 0 )
		{
			directionalSoundPlay( "LoadingTick1", pos, 1.0f );
			return;
		}

		ammo--;
		this.set_u16( "ammo", ammo );
		if ( isServer )
			this.set( "ammo", ammo );

		Vec2f velocity = params.read_Vec2f();
		Vec2f aimVector = velocity;		aimVector.Normalize();
		const f32 time = params.read_f32();

		if ( isServer )
		{
            CBlob@ bullet = server_CreateBlob( "flakbullet", this.getTeamNum(), pos + aimVector*9 );
            if (bullet !is null)
            {
            	if ( caller !is null )
                	bullet.SetDamageOwnerPlayer( caller.getPlayer() );

                bullet.setVelocity( velocity );
                bullet.server_SetTimeToDie( time );
				bullet.set_u32( "color", this.getShape().getVars().customData );
				bullet.setAngleDegrees( -aimVector.Angle() );
            }
    	}

		Rotate( this, aimVector );
		shotParticles(pos + aimVector*9, velocity.Angle());
		directionalSoundPlay( "FlakFire.ogg", pos, 0.50f );

		CSpriteLayer@ layer = this.getSprite().getSpriteLayer( "weapon" );
		if ( layer !is null )
			layer.animation.SetFrameIndex(0);
    }
	else if (cmd == this.getCommandID("clear attached"))
	{
		AttachmentPoint@ seat = this.getAttachmentPoint(0);
		CBlob@ crewmate = seat.getOccupied();
		if ( crewmate !is null )
			crewmate.SendCommand( crewmate.getCommandID("get out") );
	}
}

Random _shotrandom(0x15125); //clientside
void shotParticles(Vec2f pos, float angle)
{
	//muzzle flash
	{
		CParticle@ p = ParticleAnimated( "Entities/Block/turret_muzzle_flash.png",
												  pos, Vec2f(),
												  -angle, //angle
												  1.0f, //scale
												  3, //animtime
												  0.0f, //gravity
												  true ); //selflit
		if(p !is null)
			p.Z = 10.0f;
	}

	Vec2f shot_vel = Vec2f(0.5f,0);
	shot_vel.RotateBy(-angle);

	//smoke
	for(int i = 0; i < 5; i++)
	{
		//random velocity direction
		Vec2f vel(0.1f + _shotrandom.NextFloat()*0.2f, 0);
		vel.RotateBy(_shotrandom.NextFloat() * 360.0f);
		vel += shot_vel * i;

		CParticle@ p = ParticleAnimated( "Entities/Block/turret_smoke.png",
												  pos, vel,
												  _shotrandom.NextFloat() * 360.0f, //angle
												  1.0f, //scale
												  3+_shotrandom.NextRanged(4), //animtime
												  0.0f, //gravity
												  true ); //selflit
		if(p !is null)
			p.Z = 550.0f;
	}
}
