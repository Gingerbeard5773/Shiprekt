#define CLIENT_ONLY
#include "ShipsCommon.as";

f32 zoomTarget = 1.0f;
float timeToScroll = 0.0f;

string _targetPlayer;
s32 _shipID;
bool waitForRelease = false;

CPlayer@ targetPlayer()
{
	return getPlayerByUsername(_targetPlayer);
}

void SetTargetPlayer(CPlayer@ p, CCamera@ camera = null)
{
	_shipID = 0;
	_targetPlayer = p is null ? "" : p.getUsername();
	
	if (camera !is null)
		camera.setTarget(null);
}

void Spectator(CRules@ this)
{
	CCamera@ camera = getCamera();
	CControls@ controls = getControls();
	CMap@ map = getMap();

	//Get a target from the scoreboard
	if (this.get_bool("set new target"))
	{
		_targetPlayer = this.get_string("new target");
		if (targetPlayer() !is null)
		{
			waitForRelease = true;
			this.set_bool("set new target", false);
		}
	}

	if (camera is null || controls is null || map is null)
		return;
		
	const Vec2f dim = map.getMapDimensions();

	//Zoom in and out using mouse wheel
	if (timeToScroll <= 0)
	{
		if (controls.mouseScrollUp)
		{
			timeToScroll = 1;
			if (zoomTarget <= 0.2f)
				zoomTarget = 0.5f;
			else if (zoomTarget <= 0.5f)
				zoomTarget = 1.0f;
			else if (zoomTarget <= 1.0f)
				zoomTarget = 2.0f;
		}
		else if (controls.mouseScrollDown)
		{
			CPlayer@ localPlayer = getLocalPlayer();
			const bool isSpectator = localPlayer !is null ? localPlayer.getTeamNum() == this.getSpectatorTeamNum() : false;
			const bool allowMegaZoom = isSpectator && dim.x > 900 && camera.getTarget() is null; //map must be large enough, player has to be spectator team
			
			timeToScroll = 1;
			if (zoomTarget >= 2.0f)
				zoomTarget = 1.0f;
			else if (zoomTarget >= 1.0f)
				zoomTarget = 0.5f;
			else if (zoomTarget >= 0.5f && allowMegaZoom)
				zoomTarget = 0.2f;
		}
	}
	else
	{
		timeToScroll -= getRenderApproximateCorrectionFactor();
	}

	Vec2f pos = camera.getPosition();

	if (Maths::Abs(camera.targetDistance - zoomTarget) > 0.001f)
	{
		camera.targetDistance = (camera.targetDistance * (3 - getRenderApproximateCorrectionFactor() + 1.0f) + (zoomTarget * getRenderApproximateCorrectionFactor())) / 4;
	}
	else
	{
		camera.targetDistance = zoomTarget;
	}

	const f32 camSpeed = getRenderApproximateCorrectionFactor() * 15.0f / zoomTarget;

	//Move the camera using the action movement keys
	if (controls.ActionKeyPressed(AK_MOVE_LEFT))
	{
		pos.x -= camSpeed;
		SetTargetPlayer(null, camera);
	}
	if (controls.ActionKeyPressed(AK_MOVE_RIGHT))
	{
		pos.x += camSpeed;
		SetTargetPlayer(null, camera);
	}
	if (controls.ActionKeyPressed(AK_MOVE_UP))
	{
		pos.y -= camSpeed;
		SetTargetPlayer(null, camera);
	}
	if (controls.ActionKeyPressed(AK_MOVE_DOWN))
	{
		pos.y += camSpeed;
		SetTargetPlayer(null, camera);
	}

	if (controls.isKeyJustReleased(KEY_LBUTTON))
	{
		waitForRelease = false;
	}

	//Click on targets to track them or set camera to mousePos
	Vec2f mousePos = controls.getMouseWorldPos();
	if (controls.isKeyJustPressed(KEY_LBUTTON) && !waitForRelease)
	{
		SetTargetPlayer(null, camera);
		
		CBlob@[] candidates;
		map.getBlobsInRadius(controls.getMouseWorldPos(), 7.0f, @candidates);

		ShipDictionary@ ShipSet = getShipSet(this);
		const u16 playersLength = candidates.length;
		for (u16 i = 0; i < playersLength; i++)
		{
			CBlob@ blob = candidates[i];
			if ((blob.hasTag("player") || blob.hasTag("block")) && camera.getTarget() !is blob)
			{
				if (zoomTarget >= 0.2f)
					zoomTarget = 0.5f;
				
				const int bCol = blob.getShape().getVars().customData;
				if (bCol > 0)
				{
					//set a ship as the target
					Ship@ ship = ShipSet.getShip(bCol);
					if (ship is null || ship.centerBlock is null) return;
					
					_shipID = bCol;
					camera.setTarget(ship.centerBlock);
					camera.setPosition(ship.centerBlock.getInterpolatedPosition());
					return;
				}
				
				SetTargetPlayer(blob.getPlayer(), camera);
				camera.setTarget(blob);
				camera.setPosition(blob.getInterpolatedPosition());
				return;
			}
		}
	}
	else if (!waitForRelease && controls.isKeyPressed(KEY_LBUTTON) && camera.getTarget() is null) //classic-like held mouse moving
	{
		pos += ((mousePos - pos) / 8.0f) * getRenderApproximateCorrectionFactor();
	}
	
	//Track new blobs if our current one died
	if (camera.getTarget() is null)
	{
		if (_shipID > 0)
		{
			Ship@ ship = getShipSet(this).getShip(_shipID);
			if (ship !is null && ship.centerBlock !is null)
			{
				camera.setTarget(ship.centerBlock);
			}
			else
				_shipID = 0;
		}
		else if (targetPlayer() !is null)
		{
			CBlob@ plyBlob = targetPlayer().getBlob();
			if (plyBlob !is null)
			{
				camera.setTarget(plyBlob);
			}
		}
	}

	//Set specific zoom if we have a target
	if (camera.getTarget() !is null)
	{
		camera.mousecamstyle = 1;
		camera.mouseFactor = 0.5f;
		return;
	}

	//Don't go to far off the map boundaries

	const f32 borderMarginX = map.tilesize * (zoomTarget == 0.2f ? 15 : 2) / zoomTarget;
	const f32 borderMarginY = map.tilesize * (zoomTarget == 0.2f ? 5 : 2) / zoomTarget;

	if (pos.x < borderMarginX)
		pos.x = borderMarginX;
	if (pos.y < borderMarginY)
		pos.y = borderMarginY;
	if (pos.x > dim.x - borderMarginX)
		pos.x = dim.x - borderMarginX;
	if (pos.y > dim.y - borderMarginY)
		pos.y = dim.y - borderMarginY;

	camera.setPosition(pos);
}
