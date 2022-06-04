//render respawn timer
#include "ShiprektTranslation.as";

void onInit(CRules@ this)
{
	this.addCommandID("sync respawn time");
}

void onRender(CRules@ this)
{
	if (this.isIntermission() || this.isGameOver()) return;
	
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;
	
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob !is null) return;

	const u32 time = this.get_u32("respawn time") + 30;
	const s32 time_left = (time - getGameTime())/getTicksASecond();
	
	if (!g_videorecording && player.getTeamNum() != this.getSpectatorTeamNum())
	{
		GUI::SetFont("menu");
		string text;
		if (time_left <= 0) text = Trans::Respawn;
		else if (time_left > 60) text = Trans::RespawnSoon;
		else text = getTranslatedString("Respawning in: {SEC}").replace("{SEC}", "" + time_left);
		GUI::DrawTextCentered(text, Vec2f(getScreenWidth()/2, 200 + Maths::Cos(getGameTime()/10.0f)*8), SColor(0xFFE0BA16));
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (isClient() && cmd == this.getCommandID("sync respawn time"))
	{
		const u32 time = params.read_u32();
		this.set_u32("respawn time", time);
	}
}
