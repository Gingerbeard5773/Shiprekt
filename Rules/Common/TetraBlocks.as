#include "MakeBlock.as"

//legacy shiprekt code from classic days
//readded v1.53.2 and made compatible, unused

const string[] pool =
{
	"platform",
	"solid",
	"bomb",
	"seat",
	"propeller",
	"flak",
	"coupling"
};

f32[] weights =
{
	2.4f,   //platform
	1.3f,   //solid
	0.2f,   //bomb
	0.125f, //seat
	0.4f,   //propeller
	0.1f,   //flak
	0.2f    //coupling
};

Random@[] _r;
void Reseed()
{
	u32 rseed = XORRandom(9999999);

	_r.clear();
	for (uint i = 0; i < getRules().getTeamsCount(); i++)
	{
		_r.push_back(Random(rseed));
	}
}

void ProduceRandomBlocks(CBlob@ blob)
{
	const u16 blobID = blob.getNetworkID();
	const u8 blobTeam = blob.getTeamNum();
	const u8 random_amount = XORRandom(3) + 2; 

	string[] types = getRandomBlockTypes(blobTeam);
	Vec2f[] offsets = getRandomBlockShape(random_amount, blobTeam);
	
	for (uint i = 0; i < random_amount; i++)
	{
		CBlob@ b = makeBlock(offsets[i] * 8, 0.0f, types[i], blobTeam);
		blob.push("blocks", b.getNetworkID());
		
		//set block infos
		b.set_Vec2f("offset", b.getPosition());
		b.set_u16("ownerID", blobID);
		b.getShape().getVars().customData = -1; // don't push on island
	}
}

string[] getRandomBlockTypes(const u8&in team)
{
	string[] weighted_pool;
	const u8 count = pool.length;
	for (u8 i = 0; i < count; i++)
	{
		uint amount = Maths::Ceil(weights[i] * f32(count));
		while (amount > 0)
		{
			weighted_pool.push_back(pool[i]);
			amount--;
		}
	}

	if (_r.length == 0)
		Reseed();

	string[] types;
	for (uint i = 0; i < 4; i++)
	{
		types.push_back(weighted_pool[_r[team].NextRanged(weighted_pool.length)]);
	}

	return types;
}

Vec2f[] getRandomBlockShape(const u8&in blocksCount, const u8&in team)
{
	Vec2f[] offsets;
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
	else if (blocksCount == 1)
	{
		offsets.push_back(Vec2f(0, 0));
	}

	return offsets;
}
