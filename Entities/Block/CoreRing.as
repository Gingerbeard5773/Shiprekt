// Gingebeard @ 4/19/2022
//core ring spritelayers

void onInit(CSprite@ this)
{
	this.getCurrentScript().tickFrequency = 5;
	for (int i = 0; i < 4; i++) //4 times for each lateral side
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
	this.getBlob().set_bool("updateLayers", true);
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob.get_bool("updateLayers") && blob.getShape().getVars().customData > 0)
	{
		checkPerimeter(this, blob);
		blob.set_bool("updateLayers", false);
	}
}

void checkPerimeter(CSprite@ this, CBlob@ blob)
{
	//check nearby platforms if we can activate our spritelayers
	CMap@ map = getMap();
	Vec2f pos = blob.getPosition();
	f32 angle = blob.getAngleDegrees();
	
	checkBlock(this, map, pos + Vec2f(0,-8).RotateBy(angle), "side0");
	checkBlock(this, map, pos + Vec2f(8,0).RotateBy(angle), "side1");
	checkBlock(this, map, pos + Vec2f(0,8).RotateBy(angle), "side2");
	checkBlock(this, map, pos + Vec2f(-8,0).RotateBy(angle), "side3");
}

void checkBlock(CSprite@ this, CMap@ map, Vec2f pos, string layername)
{
	CSpriteLayer@ layer = this.getSpriteLayer(layername);
	if (layer is null) return;
	
	CBlob@[] blobs;
	map.getBlobsAtPosition(pos, @blobs);
	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ b = blobs[i];
		if (b.hasTag("platform") && b.getShape().getVars().customData > 0)
		{
			if (!layer.isVisible())
				layer.SetVisible(true);
			return;
		}
	}
	if (layer.isVisible())
		layer.SetVisible(false);
}
