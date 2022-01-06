#include "BlockHooks.as";
void onInit(CBlob@ this)
{
	this.Tag("core");
	
	BlockHooks@ blockHooks;
	this.get("BlockHooks", @blockHooks);
	blockHooks.addHook("onColored", @onColored); //add onBlockPlaced hook
}

void onColored(CBlob@ this) //activate when the block is placed
{
	if (this.get_u32("placedTime") > getGameTime() + 2) return; //bootleg onBlockPlaced due to inaccuracies in island.as
	
	//find nearby platforms and see if they can change their frame
	CMap@ map = getMap();
	
	CBlob@[] blobs;
	map.getBlobsAtPosition(this.getPosition() + Vec2f(8,0).RotateBy(this.getAngleDegrees()), @blobs);
	map.getBlobsAtPosition(this.getPosition() + Vec2f(0,8).RotateBy(this.getAngleDegrees()), @blobs);
	map.getBlobsAtPosition(this.getPosition() + Vec2f(-8,0).RotateBy(this.getAngleDegrees()), @blobs);
	map.getBlobsAtPosition(this.getPosition() + Vec2f(0,-8).RotateBy(this.getAngleDegrees()), @blobs);
	
	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ b = blobs[i];
		if (b.hasTag("platform"))
		{
			BlockHooks@ blockHooks;
			b.get("BlockHooks", @blockHooks);
			if (blockHooks !is null)
				blockHooks.update("onColored", @b);
		}
	}
}
