#include "Booty.as";
#include "IslandsCommon.as";
#include "AccurateSoundPlay.as";
#include "TileCommon.as";

const s32 timerMax = 10; //amount of tokens to tick through
const s32 treasureTick = 30; //time it takes to take 1 token off the timer (30 = 1 second)
const f32 findRadius = 100.0f; //radius a player needs to be in for the treasure to be initially spotted

void onInit(CBlob@ this)
{
	client_AddToChat("$ A treasure chest been hiddened! $", SColor(255, 250, 250, 100));

	this.set_s32("treasureScale", 0);
	this.set_s32("treasureToken", timerMax);
	this.set_string("treasureTaker", "");
}

void onInit(CSprite@ this)
{
	this.SetVisible(false);
	this.ScaleBy(Vec2f(0.1f, 0.1f));
	this.SetZ(-15.0f);
	Vec2f tokenOffset = Vec2f(8, 8);
	
	for (u8 i = 0; i < timerMax; i++)
	{
		CSpriteLayer@ layer = this.addSpriteLayer("token"+i, 4, 4);
		if (layer !is null)
		{
			layer.SetFrame(5);
			layer.SetVisible(false);

			tokenOffset.RotateBy(40.0f);
			layer.SetOffset(tokenOffset);
		}
	}
	this.ReloadSprites(1, 0); //set Red
}

void onTick(CBlob@ this)
{
	s32 timer = this.get_s32("treasureToken");
	
	CSprite@ sprite = this.getSprite();
	if (this.getTickSinceCreated() > 100)
	{
		if (timer > 0)
		{
			CBlob@[] humans;

			if (getMap().getBlobsInRadius(this.getPosition(), sprite.isVisible() ? 10.0f : findRadius, @humans))
			{
				for (u8 i = 0; i < humans.length; i++)
				{
					CBlob@ human = humans[i];
					if (isTouchingLand(human.getPosition()) && human.getName() == "human")
					{
						if (!sprite.isVisible()) //Reveal the treasure!
						{
							reveal(this, human);
						}
						else if (human.getVelocity() == Vec2f())
						{
							if (getGameTime() % treasureTick == 0)
							{
								if (human.getPlayer() !is null && this.get_string("treasureTaker") == "")
									this.set_string("treasureTaker", human.getPlayer().getUsername());

								timer = Maths::Clamp(timer - 1, 0, timerMax);
								if (timer > 0) directionalSoundPlay("Pinball_2", this.getPosition());
							}
						}
						else if (timer < timerMax) //reset timer if player moving
						{
							directionalSoundPlay("join", this.getPosition());
							this.set_string("treasureTaker", "");
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
				directionalSoundPlay("join", this.getPosition());
				this.set_string("treasureTaker", "");
				timer = timerMax;
			}
		}
	}
	
	if (sprite.isVisible() && this.get_s32("treasureScale") < 15 && !this.hasTag("revealed treasure"))
	{
		this.getSprite().ScaleBy(Vec2f(1.16f, 1.16f)); //scale X up
		this.add_s32("treasureScale", 1);
	}
	else if (this.get_s32("treasureScale") >= 15 && !this.hasTag("revealed treasure"))
		this.Tag("revealed treasure"); //for gui compass

	if (timer <= 0)
	{
		if (this.get_s32("treasureScale") == 15) directionalSoundPlay("snes_coin", this.getPosition());
		this.sub_s32("treasureScale", 1);
	}

	if (this.get_s32("treasureScale") < 15 && this.hasTag("revealed treasure")) //death sequence
	{
		this.getSprite().ScaleBy(Vec2f(0.9f, 0.9f)); //scale X down
		if (this.get_s32("treasureScale") <= 0)
		{
			server_addPlayerBooty(this.get_string("treasureTaker"), 200 + XORRandom(800));
			this.server_Die();
		}
	}
	this.set_s32("treasureToken", timer);
	//print("timer: "+timer);
}

void reset(CBlob@ this)
{
	
}

void reveal(CBlob@ this, CBlob@ finder)
{
	Sound::Play("ReportSound");
	if (finder.getPlayer() !is null)
		client_AddToChat("$ " +finder.getPlayer().getCharacterName() + " found the treasure! $", SColor(255, 250, 50, 50));
	
	//reveal sprite
	CSprite@ sprite = this.getSprite();
	sprite.SetVisible(true);
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
				layer.SetVisible(this.getBlob().get_s32("treasureToken") - 1 > i);
				layer.RotateBy(1, layer.getOffset());
				Vec2f rotation = layer.getOffset();
				rotation.RotateBy(4.0f);
				layer.SetOffset(rotation); //moving tokens around X
				//layer.RotateBy(5.0f, Vec2f_zero); //rotating the token sprite
			}
		}
	}
}
