void onRestart( CRules@ this )
{
	for (uint i = 0; i < 11; ++i)
	{
		this.set_u8("decoyCoreCount" + i, 0);
		this.Sync("decoyCoreCount" + i, true);
	}
}