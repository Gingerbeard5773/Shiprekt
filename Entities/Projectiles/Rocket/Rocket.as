#include "WaterEffects.as";
#include "BlockCommon.as";
#include "IslandsCommon.as";
#include "Booty.as";
#include "AccurateSoundPlay.as";
#include "MakeDustParticle.as";
#include "TileCommon.as";
#include "ParticleSparks.as";

const f32 SPLASH_RADIUS = 8.0f;
const f32 SPLASH_DAMAGE = 0.75f;
const f32 MANUAL_DAMAGE_MODIFIER = 0.75f;

const f32 ROCKET_FORCE = 7.5f;
const int ROCKET_DELAY = 15;
const int GUIDE_TIME = 120;
const f32 ROTATION_SPEED = 4.0;
const f32 GUIDANCE_RANGE = 225.0f;

Random _effectspreadrandom(0x11598); //clientside

void onInit( CBlob@ this )
{
	this.Tag("projectile");
	this.Tag("rocket");
	
	this.SetMapEdgeFlags(CBlob::map_collide_none);

	ShapeConsts@ consts = this.getShape().getConsts();
    consts.mapCollisions = false; // we have our own map collision
	consts.bullet = true;	

	this.getSprite().SetZ(550.0f);	
	this.getSprite().SetEmitSound("/RocketBooster.ogg");
	this.getSprite().SetEmitSoundVolume(0.5f);
	this.getSprite().SetEmitSoundPaused(true);
	
	this.set_u32("last smoke puff", 0 );
}

void onTick( CBlob@ this )
{	
	bool killed = false;

	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();
	f32 angle = this.getAngleDegrees();
	Vec2f aimvector = Vec2f(1,0).RotateBy(angle - 90.0f);
	
	if (this.getTickSinceCreated() > ROCKET_DELAY)
	{
		//rocket code!
		this.AddForce(aimvector*ROCKET_FORCE);
		
		CSprite@ sprite = this.getSprite();
		if (sprite.getEmitSoundPaused())
		{
			sprite.SetEmitSoundPaused(false);
		}
		
		if (isClient())
		{			
			f32 fireRandomOffsetX = (_effectspreadrandom.NextFloat() - 0.5) * 3.0f;
			
			const u32 gametime = getGameTime();
			u32 lastSmokeTime = this.get_u32("last smoke puff");
			int ticksTillSmoke = 1;
			int diff = gametime - (lastSmokeTime + ticksTillSmoke);
			if (diff > 0)
			{
				CParticle@ p = ParticleAnimated( CFileMatcher("RocketFire2.png").getFirst(), 
												this.getPosition() - aimvector*4 + Vec2f(fireRandomOffsetX, 0).RotateBy(angle), 
												this.getVelocity() + Vec2f(0.0f, 2.5f).RotateBy(angle), 
												float(XORRandom(360)), 
												1.0f, 
												3, 
												0.0f, 
												false );
				if (p !is null) p.damping = 0.9f;
			
				lastSmokeTime = gametime;
				this.set_u32("last smoke puff", lastSmokeTime);
			}
		}
	}
	
	//mouse guidance
	CPlayer@ owner = this.getDamageOwnerPlayer();
	if (owner !is null)
	{
		CBlob@ ownerBlob = owner.getBlob();
		if (ownerBlob !is null && ownerBlob.isAttached() && ownerBlob.isKeyPressed(key_action1))
		{	
			Vec2f aimPos = ownerBlob.getAimPos();
			Vec2f ownerPos = ownerBlob.getPosition();
			
			f32 targetDistance = (aimPos - ownerPos).getLength();
			f32 rocketDistance = (pos - ownerPos).getLength();
			
			if (targetDistance > GUIDANCE_RANGE) //must be done to preven desync issues
			{	
				aimPos = ownerPos + Vec2f( GUIDANCE_RANGE, 0).RotateBy( -(aimPos - ownerPos).getAngleDegrees());
			}
		
			f32 angleOffset = 270.0f;		
			f32 targetAngle = (aimPos - pos).getAngle();
			f32 thisAngle = this.getAngleDegrees();
			f32 shortAngle = (thisAngle + targetAngle + angleOffset) % 360;				
			
			this.set_f32("shortAngle", shortAngle);
			if (ownerBlob.isMyPlayer()) 
			{
				this.Sync("shortAngle", false);
			}
			else
			{
				shortAngle = this.get_f32("shortAngle");
			}
			
			if (shortAngle < 0 - ROTATION_SPEED*2.0f)
			{
				if (shortAngle < 180)
					this.setAngleDegrees(thisAngle + ROTATION_SPEED);
				if (shortAngle > 180)
					this.setAngleDegrees(thisAngle - ROTATION_SPEED);
			}
			if (shortAngle > 0 + ROTATION_SPEED*2.0f)
			{
				this.setAngleDegrees(thisAngle + (ROTATION_SPEED * (shortAngle < 180 ? -1 : 1)));
			}
		}
	}
	
	if (isTouchingRock(pos) || pos.y < 0.0f)
	{
		this.server_Die();
		sparks(pos, 15, 5.0f, 20);
		smoke(pos, 5);	
		blast(pos, 5);															
		directionalSoundPlay( "Blast2.ogg", pos );
	}
	
	if (isServer() && this.getTickSinceCreated() >= 4)
	{
		// this gathers HitInfo objects which contain blob or tile hit information
		HitInfo@[] hitInfos;
		if (getMap().getHitInfosFromRay(pos, -vel.Angle(), vel.Length(), this, @hitInfos))
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
				const bool sameTeam = b.getTeamNum() == this.getTeamNum();
				
				if ((b.hasTag("human") || b.hasTag("shark")) && !sameTeam)
				{
					killed = true;
					b.server_Die();
				}
				if (color > 0 || !isBlock)
				{
					if (isBlock || b.hasTag("rocket"))
					{
						if (blockType == Block::MOTHERSHIP5 || blockType == Block::SECONDARYCORE || blockType == Block::DECOYCORE || Block::isSolid(blockType) || 
							blockType == Block::DOOR || ((b.hasTag( "weapon" ) || b.hasTag( "rocket" )) && !sameTeam ))
							killed = true;
						else if (blockType == Block::SEAT)
						{
							AttachmentPoint@ seat = b.getAttachmentPoint(0);
							CBlob@ occupier = seat.getOccupied();
							if (occupier !is null && occupier.getName() == "human" && occupier.getTeamNum() != this.getTeamNum())
								killed = true;
							else continue;
						}
						else continue;
					}
					else
					{
						if (sameTeam || (b.hasTag("player") && b.isAttached()) || b.hasTag("projectile"))//don't hit
							continue;
					}
					
					if (owner !is null)
					{
						CBlob@ blob = owner.getBlob();
						if (blob !is null)
							damageBooty(owner, blob, b);
					}
					
					f32 damageModifier = this.getDamageOwnerPlayer() !is null ? MANUAL_DAMAGE_MODIFIER : 1.0f;
					this.server_Hit(b, pos, Vec2f_zero, getDamage(b, blockType) * damageModifier, 0, true);
					
					if (killed)
					{
						this.server_Die();
						break;
					}
				}
			}
		}
	}
}

f32 getDamage(CBlob@ hitBlob, int blockType)
{
	if (hitBlob.hasTag("rocket"))
		return 4.0f;

	if ((hitBlob.hasTag("weapon") && hitBlob.getName() != "hyperflak") || blockType == Block::PROPELLER )
		return 1.5f;
		
	if (blockType == Block::FAKERAM)
		return 8.0f;
		
	if (blockType == Block::ANTIRAM)
		return 3.0f;
		
	if (hitBlob.getName() == "hyperflak")
		return 1.0f;
		
	if (blockType == Block::RAMENGINE)
		return 4.0f;

	if (blockType == Block::DOOR)
		return 4.0f;
		
	if (Block::isSolid(blockType))
		return 2.0f;
	
	if (blockType == Block::PLATFORM)
		return 0.5f;

	if (hitBlob.getName() == "shark" || hitBlob.getName() == "human")
		return 0.0f;

	if (blockType == Block::SEAT)
		return 1.0f;

	if (blockType == Block::DECOYCORE)
		return 1.5f;

	return 1.20f;
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
	if (customData == 9) return;
	
	const int blockType = hitBlob.getSprite().getFrame();

	if (hitBlob.getName() == "shark"){
		ParticleBloodSplat(worldPoint, true);
		directionalSoundPlay("BodyGibFall", worldPoint);		
	}
	else if (Block::isSolid(blockType) || blockType == Block::MOTHERSHIP5 || blockType == Block::SECONDARYCORE || 
			 blockType == Block::SEAT || blockType == Block::DOOR || hitBlob.hasTag("weapon"))
	{
		sparks(worldPoint, 15, 5.0f, 20);
			
		if (blockType == Block::MOTHERSHIP5)
			directionalSoundPlay( "Entities/Characters/Knight/ShieldHit.ogg", worldPoint );
		else
			directionalSoundPlay( "Blast1.ogg", worldPoint );
	}
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	f32 spinFactor = this.getInitialHealth() - this.getHealth();
	this.setAngularVelocity((float(XORRandom(30) - 15))*spinFactor);

	return damage;
}

void onDie(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	
	if (isClient())
	{
		smoke(this.getPosition(), 5);	
		blast(this.getPosition(), 5);															
		directionalSoundPlay("Blast2.ogg", pos);
	}

	if (isServer()) return;

	//splash damage
	CBlob@[] blobsInRadius;
	if (getMap().getBlobsInRadius(pos, SPLASH_RADIUS, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			const int blockType = b.getSprite().getFrame();
			
			if (!b.hasTag("seat") && !b.hasTag("mothership") && b.getName() == "block" && b.getShape().getVars().customData > 0)
				this.server_Hit(b, Vec2f_zero, Vec2f_zero, getDamage(b, blockType) * SPLASH_DAMAGE, 9, false);
		}
	}
}

Random _smoke_r(0x10001);
void smoke(Vec2f pos, int amount)
{
	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(2.0f + _smoke_r.NextFloat() * 2.0f, 0);
        vel.RotateBy(_smoke_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericSmoke3.png").getFirst(), 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.0f, 
									4 + XORRandom(8), 
									0.0f, 
									false );
									
        if (p is null) return; //bail if we stop getting particles
		
        p.scale = 0.5f + _smoke_r.NextFloat()*0.5f;
        p.damping = 0.8f;
		p.Z = 550.0f;
    }
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount)
{
	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_blast_r.NextFloat() * 2.5f, 0);
        vel.RotateBy(_blast_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericBlast6.png").getFirst(), 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.0f, 
									2 + XORRandom(4), 
									0.0f, 
									false );
									
        if (p is null) return; //bail if we stop getting particles
		
        p.scale = 0.5f + _blast_r.NextFloat()*0.5f;
        p.damping = 0.85f;
		p.Z = 550.0f;
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
		Island@ victimIsle = getIsland(victim.getShape().getVars().customData);

		if (victimIsle !is null && victimIsle.blocks.length > 3
			&& (victimIsle.owner != "" || victimIsle.isMothership )
			&& victimTeamNum != teamNum
			&& (Block::isSolid(blockType) || victim.hasTag("weapon") || blockType == Block::MOTHERSHIP5 || blockType == Block::DOOR || Block::isBomb( blockType ) || blockType == Block::SEAT)
			)
		{
			if (attacker.isMyPlayer())
				Sound::Play( "Pinball_0", attackerBlob.getPosition(), 0.5f);

			if (isServer())
			{
				CRules@ rules = getRules();
				
				u16 reward = 3;//solids,seat
				if (blockType == Block::PROPELLER)
					reward += 5;//propellers
				else if (victim.hasTag("weapon") || Block::isBomb(blockType))
					reward += 5;
				else if (blockType == Block::MOTHERSHIP5)
					reward += 26;

				f32 bFactor = ( rules.get_bool("whirlpool") ? 3.0f : 1.0f );
				
				reward = Maths::Round(reward * bFactor);
					
				server_setPlayerBooty(attackerName, server_getPlayerBooty(attackerName) + reward);
				server_updateTotalBooty(teamNum, reward);
			}
		}
	}
}
