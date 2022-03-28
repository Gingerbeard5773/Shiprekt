//Converts a block to the player's team after some time nearby
#include "TeamColour.as";
#include "ShipsCommon.as";

const int capture_radius = 8;
const u8 checkFrequency = 15;
const u8 checkFrequencyIdle = 30;

shared class ConvertInfo
{
	u8 currentTime;
	u8 converterTeam;
}

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = checkFrequencyIdle;
	this.set_u8("convertTime", 0);
	this.set_u8("convertTeam", this.getTeamNum());
	
	ConvertInfo capture;
	capture.currentTime = this.get_u8("capture time");
	capture.converterTeam = this.getTeamNum();
	this.set("ConvertInfo", @capture);
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;
	
	ConvertInfo@ capture;
	if (!this.get("ConvertInfo", @capture)) return;
	
	const u8 capture_time = this.get_u8("capture time"); //time it takes to capture
	u8 thisTeamNum = this.getTeamNum();
	u8 crewNum = 0;

	CBlob@[] blobsInRadius;
	getMap().getBlobsInRadius(this.getPosition(), capture_radius, @blobsInRadius);
	
	//use players in radius
	for (uint i = 0; i < blobsInRadius.length; i++)
	{
		CBlob@ b = blobsInRadius[i];
		u8 bTeamNum = b.getTeamNum();
		if (b.getName() == "human" && bTeamNum != thisTeamNum)
		{
			if (capture.converterTeam == thisTeamNum) //claim attack cycle
				capture.converterTeam = bTeamNum;
			if (capture.converterTeam == bTeamNum) //attack
				crewNum++;
		}
	}
	
	//if we are attached by ship, use players on ship to capture
	//uncomment to enable
	/*Ship@ ship = getShip(this.getShape().getVars().customData);
	if (ship !is null && ship.centerBlock !is null && ship.blocks.length > 2)
	{
		blobsInRadius.clear();
		getShipCrew(ship.centerBlock, @blobsInRadius);
		if (blobsInRadius.length > 0 && ship.centerBlock.getTeamNum() != thisTeamNum)
		{
			if (capture.converterTeam == thisTeamNum) //claim attack cycle
				capture.converterTeam = ship.centerBlock.getTeamNum();
			crewNum = blobsInRadius.length;
		}
	}*/
	
	if (crewNum > 0)
	{
		//start counting upwards
		capture.currentTime = Maths::Max(0, capture.currentTime - crewNum);
		this.getCurrentScript().tickFrequency = checkFrequency;
		
		if (capture.currentTime <= 0)
		{
			//capture!
			this.server_setTeamNum(capture.converterTeam);
		
			capture.currentTime = capture_time;
			this.getCurrentScript().tickFrequency = checkFrequencyIdle;
		}
	}
	else if (capture.currentTime < capture_time)
	{
		//start counting backwards
		capture.currentTime++;
		this.getCurrentScript().tickFrequency = checkFrequency;
	}
	else if (capture.currentTime >= capture_time)
	{
		//reset
		this.getCurrentScript().tickFrequency = checkFrequencyIdle;
		capture.converterTeam = this.getTeamNum();
	}
	
	if (capture.converterTeam != this.get_u8("convertTeam"))
	{
		//sync converterTeam for use in onRender
		this.set_u8("convertTeam", capture.converterTeam);
		this.Sync("convertTeam", true);
	}
	
	if (capture.currentTime != this.get_u8("convertTime"))
	{
		//sync currentTime for use in onRender
		this.set_u8("convertTime", capture.currentTime);
		this.Sync("convertTime", true);
	}
}

void getShipCrew(CBlob@ shipBlock, CBlob@[]@ crew) //Gets all the friendly players on the ship
{
	int coreColor = shipBlock.getShape().getVars().customData;
	CBlob@[] humans;
	getBlobsByName("human", @humans);
	for (u8 i = 0; i < humans.length; i++)
	{
		CBlob@ human = humans[i];
		if (human.getTeamNum() == shipBlock.getTeamNum())
		{
			CBlob@ shipBlob = getShipBlob(human);
			if (shipBlob !is null && shipBlob.getShape().getVars().customData == coreColor)
				crew.push_back(human);
		}
	}
}

//TODO: Convert this onRender into a human-sprite script and make it universal, for more than one purpose
void onRender(CSprite@ this)
{
	if (g_videorecording) return;
	
	CCamera@ camera = getCamera();
	if (camera is null) return;
	
	CBlob@ blob = this.getBlob();
	u8 convertTime = blob.get_u8("convertTime");
	if (convertTime >= blob.get_u8("capture time")) return;
	
	f32 camFactor = camera.targetDistance;
	Vec2f pos2d = getDriver().getScreenPosFromWorldPos(blob.getPosition());

	f32 hwidth = 50 * camFactor;
	f32 hheight = 10 * camFactor;

	pos2d.y -= 40 * camFactor;
	f32 padding = 4.0f * camFactor;
	f32 shift = 15.0f;
	f32 progress = (1.1f - float(convertTime) / float(blob.get_u8("capture time")))*(hwidth*2-(13* camFactor)); //13 is a magic number used to perfectly align progress
	
	GUI::DrawPane(Vec2f(pos2d.x - hwidth + padding, pos2d.y + hheight - shift - padding),
			  Vec2f(pos2d.x + hwidth - padding, pos2d.y + hheight - padding),
			  SColor(175,200,207,197)); 				//draw capture bar background
	
	if (progress >= float(8)) 					//draw progress if capture can start
	{
		GUI::DrawPane(Vec2f(pos2d.x - hwidth + padding, pos2d.y + hheight - shift - padding),
					  Vec2f((pos2d.x - hwidth + padding) + progress, pos2d.y + hheight - padding),
				  getTeamColor(blob.get_u8("convertTeam"))); //SColor(175,200,207,197)
	}
}
