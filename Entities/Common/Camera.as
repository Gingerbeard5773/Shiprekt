#define CLIENT_ONLY
#include "IslandsCommon.as"

int angle = 0;
f32 zoom = 1.0f;
const f32 ZOOM_SPEED = 0.1f;

void onInit( CBlob@ this )
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
}

void onTick( CBlob@ this )
{
	CCamera@ camera = getCamera();
	if (camera is null)
		return;
		
	Island@ island = getIsland( this );
	if ( island !is null && island.centerBlock !is null )
	{
		//find best refBlock
		CBlob@ refBlob = getIslandBlob( this );
		if ( refBlob !is null )
		{
			//find rotation
			f32 camAngle = camera.getRotation();
			f32 nearest_angle = refBlob.getAngleDegrees();
					
			while(nearest_angle > camAngle + 45)
				nearest_angle -= 90.0f;

			while(nearest_angle < camAngle - 45)
				nearest_angle += 90.0f;

			angle = nearest_angle;
		}
	}
	
	//seat facing direction
	if (this.isAttached())
	{
		CBlob@ seat = this.getAttachmentPoint(0).getOccupied();
		
		if(seat !is null && seat.hasTag("seat"))
		{
			const f32 seat_angle = seat.getAngleDegrees() + 90.0f;
			angle = seat_angle;
		}
	}

	CameraRotation( angle );//set rotation
	
	CControls@ controls = getControls();
	bool zoomIn = controls.isKeyJustPressed( controls.getActionKeyKey( AK_ZOOMIN ) );
	bool zoomOut = controls.isKeyJustPressed( controls.getActionKeyKey( AK_ZOOMOUT ) );
	// zoom
	if (zoom == 2.0f)	
	{
		if (zoomOut){
  			zoom = 1.0f;
  		}
		else if (camera.targetDistance < zoom)
			camera.targetDistance += ZOOM_SPEED;		
	}
	else if (zoom == 1.0f)	
	{
		if (zoomOut){
  			zoom = 0.5f;
  		}
  		else if (zoomIn){
  			zoom = 2.0f;
  		}
  		else if (camera.targetDistance < zoom)
			camera.targetDistance += ZOOM_SPEED;	
		else if (camera.targetDistance > zoom)
			camera.targetDistance -= ZOOM_SPEED;	
	}
	else if (zoom == 0.5f)
	{
		if (zoomIn){
  			zoom = 1.0f;
  		}
		else if (camera.targetDistance > zoom)	
			camera.targetDistance -= ZOOM_SPEED;
	}
}

void CameraRotation( f32 angle )
{
	CCamera@ camera = getCamera();
	if (camera !is null)
	{
		f32 camAngle = camera.getRotation();
		f32 rotdelta = angle - camAngle;
		if (rotdelta > 180) {
			rotdelta -= 360;
		}
		if (rotdelta < -180) {
			rotdelta += 360;
		}

		const f32 rotate_max = 20.0f;

		rotdelta = Maths::Max(Maths::Min(rotate_max, rotdelta), -rotate_max);

		const f32 rot = rotdelta / 1.75f;
		camAngle += rot;

		while(camAngle < -180.0f){
			camAngle += 360.0f;
		}
		while(camAngle > 180.0f){
			camAngle -= 360.0f;
		}
		
		camera.setRotation( camAngle );
	}
}

void onSetPlayer( CBlob@ this, CPlayer@ player )
{
	if (player !is null && player.isMyPlayer()) // setup camera to follow
	{
		CCamera@ camera = getCamera();
		camera.mousecamstyle = 1;
		camera.targetDistance = 1.0f; // zoom factor
		camera.posLag = 1.0f; // lag/smoothen the movement of the camera
	}
}

void onDie( CBlob@ this )
{
	if(this.isMyPlayer())
	{
		CCamera@ camera = getCamera();
		if (camera !is null)
		{
			camera.setRotation(0.0f);
			camera.targetDistance = 1.0f;
		}
	}
}