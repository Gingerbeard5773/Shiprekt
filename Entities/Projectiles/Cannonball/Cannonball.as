#include "WaterEffects.as";
#include "BlockCommon.as";
#include "IslandsCommon.as";
#include "Booty.as";
#include "AccurateSoundPlay.as";
#include "TileCommon.as";
#include "ParticleSparks.as";

const f32 SPLASH_RADIUS = 8.0f;
const f32 SPLASH_DAMAGE = 0.0f;
const f32 MAX_PIERCED = 2;

void onInit( CBlob@ this )
{
	this.Tag("cannonball");
	this.Tag("projectile");

	ShapeConsts@ consts = this.getShape().getConsts();
    consts.mapCollisions = false;	 // weh ave our own map collision
	consts.bullet = true;	
	
	this.set_u16( "pierced count", 0 );
    u32[] piercedBlobIDs;
    this.set( "pierced blob IDs", piercedBlobIDs );

	this.getSprite().SetZ(550.0f);	
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;
	
	int piercedCount = this.get_u16("pierced count");
    u32[]@ piercedBlobIDs;
    this.get("pierced blob IDs", @piercedBlobIDs);
	bool killed = false;

	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();
	
	if (isTouchingRock(pos))
	{
		this.server_Die();
		sparks(pos, 15, 2.5f, 20);
		directionalSoundPlay("MetalImpact" +  (XORRandom(2) + 1) + ".ogg", pos);
	}

	// this gathers HitInfo objects which contain blob or tile hit information
	HitInfo@[] hitInfos;
	if (getMap().getHitInfosFromRay( pos, -vel.Angle(), vel.Length(), this, @hitInfos ))
	{
		//HitInfo objects are sorted, first come closest hits
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;	  
			if (b is null || b is this) continue;
			
			u32 bID = b.getNetworkID();
			
			if (piercedBlobIDs.find(bID) >= 0) 
				continue;

			const int color = b.getShape().getVars().customData;
			const int blockType = b.getSprite().getFrame();
			const bool isBlock = b.getName() == "block";
			const bool sameTeam = b.getTeamNum() == this.getTeamNum();
			if (color > 0 || !isBlock)
			{
				if (isBlock)
				{
					if (Block::isSolid(blockType) || blockType == Block::DOOR || ((blockType == Block::MOTHERSHIP5 || blockType == Block::SECONDARYCORE || blockType == Block::DECOYCORE || b.hasTag( "weapon" ) ) && !sameTeam ) )
					{
						if (piercedCount >= MAX_PIERCED)
							killed = true;
						else
						{
							this.push("pierced blob IDs", bID);
							piercedCount++;
							this.setVelocity(this.getVelocity() * 0.5f);
						}
					}
					else if (blockType == Block::SEAT)
					{
						AttachmentPoint@ seat = b.getAttachmentPoint(0);
						CBlob@ occupier = seat.getOccupied();
						if (occupier !is null && occupier.getName() == "human" && occupier.getTeamNum() != this.getTeamNum())
						{
							if (piercedCount >= MAX_PIERCED)
								killed = true;
							else
							{
								this.push("pierced blob IDs", bID );
								piercedCount++;
								this.setVelocity( this.getVelocity() * 0.5f);
							}
						}
						else
							continue;
					}
					else
						continue;
				}
				else
				{
					if (sameTeam || (b.hasTag("player") && b.isAttached()) || b.hasTag("projectile"))//don't hit
						continue;
				}
				
				this.set_u16("pierced count", piercedCount);
				
				CPlayer@ owner = this.getDamageOwnerPlayer();
				if (owner !is null)
				{
					CBlob@ blob = owner.getBlob();
					if (blob !is null)
						damageBooty( owner, blob, b );
				}
				
				this.server_Hit(b, pos, Vec2f_zero, getDamage(this, b, blockType), 0, true);
				
				if (killed) 
				{
					this.server_Die(); 
					break;
				}
			}
		}
	}
}

f32 getDamage(CBlob@ this, CBlob@ hitBlob, int blockType)
{
	int piercedCount = this.get_u16("pierced count");
	f32 damage = 0.25;
	f32 damageFactor = 1.0f;
	
	if (piercedCount > 1)
		damageFactor *= 0.5f;
	if (piercedCount > 2)
		damageFactor *= 0.5f;

	if (Block::isSolid(blockType))
		return 0.5f * damageFactor;
	
	switch (blockType)
	{
		case Block::FAKERAM:
			damage = 99.0f;
			break;
		case Block::ANTIRAM:
			damage = 0.75f;
			break;
		case Block::RAMENGINE:
			damage = 2.75f;
			break;
		case Block::DOOR:
			damage = 0.6f ;
			break;
		case Block::SEAT:
			damage = 1.0f;
			break;
		case Block::DECOYCORE:
			damage = 1.75;
			break;
		default: damage = 0.25;
	}
	
	if ((hitBlob.hasTag("weapon") && hitBlob.getName() != "hyperflak") || blockType == Block::PROPELLER)
		return 1.75f * damageFactor;
	else if (hitBlob.getName() == "hyperflak")
		return 0.7f * damageFactor;
	else if (hitBlob.getName() == "shark" || hitBlob.getName() == "human")
		return 1.0f * damageFactor;

	return damage *damageFactor;
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{	
	if (customData == 9)
		return;
	
	const int blockType = hitBlob.getSprite().getFrame();
	
	int piercedCount = this.get_u16("pierced count");

	if (Block::isSolid(blockType) || blockType == Block::MOTHERSHIP5 || blockType == Block::SECONDARYCORE || blockType == Block::DECOYCORE || blockType == Block::DOOR || blockType == Block::SEAT || hitBlob.hasTag( "weapon" ) )
	{
		sparksDirectional(worldPoint, this.getVelocity(), 7);
		directionalSoundPlay("Pierce1.ogg", worldPoint);
			
		if (blockType == Block::MOTHERSHIP5)
			directionalSoundPlay("Entities/Characters/Knight/ShieldHit.ogg", worldPoint);
	}
}

void onDie(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	
	if (this.getTouchingCount() > 0)
	{
		sparks(pos, 15, 2.5, 20);
		directionalSoundPlay( "MetalImpact" +  ( XORRandom(2) + 1 ) + ".ogg", pos );
	}
	else
	{
		MakeWaterParticle( pos, Vec2f_zero);
		directionalSoundPlay( "WaterSplashBall.ogg", pos );
	}
		
	if (!isServer()) return;
		
	//splash damage
	CBlob@[] blobsInRadius;
	if (getMap().getBlobsInRadius( pos, SPLASH_RADIUS, @blobsInRadius ))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if ( !b.hasTag( "seat" ) && b.getName() == "block" && b.getShape().getVars().customData > 0 )
				this.server_Hit( b, Vec2f_zero, Vec2f_zero, SPLASH_DAMAGE, 9, false );
		}
	}
}

void sparksDirectional(Vec2f pos, Vec2f blobVel, int amount)
{
	Random _sprk_r;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 5.0f, 0);
        vel.RotateBy((-blobVel.getAngle() + 180.0f) + _sprk_r.NextFloat() * 30.0f - 15.0f);

        CParticle@ p = ParticlePixel(pos, vel, SColor( 255, 255, 128+_sprk_r.NextRanged(128), _sprk_r.NextRanged(128)), true);
        if (p is null) return; //bail if we stop getting particles

        p.timeout = 20 + _sprk_r.NextRanged(20);
        p.scale = 1.0f + _sprk_r.NextFloat();
        p.damping = 0.85f;
    }
}

void damageBooty( CPlayer@ attacker, CBlob@ attackerBlob, CBlob@ victim )
{
	if (victim.getName() == "block")
	{
		const int blockType = victim.getSprite().getFrame();
		u8 teamNum = attacker.getTeamNum();
		u8 victimTeamNum = victim.getTeamNum();
		string attackerName = attacker.getUsername();
		Island@ victimIsle = getIsland(victim.getShape().getVars().customData );

		if (victimIsle !is null && victimIsle.blocks.length > 3
			&& (victimIsle.owner != "" || victimIsle.isMothership)
			&& victimTeamNum != teamNum
			&& (Block::isSolid(blockType) || victim.hasTag("weapon") || blockType == Block::MOTHERSHIP5 || blockType == Block::DOOR || blockType == Block::SEAT)
			)
		{
			if (attacker.isMyPlayer())
				Sound::Play( "Pinball_0", attackerBlob.getPosition(), 0.5f);

			if (isServer())
			{
				CRules@ rules = getRules();
				
				u16 reward = 0;//solids,seat
				if (blockType == Block::PROPELLER)
					reward = 4;//propellers
				else if (victim.hasTag("weapon"))
					reward = 4;
				else if (blockType == Block::MOTHERSHIP5)
					reward = 8;

				f32 bFactor = (rules.get_bool("whirlpool") ? 3.0f : 1.0f );
				
				reward = Maths::Round(reward * bFactor);
					
				server_setPlayerBooty(attackerName, server_getPlayerBooty(attackerName) + reward);
				server_updateTotalBooty(teamNum, reward);
			}
		}
	}
}
