//BlockCommon
//Costs, Weight, frames for individual blocks set here

namespace Cost
{
	// Block Costs

	const u16
	station = 100,
	ministation = 40,
	platform = 15,
	seat = 25,
	propeller = 45,
	ramengine = 50,
	solid = 35,
	door = 60,
	ram = 50,
	fakeram = 30,
	antiram = 35,
	coupling = 5,
	repulsor = 15,
	launcher = 400,
	harvester = 75,
	patcher = 200,
	harpoon = 65,
	machinegun = 125,
	cannon = 250,
	flak = 175,
	hyperflak = 300,
	pointdefense = 160,
	bomb = 30,
	secondarycore = 800,
	decoycore = 150;
};

namespace Weight
{
	// Block Weights
	const f32
	platform = 0.2,
	seat = 0.5,
	propeller = 1.00,
	ramengine = 1.25,
	solid = 0.75,
	door = 1.0,
	ram = 2.0,
	fakeram = 0.5,
	antiram = 0.75,
	coupling = 0.1,
	repulsor = 0.25,
	mothership = 12.0,
	launcher = 4.5,
	harvester = 2.0,
	patcher = 3.0,
	harpoon = 2.0,
	machinegun = 2.0,
	cannon = 3.25,
	flak = 2.5,
	hyperflak = 5.0,
	pointdefense = 3.5,
	bomb = 2.0,
	secondarycore = 12.0,
	decoycore = 6.0;
};

namespace Block
{
	const int size = 8;

	enum Type 
	{
		PLATFORM = 0,
		PLATFORM2 = 1,
		SOLID = 4,
		RAM = 8,
		FAKERAM = 48,
		ANTIRAM = 45,
	
		COUPLING = 35,
		DOOR = 12,

		PROPELLER = 16,
		RAMENGINE = 17,
		PROPELLER_A1 = 32,
		PROPELLER_A2 = 33,
		
		SEAT = 23,

		MOTHERSHIP1 = 80,
		MOTHERSHIP2 = 81,
		MOTHERSHIP3 = 82,
		MOTHERSHIP4 = 96,
		MOTHERSHIP5 = 97,
		MOTHERSHIP6 = 98,
		MOTHERSHIP7 = 112,
		MOTHERSHIP8 = 113,
		MOTHERSHIP9 = 114,
		
		STATION = 115,
		MINISTATION = 116,
		
		HARVESTER = 42,
		PATCHER = 51,
		HARPOON = 43,
		MACHINEGUN = 34,
		LAUNCHER = 36,
		CANNON = 7,
		FLAK = 22,
		HYPERFLAK = 31,
		POINTDEFENSE = 37,
		
		BOMB = 19,
		BOMB_A1 = 20,
		BOMB_A2 = 21,
		
		REPULSOR = 28,
		REPULSOR_A1 = 29,
		REPULSOR_A2 = 30,

		SECONDARYCORE = 65,
		DECOYCORE = 66,
	};
	
	bool isSolid(const uint blockType)
	{
		return (blockType == Block::SOLID || blockType == Block::PROPELLER || blockType == Block::RAMENGINE || blockType == Block::RAM || blockType == Block::FAKERAM || blockType == Block::ANTIRAM || blockType == Block::POINTDEFENSE);
	}

	bool isCore(const uint blockType)
	{
		return (blockType >= Block::MOTHERSHIP1 && blockType <= Block::MOTHERSHIP9);
	}

	bool isBomb(const uint blockType)
	{
		return (blockType >= 19 && blockType <= 21);
	}
	
	bool isRepulsor(const uint blockType)
	{
		return (blockType >= 28 && blockType <= 30);
	}

	bool isType(CBlob@ blob, const uint blockType)
	{
		return (blob.getSprite().getFrame() == blockType);
	}

	uint getType(CBlob@ blob)
	{
		return blob.getSprite().getFrame();
	}

	f32 getWeight(const uint blockType)
	{
		switch(blockType)		
		{
			case Block::PROPELLER:
				return Weight::propeller;
			break;
			case Block::RAMENGINE:
				return Weight::ramengine;
			break;
			case Block::SOLID:
				return Weight::solid;
			break;
			case Block::DOOR:
				return Weight::door;
			break;
			case Block::RAM:
				return Weight::ram;
			break;
			case Block::FAKERAM:
				return Weight::fakeram;
			break;
			case Block::ANTIRAM:
				return Weight::antiram;
			break;
			case Block::PLATFORM:
				return Weight::platform;
			break;
			case Block::CANNON:
				return Weight::cannon;
			break;
			case Block::HARVESTER:
				return Weight::harvester;
			break;
			case Block::PATCHER:
				return Weight::patcher;
			break;
			case Block::HARPOON:
				return Weight::harpoon;
			break;
			case Block::MACHINEGUN:
				return Weight::machinegun;
			break;
			case Block::FLAK:
				return Weight::flak;
			break;
			case Block::POINTDEFENSE:
				return Weight::pointdefense;
			break;
			case Block::LAUNCHER:
				return Weight::launcher;
			break;
			case Block::SEAT:
				return Weight::seat;
			break;
			case Block::COUPLING:
				return Weight::coupling;
			break;
			case Block::REPULSOR:
				return Weight::repulsor;
			break;
			case Block::BOMB:
				return Weight::bomb;
			break;			
			case Block::SECONDARYCORE:
				return Weight::secondarycore;
			break;
			case Block::DECOYCORE:
				return Weight::decoycore;
			break;
			case Block::HYPERFLAK:
				return Weight::hyperflak;
			break;
		}
	
		return blockType == MOTHERSHIP5 ? Weight::mothership : Weight::platform;//MOTHERSHIP5 is the core block
	}

	f32 getWeight(CBlob@ blob)
	{
		return getWeight(getType(blob));
	}
	
	u16 getCost(const uint blockType)
	{
		switch(blockType)		
		{
			case Block::STATION:
				return Cost::station;
			break;
			case Block::MINISTATION:
				return Cost::ministation;
			break;
			case Block::PROPELLER:
				return Cost::propeller;
			break;
			case Block::RAMENGINE:
				return Cost::ramengine;
			break;
			case Block::SOLID:
				return Cost::solid;
			break;
			case Block::DOOR:
				return Cost::door;
			break;
			case Block::RAM:
				return Cost::ram;
			break;
			case Block::FAKERAM:
				return Cost::fakeram;
			break;
			case Block::ANTIRAM:
				return Cost::antiram;
			break;
			case Block::PLATFORM:
				return Cost::platform;
			break;
			case Block::CANNON:
				return Cost::cannon;
			break;
			case Block::HARVESTER:
				return Cost::harvester;
			break;
			case Block::PATCHER:
				return Cost::patcher;
			break;
			case Block::HARPOON:
				return Cost::harpoon;
			break;
			case Block::MACHINEGUN:
				return Cost::machinegun;
			break;
			case Block::FLAK:
				return Cost::flak;
			break;
			case Block::POINTDEFENSE:
				return Cost::pointdefense;
			break;
			case Block::LAUNCHER:
				return Cost::launcher;
			break;
			case Block::SEAT:
				return Cost::seat;
			break;
			case Block::COUPLING:
				return Cost::coupling;
			break;	
			case Block::REPULSOR:
				return Cost::repulsor;
			break;
			case Block::BOMB:
				return Cost::bomb;
			break;			
			case Block::SECONDARYCORE:
				return Cost::secondarycore;
			break;
			case Block::DECOYCORE:
				return Cost::decoycore;
			break;
			case Block::HYPERFLAK:
				return Cost::hyperflak;
			break;
		}
	
		return 0;
	}
	
	f32 getCost(CBlob@ blob)
	{
		return getCost(getType(blob));
	}

	const f32 BUTTON_RADIUS_FLOOR = 6;
	const f32 BUTTON_RADIUS_SOLID = 10;

};
