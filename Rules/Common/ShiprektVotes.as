
#include "ShiprektVoteCommon.as"

//votekick and vote nextmap

const string votekick_id = "vote: kick";
const string votenextmap_id = "vote: nextmap";
const string votefreebuild_id = "vote: freebuild";

s32 g_lastVoteCounter = 0;
bool g_haveStartedVote = false;
const s32 _required_minutes = 4;
const s32 _required_time = 60*getTicksASecond()*_required_minutes;

const s32 VoteKickTime = 30*60; //seconds

const u32 BaseEnableTimeSuddenDeath = 10*30*60;//minimum base time. decreases on smaller maps and increases with cores count
const u32 suddenDeathVoteCooldown = 3*30*60;
const u32 freeBuildCooldown = 3*30*60;

//kicking related globals and enums
enum kick_reason {
	kick_reason_griefer = 0,
	kick_reason_hacker,
	kick_reason_teamkiller,
	kick_reason_spammer,
	kick_reason_afk,
	kick_reason_count,
};
string[] kick_reason_string = {"Griefer", "Hacker", "Teamkiller", "Spammer", "AFK" };

string g_kick_reason = kick_reason_string[kick_reason_griefer]; //default

//nextmap related globals and enums
enum nextmap_reason {
	nextmap_reason_ruined = 0,
	nextmap_reason_stalemate,
	nextmap_reason_bugged,
	nextmap_reason_count,
};

string[] nextmap_reason_string = {"Map Ruined", "Stalemate", "Game Bugged" };

//set up the ids

void onInit(CRules@ this)
{
	this.addCommandID(votekick_id);
	this.addCommandID(votenextmap_id);
	this.addCommandID(votefreebuild_id);
	this.set_s32( "lastSDVote", -suddenDeathVoteCooldown );
	this.set_s32( "lastFBVote", -freeBuildCooldown );
	this.set_bool( "freebuild", false );
	this.set_bool( "sudden death", false );
}

void onReload(CRules@ this)
{
	this.set_s32( "lastSDVote", -suddenDeathVoteCooldown );
	this.set_s32( "lastFBVote", -freeBuildCooldown );
	this.set_bool( "freebuild", false );
	this.set_bool( "sudden death", false );
}
 
void onRestart(CRules@ this)
{
	this.set_s32( "lastSDVote", -suddenDeathVoteCooldown );
	this.set_s32( "lastFBVote", -freeBuildCooldown );
	this.set_bool( "freebuild", false );
	this.set_bool( "sudden death", false );
}

void onTick(CRules@ this)
{
	if(g_lastVoteCounter < _required_time)
		g_lastVoteCounter++;
}

//VOTE KICK --------------------------------------------------------------------
//function to actually start a votekick

void StartVoteKick(CPlayer@ player, CPlayer@ byplayer, string reason)
{
	if(getSecurity().checkAccess_Feature( player, "kick_immunity" ))
		return;

	CRules@ rules = getRules();
	
	CBitStream params;
	
	params.write_u16(player.getNetworkID());
	params.write_u16(byplayer.getNetworkID());
	params.write_string(reason);
	
	rules.SendCommand(rules.getCommandID(votekick_id), params);
}

//votekick functor

class VoteKickFunctor : VoteFunctor {
	VoteKickFunctor() {}//dont use this
	VoteKickFunctor(u16 _playerid, u16 _byid)
	{
		playerid = _playerid;
		byid = _byid;
	}
	
	u16 playerid, byid;
	
	void Pass(bool outcome)
	{
		CPlayer@ kickplayer = getPlayerByNetworkId(playerid);
		CPlayer@ byplayer = getPlayerByNetworkId(byid);
		
		if(kickplayer is null || byplayer is null) return;
		
		if(outcome)
		{
			client_AddToChat( "Vote Kick Passed! "+kickplayer.getUsername()+" will be kicked out.", vote_message_colour() );
		}
		else
		{
			client_AddToChat( "Vote Kick Failed! "+byplayer.getUsername()+" will be kicked out.", vote_message_colour() );
		}
		
		if(getNet().isServer())
		{
			BanPlayer(outcome ? kickplayer : byplayer, VoteKickTime); //30 minutes ban
		}
	}
};

class VoteKickCheckFunctor : VoteCheckFunctor {
	VoteKickCheckFunctor() {}
	VoteKickCheckFunctor(u16 _playerid, u16 _byid)
	{
		playerid = _playerid;
		byid = _byid;
	}
	
	u16 playerid, byid;
	
	bool PlayerCanVote(CPlayer@ player)
	{
		u16 id = player.getNetworkID();
		return (id != playerid && id != byid);
	}
	
};

//setting up a votekick object
VoteObject@ Create_Votekick(CPlayer@ player, CPlayer@ byplayer, string reason)
{
	VoteObject vote;
	
	{
		VoteKickFunctor f(player.getNetworkID(), byplayer.getNetworkID());
		@vote.onvotepassed = f;
	}
	{
		VoteKickCheckFunctor f(player.getNetworkID(), byplayer.getNetworkID());
		@vote.canvote = f;
	}
	
	vote.succeedaction = "Kick "+ player.getUsername() +"\n(accused "+reason+")";
	vote.failaction = "Kick "+ byplayer.getUsername() +"\n(started votekick)";
	vote.byuser = byplayer.getUsername();
	vote.cancelaction = "Cancel vote.";
	
	vote.required_percent = 0.4f;
	CalculateVoteThresholds(vote);
	
	vote.timeremaining = 600;
	
	return vote;
}

//VOTE NEXT MAP ----------------------------------------------------------------
//function to actually start a sudden death

void StartVoteNextMap(CPlayer@ byplayer, string reason)
{
	CRules@ rules = getRules();
	
	CBitStream params;
	
	params.write_u16(byplayer.getNetworkID());
	params.write_string(reason);
	
	rules.SendCommand(rules.getCommandID(votenextmap_id), params);
}

//nextmap functor

class VoteNextmapFunctor : VoteFunctor {
	VoteNextmapFunctor() {}//dont use this
	VoteNextmapFunctor(CPlayer@ player, string _reason)
	{
		playername = player.getUsername();
		reason = _reason;
	}
	
	string playername;
	string reason;
	void Pass(bool outcome)
	{
		CMap@ map = getMap();
		f32 mapFactor = Maths::Min( 1.0f, Maths::Sqrt( map.tilemapwidth * map.tilemapheight ) / 300.0f );
		u32 minTime = Maths::Max( 0, Maths::Round( BaseEnableTimeSuddenDeath * mapFactor ) - getGameTime() );
		
		if ( minTime > 0 )	return;//for left-over votes from last round
			
		if(outcome)
		{
			client_AddToChat( "\n*** Sudden Death Started! Focus on destroying your enemies' engines so they can't escape the Whirlpool!\nPlayers get a huge Booty reward bonus from direct attacks.\nNote: removing heavy blocks from your ship doesn't help! Heavier ships are pulled less by the Whirlpool ***\n", vote_message_colour() );
			CRules@ rules = getRules();
			rules.set_bool( "sudden death", true );
		}
		else
		{
			client_AddToChat( "*** Sudden Death Failed! ***", vote_message_colour() );
		}
		
		if(getNet().isServer())
		{
			if(outcome)
			{
				CMap@ map = getMap();
				Vec2f mapCenter = Vec2f( map.tilemapwidth * map.tilesize/2, map.tilemapheight * map.tilesize/2 );
				server_CreateBlob( "whirlpool", 0, mapCenter );
				
				CBlob@[] stations;
				CBlob@[] ministations;
				getBlobsByTag( "station", @stations );
				getBlobsByTag( "ministation", @ministations );
				for (uint i = 0; i < stations.length; i++)
				{
					CBlob@ station = stations[i];
					
					if (station !is null)
						station.server_Die();
				}
				for (uint i = 0; i < ministations.length; i++)
				{
					CBlob@ ministation = ministations[i];
					
					if (ministation !is null)
						ministation.server_Die();
				}
			}
		}
	}
};


//setting up a vote next map object
VoteObject@ Create_VoteNextmap(CPlayer@ byplayer, string reason)
{
	VoteObject vote;
	
	{
		VoteNextmapFunctor f(byplayer, reason);
		@vote.onvotepassed = f;
	}
	
	vote.succeedaction = "Start Sudden Death?\n(" + reason + ")";
	vote.failaction = "Do Nothing.";
	vote.cancelaction = "Cancel vote.";
	
	vote.byuser = byplayer.getUsername();
	
	vote.required_percent = 0.7f;
	CalculateVoteThresholds(vote);
	
	vote.timeremaining = 600;
	
	return vote;
}

//vote free building
void StartVoteFreeBuilding(CPlayer@ byplayer, string reason)
{
	CRules@ rules = getRules();
	
	CBitStream params;
	
	params.write_u16(byplayer.getNetworkID());
	params.write_string(reason);
	
	rules.SendCommand(rules.getCommandID(votefreebuild_id), params);
}

//nextmap functor

class VoteFreeBuildingFunctor : VoteFunctor {
	VoteFreeBuildingFunctor() {}//dont use this
	VoteFreeBuildingFunctor(CPlayer@ player, string _reason)
	{
		playername = player.getUsername();
		reason = _reason;
	}
	
	string playername;
	string reason;
	void Pass(bool outcome)
	{
		CRules@ rules = getRules();
		bool newFreeState = !rules.get_bool( "freebuild" );
		if(outcome)
		{
			rules.set_bool( "freebuild", newFreeState );
			if (newFreeState)
				client_AddToChat( "\n*** Free building mode enabled. Blocks are free! Start a new free building mode vote to return to the normal game mode ***\n", vote_message_colour() );
			else
			client_AddToChat( "\n*** Free building mode disabled. Start a new free building mode vote to return to the free building game mode ***\n", vote_message_colour() );
		}
		else
		{
			client_AddToChat( "*** Free building mode vote Failed! ***", vote_message_colour() );
		}
	}
};


//setting up a vote free building object
VoteObject@ Create_VoteFreeBuilding(CPlayer@ byplayer, string reason)
{
	CRules@ rules = getRules();
	bool newFreeState = !rules.get_bool( "freebuild" );
	VoteObject vote;
	
	{
		VoteFreeBuildingFunctor f(byplayer, reason);
		@vote.onvotepassed = f;
	}
	if (newFreeState) 
		vote.succeedaction = "Enable free building mode?\n";
	else 
		vote.succeedaction = "Disable free building mode?\n";
	vote.failaction = "Do Nothing.";
	vote.cancelaction = "Cancel vote.";
	
	vote.byuser = byplayer.getUsername();
	
	vote.required_percent = 0.9f;
	CalculateVoteThresholds(vote);
	
	vote.timeremaining = 600;
	
	return vote;
}


//actually setting up the votes
void onCommand( CRules@ this, u8 cmd, CBitStream @params )
{
	if(Rules_AlreadyHasVote(this))
		return;
	
	if (cmd == this.getCommandID(votekick_id))
	{
		u16 playerid, byplayerid;
		string reason;
		
		if(!params.saferead_u16(playerid)) return;
		if(!params.saferead_u16(byplayerid)) return;
		if(!params.saferead_string(reason)) return;
		
		CPlayer@ player = getPlayerByNetworkId(playerid);
		CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);
		
		if(player !is null && byplayer !is null)
		{
			VoteObject@ votekick = Create_Votekick(player, byplayer, reason);
			
			Rules_SetVote(this, votekick);
		}
	}
	else if(cmd == this.getCommandID(votenextmap_id))
	{
		u16 byplayerid;
		string reason;
		
		if(!params.saferead_u16(byplayerid)) return;
		if(!params.saferead_string(reason)) return;
		
		CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);
		this.set_s32( "lastSDVote", getGameTime() );
		if( byplayer !is null && !this.get_bool( "whirlpool" ) )
		{
			VoteObject@ vote = Create_VoteNextmap(byplayer, reason);
			
			Rules_SetVote(this, vote);
		}
	}
	else if(cmd == this.getCommandID(votefreebuild_id))
	{
		u16 byplayerid;
		string reason;
		
		if(!params.saferead_u16(byplayerid)) return;
		if(!params.saferead_string(reason)) return;
		
		CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);
		this.set_s32( "lastFBVote", getGameTime() );
		if( byplayer !is null)
		{
			VoteObject@ vote = Create_VoteFreeBuilding(byplayer, reason);
			
			Rules_SetVote(this, vote);
		}
	}
	
}

//create the votes

void onMainMenuCreated(CRules@ this, CContextMenu@ menu)
{
	//get our player first - if there isn't one, move on
	CPlayer@ p = getLocalPlayer();
	if(p is null) return;
	
	int p_team = p.getTeamNum();
	
	CRules@ rules = getRules();
	
	if(Rules_AlreadyHasVote(rules))
	{
		Menu::addContextItem(menu, "(Vote already in progress)", "DefaultVotes.as", "void _CloseMenu()");
		Menu::addSeparator(menu);
		
		return;
	}
	
	//not in game long enough
	if(g_lastVoteCounter < _required_time &&
		!(getLocalPlayer() !is null && (getLocalPlayer().isMod() ||
			getSecurity().checkAccess_Feature( getLocalPlayer(), "skip_votewait") )) )
	{
		if(!g_haveStartedVote)
		{
			Menu::addInfoBox(menu, "Can't Start Vote Yet", "Voting is only available after\n"+
															"at least "+_required_minutes+" min of play to\n"+
															"prevent spamming/abuse.\n");
		}
		else
		{
			Menu::addInfoBox(menu, "Can't Start Vote", "Voting requires a wait\n"+
														"after each casted vote to\n"+
														"prevent spamming/abuse.\n");	
		}
		Menu::addSeparator(menu);
		
		return;
	}
	
	//and advance context menu when clicked
	CContextMenu@ votemenu = Menu::addContextMenu(menu, "Vote");
	
	//add separator afterwards
	Menu::addSeparator(menu);
	
	//vote options menu
	CContextMenu@ kickmenu = Menu::addContextMenu(votemenu, "Kick");
	CContextMenu@ mapmenu = Menu::addContextMenu(votemenu, "Sudden Death!");
	//CContextMenu@ freebuildingmenu = Menu::addContextMenu(votemenu, "Switch free building mode");
	Menu::addSeparator(votemenu); //before the back button
	
	//kick menu
	Menu::addInfoBox(kickmenu, "Vote Kick", "Vote to kick a player on your team\nout of the game.\n\n"+
											"- use responsibly\n"+
											"- report any abuse of this feature.\n"+
											"\nTo Use:\n\n"+
											"- select a reason from the\n     list (default is griefing).\n"+
											"- select a name from the list.\n"+
											"- everyone votes.\n"+
											"- be careful, if your vote\n     fails conclusively,\n     YOU WILL BE KICKED.");
	
	Menu::addSeparator(kickmenu);
	
	//reasons
	for(uint i = 0 ; i < kick_reason_count; ++i)
	{
		CBitStream params;
		params.write_u8(i);
		Menu::addContextItemWithParams(kickmenu, kick_reason_string[i], "DefaultVotes.as", "Callback_KickReason", params);
	}
	
	Menu::addSeparator(kickmenu);
	
	//write all players on our team
	int playerscount = getPlayersCount();
	int SPECTATOR_TEAM = this.getSpectatorTeamNum();
	bool added = false;
	for(int i = 0; i < playerscount; ++i)
	{
		CPlayer@ _player = getPlayer(i);
		
		if(_player is p) continue; //don't display ourself for kicking
		
		int _player_team = _player.getTeamNum();
		if( ( _player_team == p_team || _player_team == SPECTATOR_TEAM ) &&
			( !getSecurity().checkAccess_Feature( _player, "kick_immunity" ) ) )
		{
			string descriptor = _player.getCharacterName();

			if( _player.getUsername() != _player.getCharacterName() )
			{
				descriptor += " ("+_player.getUsername()+")";
			}

			string item = "Kick "+descriptor;

			CContextMenu@ _usermenu = Menu::addContextMenu(kickmenu, item);

			Menu::addInfoBox(_usermenu, "Kicking "+descriptor, "Make sure you're voting to kick\nthe person you meant.\n");

			Menu::addSeparator(_usermenu);

			CBitStream params;
			params.write_u16(_player.getNetworkID());

			Menu::addContextItemWithParams(_usermenu, "Yes, I'm sure", "DefaultVotes.as", "Callback_Kick", params);
			added = true;

			Menu::addSeparator(_usermenu);
		}
	}
	
	if(!added)
	{
		Menu::addContextItem(kickmenu, "(No-one available)", "DefaultVotes.as", "void _CloseMenu()");
	}
	
	Menu::addSeparator(kickmenu);
	
	//nextmap menu
	CMap@ map = getMap();
	CBlob@[] cores;
	getBlobsByTag( "mothership", @cores );
	f32 coresTime = 2.5f * ( cores.length - 2 ) * 30 * 60;
	f32 mapFactor = Maths::Min( 1.0f, Maths::Sqrt( map.tilemapwidth * map.tilemapheight ) / 300.0f );
	u32 minTime = Maths::Max( 0, Maths::Round( BaseEnableTimeSuddenDeath * mapFactor + coresTime ) - getGameTime() );
	u32 coolDown = Maths::Max( 0, suddenDeathVoteCooldown - ( getGameTime() - this.get_s32( "lastSDVote" ) ) );
	
	u32 timeToEnable = minTime + coolDown;
	bool whirlpool = this.get_bool( "whirlpool" );
	
	string desc = "Match taking too long? Vote for Sudden Death!\n";
	if ( whirlpool )
		desc = "Sudden Death is already active!";
	else if ( timeToEnable > 0 )
		desc += timeToEnable > 30*60 ? ( "Time left to enable: " + ( 1 + timeToEnable/30/60 ) +  " minute(s)." ) : ( "Time left to enable: " + timeToEnable/30 + " second(s)." );
		
	Menu::addInfoBox(mapmenu, "Vote Sudden Death", desc );

	if ( timeToEnable == 0 && !whirlpool )
	{
		Menu::addSeparator(mapmenu);
		//reason
		CBitStream params;
		params.write_u8(1);
		Menu::addContextItemWithParams(mapmenu, "Speed things up!", "ShiprektVotes.as", "Callback_NextMap", params);
		
		Menu::addSeparator(mapmenu);
	}
	
	//vote free building mode
	u32 coolDownFb = Maths::Max( 0, freeBuildCooldown - ( getGameTime() - this.get_s32( "lastFBVote" ) ) );
	
	bool freebuildstate = this.get_bool( "freebuild" );
	
	string nameFb = "Enable Free building mode\n";
	if (freebuildstate) nameFb = "Disable Free building mode\n";
	
	string descFb = "Vote to switch the free building mode.";
	if ( coolDownFb > 0 ) 
	{
		descFb = coolDownFb > 30*60 ? ( "Time left to switch again: " + ( 1 + coolDownFb/30/60 ) +  " minute(s)." ) : ( "Time left to switch again: " + coolDownFb/30 + " second(s)." );
	}
	
	/*
	Menu::addInfoBox(freebuildingmenu, nameFb, descFb );

	if ( coolDownFb == 0 )
	{
		Menu::addSeparator(freebuildingmenu);
		//reason
		CBitStream params;
		params.write_u8(1);
		Menu::addContextItemWithParams(freebuildingmenu, "Yes", "ShiprektVotes.as", "Callback_FreeBuilding", params);
		
		Menu::addSeparator(freebuildingmenu);
	}
	*/
}

void _CloseMenu()
{
	Menu::CloseAllMenus();
}

void onPlayerStartedVote()
{
	g_lastVoteCounter /= 2;
	g_haveStartedVote = true;
}

void Callback_KickReason(CBitStream@ params)
{
	u8 id; if(!params.saferead_u8(id)) return;
	
	if(id < kick_reason_count)
	{
		g_kick_reason = kick_reason_string[id];
	}
}

void Callback_Kick(CBitStream@ params)
{
	_CloseMenu(); //definitely close the menu
	
	CPlayer@ p = getLocalPlayer();
	if(p is null) return;
	
	u16 id; if(!params.saferead_u16(id)) return;
	
	CPlayer@ other_player = getPlayerByNetworkId(id);
	
	if(other_player is null) return;
	
	StartVoteKick(other_player, p, g_kick_reason);
	onPlayerStartedVote();
}


void Callback_NextMap(CBitStream@ params)
{
	_CloseMenu(); //definitely close the menu
	
	CPlayer@ p = getLocalPlayer();
	if(p is null) return;
	
	u8 id; if(!params.saferead_u8(id)) return;
	
	string reason = "";
	if(id < nextmap_reason_count)
	{
		reason = nextmap_reason_string[id];
	}
	
	StartVoteNextMap(p, "Speed things up!");
	onPlayerStartedVote();
}

void Callback_FreeBuilding(CBitStream@ params)
{
	_CloseMenu(); //definitely close the menu
	
	CPlayer@ p = getLocalPlayer();
	if(p is null) return;
	
	u8 id; if(!params.saferead_u8(id)) return;
	
	StartVoteFreeBuilding(p, "For fun!");
	onPlayerStartedVote();
}

//ban a player if they leave
void onPlayerLeave( CRules@ this, CPlayer@ player )
{
	if(Rules_AlreadyHasVote(this)) //vote is still going
	{
		VoteObject@ vote = Rules_getVote(this);	

		//is it a votekick functor?
		{
			VoteKickFunctor@ f = cast<VoteKickFunctor@>(vote.onvotepassed);
			if(f !is null)
			{
				CPlayer@ kickplayer = getPlayerByNetworkId(f.playerid);
				if(kickplayer is player)
				{
					client_AddToChat( kickplayer.getUsername()+" left early, acting as if they were kicked.", vote_message_colour() );
					BanPlayer(player, VoteKickTime);
				}
			}
		}
	}
	if (getPlayersCount() == 0) {
		this.set_bool( "freebuild", false );
	}
}

