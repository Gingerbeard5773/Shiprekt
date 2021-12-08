namespace Human
{
	const float walkSpeed = 1.0f;
	const float swimSlow = 0.4f;
};

// helper functions

namespace Human
{
	bool isHoldingBlocks(CBlob@ this)
	{
	   	CBlob@[]@ blob_blocks;
	    this.get("blocks", @blob_blocks);
	    return blob_blocks.length > 0;
	}
	
	bool wasHoldingBlocks(CBlob@ this)
	{
		return getGameTime() - this.get_u32("placedTime") < 10;
	}
	
	void clearHeldBlocks(CBlob@ this)
	{
		CBlob@[]@ blocks;
		if (this.get("blocks", @blocks))                 
		{
			for (uint i = 0; i < blocks.length; ++i)
			{
				blocks[i].Tag("disabled");
				blocks[i].server_Die();
			}

			blocks.clear();
		}
	}
}
