#define CLIENT_ONLY

#include "WaterEffects.as"
#include "TileCommon.as"

Random _r(157681529);
Vec2f wind_direction;
Random _acidrandom(0x1a73a);

void onTick( CRules@ this )
{
	//if(getGameTime() % 2 == 0)
	//{
		//randomly permute the wind direction
		wind_direction.RotateBy( (_r.NextFloat() - 0.5f) * 3.0f, Vec2f());

		CCamera@ camera = getCamera();
		Driver@ d = getDriver();
		if(camera is null || d is null) return;
		
		Vec2f pos = camera.getPosition() + Vec2f( -d.getScreenWidth()/2 + _r.NextRanged(d.getScreenWidth()), -d.getScreenHeight()/2 + _r.NextRanged(d.getScreenHeight()) );
		CMap@ map = getMap();
		u16 tileType = map.getTile( pos ).type;
		
		if ( tileType == CMap::acid )
			MakeAcidBubble(pos, wind_direction, wind_direction.Angle() );
	//}
}



CParticle@ MakeAcidBubble(Vec2f pos, Vec2f vel, float angle)
{
	CParticle@ p = ParticleAnimated( "Sprites/acid_bubble.png",
											  pos, vel,
											  angle, //angle
											  0.8f+_acidrandom.NextFloat() * 0.4f, //scale
											  4, //animtime
											  0.0f, //gravity
											  true ); //selflit
	if(p !is null)
		p.Z = 100.0f;

	return p;
}