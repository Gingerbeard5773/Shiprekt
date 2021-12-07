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

void onInit(CSprite@ this)
{
	this.SetVisible(false);
	this.ScaleBy(Vec2f(1, 1));
	this.SetZ(-15.0f);
	
	CSpriteLayer@ layer = this.addSpriteLayer("accent_1", 9, 9);
	if (layer !is null)
	{
		layer.SetFrame(2);
		layer.SetVisible(false);
		layer.SetOffset(Vec2f(8, 8));
	}
	CSpriteLayer@ layer_2 = this.addSpriteLayer("accent_2", 9, 9);
	if (layer_2 !is null)
	{
		layer_2.SetFrame(2);
		layer_2.SetVisible(false);
		layer_2.SetOffset(Vec2f(-8, -8));
		layer_2.RotateBy(180.0f, Vec2f());
	}
	this.ReloadSprites(1, 0); //set Red
}

s32 timer = 10;

void onTick(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	
	CBlob@[] humans;
	
	CSprite@ sprite = this.getSprite();
	if (this.getTickSinceCreated() > 200)
	{
		if (getMap().getBlobsInRadius(pos, sprite.isVisible() ? 10.0f : 200.0f, @humans))
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
						timer = Maths::Clamp(timer - 1, 0, 10);
						Sound::Play("Poing"+(XORRandom(6)+1), this.getPosition());
					}
					else timer = 10; //reset timer if player moving
				}
				else humans.erase(i--); //only humans in array
			}
		}

		if (humans.length <= 0) //reset timer if no players
		{
			timer = 10;
		}
	}

	if (timer == 0)
	{
		this.server_Die();
		timer = 10; //reset time so new treasure doesn't die immediately
	}
	//print("timer: "+timer);
}

void reveal(CBlob@ this, CBlob@ finder)
{
	this.Tag("revealed treasure"); //for gui compass

	if (finder.getPlayer() !is null)
		client_AddToChat("***A treasure chest has been found by " + finder.getPlayer().getCharacterName() + "! ***");
	
	//reveal sprite
	CSprite@ sprite = this.getSprite();
	
	CSpriteLayer@ layer = sprite.getSpriteLayer("accent_1");
	if (layer !is null)
		layer.SetVisible(true);
	CSpriteLayer@ layer_2 = sprite.getSpriteLayer("accent_2");
	if (layer_2 !is null) 
		layer_2.SetVisible(true);
	
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
	CSpriteLayer@ layer = this.getSpriteLayer("accent_1");
	if (layer !is null) layer.RotateBy(-4, Vec2f(-8, -8));
	CSpriteLayer@ layer_2 = this.getSpriteLayer("accent_2");
	if (layer_2 !is null) layer_2.RotateBy(-4, Vec2f(8, 8));
}
