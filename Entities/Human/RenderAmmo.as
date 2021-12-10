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
	
	CBlob@ mBlob = getMap().getBlobAtPosition( blob.getAimPos());
	if (mBlob !is null && mBlob.hasTag("usesAmmo") && mBlob.getShape().getVars().customData > 0 && mBlob.getTeamNum() == blob.getTeamNum())
	{
		u16 maxAmmo = mBlob.get_u16("maxAmmo");
		if (maxAmmo == 0) return;

		Vec2f screenPos = getDriver().getScreenPosFromWorldPos(mBlob.getPosition());	
		//GUI::DrawProgressBar( screenPos + Vec2f( -20, 10 ), screenPos + Vec2f( 20, 25 ), float( mBlob.get_u16( "ammo" ) )/maxAmmo );

		Vec2f textSize;
		GUI::GetTextDimensions("" + mBlob.get_u16("ammo"), textSize);
		GUI::DrawRectangle(screenPos + Vec2f(-15, 10), screenPos + Vec2f(-5 + textSize.x, 15 + textSize.y)); 
		GUI::DrawText("" + mBlob.get_u16("ammo"), screenPos + Vec2f(-12.5f, 12.5f), color_white);  
	}
}