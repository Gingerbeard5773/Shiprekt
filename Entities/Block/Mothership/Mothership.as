#include "IslandsCommon.as";
#include "ExplosionEffects.as";
#include "WaterEffects.as";
#include "Booty.as";
#include "BlockProduction.as";
#include "TeamColour.as";
#include "HumanCommon.as";
#include "AccurateSoundPlay.as";
#include "Hitters.as";

const u16 BASE_KILL_REWARD = 275;
const f32 HEAL_AMMOUNT = 0.1f;
const f32 HEAL_RADIUS = 16.0f;
const u16 SELF_DESTRUCT_TIME = 8 * 30;
const f32 BLAST_RADIUS = 25 * 8.0f;
const u8 MAX_TEAM_FLAKS = 100;
const u8 MAX_TOTAL_FLAKS = 1000;

void onInit(CBlob@ this)
{
	this.Tag("mothership");
	this.addCommandID("buyBlock");
	this.addCommandID("returnBlocks");
	this.addCommandID("turnShark");
	this.addCommandID("turnHuman");
	
	this.set_f32("weight", 12.0f);

	if (isServer())
	{
		SharkQueue[] human_sharks;
		this.set("human_sharks", @human_sharks);
	}
	
	if (isClient())
	{
		//add an additional frame to the damage frames animation
		CSprite@ sprite = this.getSprite();
		Animation@ animation = sprite.getAnimation("default");
		if (animation !is null)
		{
			array<int> frames = {3};
			animation.AddFrames(frames);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("buyBlock"))
    {
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller is null) return;
		
		string block = params.read_string();
		if (block != "decoycore")
			caller.set_string("last buy", block);
			
		u16 cost = params.read_u16();
		caller.set_u16("last cost", cost);

		if (!isServer() || Human::isHoldingBlocks(caller) || !this.hasTag("mothership") || this.getTeamNum() != caller.getTeamNum())
			return;
		
		BuyBlock(this, caller, block, cost);
	}
    else if (cmd == this.getCommandID("returnBlocks"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
			ReturnBlocks(caller);
	}
	else if (cmd == this.getCommandID("turnShark"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			CPlayer@ player = caller.getPlayer();
			if (player !is null) // only humans with player can turn in to sharks
			{
				caller.Tag("no_gib");
				if (isClient())
				{
					Sound::Play("SharkTurn.ogg", caller.getPosition());
					if (player.isMyPlayer()) // fix camera
					{
						CCamera@ camera = getCamera();
						camera.setTarget(null);
						camera.setPosition(caller.getPosition());
					}
				}
				if (isServer())
				{
					/*CBlob@ shark = server_CreateBlob("shark", caller.getTeamNum(), this.getPosition());
					if (shark !is null)
					{
						shark.server_SetPlayer(player);
						shark.Tag("just spawned");
					}*/
					SharkQueue new_shark = SharkQueue(player.getNetworkID(), getGameTime() + 15); // just half a second :\
					SharkQueue[]@ human_sharks;
					this.get("human_sharks", @human_sharks);
					human_sharks.push_back(new_shark);
					this.set("human_sharks", @human_sharks);
					caller.server_SetPlayer(null);
				    caller.server_Die();
				}
			}
			
		}
	}
	else if (cmd == this.getCommandID("turnHuman"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			CPlayer@ player = caller.getPlayer();
			if (player !is null) // only sharks with player can turn in to humans
			{
				if (isClient())
					Sound::Play("HumanTurn.ogg", caller.getPosition());
				if (isServer())
				{
					CBlob@ human = server_CreateBlobNoInit("human");
					if (human !is null)
					{
						human.server_SetPlayer(player);
						human.server_setTeamNum(caller.getTeamNum());
						human.setPosition(this.getPosition());
						human.Init();
					}
				    caller.server_Die();
				}
			}
			
		}
	}
}

void BuyBlock(CBlob@ this, CBlob@ caller, string bType, u16 cost)
{
	CRules@ rules = getRules();

	CPlayer@ player = caller.getPlayer();
	string pName = player !is null ? player.getUsername() : "";
	u16 pBooty = server_getPlayerBooty(pName);

	u8 amount = 1;
	u8 teamFlaks = 0;

	if (bType == "coupling") //coupling gives two blocks
	{
		amount = 2;
	}
	else if (bType == "flak")
	{
		//Max turrets to avoid lag
		CBlob@[] turrets;
		getBlobsByTag("flak", @turrets);
		for (u16 i = 0; i < turrets.length; i++)
		{
			if (turrets[i].getTeamNum() == this.getTeamNum())
				teamFlaks++;
		}
	}

	if (teamFlaks < MAX_TEAM_FLAKS)
	{
		if (getPlayersCount() == 1 || rules.get_bool("freebuild"))
			ProduceBlock(getRules(), caller, bType, amount);
		else if (pBooty >= cost)
		{
			server_addPlayerBooty(pName, -cost);
		
			ProduceBlock(getRules(), caller, bType, amount);
		}
	}
	else if (teamFlaks >= MAX_TEAM_FLAKS)
	{
		rules.set_bool("display_flak_team_max", false);
		rules.SyncToPlayer("display_flak_team_max", player);
		rules.set_bool("display_flak_team_max", true);
		rules.SyncToPlayer("display_flak_team_max", player);
	}
}

void ReturnBlocks(CBlob@ this)
{
	CRules@ rules = getRules();
	CBlob@[]@ blocks;
	if (this.get("blocks", @blocks) && blocks.size() > 0)                 
	{
		if (isServer())
		{
			CPlayer@ player = this.getPlayer();
			if (player !is null)
			{
				string pName = player.getUsername();
				u16 returnBooty = 0;
				for (uint i = 0; i < blocks.length; ++i)
				{
					CBlob@ block = blocks[i];
					if (!block.hasTag("coupling") && block.getShape().getVars().customData == -1)
						returnBooty += block.get_u16("cost");
				}
				
				if (returnBooty > 0 && !(getPlayersCount() == 1 || rules.get_bool("freebuild")))
					server_addPlayerBooty(pName, returnBooty);
			}
		}
		
		this.getSprite().PlaySound("join.ogg");
		Human::clearHeldBlocks(this);
		this.set_bool("blockPlacementWarn", false);
	}
	else
		warn("returnBlocks cmd: no blocks");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob is null) return damage;
	
	u8 thisTeamNum = this.getTeamNum();
	u8 hitterTeamNum = hitterBlob.getTeamNum();
	
	if (thisTeamNum == hitterTeamNum && hitterBlob.getTickSinceCreated() < 900 && hitterBlob.hasTag("block"))
	{
		CPlayer@ player = getLocalPlayer();
		if (player !is null && player.isMod() && !getRules().isGameOver())
		{
			CBlob@ BlobID = getBlobByNetworkID(hitterBlob.get_u16("ownerID"));
			if (BlobID !is null)
			{
				CPlayer@ owner = getPlayerByNetworkId(BlobID.getPlayer().getNetworkID());
				if (owner !is null)
					error(">Core teamHit (" + hitterTeamNum+ "): " + owner.getUsername()); 
			}
		}
		
		damage /= 2;
	}
	
	f32 hp = this.getHealth();
	if (!this.hasTag("critical") && hp - damage > 0.0f)//assign last team hitter
	{
		if (thisTeamNum != hitterTeamNum && hitterBlob.getName() != "whirlpool")
		{
			this.set_u8("lastHitterTeam", hitterTeamNum);
			this.set_u32("lastHitterTime", getGameTime());
		}
	}
	else
	{
		if (!this.hasTag("critical"))//deathHit(once)
		{
			initiateSelfDestruct(this);
			
			//increase captain deaths
			string defeatedCaptainName = getCaptainName(thisTeamNum);
			CPlayer@ defeatedCaptain = getPlayerByUsername(defeatedCaptainName);
			if (defeatedCaptain !is null)
			{
				defeatedCaptain.setDeaths(defeatedCaptain.getDeaths() + 1);
				if (defeatedCaptain.isMyPlayer())
					client_AddToChat("You lost your Mothership! A Core Death was added to your Scoreboard.");
			}
			
			//rewards if they apply
			CRules@ rules = getRules();
			if (thisTeamNum == hitterTeamNum || hitterBlob.getName() == "whirlpool" || hitterBlob.hasTag("mothership"))//suicide. try with last good hitterTeam
				if (getGameTime() - this.get_u32("lastHitterTime") < 450)//15 seconds lease
					hitterTeamNum = this.get_u8("lastHitterTeam");
				else
					return Maths::Max( 0.0f, hp - 1.0f );//no rewards
					
			//got a possible winner team
			u8 thisPlayers = 0;
			u8 hitterPlayers = 0;
			u8 playersCount = getPlayersCount();
			for (u8 i = 0; i < playersCount; i++)
			{
				u8 pteam = getPlayer(i).getTeamNum();
				if (pteam == thisTeamNum)
					thisPlayers++;
				else if (pteam == hitterTeamNum)
					hitterPlayers++;
			}
							
			CBlob@ hitterCore = getMothership(hitterTeamNum);
			if (hitterPlayers == 0 || hitterCore is null)//in case of suicide against leftover/empty team ship
				return Maths::Max( 0.0f, hp - 1.0f );//no rewards

			//got a winner team
			this.Tag("cleanDeath");	
			
			//winSound
			CPlayer@ myPlayer = getLocalPlayer();
			if (myPlayer !is null && myPlayer.getTeamNum() == hitterTeamNum)
			{
				Sound::Play("KAGWorldQuickOut.ogg");
				Sound::Play("ResearchComplete.ogg");
			}
			
			//increase winner captain kills
			string captainName = getCaptainName(hitterTeamNum);
			CPlayer@ captain = getPlayerByUsername(captainName);
			if (captain !is null)
			{
				captain.setKills(captain.getKills() + 1);
				if (captain.isMyPlayer())
					client_AddToChat("Congratulations! A Core Kill was added to your Scoreboard.");
			}
			
			f32 ratio = Maths::Max(0.25f, Maths::Min(1.75f,
							float(rules.get_u16("bootyTeam_total" + thisTeamNum))/float(rules.get_u32("bootyTeam_median") + 1.0f ))); //I added 1.0f as a safety measure against dividing by 0
			
			u16 totalReward = (thisPlayers + 1) * BASE_KILL_REWARD * ratio;
			client_AddToChat("*** " + rules.getTeam(hitterTeamNum).getName() + " gets " + (totalReward + BASE_KILL_REWARD) + " Booty for destroying " + rules.getTeam(thisTeamNum).getName() + "! ***");
			
			//give rewards
			if (isServer())
			{
				u16 reward = Maths::Round(totalReward/hitterPlayers);
				for (u8 i = 0; i < playersCount; i++)
				{
					CPlayer@ player = getPlayer(i);
					u8 teamNum = player.getTeamNum();
					if (teamNum == hitterTeamNum)//winning tam
					{
						string name = player.getUsername();
						server_addPlayerBooty(name, (name == captainName ? 2 * reward : reward));
					}
					else if (teamNum == thisTeamNum)//losing team consolation money
					{
						string name = player.getUsername();
						u16 booty = server_getPlayerBooty(name);
						u16 rewardHalved = Maths::Round(BASE_KILL_REWARD/2);
						if (booty < rewardHalved)
							server_addPlayerBooty(name, rewardHalved);
					}
				}
				server_updateTotalBooty(hitterTeamNum, totalReward + BASE_KILL_REWARD);
				//print ("MothershipKill: " + thisPlayers + " players; " + ((thisPlayers + 1) * BASE_KILL_REWARD) + " to " + rules.getTeam(hitterTeamNum).getName());
			}
		}

		return Maths::Max(0.0f, hp - 1.0f);
	}
		
	return damage;
}

void onDie(CBlob@ this)
{
	selfDestruct(this);

	if (!this.hasTag("cleanDeath"))
		client_AddToChat("*** " + getRules().getTeam(this.getTeamNum()).getName() + " had their core bombed - instant death! ***");
}

//healing, repelling, dmgmanaging, selfDestruct, damagesprite
void onTick(CBlob@ this)
{
	f32 hp = this.getHealth();
	Vec2f pos = this.getPosition();
	int color1 = this.getShape().getVars().customData;
	Island@ isle = getIsland(color1);
	CRules@ rules = getRules();
	
	//repel
/* 	CBlob@[] cores;
	getBlobsByTag("mothership", @cores);
	for (u8 i = 0; i < cores.length; i++)
	{
		f32 distance = cores[i].getDistanceTo(this);
		
		int color2 = cores[i].getShape().getVars().customData;
		if (cores[i] !is this && color1 != color2 && distance < 125.0f)
		{
			//sparks in the direction of the island
			if (isle !is null)
			{
				Vec2f dir = pos - cores[i].getPosition();
				dir.Normalize();
				
				f32 whirlpoolFactor = !getRules().get_bool("whirlpool") ? 2.0f : 1.25f;
				f32 healthFactor = Maths::Max( 0.25f, hp/this.getInitialHealth());
				isle.vel += dir * healthFactor*whirlpoolFactor/distance;
				
				dir.RotateBy(-45.0f);
				dir *= -6.0f * healthFactor;
				for (int i = 0; i < 5; i++)
				{
					CParticle@ p = ParticlePixel(pos, dir.RotateBy(15), getTeamColor(this.getTeamNum()), true);
					if (p !is null)
					{
						p.Z = 10.0f;
						p.timeout = 4;
					}
				}
			}
		}
	}*/

	//heal
	if (getGameTime() % 60 == 0)
	{
		u8 coreTeam = this.getTeamNum();
		
		if (isServer())
		{
			CBlob@[] humans;
			getBlobsByName("human", humans);
			int hNum = humans.length();

			for (int i = 0; i < hNum; i++)
			{
				if (humans[i].getTeamNum() == coreTeam && humans[i].getHealth() < humans[i].getInitialHealth())
				{
					Island@ hIsle = getIsland(humans[i]);
					if (hIsle !is null && hIsle.centerBlock !is null && color1 == hIsle.centerBlock.getShape().getVars().customData)
						humans[i].server_Heal(HEAL_AMMOUNT);
				}
			}
		}

		//dmgmanaging
		f32 msDMG = rules.get_f32("msDMG" + coreTeam);
		if (msDMG > 0)
			rules.set_f32("msDMG" + coreTeam, Maths::Max(msDMG - 0.75f, 0.0f));
	}

	//critical Slowdown, selfDestruct and effects
	if (this.hasTag("critical"))
	{
		isle.vel *= 0.8f;

		if (isServer() && getGameTime() > this.get_u32("dieTime"))
			this.server_Die();
		
		//particles
		{
			CParticle@ p = ParticlePixel(pos, getRandomVelocity(90, 4, 360), getTeamColor(this.getTeamNum()), true);
			if (p !is null)
			{
				p.Z = 10.0f;
				p.timeout = XORRandom(3) + 2;
			}
		}
		
		if (v_fastrender)
		{
			CParticle@ p = ParticlePixel(pos, getRandomVelocity(90, 4, 360), getTeamColor(this.getTeamNum()), true);
			if (p !is null)
			{
				p.Z = 10.0f;
				p.timeout = XORRandom(3) + 2;
			}
		}
	}
	
	//displayed by ShiprektHUD.as
	if (rules.get_bool("display_flak_team_max"))
	{
		rules.add_u8("flak_team_max_timer", 1);
		if (rules.get_u8("flak_team_max_timer") == 2)
			client_AddToChat("Too many team flaks!");
		if (rules.get_u8("flak_team_max_timer") >= 30*5)
		{
			rules.set_bool("display_flak_team_max", false);
			rules.set_u8("flak_team_max_timer", 0);
		}
	}

	// check human sharks to spawn
	if (isServer())
	{
		SharkQueue[]@ human_sharks;
		this.get("human_sharks", @human_sharks);
		for (int i = 0; i < human_sharks.size(); i++) // loop trough all, but process only one
		{
			SharkQueue new_shark = human_sharks[i];
			CPlayer@ pl = getPlayerByNetworkId(new_shark.netid);
			if (pl is null)
			{
				human_sharks.removeAt(i);
				this.set("human_sharks", @human_sharks);
				break;
			}
			else
			{
				if (new_shark.supposed_time <= getGameTime()) // crate sharko
				{
					CBlob@ shark = server_CreateBlob("shark", pl.getTeamNum(), this.getPosition());
					if (shark !is null)
					{
						shark.server_SetPlayer(pl);
						shark.Tag("just spawned");
					}
					human_sharks.removeAt(i);
					this.set("human_sharks", @human_sharks);
					break;
				}
			}
		}
	}
}

//make islandblocks start exploding
void initiateSelfDestruct(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	//set timer for selfDestruct sequence
	this.Tag("critical");
	this.set_u32("dieTime", getGameTime() + SELF_DESTRUCT_TIME);
	
	//effects
	directionalSoundPlay("ShipExplosion.ogg", pos, 1.5f);
    makeLargeExplosionParticle(pos);

	//add block explosion scripts
	const int color = this.getShape().getVars().customData;
    if (color == 0) return;

	Island@ isle = getIsland(color);
	if (isle is null || isle.blocks.length < 10) return;
		
	this.AddScript("Block_Explode.as");
	u8 teamNum = this.getTeamNum();
	for (uint i = 0; i < isle.blocks.length; ++i)
	{
		IslandBlock@ isle_block = isle.blocks[i];
		CBlob@ b = getBlobByNetworkID( isle_block.blobID);
		if (b !is null && teamNum == b.getTeamNum())
		{
			if (i % 4 == 0 && !b.hasTag("mothership") && !b.hasTag("coupling"))
				b.AddScript("Block_Explode.as");
		}
	}
}

//kill players, turrets and island
void selfDestruct(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	
	//effects
	directionalSoundPlay("ShipExplosion", pos, 2.0f);
	makeWaveRing(pos, 4.5f, 15);
    makeHugeExplosionParticle(pos);
    ShakeScreen(90, 80, pos);
	if (this.isOnScreen())
		SetScreenFlash(150, 255, 255, 255);

	if (!isServer()) return;
		
	u8 teamNum = this.getTeamNum();
	//kill team players
	CBlob@[] dieBlobs;
	getBlobsByName("human", @dieBlobs);
	for (u16 i = 0; i < dieBlobs.length; i++)
		if (dieBlobs[i].getTeamNum() == teamNum)
			dieBlobs[i].server_Die();
	
	//turrets go neutral
	CBlob@[] turrets;
	getBlobsByTag("weapon", @turrets);
	for (u16 i = 0; i < turrets.length; i++)
		if (turrets[i].getTeamNum() == teamNum)
			turrets[i].server_setTeamNum(-1);
			
	//damage nearby blobs
	CBlob@[] blastBlobs;
	getMap().getBlobsInRadius(pos, BLAST_RADIUS, @blastBlobs);
	for (u16 i = 0; i < blastBlobs.length; i++)
		if (blastBlobs[i] !is this)
		{
			f32 maxHealth = blastBlobs[i].getInitialHealth();
			f32 damage = 1.5f * maxHealth * (BLAST_RADIUS - this.getDistanceTo(blastBlobs[i]))/BLAST_RADIUS;
			this.server_Hit(blastBlobs[i], pos, Vec2f_zero, damage, Hitters::bomb, true);
		}

	//kill island
	const int color = this.getShape().getVars().customData;
    if (color == 0)		return;

	Island@ isle = getIsland(color);
	if (isle is null || isle.blocks.length < 10) return;

	for (uint i = 0; i < isle.blocks.length; ++i)
	{
		IslandBlock@ isle_block = isle.blocks[i];
		CBlob@ b = getBlobByNetworkID(isle_block.blobID);
		if (b !is null && b !is this && teamNum == b.getTeamNum())
			b.server_Die();
	}
}

class SharkQueue
{
	u16 netid;
	u32 supposed_time;

	SharkQueue(u16 _netid, u32 _supposed_time)
	{
		netid = _netid;
		supposed_time = _supposed_time;
	}
}
