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
	f32 getWeight(const string blockName)
	{
		if (blockName =="propeller")
			return Weight::propeller;
		if (blockName == "ramengine")
			return Weight::ramengine;
		if (blockName == "solid")
			return Weight::solid;
		if (blockName == "door")
			return Weight::door;
		if (blockName == "ram")
			return Weight::ram;
		if (blockName == "fakeram")
			return Weight::fakeram;
		if (blockName == "antiram")
			return Weight::antiram;
		if (blockName == "platform")
			return Weight::platform;
		if (blockName == "cannon")
			return Weight::cannon;
		if (blockName == "harvester")
			return Weight::harvester;
		if (blockName == "patcher")
			return Weight::patcher;
		if (blockName == "harpoon")
			return Weight::harpoon;
		if (blockName == "machinegun")
			return Weight::machinegun;
		if (blockName == "flak")
			return Weight::flak;
		if (blockName == "pointdefense")
			return Weight::pointdefense;
		if (blockName == "launcher")
			return Weight::launcher;
		if (blockName == "seat")
			return Weight::seat;
		if (blockName == "coupling")
			return Weight::coupling;
		if (blockName == "repulsor")
			return Weight::repulsor;
		if (blockName == "bomb")
			return Weight::bomb;		
		if (blockName == "secondarycore")
			return Weight::secondarycore;
		if (blockName == "decoycore")
			return Weight::decoycore;
		if (blockName == "hyperflak")
			return Weight::hyperflak;
	
		return blockName == "mothership" ? Weight::mothership : Weight::platform;
	}

	f32 getWeight(CBlob@ blob)
	{
		return getWeight(blob.getName());
	}
	
	u16 getCost(const string blockName)
	{
		if (blockName == "station")
			return Cost::station;
		if (blockName == "ministation")
			return Cost::ministation;
		if (blockName =="propeller")
			return Cost::propeller;
		if (blockName == "ramengine")
			return Cost::ramengine;
		if (blockName == "solid")
			return Cost::solid;
		if (blockName == "door")
			return Cost::door;
		if (blockName == "ram")
			return Cost::ram;
		if (blockName == "fakeram")
			return Cost::fakeram;
		if (blockName == "antiram")
			return Cost::antiram;
		if (blockName == "platform")
			return Cost::platform;
		if (blockName == "cannon")
			return Cost::cannon;
		if (blockName == "harvester")
			return Cost::harvester;
		if (blockName == "patcher")
			return Cost::patcher;
		if (blockName == "harpoon")
			return Cost::harpoon;
		if (blockName == "machinegun")
			return Cost::machinegun;
		if (blockName == "flak")
			return Cost::flak;
		if (blockName == "pointdefense")
			return Cost::pointdefense;
		if (blockName == "launcher")
			return Cost::launcher;
		if (blockName == "seat")
			return Cost::seat;
		if (blockName == "coupling")
			return Cost::coupling;
		if (blockName == "repulsor")
			return Cost::repulsor;
		if (blockName == "bomb")
			return Cost::bomb;		
		if (blockName == "secondarycore")
			return Cost::secondarycore;
		if (blockName == "decoycore")
			return Cost::decoycore;
		if (blockName == "hyperflak")
			return Cost::hyperflak;
	
		return 0;
	}
	
	f32 getCost(CBlob@ blob)
	{
		return getCost(blob.getName());
	}
};
