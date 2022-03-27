#define CLIENT_ONLY

//health, reclaim renderer

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	 
	CBlob@ mBlob = getMap().getBlobAtPosition(blob.getAimPos());
	
	if (mBlob !is null && mBlob.getShape().getVars().customData > 0 && !mBlob.hasTag("noRenderHealth") 
			&& (blob.get_string("current tool") == "deconstructor" || blob.get_string("current tool") == "reconstructor"))
	{
		                                  //VV right here VV
		Vec2f pos2d = mBlob.getScreenPos() + Vec2f(0, -50);
		Vec2f dim = Vec2f(24,8);
		const f32 y = mBlob.getHeight()*2.4f;
		const f32 initialHealth = mBlob.getInitialHealth();
		if (initialHealth > 0.0f)
		{
			const f32 perc = mBlob.getHealth() / initialHealth;
			if (perc >= 0.0f)
			{
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x-2, pos2d.y + y-2), Vec2f(pos2d.x +dim.x+2, pos2d.y + y + dim.y+2));
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x+2, pos2d.y + y+2), Vec2f(pos2d.x - dim.x + perc*2.0f*dim.x -2, pos2d.y + y + dim.y-2), SColor(0xffac1512));
			}
		}
		
		if (initialHealth > 0.0f)
		{
			const f32 perc = mBlob.get_f32("current reclaim") / initialHealth;
			if (perc >= 0.0f)
			{
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x+2, pos2d.y + y+2), Vec2f(pos2d.x - dim.x + perc*2.0f*dim.x -2, pos2d.y + y + dim.y-2), SColor(255, 36,177,53));
			}
		}
	}
}