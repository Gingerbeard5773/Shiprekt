void onInit(CBlob@ this)
{
	this.Tag("plank");
	this.Tag("solid");
	
	this.set_f32("weight", 3.0f);
	
	CShape@ shape = this.getShape();
	shape.AddPlatformDirection(Vec2f(0, -1), 89, false);
}
