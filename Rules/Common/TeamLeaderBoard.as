#define CLIENT_ONLY
#include "TeamColour.as";
#include "ShiprektTranslation";

f32 lineHeight = 17.5f;
f32 panelWidth = 155.0f;
u16[] boardBooty = {0};
u8[] boardTeams = {0};

void onTick(CRules@ this)
{
	if (getGameTime() % 10 != 0)
		return;
		
	boardBooty.clear();
	CBlob@[] cores;
	getBlobsByTag("mothership", @cores);
	for (u8 i = 0; i < cores.length; i++)
		boardBooty.push_back(this.get_u16("bootyTeam_total" + cores[i].getTeamNum()));

	boardBooty.sortDesc();
	boardTeams.clear();
	
	for (u8 b = 0; b < boardBooty.length; b++)
		for (u8 i = 0; i < cores.length; i++)
		{
			u8 coreTeamNum =  cores[i].getTeamNum();
			if (boardBooty[b] == this.get_u16("bootyTeam_total" + coreTeamNum) && boardTeams.find(coreTeamNum) == -1)
				boardTeams.push_back(coreTeamNum);
		}
}

void onRender(CRules@ this)
{
	if (g_videorecording || !isClient())
		return;
		
	Vec2f mousePos = getControls().getMouseScreenPos();
	Vec2f panelCenter = Vec2f(getScreenWidth() - panelWidth/2, 75);
	if ((mousePos - panelCenter).Length() < panelWidth/2)
		return;
		
	//Draw
	Vec2f panelStart = Vec2f(getScreenWidth() - panelWidth - 5, 15);

	//background
	GUI::DrawButtonPressed(panelStart - Vec2f(10, 10), panelStart + Vec2f(panelWidth, 10 + lineHeight * (boardTeams.length + 1 )));
	
	//teams column
	string header = Trans::Total+" "+Trans::Booty;
	Vec2f size;
	GUI::GetTextDimensions(header, size);
	GUI::DrawText(header, panelStart + Vec2f((panelWidth - size.x)/2 - 6, 0), SColor(255, 255, 255, 255));
	for (u8 i = 0; i < boardTeams.length; i++)
		GUI::DrawText(teamColors[boardTeams[i]]+" "+Trans::Team, panelStart + Vec2f(0, (i+1)*lineHeight), getTeamColor(boardTeams[i]));
		
	//booty column
	for (u8 i = 0; i < boardBooty.length; i++)
		GUI::DrawText("" + Maths::Round(boardBooty[i]/10) * 10, panelStart + Vec2f(103, (i+1)*lineHeight), SColor(255, 255, 255, 255));
}
