#include "Booty.as";
#include "IslandsCommon.as";
#include "AccurateSoundPlay.as"
#include "TileCommon.as"

const u8 CHECK_FREQUENCY =  30;//30 = 1 second
const u32 FISH_RADIUS = 65.0f;//pickup radius
const f32 MAX_REWARD_FACTOR = 0.13f;//% taken per check for mothership (goes fully to captain if no one else on the ship)
const f32 CREW_REWARD_FACTOR = MAX_REWARD_FACTOR/5.0f;
const f32 CREW_REWARD_FACTOR_MOTHERSHIP = MAX_REWARD_FACTOR/2.5f;
const u32 AMMOUNT_INSTANT_PICKUP = 50;
const u8 SPACE_HOG_TICKS = 15;//seconds after collecting where no Xs can spawn there

void onInit(CBlob@ this)
{
	this.Tag("treasure");
	this.getCurrentScript().tickFrequency = CHECK_FREQUENCY;
}

void onInit(CSprite@ this)
{
	this.ReloadSprites(1, 0); //set Red
	u16 ammount = this.getBlob().get_u16("ammount");
	f32 size = ammount/(getRules().get_u16("booty_x_max") * 0.3f);
	if (size >= 1.0f)
		this.ScaleBy(Vec2f(size, size));
	this.SetZ(-15.0f);
}

void onTick(CBlob@ this)
{
	/*Vec2f pos = this.getPosition();

	//booty to motherships captain crew
	CBlob@[] humans;
	getBlobsByTag("player", @humans);
	u16 minBooty = getRules().get_u16("bootyRefillLimit");
	
	//booty to over-sea crew
	for (u8 i = 0; i < humans.length; i++ )
	{
		CPlayer@ player = humans[i].getPlayer();
		if (player is null) continue;

		string name = player.getUsername();
		if (this.getDistanceTo(humans[i]) <= FISH_RADIUS)
		{
			u16 reward = Maths::Ceil(ammount * CREW_REWARD_FACTOR);
			server_giveBooty(name, reward);
		}
	}*/
}

void server_giveBooty(string name, u16 ammount)
{
	if (!isServer()) return;

	CPlayer@ player = getPlayerByUsername(name);
	if (player is null) return;

	u16 pBooty = server_getPlayerBooty(name);
	server_setPlayerBooty(name, pBooty + ammount);
	server_updateTotalBooty(player.getTeamNum(), ammount);
}

void onTick(CSprite@ this)
{
	this.RotateBy(4, Vec2f_zero);
}
