shared CBlob@ makeBlock(const Vec2f pos, const f32 angle, const string blockName, const u8 team)
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
