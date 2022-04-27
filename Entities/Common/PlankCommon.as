//script-side check for 1 way exit (vanilla platform). Used in instances where collisions cannot properly work with planks
//stolen from Rock.as in base
bool CollidesWithPlank(CBlob@ blob, Vec2f velocity)
{
	Vec2f direction = Vec2f(0.0f, -1.0f).RotateBy(blob.getAngleDegrees());
	float velocity_angle = direction.AngleWith(velocity);

	return !(velocity_angle > -90.0f && velocity_angle < 90.0f);
}
