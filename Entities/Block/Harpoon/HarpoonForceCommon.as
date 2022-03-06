//Common file for getting forces from a propeller

#include "ShipsCommon.as";

const f32 HARPOON_SPEED = 0.5f;

void HarpoonForces(CBlob@ this,
					CBlob@ hitBlob,
					 float power,
					 Vec2f &out moveVel,
					 Vec2f &out moveNorm,
					 float &out angleVel)
{
	Ship@ movingShip = getShip(hitBlob.getShape().getVars().customData);

	Vec2f pos = this.getPosition();

	moveVel = -(hitBlob.getPosition() - this.getPosition());
	moveVel.Normalize();
	moveNorm = moveVel;
	const f32 moveSpeed = moveNorm.Normalize();

	// calculate "proper" force

	Vec2f fromCenter = pos - movingShip.pos;
	f32 fromCenterLen = fromCenter.Normalize();			
	f32 directionMag = Maths::Abs( fromCenter * moveNorm );
	f32 dist = 35.0f;
	f32 harpoonLength = (hitBlob.getPosition() - this.getPosition()).getLength();
	f32 centerMag = (dist - Maths::Min( dist, fromCenterLen ))/dist;
	f32 velCoef = (directionMag + centerMag)*0.5f + Maths::Pow(harpoonLength - harpoon_grapple_length, 2);

	moveVel *= velCoef;

	f32 turnDirection = Vec2f(moveNorm.y, -moveNorm.x) * fromCenter;
	f32 angleCoef = (1.0f - velCoef) * (1.0f - directionMag) * turnDirection;
	angleVel = angleCoef * moveSpeed;
}