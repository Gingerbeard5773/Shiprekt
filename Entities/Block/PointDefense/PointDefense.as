#include "BlockCommon.as";
#include "IslandsCommon.as";
#include "AccurateSoundPlay.as";
#include "ParticleSparks.as";

const f32 PROJECTILE_SPEED = 9.0f;
const f32 PROJECTILE_SPREAD = 2.25;
const int FIRE_RATE = 50;
const f32 PROJECTILE_RANGE = 100.0f;
const f32 AUTO_RADIUS = 100.0f;

// Max amount of ammunition
const uint8 MAX_AMMO = 30;

// Amount of ammunition to refill when
// connected to motherships and stations
const uint8 REFILL_AMOUNT = 10;

// How often to refill when connected
// to motherships and stations
const uint8 REFILL_SECONDS = 1;

// How often to refill when connected
// to secondary cores
const uint8 REFILL_SECONDARY_CORE_SECONDS = 10;

// Amount of ammunition to refill when
// connected to secondary cores
const uint8 REFILL_SECONDARY_CORE_AMOUNT = 1;

Random _shotspreadrandom(0x11598); //clientside

void onInit( CBlob@ this )
{
	this.Tag("pointDefense");
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

	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ layer = sprite.addSpriteLayer( "weapon", 16, 16 );
    if (layer !is null)
    {
    	layer.SetRelativeZ(2);
    	layer.SetLighting( false );
     	Animation@ anim = layer.addAnimation( "fire", 15, false );
        anim.AddFrame(Block::POINTDEFENSE_A2);
        anim.AddFrame(Block::POINTDEFENSE_A1);
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

	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ laser = sprite.getSpriteLayer( "laser" );
	if ( laser !is null && this.get_u32("fire time") + 5.0f < gameTime )
		sprite.RemoveSpriteLayer("laser");

	Auto( this );

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

void Auto(CBlob@ this)
{
	if ((getGameTime() + this.getNetworkID() * 33 ) % 5 != 0 )
		return;

	CBlob@[] blobsInRadius;
	Vec2f pos = this.getPosition();
	int thisColor = this.getShape().getVars().customData;
	f32 minDistance = 9999999.9f;
	bool shoot = false;
	Vec2f shootVec = Vec2f(0, 0);

	u16 hitBlobNetID = 0;
	Vec2f bPos = Vec2f(0, 0);

	//ammo
	u16 ammo = this.get_u16("ammo");
	if (isServer()) this.get("ammo", ammo);

	if (this.getMap().getBlobsInRadius( this.getPosition(), AUTO_RADIUS, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if ( b.getTeamNum() != this.getTeamNum()
					&& (b.getName() == "human"|| b.hasTag("projectile")))
			{
				bPos = b.getPosition();

				Island@ targetIsland;
				if (b.getName() == "block")
					@targetIsland = getIsland( b.getShape().getVars().customData );
				else
				{
					@targetIsland = getIsland(b);
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

bool canShootAuto(CBlob@ this, bool manual = false)
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
			if(b is null || b is this) continue;

			int thisColor = this.getShape().getVars().customData;
			int bColor = b.getShape().getVars().customData;
			bool sameIsland = bColor != 0 && thisColor == bColor;

			const int blockType = b.getSprite().getFrame();

			bool canShootSelf = targetMerged && hi.distance > distanceToTarget * 0.7f;

			bool isOwnCore = Block::isCore( blockType ) && this.getTeamNum() == b.getTeamNum();

			//if ( sameIsland || targetMerged ) print ( "" + ( sameIsland ? "sameisland; " : "" ) + ( targetMerged ? "targetMerged; " : "" ) );

			if (b.hasTag("weapon") || Block::isSolid(blockType)
					|| ( b.getName() == "block" && b.getShape().getVars().customData > 0 && (Block::isSolid(blockType)) && sameIsland && !canShootSelf ) )
			{
				//print ( "not clear " + ( b.getName() == "block" ? " (block) " : "" ) + ( !canShootSelf ? "!canShootSelf; " : "" )  );
				return false;
			}
		}
	}

	return true;
}

void Fire( CBlob@ this, Vec2f aimVector, const u16 hitBlobNetID )
{
	CBitStream params;
	params.write_netid(hitBlobNetID);
	params.write_Vec2f(aimVector);

	this.SendCommand(this.getCommandID("fire"), params);
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

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("fire"))
    {
		CBlob@ hitBlob = getBlobByNetworkID( params.read_netid() );
		Vec2f aimVector = params.read_Vec2f();

		if (hitBlob is null)
			return;

		Vec2f pos = this.getPosition();
		Vec2f bPos = hitBlob.getPosition();
		//ammo
		u16 ammo = this.get_u16( "ammo" );
		if (isServer())
			this.get( "ammo", ammo );

		if ( ammo == 0 )
		{
			directionalSoundPlay( "LoadingTick1", pos, 1.0f );
			return;
		}

		ammo--;
		this.set_u16( "ammo", ammo );
		if (isServer())
			this.set( "ammo", ammo );

		if (hitBlob !is null)
		{
			if (isServer())
			{
				f32 damage = getDamage(hitBlob);
				this.server_Hit(hitBlob, bPos, Vec2f_zero, damage, 0, true);
			}

			Rotate(this, aimVector);
			shotParticles(pos + aimVector*9, aimVector.Angle());
			directionalSoundPlay( "Laser1.ogg", pos, 1.0f );

			Vec2f barrelPos = pos + Vec2f(1,0).RotateBy(aimVector.Angle())*8;
			if (isClient())//effects
			{
				CSprite@ sprite = this.getSprite();
				sprite.RemoveSpriteLayer("laser");
				CSpriteLayer@ laser = sprite.addSpriteLayer("laser", "Beam2.png", 16, 16);
				if (laser !is null)//partial length laser
				{
					Animation@ anim = laser.addAnimation( "default", 1, false );
					int[] frames = { 0, 1, 2, 3, 4, 5 };
					anim.AddFrames(frames);
					laser.SetVisible(true);
					f32 laserLength = Maths::Max(0.1f, (bPos - barrelPos).getLength() / 16.0f);
					laser.ResetTransform();
					laser.ScaleBy( Vec2f(laserLength, 0.5f) );
					laser.TranslateBy( Vec2f(laserLength*8.0f, 0.0f) );
					laser.RotateBy( -this.getAngleDegrees() - aimVector.Angle(), Vec2f());
					laser.setRenderStyle(RenderStyle::light);
					laser.SetRelativeZ(1);
				}

				hitEffects( hitBlob, bPos );
			}
		}

		CSpriteLayer@ layer = this.getSprite().getSpriteLayer( "weapon" );
		if ( layer !is null )
			layer.animation.SetFrameIndex(0);

		this.set_u32("fire time", getGameTime());
    }
}

f32 getDamage( CBlob@ hitBlob )
{
	if ( hitBlob.hasTag( "rocket" ) )
		return 0.5f;

	if ( hitBlob.hasTag( "cannonball" ) )
		return 1.0f;

	if ( hitBlob.hasTag( "bullet" ) )
		return 1.0f;

	if ( hitBlob.hasTag( "flak shell" ) )
		return 1.0f;

	if ( hitBlob.hasTag( "hyperflak shell" ) )
		return 0.5f;

	if ( hitBlob.getName() == "human" )
		return 0.2f;

	return 0.01f;//cores, solids
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
}

void hitEffects( CBlob@ hitBlob, Vec2f worldPoint )
{
	if (hitBlob.hasTag("player") )
	{
		directionalSoundPlay( "ImpactFlesh", worldPoint );
		ParticleBloodSplat( worldPoint, true );
	}
	else if ( hitBlob.hasTag("projectile") )
	{
		sparks(worldPoint, 4);
	}
}

