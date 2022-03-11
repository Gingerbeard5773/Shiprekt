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
		Vec2f spawnOffset(4.0f, 4.0f); //align to tilegrid
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
        		SpawnMothership(spawns[s] + spawnOffset, s);
			}
    	}
    }
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

	makeBlock(pos + Vec2f(0, -8*2), 0.0f, "platform", team).getSprite().SetFrame(1);

	makeBlock(pos + Vec2f(8*1, -8*2), 0.0f, "solid", team);
	makeBlock(pos + Vec2f(8*2, -8*2), 0.0f, "solid", team);
	makeBlock(pos + Vec2f(8*2, -8*1), 0.0f, "solid", team);

	makeBlock(pos + Vec2f(8*2, 0), 0.0f, "platform", team).getSprite().SetFrame(1);

	makeBlock(pos + Vec2f(8*2, 8*1), 0.0f, "solid", team);
	makeBlock(pos + Vec2f(8*2, 8*2), 0.0f, "solid", team);
	makeBlock(pos + Vec2f(8*1, 8*2), 0.0f, "solid", team);

	makeBlock(pos + Vec2f(0, 8*2), 0.0f, "platform", team).getSprite().SetFrame(1);

	makeBlock(pos + Vec2f(-8*1, 8*2), 0.0f, "solid", team);
	makeBlock(pos + Vec2f(-8*2, 8*2), 0.0f, "solid", team);
	makeBlock(pos + Vec2f(-8*2, 8*1), 0.0f, "solid", team);

	makeBlock(pos + Vec2f(-8*2, 0), 0.0f, "platform", team).getSprite().SetFrame(1);
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (player is null) return true;

	if (sv_test || player.isMod())
	{
		if (text_in.substr(0,1) == "!" )
		{
			string[]@ tokens = text_in.split(" ");

			if (tokens.length > 1)
			{
				CBlob@ pBlob = player.getBlob();
				if (pBlob is null) return false;
				
				if (tokens[0] == "!spawnmothership") //spawn a mothership
				{
					SpawnMothership(pBlob.getPosition(), parseInt(tokens[1]));
				}
			}
		}
	}
	return true;
}
