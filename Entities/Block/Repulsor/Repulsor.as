#include "Hitters.as";
#include "BlockCommon.as";
#include "ExplosionEffects.as";
#include "IslandsCommon.as";
#include "AccurateSoundPlay.as"

const f32 PUSH_RADIUS = 18.0f;
const f32 PUSH_FACTOR =  1.0f;
const u8 FUSE_TIME = 40;

Random _effectsrandom(0x15125); //clientside

void onInit( CBlob@ this )
{
	this.Tag( "repulsor" );
	this.Tag( "removable" );//for corelinked checks
    this.addCommandID("chainReaction");
    this.addCommandID("activate");
	this.set_u32( "detonationTime", 0 );
	this.server_SetHealth( 2.0f );

	//Set Owner
	if ( getNet().isServer() )
	{
		CBlob@ owner = getBlobByNetworkID( this.get_u16( "ownerID" ) );    
		if ( owner !is null )
		{
			this.set_string( "playerOwner", owner.getPlayer().getUsername() );
			this.Sync( "playerOwner", true );
		}
	}

    CSprite@ sprite = this.getSprite();
    if(sprite !is null)
    {
        //default animation
        {
            Animation@ anim = sprite.addAnimation("default", 0, false);
            anim.AddFrame(Block::REPULSOR);
        }
        //activated animation
        {
            Animation@ anim = sprite.addAnimation("activated", FUSE_TIME/3, false);

            int[] frames = { Block::REPULSOR, Block::REPULSOR_A1, Block::REPULSOR_A2, Block::REPULSOR_A2, Block::REPULSOR_A2, };
            anim.AddFrames(frames);
        }
    }
}

void Repulse( CBlob@ this )
{
    Vec2f pos = this.getPosition();
	directionalSoundPlay( "Repulse2.ogg", pos, 2.5f );
	directionalSoundPlay( "Repulse3.ogg", pos, 1.5f );
	CBlob@[] blobs;
	getMap().getBlobsInRadius( pos, PUSH_RADIUS, @blobs );
	for (uint i = 0; i < blobs.length; i++)
	{
		CBlob@ b = blobs[i];
		int color = b.getShape().getVars().customData;
		if ( b is this || b.getName() != "block" || color <= 0 )
			continue;
		
		//push island
		Island@ isle = getIsland(color);
		if (isle !is null && isle.mass > 0.0f)
		{
			const int blockType = b.getSprite().getFrame();
			
			f32 pushMultiplier = 1.0f;
			if ( blockType == Block::RAMENGINE || blockType == Block::PROPELLER )
				pushMultiplier = 1.5f;			
			
			f32 pushDistance = (b.getPosition() - pos).getLength();
			
			Vec2f pushVel = ( b.getPosition() - pos) * (1 - (pushDistance/(PUSH_RADIUS*1.5f))) * PUSH_FACTOR*pushMultiplier/isle.mass;		//use island.centerBlock.getPosition() instead of  b.getPosition()?
			isle.vel += pushVel;
			//if ( isle.blocks.length == 1 )	b.setAngularVelocity( 300.0f );
		}
		
		//turn on props
		if ( getNet().isServer() && b.hasTag( "propeller" )  && isle.owner == "" )
		{
			b.set_u32( "onTime", getGameTime() );
			b.set_f32( "power", -1.0f );
		}
	}
	
	CParticle@ p = ParticleAnimated( "Shockwave2.png",
										  pos, //position
										  Vec2f(0, 0), //velocity
										  _effectsrandom.NextFloat()*360, //angle
										  1.0f, //scale
										  2, //animtime
										  0.0f, //gravity
										  true ); //selflit
	if(p !is null)
		p.Z = -100.0f;
	
	this.server_Die();
}

void onTick( CBlob@ this )
{
	if ( this.hasTag( "activated" ) )
	{
		u32 gameTime = getGameTime();
		if ( getNet().isServer() && gameTime == this.get_u32( "detonationTime" ) - 1 )
		{
			this.getShape().getVars().customData = -1;
			getRules().set_bool( "dirty islands", true );
		}
		else	if ( gameTime == this.get_u32( "detonationTime" ) )
			Repulse( this );
	}
}

void Activate(CBlob@ this, u32 time )
{
    this.Tag("activated");
	this.set_u32( "detonationTime", time );
    CSprite@ sprite = this.getSprite();
    sprite.SetAnimation("activated");
	directionalSoundPlay( "ChargeUp3.ogg", this.getPosition(), 3.75f );
}

void ChainReaction(CBlob@ this, u32 time)
{
	CBitStream bs;
	bs.write_u32( time );
	this.SendCommand( this.getCommandID("activate"), bs );

	CBlob@[] overlapping;
	this.getOverlapping( @overlapping );
	for ( int i = 0; i < overlapping.length; i++ )
	{
		CBlob@ b = overlapping[i];
		if ( b.hasTag( "repulsor" ) 
			&& !b.hasTag( "activated" ) 
			&& b.getShape().getVars().customData > 0
            && b.getDistanceTo(this) < 8.8f
			)
		{
			ChainReaction(b, time);
		}
	}
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("activate") && !this.hasTag("activated"))
		Activate(this, params.read_u32());
	else if ( getNet().isServer() && cmd == this.getCommandID("chainReaction") && !this.hasTag("activated"))
		ChainReaction(this, getGameTime() + FUSE_TIME );
}

void onDie(CBlob@ this)
{
	if ( !this.hasTag( "disabled" ) )
		Repulse( this );
}