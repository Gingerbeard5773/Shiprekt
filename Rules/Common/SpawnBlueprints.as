#include "MakeBlock.as"

void SpawnBlueprint( Vec2f pos, const int team )
{
	// platforms
	
	makeBlock( pos + Vec2f(-Block::size, -Block::size), 0.0f, Block::MOTHERSHIP1, team );
	makeBlock( pos + Vec2f(0, -Block::size), 0.0f, Block::MOTHERSHIP2, team );
	makeBlock( pos + Vec2f(Block::size, -Block::size), 0.0f, Block::MOTHERSHIP3, team );

	makeBlock( pos + Vec2f(-Block::size, 0), 0.0f, Block::MOTHERSHIP4, team );	
	makeBlock( pos, 0.0f, Block::SEAT, team ).AddScript("Seat.as");
	makeBlock( pos + Vec2f(Block::size, 0), 0.0f, Block::MOTHERSHIP6, team );

	makeBlock( pos + Vec2f(-Block::size, Block::size), 0.0f, Block::MOTHERSHIP7, team );
	makeBlock( pos + Vec2f(0, Block::size), 0.0f, Block::MOTHERSHIP8, team );
	makeBlock( pos + Vec2f(Block::size, Block::size), 0.0f, Block::MOTHERSHIP9, team );

	// surrounding

	makeBlock( pos + Vec2f(-Block::size*2, -Block::size*1), 0.0f, Block::SOLID, team );
	makeBlock( pos + Vec2f(-Block::size*2, -Block::size*2), 0.0f, Block::SOLID, team );
	makeBlock( pos + Vec2f(-Block::size*1, -Block::size*2), 0.0f, Block::SOLID, team );

	makeBlock( pos + Vec2f( 0, -Block::size*2), 0.0f, Block::PLATFORM2, team );

	makeBlock( pos + Vec2f( Block::size*1, -Block::size*2), 0.0f, Block::SOLID, team );
	makeBlock( pos + Vec2f( Block::size*2, -Block::size*2), 0.0f, Block::SOLID, team );
	makeBlock( pos + Vec2f( Block::size*2, -Block::size*1), 0.0f, Block::SOLID, team );

	makeBlock( pos + Vec2f( Block::size*2, 0), 0.0f, Block::PLATFORM2, team );

	makeBlock( pos + Vec2f( Block::size*2, Block::size*1), 0.0f, Block::SOLID, team );
	makeBlock( pos + Vec2f( Block::size*2, Block::size*2), 0.0f, Block::SOLID, team );
	makeBlock( pos + Vec2f( Block::size*1, Block::size*2), 0.0f, Block::SOLID, team );

	makeBlock( pos + Vec2f( 0, Block::size*2), 0.0f, Block::PLATFORM2, team );

	makeBlock( pos + Vec2f( -Block::size*1, Block::size*2), 0.0f, Block::SOLID, team );
	makeBlock( pos + Vec2f( -Block::size*2, Block::size*2), 0.0f, Block::SOLID, team );
	makeBlock( pos + Vec2f( -Block::size*2, Block::size*1), 0.0f, Block::SOLID, team );

	makeBlock( pos + Vec2f( -Block::size*2, 0), 0.0f, Block::PLATFORM2, team );
}