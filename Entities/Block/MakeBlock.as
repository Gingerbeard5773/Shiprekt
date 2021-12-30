
CBlob@ makeBlock(Vec2f pos, f32 angle, string blockName, const int team = -1)
{
	CBlob@ block = server_CreateBlob(blockName, team, pos);
	if (block !is null) 
	{
		block.setAngleDegrees(angle);
		block.getShape().getVars().customData = 0;
		block.set_u32("placedTime", getGameTime());
	}
	return block;
}
