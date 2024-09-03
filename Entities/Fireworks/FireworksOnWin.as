#include "FW_Explosion.as"

u8 time_till_next_launch = 35;
u16 fw_spawn_delay = 0;
void onTick(CRules@ this)
{
	if (!this.isGameOver()) return;

	CBlob@[] cores;
	getBlobsByTag("mothership", @cores);
	if (cores.length <= 0 || cores[0].hasTag("critical")) return;

	Vec2f spawnpos = cores[0].getPosition();

	if (fw_spawn_delay < 90)
	{
		fw_spawn_delay++;
	}		

	if (fw_spawn_delay >= time_till_next_launch) 
	{	
		Fireworks::FireworksBullet(spawnpos);

		string launchsound;
		switch (XORRandom(3))
		{
			case 0: launchsound = "FW_Whistle1.ogg"; break;
			case 1: launchsound = "FW_Whistle2.ogg"; break;
			case 2: launchsound = "FW_Launch.ogg"; break;
		}
		Sound::Play(launchsound, spawnpos, 0.6f);

		fw_spawn_delay = 0;			
	}
}
