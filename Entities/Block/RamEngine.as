#include "IslandsCommon.as"
#include "BlockCommon.as"
#include "WaterEffects.as"
#include "PropellerForceCommon.as"
#include "AccurateSoundPlay.as"
#include "TileCommon.as"

Random _r(133701); //global clientside random object

void onInit( CBlob@ this )
{
	this.addCommandID("on/off");
	this.addCommandID("off");
	this.addCommandID("stall");
	this.Tag("propeller");
	this.set_f32("power", 0.0f);
	this.set_f32("powerFactor", 2.0f);
	this.set_u32( "onTime", 0 );
	this.set_u8( "stallTime", 0 );

	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ ramEngine = sprite.addSpriteLayer( "ramEngine" );
    if (ramEngine !is null)
    {
    	ramEngine.SetOffset(Vec2f(0,8));
    	ramEngine.SetRelativeZ(2);
    	ramEngine.SetLighting( false );
        Animation@ animcharge = ramEngine.addAnimation( "go", 1, true );
        animcharge.AddFrame(Block::PROPELLER_A1);
        animcharge.AddFrame(Block::PROPELLER_A2);
        ramEngine.SetAnimation("go");
    }

    sprite.SetEmitSound("PropellerMotor");
    sprite.SetEmitSoundPaused(true);
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("on/off") && getNet().isServer())
    {
		this.set_f32("power", isOn(this) ? 0.0f : -this.get_f32("powerFactor"));
    }
	
    if (cmd == this.getCommandID("off") && getNet().isServer())
    {
		this.set_f32("power", 0.0f);
    }
	
    if (cmd == this.getCommandID("stall") && getNet().isClient())
	{
		directionalSoundPlay( "propellerStall.ogg", this.getPosition(), 2.5f );		
		this.set_u8( "stallTime", params.read_u8() );
	}
}

bool isOn(CBlob@ this)
{
	return this.get_f32("power") != 0;
}

void onTick( CBlob@ this )
{
	if (this.getShape().getVars().customData <= 0)
		return;
	
	u32 gameTime = getGameTime();
	CSprite@ sprite = this.getSprite();
	f32 power = this.get_f32("power");
	Vec2f pos = this.getPosition();
	u8 stallTime = this.get_u8( "stallTime" );
	const bool stalled = stallTime > 0;
	const bool on = power != 0 && !stalled;	
	
	CSpriteLayer@ ramEngine = sprite.getSpriteLayer("ramEngine");
	if ( ramEngine !is null )
		ramEngine.animation.time = on ? 1 : 0;

	if ( getNet().isServer() )
		this.Sync("power", true);

	if ( stalled )
	{
		this.set_u8( "stallTime", stallTime - 1 );
		if ( getNet().isClient() )//stall smoke effect
		{
			if ( gameTime % ( v_fastrender ? 5 : 2 ) == 0 )
				smoke( pos );
		}
	}
	
	if (on)
	{
		//auto turn off after a while
		if ( getNet().isServer() && gameTime - this.get_u32( "onTime") > 750 )
		{
			this.SendCommand( this.getCommandID( "off" ) );
			return;
		}
			
		Island@ island = getIsland(this.getShape().getVars().customData);
		if (island !is null)
		{
			// move
			Vec2f moveVel;
			Vec2f moveNorm;
			float angleVel;
			
			PropellerForces(this, island, power, moveVel, moveNorm, angleVel);
			
			const f32 mass = island.mass + island.carryMass;
			moveVel /= mass;
			angleVel /= mass;
			
			island.vel += moveVel;
			island.angle_vel += angleVel;
		
			// eat stuff
			if (getNet().isServer() && ( gameTime + this.getNetworkID() ) % 15 == 0)
			{
				//low health stall failure
				f32 healthPct = this.getHealth()/this.getInitialHealth();
				if ( healthPct < 0.25f && !stalled && XORRandom(25) == 0 )
				{
					u8 stallTime = 30 + XORRandom(50);
					this.set_u8( "stallTime", stallTime );
					CBitStream params;
					params.write_u8( stallTime );
					this.SendCommand( this.getCommandID( "stall" ), params );
				}
				
				//eat stuff
				Vec2f faceNorm(0,-1);
				faceNorm.RotateBy(this.getAngleDegrees());
				CBlob@ victim = getMap().getBlobAtPosition( pos - faceNorm * Block::size );
				if ( victim !is null && !victim.isAttached() 
					 && victim.getShape().getVars().customData > 0
					       && !victim.hasTag( "player" ) )	
				{
					f32 hitPower = Maths::Max( 0.5f, Maths::Abs( this.get_f32("power") ) );
					if ( !victim.hasTag( "mothership" ) )
						this.server_Hit( victim, pos, Vec2f_zero, hitPower, 9, true );
					else
						victim.server_Hit( this, pos, Vec2f_zero, hitPower, 9, true );
				}
			}
			
			// effects
			if ( getNet().isClient() )
			{
				u8 tickStep = v_fastrender ? 20 : 4;
				if ( ( gameTime + this.getNetworkID() ) % tickStep == 0 && Maths::Abs(power) >= 1 && !isTouchingLand(pos) )
				{
					Vec2f rpos = Vec2f(_r.NextFloat() * -4 + 4, _r.NextFloat() * -4 + 4);
					MakeWaterParticle(pos + moveNorm * -6 + rpos, moveNorm * (-0.8f + _r.NextFloat() * -0.3f));
				}
				
				// limit sounds		
				if (island.soundsPlayed == 0 && sprite.getEmitSoundPaused() == true)
				{
					sprite.SetEmitSoundPaused(false);								
				}
				island.soundsPlayed++;
				const f32 vol = Maths::Min(0.5f + float(island.soundsPlayed)/2.0f, 3.0f);
				sprite.SetEmitSoundVolume( vol );
			}
		}
	}
	else
	{
		if ( sprite.getEmitSoundPaused() == false )
		{
			sprite.SetEmitSoundPaused(true);
		}
	}
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	if ( !getNet().isServer() || this.get_u8( "stallTime" ) > 0 )
		return damage;
		
	f32 healthPct = this.getHealth()/this.getInitialHealth();
	if ( healthPct > 0.0f && healthPct < 0.75f )
	{
		f32 stallFactor = 1.0f/healthPct + Maths::FastSqrt( damage );
		if ( stallFactor * XORRandom(9) > 15 )//chance based on health and damage to stall
		{
			u8 stallTime = stallFactor * 30;
			this.set_u8( "stallTime", stallTime );
			CBitStream params;
			params.write_u8( stallTime );
			this.SendCommand( this.getCommandID( "stall" ), params );
		}
	}
	
	return damage;
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
	if ( customData == 9 )
		directionalSoundPlay( "propellerHit.ogg", worldPoint );		
}

Random _smokerandom(0x15125); //clientside
void smoke( Vec2f pos )
{
	CParticle@ p = ParticleAnimated( "SmallSmoke1.png",
											  pos, Vec2f_zero,
											  _smokerandom.NextFloat() * 360.0f, //angle
											  1.0f, //scale
											  3+_smokerandom.NextRanged(2), //animtime
											  0.0f, //gravity
											  true ); //selflit
	if(p !is null)
		p.Z = 110.0f;
}