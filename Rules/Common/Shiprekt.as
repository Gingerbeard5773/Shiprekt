#define SERVER_ONLY
#include "Booty.as";
#include "IslandsCommon.as";
#include "MakeBlock.as";

const u16 STATION_BOOTY = 4;
const u16 MINI_STATION_BOOTY = 1;

void onInit(CRules@ this)
{
	this.set_bool("whirlpool", false);
	setStartingBooty(this);
	server_resetTotalBooty(this); 
}

void onTick(CRules@ this)
{
	u32 gameTime = getGameTime();
	//check for minimum resources on captains
	if (gameTime % 150 == 0 && !this.get_bool("whirlpool"))
	{
		u16 minBooty = this.get_u16("bootyRefillLimit");
		CBlob@[] cores;
		getBlobsByTag("mothership", @cores);
		for (u8 i = 0; i < cores.length; i++)
		{
			Island@ isle = getIsland(cores[i].getShape().getVars().customData);
			if (isle !is null && isle.owner != "" && isle.owner  != "*")
			{
				u16 captainBooty = server_getPlayerBooty(isle.owner);
				if (captainBooty < minBooty)
				{
					CPlayer@ player = getPlayerByUsername(isle.owner);
					if (player is null) continue;
					
					//consider blocks to propellers ratio
					int propellers = 1;
					int couplings = 0;
					for (uint b_iter = 0; b_iter < isle.blocks.length; ++b_iter )
					{
						CBlob@ b = getBlobByNetworkID(isle.blocks[b_iter].blobID);
						if (b !is null)
							if (b.hasTag("engine"))
								propellers++;
							else if (b.hasTag("coupling"))
								couplings++;
					}

					if (((isle.blocks.length - propellers - couplings)/propellers > 3) || gameTime < this.get_u16("warmup_time"))
					{
						CBlob@ pBlob = player.getBlob();
						CBlob@[]@ blocks;
						if (pBlob !is null && pBlob.get("blocks", @blocks) && blocks.size() == 0)
							server_addPlayerBooty(isle.owner, Maths::Min(15, minBooty - captainBooty));
					}
				}				
			}
		}
		
		for (int i = 0; i < getPlayersCount(); ++i)
		{
			CPlayer@ player = getPlayer(i);
			u8 pteam = player.getTeamNum();
			if (player is null)	
				continue;
			
			u16 pStationCount = 0;
			u16 pMiniStationCount = 0;
			CBlob@[] stations;
			CBlob@[] ministations;
			getBlobsByTag("station", @stations);
			getBlobsByTag("ministation", @ministations);
			for (u8 u = 0; u < stations.length; u++)
			{
				CBlob@ station = stations[u];
				if (station is null)
					continue;
			
				if (stations[u].getTeamNum() == pteam)
					pStationCount++;
			}
			
			for (u8 u = 0; u < ministations.length; u++)
			{
				CBlob@ ministation = ministations[u];
				if (ministation is null)
					continue;
			
				if (ministations[u].getTeamNum() == pteam )
					pMiniStationCount++;
			}
			
			CBlob@ pBlob = player.getBlob();
			if (pBlob !is null)
			{
				server_addPlayerBooty(player.getUsername(), (STATION_BOOTY * pStationCount) + (MINI_STATION_BOOTY * pMiniStationCount));
				server_updateTotalBooty(pteam, (STATION_BOOTY * pStationCount) + (MINI_STATION_BOOTY * pMiniStationCount));
			}
		}
	}
	
	//after some secs, balance starting booty for teams with less players than the average
	if (gameTime == 500)
	{
		CBlob@[] cores;
		getBlobsByTag("mothership", @cores);
		u8 teams = cores.length;
		u16 initBooty = Maths::Round(getRules().get_u16("starting_booty") * 0.75f);
		u8 players = getPlayersCount();
		u8 median = Maths::Round(players/teams);
		//player per team
		u8[] teamPlayers;
		for (u8 t = 0; t < 16; t++)
			teamPlayers.push_back(0);
		
		for (u8 p = 0; p < players; p++)
		{
			u8 team = getPlayer(p).getTeamNum();
			if (team < teamPlayers.length)
				teamPlayers[team]++;
		}
		
		print("** Balancing booty: median = " + median + " for " + players + " players in " + teams + " teams");
		//balance booty
		for (u8 p = 0; p < players; p++)
		{
			CPlayer@ player = getPlayer(p);
			u8 team = player.getTeamNum();
			if (team >= teamPlayers.length) continue;
				
			f32 compensate = median/teamPlayers[team];
			if (compensate > 1)
			{
				u16 balance = Maths::Round(initBooty * compensate/teamPlayers[team] - initBooty);
				string name = player.getUsername();
				server_setPlayerBooty(name, balance);
			}
		}
	}
}

void onRestart(CRules@ this)
{
	setStartingBooty(this);
	server_resetTotalBooty(this);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	string pName = player.getUsername();

	u16 pBooty = server_getPlayerBooty(pName);
	u16 minBooty = Maths::Round(this.get_u16("bootyRefillLimit") / 2);
	if (sv_test)
		server_setPlayerBooty(pName, 9999);
	else if (pBooty > minBooty)
	{
		this.set_u16("booty" + pName, pBooty);
		this.Sync("booty" + pName, true);
	}
	else
		server_setPlayerBooty(pName, getGameTime() > this.get_u16("warmup_time") ? minBooty : this.get_u16("starting_booty"));
		
	print("New player joined. New count : " + getPlayersCount());
	if (getPlayersCount() <= 1)
	{
		//print("*** Restarting the map to be fair to the new player ***");
		getNet().server_SendMsg( "*** " + getPlayerCount() + " player(s) in map. Setting freebuild mode until more players join. ***");
		this.set_bool("freebuild", true);
	}
}

bool isSuperAdmin(CPlayer@ player)
{
	return getSecurity().getPlayerSeclev(player).getName().toLower() == "super admin";
}

bool isDev(CPlayer@ player)
{
	//case sensitive
	const string[] devNames = 
	{
		"Mr" + "Ho" + "bo"
	};
	
	for (int i = 0; i < devNames.length; ++i)
	{
		if (player.getUsername() == devNames[i])
			return true;
	}
	return false;
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (player is null) return true;

	//for testing
	if (sv_test || player.isMod() || isDev(player))
	{
		if (text_in.substr(0,1) == "!" )
		{
			string[]@ tokens = text_in.split(" ");

			if (tokens.length > 1)
			{
				CBlob@ pBlob = player.getBlob();
				if (pBlob is null) return false;
				
				if (tokens[0] =="!addbot") //add a bot to the server. Supports names & teams
				{
					if (tokens.length > 2)
						AddBot(tokens[1], parseInt(tokens[2]), 0);
					else
						AddBot(tokens[1]);
					
					return true;
				}
				else if (tokens[0] == "!team")
				{
					if (tokens.length > 2)
					{
						CPlayer@ nameplayer = getPlayerByUsername(tokens[1]);
						if (nameplayer !is null)
						{
							nameplayer.server_setTeamNum(parseInt(tokens[2]));
							if (nameplayer.getBlob() !is null)
								nameplayer.getBlob().server_Die();
						}
					}
					else
					{
						player.server_setTeamNum(parseInt(tokens[1]));
						if (player.getBlob() !is null)
							player.getBlob().server_Die();
					}
					
					return false;
				}
				else if (tokens[0] == "!hash") //gives encoded hash for the word you input
				{
					string word = tokens[1];
					if (tokens.length > 2) word = tokens[1]+" "+tokens[2]; //only supports up to two words
					print(word.getHash() + " : "+ word);
					
					return false;
				}
				else if (tokens[0] == "!tp") //teleport to blob or player, uses blob's ID or player name
				{
					
					CBlob@ b = getBlobByNetworkID(parseInt(tokens[1]));
					CPlayer@ ply = getPlayerByUsername(tokens[1]);
					if (ply !is null)
					{
						@b = ply.getBlob();
					}
					if (b is null) 
					{
						warn("!tp:: Blob not found: "+ tokens[1]);
						return false;
					}
					
					print("Teleported "+player.getUsername()+" to "+b.getName()+" "+b.getNetworkID());
					pBlob.setPosition(b.getPosition()); //teleport to blob!
					return false;
				}
				else if (tokens[0] == "!tphere") //teleport player here, uses playername
				{
					CPlayer@ ply = getPlayerByUsername(tokens[1]);
					if (ply is null) 
					{
						warn("!tphere:: Player not found: "+ tokens[1]);
						return false;
					}
					
					CBlob@ b = ply.getBlob();
					if (b is null) return false;
					
					print("Teleported "+ply.getUsername()+" to "+player.getUsername()+" "+ply.getNetworkID());
					b.setPosition(pBlob.getPosition()); //teleport to blob!
					return false;
				}
				else if (tokens[0] == "!class") //change your player blob (shark etc)
				{
					CBlob@ b = server_CreateBlob(tokens[1], pBlob.getTeamNum(), pBlob.getPosition());
					if (b !is null)
					{
						b.server_SetPlayer(player);
						pBlob.server_Die();
						print("Setting "+player.getUsername()+" to "+tokens[1]);
					}
					return false;
				}
				else if (tokens[0] == "!teamchange") //change your player blobs team without dying
				{
					player.server_setTeamNum(parseInt(tokens[1]));
					pBlob.server_setTeamNum(parseInt(tokens[1]));
				}
				else if (tokens[0] == "!setcorekills") //change your player core kills
				{
					player.setAssists(parseInt(tokens[1]));
				}
				else if (tokens[0] == "!crit") //kill defined mothership
				{
					CBlob@ mothership = getMothership(parseInt(tokens[1]));
					if (mothership !is null)
						mothership.server_Hit(mothership, mothership.getPosition(), Vec2f_zero, 50.0f, 0, true);
				}
				else if (tokens[0] == "!playsound") //play a sound (only works localhost)
				{
					Sound::Play(tokens[1]);
					return false;
				}
				else if (tokens[0] == "!g_debug")
				{
					g_debug = parseInt(tokens[1]);
					print("Setting g_debug to "+tokens[1]);
					return false;
				}
				else if (tokens[0] == "!saveship") //all players can save their ship
				{
					ConfigFile cfg;
					
					CBlob@ pBlob = player.getBlob();
					if (pBlob is null)
						return false;
					
					Vec2f playerPos = pBlob.getPosition();
					Island@ isle = getIsland(player.getBlob());
					int numBlocks = isle.blocks.length;
					cfg.add_u16("total blocks", numBlocks);
					for (uint i = 0; i < numBlocks; ++i)
					{
						IslandBlock@ isle_block = isle.blocks[i];
						if (isle_block is null) continue;

						CBlob@ block = getBlobByNetworkID(isle_block.blobID);
						if (block is null) continue;
						
						cfg.add_string("block" + i + "type", block.getName());
						cfg.add_f32("block" + i + "positionX", (block.getPosition().x - playerPos.x));
						cfg.add_f32("block" + i + "positionY", (block.getPosition().y - playerPos.y));
						cfg.add_f32("block" + i + "angle", block.getAngleDegrees());
					}
					
					cfg.saveFile("SHIP_" + tokens[1] + ".cfg");
				}
				else if (tokens[0] == "!loadship")
				{
					ConfigFile cfg;
					
					if (!cfg.loadFile("../Cache/SHIP_" + tokens[1] + ".cfg"))
						return false;
						
					CBlob@ pBlob = player.getBlob();
					if (pBlob is null)
						return false;
						
					Vec2f playerPos = pBlob.getPosition();
				
					int numBlocks = cfg.read_u16("total blocks");
					for (uint i = 0; i < numBlocks; ++i)
					{	
						string blockType = cfg.read_string("block" + i + "type");
						f32 blockPosX = cfg.read_f32("block" + i + "positionX");
						f32 blockPosY = cfg.read_f32("block" + i + "positionY");
						f32 blockAngle = cfg.read_f32("block" + i + "angle");
						CBlob@ b = makeBlock(playerPos + Vec2f(blockPosX, blockPosY), blockAngle, blockType, pBlob.getTeamNum());
					}
				}
			}
			else
			{
				if (tokens[0] == "!deleteship")
				{
					CBlob@ pBlob = player.getBlob();
					if (pBlob is null)
						return false;
					
					Vec2f playerPos = pBlob.getPosition();
					Island@ isle = getIsland(player.getBlob());
					if (isle !is null)
					{
						int numBlocks = isle.blocks.length;
						if (isServer()) 
						{
							for (uint i = 0; i < numBlocks; ++i)
							{
								IslandBlock@ isle_block = isle.blocks[i];
								if (isle_block is null) continue;

								CBlob@ block = getBlobByNetworkID(isle_block.blobID);
								if (block is null) continue;
								
								if (!block.hasTag("mothership") || numBlocks == 1)
								{
									block.Tag("noCollide");
									block.server_Die();
								}
							}
						}
					}
				}
				else if (tokens[0] == "!clearmap")
				{
					CBlob@[] blocks;
					if (getBlobsByTag("block", @blocks))
					{							
						if (isServer()) 
						{
							for (uint i = 0; i < blocks.length; ++i)
							{
								CBlob@ block = blocks[i];
								if (block is null) continue;
								
								if (!block.hasTag("mothership"))
								{
									block.Tag("noCollide");
									block.server_Die();
								}
								else blocks.erase(i);
							}
						}
						print("Clearing "+blocks.length+" blocks");
					}
					return false;
				}				
				else if (tokens[0] == "!ships")
				{
					CFileMatcher@ files = CFileMatcher("../KAG/player");
					while (files.iterating())
					{
						const string filename = files.getCurrent();
						//string[]@ toks = filename.split("_");
						if (isClient())
						{
							client_AddToChat(filename, SColor(255, 255, 0, 0));
						}
					}
					return false;
				}
				else if (tokens[0] == "!dirty") //activate dirty islands 
				{
					this.set_bool("dirty islands", true);
					return false;
				}
				else if (tokens[0] == "!sv_test")
				{
					sv_test = !sv_test;
					print("Setting sv_test "+ (sv_test ? "on" : "off"));
					return false;
				}
				else if (tokens[0] == "!freebuild") //toggle freebuild mode
				{
					client_AddToChat("Toggled freebuild "+ (this.get_bool("freebuild") ? "off" : "on"),  SColor(255, 255, 255, 0));
					this.set_bool("freebuild", !this.get_bool("freebuild"));
				}
				else if (tokens[0] == "!booty")
				{
					print(player.getUsername()+" cheating for 800 booty, bad!");
					server_addPlayerBooty(player.getUsername(), 800);
					return false;
				}
				else if (tokens[0] == "!sd") //spawn a whirlpool
				{
					CMap@ map = getMap();
					Vec2f mapCenter = Vec2f(map.tilemapwidth * map.tilesize/2, map.tilemapheight * map.tilesize/2);
					server_CreateBlob("whirlpool", 0, mapCenter);
				}
				else if (tokens[0] == "!pinball") //pinball machine
				{
					Island[]@ islands;
					if (!this.get("islands", @islands)) return false;
					
					for (uint i = 0; i < islands.length; ++i)
					{
						//commence pain
						Island@ isle = islands[i];
						isle.angle_vel += (180 + XORRandom(180)) * (XORRandom(2) == 0 ? 1 : -1);
						isle.vel += Vec2f(XORRandom(50) * (XORRandom(2) == 0 ? 1 : -1), XORRandom(50)* (XORRandom(2) == 0 ? 1 : -1));
					}
				}
			}
		}
	}
	return true;
}
