#define SERVER_ONLY
#include "IslandsCommon.as"

const string PLAYER_BLOB = "human";
const string SPAWN_TAG = "mothership";

bool oneTeamLeft = false;

shared class Respawn
{
	string username;
	u32 timeStarted;

	Respawn( const string _username, const u32 _timeStarted ){
		username = _username;
		timeStarted = _timeStarted;
	}
};

s32 getRandomMinimumTeam(CRules@ this, const int atLeast = -1)
{
    const int teamsCount = this.getTeamsNum();
    int[] playersperteam;
    for (int i = 0; i < teamsCount; i++)
	{
        playersperteam.push_back(0);
	}

    //gather the per team player counts
    const int playersCount = getPlayersCount();
    for (int i = 0; i < playersCount; i++)
    {
        CPlayer@ p = getPlayer(i);
        s32 pteam = p.getTeamNum();
        if (pteam >= 0 && pteam < teamsCount)
            playersperteam[pteam]++;
    }

    //calc the minimum player count, dequalify teams
    int minplayers = 1000;
    for (int i = 0; i < teamsCount; i++)
    {
        if (playersperteam[i] < atLeast || getMothership(i) is null)
            playersperteam[i] += 500;
        minplayers = Maths::Min(playersperteam[i], minplayers);
    }
	
    //choose a random team with minimum player count
    s32 team;
    do
        team = XORRandom(teamsCount);
    while(playersperteam[team] > minplayers);

	//print( "ret Team : " + team );
    return team;
}

void onInit(CRules@ this)
{
	Respawn[] respawns;
	this.set("respawns", respawns);
	this.set_u8( "endCount", 0 );
    onRestart(this);
}

void onReload(CRules@ this)
{
    this.clear("respawns"); 
	this.set_u8("endCount", 0);	
    for (int i = 0; i < getPlayerCount(); i++)
    {
        CPlayer@ player = getPlayer(i);
        if (player.getTeamNum() == this.getSpectatorTeamNum())
			player.server_setTeamNum( this.getSpectatorTeamNum());
        else if (player.getBlob() is null)
        {
            Respawn r(player.getUsername(), getGameTime());
            this.push("respawns", r);
        }
    }
}

void onRestart(CRules@ this)
{
	this.clear("respawns");
	this.set_u8( "endCount", 0 );
	//assign teams
    for (int i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player.getTeamNum() == this.getSpectatorTeamNum())
			player.server_setTeamNum( this.getSpectatorTeamNum());
		else
		{
			//print ( "onRestart: assigning " + player.getUsername() );
			player.server_setTeamNum(getRandomMinimumTeam(this));
			Respawn r(player.getUsername(), getGameTime());
			this.push("respawns", r);
		}
	}

    this.SetCurrentState(GAME);
    //this.SetGlobalMessage("");
}

void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{
	if (!isRespawnAdded( this, player.getUsername()) && player.getTeamNum() != this.getSpectatorTeamNum())
	{
    	Respawn r(player.getUsername(), getGameTime());
    	this.push("respawns", r);
    }
}

void onTick(CRules@ this)
{
	const u32 gametime = getGameTime();
	if (this.isMatchRunning() && gametime % 30 == 0)
	{
		Respawn[]@ respawns;
		if (this.get("respawns", @respawns))
		{
			for (uint i = 0; i < respawns.length; i++)
			{
				Respawn@ r = respawns[i];
				if (r.timeStarted == 0 || r.timeStarted + this.playerrespawn_seconds*getTicksASecond() <= gametime)
				{
					SpawnPlayer( this, getPlayerByUsername( r.username ));
					respawns.erase(i);
					i = 0;
				}
			}
		}

        CBlob@[] cores;
        getBlobsByTag(SPAWN_TAG, cores);
		
        oneTeamLeft = (cores.length <= 1);
		u8 endCount = this.get_u8("endCount");
		
		if (oneTeamLeft && endCount == 0)//start endmatch countdown
			this.set_u8("endCount", 5);
		
		if (endCount != 0)
		{
			this.set_u8("endCount", endCount - 1);
			if (endCount == 1)
			{
				u8 teamWithPlayers = 0;
				if (!this.isGameOver())
				{
					for (uint coreIt = 0; coreIt < cores.length; coreIt++)
					{
						for (int i = 0; i < getPlayerCount(); i++)
						{
							CPlayer@ player = getPlayer(i);
							if ( player.getBlob() !is null )
								teamWithPlayers = player.getTeamNum();
						}
					}
				}
				u8 coresAlive = 0;
				for (int i = 0; i < cores.length; i++)
				{
					if (!cores[i].hasTag("critical"))
					coresAlive++;
				}

				if (coresAlive > 0)
				{
					string captain = "";
					CBlob@ mShip = getMothership(teamWithPlayers);
					if (mShip !is null)
					{
						Island@ isle = getIsland(mShip.getShape().getVars().customData);
						if (isle !is null && isle.owner != "" && isle.owner != "*")
						{
							string lastChar = isle.owner.substr(isle.owner.length() -1);
							captain = isle.owner + (lastChar == "s" ? "' " : "'s ");
						}
						this.SetGlobalMessage(captain + this.getTeam(mShip.getTeamNum()).getName() + " Wins!");
					}
				}
				else
					this.SetGlobalMessage("Game Over! It's a tie!");
				
				this.SetCurrentState(GAME_OVER);
			}
        }
        else
            this.SetGlobalMessage("");
	}
}

CBlob@ SpawnPlayer(CRules@ this, CPlayer@ player)
{
    if (player !is null)
    {
        // remove previous players blob
        CBlob @blob = player.getBlob();		   
        if (blob !is null)
        {
            CBlob @blob = player.getBlob();
            blob.server_SetPlayer(null);
            blob.server_Die();
        }

        const u8 teamsCount = this.getTeamsNum();
		u8 team = player.getTeamNum();
        team = team > 32 ? getRandomMinimumTeam(this) : team;
        player.server_setTeamNum(team);
    
		//player mothership got destroyed
        CBlob@ ship = getMothership(team);
        if (ship is null)
        {
			//print ( "SpawnPlayer: reasigning " + player.getUsername() );
			//reasign to a team with alive core
        	team = getRandomMinimumTeam(this);
        	@ship = getMothership(team);
        	int count = 0;
        	while (ship is null && count <= 3*teamsCount)
        	{
        		team = getRandomMinimumTeam(this, count%teamsCount);
        		@ship = getMothership(team);
        		count++;
        	}

        	// spawn as shark if cant find a ship
        	if (ship is null)
	            return SpawnAsShark(this, player);
        	else
        		player.server_setTeamNum(team);
        }

		CBlob@ newBlob = server_CreateBlobNoInit( PLAYER_BLOB );
		if (newBlob !is null)
		{
			newBlob.server_SetPlayer(player);
			newBlob.server_setTeamNum(team);
			newBlob.setPosition(ship.getPosition());
			newBlob.Init();
		}
		
        return newBlob;        
    }

    return null;
}

bool isRespawnAdded(CRules@ this, const string username)
{
	Respawn[]@ respawns;
	if (this.get("respawns", @respawns))
	{
		for (uint i = 0; i < respawns.length; i++)
		{
			Respawn@ r = respawns[i];
			if (r.username == username)
				return true;
		}
	}
	return false;
}

Vec2f getSpawnPosition(const uint team)
{
    Vec2f[] spawns;			 
    if (getMap().getMarkers("spawn", spawns))
	{
    	if (team >= 0 && team < spawns.length)
    		return spawns[team];
    }
    CMap@ map = getMap();
    return Vec2f(map.tilesize*map.tilemapwidth/2, map.tilesize*map.tilemapheight/2);
}

CBlob@ SpawnAsShark(CRules@ this, CPlayer@ player)
{
    CBlob @shark = server_CreateBlob("shark", this.getSpectatorTeamNum(), getSpawnPosition(player.getTeamNum()));
    if (shark !is null)
	{
        shark.server_SetPlayer(player);
    }
    return shark;
}

void onPlayerRequestTeamChange(CRules@ this, CPlayer@ player, u8 newteam)
{
    CBlob@ blob = player.getBlob();
	if (blob !is null)
        blob.server_Die();
	
	if (newteam == 44)//request from Block.as
		return;
	
	if (player.isMod())
	{
		player.server_setTeamNum(newteam);
		if (newteam != this.getSpectatorTeamNum())
			onPlayerRequestSpawn(this, player);
	}
	else if (newteam == this.getSpectatorTeamNum())
    {
        if (blob !is null && blob.getName() == "human")
            SpawnAsShark(this, player);
    }
}

bool allPlayersInOneTeam(CRules@ this)
{
    if (getPlayerCount() <= 1)
        return false;
    int team = -1;
	u16 specTeam = this.getSpectatorTeamNum();
    for (int i = 0; i < getPlayerCount(); i++)
    {
        CPlayer@ player = getPlayer(i);
        if (i == 0)
            team = player.getTeamNum();
        else if (team != player.getTeamNum() && player.getTeamNum() != specTeam)
            return false;
    }

    return true;
}
