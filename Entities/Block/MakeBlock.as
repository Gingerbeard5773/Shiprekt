#include "BlockCommon.as"

CBlob@ makeBlock( Vec2f pos, f32 angle, u16 blockType, const int team = -1 )
{
	CBlob@ block = server_CreateBlob( "block", team, pos );
	if (block !is null) 
	{
		block.getSprite().SetFrame( blockType );
		block.set_f32( "weight", Block::getWeight( block ) );
		block.setAngleDegrees( angle );
		
		switch(blockType)		
		{
			case Block::PROPELLER:
			block.AddScript("Propeller.as");
			break;
			case Block::RAMENGINE:
			block.AddScript("RamEngine.as");
			break;
			case Block::SEAT:
			block.AddScript("GetInSeat.as"); // so oninit doesnt override
			block.AddScript("Seat.as");
			break;		
			case Block::COUPLING:
			block.AddScript("Coupling.as");
			break;
			case Block::DOOR:
			block.AddScript("Door.as");
			break;		
			case Block::REPULSOR:
			block.AddScript("Repulsor.as");
			break;
			case Block::HARVESTER:
			block.AddScript("Harvester.as");
			break;
			case Block::PATCHER:
			block.AddScript("Patcher.as");
			break;
			case Block::HARPOON:
			block.AddScript("GetInSeat.as");
			block.AddScript("Harpoon.as");
			break;
			case Block::MACHINEGUN:
			block.AddScript("Machinegun.as");
			break;
			case Block::LAUNCHER:
			block.AddScript("Launcher.as");
			break;
			case Block::CANNON:
			block.AddScript("Cannon.as");
			break;
			case Block::FLAK:
			block.AddScript("GetInSeat.as");
			block.AddScript("Flak.as");
			break;
			case Block::HYPERFLAK:
			block.AddScript("GetInSeat.as");
			block.AddScript("HyperFlak.as");
			break;
			case Block::POINTDEFENSE:
			block.AddScript("PointDefense.as");
			break;
			case Block::BOMB:
			block.AddScript("Bomb.as");
			break;	
			case Block::SECONDARYCORE:
			block.AddScript("SecondaryCore.as");
			break;
			case Block::DECOYCORE:
			block.AddScript("DecoyCore.as");
			break;
		}
		
		block.getShape().getVars().customData = 0;
		block.set_u32( "placedTime", getGameTime() );
	}
	return block;
}
