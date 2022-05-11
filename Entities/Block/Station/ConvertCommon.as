//Gingerbeard @ 3/27/2022
//Converts a block to the player's team after some time nearby
#include "TeamColour.as";
#include "ShipsCommon.as";

const int capture_radius = 8;
const u8 checkFrequency = 15;
const u8 checkFrequencyIdle = 40;

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
	const u8 thisTeamNum = this.getTeamNum();
	u8 crewNum = 0;

	CBlob@[] blobsInRadius;
	getMap().getBlobsInRadius(this.getPosition(), capture_radius, @blobsInRadius);
	
	//use players in radius
	const u8 blobsLength = blobsInRadius.length;
	for (u8 i = 0; i < blobsLength; i++)
	{
		CBlob@ b = blobsInRadius[i];
		const u8 bTeamNum = b.getTeamNum();
		if (b.getName() == "human" && bTeamNum != thisTeamNum)
		{
			if (capture.converterTeam == thisTeamNum) //claim attack cycle
				capture.converterTeam = bTeamNum;
			if (capture.converterTeam == bTeamNum) //attack
				crewNum++;
		}
	}
	
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
		this.Sync("convertTeam", true); //-1380000415 HASH
	}
	
	if (capture.currentTime != this.get_u8("convertTime"))
	{
		//sync currentTime for use in onRender
		this.set_u8("convertTime", capture.currentTime);
		this.Sync("convertTime", true); //-1321747407 HASH
	}
}

//TODO: Convert this onRender into a human-sprite script and make it universal, for more than one purpose
void onRender(CSprite@ this)
{
	if (g_videorecording) return;
	
	CCamera@ camera = getCamera();
	if (camera is null) return;
	
	CBlob@ blob = this.getBlob();
	const u8 convertTime = blob.get_u8("convertTime");
	if (convertTime >= blob.get_u8("capture time")) return;
	
	const f32 camFactor = camera.targetDistance;
	Vec2f pos2d = getDriver().getScreenPosFromWorldPos(blob.getPosition());

	const f32 hwidth = 50 * camFactor;
	const f32 hheight = 10 * camFactor;

	pos2d.y -= 40 * camFactor;
	const f32 padding = 4.0f * camFactor;
	const f32 shift = 15.0f;
	const f32 progress = (1.1f - float(convertTime) / float(blob.get_u8("capture time")))*(hwidth*2-(13* camFactor)); //13 is a magic number used to perfectly align progress
	
	GUI::DrawPane(Vec2f(pos2d.x - hwidth + padding, pos2d.y + hheight - shift - padding),
			  Vec2f(pos2d.x + hwidth - padding, pos2d.y + hheight - padding),
			  SColor(175,200,207,197)); //draw capture bar background
	
	if (progress >= float(8)) //draw progress if capture can start
	{
		GUI::DrawPane(Vec2f(pos2d.x - hwidth + padding, pos2d.y + hheight - shift - padding),
					  Vec2f((pos2d.x - hwidth + padding) + progress, pos2d.y + hheight - padding),
				  getTeamColor(blob.get_u8("convertTeam"))); //SColor(175,200,207,197)
	}
}
