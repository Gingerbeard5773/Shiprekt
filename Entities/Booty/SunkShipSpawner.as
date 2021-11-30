#define SERVER_ONLY
//Spawn booty randomly
const u16 FREQUENCY = 2*30;//30 = 1 second
const f32 CLEAR_RADIUS_FACTOR = 2.5f;
const f32 MAX_CLEAR_RADIUS = 700.0f;
const u32 PADDING = 80;//border spawn padding
const u32 MAX_PENALTY_TIME = 90 * 30 * 60;//time where the area of spawning is reduced to the centermap

void onTick(CRules@ this)
{
	if ( getGameTime() % FREQUENCY > 0 || getRules().get_bool( "whirlpool" ) ) return;	
	
	CMap@ map = getMap();
	f32 mWidth = map.tilemapwidth * map.tilesize;
	f32 mHeight = map.tilemapheight * map.tilesize;
	Vec2f center = Vec2f( mWidth/2, mHeight/2 );
	u16 totalB = totalBooty();
	f32 timePenalty = Maths::Max( 0.0f, 1.0f - getGameTime()/MAX_PENALTY_TIME );
	u16 MAX_AMMOUNT = this.get_u16( "booty_x_max" );
	u16 MIN_AMMOUNT = this.get_u16( "booty_x_min" );
	f32 PER_PLAYER_AMMONT = 2.5f * MAX_AMMOUNT;
	//print( "<> " + getGameTime()/30/60 + " minutes penalty%: " + timePenalty );

	if ( totalB < getPlayersCount() * PER_PLAYER_AMMONT )
	{
		for ( u8 tries = 0; tries < 5; tries++ )
		{
			Vec2f spot = Vec2f ( center.x + 0.4f * ( XORRandom(2) == 0 ? -1 : 1 ) * XORRandom( center.x - PADDING ),
											center.y + 0.4f * ( XORRandom(2) == 0 ? -1 : 1 ) * XORRandom( center.y - PADDING ) );
			if ( zoneClear( map, spot, timePenalty < 0.2f ) )
			{
				f32 centerDist = ( center - spot ).Length();
				u16 ammount = Maths::Max( MIN_AMMOUNT, ( 1.0f - centerDist/Maths::Min( mWidth, mHeight ) ) * MAX_AMMOUNT );
				createBooty( spot, ammount );
				return;
			}
		}
		
		if ( timePenalty > 0.4f )
			for ( u8 tries = 0; tries < 10; tries++ )
			{
				Vec2f spot = Vec2f ( center.x + timePenalty * ( XORRandom(2) == 0 ? -1 : 1 ) * XORRandom( center.x - PADDING ),
												center.y + timePenalty * ( XORRandom(2) == 0 ? -1 : 1 ) * XORRandom( center.y - PADDING ) );
				if ( zoneClear( map, spot ) )
				{
					f32 centerDist = ( center - spot ).Length();
					u16 ammount = Maths::Max( MIN_AMMOUNT, ( 1.0f - centerDist/Maths::Min( mWidth, mHeight ) ) * MAX_AMMOUNT );
					createBooty( spot, ammount );
					break;
				}
			}
	}
}

void createBooty( Vec2f pos, u16 ammount )
{
    CBlob@ booty = server_CreateBlobNoInit( "booty" );
    if ( booty !is null )
	{
		booty.Tag( "booty" );
	    booty.set_u16( "ammount", ammount );
	    booty.set_u16( "prevAmmount", ammount );
		booty.server_setTeamNum(-1);
		booty.setPosition( pos );
		booty.Init();
	}
}

int totalBooty()
{
	CBlob@[] booty;
	getBlobsByName( "booty", @booty );
	u16 totalBooty = 0;

	for( int b = 0; b < booty.length(); b++ )
		totalBooty += booty[b].get_u16( "ammount" );

	return totalBooty;
}

bool zoneClear( CMap@ map, Vec2f spot, bool onlyBooty = false )
{
	f32 clearRadius = Maths::Min( Maths::Sqrt( map.tilemapwidth * map.tilemapheight ) * CLEAR_RADIUS_FACTOR, MAX_CLEAR_RADIUS );
	
	bool mothership = map.isBlobWithTagInRadius( "mothership", spot, clearRadius * 0.5f );
	bool booty = map.isBlobWithTagInRadius( "booty", spot, clearRadius );

	return !booty && ( onlyBooty || !mothership );
}