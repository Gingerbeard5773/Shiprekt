#define SERVER_ONLY
#include "ShipsCommon.as"

const string PLAYER_BLOB = "human";
const string SPAWN_TAG = "mothership";

const u32 standartRespawnTime = 7.5f*getTicksASecond();
const u32 specToTeamRespawnTime = 10.0f*getTicksASecond(); // one minute

bool oneTeamLeft = false;

shared class Respawn
{
	string username;
	u32 timeStarted;

	Respawn(const string _username, const u32 _timeStarted)
	{
		username = _username;
		timeStarted = _timeStarted;
	}
};

void onInit(CRules@ this)
{
	Respawn[] respawns;
	this.set("respawns", respawns);
	this.set_u8("endCount", 0);
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
			player.server_setTeamNum(this.getSpectatorTeamNum());
        else if (player.getBlob() is null)
        {
            Respawn r(player.getUsername(), getGameTime());
            this.push("respawns", r);
            syncRespawnTime(this, player, getGameTime());
        }
    }
}

void onRestart(CRules@ this)
{
	this.clear("respawns");
	this.set_u8("endCount", 0);
	
	CPlayer@[] players;
	for (int i = 0; i < getPlayerCount(); i++)
	{
		//assign player teams
		CPlayer@ player = getPlayer(i);
		players.push_back(player);
		
		//spawn players!
		Respawn r(player.getUsername(), getGameTime());
		this.push("respawns", r);
		syncRespawnTime(this, player, getGameTime());
	}
	assignTeams(this, players); 

    this.SetCurrentState(GAME);
    //this.SetGlobalMessage("");
}

void assignTeams(CRules@ this, CPlayer@[] players)
{
	//equally distribute players
	
	CBlob@[] cores;
    getBlobsByTag(SPAWN_TAG, cores); //get available teams for the map
	u8 currentTeam = XORRandom(cores.length);
	
	while (!players.isEmpty())
	{
		int randPlayer = XORRandom(players.length); //randomize selection
		CPlayer@ player = players[randPlayer];
		
		if (player.getTeamNum() != this.getSpectatorTeamNum())
		{
			//print("assignTeams: assigning " + player.getUsername() +" "+cores[currentTeam].getTeamNum());
			player.server_setTeamNum(cores[currentTeam].getTeamNum());
			
			if (currentTeam + 2 > cores.length)
				currentTeam = 0;
			else currentTeam++;
		}
		players.removeAt(randPlayer);
	}
}

void assignTeam(CRules@ this, CPlayer@ player)
{
	//finds the team with the lowest amount of players
	
    int[] playersperteam(this.getTeamsNum());

    //gather the per team player counts
    for (int i = 0; i < getPlayersCount(); i++)
    {
        CPlayer@ p = getPlayer(i);
        s32 pteam = p.getTeamNum();
        if (pteam >= 0 && pteam < playersperteam.length)
            playersperteam[pteam]++;
    }
	
	 //calc the minimum player count, dequalify teams
    int minplayers = 1000;
    for (int i = 0; i < playersperteam.length; i++)
    {
        if (playersperteam[i] < -1 || getMothership(i) is null)
            playersperteam[i] += 500;
        minplayers = Maths::Min(playersperteam[i], minplayers);
    }
	
    //choose a random team with minimum player count
    s32 team;
    do
        team = XORRandom(playersperteam.length);
    while (playersperteam[team] > minplayers);

	player.server_setTeamNum(team);
}

void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{
	if (!isRespawnAdded(this, player.getUsername()) && player.getTeamNum() != this.getSpectatorTeamNum())
	{
    	Respawn r(player.getUsername(), standartRespawnTime + getGameTime());
    	this.push("respawns", r);
    	syncRespawnTime(this, player, standartRespawnTime + getGameTime());
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
				if (r.timeStarted == 0 || r.timeStarted <= gametime)
				{
					SpawnPlayer(this, getPlayerByUsername(r.username));
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
							if (player.getBlob() !is null)
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
						Ship@ ship = getShip(mShip.getShape().getVars().customData);
						if (ship !is null && ship.owner != "" && ship.owner != "*")
						{
							string lastChar = ship.owner.substr(ship.owner.length() -1);
							captain = ship.owner + (lastChar == "s" ? "' " : "'s ");
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
		
		//player mothership got destroyed or joining player
        CBlob@ ship = getMothership(player.getTeamNum());
        if (ship is null)
        {
			//reassign to a team with alive core
        	assignTeam(this, player);
			//print("SpawnPlayer: reassigning " + player.getUsername() +"to team "+player.getTeamNum());
        }
		
		u8 newteam = player.getTeamNum();
		CBlob@ newship = getMothership(newteam);
			
		// spawn as shark if cant find a ship
		if (newship is null)
			return SpawnAsShark(this, player);

		CBlob@ newBlob = server_CreateBlobNoInit(PLAYER_BLOB);
		if (newBlob !is null)
		{
			newBlob.server_SetPlayer(player);
			newBlob.server_setTeamNum(newteam);
			newBlob.setPosition(newship.getPosition());
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
		//player.server_setTeamNum(this.getSpectatorTeamNum());
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

	u8 old_team = player.getTeamNum();

	player.server_setTeamNum(newteam);
	if (newteam != this.getSpectatorTeamNum())
	{
		if (old_team == this.getSpectatorTeamNum() && !player.isMod())
		{
			Respawn r(player.getUsername(), specToTeamRespawnTime + getGameTime());
	    	this.push("respawns", r);
	    	syncRespawnTime(this, player, specToTeamRespawnTime + getGameTime());
			return;
		}
		onPlayerRequestSpawn(this, player);
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

void syncRespawnTime(CRules@ this, CPlayer@ player, u32 time)
{
	CBitStream params;
	params.write_u32(time);
	this.SendCommand(this.getCommandID("sync respawn time"), params, player);
}
