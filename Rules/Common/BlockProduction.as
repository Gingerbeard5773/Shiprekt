#include "MakeBlock.as"

//Produce a block by a player
void ProduceBlock(CRules@ this, CBlob@ blob, uint type, u8 amount = 1)
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
			CBlob@ b = makeBlock(Vec2f(i, 0) * Block::size, 0.0f, type, blobTeam);
        	blob_blocks.push_back(b);

			//set block infos
			b.set_Vec2f("offset", b.getPosition());			
        	b.set_u16("ownerID", blobID);
    		b.getShape().getVars().customData = -1; // don't push on island
    	}
	}
}

//Below unused by the current version of Shiprekt

/*Random _rb;
Random@[] _r;

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

void Reseed()
{
	CMap@ map = getMap();
	if (map is null)
	{
		warn("MAP IS MISSING: ONRESTART BLOCKPRODUCTION.AS");
		return;
	}

	u32 rseed = XORRandom(9999999); // map.getMapSeed() - doesn't work properly :(

	_r.clear();
	for (uint i = 0; i < getRules().getTeamsCount(); i++)
	{
		_r.push_back(Random(rseed));
	}
}

void MakeMultiBlock(Block::Type[]@ types, Vec2f[]@ offsets, Vec2f pos, CBlob@[]@ list, const uint count, const uint team)
{
	for (uint i = 0; i < count; i++)
		MakeBlock( types[i], offsets[i], pos, list, team );
}

void MakeRandomBlocks(const int blocksCount, Vec2f pos, CBlob@[]@ list, const uint team = -1)
{
	Vec2f[] offsets;
	Block::Type[] types;
	getRandomBlockTypes(@types, team);
	getRandomBlockShape(@offsets, blocksCount, team);
	if (blocksCount > 1 && blocksCount <= 4)
	{
		MakeMultiBlock( @types, @offsets, pos, list, blocksCount, team );
	}
	else
	{
		MakeBlock( types[0], Vec2f_zero, pos, list, team);
	}
}

void getRandomBlockShape( Vec2f[]@ offsets, const int blocksCount, int team )
{
	if (blocksCount == 4)
	{
		const uint shape = _r[team].NextRanged(7);
		switch (shape)
		{
			case 0: // O
			offsets.push_back(Vec2f(0, 0));
			offsets.push_back(Vec2f(1, 0));
			offsets.push_back(Vec2f(1, 1));
			offsets.push_back(Vec2f(0, 1));
			break;

			case 1: // I
			offsets.push_back(Vec2f(-1, 0));
			offsets.push_back(Vec2f(0, 0));
			offsets.push_back(Vec2f(1, 0));
			offsets.push_back(Vec2f(2, 0));
			break;

			case 2: // Z
			offsets.push_back(Vec2f(-1, 0));
			offsets.push_back(Vec2f(0, 0));
			offsets.push_back(Vec2f(0, 1));
			offsets.push_back(Vec2f(1, 1));
			break;

			case 3: // S
			offsets.push_back(Vec2f(0, 0));
			offsets.push_back(Vec2f(1, 0));
			offsets.push_back(Vec2f(-1, 1));
			offsets.push_back(Vec2f(0, 1));
			break;

			case 4: // L
			offsets.push_back(Vec2f(0, -1));
			offsets.push_back(Vec2f(0, 0));
			offsets.push_back(Vec2f(0, 1));
			offsets.push_back(Vec2f(1, 1));
			break;

			case 5: // J
			offsets.push_back(Vec2f(1, -1));
			offsets.push_back(Vec2f(1, 0));
			offsets.push_back(Vec2f(1, 1));
			offsets.push_back(Vec2f(0, 1));
			break;

			case 6: // T
			offsets.push_back(Vec2f(-1, 0));
			offsets.push_back(Vec2f(0, 0));
			offsets.push_back(Vec2f(1, 0));
			offsets.push_back(Vec2f(0, 1));
			break;
		}
	}
	else if (blocksCount == 2)
	{
		offsets.push_back(Vec2f(0, 0));
		offsets.push_back(Vec2f(1, 0));
	}
	else if (blocksCount == 3)
	{
		const uint shape = _r[team].NextRanged(3);
		switch (shape)
		{
			case 0: // O
			offsets.push_back(Vec2f(0, 0));
			offsets.push_back(Vec2f(1, 0));
			offsets.push_back(Vec2f(1, 1));
			break;

			case 1: // I
			offsets.push_back(Vec2f(-1, 0));
			offsets.push_back(Vec2f(0, 0));
			offsets.push_back(Vec2f(1, 0));
			break;

			case 2: // Z
			offsets.push_back(Vec2f(-1, 0));
			offsets.push_back(Vec2f(0, 0));
			offsets.push_back(Vec2f(0, 1));
			break;

			case 3: // S
			offsets.push_back(Vec2f(0, 0));
			offsets.push_back(Vec2f(1, 0));
			offsets.push_back(Vec2f(-1, 1));
			break;

			case 4: // L
			offsets.push_back(Vec2f(-1, 0));
			offsets.push_back(Vec2f(0, 0));
			offsets.push_back(Vec2f(1, 0));
			break;

			case 5: // J
			offsets.push_back(Vec2f(-1, 0));
			offsets.push_back(Vec2f(0, 0));
			offsets.push_back(Vec2f(1, 0));
			break;

			case 6: // T
			offsets.push_back(Vec2f(-1, 0));
			offsets.push_back(Vec2f(0, 0));
			offsets.push_back(Vec2f(1, 0));
			break;
		}
	}
}*/
