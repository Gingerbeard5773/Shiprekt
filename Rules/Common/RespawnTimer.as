
void onInit(CRules@ this)
{
	this.addCommandID("sync respawn time");
}

void onTick(CRules@ this)
{
	
}

void onRender(CRules@ this)
{
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;
		
	CBlob@ localBlob = getLocalPlayerBlob();

	u32 time = this.get_u32("respawn time") + 30;
	s32 time_left = (time - getGameTime())/getTicksASecond();
	
	if (!g_videorecording && localBlob is null && player.getTeamNum() != this.getSpectatorTeamNum() && this.getCurrentState() == RuleState::GAME)
	{
		GUI::SetFont("menu");
		string text;
		if(time_left <= 0) text = "Respawning...";
		else if(time_left > 60)  text = "Respawning soon...";
		else text = "Respawning in "+time_left+" "+textFromNumber(time_left)+".";
		GUI::DrawTextCentered(text, Vec2f(getScreenWidth()/2, 200 + Maths::Cos(getGameTime()/10.0f)*8), SColor(0xFFE0BA16));
	}
}

string textFromNumber(int num) // lol
{
	if(num == 1)
		return "second";
	return "seconds";
}

void onCommand( CRules@ this, u8 cmd, CBitStream @params )
{
	if(isClient() && cmd == this.getCommandID("sync respawn time"))
	{
		u32 time = params.read_u32();
		this.set_u32("respawn time", time);
	}
}