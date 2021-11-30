#include "ExplosionEffects.as";
#include "AccurateSoundPlay.as"

void onTick( CBlob@ this )
{
	if ( !this.exists( "nextExplosion" ) )
	{
		this.set_u32( "addedTime", getGameTime() );
		this.set_u32( "nextExplosion", getGameTime() + 20 + XORRandom( 80 ) );
	}
		
	if ( getGameTime() > this.get_u32( "nextExplosion" ) )
	{
		Explode( this );
		this.set_u32( "nextExplosion", getGameTime() + 20 + XORRandom( 45 ) );
	}
	
	//failsafe
	if ( getNet().isClient() && getGameTime() > this.get_u32( "addedTime" ) + 450 )
		this.getCurrentScript().runFlags |= Script::remove_after_this;	
}

void Explode( CBlob@ this )
{
	Vec2f pos = this.getPosition();
	//explosion effect
	directionalSoundPlay( "KegExplosion.ogg", pos );
    makeBrightExplosionParticle(pos);
	
	if ( this.isOnScreen() )
	    ShakeScreen( 30, 20, pos );

	if ( !getNet().isServer() ) return;
	
	//grab players nearby and damage them
	CBlob@[] blobs;
	getMap().getBlobsInRadius( pos, 8.0f, @blobs );

	for ( uint i = 0; i < blobs.length; i++ )
		if ( blobs[i] !is this && blobs[i].hasTag( "player" ) )
			this.server_Hit( blobs[i], pos, Vec2f_zero, blobs[i].getInitialHealth()/4.0f, 0, true );
	
	//damage self
	if ( !this.hasTag( "mothership" ) )
		this.server_Hit( this, pos, Vec2f_zero, this.getInitialHealth()/4.0f, 0, true );
}