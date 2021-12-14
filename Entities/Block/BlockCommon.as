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
		ANTIRAM = 46,
	
		COUPLING = 35,
		DOOR = 12,

		PROPELLER = 16,
		RAMENGINE = 17,
		PROPELLER_A1 = 32,
		PROPELLER_A2 = 33,
		
		SEAT = 23,
		RAMCHAIR = 2,

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
		STATION_A1 = 72,
		
		MINISTATION = 116,
		MINISTATION_A1 = 14,
		
		HARVESTER = 42,
		HARVESTER_A1 = 67,

		PATCHER = 51,
		PATCHER_A1 = 69,
		
		HARPOON = 43,
		HARPOON_A1 = 75,
		HARPOON_A2 = 76,
		
		MACHINEGUN = 34,
		MACHINEGUN_A1 = 27,
		MACHINEGUN_A2 = 28,
		MACHINEGUN_A3 = 29,
		
		LAUNCHER = 36,
		LAUNCHER1 = 51,

		CANNON = 7,
		CANNON_A1 = 30,
		CANNON_A2 = 31,
		
		FLAK = 22,
		FLAK_A1 = 11,
		FLAK_A2 = 12,
		
		HYPERFLAK = 31,
		HYPERFLAK_A1 = 19,
		HYPERFLAK_A2 = 20,
		
		POINTDEFENSE = 37,
		POINTDEFENSE_A1 = 59,
		POINTDEFENSE_A2 = 60,
		
		BOMB = 19,
		BOMB_A1 = 20,
		BOMB_A2 = 21,
		
		REPULSOR = 28,
		REPULSOR_A1 = 29,
		REPULSOR_A2 = 30,

		SECONDARYCORE = 65,
		DECOYCORE = 66,
	};
					
	shared class Weights
	{
		f32 mothership;
		f32 wood;
		f32 ram;
		f32 fakeram;
		f32 antiram;
		f32 solid;
		f32 door;
		f32 propeller;
		f32 ramEngine;
		f32 seat;
		f32 ramChair;
		f32 cannon;
		f32 station;
		f32 ministation;
		f32 harvester;
		f32 patcher;
		f32 harpoon;
		f32 machinegun;
		f32 flak;
		f32 hyperflak;
		f32 pointDefense;
		f32 launcher;
		f32 bomb;
		f32 coupling;
		f32 repulsor;
		f32 secondaryCore;
		f32 decoyCore;
	}
	
	Weights@ queryWeights(CRules@ this)
	{
		ConfigFile cfg;
		if (!cfg.loadFile("SHRKTVars.cfg")) 
			return null;
		
		print("** Getting Weights from cfg");
		Block::Weights w;

		w.mothership = cfg.read_f32("w_mothership");
		w.wood = cfg.read_f32("w_wood");
		w.ram = cfg.read_f32("w_ram");
		w.fakeram = cfg.read_f32("w_fakeram");
		w.antiram = cfg.read_f32("w_antiram");
		w.solid = cfg.read_f32("w_solid");
		w.door = cfg.read_f32("w_door");
		w.propeller = cfg.read_f32("w_propeller");
		w.ramEngine = cfg.read_f32("w_ramEngine");
		w.seat = cfg.read_f32("w_seat");
		w.ramChair = cfg.read_f32("w_ramChair");
		w.cannon = cfg.read_f32("w_cannon");
		w.harvester = cfg.read_f32("w_harvester");
		w.patcher = cfg.read_f32("w_patcher");
		w.harpoon = cfg.read_f32("w_harpoon");
		w.machinegun = cfg.read_f32("w_machinegun");
		w.flak = cfg.read_f32("w_flak");
		w.hyperflak = cfg.read_f32("w_hyperflak");
		w.pointDefense = cfg.read_f32("w_pointDefense");
		w.launcher = cfg.read_f32("w_launcher");
		w.bomb = cfg.read_f32("w_bomb");
		w.coupling = cfg.read_f32("w_coupling");
		w.repulsor = cfg.read_f32("w_repulsor");
		w.secondaryCore = cfg.read_f32("w_secondaryCore");
		w.decoyCore = cfg.read_f32("w_decoyCore");

		this.set("weights", w);
		return @w;
	}
	
	Weights@ getWeights(CRules@ this)
	{
		Block::Weights@ w;
		this.get("weights", @w);
		
		if (w is null)
			@w = Block::queryWeights(this);

		return w;
	}
	
	shared class Costs
	{
		u16 station;
		u16 ministation;
		u16 wood;
		u16 ram;
		u16 fakeram;
		u16 antiram;
		u16 solid;
		u16 door;
		u16 propeller;
		u16 ramEngine;
		u16 seat;
		u16 ramChair;
		u16 cannon;
		u16 harvester;
		u16 patcher;
		u16 harpoon;
		u16 machinegun;
		u16 flak;
		u16 hyperflak;
		u16 pointDefense;
		u16 launcher;
		u16 bomb;
		u16 coupling;
		u16 repulsor;
		u16 secondaryCore;
		u16 decoyCore;
	}
	
	Costs@ queryCosts(CRules@ this)
	{
		ConfigFile cfg;
		if (!cfg.loadFile("SHRKTVars.cfg")) 
			return null;
		
		print("** Getting Costs from cfg");
		Block::Costs c;
		
		c.station = 100;
		c.ministation = 40;
		c.wood = cfg.read_u16("cost_wood");
		c.ram = cfg.read_u16("cost_ram");
		c.fakeram = cfg.read_u16("cost_fakeram");
		c.antiram = cfg.read_u16("cost_antiram");
		c.solid = cfg.read_u16("cost_solid");
		c.door = cfg.read_u16("cost_door");
		c.propeller = cfg.read_u16("cost_propeller");
		c.ramEngine = cfg.read_u16("cost_ramEngine");
		c.seat = cfg.read_u16("cost_seat");
		c.ramChair = cfg.read_u16("cost_ramChair");
		c.cannon = cfg.read_u16("cost_cannon");
		c.harvester = cfg.read_u16("cost_harvester");
		c.patcher = cfg.read_u16("cost_patcher");
		c.harpoon = cfg.read_u16("cost_harpoon");
		c.machinegun = cfg.read_u16("cost_machinegun");
		c.flak = cfg.read_u16("cost_flak");
		c.hyperflak = cfg.read_u16("cost_hyperflak");
		c.pointDefense = cfg.read_u16("cost_pointDefense");
		c.launcher = cfg.read_u16("cost_launcher");
		c.bomb = cfg.read_u16("cost_bomb");
		c.coupling = cfg.read_u16("cost_coupling");
		c.repulsor = cfg.read_u16("cost_repulsor");
		c.secondaryCore = cfg.read_u16("cost_secondaryCore");
		c.decoyCore = cfg.read_u16("cost_decoyCore");

		this.set("costs", c);
		return @c;
	}
	
	Costs@ getCosts(CRules@ this)
	{
		Block::Costs@ c;
		this.get("costs", @c);
		
		if (c is null)
			@c = Block::queryCosts(this);
			
		return c;
	}
	
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

	f32 getWeight (const uint blockType)
	{
		CRules@ rules = getRules();
		
		Weights@ w = Block::getWeights(rules);

		if (w is null)
		{
			warn("** Couldn't get Weights!");
			return 0;
		}
		
		switch(blockType)		
		{
			case Block::PROPELLER:
				return w.propeller;
			break;
			case Block::RAMENGINE:
				return w.ramEngine;
			break;
			case Block::SOLID:
				return w.solid;
			break;
			case Block::DOOR:
				return w.door;
			break;
			case Block::RAM:
				return w.ram;
			break;
			case Block::FAKERAM:
				return w.fakeram;
			break;
			case Block::ANTIRAM:
				return w.antiram;
			break;
			case Block::PLATFORM:
				return w.wood;
			break;
			case Block::CANNON:
				return w.cannon;
			break;
			case Block::HARVESTER:
				return w.harvester;
			break;
			case Block::PATCHER:
				return w.patcher;
			break;
			case Block::HARPOON:
				return w.harpoon;
			break;
			case Block::MACHINEGUN:
				return w.machinegun;
			break;
			case Block::FLAK:
				return w.flak;
			break;
			case Block::POINTDEFENSE:
				return w.pointDefense;
			break;
			case Block::LAUNCHER:
				return w.launcher;
			break;
			case Block::SEAT:
				return w.seat;
			break;
			case Block::RAMCHAIR:
				return w.ramChair;
			break;
			case Block::COUPLING:
				return w.coupling;
			break;
			case Block::REPULSOR:
				return w.repulsor;
			break;
			case Block::BOMB:
				return w.bomb;
			break;			
			case Block::SECONDARYCORE:
				return w.secondaryCore;
			break;
			case Block::DECOYCORE:
				return w.decoyCore;
			break;
			case Block::HYPERFLAK:
				return w.hyperflak;
			break;
		}
	
		return blockType == MOTHERSHIP5 ? w.mothership : w.wood;//MOTHERSHIP5 is the core block
	}

	f32 getWeight (CBlob@ blob)
	{
		return getWeight(getType(blob));
	}
	
	u16 getCost (const uint blockType)
	{
		CRules@ rules = getRules();
		
		Costs@ c = Block::getCosts(rules);

		if (c is null)
		{
			warn("** Couldn't get Costs!");
			return 0;
		}
		
		switch(blockType)		
		{
			case Block::STATION:
				return c.station;
			break;
			case Block::MINISTATION:
				return c.ministation;
			break;
			case Block::PROPELLER:
				return c.propeller;
			break;
			case Block::RAMENGINE:
				return c.ramEngine;
			break;
			case Block::SOLID:
				return c.solid;
			break;
			case Block::DOOR:
				return c.door;
			break;
			case Block::RAM:
				return c.ram;
			break;
			case Block::FAKERAM:
				return c.fakeram;
			break;
			case Block::ANTIRAM:
				return c.antiram;
			break;
			case Block::PLATFORM:
				return c.wood;
			break;
			case Block::CANNON:
				return c.cannon;
			break;
			case Block::HARVESTER:
				return c.harvester;
			break;
			case Block::PATCHER:
				return c.patcher;
			break;
			case Block::HARPOON:
				return c.harpoon;
			break;
			case Block::MACHINEGUN:
				return c.machinegun;
			break;
			case Block::FLAK:
				return c.flak;
			break;
			case Block::POINTDEFENSE:
				return c.pointDefense;
			break;
			case Block::LAUNCHER:
				return c.launcher;
			break;
			case Block::SEAT:
				return c.seat;
			break;
			case Block::RAMCHAIR:
				return c.ramChair;
			break;
			case Block::COUPLING:
				return c.coupling;
			break;	
			case Block::REPULSOR:
				return c.repulsor;
			break;
			case Block::BOMB:
				return c.bomb;
			break;			
			case Block::SECONDARYCORE:
				return c.secondaryCore;
			break;
			case Block::DECOYCORE:
				return c.decoyCore;
			break;
			case Block::HYPERFLAK:
				return c.hyperflak;
			break;
		}
	
		return 0;
	}

	const f32 BUTTON_RADIUS_FLOOR = 6;
	const f32 BUTTON_RADIUS_SOLID = 10;

};