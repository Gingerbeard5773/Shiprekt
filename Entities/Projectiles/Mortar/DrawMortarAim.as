// warning: bad maths down there
void onRender(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    if (blob is null) return;

    CBlob@ occupier = getBlobByNetworkID(blob.get_u16("operatorid"));

    f32 distance = blob.get_f32("distance");
    //if (distance == 0) return;

    if (occupier !is null && occupier.getPlayer() !is null && occupier.isMyPlayer())
    {
        CControls@ controls = occupier.getControls();
        if (controls is null) return;

        Vec2f mspos = controls.getMouseScreenPos(); // screen positioning if not out of max radius
        Vec2f mpos = occupier.getAimPos();
        Vec2f diff = occupier.getPosition() - mpos;
        f32 dist = diff.Normalize();
        Vec2f aimVector = Vec2f(1, 0).RotateBy(occupier.getAngleDegrees()-blob.getAngleDegrees()+90);
        int scrw = getDriver().getScreenWidth();
        int scrh = getDriver().getScreenHeight();

        if (dist <= distance)
            GUI::DrawIcon("MortarAim.png", Vec2f(-18.5, -18.5)+mspos);
        else // set icon to max distance radius border
            GUI::DrawIcon("MortarAim.png", Vec2f(-18.5, -18.5)+Vec2f(scrw/2, scrh/2)-aimVector*(distance+distance/2.5)); // otherwise wrong icon placement distance, idk why
    }   // -18.5 is offset to center of the cursor
}