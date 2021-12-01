#define CLIENT_ONLY
#include "ActorHUDStartPos.as"
#include "TeamColour.as"
#include "IslandsCommon.as"
#include "KGUI.as";

bool showHelp = true;
bool justJoined = true;
bool page1 = true;
const int slotsSize = 6;
f32 boxMargin = 50.0f;
//key names
const string party_key = getControls().getActionKeyKeyName( AK_PARTY );
const string inv_key = getControls().getActionKeyKeyName( AK_INVENTORY );
const string pick_key = getControls().getActionKeyKeyName( AK_PICKUP );
const string taunts_key = getControls().getActionKeyKeyName( AK_TAUNTS );
const string use_key = getControls().getActionKeyKeyName( AK_USE );
const string action1_key = getControls().getActionKeyKeyName( AK_ACTION1 );
const string action2_key = getControls().getActionKeyKeyName( AK_ACTION2 );
const string action3_key = getControls().getActionKeyKeyName( AK_ACTION3 );
const string map_key = getControls().getActionKeyKeyName( AK_MAP );
const string zoomIn_key = getControls().getActionKeyKeyName( AK_ZOOMIN );
const string zoomOut_key = getControls().getActionKeyKeyName( AK_ZOOMOUT );

Window@ helpWindow;
Label@ helpText;
Button@ nextBtn;
Button@ doneBtn;
		
void onInit( CRules@ this )
{
	CFileImage@ image = CFileImage("GameHelp.png");
	Vec2f imageSize = Vec2f(image.getWidth(), image.getHeight());
	AddIconToken("$HELP$", "GameHelp.png", imageSize, 0);
	u_showtutorial = true;// for ShowTipOnDeath to work
}

void onTick( CRules@ this )
{
	CControls@ controls = getControls();
	if (controls.isKeyJustPressed(KEY_F1))
	{
		u_showtutorial = true;// for ShowTipOnDeath to work
		showHelp = !showHelp;
		justJoined = false;
	}
	if (controls.isKeyJustPressed(KEY_LBUTTON))
		page1 = !page1;
}

//a work in progress
void onRender(CRules@ this)
{
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;
		
	CBlob@ localBlob = getLocalPlayerBlob();
	CControls@ controls = getControls();
	
	if (showHelp)
	{
		CCamera@ camera = getCamera();
		if (camera is null) return;
		camera.setRotation(0.0f);//for the the arrows to work
		
		SColor tipsColor = SColor(255, 255, 255, 255);
		f32 sWidth = getScreenWidth();
		f32 sHeight = getScreenHeight();
		u32 gameTime = getGameTime();
		
		//
		string intro =  "Welcome to Shiprekt! Made by Strathos, Chrispin, and various other community members.\n Last changes and fixes by Gingerbeard.";
		Vec2f introSize;
		GUI::GetTextDimensions(intro, introSize);

		Vec2f imageSize;
		GUI::GetIconDimensions("$HELP$", imageSize);

		string textInfo = "- Motherships:\n"+
		" * Gather Xs for Booty. Xs have more Booty the closer they spawn to the map center.\n"+
		" * Engines are very weak! Use Solid blocks as armor or Miniships will eat through them!\n\n"+
		"- Miniships:\n"+
		" * Xs yield little Booty, but weapons reward a lot per hit to enemy ships!\n"+
		" * Couplings stick to your Mothership on collision. Use them to dock with it.\n\n"+
		"- Other Tips:\n"+
		" * The higher a team is on the leaderboard, the more Booty you get for attacking them.\n"+  
		" * Each block has a different weight. The heavier, the more they slow your ship down.\n"+
		" * Get a refund on Blocks you bought by bringing up the buy window again.\n\n"+
		"- Default Controls:\n" +
		" [ " + inv_key + " ] get Blocks while aboard your Mothership. Produces couplings while in a seat.\n"+
		" [ " + action3_key + " ]  rotate blocks while building or release couplings when sitting.\n"+
		" [ " + action1_key + " ] punch when standing or fire Machineguns when sitting.\n"+
		" [ " + action2_key + " ]  <hold> fire handgun.\n"+
		" [ MOUSE MIDDLE ]  <hold> show point emote.\n"+
		" [ " + zoomIn_key + " ], [ " + zoomOut_key + " ]  zoom in/out.\n"+
		" [ " + party_key + " ]  access the tools menu.\n"+
		" [ " + map_key + " ]  scale the Compass 2x. Tap to toggle. Hold for a quick view.\n"+
		" [ " + pick_key + " ] OR [ " + taunts_key + " ]  <hold> toggle engines strafe mode.";

		Vec2f infoSize;
		GUI::GetTextDimensions( textInfo, infoSize );
		
		bool fitsVertically = sHeight > 2*imageSize.y + infoSize.y + 2 * boxMargin;

		Vec2f tlBox = Vec2f(sWidth/2 - imageSize.x - boxMargin,  Maths::Max( 10.0f, sHeight/2 - imageSize.y - infoSize.y/2 - boxMargin));
		Vec2f brBox = Vec2f(sWidth/2 + imageSize.x + boxMargin, sHeight/2 + imageSize.y + infoSize.y/2);
		
		string lastChangesInfo = "Last changes :\n"

		+ "- 11-30-2021 - By Gingerbeard\n"
		+ "  * Mini-station takes half as much time to capture.\n"
		+ "  * Explosives can now be deconstructed properly without detonating.\n"
		+ "  * Auxillary Core can only be created at your mothership.\n"
		+ "  * Harvesters can now properly deconstruct bombs.\n";

		Vec2f lastChangesSize;
		GUI::GetTextDimensions(lastChangesInfo, lastChangesSize);
		
		Vec2f tlBoxJustJoined = Vec2f(sWidth/2 - imageSize.x - boxMargin,  Maths::Max( 10.0f, sHeight/2 - imageSize.y - lastChangesSize.y/2));
		Vec2f brBoxJustJoined = Vec2f(sWidth/2 + imageSize.x + boxMargin, sHeight/2 + imageSize.y + lastChangesSize.y/2);
		
		//welcome
		//Draw box
		GUI::DrawButtonPressed(tlBox, brBox);
		if (justJoined)
		{
			GUI::DrawText(intro, Vec2f(Maths::Max(tlBox.x, sWidth/2 - introSize.x/2), tlBox.y + 20), tipsColor);
		} 
		//helptoggle, image && textInfo
		string helpToggle = (!justJoined || localBlob !is null) ? ">> Press Left Click to change page | F1 to toggle this Help Box (or type !help) <<" : ">> Press Left Click to change page <<";
		Vec2f toggleSize;
		GUI::GetTextDimensions(helpToggle, toggleSize);
		if (!justJoined || gameTime % 90 > 30)
		{
			GUI::DrawText(helpToggle, Vec2f(Maths::Max(tlBox.x, sWidth/2 - toggleSize.x/2), tlBox.y + 40), tipsColor);
			GUI::DrawText(helpToggle, Vec2f(Maths::Max(tlBox.x, sWidth/2 - toggleSize.x/2), tlBox.y + 2*imageSize.y  + boxMargin + 25), tipsColor);
		}
		
		if (page1)
		{
			GUI::DrawText(lastChangesInfo, Vec2f( sWidth/2 - imageSize.x,  tlBoxJustJoined.y + 2*imageSize.y + boxMargin), tipsColor);
			GUI::DrawIconByName( "$HELP$", Vec2f( sWidth/2 - imageSize.x,  tlBox.y + boxMargin + 10));
		}
		else
			GUI::DrawText(textInfo, Vec2f(sWidth/2 - infoSize.x/2,  tlBox.y + boxMargin + 40), tipsColor);
	
		
		//hud icons
		Vec2f tl = getActorHUDStartPosition(null, 6);
		if (localBlob is null)
		{
			GUI::DrawIconByName("$BOOTY$", tl + Vec2f(111, -12));
			GUI::DrawIconByName("$CREW$", tl + Vec2f(67, -11));
		}
		
		if (localBlob is null || (controls.getMouseScreenPos() - tl - Vec2f(125, 20)).Length() > 50.0f)
		{
			SColor arrowColor = SColor( 150, 255, 255, 255 );
			GUI::DrawText( "Click these Icons for Control and Booty functions",  tl + Vec2f(225, 5), tipsColor);
			GUI::DrawSplineArrow2D( tl + Vec2f(225, 7), tl + Vec2f(145, -12), arrowColor);
			GUI::DrawSplineArrow2D( tl + Vec2f(225, 7), tl + Vec2f(105, -12), arrowColor);
		}
		
		if (helpWindow !is null)
		{
			if (helpWindow.isEnabled){helpWindow.draw();} //telling window to draw iteself
		}
	}
}

//failback for F1 key problems
bool onClientProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{	
	if (player !is null && player.isMyPlayer() && textIn == "!help")
	{
		showHelp = !showHelp;
		justJoined = false;
	}
	
	return true;
}