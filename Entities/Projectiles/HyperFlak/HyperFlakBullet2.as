#include "ExplosionEffects.as";
#include "WaterEffects.as";
#include "BlockCommon.as";
#include "IslandsCommon.as";
#include "Booty.as";
#include "AccurateSoundPlay.as";
#include "TileCommon.as";
#include "ParticleSparks.as";
#include "Hitters.as";

const f32 EXPLODE_RADIUS = 25.0f;
const f32 FLAK_REACH = 50.0f;

void onInit( CBlob@ this )
{
	this.Tag("hyperflak shell");
	this.Tag("projectile");

	ShapeConsts@ consts = this.getShape().getConsts();
    consts.mapCollisions = false;	 // weh ave our own map collision
	consts.bullet = true;	

	this.getSprite().SetZ(550.0f);
	
	//shake screen (onInit accounts for firing latency)
	CPlayer@ localPlayer = getLocalPlayer();
	if (localPlayer !is null && localPlayer is this.getDamageOwnerPlayer())
		ShakeScreen(4, 4, this.getPosition());
}

void onTick( CBlob@ this )
{
	if (!isServer()) return;
	
	bool killed = false;

	Vec2f pos = this.getPosition();
	const int thisColor = this.get_u32("color");
	
	if (isTouchingRock(pos))
	{
		this.server_Die();
	}

	CBlob@[] blobs;
	if (getMap().getBlobsInRadius(pos, Maths::Min(float(5 + this.getTickSinceCreated()), EXPLODE_RADIUS), @blobs))
	{
		for (uint i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			if (b is null) continue;

			const int color = b.getShape().getVars().customData;
			const int blockType = b.getSprite().getFrame();
			const bool isBlock = b.getName() == "block";
			if (isBlock && color > 0 && color != thisColor && Block::isSolid(blockType))
				this.server_Die();
		}
	}
}

void flak(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	CMap@ map = getMap();
	CBlob@[] blobs;
	map.getBlobsInRadius(pos, FLAK_REACH, @blobs);
	
	if (blobs.length < 2)
		return;
		
	f32 angle = XORRandom(360);
	CPlayer@ owner = this.getDamageOwnerPlayer();

	for (u8 s = 0; s < 12; s++)
	{
		HitInfo@[] hitInfos;
		if (map.getHitInfosFromRay(pos, angle, FLAK_REACH, this, @hitInfos))
		{
			for (uint i = 0; i < hitInfos.length; i++)//sharpnel trail
			{
				CBlob@ b = hitInfos[i].blob;	  
				if (b is null || b is this) continue;
									
				const int blockType = b.getSprite().getFrame();
				const bool sameTeam = b.getTeamNum() == this.getTeamNum();
				if (Block::isSolid(blockType) || (!sameTeam
					&& (blockType == Block::SEAT || b.hasTag("weapon") || b.hasTag("rocket") || blockType == Block::MOTHERSHIP5 || blockType == Block::SECONDARYCORE || blockType == Block::DECOYCORE || blockType == Block::DOOR || Block::isBomb( blockType ) || ( b.hasTag( "player" ) && !b.isAttached() ) ) ) )
				{
					this.server_Hit(b, hitInfos[i].hitpos, Vec2f_zero, getDamage(b, blockType), Hitters::bomb, true);
					if (owner !is null)
					{
						CBlob@ blob = owner.getBlob();
						if (blob !is null)
							damageBooty(owner, blob, b);
					}
					
					break;
				}
			}
		}
		
		angle = ( angle + 30.0f ) % 360;
	}
}

void onDie( CBlob@ this )
{
	Vec2f pos = this.getPosition();
	
	if (getNet().isClient())
	{
		directionalSoundPlay( "FlakExp"+XORRandom(2), pos, 2.0f );
		for ( u8 i = 0; i < 3; i++ )
				makeSmallExplosionParticle( pos + getRandomVelocity( 90, 12, 360 ) );
	}

	if (isServer()) 	
		flak( this );
}

f32 getDamage( CBlob@ hitBlob, int blockType )
{
	if ( hitBlob.hasTag("rocket") )
		return 4.0f;
	
	if ( blockType == Block::RAM )
		return 1.0f;
	
	if ( blockType == Block::FAKERAM )
		return 4.0f;

	if ( blockType == Block::PROPELLER )
		return 0.75f;
		
	if ( blockType == Block::ANTIRAM )
		return 1.5f;
		
	if ( blockType == Block::RAMENGINE )
		return 1.25f;

	if ( blockType == Block::DOOR )
		return 0.9f;

	if ( hitBlob.getName() == "shark" || hitBlob.getName() == "human" )
		return 1.0f;

	if ( blockType == Block::SEAT || (hitBlob.hasTag( "weapon" ) && hitBlob.getName() != "hyperflak" ))
		return 0.6f;

	if ( hitBlob.getName() == "hyperflak" )
		return 0.4f;
	
	if ( blockType == Block::MOTHERSHIP5 || blockType == Block::SECONDARYCORE)
		return 0.3f;
	
	if ( Block::isBomb( blockType ) )
		return 4.0f;

	if ( blockType == Block::DECOYCORE )
		return 0.6f;
	
	return 1.0f;
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{	
	const int blockType = hitBlob.getSprite().getFrame();

	if (Block::isSolid(blockType) || blockType == Block::MOTHERSHIP5 || blockType == Block::SECONDARYCORE || blockType == Block::DOOR || blockType == Block::SEAT || hitBlob.hasTag( "weapon" ) )
	{
		Vec2f vel = worldPoint - hitBlob.getPosition();//todo: calculate real bounce angles?
		ShrapnelParticle( worldPoint, vel );
		directionalSoundPlay( "Ricochet" +  ( XORRandom(3) + 1 ) + ".ogg", worldPoint, 0.35f );
	}
}
