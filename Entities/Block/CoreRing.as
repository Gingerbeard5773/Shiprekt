// Gingebeard @ 4/19/2022
//core ring spritelayers

void onInit(CSprite@ this)
{
	this.getCurrentScript().tickIfTag = "updateBlock";
	this.getCurrentScript().runFlags |= Script::tick_onscreen;
	for (u8 i = 0; i < 4; i++) //4 times for each lateral side
	{
		CSpriteLayer@ layer = this.addSpriteLayer("side"+i, "CoreSide.png", 8, 3);
		if (layer !is null)
		{
			layer.SetRelativeZ(0.7f);
			layer.SetOffset(Vec2f(0, -5.5));
			layer.RotateBy(i*90, Vec2f(0, 5.5));
			layer.SetFrame(XORRandom(3));
			layer.SetVisible(false);
		}
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	blob.Untag("updateBlock");
	const int bCol = blob.getShape().getVars().customData;
	if (bCol <= 0) return;

	CMap@ map = getMap();
	Vec2f pos = blob.getPosition();
	const f32 angle = blob.getAngleDegrees();
	
	checkBlock(this, map, bCol, pos + Vec2f(0,-8).RotateBy(angle), "side0");
	checkBlock(this, map, bCol, pos + Vec2f(8,0).RotateBy(angle), "side1");
	checkBlock(this, map, bCol, pos + Vec2f(0,8).RotateBy(angle), "side2");
	checkBlock(this, map, bCol, pos + Vec2f(-8,0).RotateBy(angle), "side3");
}

void checkBlock(CSprite@ this, CMap@ map, const int&in bCol, const Vec2f&in pos, const string&in layername)
{
	CSpriteLayer@ layer = this.getSpriteLayer(layername);
	
	CBlob@[] blobs;
	map.getBlobsAtPosition(pos, @blobs);
	const u8 blobsLength = blobs.length;
	for (u8 i = 0; i < blobsLength; i++)
	{
		CBlob@ b = blobs[i];
		if (b.hasTag("platform") && b.getShape().getVars().customData == bCol)
		{
			if (!layer.isVisible())
				layer.SetVisible(true);
			return;
		}
	}
	if (layer.isVisible())
		layer.SetVisible(false);
}
