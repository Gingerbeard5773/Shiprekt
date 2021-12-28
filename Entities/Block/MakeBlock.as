#include "BlockCommon.as"

CBlob@ makeBlock(Vec2f pos, f32 angle, u16 blockType, const int team = -1)
{
	string blockname = "block";
	
	switch(blockType)		
	{
		case Block::BOMB:
		blockname = "bomb";
		break;
		case Block::CANNON:
		blockname = "cannon";
		break;
		case Block::COUPLING:
		blockname = "coupling";
		break;
		case Block::DECOYCORE:
		blockname = "decoycore";
		break;
		case Block::DOOR:
		blockname = "door";
		break;
		case Block::FLAK:
		blockname = "flak";
		break;
		case Block::HARPOON:
		blockname = "harpoon";
		break;
		case Block::HARVESTER:
		blockname = "harvester";
		break;
		case Block::HYPERFLAK:
		blockname = "hyperflak";
		break;
		case Block::LAUNCHER:
		blockname = "launcher";
		break;
		case Block::MACHINEGUN:
		blockname = "machinegun";
		break;
		case Block::MOTHERSHIP5:
		blockname = "mothership";
		break;
		case Block::PATCHER:
		blockname = "patcher";
		break;
		case Block::POINTDEFENSE:
		blockname = "pointdefense";
		break;
		case Block::RAMENGINE:
		blockname = "ramengine";
		break;
		case Block::PROPELLER:
		blockname = "propeller";
		break;
		case Block::REPULSOR:
		blockname = "repulsor";
		break;
		case Block::SEAT:
		blockname = "seat";
		break;
		case Block::SECONDARYCORE:
		blockname = "secondarycore";
		break;
		case Block::SOLID:
		blockname = "solid";
		break;
		case Block::ANTIRAM:
		blockname = "antiram";
		break;
		case Block::RAM:
		blockname = "ram";
		break;
		case Block::FAKERAM:
		blockname = "fakeram";
		break;
	}
	CBlob@ block = server_CreateBlob(blockname, team, pos);
	if (block !is null) 
	{
		print(blockname);
		block.getSprite().SetFrame(blockType);
		block.setAngleDegrees(angle);
		block.getShape().getVars().customData = 0;
		block.set_u32("placedTime", getGameTime());
	}
	return block;
}
