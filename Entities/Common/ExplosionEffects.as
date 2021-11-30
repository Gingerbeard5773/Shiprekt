void makeSmallExplosionParticle(Vec2f pos)
{
     CParticle@ p = ParticleAnimated( "Entities/Effects/Sprites/SmallExplosion"+(XORRandom(3)+1)+".png",
                      pos, Vec2f_zero, 0.0f, 1.0f,
                      3+XORRandom(3),
                      0.0f, true );
	
	if ( p !is null )
		p.Z = 550.0f;
}

void makeBrightExplosionParticle(Vec2f pos)
{
     CParticle@ p = ParticleAnimated( "Entities/Effects/Sprites/explosion_old.png",
                      pos, Vec2f_zero, 0.0f, 1.0f,
                      2+XORRandom(2),
                      0.0f, true );
	
	if ( p !is null )
		p.Z = 550.0f;
}

void makeLargeExplosionParticle(Vec2f pos)
{
	 CParticle@ p = ParticleAnimated( "Entities/Effects/Sprites/Explosion.png",
						pos, Vec2f_zero, 0.0f, 1.0f,
						3+XORRandom(3),
						0.0f, true );
	
	if ( p !is null )
		p.Z = 550.0f;
}

void makeHugeExplosionParticle(Vec2f pos)
{
	CParticle@ p = ParticleAnimated( "Entities/Effects/Sprites/Explosion.png",
						pos, Vec2f_zero, 0.0f, 2.0f,
						8,
						0.0f, true );
	
	if ( p !is null )
		p.Z = 550.0f;
}