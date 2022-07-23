#define CLIENT_ONLY
#include "ShipsCommon.as"
#include "TileCommon.as"

f32 zoom = 1.0f;

void onInit(CBlob@ this)
{
	this.set_f32("camera_angle", 0.0f);
	this.set_f32("camera_zoom", zoom);
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
}

void onTick(CBlob@ this)
{
	CCamera@ camera = getCamera();
	if (camera is null) return;
	
	//set camera zoom
	CControls@ controls = getControls();
	const bool zoomIn = controls.isKeyJustPressed(controls.getActionKeyKey(AK_ZOOMIN));
	const bool zoomOut = controls.isKeyJustPressed(controls.getActionKeyKey(AK_ZOOMOUT));
	if (zoomIn)
	{
		if (zoom == 1.0f)
		{
			zoom = 2.0f;
		}
		else if (zoom == 0.5f)
		{
			zoom = 1.0f;
		}
	}
	else if (zoomOut)
	{
		if (zoom == 1.0f)
		{
			zoom = 0.5f;
		}
		else if (zoom == 2.0f)
		{
			zoom = 1.0f;
		}
	}
	this.set_f32("camera_zoom", zoom);
	
	if (this.getName() == "shark") return;
	
	//set camera rotation
	f32 angle = camera.getRotation();
	if (this.isAttached()) //use angle of seat
	{
		CBlob@ seat = this.getAttachmentPoint(0).getOccupied();
		if (seat !is null && seat.hasTag("hasSeat"))
			angle = seat.getAngleDegrees() + 90.0f;
	}
	else
	{
		//reference off block we're on
		CBlob@ refBlob = getBlobByNetworkID(this.get_u16("shipBlobID"));
		if (refBlob !is null)
		{
			//find rotation
			const f32 camAngle = camera.getRotation();
			f32 nearest_angle = refBlob.getAngleDegrees();
			
			while (nearest_angle > camAngle + 45) nearest_angle -= 90.0f;
			while (nearest_angle < camAngle - 45) nearest_angle += 90.0f;
			
			angle = nearest_angle;
		}
		else if (isTouchingLand(this.getPosition()))
		{
			angle = Maths::Ceil((camera.getRotation()-45.0f) / 90.0f) * 90.0f;
		}
	}
	this.set_f32("camera_angle", angle);
}

void onSetPlayer(CBlob@ this, CPlayer@ player) // never runs on localhost, huh
{
	if (player !is null && player.isMyPlayer()) // setup camera to follow
	{
		CCamera@ camera = getCamera();
		camera.mousecamstyle = 1;
		camera.targetDistance = 1.0f; // zoom factor
		camera.posLag = 1.0f; // lag/smoothen the movement of the camera, carries outside of shiprekt for some reason
		camera.setRotation(0.0f);
		this.set_f32("camera_angle", 0.0f);
	}
}

void onDie(CBlob@ this)
{
	if (this.isMyPlayer())
	{
		CCamera@ camera = getCamera();
		if (camera !is null)
		{
			camera.setRotation(0.0f);
			camera.targetDistance = 1.0f;
		}
	}
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	CCamera@ camera = getCamera();
	if (camera is null) return;

	f32 next_zoom = blob.get_f32("camera_zoom");
	f32 old_zoom = camera.targetDistance;

	f32 next_angle = blob.get_f32("camera_angle");
	f32 angle = camera.getRotation();

	f32 angle_delta = next_angle - angle;
	if (angle_delta > 180.0f) angle += 360.0f;
	if (angle_delta < -180.0f) angle -= 360.0f;

	camera.setRotation(Maths::Lerp(angle, next_angle, getRenderApproximateCorrectionFactor()/2.0f));
	camera.targetDistance = Maths::Lerp(old_zoom, next_zoom, getRenderApproximateCorrectionFactor()/2.0f);
}