#define CLIENT_ONLY
//ammo renderer
void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	
	u32 timer = blob.get_u32("sharkTurn time");
	if(timer <= 0) return;

	Vec2f player_screen_pos = getDriver().getScreenPosFromWorldPos(blob.getPosition());
	float percent = timer/15.0f;

	Vec2f bar_pos = player_screen_pos;
	bar_pos.y -= 24;

	GUI::SetFont("snes");
	GUI::DrawTextCentered("turning in to shark...", bar_pos - Vec2f(0, 22), SColor(0xFFC4C4C4));
	GUI::DrawSunkenPane(bar_pos - Vec2f(25, 7), bar_pos + Vec2f(25, 7));
	GUI::DrawPane(bar_pos - Vec2f(22, 4), bar_pos + Vec2f(22, 4), SColor(0xFF008E0B));
	GUI::DrawPane(bar_pos - Vec2f(22, 4), Vec2f(bar_pos.x - 22 + Maths::Max(8, percent * 44), bar_pos.y + 4), SColor(0xFF00DB0E));
	//GUI::DrawProgressBar(pos-Vec2f(8, 2), pos+Vec2f(8, 2), percent);
}