void sparks1(Vec2f at, f32 angle, f32 damage)
{
    int amount = damage * 5 + XORRandom(5);

    for (int i = 0; i < amount; i++)
    {
        Vec2f vel = getRandomVelocity(angle, damage * 3.0f, 180.0f) * 0.1f;
        vel.y = vel.y - float(XORRandom(100)) / 100.0f;
		vel.x = vel.x - float(XORRandom(100)) / 100.0f;
        CParticle@ p = ParticlePixel(at, vel, SColor(255, 255, 255, 0), true);
		
        if (p is null) return; //bail if we stop getting particles

        p.Z = 550.0f;
    }
}

void sparks(Vec2f pos, int amount, f32 spread = 1.0f, int16 pTime = 10)
{
	Random spark(getGameTime() + XORRandom(20));

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(spark.NextFloat() * spread, 0); //spread
        vel.RotateBy(spark.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixel(pos, vel, SColor(255, 255, 128 + spark.NextRanged(128), spark.NextRanged(128)), true);
        if (p is null) return; //bail if we stop getting particles

        p.timeout = pTime + spark.NextRanged(20);
        p.scale = 0.5f + spark.NextFloat();
        p.damping = 0.95f;
		p.Z = 550.0f;
    }
}

void ShrapnelParticle(Vec2f pos, Vec2f vel)
{
	CParticle@ p = ParticlePixel(pos, vel, SColor(255, 255, 128 + XORRandom(128), 100), true);
	if (p !is null)
	{
		p.timeout = 10 + XORRandom(6);
		p.scale = 1.5f;
		p.Z = 550.0f;
		p.damping = 0.85f;
	}
}
