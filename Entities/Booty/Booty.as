//Booty related functions. mostly server-side that sync to clients

void SetupBooty(CRules@ this)
{
	if (isServer())
	{
		dictionary@ current_bSet;
		if (!this.get("BootySet", @current_bSet))
		{
			//print("** Setting Booty Dictionary");
			dictionary bSet;
			this.set("BootySet", bSet);
		}
	}
}
 
dictionary@ getBootySet()
{
	dictionary@ bSet;
	getRules().get("BootySet", @bSet);
	
	return bSet;
}

void setStartingBooty(CRules@ this)
{
	//reset properties
	//print("** SetStartingBooty routine");
	dictionary@ bootySet = getBootySet();
	/*//causes seg faults
	string[]@ bKeys = bootySet.getKeys();
	for (u8 i = 0; i < bKeys.length; i++)
	{
		print(bKeys[i]);
		this.set_u16(bKeys[i], 0);
	}*/
	
	//bootySet.deleteAll();//clear booty
	dictionary bSet;
	this.set("BootySet", bSet);

	print("** Setting Starting Player Booty ");

	u16 initBooty = this.get_u16("starting_booty");
	for (u8 p = 0; p < getPlayersCount(); ++p)
	{
		server_setPlayerBooty(getPlayer(p).getUsername(), sv_test ? 9999 : initBooty);
	}
}

void server_updateTotalBooty(u8 teamNum, u16 ammount)
{
	if (isServer())
	{
		CRules@ rules = getRules();
		u16 totalBooty = rules.get_u16("bootyTeam_total" + teamNum);
		u16 roundedBooty = Maths::Round(totalBooty/10) * 10;
		u16 newBooty = totalBooty + ammount;
		u16 newRoundedBooty = Maths::Round(newBooty/10) * 10;
		rules.set_u16("bootyTeam_total" + teamNum, totalBooty + ammount);
		if (roundedBooty != newRoundedBooty)
		{
			rules.Sync("bootyTeam_total" + teamNum, true);
				
			//set booty median
			u32 allBooty = 0;
			CBlob@[] cores;
			if (getBlobsByTag("mothership", @cores))
			{
				for (u8 i = 0; i < cores.length; i++)
					allBooty += rules.get_u16("bootyTeam_total" + cores[i].getTeamNum());
				
				rules.set_u32("bootyTeam_median", allBooty/cores.length + 1);
				rules.Sync("bootyTeam_median", true);
			}
		}
	}
}

void server_resetTotalBooty(CRules@ this)
{
	if (!isServer()) return;
		
	u8 teamsNum = this.getTeamsNum();
	for (int teamNum = 0; teamNum < teamsNum; teamNum++)
	{
		this.set_u16("bootyTeam_total" + teamNum, 0);
		this.Sync("bootyTeam_total" + teamNum, true);
	}
	this.set_u32("bootyTeam_median", 1);
}

//player
u16 server_getPlayerBooty(string name)
{
	if (isServer())
	{
		u16 booty;
		if (getBootySet().get("booty" + name, booty))
			return booty;
	}
	return 0;
}
 
void server_setPlayerBooty(string name, u16 booty)
{
	if (isServer())
	{
		getBootySet().set("booty" + name, booty);
		//sync to clients
		CRules@ rules = getRules();
		rules.set_u16("booty" + name, booty);
		rules.Sync("booty" + name, true);
		CPlayer@ player = getPlayerByUsername(name);
		if (player !is null)
			player.setScore(booty);
	}
}

void server_addPlayerBooty(string name, u16 booty) //give or take booty
{
	server_setPlayerBooty(name, server_getPlayerBooty(name) + booty);
}

#include "ShipsCommon.as";

//rewards for damaging enemy ships
void damageBooty(CPlayer@ attacker, CBlob@ attackerBlob, CBlob@ victim, bool rewardBlocks = false, u16 reward = 4, string sound = "Pinball_0", bool randomSound = false)
{
	if (victim.hasTag("block"))
	{
		string attackerName = attacker.getUsername();
		Ship@ victimShip = getShip(victim.getShape().getVars().customData);

		if (victimShip !is null && victimShip.blocks.length > 3 //minimum size requirement
			&& (victimShip.owner != "" || victimShip.isMothership) //verified ship
			&& victim.getTeamNum() != attacker.getTeamNum() //not teammates
			&& (victim.hasTag("weapon") || victim.hasTag("bomb") || victim.hasTag("seat") || victim.hasTag("mothership") || victim.hasTag("secondaryCore") || //for sure reward
				rewardBlocks) //individual blocks for each
			)
		{
			if (attacker.isMyPlayer())
			{
				Sound::Play(sound + (randomSound ? XORRandom(4)+"" : ""), attackerBlob.getPosition(), 0.8f);
			}

			if (isServer())
			{
				if (victim.hasTag("engine"))
					reward += Maths::Clamp(reward/2, 1, 3);
				else if (victim.hasTag("weapon"))
					reward += Maths::Clamp(reward/2, 1, 8);
				else if (victim.hasTag("bomb") || victim.hasTag("secondaryCore"))
					reward += Maths::Clamp(reward/2, 2, 10);
				else if (victim.hasTag("mothership"))
					reward *= 2.0f;

				f32 bFactor = (getRules().get_bool("whirlpool") ? 3.0f : 1.0f);
				
				reward = Maths::Round(reward * bFactor);
								
				server_addPlayerBooty(attackerName, reward);
				server_updateTotalBooty(attacker.getTeamNum(), reward);
			}
		}
	}
}
