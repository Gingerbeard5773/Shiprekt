#include "WaterEffects.as";
#include "BlockCommon.as";
#include "IslandsCommon.as";
#include "Booty.as";
#include "AccurateSoundPlay.as";
#include "TileCommon.as";
#include "ParticleSparks.as";

void onInit( CBlob@ this )
{
	this.Tag("projectile");
	this.Tag("bullet");

	ShapeConsts@ consts = this.getShape().getConsts();
    consts.mapCollisions = false;
	consts.bullet = true;	

	this.getSprite().SetZ(550.0f);	
}

void onTick(CBlob@ this)
{
	bool killed = false;

	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();
	
	if (isTouchingRock(pos))
	{
		this.server_Die();
		sparks(pos, 8);
		directionalSoundPlay("Ricochet" +  ( XORRandom(3) + 1 ) + ".ogg", pos, 0.50f);
	}

	// this gathers HitInfo objects which contain blob or tile hit information
	HitInfo@[] hitInfos;
	if (getMap().getHitInfosFromRay(pos, -vel.Angle(), 2, this, @hitInfos))
	{
		//HitInfo objects are sorted, first come closest hits
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;	  
			if (b is null || b is this) continue;

			const int color = b.getShape().getVars().customData;
			const int blockType = b.getSprite().getFrame();
			const bool isBlock = b.getName() == "block";				

			if (!b.hasTag( "booty" ) && (color > 0 || !isBlock))
			{
				if (isBlock || b.hasTag("weapon"))
				{
					if (Block::isSolid(blockType) || ( b.getTeamNum() != this.getTeamNum() && ( blockType == Block::MOTHERSHIP5 || blockType == Block::SECONDARYCORE || blockType == Block::DECOYCORE || b.hasTag("weapon") || blockType == Block::BOMB || blockType == Block::DOOR ) ) )//hit these and die
						killed = true;
					else if (blockType == Block::SEAT)
					{
						AttachmentPoint@ seat = b.getAttachmentPoint(0);
						CBlob@ occupier = seat.getOccupied();
						if ( occupier !is null && occupier.getName() == "human" && occupier.getTeamNum() != this.getTeamNum() )
						{
							killed = true;
							if (XORRandom(3) == 0)//1/3 chance to hit the driver
								@b = occupier;
						}
						else
							continue;
					}
					else
						continue;
				}
				else
				{
					if ( b.getTeamNum() == this.getTeamNum() || b.isAttached() )
						continue;
					else if ( b.getName() == "shark" || b.hasTag("player") )
						killed = true;
				}
				
				CPlayer@ owner = this.getDamageOwnerPlayer();
				if ( owner !is null )
				{
					CBlob@ blob = owner.getBlob();
					if ( blob !is null )
						damageBooty( owner, blob, b );
				}
					
				this.server_Hit( b, pos, Vec2f_zero, getDamage( b, blockType ), 0, true );
				
				if (killed)
				{
					this.server_Die();
					break;
				}
			}
		}
	}
}

f32 getDamage( CBlob@ hitBlob, int blockType )
{
	if (hitBlob.getName() == "shark" || hitBlob.getName() == "human" || hitBlob.hasTag("weapon"))
		return 0.4f;
	else if (Block::isBomb(blockType))
		return 1.35f;

	f32 dmg = 0.25f; //cores | solids
	switch (blockType)
	{
		case Block::PROPELLER:
			dmg = 0.75f;
			break;
		case Block::RAMENGINE:
			dmg = 1.5f;
			break;
		case Block::SEAT:
		case Block::DECOYCORE:
		case Block::POINTDEFENSE:
			dmg = 0.4f;
			break;
		case Block::ANTIRAM:
			dmg = 0.5f;
			break;
		case Block::FAKERAM:
			dmg = 2.0f;
			break;
		case Block::DOOR:
			dmg = 0.7f;
			break;
	}
		
	return dmg;
}

void onDie(CBlob@ this)
{
	if (isInWater(this.getPosition()))
		MakeWaterParticle(this.getPosition(), Vec2f_zero);
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
	CSprite@ sprite = hitBlob.getSprite();
	const int blockType = sprite.getFrame();

	if (hitBlob.getName() == "shark"){
		ParticleBloodSplat( worldPoint, true );
		directionalSoundPlay( "BodyGibFall", worldPoint );
	}
	else if (hitBlob.hasTag("player") && hitBlob.getTeamNum() != this.getTeamNum())
	{
		directionalSoundPlay( "ImpactFlesh", worldPoint );
		ParticleBloodSplat( worldPoint, true );
	}
	else if (Block::isSolid(blockType) || blockType == Block::MOTHERSHIP5 || blockType == Block::SECONDARYCORE || blockType == Block::DECOYCORE || hitBlob.hasTag("weapon") || blockType == Block::PLATFORM || blockType == Block::SEAT || Block::isBomb( blockType ) || blockType == Block::DOOR)
	{
		//effects
		sparks(worldPoint, 8);
		directionalSoundPlay( "Ricochet" +  ( XORRandom(3) + 1 ) + ".ogg", worldPoint, 0.50f );
	}
}

void damageBooty(CPlayer@ attacker, CBlob@ attackerBlob, CBlob@ victim)
{
	if (victim.getName() == "block")
	{
		const int blockType = victim.getSprite().getFrame();
		u8 teamNum = attacker.getTeamNum();
		u8 victimTeamNum = victim.getTeamNum();
		string attackerName = attacker.getUsername();
		Island@ victimIsle = getIsland( victim.getShape().getVars().customData);

		if ( victimIsle !is null && victimIsle.blocks.length > 3
			&& ( victimIsle.owner != "" || victimIsle.isMothership )
			&& victimTeamNum != teamNum
			&& ( victim.hasTag("propeller") || victim.hasTag("weapon") || blockType == Block::MOTHERSHIP5 || Block::isBomb( blockType ) || blockType == Block::SEAT || blockType == Block::DOOR )
			)
		{
			if (attacker.isMyPlayer())
				Sound::Play( "Pinball_0", attackerBlob.getPosition(), 0.5f );

			if (isServer())
			{
				CRules@ rules = getRules();
				
				u16 reward = 5;//propellers, seat
				if ( victim.hasTag( "weapon" ) || Block::isBomb( blockType ) )
					reward = 5;
				else if ( blockType == Block::MOTHERSHIP5 )
					reward += 7;

				f32 bFactor = ( rules.get_bool( "whirlpool" ) ? 3.0f : 1.0f );
				
				reward = Maths::Round( reward * bFactor );
								
				server_setPlayerBooty( attackerName, server_getPlayerBooty( attackerName ) + reward );
				server_updateTotalBooty( teamNum, reward );
			}
		}
	}
}
