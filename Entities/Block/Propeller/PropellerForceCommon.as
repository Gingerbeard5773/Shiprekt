//Common file for getting forces from a propeller

#include "ShipsCommon.as";

const f32 PROPELLER_SPEED = 0.9f;//0.9f

void PropellerForces(CBlob@ this,
					 Ship@ ship,
					 float power,
					 Vec2f &out moveVel,
					 Vec2f &out moveNorm,
					 float &out angleVel)
{
	Vec2f pos = this.getPosition();

	moveVel = Vec2f(0.0f, PROPELLER_SPEED * power);
		
	moveVel.RotateBy(this.getAngleDegrees());
	moveNorm = moveVel;
	const f32 moveSpeed = moveNorm.Normalize();

	// calculate "proper" force

	Vec2f fromCenter = pos - ship.pos;
	f32 fromCenterLen = fromCenter.Normalize();
	f32 directionMag = ship.blocks.length > 2 ? Maths::Abs(fromCenter * moveNorm) : 1.0f;//how "aligned" it is from center
	f32 dist = 35.0f;
	f32 centerMag = (dist - Maths::Min(dist, fromCenterLen))/dist;
	f32 velCoef = (directionMag + centerMag)*0.5f;

	moveVel *= velCoef;

	f32 dragFactor = Maths::Max(0.2f, 1.1f - 0.005f * ship.blocks.length);//Maths::Max(0.2f, 1.1f - 0.000055f * Maths::Pow(ship.blocks.length, 2))
	f32 turnDirection = Vec2f(dragFactor * moveNorm.y, dragFactor * -moveNorm.x) * fromCenter;//how "disaligned" it is from center
	f32 angleCoef = (1.0f - velCoef) * (1.0f - directionMag) * turnDirection;
	angleVel = angleCoef * moveSpeed;
}

//overload with fewer params
void PropellerForces(CBlob@ this, Ship@ ship, float power, Vec2f &out moveVel, float &out angleVel)
{
	Vec2f _a;
	PropellerForces(this, ship, power, moveVel, _a, angleVel);
}