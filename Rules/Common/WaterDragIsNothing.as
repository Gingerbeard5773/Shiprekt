void onBlobCreated( CRules@ this, CBlob@ blob )
{
    CShape@ shape = blob.getShape();
    if (shape != @null)
    {
        if (shape.getVars().waterDragScale == 5.0f)
        {
            shape.getVars().waterDragScale = 0;
        }
    }
}