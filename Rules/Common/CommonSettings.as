#include "EmotesCommon.as";
#include "Default/DefaultGUI.as"

void onInit(CRules@ this)
{
	//mod version
	this.set_string("version", "1.53.2");
	
	//change log
	this.set_string("changelog",
		  "- 12-25-2023 - By Gingerbeard\n"
		+ "  * Major map changes and new maps.\n"
		+ "  * Docking to ships with couplings is much more reliable.\n"
		+ "  * Disabled torpedo border bouncing.\n"
		+ "  * Fixed a years old bug where particles' size was incorrect.\n"
		+ "  * Bombs are much more stronger than before, but cost more.\n"
		+ "  * Machinegun bullets go farther.\n");
	
	//dedicated server name
	const string server_name = "[EU] Shiprekt++ ("+this.get_string("version")+")";
	
	if (sv_name != server_name)
	{
		if (isServer())
		{
			warn("\nServer name overwritten!\n" +
				 "Previous : " + sv_name + "\n" +
				 "Current  : " + server_name + "\n" +
				 "Change your server's name (if desired) at " + getCurrentScriptName() + "\n");
		}
		sv_name = server_name;
	}
	
	//mod support
	sv_contact_info = "github.com/Gingerbeard5773/shiprekt"; //if red circles appear, this link will show
	
	print("\n      ------- INITIALIZING SHIPREKT ------- "+
		  "\n" +
		  "\n  Version: " + this.get_string("version") +
		  "\n  Mod Page: " + sv_contact_info + 
		  "\n  Localhost: " + (isServer() && isClient()) +
		  "\n  Testing: " + sv_test +
		  "\n" +
		  "\n      ------------------------------------- \n", 0xff66C6FF);
	
	//engine settings
	particles_gravity.y = 0.0f;
	sv_gravity = 0;
	sv_visiblity_scale = 2.0f;
	
	//gameplay settings
	this.set_u16("starting_booty", 325);         //booty given to players on map restart
	this.set_u16("warmup_time", 150 * 30);       //no weapons warmup time
	this.set_u16("booty_x_max", 200);            //X maximum booty
	this.set_u16("booty_x_min", 100);            //X minimum booty
	this.set_u16("booty_transfer", 50);          //min transfer amount
	this.set_f32("booty_transfer_fee", 0.0f);    //percentage of booty lost during player-player transfer
	this.set_u16("bootyRefillLimit", 50);        //limit of welfare booty for poor captains
	
	//add icons
	LoadDefaultGUI();
	AddIconToken("$BOOTY$", "InteractionIconsBig.png", Vec2f(32,32), 26);
	AddIconToken("$CORE$", "InteractionIconsBig.png", Vec2f(32,32), 29);
	AddIconToken("$CAPTAIN$", "InteractionIconsBig.png", Vec2f(32,32), 11);
	AddIconToken("$CREW$", "InteractionIconsBig.png", Vec2f(32,32), 15);
	AddIconToken("$FREEMAN$", "InteractionIconsBig.png", Vec2f(32,32), 14);
	AddIconToken("$SEA$", "InteractionIconsBig.png", Vec2f(32,32), 9);
	AddIconToken("$ASSAIL$", "InteractionIconsBig.png", Vec2f(32,32), 10);
	AddIconToken("$PISTOL$", "Tools.png", Vec2f(32,32), 0);
	AddIconToken("$DECONSTRUCTOR$", "Tools.png", Vec2f(32,32), 1);
	AddIconToken("$RECONSTRUCTOR$", "Tools.png", Vec2f(32,32), 2);
	AddIconToken("$WOOD$", "platform.png", Vec2f(8,8), 0);
	AddIconToken("$SOLID$", "Solid.png", Vec2f(8,8), 0);
	AddIconToken("$DOOR$", "Door.png", Vec2f(8,8), 0);
	AddIconToken("$RAM$", "Ram.png", Vec2f(8,8), 0);
	AddIconToken("$PROPELLER$", "PropellerIcons.png", Vec2f(16,16), 0);
	AddIconToken("$RAMENGINE$", "PropellerIcons.png", Vec2f(16,16), 1);
	AddIconToken("$SEAT$", "Seat.png", Vec2f(8,8), 0);
	AddIconToken("$BOMB$", "Bomb.png", Vec2f(8,8), 0);
	AddIconToken("$HARVESTER$", "Harvester.png", Vec2f(16,16), 0);
	AddIconToken("$PATCHER$", "Patcher.png", Vec2f(16,16), 0);
	AddIconToken("$HARPOON$", "HarpoonBlock.png", Vec2f(16,16), 0); 
	AddIconToken("$MACHINEGUN$", "Machinegun.png", Vec2f(16,16), 0);
	AddIconToken("$HEAVYMACHINEGUN$", "HeavyMachinegun.png", Vec2f(21,13), 0);
	AddIconToken("$CANNON$", "Cannon.png", Vec2f(16,16), 0);
	AddIconToken("$FLAK$", "Flak.png", Vec2f(16,16), 0);
	AddIconToken("$POINTDEFENSE$", "PointDefense.png", Vec2f(16,16), 0);
	AddIconToken("$LAUNCHER$", "Launcher.png", Vec2f(16,16), 0);
	AddIconToken("$COUPLING$", "Coupling.png", Vec2f(8,8), 0);
	AddIconToken("$REPULSOR$", "Repulsor.png", Vec2f(8,8), 0);
	AddIconToken("$SECONDARYCORE$", "SecondaryCore.png", Vec2f(8,8), 0);
	AddIconToken("$DECOYCORE$", "Mothership.png", Vec2f(8,8), 0);
	AddIconToken("$PLANK$", "Plank.png", Vec2f(8,8), 0);
	
	//minimap only appears on browsing
	this.minimap = !isClient();
	
	//shiprekt is old and needs the old command system. very important.
	getNet().legacy_cmd = true;
	
	//add shaders
	Driver@ driver = getDriver();
	driver.AddShader("hq2x", 1.0f);
	driver.SetShader("hq2x", v_postprocess);
	
	this.addCommandID("sync bool");
	
	if (isServer())
	{
		this.set_bool("freebuild", true);
	}
	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
	syncBool(this, "whirlpool", false);
	syncBool(this, "freebuild", getPlayerCount() <= 1);
}

void Reset(CRules@ this)
{
	CCamera@ camera = getCamera();
	if (camera !is null)
		camera.setRotation(0.0f);

	if (this.get_bool("client debug") && isClient())
		LoadRules("CommonSettings.as");
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	syncBool(this, "freebuild", this.get_bool("freebuild"));
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	//set freebuild on if only one player remains
	if (isServer() && getPlayerCount() - 1 <= 1 && !this.get_bool("freebuild"))
	{
		getNet().server_SendMsg("> Free building mode set until more players join! <");
		syncBool(this, "freebuild", true);
	}
}

void syncBool(CRules@ this, const string&in boolname, const bool&in booltype)
{
	if (isServer())
	{
		CBitStream params;
		params.write_string(boolname);
		params.write_bool(booltype);
		this.SendCommand(this.getCommandID("sync bool"), params);
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("sync bool"))
	{
		const string boolname = params.read_string();
		this.set_bool(boolname, params.read_bool());
	}
}

//bubble while in chat
void onEnterChat(CRules@ this)
{
	if (getChatChannel() != 0) return; //no dots for team chat

	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, "smalldots", 100000);
}

void onExitChat(CRules@ this)
{
	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emoteByCommand(localblob, "");
}
