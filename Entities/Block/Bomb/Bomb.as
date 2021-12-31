#include "Hitters.as";
#include "ExplosionEffects.as";
#include "IslandsCommon.as";
#include "Booty.as"
#include "AccurateSoundPlay.as"

const f32 BOMB_RADIUS = 12.0f;
const f32 BOMB_BASE_DAMAGE = 2.7f;

void onInit(CBlob@ this)
{
	this.Tag("bomb");
    this.getCurrentScript().tickFrequency = 60;
	
	this.set_u16("cost", 30);
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
	//update island owner
	int color = this.getShape().getVars().customData;
	if (color == 0) return;
	
	Island@ island = getIsland(color);	
	if (island !is null)
	{
		//go neutral when placed on an enemy mothership
		if (isServer() && island.isMothership && island.centerBlock !is null)
		{
			u8 teamNum = this.getTeamNum();
			if (teamNum != 255 && island.centerBlock.getTeamNum() != teamNum)
			{
				this.server_setTeamNum(255);
			}
		}
	}
}

void Explode(CBlob@ this, f32 radius = BOMB_RADIUS)
{
    Vec2f pos = this.getPosition();
    CMap@ map = this.getMap();

	directionalSoundPlay("Bomb.ogg", pos);
    makeLargeExplosionParticle(pos);
    ShakeScreen(4*radius, 45, pos);

	//hit blobs
	CBlob@[] blobs;
	map.getBlobsInRadius(pos, radius, @blobs);

	for (uint i = 0; i < blobs.length; i++)
	{
		CBlob@ hit_blob = blobs[i];
		if (hit_blob is this)
			continue;

		if (isServer())
		{
			Vec2f hit_blob_pos = hit_blob.getPosition();  

			if (hit_blob.hasTag("block"))
			{
				if (hit_blob.getShape().getVars().customData <= 0)
					continue;

				// move the island

				Island@ isle = getIsland(hit_blob);
				if (isle !is null && isle.mass > 0.0f)
				{
					Vec2f impact = (hit_blob_pos - pos) * 0.15f / isle.mass;
					isle.vel += impact;
				}

				// detonate bomb
					
				if (hit_blob.hasTag("bomb"))
				{
					hit_blob.server_Die();
					continue;
				}
			}
		
			//f32 distanceFactor = Maths::Min( 1.0f, Maths::Max( 0.0f, BOMB_RADIUS - this.getDistanceTo( hit_blob ) + 8.0f ) / BOMB_RADIUS );
			f32 distanceFactor = 1.0f;
			f32 damageFactor = (hit_blob.hasTag("mothership") || hit_blob.hasTag("player")) ? 0.25f : 1.0f;

			//hit the object
			this.server_Hit(hit_blob, hit_blob_pos, Vec2f_zero, BOMB_BASE_DAMAGE * distanceFactor * damageFactor, Hitters::bomb, true);
			//print(hit_blob.getNetworkID() + " for: " + BOMB_BASE_DAMAGE * distanceFactor + " dFctr: " + distanceFactor + ", dist: " + this.getDistanceTo(hit_blob));
		}
		
		CPlayer@ owner = getPlayerByUsername(this.get_string("playerOwner"));
		if (owner !is null)
		{
			this.SetDamageOwnerPlayer(owner);
			CBlob@ blob = owner.getBlob();
			if (blob !is null)
				damageBootyBomb(owner, blob, hit_blob);
		}
	}  
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
    if (customData == Hitters::bomb)
    {
        //explosion particle
        makeSmallExplosionParticle(worldPoint);
    }
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.hasTag("engine") && this.getHealth()/this.getInitialHealth() < 0.5f)
		this.Tag("disabled");
		
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
    sprite.SetEmitSound( "/bomb_timer.ogg" );
    sprite.SetEmitSoundPaused( false );
    sprite.RewindEmitSound();
}*/

void damageBootyBomb(CPlayer@ attacker, CBlob@ attackerBlob, CBlob@ victim)
{
	if (victim.hasTag("block"))
	{
		u8 teamNum = attacker.getTeamNum();
		u8 victimTeamNum = victim.getTeamNum();
		string attackerName = attacker.getUsername();
		Island@ victimIsle = getIsland(victim.getShape().getVars().customData);

		if (victimIsle !is null && victimIsle.blocks.length > 3
			&& (victimIsle.owner != "" || victimIsle.isMothership) //only inhabited ships
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
					reward += 15;

				f32 bFactor = (rules.get_bool("whirlpool") ? 3.0f : 1.0f) * Maths::Min(2.5f, Maths::Max(0.15f,
				(2.0f * rules.get_u16("bootyTeam_total" + victimTeamNum) - rules.get_u16("bootyTeam_total" + teamNum) + 1000)/(rules.get_u32( "bootyTeam_median") + 1000)));
				
				reward = Maths::Round(reward * bFactor);
				
				server_addPlayerBooty(attackerName, reward);
				server_updateTotalBooty(teamNum, reward);
			}
		}
	}
}
