#define CLIENT_ONLY

#include "IslandsCommon.as";

bool mKeyTap = false;
bool mKeyWasPressed = false;
u32 mKeyPressTime = 0;

class CompassVars 
{
    s32[] core_teams;
    f32[] core_angles;
    f32[] core_distances;

    s32[] decoycore_teams;
    f32[] decoycore_angles;
    f32[] decoycore_distances;
	
    s32[] station_teams;
    f32[] station_angles;
    f32[] station_distances;
	
	//s32[] ministation_teams;
    //f32[] ministation_angles;
    //f32[] ministation_distances;

    s32[] human_teams;
    f32[] human_angles;
    f32[] human_distances;
	
    f32 center_angle;
	f32 center_distance;
	
	f32 booty_angle;
	f32 booty_distance;
	
	f32 treasure_angle;
	f32 treasure_distance;
	
	f32 isle_angle;
	f32 isle_distance;

    CompassVars() {
        Reset();
    }

    void Reset() {
        center_angle = 0.0f;
		center_distance = -1.0f;
        core_angles.clear();
        core_teams.clear();
        core_distances.clear();
        decoycore_angles.clear();
        decoycore_teams.clear();
        decoycore_distances.clear();
        station_angles.clear();
        station_teams.clear();
        station_distances.clear();
		//ministation_angles.clear();
        //ministation_teams.clear();
        //ministation_distances.clear();
        human_angles.clear();
        human_teams.clear();
        human_distances.clear();
		booty_angle = 0.0f;
		booty_distance = -1.0f;
		treasure_angle = 0.0f;
		treasure_distance = -1.0f;
		isle_angle = 0.0f;
		isle_distance = -1.0f;
    }
};

CompassVars _vars;

void onTick( CRules@ this )
{
    _vars.Reset();

    CPlayer@ p = getLocalPlayer();
    if (p is null || !p.isMyPlayer()) return;

    CBlob@ b = p.getBlob();
	CCamera@ camera = getCamera();
    if(b is null && camera is null) return;

    Vec2f pos = b !is null ? b.getPosition() : camera.getPosition();
	u8 localTeamNum = p.getTeamNum();
	u8 specTeamNum = this.getSpectatorTeamNum();
	
	//center
	CMap@ map = getMap();
	Vec2f mapCenter = Vec2f( map.tilemapwidth * map.tilesize/2, map.tilemapheight * map.tilesize/2);
	Vec2f centerVec = mapCenter - pos;
	_vars.center_angle = centerVec.Angle() * -1.0f; 
	_vars.center_distance = centerVec.Length();

	//cores
    CBlob@[] cores;
    getBlobsByTag("mothership", @cores);
	for (uint i = 0; i < cores.length; i++)
    {
        CBlob@ core = cores[i];

        _vars.core_teams.push_back(core.getTeamNum());

        Vec2f offset = (core.getPosition() - pos);

        _vars.core_angles.push_back(offset.Angle() * -1.0f); 
        _vars.core_distances.push_back(offset.Length());
    }
	
	CBlob@[] decoycores;
    getBlobsByTag( "decoyCore", @decoycores );
    for (uint i = 0; i < decoycores.length; i++)
    {
        CBlob@ decoycore = decoycores[i];
			
        _vars.decoycore_teams.push_back(decoycore.getTeamNum());

        Vec2f offset = (decoycore.getPosition() - pos);

        _vars.decoycore_angles.push_back(offset.Angle() * -1.0f); 
        _vars.decoycore_distances.push_back(offset.Length());
    }
	
	//stations
    CBlob@[] stations;
    getBlobsByTag("station", @stations);
	getBlobsByTag("ministation", @stations);
    for (uint i = 0; i < stations.length; i++)
    {
        CBlob@ station = stations[i];

        _vars.station_teams.push_back(station.getTeamNum());

        Vec2f offset = (station.getPosition() - pos);

        _vars.station_angles.push_back(offset.Angle() * -1.0f); 
        _vars.station_distances.push_back(offset.Length());
    }
	
	//ministations
    /*CBlob@[] ministations;
    getBlobsByTag( "ministation", @ministations );
    for (uint i = 0; i < ministations.length; i++)
    {
        CBlob@ ministation = ministations[i];
			
        _vars.ministation_teams.push_back(ministation.getTeamNum());

        Vec2f offset = (ministation.getPosition() - pos);

        _vars.ministation_angles.push_back(offset.Angle() * -1.0f); 
        _vars.ministation_distances.push_back(offset.Length());
    }*/
	
	//humans
    CBlob@[] humans;
    getBlobsByTag("player", @humans);
    for (uint i = 0; i < humans.length; i++)
    {
        CBlob@ human = humans[i];		
        Vec2f offset = (human.getPosition() - pos);

		f32 distance = offset.Length();
		u8 teamNum = human.getTeamNum();
		
		if (distance < 208 || ( distance > 864 && localTeamNum != teamNum))//don't include if too close or too far
			continue;
			
        _vars.human_teams.push_back(teamNum);
        _vars.human_angles.push_back(offset.Angle() * -1.0f); 
        _vars.human_distances.push_back(distance);
    }
	
	//booty
	CBlob@[] booty;
    getBlobsByTag( "booty", @booty );	
	f32 closestBootyDist = 999999.9f;
	s16 closestBootyIndex = -1;
    for (uint i = 0; i < booty.length; i++)
    {
        CBlob@ currBooty = booty[i];
		Vec2f bootyPos = currBooty.getPosition();
		f32 distToPlayer = (bootyPos - pos).getLength();
		f32 dist = distToPlayer;	
		if (currBooty.get_u16( "ammount" ) > 0 && dist < closestBootyDist)
		{
			closestBootyDist = dist;
			closestBootyIndex = i;
		}
		if (closestBootyIndex >= 999) 
		{
			break;
		}
    }
	
	if ( closestBootyIndex > -1 )
	{
		Vec2f bootyOffset = (booty[closestBootyIndex].getPosition() - pos);

		_vars.booty_angle = bootyOffset.Angle() * -1.0f; 
		_vars.booty_distance = bootyOffset.Length();
	}
	
	//treasure
	CBlob@[] treasure;
    getBlobsByTag("revealed treasure", @treasure);	
	f32 closestTreasureDist = 999999.9f;
	s16 closestTreasureIndex = -1;
    for (uint i = 0; i < treasure.length; i++)
    {
        CBlob@ currTreasure = treasure[i];
		Vec2f treasurePos = currTreasure.getPosition();
		f32 distToPlayer = (treasurePos - pos).getLength();
		f32 dist = distToPlayer;	
		if (dist < closestTreasureDist)
		{
			closestTreasureDist = dist;
			closestTreasureIndex = i;
		}
		if (closestTreasureIndex >= 999) 
		{
			break;
		}
    }
	
	if (closestTreasureIndex > -1 )
	{
		Vec2f treasureOffset = (treasure[closestTreasureIndex].getPosition() - pos);

		_vars.treasure_angle = treasureOffset.Angle() * -1.0f; 
		_vars.treasure_distance = treasureOffset.Length();
	}
	
	//islands
	Island[]@ islands;
	f32 closestIsleDist = 999999.9f;
	s16 closestIsleIndex = -1;
	if ( getRules().get( "islands", @islands ) )	//count islands as booty too
	{
		for ( uint i = 0; i < islands.length; ++i )
		{								
			Island @isle = islands[i];	
			Vec2f islePos = isle.pos;
			f32 distToPlayer = (islePos - pos).getLength();
			f32 dist = distToPlayer;	
			if ( dist < closestIsleDist && isle.owner == "" )
			{
				closestIsleDist = dist;
				closestIsleIndex = i;
			}
			if (closestIsleIndex >= 999) 
			{
				break;
			}
		}
	}
	
	if ( closestIsleIndex > -1 )
	{
		Vec2f isleOffset = (islands[closestIsleIndex].pos - pos);

		_vars.isle_angle = isleOffset.Angle() * -1.0f; 
		_vars.isle_distance = isleOffset.Length();
	}
}

void onInit( CRules@ this )
{
    onRestart(this);
}

void onRestart( CRules@ this )
{
    _vars.Reset();
}

void onRender( CRules@ this )
{
    const string gui_image_fname = "GUI/compass.png";

    CCamera@ c = getCamera();
    f32 camangle = c.getRotation();
	CControls@ controls = getControls();
	bool mapKey = controls.ActionKeyPressed( AK_MAP );
	
	CPlayer@ p = getLocalPlayer();
	u8 localTeamNum = p !is null ? p.getTeamNum() : -1;
	
    Vec2f topLeft = Vec2f(8,8);
    Vec2f framesize = Vec2f(64,64);
    Vec2f center = Vec2f(32,32);

	if ( mapKey )
	{
		if ( !mKeyWasPressed )
		{
			mKeyWasPressed = true;
			mKeyPressTime = getGameTime();
		}
	} else if ( mKeyWasPressed )
	{
		mKeyWasPressed = false;
		mKeyTap = mKeyTap ? false : getGameTime() - mKeyPressTime < 10;
	}
		
	f32 scale = 1.0f;
	//GUI set scale
	if ( mKeyTap || ( controls.getMouseScreenPos() - topLeft - center ).Length() < 64.0f 
		|| mapKey )
	{
		scale = 2.0f;
	}
	
    GUI::DrawIcon(gui_image_fname, 0, framesize, topLeft * scale, scale, 0);

    //center
    {
        Vec2f pos(Maths::Min(8.0f, _vars.center_distance / 48.0f ), 0.0f);

        Vec2f thisframesize = Vec2f(16,16);

        pos.RotateBy(_vars.center_angle - camangle);
		
		if ( !getRules().get_bool( "whirlpool" ) )
			GUI::DrawIcon(gui_image_fname, 13, thisframesize, ( topLeft + (center + pos)*2.0f - thisframesize ) * scale, scale, 0);
		else
			GUI::DrawIcon("WhilrpoolIcon.png", 0, Vec2f(16,16), ( topLeft + (center + pos)*2.0f - thisframesize ) * scale, scale, 0);
    }
	
	//closest booty
	if ( _vars.booty_distance > 0.0f && _vars.booty_distance < _vars.isle_distance )
	{
        Vec2f pos(Maths::Min(18.0f, _vars.booty_distance / 48.0f), 0.0f);

        Vec2f thisframesize = Vec2f(16,16);

        pos.RotateBy(_vars.booty_angle - camangle);

        GUI::DrawIcon(gui_image_fname, 14, thisframesize, ( topLeft + (center + pos)*2.0f - thisframesize ) * scale, scale, 0);
    }
	
	//closest treasure
	if ( _vars.treasure_distance > 0.0f)
	{
        Vec2f pos(Maths::Min(18.0f, _vars.treasure_distance / 48.0f), 0.0f);

        Vec2f thisframesize = Vec2f(16,16);

        pos.RotateBy(_vars.treasure_angle - camangle);

        GUI::DrawIcon("WhilrpoolIcon.png", 0, Vec2f(16,16), ( topLeft + (center + pos)*2.0f - thisframesize ) * scale, scale, 1);
    }
	
	//closest island
	if ( _vars.isle_distance > 0.0f && _vars.isle_distance < _vars.booty_distance )
	{
        Vec2f pos(Maths::Min(18.0f, _vars.isle_distance / 48.0f), 0.0f);

        Vec2f thisframesize = Vec2f(16,16);

        pos.RotateBy(_vars.isle_angle - camangle);

        GUI::DrawIcon(gui_image_fname, 14, thisframesize, ( topLeft + (center + pos)*2.0f - thisframesize ) * scale, scale, 0);
    }
	
	//station icons
    for (uint i = 0; i < _vars.station_teams.length; i++)
    {
        Vec2f pos(Maths::Min(18.0f, _vars.station_distances[i] / 48.0f), 0.0f);

        Vec2f thisframesize = Vec2f(8,8);

        pos.RotateBy(_vars.station_angles[i] - camangle);

        GUI::DrawIcon(gui_image_fname, 25, thisframesize, ( topLeft + (center + pos)*2.0f - thisframesize ) * scale, scale, _vars.station_teams[i]);
    }
	
	//ministation icons
    /*for (uint i = 0; i < _vars.ministation_teams.length; i++)
    {
        Vec2f pos(Maths::Min(18.0f, _vars.ministation_distances[i] / 48.0f), 0.0f);

        Vec2f thisframesize = Vec2f(8,8);

        pos.RotateBy(_vars.ministation_angles[i] - camangle);

        GUI::DrawIcon(gui_image_fname, 25, thisframesize, ( topLeft + (center + pos)*2.0f - thisframesize ) * scale, scale, _vars.ministation_teams[i]);
    }*/
	
	//human icons
    for (uint i = 0; i < _vars.human_teams.length; i++)
    {
        Vec2f pos(Maths::Min(18.0f, _vars.human_distances[i] / 48.0f), 0.0f);
		
        Vec2f thisframesize = Vec2f(8,8);

		bool borderZoom = localTeamNum != _vars.human_teams[i] && pos.x > 16.5f;
        
		pos.RotateBy(_vars.human_angles[i] - camangle);
        
		GUI::DrawIcon(gui_image_fname, 23, thisframesize, ( topLeft + (center + pos)*2.0f - thisframesize ) * scale, scale * ( borderZoom ? 1.25f : 1.0f ), _vars.human_teams[i]);
    }
	
	
	//core icons
    for (uint i = 0; i < _vars.core_teams.length; i++)
    {
    	bool decoyExists = false;
    	uint decoycore_index = 0;
    	if (_vars.decoycore_teams.length > 0)
    	{
	    	for (uint h = 0; h < _vars.decoycore_teams.length; h++)
	    	{
	    		if (_vars.core_teams[i] == _vars.decoycore_teams[h])
	    		{
	    			decoyExists = true;
	    			decoycore_index = h;
	    		}
	    	}
	    }

    	if (decoyExists)
    	{
    		// draw decoy core as mother core
    		Vec2f pos(Maths::Min(18.0f, _vars.decoycore_distances[decoycore_index] / 48.0f), 0.0f);

	        Vec2f thisframesize = Vec2f(8,8);

	        pos.RotateBy(_vars.decoycore_angles[decoycore_index] - camangle);

	        GUI::DrawIcon(gui_image_fname, 24, thisframesize, ( topLeft + (center + pos)*2.0f - thisframesize ) * scale, scale, _vars.decoycore_teams[decoycore_index]);

	        // draw main core as miniship
	        Vec2f pos2(Maths::Min(18.0f, _vars.core_distances[i] / 48.0f), 0.0f);

	        pos2.RotateBy(_vars.core_angles[i] - camangle);

	        GUI::DrawIcon(gui_image_fname, 23, thisframesize, ( topLeft + (center + pos2)*2.0f - thisframesize ) * scale, scale, _vars.core_teams[i]);
    	}
    	else
    	{
	        Vec2f pos(Maths::Min(18.0f, _vars.core_distances[i] / 48.0f), 0.0f);

	        Vec2f thisframesize = Vec2f(8,8);

	        pos.RotateBy(_vars.core_angles[i] - camangle);

	        GUI::DrawIcon(gui_image_fname, 24, thisframesize, ( topLeft + (center + pos)*2.0f - thisframesize ) * scale, scale, _vars.core_teams[i]);
	    }
    }
}
