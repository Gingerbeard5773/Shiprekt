// fzzle @ 25/03/17
#include "TeamColour.as"
#include 'DestructCommon.as';

const uint16 SELF_DESTRUCT_SECONDS = 8;
const float INITIAL_HEALTH = 4.0f;
const float BLAST_RADIUS = 100.0f;
const float HEAL_AMOUNT = 0.1f;

void onInit(CBlob@ this)
{
	this.Tag('secondaryCore');

	if (isServer())
	{
		this.server_SetHealth(INITIAL_HEALTH);
	}

	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ layer = sprite.addSpriteLayer('damage');

		if (layer !is null)
		{
			layer.SetRelativeZ(1);
			layer.SetLighting(false);
			Animation@ animation = layer.addAnimation('default', 0, false);
			array<int> frames = {65, 67, 68, 69};
			animation.AddFrames(frames);
			layer.SetAnimation('default');
		}

		updateFrame(this);
	}
}

void onTick(CBlob@ this)
{
	uint8 team = this.getTeamNum();

	if (isServer())
	{ 
		if (getGameTime() % 60 == 0)
		{
			array<CBlob@> humans;
			getBlobsByName('human', humans);

			for (uint i = 0; i < humans.length; ++ i)
			{
				CBlob@ human = humans[i];

				if (human.getTeamNum() != team) continue;

				if (human.getHealth() >= human.getInitialHealth()) continue;

				Island@ isle = getIsland(human);

				if (isle is null) continue;

				if (isle.isMothership) continue;

				if (not this.isOverlapping(human)) continue;

				human.server_Heal(HEAL_AMOUNT);  
			}
		}
	}

	if (this.hasTag('critical'))
	{
		int color = this.getShape().getVars().customData;
		Island@ isle = getIsland(color);

		isle.vel *= 0.8f;

		Vec2f position = this.getPosition();

		CParticle@ particle = ParticlePixel(position, getRandomVelocity(90, 4, 360), getTeamColor(team), true);
		if (particle !is null)
		{
			particle.Z = 10.0f;
			particle.timeout = XORRandom(3) + 2;
		}
	}
}

f32 onHit(CBlob@ this, Vec2f point, Vec2f velocity, f32 damage, CBlob@ blob, u8 customData)
{
	if (damage >= this.getHealth())
	{
		if (this.hasTag('critical')) return 0.0f;

		this.Tag('critical');

		this.server_SetTimeToDie(SELF_DESTRUCT_SECONDS);

		Vec2f position = this.getPosition();

		directionalSoundPlay('ShipExplosion', position);
		makeSmallExplosionParticle(position);

		this.AddScript('Block_Explode.as');

		const int color = this.getShape().getVars().customData;

		if (color == 0) return 0.0f;

		Island@ isle = getIsland(color);

		if (isle is null || isle.blocks.length < 10) return 0.0f;

		if (isle.isMothership) return 0.0f;

		uint8 team = this.getTeamNum();

		for (uint i = 0; i < isle.blocks.length; ++ i)
		{
			IslandBlock@ block = isle.blocks[i];

			CBlob@ blob = getBlobByNetworkID(block.blobID);

			if (blob !is null && team == blob.getTeamNum())
			{
				int blobType = blob.getSprite().getFrame();

				if (i % 4 == 0 && blobType != Block::COUPLING)
				{
					blob.AddScript('Block_Explode.as');
				}
			}
		}

		return 0.0f;
	}

	return damage;
}

void onHealthChange(CBlob@ this, float old)
{
	if (isClient())
	{
		updateFrame(this);
	}
}

void updateFrame(CBlob@ this)
{
	float health = this.getHealth();
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ layer = sprite.getSpriteLayer('damage');
	uint8 frames = layer.animation.getFramesCount();
	uint8 step = frames - ((health / INITIAL_HEALTH) * frames);
	layer.animation.frame = step;
}

void onDie(CBlob@ this)
{
	if (this.getShape().getVars().customData > 0)
	{
		if (!this.hasTag("disabled"))
			Destruct::self(this, BLAST_RADIUS);
	}
}
