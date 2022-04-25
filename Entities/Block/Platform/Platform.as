#include "BlockHooks.as";
void onInit(CBlob@ this)
{
	this.Tag("platform");
	
	this.set_f32("weight", 0.2f);
	
	BlockHooks@ blockHooks;
	this.get("BlockHooks", @blockHooks);
	blockHooks.addHook("onColored", @onColored); //add onBlockPlaced hook
}

void onColored(CBlob@ this) //activate when the block is placed
{
	updateCores(this);
}

void onDie(CBlob@ this)
{
	updateCores(this);
}

void updateCores(CBlob@ this)
{
	//for core rings
	if (this.getShape().getVars().customData <= 0 || !isClient())
		return;
	
	CBlob@[] overlapping;
	this.getOverlapping(@overlapping);
	
	const u8 overlappingLength = overlapping.length;
	for (u8 i = 0; i < overlappingLength; i++)
	{
		CBlob@ b = overlapping[i];
		if (b.hasTag("core"))
			b.set_bool("updateLayers", true);
	}
}
