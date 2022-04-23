#define SERVER_ONLY
#include "Booty.as";
#include "ShipsCommon.as";
#include "MakeBlock.as";

const u16 STATION_BOOTY = 4;

void onInit(CRules@ this)
{
	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	this.set_u8("endCount", 0);
	
	setStartingBooty(this);
	server_resetTotalBooty(this);
	
	CCamera@ camera = getCamera();
    if (camera !is null)
    	camera.setRotation(0.0f);
	
	this.SetGlobalMessage("");
	this.SetCurrentState(WARMUP);
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
		
		const u8 coresLength = cores.length;
		for (u8 i = 0; i < coresLength; i++)
		{
			Ship@ ship = getShip(cores[i].getShape().getVars().customData);
			if (ship !is null && ship.owner != "" && ship.owner  != "*")
			{
				u16 captainBooty = server_getPlayerBooty(ship.owner);
				if (captainBooty < minBooty)
				{
					CPlayer@ player = getPlayerByUsername(ship.owner);
					if (player is null) continue;
					
					//consider blocks to propellers ratio
					int propellers = 1;
					int couplings = 0;
					const int blocksLength = ship.blocks.length;
					for (uint q = 0; q < blocksLength; ++q)
					{
						CBlob@ b = getBlobByNetworkID(ship.blocks[q].blobID);
						if (b !is null)
						{
							if (b.hasTag("engine"))
								propellers++;
							else if (b.hasTag("coupling"))
								couplings++;
						}
					}

					if (((blocksLength - propellers - couplings)/propellers > 3) || this.isWarmup())
					{
						CBlob@ pBlob = player.getBlob();
						CBlob@[]@ blocks;
						if (pBlob !is null && pBlob.get("blocks", @blocks) && blocks.size() == 0)
							server_addPlayerBooty(ship.owner, Maths::Min(15, minBooty - captainBooty));
					}
				}				
			}
		}
		
		const int plyCount = getPlayersCount();
		for (int i = 0; i < plyCount; ++i)
		{
			CPlayer@ player = getPlayer(i);
			u8 pteam = player.getTeamNum();
			if (player is null)	
				continue;
			
			u16 pStationCount = 0;
			CBlob@[] stations;
			getBlobsByTag("station", @stations);
			const int stationsLength = stations.length;
			for (u8 u = 0; u < stationsLength; u++)
			{
				CBlob@ station = stations[u];
				if (station is null)
					continue;
			
				if (stations[u].getTeamNum() == pteam)
					pStationCount++;
			}
			
			CBlob@ pBlob = player.getBlob();
			if (pBlob !is null)
			{
				server_addPlayerBooty(player.getUsername(), (STATION_BOOTY * pStationCount));
				server_updateTotalBooty(pteam, (STATION_BOOTY * pStationCount));
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
		u8 median = teams <= 0 ? 1 : Maths::Round(players/teams);
		//player per team
		u8[] teamPlayers;
		for (u8 t = 0; t < 16; t++)
			teamPlayers.push_back(0);
		
		const int teamPlyLength = teamPlayers.length;
		for (u8 p = 0; p < players; p++)
		{
			u8 team = getPlayer(p).getTeamNum();
			if (team < teamPlyLength)
				teamPlayers[team]++;
		}
		
		print("** Balancing booty: median = " + median + " for " + players + " players in " + teams + " teams");
		//balance booty
		for (u8 p = 0; p < players; p++)
		{
			CPlayer@ player = getPlayer(p);
			u8 team = player.getTeamNum();
			if (team >= teamPlyLength) continue;
				
			f32 compensate = median/teamPlayers[team];
			if (compensate > 1)
			{
				u16 balance = Maths::Round(initBooty * compensate/teamPlayers[team] - initBooty);
				string name = player.getUsername();
				server_setPlayerBooty(name, balance);
			}
		}
	}
	
	//check game states
	if (gameTime % 30 == 0)
	{
		//end warmup time
		if (this.isWarmup() && (gameTime > this.get_u16("warmup_time") || this.get_bool("freebuild")))
		{
			this.SetCurrentState(GAME);
		}
		
		//check if the game has ended
		CBlob@[] cores;
        getBlobsByTag("mothership", cores);
		
		const int coresLength = cores.length;
		
        bool oneTeamLeft = coresLength <= 1;
		u8 endCount = this.get_u8("endCount");
		
		if (oneTeamLeft && endCount == 0)//start endmatch countdown
			this.set_u8("endCount", 15);
		
		if (endCount != 0)
		{
			this.set_u8("endCount", Maths::Max(endCount - 1, 1));
			if (endCount == 11)
			{
				u8 teamWithPlayers = 0;
				if (!this.isGameOver())
				{
					for (uint coreIt = 0; coreIt < coresLength; coreIt++)
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
				for (int i = 0; i < coresLength; i++)
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
	}
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
		server_setPlayerBooty(pName, !this.isWarmup() ? minBooty : this.get_u16("starting_booty"));
		
	print("New player joined. New count : " + getPlayersCount());
	if (getPlayersCount() <= 1 && !this.get_bool("freebuild"))
	{
		//print("*** Restarting the map to be fair to the new player ***");
		getNet().server_SendMsg("*** 1 player on map. Setting freebuild mode until more players join. ***");
		this.set_bool("freebuild", true);
		this.Sync("freebuild", true);
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	if ((getPlayersCount() - 1) <= 1 && !this.get_bool("freebuild"))
	{
		getNet().server_SendMsg("*** 1 player on map. Setting freebuild mode until more players join. ***");
		this.set_bool("freebuild", true);
		this.Sync("freebuild", true);
	}
}

bool isDev(CPlayer@ player)
{
	//case sensitive
	const string[] devNames = 
	{
		"Mr" + "Ho" + "bo"
	};
	
	if (devNames.find(player.getUsername()) >= 0)
		return true;
	
	return false;
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (player is null) return true;

	//for testing
	if (sv_test || player.isMod() || isDev(player))
	{
		if (text_in.substr(0,1) == "!")
		{
			string[]@ tokens = text_in.split(" ");
			const int tokensLength = tokens.length;
			if (tokensLength > 1)
			{
				CBlob@ pBlob = player.getBlob();
				if (pBlob is null) return false;
				
				if (tokens[0] == "!kick") //force kick player of choice by username or player ID
				{
					CPlayer@ kickedPly = getPlayerByUsername(tokens[1]);
					if (kickedPly is null)
						@kickedPly = getPlayerByNetworkId(parseInt(tokens[1]));
					if (kickedPly !is null)
					{
						error(">> "+player.getUsername()+" kicked player "+kickedPly.getUsername()+" <<");
						getNet().server_SendMsg(">> Kicking Player "+kickedPly.getUsername()+" <<");
						KickPlayer(kickedPly);
						return true;
					}
					warn("!kick:: Player "+tokens[1]+" does not exist!");
				}
				else if (tokens[0] == "!addbot") //add a bot to the server. Supports names & teams
				{
					if (tokensLength > 2)
						AddBot(tokens[1], parseInt(tokens[2]), 0);
					else
						AddBot(tokens[1]);
					
					return true;
				}
				else if (tokens[0] == "!team")
				{
					if (tokensLength > 2)
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
					string word = text_in.replace("!hash ", "");
					print(word.getHash() + " : "+ word, color_white);
					
					return false;
				}
				else if (tokens[0] == "!tp") //teleport to player, uses playername or playerID
				{
					//this command also has support to teleport other players to our player. E.g "!tp (player) here"
					string word = text_in.replace("!tp ", "").replace(" here", "");
					CPlayer@ ply = getPlayerByUsername(word);
					if (ply is null)
						@ply = getPlayerByNetworkId(parseInt(tokens[1]));
					if (ply is null) 
					{
						warn("!tp:: Player not found: "+ tokens[1]);
						return false;
					}
					
					CBlob@ b = ply.getBlob();
					if (b is null) return false;
					
					if (text_in.find(" here") >= 0)
					{
						print("Teleported "+ply.getUsername()+" to "+player.getUsername()+" ("+ply.getNetworkID()+")", color_white);
						b.setPosition(pBlob.getPosition()); //teleport to player!
					}
					else
					{
						print("Teleported "+player.getUsername()+" to "+ply.getUsername()+" ("+b.getNetworkID()+")", color_white);
						pBlob.setPosition(b.getPosition()); //teleport player here!
					}
					
					return false;
				}
				else if (tokens[0] == "!class") //change your player blob (shark etc)
				{
					CBlob@ b = server_CreateBlob(tokens[1], pBlob.getTeamNum(), pBlob.getPosition());
					if (b !is null)
					{
						b.server_SetPlayer(player);
						pBlob.server_Die();
						print("Setting "+player.getUsername()+" to "+tokens[1], color_white);
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
					print("Setting g_debug to "+tokens[1], color_white);
					return false;
				}
				else if (tokens[0] == "!saveship") //all players can save their ship
				{
					ConfigFile cfg;
					
					Vec2f playerPos = pBlob.getPosition();
					Ship@ ship = getShip(player.getBlob());
					if (ship is null)
					{
						warn("!saveship:: No ship found!");
						return false;
					}
					int numBlocks = ship.blocks.length;
					cfg.add_u16("total blocks", numBlocks);
					for (uint i = 0; i < numBlocks; ++i)
					{
						ShipBlock@ ship_block = ship.blocks[i];
						if (ship_block is null) continue;

						CBlob@ block = getBlobByNetworkID(ship_block.blobID);
						if (block is null) continue;
						
						cfg.add_string("block" + i + "type", block.getName());
						cfg.add_f32("block" + i + "positionX", (block.getPosition().x - playerPos.x));
						cfg.add_f32("block" + i + "positionY", (block.getPosition().y - playerPos.y));
						cfg.add_f32("block" + i + "angle", block.getAngleDegrees());
					}
					
					cfg.saveFile("SHIP_" + tokens[1] + ".cfg");
					print("Saved ship as: "+tokens[1], color_white);
				}
				else if (tokens[0] == "!loadship")
				{
					ConfigFile cfg;
					
					if (!cfg.loadFile("../Cache/SHIP_" + tokens[1] + ".cfg"))
					{
						warn("Failed to load ship "+tokens[1]);
						return false;
					}
					
					Vec2f playerPos = pBlob.getPosition();
				
					int numBlocks = cfg.read_u16("total blocks");
					for (uint i = 0; i < numBlocks; ++i)
					{	
						string blockType = cfg.read_string("block" + i + "type");
						f32 blockPosX = cfg.read_f32("block" + i + "positionX");
						f32 blockPosY = cfg.read_f32("block" + i + "positionY");
						f32 blockAngle = cfg.read_f32("block" + i + "angle");
						
						makeBlock(playerPos + Vec2f(blockPosX, blockPosY), blockAngle, blockType, pBlob.getTeamNum());
					}
					print(player.getUsername()+" Generated ship "+tokens[1], color_white);
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
					Ship@ ship = getShip(player.getBlob());
					if (ship !is null)
					{
						int numBlocks = ship.blocks.length;
						for (uint i = 0; i < numBlocks; ++i)
						{
							ShipBlock@ ship_block = ship.blocks[i];
							if (ship_block is null) continue;

							CBlob@ block = getBlobByNetworkID(ship_block.blobID);
							if (block is null) continue;
							
							if (!block.hasTag("mothership") || numBlocks == 1)
							{
								block.Tag("noCollide");
								block.server_Die();
							}
						}
						print(player.getUsername()+" destroyed "+numBlocks+" blocks", color_white);
					}
				}
				else if (tokens[0] == "!clearmap")
				{
					CBlob@[] blocks;
					if (getBlobsByTag("block", @blocks))
					{
						const int blocksLength = blocks.length;
						for (uint i = 0; i < blocksLength; ++i)
						{
							CBlob@ block = blocks[i];
							if (block is null) continue;
							
							if (!block.hasTag("mothership"))
							{
								block.Tag("noCollide");
								block.server_Die();
							}
						}
						print("Clearing "+blocksLength+" blocks", color_white);
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
				else if (tokens[0] == "!debugship") //print ship infos
				{
					if (player.getBlob() is null) return true;
					
					Ship@ ship = getShip(player.getBlob());
					if (ship is null || ship.centerBlock is null)
					{
						warn("!debugship:: no ship found");
						return false;
					}
					
					string shipType;
					if (ship.isMothership) shipType += "Mothership";
					if (ship.isSecondaryCore) shipType += (shipType.length > 0 ? ", " : "")+"Secondary Core";
					if (ship.isStation) shipType += (shipType.length > 0 ? ", " : "")+"Station";
					
					//RGB cause cool
					print("---- ISLAND "+ship.centerBlock.getShape().getVars().customData+" ----", color_white);
					print("ID: "+ship.id, SColor(255, 235, 30, 30));
					print("Type: "+shipType, SColor(255, 255, 165, 0));
					print("Owner: "+ship.owner, SColor(255, 235, 235, 0));
					print("Speed: "+ship.vel.LengthSquared(), SColor(255, 30, 220, 30));
					print("Angle: "+ship.angle, SColor(255, 173, 216, 200));
					print("Mass: "+ship.mass, SColor(255, 77, 100, 195));
					print("Blocks: "+ship.blocks.length, SColor(255, 168, 50, 168));
					
					return false;
				}
				else if (tokens[0] == "!bc") //print block count
				{
					CBlob@[] blocks;
					getBlobsByTag("block", @blocks);
					print("BLOCK COUNT: "+blocks.length, color_white);
					return false;
				}
				else if (tokens[0] == "!dirty") //activate dirty ships 
				{
					this.set_bool("dirty ships", true);
					return false;
				}
				else if (tokens[0] == "!sv_test")
				{
					sv_test = !sv_test;
					print("Setting sv_test "+ (sv_test ? "on" : "off"), color_white);
					return false;
				}
				else if (tokens[0] == "!performance")
				{
					g_measureperformance = !g_measureperformance;
					print("Setting g_measureperformance to "+g_measureperformance, color_white);
				}
				else if (tokens[0] == "!freebuild") //toggle freebuild mode
				{
					getNet().server_SendMsg("*** Setting freebuild mode "+ (this.get_bool("freebuild") ? "off" : "on") +" ***");
					this.set_bool("freebuild", !this.get_bool("freebuild"));
					this.Sync("freebuild", true);
				}
				else if (tokens[0] == "!booty")
				{
					error(player.getUsername()+" cheating for 800 booty, bad!");
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
					Ship[]@ ships;
					if (!this.get("ships", @ships)) return false;
					
					const int shipsLength = ships.length;
					for (uint i = 0; i < shipsLength; ++i)
					{
						//commence pain
						Ship@ ship = ships[i];
						ship.angle_vel += (180 + XORRandom(180)) * (XORRandom(2) == 0 ? 1 : -1);
						ship.vel += Vec2f(XORRandom(50) * (XORRandom(2) == 0 ? 1 : -1), XORRandom(50)* (XORRandom(2) == 0 ? 1 : -1));
					}
				}
			}
		}
	}
	return true;
}
