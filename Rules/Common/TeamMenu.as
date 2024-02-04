#include "ShipsCommon.as";
#include "ShiprektTranslation.as";

const Vec2f BUTTON_SIZE(4, 4);

void onInit(CRules@ this)
{
	this.addCommandID("pick teams");
	this.addCommandID("pick none");
	
	AddIconToken("$TEAMS$", "GUI/MenuItems.png", Vec2f(32,32), 1);
	AddIconToken("$SPECTATOR$", "GUI/MenuItems.png", Vec2f(32,32), 19);
	
	for (u8 i = 0; i < this.getTeamsNum(); i++)
	{
		AddIconToken("$MOTHERSHIP"+i+"$", "MothershipIcon.png", Vec2f(32,32), 0, i);
	}
}

void ShowTeamMenu(CRules@ this)
{
	CPlayer@ local = getLocalPlayer();
	if (local is null) return;

	//build spectator/auto pick button
	const bool isSpectator = local.getTeamNum() == this.getSpectatorTeamNum();
	const string label = isSpectator ? "Auto-pick teams" : "Spectator";
	CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos(), null, BUTTON_SIZE, label);
	if (menu !is null)
	{
		CBitStream params;
		params.write_netid(local.getNetworkID());

		menu.AddKeyCommand(KEY_ESCAPE, this.getCommandID("pick none"), params);
		menu.SetDefaultCommand(this.getCommandID("pick none"), params);
		
		if (local.getTeamNum() == this.getSpectatorTeamNum())
		{
			params.write_u8(-1);
			CGridButton@ button = menu.AddButton("$TEAMS$", label, this.getCommandID("pick teams"), BUTTON_SIZE, params);
		}
		else
		{
			params.write_u8(this.getSpectatorTeamNum());
			CGridButton@ button = menu.AddButton("$SPECTATOR$", label, this.getCommandID("pick teams"), BUTTON_SIZE, params);
		}
	}

	//team selector
	bool canSwitch = true;
	u8[] availableTeams = getAvailableTeams(this, local, canSwitch);
	const u8 availableTeamsLength = availableTeams.length;
	if (availableTeamsLength > 0 && canSwitch)
	{
		CGridMenu@ menu2 = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0, 200), null, Vec2f(availableTeamsLength*2, 2), "Change team");
		if (menu2 !is null)
		{
			for (u8 i = 0; i < availableTeamsLength; i++)
			{
				const u8 team = availableTeams[i];
				CBitStream params;
				params.write_netid(local.getNetworkID());
				params.write_u8(team);
				CGridButton@ button = menu2.AddButton("$MOTHERSHIP"+team+"$", teamColors[team]+" "+Trans::Team, this.getCommandID("pick teams"), Vec2f(2, 2), params);
			}
		}
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("pick teams"))
	{
		CPlayer@ player = getPlayerByNetworkId(params.read_netid());
		const u8 team = params.read_u8();
		if (player !is null && player is getLocalPlayer())
		{
			getHUD().ClearMenus();
			if (isTeamAvailable(this, player, team))
				player.client_ChangeTeam(team);
		}
	}
	else if (cmd == this.getCommandID("pick none"))
	{
		CPlayer@ player = getPlayerByNetworkId(params.read_netid());
		if (player !is null && player is getLocalPlayer())
			getHUD().ClearMenus();
	}
}

u8[] getAvailableTeams(CRules@ this, CPlayer@ player, bool&out canSwitch = true) //taken from Respawning.as
{
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

	u8[] smallestTeams;
	for (u8 i = 0; i < teamsNum; i++)
	{
		if (playersperteam[i] == minplayers)
		{
			if (player.getTeamNum() != i)
				smallestTeams.push_back(i);
			else canSwitch = false;
		}
	}

	return smallestTeams;
}

bool isTeamAvailable(CRules@ this, CPlayer@ player, const u8&in team)
{
	if (team > this.getTeamsNum()) return true;

	bool canSwitch = true;
	if (getAvailableTeams(this, player, canSwitch).find(team) != -1)
	{
		return canSwitch;
	}

	return false;
}
