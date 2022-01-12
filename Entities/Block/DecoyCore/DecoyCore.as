#include "BlockHooks.as";
void onInit(CBlob@ this)
{
	this.Tag("decoyCore");
	
	this.set_u16("cost", 150);
	this.set_f32("weight", 6.0f);

	if (isClient())
	{
		//add an additional frame to the damage frames animation
		CSprite@ sprite = this.getSprite();
		Animation@ animation = sprite.getAnimation("default");
		if (animation !is null)
		{
			array<int> frames = {3};
			animation.AddFrames(frames);
		}
	}
	
	BlockHooks@ blockHooks;
	this.get("BlockHooks", @blockHooks);
	blockHooks.addHook("onBlockPlaced", @onBlockPlaced);
}

void onBlockPlaced(CBlob@ this) //called when the block has been placed
{
	int teamNum = this.getTeamNum();
	CRules@ rules = getRules();
	if (!rules.exists("decoyCoreCount" + teamNum))
	{
		rules.set_u8("decoyCoreCount" + teamNum, 0);
		rules.Sync("decoyCoreCount" + teamNum, true);
	}

	rules.add_u8("decoyCoreCount" + teamNum, 1);
	rules.Sync("decoyCoreCount" + teamNum, true);
}
