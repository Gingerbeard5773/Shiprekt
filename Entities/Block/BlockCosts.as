const u16 getCost(const string&in blockName, const bool&in normalCost = false)
{
	ConfigFile cfg;
	if (!cfg.loadFile("BlockVars.cfg"))
		return 0;
	
	if (!cfg.exists(blockName))
	{
		warn("BlockCosts.as: Cost not found! : "+blockName);
		return 0;
	}
	u16 cost = cfg.read_u16(blockName);
	u16 warmup_cost = cfg.read_u16("warmup_"+blockName, cost);

	if (getRules().isWarmup() && !normalCost)
		return warmup_cost;
	
	return cost;
}
