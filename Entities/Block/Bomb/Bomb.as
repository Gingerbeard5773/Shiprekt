#include "Hitters.as";
#include "ExplosionEffects.as";
#include "ShipsCommon.as";
#include "Booty.as";
#include "AccurateSoundPlay.as";

const f32 BOMB_RADIUS = 15.0f;
const f32 BOMB_BASE_DAMAGE = 2.7f;

void onInit(CBlob@ this)
{
	this.Tag("bomb");
	//this.Tag("ramming");
	this.set_u8("gibType", 1);
	//this.getCurrentScript().tickFrequency = 60;
	
	this.set_f32("weight", 2.0f);
	
	/*CSprite@ sprite = this.getSprite();
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

			int[] frames = {
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
	}*/
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

const u8 findCloseBombs(CBlob@ this)
{
	u8 factor = 0;
	CBlob@[] blobs;
	getMap().getBlobsInRadius(this.getPosition(), 12.0f, @blobs);
	const u8 blobsLength = blobs.length;
	for (u8 i = 0; i < blobsLength; i++)
	{
		CBlob@ blob = blobs[i];
		if (blob.hasTag("bomb"))
		{
			factor++;
		}
	}
	
	return factor;
}

void Explode(CBlob@ this, const f32&in radius = BOMB_RADIUS)
{
	const Vec2f pos = this.getPosition();
	const u8 stackfactor = findCloseBombs(this);

	if (isClient())
	{
		directionalSoundPlay("Bomb.ogg", pos);
		makeLargeExplosionParticle(pos);
		ShakeScreen(4 * radius + stackfactor, 45, pos);
	}

	//hit blobs
	CBlob@[] blobs;
	if (!getMap().getBlobsInRadius(pos, (radius-3)+ (stackfactor*3), @blobs))
		return;
	
	ShipDictionary@ ShipSet = getShipSet();
	const u8 blobsLength = blobs.length;
	for (u8 i = 0; i < blobsLength; i++)
	{
		CBlob@ hit_blob = blobs[i];
		if (hit_blob is this) continue;
		
		const int hitCol = hit_blob.getShape().getVars().customData;

		if (isServer())
		{
			Vec2f hit_blob_pos = hit_blob.getPosition();  

			if (hit_blob.hasTag("block"))
			{
				if (hitCol <= 0) continue;

				// move the ship
				Ship@ ship = ShipSet.getShip(hitCol);
				if (ship !is null && ship.mass > 0.0f)
				{
					Vec2f impact = (hit_blob_pos - pos) * 0.15f / ship.mass;
					ship.vel += impact;
				}
			}
		
			const f32 distanceFactor = Maths::Min(1.0f, Maths::Max(0.0f, BOMB_RADIUS - this.getDistanceTo(hit_blob) + 8.0f + (stackfactor/2)) / BOMB_RADIUS);
			//f32 distanceFactor = 1.0f;
			const f32 damageFactor = (hit_blob.hasTag("mothership")) ? 0.25f : 1.0f;

			//hit the object
			this.server_Hit(hit_blob, hit_blob_pos, Vec2f_zero, BOMB_BASE_DAMAGE * distanceFactor * damageFactor + (stackfactor/3), Hitters::bomb, true);
			//print(hit_blob.getNetworkID() + " for: " + BOMB_BASE_DAMAGE * distanceFactor + " dFctr: " + distanceFactor + ", dist: " + this.getDistanceTo(hit_blob));
		}
		
		CPlayer@ owner = this.getDamageOwnerPlayer();
		if (owner !is null && hitCol > 0)
		{
			CBlob@ blob = owner.getBlob();
			if (blob !is null)
				damageBootyBomb(owner, blob, hit_blob, ShipSet);
		}
	}
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (isClient() && customData == Hitters::bomb)
	{
		//explosion particle
		makeSmallExplosionParticle(worldPoint);
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.hasTag("engine") && this.getHealth() / this.getInitialHealth() < 0.5f)
		this.Tag("disabled");
	
	if (customData == Hitters::bomb)
	{
		this.server_Die();
	}
	
	return damage;
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

/*void StartDetonation(CBlob@ this)//not being used
{
	this.server_SetTimeToDie(2);
	CSprite@ sprite = this.getSprite();
	sprite.SetAnimation("exploding");
	sprite.SetEmitSound("/bomb_timer.ogg");
	sprite.SetEmitSoundPaused(false);
	sprite.RewindEmitSound();
}*/

void damageBootyBomb(CPlayer@ attacker, CBlob@ attackerBlob, CBlob@ victim, ShipDictionary@ ShipSet)
{
	if (victim.hasTag("block"))
	{
		const u8 teamNum = attacker.getTeamNum();
		const u8 victimTeamNum = victim.getTeamNum();
		
		Ship@ victimShip = ShipSet.getShip(victim.getShape().getVars().customData);
		if (victimShip !is null && victimShip.blocks.length > 3
			&& (!victimShip.owner.isEmpty() || victimShip.isMothership) //only inhabited ships
			&& victimTeamNum != teamNum //cant be own ships
			&& (!victim.hasTag("platform") && !victim.hasTag("coupling")))
		{
			if (attacker.isMyPlayer())
				directionalSoundPlay("Pinball_3", attackerBlob.getPosition(), 1.2f);

			if (isServer())
			{
				CRules@ rules = getRules();
				
				u16 reward = 15;//propellers, seat, solids
				if (victim.hasTag("weapon") || victim.hasTag("bomb"))
					reward += 15;
				else if (victim.hasTag("mothership"))
					reward += 20;

				const f32 bFactor = (rules.get_bool("whirlpool") ? 3.0f : 1.0f) * Maths::Min(2.5f, Maths::Max(0.15f,
				(2.0f * rules.get_u16("bootyTeam_total" + victimTeamNum) - rules.get_u16("bootyTeam_total" + teamNum) + 1000)/(rules.get_u32("bootyTeam_median") + 1000)));
				
				reward = Maths::Round(reward * bFactor);
				
				server_addPlayerBooty(attacker.getUsername(), reward);
				server_updateTotalBooty(teamNum, reward);
			}
		}
	}
}
