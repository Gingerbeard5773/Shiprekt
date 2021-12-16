//Heal particles

void makeHealParticle(CBlob@ this, string particleName = "HealParticle"+(XORRandom(2)+1))
{
	const Vec2f pos = this.getPosition() + getRandomVelocity(0, this.getRadius(), XORRandom(360));

	CParticle@ p = ParticleAnimated(particleName, pos, getRandomVelocity(0, 0.5f, XORRandom(360)), XORRandom(360), 1.0f, 2+XORRandom(3), 0.0f, false);
	if (p !is null)
	{
		p.diesoncollide = true;
		p.fastcollision = true;
		p.lighting = true;
		p.Z = 550.0f;
	}
}
