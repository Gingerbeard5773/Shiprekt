
void onInit(CBlob@ this)
{
	this.Tag("fakeram");
    this.Tag("solid");
	
	this.set_u16("cost", 10);
	this.set_f32("weight", 0.5f);
}
