#include "Hitters.as";
#include "ExplosionEffects.as";
#include "DamageBooty.as";
#include "AccurateSoundPlay.as";

const f32 BOMB_RADIUS = 16.0f;
const f32 BOMB_BASE_DAMAGE = 5.0f; //2.7

BootyRewards@ booty_reward;

void onInit(CBlob@ this)
{
	if (booty_reward is null)
	{
		BootyRewards _booty_reward;
		_booty_reward.addTagReward("bomb", 20);
		_booty_reward.addTagReward("mothership", 35);
		_booty_reward.addTagReward("secondarycore", 25);
		_booty_reward.addTagReward("weapon", 20);
		_booty_reward.addTagReward("solid", 15);
		_booty_reward.addTagReward("seat", 20);
		_booty_reward.addTagReward("platform", 5);
		_booty_reward.addTagReward("door", 15);
		@booty_reward = _booty_reward;
	}

	this.Tag("bomb");
	//this.Tag("ramming");
	this.set_u8("gibType", 1);
	//this.getCurrentScript().tickFrequency = 60;

	this.set_f32("weight", 2.0f);

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		 //default animation
		{
			Animation@ anim = sprite.addAnimation("default", 0, false);
			anim.AddFrame(0);
		}
		//exploding "warmup" animation
		{
			Animation@ anim = sprite.addAnimation("exploding", 2, true);

			const int[] frames = {
				1, 1,
				2, 2,
				0, 0,
				0, 0,

				1, 1,
				2, 2,
				0, 0,
				0,

				1,
				2,
				0, 0,

				1,
				2,
				0, 0,

				1,
				2,
				0, 0,

				1,
				2,
				0, 0,

				1,
				2,
				0, 0,
			};
			anim.AddFrames(frames);
		}
	}
}

void onTick(CBlob@ this)
{
	const int col = this.getShape().getVars().customData;
	if (col <= 0) return;
	
	CPlayer@ owner = getPlayerByUsername(this.get_string("playerOwner"));
	if (owner !is null)
		this.SetDamageOwnerPlayer(owner);

	//go neutral if bomb is placed on an enemy owned ship
	if (isServer())
	{
		CBlob@[] overlapping;
		this.getOverlapping(@overlapping);
		
		const u8 overlappingLength = overlapping.length;
		for (u8 i = 0; i < overlappingLength; i++)
		{
			CBlob@ b = overlapping[i];
			if (b.getShape().getVars().customData == col && this.getTeamNum() != b.getTeamNum())
			{
				this.server_setTeamNum(255);
				break;
			}
		}
	}
	this.getCurrentScript().tickFrequency = 0; //only tick once, when this block is placed
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (isClient() && customData == Hitters::bomb)
		makeSmallExplosionParticle(worldPoint);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.hasTag("engine") && this.getHealth() - damage <= 0.0f)
		this.Tag("disabled");
	
	if (customData == Hitters::bomb && this.getShape().getVars().customData > 0)
	{
		if (!this.hasTag("exploding"))
			StartDetonation(this);
		return 0.0f;
	}
	
	return damage;
}

void StartDetonation(CBlob@ this)
{
	this.server_SetTimeToDie(2);
	this.Tag("exploding");
	CSprite@ sprite = this.getSprite();
	sprite.SetAnimation("exploding");
	sprite.SetEmitSound("/bomb_timer.ogg");
	sprite.SetEmitSoundPaused(false);
	sprite.RewindEmitSound();
}

void onDie(CBlob@ this)
{
	if (this.getShape().getVars().customData > 0)
	{
		this.getSprite().Gib();
		if (!this.hasTag("disabled"))
			Explode(this);
	}
}

void Explode(CBlob@ this)
{
	Vec2f pos = this.getPosition();

	directionalSoundPlay("Bomb.ogg", pos);
	makeLargeExplosionParticle(pos);
	ShakeScreen(4 * BOMB_RADIUS, 45, pos);

	if (isServer())
	{
		//hit blobs
		CBlob@[] blobs;
		getMap().getBlobsInRadius(pos, BOMB_RADIUS, @blobs);

		ShipDictionary@ ShipSet = getShipSet();
		const u8 blobsLength = blobs.length;
		for (u8 i = 0; i < blobsLength; i++)
		{
			CBlob@ hit_blob = blobs[i];
			if (hit_blob is this) continue;
			
			const int hitCol = hit_blob.getShape().getVars().customData;
			Vec2f hit_blob_pos = hit_blob.getPosition();
			Vec2f direction = hit_blob_pos - pos;
			const f32 damage = direction.Length() > 13.0f ? BOMB_BASE_DAMAGE / 2.0f : BOMB_BASE_DAMAGE;
			const f32 booty_factor = Maths::Min(damage, hit_blob.getHealth()) / hit_blob.getInitialHealth();

			if (hitCol > 0)
			{
				// move the ship
				Ship@ ship = ShipSet.getShip(hitCol);
				if (ship !is null && ship.mass > 0.0f)
				{
					Vec2f impact = direction * 0.15f / ship.mass;
					ship.vel += impact;
				}
			}

			this.server_Hit(hit_blob, hit_blob_pos, direction, damage, Hitters::bomb, true);

			server_rewardBooty(this.getDamageOwnerPlayer(), hit_blob, booty_reward, "Pinball_3", booty_factor);
		}
	}
}
