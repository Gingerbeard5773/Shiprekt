#include "IslandsCommon.as";
#include "WaterEffects.as";
#include "Hitters.as";

const f32 FORCE_INCREASE = 0.4f;
const f32 ANGLE_DECREASE = 0.2f;

void onInit(CBlob@ this)
{
	this.set_f32("force", 1.0f);
	this.set_f32("force angle", 90.0f);
	this.getShape().SetStatic(true);

	
	getRules().set_bool("whirlpool", true);

	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSound("Whirlpool.ogg");
	sprite.SetEmitSoundPaused(false);
	sprite.SetEmitSoundVolume(3.0f);
	sprite.SetZ(-20.0f);
		
	if( !CustomEmitEffectExists("whirlpoolEmit"))
		SetupCustomEmitEffect("whirlpoolEmit", "Whirlpool.as", "updateWhirlpoolParticle", 10, 0, 120);
}

void onTick(CBlob@ this)
{
	CRules@ rules = getRules();
	if (rules.isGameOver())
		return;
	
	Vec2f pos = this.getPosition();
	f32 force = this.get_f32("force");
	f32 forceAngle = this.get_f32("force angle");
	
	//particles
	if (getGameTime() % 5 == 0)
		makeParticle(pos);
		
	//suck in player
	CBlob@ h = getLocalPlayerBlob();
	if (h !is null && !h.isOnGround())
	{
		Vec2f attractDir = h.getPosition() - pos;
		
		attractDir.Normalize();
		Vec2f perpDir = attractDir * 2.5f;
		perpDir.RotateBy(90.0f);
		
		h.setVelocity(-(attractDir + perpDir) * Maths::Min( 5.0f, force ) / 2.0f);
	}
		
	//suck in islands
	Island[]@ islands;
	if (rules.get("islands", @islands))
		for (uint i = 0; i < islands.length; ++i)
		{
			Island @isle = islands[i];	
			Vec2f attractDir = isle.pos - pos;
			f32 distance = attractDir.Length();
			f32 distanceFactor;
			
			if (distance > 600.0f)
				distanceFactor = 3.0f;
			else if (distance > 315.0f || distance < 50.0f)
				distanceFactor = 2.0f;
			else 
				distanceFactor = 1.0f;
									
			attractDir.Normalize();
			Vec2f perpDir = attractDir;
			perpDir.RotateBy(forceAngle);
			
			attractDir *= force * distanceFactor;
			perpDir *= force / Maths::Pow( distanceFactor, 2 );
			
			f32 massFactor = isle.isMothership ? (Maths::Sqrt(isle.mass) * 65.0f) : Maths::Max(200.0f, (isle.mass * 35.0f));
			
			isle.vel -= (attractDir + perpDir)/massFactor;
		}
	
	//increase factor, damage blobs
	if (this.getTickSinceCreated() > 300 && getGameTime() % 30 == 0)
	{
		force += FORCE_INCREASE;
		this.set_f32("force", force);
		
		if (forceAngle > 0.0f )
		{
			forceAngle -= ANGLE_DECREASE;
			this.set_f32("force angle", forceAngle);
		}
		
		if (isServer())
			damageBlobs(this);		
	}

}

void updateWhirlpoolParticle(CParticle@ p)
{
	CBlob@ whirlpool = getBlobByName("whirlpool");
	if (whirlpool is null) return;
	
	CMap@ map = getMap();
	Vec2f pos = whirlpool.getPosition();
	Vec2f attractDir = p.position - pos;
	f32 distance = attractDir.Length() + 0.1f;
	attractDir.Normalize();
	Vec2f perpDir = attractDir;
	perpDir.RotateBy(whirlpool.get_f32("force angle"));
	
	p.velocity = -(attractDir * 275.0f/(distance + 20.0f) + perpDir * distance / 30.0f) * 1.0f;

	//kill near center particles
	if ((pos - p.position ).Length() < 30.0f)
		p.frame = 10;
		
	//add actual particles emit
	if (p.frame < 7)
	{
		Vec2f offset = p.velocity;
		offset.Normalize();
		offset.RotateBy(90.0f);
		offset.x *= 2.0f;
		{
			CParticle@ pixel = ParticlePixel(p.position - offset, Vec2f_zero, SColor(255, 150, 200, 250), true);
			if (pixel !is null)
			{
				pixel.timeout = 4;
				pixel.fadeout = true;
				pixel.Z = p.Z -0.1f;
			}
		}
		{
			CParticle@ pixel = ParticlePixel(p.position + offset, Vec2f_zero, SColor(255, 150, 200, 250), true);
			if (pixel !is null)
			{
				pixel.timeout = 4;
				pixel.fadeout = true;
				pixel.Z = p.Z -0.1f;
			}
		}
	}
}

void makeParticle(Vec2f pos)
{
	u32 step = getGameTime()/6;
	u8 aliveT = 20;
	f32 radius = 225.0f;
	u8 emiteffect = GetCustomEmitEffectID("whirlpoolEmit");
	
	{
		CParticle@ water = MakeWhirlpoolParticle(pos + Vec2f(radius * Maths::Cos(step), radius * Maths::Sin(step)), Vec2f_zero, aliveT);
		if (water !is null)
			water.emiteffect = emiteffect;
	}
	{
		CParticle@ water = MakeWhirlpoolParticle(pos + Vec2f(-radius * Maths::Cos(step), -radius * Maths::Sin(step)), Vec2f_zero, aliveT);
		if (water !is null)
			water.emiteffect = emiteffect;
	}
}

void damageBlobs(CBlob@ this)
{
	CBlob@[] nearby;
	if (getMap().getBlobsInRadius(this.getPosition(), 50.0f, @nearby))
	{
		int blobsNum = nearby.length();
		for (int i = 0; i < blobsNum; i++)
		{
			if ((nearby[i].hasTag("block") && XORRandom(2) == 0) || (nearby[i].getName() == "human" && !nearby[i].get_bool("onGround")))
				this.server_Hit(nearby[i], Vec2f_zero, Vec2f_zero, this.getInitialHealth()/4.0f, Hitters::drown, true);
			
			if (nearby[i] !is this && this.getDistanceTo(nearby[i]) < 15.0f)
			{
				this.server_Hit(nearby[i], Vec2f_zero, Vec2f_zero, 999.0f, Hitters::drown, true);
				nearby[i].server_Die();
			}
		}
	}
}

void onInit(CSprite@ this)
{
	this.ScaleBy(Vec2f( 2.0f, 2.0f));
}

void onTick(CSprite@ this)
{
	this.RotateBy(-6.0f, Vec2f_zero);
}
