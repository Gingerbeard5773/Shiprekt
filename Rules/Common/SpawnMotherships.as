#include "MakeBlock.as"

void onInit( CRules@ this )
{
	onRestart( this );
}

void onRestart( CRules@ this )
{
	if (getNet().isServer())
	{
		Vec2f[] spawns;			 
    	if (getMap().getMarkers("spawn", spawns))
		{
			u8 pCount = getPlayerCount();
			
			for ( u8 p = 0; p < pCount; p++ )//discard spectators
			{
				CPlayer@ player = getPlayer(p);
				if ( player.getTeamNum() == this.getSpectatorTeamNum() )
					pCount --;
			}
			
			u8 teamsNums = this.getTeamsNum();
			u8 availableCores = Maths::Min( spawns.length, teamsNums );
			u8 playingCores = pCount == 3 ? 3 : Maths::Max( 2, int( Maths::Floor( pCount/2 ) ) );//special case for 3 players
			u8 mShipsToSpawn = Maths::Min( playingCores, availableCores );
			print( "** Spawning " + mShipsToSpawn + " motherships of " + availableCores + " for " + pCount + " players" );
			
			for ( u8 s = 0; s < mShipsToSpawn; s ++ )
			{
				//quick fix: cyan looks too much like blue
				u8 team = s;
				if ( team == 5 )
					team = 7;
				else if ( team == 7 )
					team = 5;
					
        		SpawnMothership( spawns[s], team );
			}
    	}
    }
	//should find a better place for these
	this.set_bool( "whirlpool", false );
    CCamera@ camera = getCamera();
    if (camera !is null)
    	camera.setRotation(0.0f);
}

void SpawnMothership( Vec2f pos, const int team )
{
	// platforms
	
	makeBlock( pos + Vec2f(-Block::size, -Block::size), 0.0f, Block::MOTHERSHIP1, team );
	makeBlock( pos + Vec2f(0, -Block::size), 0.0f, Block::MOTHERSHIP2, team );
	makeBlock( pos + Vec2f(Block::size, -Block::size), 0.0f, Block::MOTHERSHIP3, team );

	makeBlock( pos + Vec2f(-Block::size, 0), 0.0f, Block::MOTHERSHIP4, team );	
	makeBlock( pos, 0.0f, Block::MOTHERSHIP5, team ).AddScript("Mothership.as");
	makeBlock( pos + Vec2f(Block::size, 0), 0.0f, Block::MOTHERSHIP6, team );

	makeBlock( pos + Vec2f(-Block::size, Block::size), 0.0f, Block::MOTHERSHIP7, team );
	makeBlock( pos + Vec2f(0, Block::size), 0.0f, Block::MOTHERSHIP8, team );
	makeBlock( pos + Vec2f(Block::size, Block::size), 0.0f, Block::MOTHERSHIP9, team );

	// surrounding

	makeBlock( pos + Vec2f(-Block::size*2, -Block::size*1), 0.0f, Block::SOLID, team );
	makeBlock( pos + Vec2f(-Block::size*2, -Block::size*2), 0.0f, Block::SOLID, team );
	makeBlock( pos + Vec2f(-Block::size*1, -Block::size*2), 0.0f, Block::SOLID, team );

	makeBlock( pos + Vec2f( 0, -Block::size*2), 0.0f, Block::PLATFORM, team );

	makeBlock( pos + Vec2f( Block::size*1, -Block::size*2), 0.0f, Block::SOLID, team );
	makeBlock( pos + Vec2f( Block::size*2, -Block::size*2), 0.0f, Block::SOLID, team );
	makeBlock( pos + Vec2f( Block::size*2, -Block::size*1), 0.0f, Block::SOLID, team );

	makeBlock( pos + Vec2f( Block::size*2, 0), 0.0f, Block::PLATFORM, team );

	makeBlock( pos + Vec2f( Block::size*2, Block::size*1), 0.0f, Block::SOLID, team );
	makeBlock( pos + Vec2f( Block::size*2, Block::size*2), 0.0f, Block::SOLID, team );
	makeBlock( pos + Vec2f( Block::size*1, Block::size*2), 0.0f, Block::SOLID, team );

	makeBlock( pos + Vec2f( 0, Block::size*2), 0.0f, Block::PLATFORM, team );

	makeBlock( pos + Vec2f( -Block::size*1, Block::size*2), 0.0f, Block::SOLID, team );
	makeBlock( pos + Vec2f( -Block::size*2, Block::size*2), 0.0f, Block::SOLID, team );
	makeBlock( pos + Vec2f( -Block::size*2, Block::size*1), 0.0f, Block::SOLID, team );

	makeBlock( pos + Vec2f( -Block::size*2, 0), 0.0f, Block::PLATFORM, team );
}
