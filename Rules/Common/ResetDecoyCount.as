void onRestart(CRules@ this)
{
	for (uint i = 0; i < 10; ++i) //using getTeamsNum() causes a crash when onRestart is called, use const numbers instead
	{
		this.set_u8("decoyCoreCount" + i, 0);
		this.Sync("decoyCoreCount" + i, true);
	}
}
