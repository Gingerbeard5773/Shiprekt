#include "MakeBlock.as"

//Produce a block by a player
void ProduceBlock(CRules@ this, CBlob@ blob, string type, u8 amount = 1)
{
	const int blobTeam = blob.getTeamNum();

	if (isServer())
	{
    	CBlob@[]@ blob_blocks;
	    blob.get("blocks", @blob_blocks);
    	blob_blocks.clear();

		u16 blobID = blob.getNetworkID();

    	for (uint i = 0; i < amount; i++)
		{
			CBlob@ b = makeBlock(Vec2f(i, 0) * 8, 0.0f, type, blobTeam);
        	blob_blocks.push_back(b);

			//set block infos
			b.set_Vec2f("offset", b.getPosition());			
        	b.set_u16("ownerID", blobID);
    		b.getShape().getVars().customData = -1; // don't push on ship
    	}
	}
}
