void sparks(Vec2f at, f32 angle, f32 damage)
{
    int amount = damage*5 + XORRandom(5);

    for (int i = 0; i < amount; i++)
    {
        Vec2f vel = getRandomVelocity(angle, damage * 3.0f, 180.0f)*0.1f;
        vel.y = vel.y - float(XORRandom(100))/100.0f;
		vel.x = vel.x - float(XORRandom(100))/100.0f;
        CParticle@ p = ParticlePixel( at, vel, SColor( 255, 255, 255, 0), true );
		
        if(p is null) return; //bail if we stop getting particles

        p.Z = 550;
    }
}
