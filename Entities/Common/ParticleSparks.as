//Various particles 

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
		p.collides = false;
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

void shotParticles(Vec2f pos, float angle, bool smoke = true, f32 smokeVelocity = 0.1f, f32 scale = 1.0f)
{
	//muzzle flash
	{
		CParticle@ p = ParticleAnimated("Entities/Block/turret_muzzle_flash.png",
										pos, Vec2f(),
										-angle, //angle
										1.0f, //scale
										3, //animtime
										0.0f, //gravity
										true ); //selflit
		if (p !is null)
		{
			p.Z = 550.0f;
		}
	}
	
	//smoke
	if (smoke)
	{
		Vec2f shot_vel = Vec2f(0.5f,0);
		shot_vel.RotateBy(-angle);
		
		Random shotrandom(0x15125); //clientside
		for (int i = 0; i < 5; i++)
		{
			//random velocity direction
			Vec2f vel(smokeVelocity + shotrandom.NextFloat()*0.1f, 0);
			vel.RotateBy(shotrandom.NextFloat() * 360.0f);
			vel += shot_vel * i;

			CParticle@ p = ParticleAnimated("Entities/Block/turret_smoke.png",
											pos, vel,
											shotrandom.NextFloat() * 360.0f, //angle
											scale, //scale
											3+shotrandom.NextRanged(4), //animtime
											0.0f, //gravity
											true ); //selflit
			if (p !is null)
			{
				p.Z = 540.0f;
			}
		}
	}
}

void AngledDirtParticle(Vec2f pos, f32 angle = 0.0f, string fileName = "DustSmall")
{
	CParticle@ p = ParticleAnimated("DustSmall", pos, Vec2f(0, 0), angle, 1.0f, 3, 0.0f, false);
	if (p !is null)
	{
		p.width = 8;
		p.height = 8;
	}
}
