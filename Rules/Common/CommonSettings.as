#include "EmotesCommon.as"; 
const int BUTTON_SIZE = 4;

void onInit(CRules@ this)
{
	RegisterFileExtensionScript("WaterPNGMap.as", "png");
    particles_gravity.y = 0.0f; 
    sv_gravity = 0;    
    v_camera_ints = false;
    sv_visiblity_scale = 2.0f;
	cc_halign = 2;
	cc_valign = 2;
	s_effects = false;
	
	//gameplay settings (could be a cfg file)
	this.set_u16("starting_booty", 325);
	this.set_u16("warmup_time", 1 * 150 * 30);//no weapons warmup time
	this.set_u16("booty_x_max", 200);
	this.set_u16("booty_x_min", 100);
	this.set_u16("booty_transfer", 50);//min transfer ammount
	this.set_f32("booty_transfer_fee", 0.0f);
	this.set_f32("build_distance", 16 * 16);//max distance from the core for purchasing blocks
	this.set_u16("bootyRefillLimit", 50);

	//
	
	//Icons
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
	AddIconToken("$ANTIRAM$", "AntiRam.png", Vec2f(8,8), 0);
	AddIconToken("$PROPELLER$", "PropellerIcons.png", Vec2f(16,16), 0);
	AddIconToken("$RAMENGINE$", "PropellerIcons.png", Vec2f(16,16), 1);
	AddIconToken("$SEAT$", "Seat.png", Vec2f(8,8), 0);
	AddIconToken("$BOMB$", "Bomb.png", Vec2f(8,8), 0);
	AddIconToken("$HARVESTER$", "Harvester.png", Vec2f(16,16), 0);
	AddIconToken("$PATCHER$", "Patcher.png", Vec2f(16,16), 0);
	AddIconToken("$HARPOON$", "HarpoonBlock.png", Vec2f(16,16), 0); 
	AddIconToken("$MACHINEGUN$", "Machinegun.png", Vec2f(16,16), 0);
	AddIconToken("$CANNON$", "Cannon.png", Vec2f(16,16), 0);
	AddIconToken("$FLAK$", "Flak.png", Vec2f(16,16), 0);
	AddIconToken("$POINTDEFENSE$", "PointDefense.png", Vec2f(16,16), 0);
	AddIconToken("$LAUNCHER$", "Launcher.png", Vec2f(16,16), 0);
	AddIconToken("$COUPLING$", "Coupling.png", Vec2f(8,8), 0);
	AddIconToken("$REPULSOR$", "Repulsor.png", Vec2f(8,8), 0);
	AddIconToken("$SECONDARYCORE$", "SecondaryCore.png", Vec2f(8,8), 0);
	AddIconToken("$DECOYCORE$", "Mothership.png", Vec2f(8,8), 0);
	AddIconToken("$PISTON$", "Piston.png", Vec2f(8,8), 2);

	//spectator stuff
	this.addCommandID("pick teams");
    this.addCommandID("pick spectator");
	this.addCommandID("pick none");

    AddIconToken("$TEAMS$", "GUI/MenuItems.png", Vec2f(32,32), 1);
    AddIconToken("$SPECTATOR$", "GUI/MenuItems.png", Vec2f(32,32), 19);

	//sandbox notice
	if (getPlayersCount() == 0)
		client_AddToChat( "> Free building mode set until more players join! <");
	//warn for black water glitch
	if ( v_postprocess )
	{
		client_AddToChat(">", SColor(255, 255, 75, 75));
		client_AddToChat(">>", SColor(255, 255, 75, 75));
		client_AddToChat(">>>", SColor(255, 255, 75, 75));
		client_AddToChat("NOTICE: the \"smooth shader\" setting causes the water to turn black when zooming in.\nYou can disable the smooth shader at the Video Options tab.", SColor(255, 255, 75, 75));
	}
}

void ShowTeamMenu(CRules@ this)
{
	CPlayer@ local = getLocalPlayer();
    if (local is null) 
	{
        return;
    }

    CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos(), null, Vec2f( BUTTON_SIZE, BUTTON_SIZE), "Change team");

    if (menu !is null)
    {
		CBitStream exitParams;
		menu.AddKeyCommand(KEY_ESCAPE, this.getCommandID("pick none"), exitParams);
		menu.SetDefaultCommand(this.getCommandID("pick none"), exitParams);


        CBitStream params;
        params.write_u16(local.getNetworkID());
        if (local.getTeamNum() == this.getSpectatorTeamNum())
        {
			CGridButton@ button = menu.AddButton("$TEAMS$", "Auto-pick teams", this.getCommandID("pick teams"), Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);
		}
		else
		{
			CGridButton@ button = menu.AddButton("$SPECTATOR$", "Spectator", this.getCommandID("pick spectator"), Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);
		}
    }
}

void ReadChangeTeam(CRules@ this, CBitStream @params, int team)
{
    CPlayer@ player = getPlayerByNetworkId(params.read_u16());
    if (player is getLocalPlayer())
    {
        player.client_ChangeTeam(team);
        getHUD().ClearMenus();
    }
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("pick teams"))
    {
        ReadChangeTeam(this, params, -1);
    }
    else if (cmd == this.getCommandID("pick spectator"))
    {
        ReadChangeTeam(this, params, this.getSpectatorTeamNum());
	}
	else if (cmd == this.getCommandID("pick none"))
	{
		getHUD().ClearMenus();
	}
}

//bubble while in chat
//located in a strange place
void onEnterChat(CRules@ this)
{
	if (getChatChannel() != 0) return; //no dots for team chat

	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, Emotes::dots, 100000);
}

void onExitChat(CRules@ this)
{
	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, Emotes::off);
}
