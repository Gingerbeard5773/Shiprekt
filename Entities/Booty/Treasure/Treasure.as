#include "Booty.as";
#include "IslandsCommon.as";
#include "AccurateSoundPlay.as"
#include "TileCommon.as"

const u8 CHECK_FREQUENCY = 30;//30 = 1 second
const u32 FISH_RADIUS = 65.0f;//pickup radius
const f32 MAX_REWARD_FACTOR = 0.13f;//% taken per check for mothership (goes fully to captain if no one else on the ship)
const f32 CREW_REWARD_FACTOR = MAX_REWARD_FACTOR/5.0f;
const f32 CREW_REWARD_FACTOR_MOTHERSHIP = MAX_REWARD_FACTOR/2.5f;
const u32 AMMOUNT_INSTANT_PICKUP = 50;
const u8 SPACE_HOG_TICKS = 15;//seconds after collecting where no Xs can spawn there

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = CHECK_FREQUENCY;
}

const s32 timerMax = 10;
s32 timer = timerMax;

void onInit(CSprite@ this)
{
	this.SetVisible(false);
	this.ScaleBy(Vec2f(1, 1));
	this.SetZ(-15.0f);
	Vec2f tokenOffset = Vec2f(8, 8);
	
	for (u8 i = 0; i < timerMax; i++)
	{
		CSpriteLayer@ layer = this.addSpriteLayer("token"+i, 4, 4);
		if (layer !is null)
		{
			layer.SetFrame(5);
			layer.SetVisible(false);
			
			//if (i == 10) tokenOffset = Vec2f(12, 12); //second layer

			tokenOffset.RotateBy(40.0f);
			layer.SetOffset(tokenOffset);
		}
	}
	this.ReloadSprites(1, 0); //set Red
}

void onTick(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	
	CBlob@[] humans;
	
	CSprite@ sprite = this.getSprite();
	if (this.getTickSinceCreated() > 100)
	{
		if (getMap().getBlobsInRadius(pos, sprite.isVisible() ? 10.0f : 100.0f, @humans))
		{
			for (u8 i = 0; i < humans.length; i++)
			{
				CBlob@ human = humans[i];
				if (human.getName() == "human" || human.getName() == "shark")
				{
					if (!sprite.isVisible()) //Reveal the treasure!
					{
						reveal(this, human);
					}

					if (human.getVelocity() == Vec2f())
					{
						timer = Maths::Clamp(timer - 1, 0, timerMax);
						if (timer > 0) Sound::Play("Pinball_2", this.getPosition());
					}
					else if (timer < timerMax) //reset timer if player moving
					{
						Sound::Play("join", this.getPosition());
						timer = timerMax;
					}
				}
				else
				{
					humans.erase(i--); //only humans in array
				}
			}
		}

		if (humans.length <= 0 && timer < timerMax) //reset timer if no players
		{
			Sound::Play("join", this.getPosition());
			timer = timerMax;
		}
	}

	if (timer <= 0)
	{
		Sound::Play("snes_coin", this.getPosition());
		this.server_Die();
		timer = timerMax; //reset time so new treasure doesn't die immediately
	}
	//print("timer: "+timer);
}

void reveal(CBlob@ this, CBlob@ finder)
{
	this.Tag("revealed treasure"); //for gui compass

	if (finder.getPlayer() !is null)
		client_AddToChat("*** A treasure chest has been found by " + finder.getPlayer().getCharacterName() + "! ***");
	
	//reveal sprite
	CSprite@ sprite = this.getSprite();
	sprite.SetVisible(true);
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
	//rotate sprites
	this.RotateBy(4, Vec2f_zero);
	
	if (this.isVisible())
	{
		for (u8 i = 0; i < timerMax; i++)
		{
			CSpriteLayer@ layer = this.getSpriteLayer("token"+i);
			if (layer !is null)
			{
				layer.SetVisible(timer - 1 > i);
				layer.RotateBy(1, layer.getOffset());
				Vec2f rotation = layer.getOffset();
				rotation.RotateBy(4.0f);
				layer.SetOffset(rotation); //moving tokens around X
				//layer.RotateBy(5.0f, Vec2f_zero); //rotating the token sprite
			}
		}
	}
}
