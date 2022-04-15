#include "BlockHooks.as";
//core rings

void onInit(CBlob@ this)
{
	this.Tag("core");
	
	BlockHooks@ blockHooks;
	this.get("BlockHooks", @blockHooks);
	blockHooks.addHook("onColored", @onColored); //add onColored hook
	
	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		for (int i = 0; i < 4; i++)
		{
			CSpriteLayer@ layer = sprite.addSpriteLayer("side"+i, "CoreCover.png", 8, 3);
			if (layer !is null)
			{
				layer.SetOffset(Vec2f(0, -5.5));
				layer.RotateBy(i*90, Vec2f(0, 5.5));
				//layer.SetVisible(false);
			}
		}
	}
}

void onColored(CBlob@ this) //activate when the block is placed or updated
{
	if (!isClient()) return;
	
	checkPerimeter(this);
}

void checkPerimeter(CBlob@ this)
{
	//check nearby platforms if we can activate our spritelayers
	CSprite@ sprite = this.getSprite();
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();
	f32 angle = this.getAngleDegrees();
	
	checkBlock(sprite, map, pos + Vec2f(0,-8).RotateBy(angle), "side0");
	checkBlock(sprite, map, pos + Vec2f(8,0).RotateBy(angle), "side1");
	checkBlock(sprite, map, pos + Vec2f(0,8).RotateBy(angle), "side2");
	checkBlock(sprite, map, pos + Vec2f(-8,0).RotateBy(angle), "side3");
}

void checkBlock(CSprite@ sprite, CMap@ map, Vec2f pos, string layername)
{
	CSpriteLayer@ layer = sprite.getSpriteLayer(layername);
	if (layer is null) return;
	
	CBlob@[] blobs;
	map.getBlobsAtPosition(pos, @blobs);
	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		if (blob.hasTag("platform") && blob.getShape().getVars().customData > 0)
		{
			if (!layer.isVisible())
			{
				layer.SetVisible(true);
			}
			return;
		}
	}
	
	if (layer.isVisible())
		layer.SetVisible(false);
}
