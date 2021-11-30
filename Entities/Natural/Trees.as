// tree logic

void onInit( CBlob@ this )
{
    this.Tag("land");
    int n = XORRandom(2);
    if (n == 1){
    this.setAngleDegrees(90.0f);}
    else if (n == 0){
    this.setAngleDegrees(180.0f);}
    else if (n == 2){
    this.setAngleDegrees(270.0f);}
}

void onInit( CSprite@ this )
{
	this.SetFrame( XORRandom(1) );
	this.SetZ(250.0f);
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	damage = 0.0f;
	return damage;
}

