#define CLIENT_ONLY

#include "ShipsCommon.as"
#include "TileCommon.as"

f32 cam_angle = 0.0f;
f32 cam_zoom = 1.0f;

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	if (!blob.isMyPlayer()) return;
	CCamera@ camera = getCamera();
	
	//set camera zoom
	CControls@ controls = getControls();
	const bool zoomIn = controls.isKeyJustPressed(controls.getActionKeyKey(AK_ZOOMIN));
	const bool zoomOut = controls.isKeyJustPressed(controls.getActionKeyKey(AK_ZOOMOUT));
	
	if (zoomIn)
	{
		if (cam_zoom == 1.0f)
		{
			cam_zoom = 2.0f;
		}
		else if (cam_zoom == 0.5f)
		{
			cam_zoom = 1.0f;
		}
	}
	else if (zoomOut)
	{
		if (cam_zoom == 1.0f)
		{
			cam_zoom = 0.5f;
		}
		else if (cam_zoom == 2.0f)
		{
			cam_zoom = 1.0f;
		}
	}

	cam_zoom = Maths::Clamp(cam_zoom, 0.5f, 2.0f);
	
	if (blob.getName() == "shark") return;
	
	//set camera rotation
	f32 angle = camera.getRotation();
	if (blob.isAttached()) //use angle of seat
	{
		CBlob@ seat = blob.getAttachmentPoint(0).getOccupied();
		if (seat !is null && seat.hasTag("hasSeat"))
			angle = seat.getAngleDegrees() + 90.0f;
	}
	else
	{
		//reference off block we're on
		CBlob@ refBlob = getBlobByNetworkID(blob.get_u16("shipBlobID"));
		if (refBlob !is null)
		{
			//find rotation
			const f32 camAngle = camera.getRotation();
			f32 nearest_angle = refBlob.getAngleDegrees();
			
			while (nearest_angle > camAngle + 45) nearest_angle -= 90.0f;
			while (nearest_angle < camAngle - 45) nearest_angle += 90.0f;
			
			angle = nearest_angle;
		}
		else if (isTouchingLand(blob.getPosition()))
		{
			angle = Maths::Ceil((camera.getRotation()-45.0f) / 90.0f) * 90.0f;
		}
	}
	cam_angle = angle;
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	if (!blob.isMyPlayer()) return;

	CCamera@ camera = getCamera();

	f32 old_angle = camera.getRotation();
	f32 old_zoom = camera.targetDistance;

	f32 angle_delta = cam_angle - old_angle;
	if (angle_delta > 180.0f) old_angle += 360.0f;
	if (angle_delta < -180.0f) old_angle -= 360.0f;

	camera.setRotation(Maths::Lerp(old_angle, cam_angle, getRenderApproximateCorrectionFactor()));
	camera.targetDistance = Maths::Lerp(old_zoom, cam_zoom, getRenderApproximateCorrectionFactor());
}