#include "ShipsCommon.as";
#include "ShiprektTranslation.as";

const Vec2f BUTTON_SIZE(4, 4);
const u8 teamsNum = 8;

void onInit(CRules@ this)
{
	this.addCommandID("pick teams");
	this.addCommandID("pick none");
	
	AddIconToken("$TEAMS$", "GUI/MenuItems.png", Vec2f(32,32), 1);
	AddIconToken("$SPECTATOR$", "GUI/MenuItems.png", Vec2f(32,32), 19);
	
	for (u8 i = 0; i < teamsNum; i++)
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

		menu.AddKeyCallback(KEY_ESCAPE, "TeamMenuShiprekt.as", "Callback_PickNone", params);
		menu.SetDefaultCallback("TeamMenuShiprekt.as", "Callback_PickNone", params);
		
		if (isSpectator)
		{
			params.write_u8(-1);
			CGridButton@ button = menu.AddButton("$TEAMS$", label, "TeamMenuShiprekt.as", "Callback_PickTeamsShiprekt", BUTTON_SIZE, params);
		}
		else
		{
			params.write_u8(this.getSpectatorTeamNum());
			CGridButton@ button = menu.AddButton("$SPECTATOR$", label, "TeamMenuShiprekt.as", "Callback_PickTeamsShiprekt", BUTTON_SIZE, params);
		}
	}

	//team selector
	bool canSwitch;
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
				params.write_u8(team);
				CGridButton@ button = menu2.AddButton("$MOTHERSHIP"+team+"$", teamColors[team]+" "+Trans::Team, "TeamMenuShiprekt.as", "Callback_PickTeamsShiprekt", Vec2f(2, 2), params);
			}
		}
	}
}

void Callback_PickTeamsShiprekt(CBitStream@ params)
{
	u8 team;
	if (!params.saferead_u8(team)) return;

	CPlayer@ player = getLocalPlayer();
	if (player is null) return;

	if (isTeamAvailable(getRules(), player, team))
	{
		player.client_ChangeTeam(team);
		getHUD().ClearMenus();
	}
}

void Callback_PickNone(CBitStream@ params)
{
	getHUD().ClearMenus();
}

u8[] getAvailableTeams(CRules@ this, CPlayer@ player, bool&out canSwitch) //taken from Respawning.as
{
	canSwitch = true;
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
	if (team > teamsNum) return true;

	bool canSwitch;
	if (getAvailableTeams(this, player, canSwitch).find(team) != -1)
	{
		return canSwitch;
	}

	return false;
}
