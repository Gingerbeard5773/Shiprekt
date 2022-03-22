//coupling
void onInit(CBlob@ this)
{
    this.addCommandID("decouple");
    this.Tag("coupling");
	this.Tag("removable");//for corelinked checks
	
	this.set_f32("weight", 0.1f);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getShape().getVars().customData <= 0)//mycolour
        return;

	//only owners can directly destroy the coupling
    if (this.getDistanceTo(caller) < 6 && caller.getPlayer().getUsername() == this.get_string("playerOwner"))
	{
		CButton@ button = caller.CreateGenericButton(2, Vec2f(0.0f, 0.0f), this, this.getCommandID("decouple"), "Decouple");
		if (button !is null) button.radius = 3.3f; //engine fix
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("decouple"))
    {
        this.server_Die();
    }
}