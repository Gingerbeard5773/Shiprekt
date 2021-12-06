#include "Booty.as";
#include "IslandsCommon.as";
#include "AccurateSoundPlay.as"
#include "TileCommon.as"

const u8 CHECK_FREQUENCY =  30;//30 = 1 second
const u32 FISH_RADIUS = 65.0f;//pickup radius
const f32 MAX_REWARD_FACTOR = 0.13f;//% taken per check for mothership (goes fully to captain if no one else on the ship)
const f32 CREW_REWARD_FACTOR = MAX_REWARD_FACTOR/5.0f;
const f32 CREW_REWARD_FACTOR_MOTHERSHIP = MAX_REWARD_FACTOR/2.5f;
const u32 AMMOUNT_INSTANT_PICKUP = 50;
const u8 SPACE_HOG_TICKS = 15;//seconds after collecting where no Xs can spawn there

void onInit( CBlob@ this )
{
	this.Tag( "booty" );
	this.getCurrentScript().tickFrequency = CHECK_FREQUENCY;
	this.set_u8( "killtimer", SPACE_HOG_TICKS );
	
	if ( !isInWater(this.getPosition()) )
		this.server_Die();
}

void onInit( CSprite@ this )
{
	this.ReloadSprites( 0, 0 );
	u16 ammount = this.getBlob().get_u16( "ammount" );
	f32 size = ammount/( getRules().get_u16( "booty_x_max" ) * 0.3f );
	if ( size >= 1.0f )
		this.ScaleBy( Vec2f( size, size ) );
	this.SetZ(-15.0f);
	this.RotateBy( XORRandom(360), Vec2f_zero );
}

void onTick( CBlob@ this )
{
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();
	u16 ammount = this.get_u16( "ammount" );
	
	if ( ammount == 0 )
	{
		this.SetVisible( false );

		u8 killtimer = this.get_u8( "killtimer" );
		if ( killtimer == SPACE_HOG_TICKS )
			directionalSoundPlay( "/ChaChing.ogg", pos );
			
		if ( map.isBlobWithTagInRadius( "mothership", this.getPosition(), FISH_RADIUS * 3.0f ) )
			killtimer = SPACE_HOG_TICKS;
			
		this.set_u8( "killtimer", killtimer - 1 );
		
		if ( getNet().isServer() && killtimer == 1 )
			this.server_Die();
		
		return;
	}
	
	string[] served;
	bool gaveBooty = false;

	//booty to motherships captain crew
	CBlob@[] humans;
	getBlobsByTag( "player", @humans );
	CBlob@[] cores;
	getBlobsByTag( "mothership", @cores );
	u16 minBooty = getRules().get_u16( "bootyRefillLimit" );
	for ( u8 i = 0; i < cores.length; i++ )
	{
		int coreColor = cores[i].getShape().getVars().customData;
		Island@ isle = getIsland( coreColor );
		if ( isle is null || isle.owner == "" || isle.owner  == "*" )
			continue;
			
		served.push_back( isle.owner );//captains only gather through the core
		string[] crew;
		if ( this.getDistanceTo( cores[i] ) <= FISH_RADIUS )
		{
			bool captainOnShip = false;
			for ( u8 i = 0; i < humans.length; i++ )//get crew on mothership and check if captain is there
			{
				CPlayer@ player = humans[i].getPlayer();
				if ( player is null )
					continue;
					
				CBlob@ islandBlob = getIslandBlob( humans[i] );
				if ( islandBlob is null || islandBlob.getShape().getVars().customData != coreColor )
					continue;
					
				string pName = player.getUsername();
				if ( pName == isle.owner )
					captainOnShip = true;
				else	if ( server_getPlayerBooty( pName ) < minBooty * 4 )
					crew.push_back( pName );
				else//wealthy or slacker on the mShip
					served.push_back( pName );
			}
			
			if ( !captainOnShip )//go to next core
				continue;
				
			u16 mothership_maxReward = Maths::Ceil( ammount * MAX_REWARD_FACTOR );
			f32 mothership_crewRewardFactor = Maths::Min( MAX_REWARD_FACTOR * 0.5f,  CREW_REWARD_FACTOR_MOTHERSHIP * crew.length );
			u16 mothership_crewTotalReward = Maths::Round( ammount * mothership_crewRewardFactor );

			//booty to captain
			u16 captainReward = mothership_maxReward - mothership_crewTotalReward;
			if ( ammount - captainReward <= AMMOUNT_INSTANT_PICKUP )
				captainReward = AMMOUNT_INSTANT_PICKUP;
			server_giveBooty( isle.owner, captainReward );
			server_updateX( this, captainReward, true );
			gaveBooty = true;

			//booty to crew
			if ( crew.length == 0 || !getNet().isServer() )
				continue;
				
			for ( u8 i = 0; i < crew.length; i++ )
			{
				served.push_back( crew[i] );
				f32 rewardFactor = Maths::Max( mothership_crewRewardFactor/crew.length, CREW_REWARD_FACTOR );
				u16 reward = Maths::Ceil( ammount * rewardFactor );
				server_giveBooty( crew[i], reward );
				server_updateX( this, reward, false );
			}
		}
	}
	
	//booty to over-sea crew
	for ( u8 i = 0; i < humans.length; i++ )
	{
		CPlayer@ player = humans[i].getPlayer();
		if ( player is null )
			continue;

		string name = player.getUsername();
		if ( this.getDistanceTo( humans[i] ) <= FISH_RADIUS && served.find( name ) == -1 )
		{
			u16 reward = Maths::Ceil( ammount * CREW_REWARD_FACTOR );
			server_giveBooty( name, reward );
			server_updateX( this, reward, !gaveBooty );
			gaveBooty = true;
		}
	}
	
	if ( gaveBooty )
		directionalSoundPlay( "/select.ogg", pos, 0.65f );
	else if ( getNet().isServer() )//bleed out
	{
		if ( ammount < AMMOUNT_INSTANT_PICKUP )
			this.server_Die();
		else if ( ammount > 0 && ( ammount < getRules().get_u16( "booty_x_min" ) || this.getTickSinceCreated() > 3600 ) )
			server_updateX( this, 2, false );
	}
}

void server_updateX( CBlob@ this, u16 reward, bool instaPickup = true )
{
	if ( !getNet().isServer() )	return;
	
	u16 ammount = this.get_u16( "ammount" );
		
	//if X is small enough, kill it and give remaining booty to player
	if ( instaPickup && ammount - reward <= AMMOUNT_INSTANT_PICKUP )
		this.set_u16( "ammount", 0 );
	else
		this.set_u16( "ammount", Maths::Max( 0, ammount - reward ) );

	this.Sync( "ammount", true );	
}

void server_giveBooty( string name, u16 ammount )
{
	if ( !getNet().isServer() )	return;

	CPlayer@ player = getPlayerByUsername( name );
	if ( player is null )	return;

	u16 pBooty = server_getPlayerBooty( name );
	server_setPlayerBooty( name, pBooty + ammount );
	server_updateTotalBooty( player.getTeamNum(), ammount );
}

void onTick(CSprite@ this)
{
	if ( this.animation.name == "default" && this.animation.ended() )
		this.SetAnimation( "pulse" );

	CBlob@ blob = this.getBlob();
	f32 ammount = blob.get_u16( "ammount" );	
	f32 prevAmmount = blob.get_u16( "prevAmmount" );
	blob.set_u16( "prevAmmount", ammount );
	f32 change = prevAmmount - ammount;
	
	if ( change > 0 )
	{
		f32 size = ammount/prevAmmount;
		this.ScaleBy( Vec2f( size, size ) );
	}
}