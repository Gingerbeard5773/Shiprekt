#include "MakeBlock.as";

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	if (isServer())
	{
		Vec2f[] spawns;			 
    	if (getMap().getMarkers("spawn", spawns))
		{
			u8 pCount = getPlayerCount();
			
			for (u8 p = 0; p < pCount; p++)//discard spectators
			{
				CPlayer@ player = getPlayer(p);
				if (player.getTeamNum() == this.getSpectatorTeamNum())
					pCount --;
			}
			
			u8 availableCores = Maths::Min(spawns.length, this.getTeamsNum());
			u8 playingCores = pCount == 3 ? 3 : Maths::Max(2, int(Maths::Floor(pCount/2)));//special case for 3 players
			u8 mShipsToSpawn = Maths::Min(playingCores, availableCores);
			print("** Spawning " + mShipsToSpawn + " motherships of " + availableCores + " for " + pCount + " players");
			
			for (u8 s = 0; s < mShipsToSpawn; s ++)
			{
				//quick fix: cyan looks too much like blue
				u8 team = s;
				if (team == 5)
					team = 7;
				else if (team == 7)
					team = 5;
					
        		SpawnMothership(spawns[s], team);
			}
    	}
    }
	//should find a better place for these
	this.set_bool("whirlpool", false);
    CCamera@ camera = getCamera();
    if (camera !is null)
    	camera.setRotation(0.0f);
}

void SpawnMothership(Vec2f pos, const int team)
{
	// platforms
	
	makeBlock(pos + Vec2f(-8, -8), 0.0f, "platform", team);
	makeBlock(pos + Vec2f(0, -8), 0.0f, "platform", team).getSprite().SetFrame(2);
	makeBlock(pos + Vec2f(8, -8), 0.0f, "platform", team);

	makeBlock(pos + Vec2f(-8, 0), 0.0f, "platform", team).getSprite().SetFrame(5);	
	makeBlock(pos, 0.0f, "mothership", team);
	makeBlock(pos + Vec2f(8, 0), 0.0f, "platform", team).getSprite().SetFrame(3);

	makeBlock(pos + Vec2f(-8, 8), 0.0f, "platform", team);
	makeBlock(pos + Vec2f(0, 8), 0.0f, "platform", team).getSprite().SetFrame(4);
	makeBlock(pos + Vec2f(8, 8), 0.0f, "platform", team);

	// surrounding

	makeBlock(pos + Vec2f(-8*2, -8*1), 0.0f, "solid", team);
	makeBlock(pos + Vec2f(-8*2, -8*2), 0.0f, "solid", team);
	makeBlock(pos + Vec2f(-8*1, -8*2), 0.0f, "solid", team);

	makeBlock(pos + Vec2f(0, -8*2), 0.0f, "platform", team);

	makeBlock(pos + Vec2f(8*1, -8*2), 0.0f, "solid", team);
	makeBlock(pos + Vec2f(8*2, -8*2), 0.0f, "solid", team);
	makeBlock(pos + Vec2f(8*2, -8*1), 0.0f, "solid", team);

	makeBlock(pos + Vec2f(8*2, 0), 0.0f, "platform", team);

	makeBlock(pos + Vec2f(8*2, 8*1), 0.0f, "solid", team);
	makeBlock(pos + Vec2f(8*2, 8*2), 0.0f, "solid", team);
	makeBlock(pos + Vec2f(8*1, 8*2), 0.0f, "solid", team);

	makeBlock(pos + Vec2f(0, 8*2), 0.0f, "platform", team);

	makeBlock(pos + Vec2f(-8*1, 8*2), 0.0f, "solid", team);
	makeBlock(pos + Vec2f(-8*2, 8*2), 0.0f, "solid", team);
	makeBlock(pos + Vec2f(-8*2, 8*1), 0.0f, "solid", team);

	makeBlock(pos + Vec2f(-8*2, 0), 0.0f, "platform", team);
}
