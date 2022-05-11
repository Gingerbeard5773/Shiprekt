//Various particles 

Random spark;
void sparks(const Vec2f pos, const u8 amount, const f32 spread = 1.0f, const int16 pTime = 10)
{
	for (u8 i = 0; i < amount; i++)
    {
        Vec2f vel(spark.NextFloat() * spread, 0); //spread
        vel.RotateBy(spark.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixel(pos, vel, SColor(255, 255, 128 + spark.NextRanged(128), spark.NextRanged(128)), true);
        if (p is null) return; //bail if we stop getting particles

        p.timeout = pTime + spark.NextRanged(20);
        p.scale = 0.5f + spark.NextFloat();
        p.damping = 0.95f;
		p.collides = false;
		p.Z = 650.0f;
    }
}

void ShrapnelParticle(const Vec2f pos, const Vec2f vel)
{
	CParticle@ p = ParticlePixel(pos, vel, SColor(255, 255, 128 + XORRandom(128), 100), true);
	if (p !is null)
	{
		p.timeout = 10 + XORRandom(6);
		p.scale = 1.5f;
		p.Z = 650.0f;
		p.damping = 0.85f;
	}
}

Random shotrandom(0x15125);
void shotParticles(const Vec2f pos, const float angle, const bool smoke = true, const f32 smokeVelocity = 0.1f, const f32 scale = 1.0f)
{
	//muzzle flash
	{
		CParticle@ p = ParticleAnimated("Entities/Block/turret_muzzle_flash.png",
										pos, Vec2f(),
										-angle, //angle
										1.0f, //scale
										3, //animtime
										0.0f, //gravity
										true); //selflit
		if (p !is null)
		{
			p.Z = 650.0f;
		}
	}
	
	//smoke
	if (smoke)
	{
		Vec2f shot_vel = Vec2f(0.5f,0);
		shot_vel.RotateBy(-angle);
		
		for (u8 i = 0; i < 5; i++)
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
											true); //selflit
			if (p !is null)
			{
				p.Z = 640.0f;
			}
		}
	}
}

void AngledDirtParticle(const Vec2f pos, const f32 angle = 0.0f, const string fileName = "DustSmall")
{
	CParticle@ p = ParticleAnimated(fileName, pos, Vec2f(0, 0), angle, 1.0f, 3, 0.0f, false);
	if (p !is null)
	{
		p.width = 8;
		p.height = 8;
	}
}
