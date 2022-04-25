#define SERVER_ONLY
#include "ShipsCommon.as"

const string PLAYER_BLOB = "human";
const string SPAWN_TAG = "mothership";

const u32 standardRespawnTime = 7 * getTicksASecond();
const u32 specToTeamRespawnTime = 10 * getTicksASecond();

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
    onRestart(this);
}

void onReload(CRules@ this)
{
    this.clear("respawns");
	const u8 specNum = this.getSpectatorTeamNum();
	const u8 plyCount = getPlayerCount();
    for (u8 i = 0; i < plyCount; i++)
    {
        CPlayer@ player = getPlayer(i);
        if (player.getBlob() is null && player.getTeamNum() != specNum)
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
	
	CPlayer@[] players;
	const u8 specNum = this.getSpectatorTeamNum();
	const u8 plyCount = getPlayerCount();
	for (u8 i = 0; i < plyCount; i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player.getTeamNum() != specNum)
		{
			players.push_back(player);
			
			//spawn players!
			Respawn r(player.getUsername(), getGameTime());
			this.push("respawns", r);
			syncRespawnTime(this, player, getGameTime());
		}
	}
	
	//assign player teams
	assignTeams(this, players);
}

void assignTeams(CRules@ this, CPlayer@[] players)
{
	//equally distribute players
	
	CBlob@[] cores;
    getBlobsByTag(SPAWN_TAG, cores); //get available teams for the map
	const u8 coresLength = cores.length;
	u8 currentTeam = XORRandom(coresLength);
	
	while (!players.isEmpty())
	{
		u8 randPlayer = XORRandom(players.length); //randomize selection
		CPlayer@ player = players[randPlayer];
		
		//print("assignTeams: assigning " + player.getUsername() +" "+cores[currentTeam].getTeamNum());
		player.server_setTeamNum(cores[currentTeam].getTeamNum());
		
		if (currentTeam + 2 > coresLength)
			currentTeam = 0;
		else currentTeam++;
		
		players.removeAt(randPlayer);
	}
}

void assignTeam(CRules@ this, CPlayer@ player)
{
	//finds the team with the lowest amount of players
	//TODO: prioritize assignment to teams with less booty over rich teams when teams have equal playercount
	
	const u8 teamsNum = this.getTeamsNum();
    int[] playersperteam(teamsNum);

    //gather the per team player counts
	const u8 plyCount = getPlayersCount();
    for (u8 i = 0; i < plyCount; i++)
    {
        CPlayer@ p = getPlayer(i);
        s32 pteam = p.getTeamNum();
        if (pteam >= 0 && pteam < teamsNum)
            playersperteam[pteam]++;
    }
	
	 //calc the minimum player count, dequalify teams
    int minplayers = 1000;
    for (u8 i = 0; i < teamsNum; i++)
    {
        if (playersperteam[i] < -1 || getMothership(i) is null)
            playersperteam[i] += 500;
        minplayers = Maths::Min(playersperteam[i], minplayers);
    }
	
    //choose a random team with minimum player count
    u8 team;
    do
        team = XORRandom(teamsNum);
    while (playersperteam[team] > minplayers);

	player.server_setTeamNum(team);
}

void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{
	if (!isRespawnAdded(this, player.getUsername()) && player.getTeamNum() != this.getSpectatorTeamNum())
	{
    	Respawn r(player.getUsername(), standardRespawnTime + getGameTime());
    	this.push("respawns", r);
    	syncRespawnTime(this, player, standardRespawnTime + getGameTime());
    }
}

void onTick(CRules@ this)
{
	const u32 gametime = getGameTime();
	if (!this.isGameOver() && gametime % 30 == 0)
	{
		Respawn[]@ respawns;
		if (this.get("respawns", @respawns))
		{
			for (u8 i = 0; i < respawns.length; i++)
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
	}
}

CBlob@ SpawnPlayer(CRules@ this, CPlayer@ player)
{
    if (player is null)
		return null;
	
	// remove previous players blob
	CBlob@ blob = player.getBlob();		   
	if (blob !is null)
	{
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
	{
		CBlob@ shark = server_CreateBlob("shark", this.getSpectatorTeamNum(), getSpawnPosition(player.getTeamNum()));
		if (shark !is null)
		{
			shark.server_SetPlayer(player);
			//player.server_setTeamNum(this.getSpectatorTeamNum());
		}
		return shark;
	}

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

bool isRespawnAdded(CRules@ this, const string username)
{
	Respawn[]@ respawns;
	if (this.get("respawns", @respawns))
	{
		const u8 respawnLength = respawns.length;
		for (u8 i = 0; i < respawnLength; i++)
		{
			Respawn@ r = respawns[i];
			if (r.username == username)
				return true;
		}
	}
	return false;
}

Vec2f getSpawnPosition(const u8 team)
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

void onPlayerRequestTeamChange(CRules@ this, CPlayer@ player, u8 newteam)
{
    CBlob@ blob = player.getBlob();
	if (blob !is null)
        blob.server_Die();
	
	const u8 specNum = this.getSpectatorTeamNum();
	u8 old_team = player.getTeamNum();
	
	player.server_setTeamNum(newteam);
	if (newteam != specNum)
	{
		if (old_team == specNum)
		{
			Respawn r(player.getUsername(), specToTeamRespawnTime + getGameTime());
	    	this.push("respawns", r);
	    	syncRespawnTime(this, player, specToTeamRespawnTime + getGameTime());
			return;
		}
		onPlayerRequestSpawn(this, player);
	}
}

void syncRespawnTime(CRules@ this, CPlayer@ player, u32 time)
{
	CBitStream params;
	params.write_u32(time);
	this.SendCommand(this.getCommandID("sync respawn time"), params, player);
}
