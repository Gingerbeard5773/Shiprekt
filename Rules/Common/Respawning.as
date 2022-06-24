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
	const u32 gameTime = getGameTime();
	const u8 specNum = this.getSpectatorTeamNum();
	const u8 plyCount = getPlayerCount();
	for (u8 i = 0; i < plyCount; i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player.getBlob() is null && player.getTeamNum() != specNum)
		{
			Respawn r(player.getUsername(), gameTime);
			this.push("respawns", r);
			syncRespawnTime(this, player, gameTime);
		}
	}
}

void onRestart(CRules@ this)
{
	this.clear("respawns");
	
	CPlayer@[] players;
	const u32 gameTime = getGameTime();
	const u8 specNum = this.getSpectatorTeamNum();
	const u8 plyCount = getPlayerCount();
	for (u8 i = 0; i < plyCount; i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player.getTeamNum() != specNum)
		{
			players.push_back(player);
			
			//spawn players!
			Respawn r(player.getUsername(), gameTime);
			this.push("respawns", r);
			syncRespawnTime(this, player, gameTime);
		}
	}
	
	//assign player teams
	if (players.length > 0)
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
		const u8 randPlayer = XORRandom(players.length); //randomize selection
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
	u8[] playersperteam(teamsNum);

	//gather the per team player counts
	const u8 plyCount = getPlayersCount();
	for (u8 i = 0; i < plyCount; i++)
	{
		CPlayer@ p = getPlayer(i);
		if (p is null) continue;
		
		const u8 pteam = p.getTeamNum();
		if (pteam < teamsNum)
			playersperteam[pteam]++;
	}
	
	//calc the minimum player count, dequalify teams
	u8 minplayers = 255; //set as the max of u8
	for (u8 i = 0; i < teamsNum; i++)
	{
		if (getMothership(i) is null)
			playersperteam[i] = 255; //disqualify since team is dead
			
		minplayers = Maths::Min(playersperteam[i], minplayers); //set minimum
	}
	
	if (minplayers == 255) return;
	
	//choose a random team with minimum player count
	u8 team;
	do
		team = XORRandom(teamsNum);
	while (playersperteam[team] > minplayers); //theoretically could loop infinitely

	player.server_setTeamNum(team);
}

void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{
	if (!isRespawnAdded(this, player.getUsername()) && player.getTeamNum() != this.getSpectatorTeamNum())
	{
		const u32 gametime = getGameTime();
		Respawn r(player.getUsername(), standardRespawnTime + gametime);
		this.push("respawns", r);
		syncRespawnTime(this, player, standardRespawnTime + gametime);
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
	if (getMothership(player.getTeamNum()) is null)
	{
		//reassign to a team with alive core
		assignTeam(this, player);
		//print("SpawnPlayer: reassigning " + player.getUsername() +"to team "+player.getTeamNum());
	}
	
	const u8 newteam = player.getTeamNum();
	CBlob@ newship = getMothership(newteam);
		
	// spawn as shark if cant find a ship
	if (newship is null)
	{
		CBlob@ shark = server_CreateBlob("shark", this.getSpectatorTeamNum(), getSpawnPosition(player.getTeamNum()));
		if (shark !is null)
		{
			shark.server_SetPlayer(player);
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

bool isRespawnAdded(CRules@ this, const string&in username)
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

Vec2f getSpawnPosition(const u8&in team)
{
	CMap@ map = getMap();
	
	Vec2f[] spawns;
	if (map.getMarkers("spawn", spawns))
	{
		if (team >= 0 && team < spawns.length)
			return spawns[team];
	}
	return map.getMapDimensions() / 2;
}

void onPlayerRequestTeamChange(CRules@ this, CPlayer@ player, u8 newteam)
{
	CBlob@ blob = player.getBlob();
	if (blob !is null)
		blob.server_Die();
	
	const u8 specNum = this.getSpectatorTeamNum();
	const u8 old_team = player.getTeamNum();
	
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

void syncRespawnTime(CRules@ this, CPlayer@ player, const u32&in time)
{
	CBitStream params;
	params.write_u32(time);
	this.SendCommand(this.getCommandID("sync respawn time"), params, player);
}
