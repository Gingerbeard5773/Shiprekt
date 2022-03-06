// fzzle @ 25/03/17
#include "TeamColour.as"
#include 'DestructCommon.as';

const uint16 SELF_DESTRUCT_SECONDS = 8;
const float BLAST_RADIUS = 100.0f;
const float HEAL_AMOUNT = 0.1f;

void onInit(CBlob@ this)
{
	this.set_f32("weight", 12.0f);
	
	this.Tag("secondaryCore");

	if (isClient())
	{
		//add an additional frame to the damage frames animation
		CSprite@ sprite = this.getSprite();
		Animation@ animation = sprite.getAnimation("default");
		if (animation !is null)
		{
			array<int> frames = {3};
			animation.AddFrames(frames);
		}
	}
}

void onTick(CBlob@ this)
{
	uint8 team = this.getTeamNum();

	if (isServer())
	{ 
		if (getGameTime() % 60 == 0)
		{
			CBlob@[] humans;
			getBlobsByName("human", humans);

			for (uint i = 0; i < humans.length; ++ i)
			{
				CBlob@ human = humans[i];

				if (human.getTeamNum() != team || human.getHealth() >= human.getInitialHealth())
					continue;

				Ship@ ship = getShip(this.getShape().getVars().customData);
				if (ship is null) continue;

				if (ship.isMothership) continue;

				if (!this.isOverlapping(human)) continue;

				human.server_Heal(HEAL_AMOUNT);  
			}
		}
	}

	if (this.hasTag('critical'))
	{
		//Ship@ ship = getShip(this.getShape().getVars().customData);
		//ship.vel *= 0.8f;

		if (!v_fastrender)
		{
			CParticle@ particle = ParticlePixel(this.getPosition(), getRandomVelocity(90, 4, 360), getTeamColor(team), true);
			if (particle !is null)
			{
				particle.Z = 10.0f;
				particle.timeout = XORRandom(3) + 2;
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f point, Vec2f velocity, f32 damage, CBlob@ blob, u8 customData)
{
	if (damage >= this.getHealth())
	{
		if (this.hasTag('critical')) return 0.0f;

		CPlayer@ owner = getPlayerByUsername(this.get_string("playerOwner"));
		if (owner !is null)
			this.SetDamageOwnerPlayer(owner);
		
		this.Tag('critical');
		this.server_SetTimeToDie(SELF_DESTRUCT_SECONDS);

		Vec2f position = this.getPosition();

		directionalSoundPlay('ShipExplosion', position);
		makeSmallExplosionParticle(position);

		this.AddScript('Block_Explode.as');

		const int color = this.getShape().getVars().customData;
		if (color == 0) return 0.0f;

		Ship@ ship = getShip(color);
		if (ship is null || ship.blocks.length < 10 || ship.isMothership) return 0.0f;

		for (uint i = 0; i < ship.blocks.length; ++ i)
		{
			ShipBlock@ block = ship.blocks[i];

			CBlob@ blob = getBlobByNetworkID(block.blobID);

			if (blob !is null && this.getTeamNum() == blob.getTeamNum())
			{
				if (i % 4 == 0 && !blob.hasTag("coupling"))
				{
					blob.AddScript('Block_Explode.as');
				}
			}
		}

		return 0.0f;
	}

	return damage;
}

void onDie(CBlob@ this)
{
	if (this.getShape().getVars().customData > 0)
	{
		if (!this.hasTag("disabled"))
			Destruct::self(this, BLAST_RADIUS);
	}
}
