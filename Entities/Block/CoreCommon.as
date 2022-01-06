#include "BlockHooks.as";
void onInit(CBlob@ this)
{
	this.Tag("core");
	
	BlockHooks@ blockHooks;
	this.get("BlockHooks", @blockHooks);
	blockHooks.addHook("onBlockPlaced", @onBlockPlaced); //add onBlockPlaced hook
}

void onBlockPlaced(CBlob@ this) //activate when the block is placed
{
	//find nearby platforms and see if they can change their frame
	CBlob@[] overlapping;
	this.getOverlapping(@overlapping);
	
	for (uint i = 0; i < overlapping.length; i++)
	{
		CBlob@ b = overlapping[i];
		if (b.hasTag("platform"))
		{
			BlockHooks@ blockHooks;
			b.get("BlockHooks", @blockHooks);
			if (blockHooks !is null)
				blockHooks.update("onBlockPlaced", @b);
		}
	}
}
