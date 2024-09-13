#include "ExplosionEffects.as";
#include "AccurateSoundPlay.as";
#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.set_u32("addedTime", getGameTime());
	this.set_u32("nextExplosion", getGameTime() + 20 + XORRandom(80));
}

void onTick(CBlob@ this)
{
	if (isServer() && getGameTime() > this.get_u32("nextExplosion"))
	{
		Explode(this);
		this.set_u32("nextExplosion", getGameTime() + 20 + XORRandom(45));
	}
	
	//failsafe
	if (getGameTime() > this.get_u32("addedTime") + 450)
		this.getCurrentScript().runFlags |= Script::remove_after_this;	
}

void Explode(CBlob@ this)
{
	const Vec2f pos = this.getPosition();
	
	//grab players nearby and damage them
	CBlob@[] overlapping;
	this.getOverlapping(@overlapping);
	
	const u8 overlappingLength = overlapping.length;
	for (u8 i = 0; i < overlappingLength; i++)
	{
		CBlob@ blob = overlapping[i];
		if (blob.hasTag("player"))
			this.server_Hit(blob, pos, Vec2f_zero, blob.getInitialHealth() * 0.25f, Hitters::bomb, true);
	}
	
	//damage self
	if (!this.hasTag("mothership"))
		this.server_Hit(this, pos, Vec2f_zero, this.getInitialHealth() * 0.25f, 0, true);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isClient() && hitterBlob is this && customData == 0)
	{
		const Vec2f pos = this.getPosition();

		//explosion effect
		directionalSoundPlay("KegExplosion.ogg", pos);
		makeSmallExplosionParticle(pos);
		
		if (this.isOnScreen())
			ShakeScreen(30, 20, pos);
	}
	return damage;
}
