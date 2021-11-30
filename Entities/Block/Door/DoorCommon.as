//common functionality for door-like objects


bool canOpenDoor(CBlob@ this, CBlob@ blob)
{
	if ((blob.getShape().getConsts().collidable) && //solid   
	        (blob.getRadius() > 0.1f) && //large           // vvv lets see
	        (this.getTeamNum() == 255 || this.getTeamNum() == blob.getTeamNum()) &&
	        (blob.hasTag("player") || blob.hasTag("vehicle") || blob.hasTag("migrant"))) //tags that can open doors
	{
		Vec2f direction = Vec2f(0, -1);
		direction.RotateBy(this.getAngleDegrees());

		Vec2f doorpos = this.getPosition();
		Vec2f playerpos = blob.getPosition();

  return true;
	}
	return false;
}