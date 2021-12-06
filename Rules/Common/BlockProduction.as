#include "TetraBlocks.as"

Random _rb;
int randomBlock = 1;

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	Reseed();
	if (getMap() !is null)
	{
		_rb.Reset(XORRandom(9999999));
	}
}

void ProduceBlock(CRules@ this, CBlob@ blob, uint type, u8 ammount = 1)
{
	const int blobTeam = blob.getTeamNum();

	if (isServer())
	{
		CBlob@[] blocks;
		for (int i = 0; i < ammount; i++)
		{
			MakeBlock(type, Vec2f(i, 0), Vec2f_zero, @blocks, blobTeam);
		}

    	CBlob@[]@ blob_blocks;
	    blob.get("blocks", @blob_blocks);
    	blob_blocks.clear();
		u16 blobID = blob.getNetworkID();
		u16 playerID = blob.getPlayer().getNetworkID();
    	for (uint i = 0; i < blocks.length; i++)
		{
    		CBlob@ b = blocks[i];
        	blob_blocks.push_back(b);	        
        	b.set_u16("ownerID", blobID);
        	b.set_u16("playerID", playerID);
    		b.getShape().getVars().customData = -1; // don't push on island
    	}
	}
}