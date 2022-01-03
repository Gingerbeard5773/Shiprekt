#include "HumanCommon.as";
#include "MakeBlock.as";
#include "WaterEffects.as";
#include "IslandsCommon.as";
#include "Booty.as";
#include "AccurateSoundPlay.as";
#include "TileCommon.as";
#include "Hitters.as";
#include "ParticleSparks.as";
#include "ParticleHeal.as";

int useClickTime = 0;
const int CONSTRUCT_VALUE = 5;
const int CONSTRUCT_RANGE = 48;
const f32 BULLET_SPREAD = 0.2f;
const f32 BULLET_SPEED = 9.0f;
const f32 BULLET_RANGE = 350.0f;
const u8 BUILD_MENU_COOLDOWN = 30;
const Vec2f BUILD_MENU_SIZE = Vec2f(7, 3);
const Vec2f MINI_BUILD_MENU_SIZE = Vec2f(3, 2);
const Vec2f TOOLS_MENU_SIZE = Vec2f(2, 6);
Random _shotspreadrandom(0x11598); //clientside

void onInit(CBlob@ this)
{
	this.Tag("player");	 
	this.addCommandID("get out");
	this.addCommandID("shoot");
	this.addCommandID("construct");
	this.addCommandID("punch");
	this.addCommandID("giveBooty");
	this.addCommandID("releaseOwnership");
	this.addCommandID("swap tool");
	//this.set_f32("cam rotation", 0.0f);

	this.getShape().getVars().waterDragScale = 0; // fix
	
	this.chatBubbleOffset = Vec2f(0.0f, 10.0f);

	if (isClient())
	{
		CBlob@ core = getMothership(this.getTeamNum());
		if (core !is null) 
		{
			this.setPosition(core.getPosition());
			this.set_u16("shipID", core.getNetworkID());
			this.set_s8("stay count", 3);
		}
	}
	
	this.SetMapEdgeFlags(u8(CBlob::map_collide_up) |
		u8(CBlob::map_collide_down) |
		u8(CBlob::map_collide_sides));
	
	this.set_u32("menu time", 0);
	this.set_bool("build menu open", false);
	this.set_string("last buy", "coupling");
	this.set_u16("last cost", 5);
	this.set_string("current tool", "pistol");
	this.set_u32("fire time", 0);
	this.set_u32("punch time", 0);
	this.set_u32("groundTouch time", 0);
	this.set_s32("sharkTurn time", 0);
	this.set_bool("onGround", true);//for syncing
	this.getShape().getVars().onground = true;
	directionalSoundPlay("Respawn", this.getPosition(), 2.5f);
}

void onTick(CBlob@ this)
{
	Move(this);
	
	u32 gameTime = getGameTime();

	if (this.isMyPlayer())
	{
		PlayerControls(this);

		if (gameTime % 10 == 0)
		{
			this.set_bool("onGround", this.isOnGround());
			this.Sync("onGround", false); //1954602763
		}
	}

	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ laser = sprite.getSpriteLayer("laser");

	//kill laser after a certain time
	if (laser !is null && !this.isKeyPressed(key_action2) && this.get_u32("fire time") + Human::CONSTRUCT_RATE < gameTime)
	{
		sprite.RemoveSpriteLayer("laser");
	}
	
	// stop reclaim effects
	if (this.isKeyJustReleased(key_action2) || this.isAttached())
	{
		this.set_bool("reclaimPropertyWarn", false);
		if (!sprite.getEmitSoundPaused())
		{
			sprite.SetEmitSoundPaused(true);
		}
		sprite.RemoveSpriteLayer("laser");
	}
}

void Move(CBlob@ this)
{
	const bool myPlayer = this.isMyPlayer();
	//const f32 camRotation = myPlayer ? getCamera().getRotation() : this.get_f32("cam rotation");
	const f32 camRotation = myPlayer ? getCamera().getRotation() : 0.0f;
	const bool attached = this.isAttached();
	Vec2f pos = this.getPosition();	
	Vec2f aimpos = this.getAimPos();
	Vec2f forward = aimpos - pos;
	CShape@ shape = this.getShape();
	CSprite@ sprite = this.getSprite();
	
	string currentTool = this.get_string("current tool");

	/*if (myPlayer)
	{
		this.set_f32("cam rotation", camRotation);
		this.Sync("cam rotation", false); //1732223106
	}*/
	
	if (!attached)
	{
		const bool up = this.isKeyPressed(key_up);
		const bool down = this.isKeyPressed(key_down);
		const bool left = this.isKeyPressed(key_left);
		const bool right = this.isKeyPressed(key_right);	
		const bool punch = this.isKeyPressed(key_action1);
		const bool shoot = this.isKeyPressed(key_action2);
		const u32 time = getGameTime();
		const f32 vellen = shape.vellen;
		Island@ isle = getIsland(this);
		const bool solidGround = shape.getVars().onground = attached || isle !is null || isTouchingLand(pos);
		if (!this.wasOnGround() && solidGround)
			this.set_u32("groundTouch time", time);//used on collisions

		// move
		Vec2f moveVel;

		if (up)
		{
			moveVel.y -= Human::walkSpeed;
		}
		else if (down)
		{
			moveVel.y += Human::walkSpeed;
		}
		
		if (left)
		{
			moveVel.x -= Human::walkSpeed;
		}
		else if (right)
		{
			moveVel.x += Human::walkSpeed;
		}

		if (!solidGround)
		{
			if (isTouchingShoal(pos))
			{
				moveVel *= 0.8f;
			}
			else
			{
				moveVel *= Human::swimSlow;
			}

			u8 tickStep = v_fastrender ? 15 : 5;

			if ((time + this.getNetworkID()) % tickStep == 0)
				MakeWaterParticle(pos, Vec2f()); 

			if (this.wasOnGround() && time - this.get_u32("lastSplash") > 45)
			{
				directionalSoundPlay("SplashFast", pos);
				this.set_u32("lastSplash", time);
			}
		}
		else
		{		
			// punch
			if (punch && !Human::isHoldingBlocks(this) && canPunch(this))
			{
				Punch(this);
			}
			
			//speedup on own mothership
			if (isle !is null && isle.isMothership && isle.centerBlock !is null)
			{
				CBlob@ thisCore = getMothership(this.getTeamNum());
				if (thisCore !is null && thisCore.getShape().getVars().customData == isle.centerBlock.getShape().getVars().customData)
					moveVel *= 1.35f;
			}
		}
		
		//tool actions
		if (shoot && !punch)
		{
			if (currentTool == "pistol" && canShootPistol(this)) // shoot
			{
				ShootPistol(this);
				sprite.SetAnimation("shoot");
			}
			else if (currentTool == "deconstructor" || currentTool == "reconstructor") //reclaim, repair
			{
				Construct(this);
			}
		}		

		//canmove check
		if (!getRules().get_bool("whirlpool") || solidGround)
		{
			moveVel.RotateBy(camRotation);
			Vec2f nextPos = (pos + moveVel*4.0f);
			
			this.setVelocity(moveVel);
		}

		// face

		f32 angle = camRotation;
		forward.Normalize();
		
		if (sprite.isAnimation("shoot") || sprite.isAnimation("reclaim") || sprite.isAnimation("repair"))
			angle = -forward.Angle();
		else
		{
			if (up && left) angle += 225;
			else if (up && right) angle += 315;
			else if (down && left) angle += 135;
			else if (down && right) angle += 45;
			else if (up) angle += 270;
			else if (down) angle += 90;
			else if (left) angle += 180;
			else if (right) angle += 0;
			else angle = -forward.Angle();
		}
		
		while(angle > 360)
			angle -= 360;
		while(angle < 0)
			angle += 360;

		shape.SetAngleDegrees(angle);	

		// artificial stay on ship
		if (myPlayer)
		{
			CBlob@ islandBlob = getIslandBlob(this);
			if (islandBlob !is null)
			{
				this.set_u16("shipID", islandBlob.getNetworkID());	
				this.set_s8("stay count", 3);
			}
			else
			{
				CBlob@ shipBlob = getBlobByNetworkID(this.get_u16("shipID"));
				if (shipBlob !is null)
				{
					s8 count = this.get_s8("stay count");		
					count--;
					if (count <= 0)
					{
						this.set_u16("shipID", 0);	
					}
					else if (!shipBlob.hasTag("solid") && !up && !left && !right && !down)
					{
						Island@ isle = getIsland(shipBlob.getShape().getVars().customData);
						if (isle !is null && isle.vel.Length() > 1.0f)
							this.setPosition(shipBlob.getPosition());
					}
					this.set_s8("stay count", count);		
				}
			}
		}
	}
	else
	{
		shape.getVars().onground = true;
	}
}

void PlayerControls(CBlob@ this)
{
	CHUD@ hud = getHUD();
	CControls@ controls = getControls();
	bool toolsKey = controls.isKeyJustPressed(controls.getActionKeyKey(AK_PARTY));
	CSprite@ sprite = this.getSprite();
	
	// bubble menu
	if (this.isKeyJustPressed(key_bubbles))
	{
		this.CreateBubbleMenu();
	}

	if (this.isAttached())
	{
	    // get out of seat
		if (this.isKeyJustPressed(key_use))
		{
			this.SendCommand(this.getCommandID("get out"));
		}

		// aim cursor
		hud.SetCursorImage("AimCursor.png", Vec2f(32,32));
		hud.SetCursorOffset(Vec2f(-34, -34));		
	}
	else
	{
		// use menu
	    if (this.isKeyJustPressed(key_use))
	    {
	        useClickTime = getGameTime();
	    }
	    if (this.isKeyPressed(key_use))
	    {
	        this.ClearMenus();
			this.ClearButtons();
	        this.ShowInteractButtons();

	        CBlob@ core = getMothership(this.getTeamNum());
	        if(core !is null)
	        {
		        if((this.getPosition() - core.getPosition()).Length() <= 4.5f) // standing on core
		        {
		        	this.add_s32("sharkTurn time", 1);
		        	if(this.get_s32("sharkTurn time") >= 15) // turn
	    			{
	    				turnToShark(this);
	    				this.set_s32("sharkTurn time", -1);
	    			}
		        }
	        }
	        
	    }
	    else if (this.isKeyJustReleased(key_use))
	    {
	    	bool tapped = (getGameTime() - useClickTime) < 10; 
			this.ClickClosestInteractButton(tapped ? this.getPosition() : this.getAimPos(), this.getRadius()*2);

	        this.ClearButtons();

	        if(this.get_s32("sharkTurn time") > 0)
	        	this.set_s32("sharkTurn time", 0);
	    }
	    else
	    {
	    	if(this.get_s32("sharkTurn time") > 0)
	        	this.set_s32("sharkTurn time", 0);
	    }

	    // default cursor
		if (hud.hasMenus())
			hud.SetDefaultCursor();
		else
		{
			hud.SetCursorImage("PointerCursor.png", Vec2f(32,32));
			hud.SetCursorOffset(Vec2f(-36, -36));		
		}
	}
	
	// click action1 to click buttons
	if (hud.hasButtons() && this.isKeyPressed(key_action1) && !this.ClickClosestInteractButton(this.getAimPos(), 2.0f))
	{
	}

	// click grid menus

    if (hud.hasButtons())
    {
        if (this.isKeyJustPressed(key_action1))
        {
		    CGridMenu @gmenu;
		    CGridButton @gbutton;
		    this.ClickGridMenu(0, gmenu, gbutton); 
	    } 
		else if (this.isKeyJustPressed(key_inventory))
		{
			
		}
	}
	
	//build menu
	if (this.isKeyJustPressed(key_inventory))
	{
		CBlob@ core = getMothership(this.getTeamNum());
		if (core !is null && !core.hasTag("critical"))
		{
			Island@ pIsle = getIsland( this );
			bool canShop = pIsle !is null && pIsle.centerBlock !is null 
							&& ((pIsle.centerBlock.getShape().getVars().customData == core.getShape().getVars().customData) 
							|| ((pIsle.isStation || pIsle.isMiniStation || pIsle.isSecondaryCore) && pIsle.centerBlock.getTeamNum() == this.getTeamNum()));

			if (!Human::isHoldingBlocks(this) && !this.isAttached())
			{
				if (!hud.hasButtons())
				{
					if (canShop)
					{
						this.set_bool("build menu open", true);

						u32 gameTime = getGameTime();
						
						if (gameTime - this.get_u32("menu time") > BUILD_MENU_COOLDOWN)
						{
							Sound::Play("buttonclick.ogg");
							this.set_u32("menu time", gameTime);
							BuildShopMenu(this, core, "Components", Vec2f(0,0), (pIsle.isStation || pIsle.isSecondaryCore) && !pIsle.isMothership, pIsle.isMiniStation);
						}
						else
							Sound::Play("/Sounds/bone_fall1.ogg");
					}
					else
						Sound::Play("/Sounds/bone_fall1.ogg");
				} 
				else if (hud.hasMenus())
				{
					this.ClearMenus();
					Sound::Play("buttonclick.ogg");
					
					if (this.get_bool("build menu open"))
					{
						CBitStream params;
						params.write_u16(this.getNetworkID());
						params.write_string(this.get_string("last buy"));
						params.write_u16(this.get_u16("last cost"));
						core.SendCommand(core.getCommandID("buyBlock"), params);
					}
					this.set_bool("build menu open", false);
				}
			}
			else if (Human::isHoldingBlocks(this))
			{
				CBitStream params;
				params.write_u16(this.getNetworkID());
				core.SendCommand(core.getCommandID("returnBlocks"), params);
			}
		}
	}

	//tools menu
	if (toolsKey && !this.isAttached())
	{
		if (!hud.hasButtons())
		{	
			this.set_bool("build menu open", false);
			
			Sound::Play("buttonclick.ogg");
			BuildToolsMenu(this, "Tools Menu", Vec2f(0,0));
			
		} 
		else if (hud.hasMenus())
		{
			this.ClearMenus();
			Sound::Play("buttonclick.ogg");
		}
	}
}

void turnToShark(CBlob@ this)
{
	CBlob@ core = getMothership(this.getTeamNum());
    if(core !is null)
    {
    	CBitStream params;
		params.write_u16(this.getNetworkID());
		core.SendCommand(core.getCommandID("turnShark"), params);
	}
}

void BuildShopMenu(CBlob@ this, CBlob@ core, string desc, Vec2f offset, bool isStation = false, bool isMiniStation = false)
{
	CRules@ rules = getRules();
		
	CGridMenu@ menu = CreateGridMenu(this.getScreenPos() + offset, core, isMiniStation ? MINI_BUILD_MENU_SIZE : BUILD_MENU_SIZE, desc);
	u32 gameTime = getGameTime();
	u16 WARMUP_TIME = getPlayersCount() > 1 && !rules.get_bool("freebuild") ? rules.get_u16("warmup_time") : 0;
	
	if (menu !is null) 
	{
		menu.deleteAfterClick = true;
		
		string description;
		{ //Seat
			description = "Use it to control your ship. It can also release and produce Couplings. Breaks on impact.";
			AddBlock(this, menu, "seat", "$SEAT$", "Seat", description, core, 25, 0.5f);
		}
		{ //Propeller
			description = "A ship motor with some armor plating for protection. Reliable and resists flak.";
			AddBlock(this, menu, "propeller", "$PROPELLER$", "Standard Engine", description, core, 45, 1.0f);
		}
		{ //Ram Engine
			description = "An engine that trades protection for extra power. Will break on impact with anything!";
			AddBlock(this, menu, "ramengine", "$RAMENGINE$", "Ram Engine", description, core, 50, 1.25f);
		}
		{ //Coupling
			description = "A versatile block used to hold and release other blocks.";
			AddBlock(this, menu, "coupling", "$COUPLING$", "Coupling", description, core, 5, 0.1f);
		}

		if (!isMiniStation)
		{
			{ //Wooden Hull
				description = "A very tough block for protecting delicate components. Can effectively negate damage from bullets, flak, and to some extent cannons.";
				AddBlock(this, menu, "solid", "$SOLID$", "Wooden Hull", description, core, 35, 0.75f);
			}
			{ //Wooden Platform
				description = "A good quality wooden floor panel. Get that deck shining.";
				AddBlock(this, menu, "platform", "$WOOD$", "Wooden Hull", description, core, 15, 0.2f);
			}
			{ //Wooden Door
				description = "A wooden door. Useful for ship security.";
				AddBlock(this, menu, "door", "$DOOR$", "Wooden Door", description, core, 60, 1.0f);
			}
			{ //Harpoon
				description = "A manual-fire harpoon launcher. Can be used for grabbing, towing, or water skiing!";
				AddBlock(this, menu, "harpoon", "$HARPOON$", "Harpoon", description, core, 65, 2.0f);
			}
			{ //Harvester
				description = "An industrial-sized deconstructor that allows you to quickly mine resources from ship debris. Largely ineffective against owned ships.\nAmmoCap: infinite";
				AddBlock(this, menu, "harvester", "$HARVESTER$", "Harvester", description, core, 75, 2.0f);
			}
			{ //Patcher
				description = "An industrial-sized reconstructor that shoots a green restoration beem through a ship, repairing multiple ship parts concomitantly.\nAmmoCap: infinite";
				AddBlock(this, menu, "patcher", "$PATCHER$", "Patcher", description, core, 200, 3.0f);
			}
			{ //Anti Ram Hull
				description = "An excellent defence against enemy rammers. Can absorb multiple ram components. Partially weaker against gunfire than Wood Hull.";
				AddBlock(this, menu, "antiram", "$ANTIRAM$", "Anti-Ram Hull", description, core, 35, 0.75f);
			}
			{ //Repulsor
				description = "Explodes pushing blocks away. Can be triggered remotely or by impact. Activates in a chain.";
				AddBlock(this, menu, "repulsor", "$REPULSOR$", "Repulsor", description, core, 15, 0.25f);
			}
			{ //Ram Hull
				description = "A rigid block that fractures on contact with other blocks. Will destroy itself as well as the block it hits. Can effectively negate damage from bullets, flak, and to some extent cannons.";
				AddBlock(this, menu, "ram", "$RAM$", "Ram Hull", description, core, 50, 2.0f, gameTime < WARMUP_TIME);
			}
			if (!isStation)
			{ //Auxilliary Core
				description = "Similar to the Mothership core. Very powerful - gives greater independence to support ships. Can be improvised into a mega-yield explosive.";
				AddBlock(this, menu, "secondarycore", "$SECONDARYCORE$", "Auxilliary Core", description, core, 800, 12.0f, gameTime < WARMUP_TIME);
			}
			{ //Bomb
				description = "Explodes on contact. Very useful against Solid blocks.";
				AddBlock(this, menu, "bomb", "$BOMB$", "Bomb", description, core, 30, 2.0f, gameTime < WARMUP_TIME);
			}
		}
		{ //Point Defense
			description = "A short-ranged automated defensive turret that fires lasers with pin-point accuracy. Able to deter enemy personnel and neutralize incoming projectiles such as flak.\nAmmoCap: medium";
			AddBlock(this, menu, "pointdefense", "$POINTDEFENSE$", "Point Defense", description, core, 160, 3.5f, gameTime < WARMUP_TIME);
		}
		{ //Flak
			description = "A long-ranged automated defensive turret that fires high-explosive fragmentation shells with a proximity fuse. Best used as an unarmored ship deterrent. Effective against missiles, engines, and cores.\nAmmoCap: medium";
			AddBlock(this, menu, "flak", "$FLAK$", "Flak Cannon", description, core, 175, 2.5f, gameTime < WARMUP_TIME);
		}

		if (!isMiniStation)
		{
			{ //Machinegun
				description = "A fixed rapid-fire, lightweight, machinegun that fires high-velocity projectiles uncounterable by point defense. Effective against engines, flak cannons, and other weapons. However ineffectual against armour.\nAmmoCap: high";
				AddBlock(this, menu, "machinegun", "$MACHINEGUN$", "Machinegun", description, core, 125, 2.0f, gameTime < WARMUP_TIME);
			}
			{ //AP Cannon
				description = "A fixed cannon that fires momentum-bearing armor-piercing shells. Can penetrate up to 2 solid blocks, but deals less damage after each penetration. Effective against engines, flak cannons, and other weapons.\nAmmoCap: medium";
				AddBlock(this, menu, "cannon", "$CANNON$", "AP Cannon", description, core, 250, 3.25f, gameTime < WARMUP_TIME);
			}
			{ //Missile Launcher
				description = "A fixed tube that fires a slow missile with short-ranged guidance. Best used for close-ranged bombing, but can be used at range. Very effective against armored ships.\nAmmoCap: low";
				AddBlock(this, menu, "launcher", "$LAUNCHER$", "Missile Launcher", description, core, 400, 4.5f, gameTime < WARMUP_TIME);
			}
			{ //Decoy Core
				description = "A fake core to fool enemies.\nLimit of 3 per team per match. Currently bought: " + rules.get_u8("decoyCoreCount" + this.getTeamNum()) + "/3";
				CGridButton@ button = AddBlock(this, menu, "decoycore", "$DECOYCORE$", "Decoy Core", description, core, 150, 6.0f);
				button.SetEnabled(rules.get_u8("decoyCoreCount" + this.getTeamNum()) < 3);
			}
		}
	}
}

CGridButton@ AddBlock(CBlob@ this, CGridMenu@ menu, string block, string icon, string bname, string desc, CBlob@ core, u16 cost, f32 weight, bool isWeapon = false)
{
	//Add a block to the build menu
	CBitStream params;
	params.write_u16(this.getNetworkID());
	params.write_string(block);
	params.write_u16(cost);
			
	CGridButton@ button = menu.AddButton(icon, bname + " $" + cost, core.getCommandID("buyBlock"), params);

	const bool selected = this.get_string("last buy") == block;
	if (selected) button.SetSelected(2);
			
	button.SetHoverText(isWeapon ? "Weapons are enabled after the warm-up time ends.\n" :
						desc + "\nWeight: " + weight * 100 + "rkt\n" + (selected ? "\nPress the inventory key to buy again.\n" : ""));
	button.SetEnabled(!isWeapon);
	return button;
}

void BuildToolsMenu(CBlob@ this, string description, Vec2f offset)
{	
	CGridMenu@ menu = CreateGridMenu(this.getScreenPos() + offset, this, TOOLS_MENU_SIZE, description);
	if (menu !is null) 
	{
		menu.deleteAfterClick = true;

		string description;
		{ //Pistol
			description = "A basic, ranged, personal defence weapon.";
			AddTool(this, menu, "$PISTOL$", "Pistol", description, "pistol");
		}
		{ //Deconstructor
			description = "A tool that can reclaim ship parts for booty.";
			AddTool(this, menu, "$DECONSTRUCTOR$", "Deconstructor", description, "deconstructor");
		}
		{ //Reconstructor
			description = "A tool that can repair ship parts at the cost of booty. Can repair cores at a rate of 10 booty per 1% health.";
			AddTool(this, menu, "$RECONSTRUCTOR$", "Reconstructor", description, "reconstructor");
		}
	}
}

CGridButton@ AddTool(CBlob@ this, CGridMenu@ menu, string icon, string toolName, string desc, string currentTool)
{
	//Add a tool to the tools menu
	CBitStream params;
	params.write_u16(this.getNetworkID());
	params.write_string(currentTool);
	
	CGridButton@ button = menu.AddButton(icon, toolName, this.getCommandID("swap tool"), params);
			
	if (this.get_string("current tool") == currentTool)
		button.SetSelected(2);
			
	button.SetHoverText(desc);
	return button;
}

void Punch(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	Vec2f aimVector = this.getAimPos() - pos;
	
    HitInfo@[] hitInfos;
	if (this.getMap().getHitInfosFromArc(pos, -aimVector.Angle(), 150.0f, 10.0f, this, @hitInfos))
	{
		for (uint i = 0; i < hitInfos.length; i++)
		{
			CBlob @b = hitInfos[i].blob;
			if (b is null) continue;
			//dirty fix: get occupier if seat
			if (b.hasTag("hasSeat"))
			{
				AttachmentPoint@ seat = b.getAttachmentPoint(0);
				@b = seat.getOccupied();
			}
			if (b !is null && b.getName() == "human" && b.getTeamNum() != this.getTeamNum())
			{
				if (this.isMyPlayer())
				{
					CBitStream params;
					params.write_u16(b.getNetworkID());
					this.SendCommand(this.getCommandID("punch"), params);
				}
				return;
			}
		}
	}

	// miss
	directionalSoundPlay("throw", pos);
	this.set_u32("punch time", getGameTime());	
}

void ShootPistol(CBlob@ this)
{
	if (!this.isMyPlayer()) return;

	Vec2f pos = this.getPosition();
	Vec2f aimVector = this.getAimPos() - pos;
	const f32 aimdist = aimVector.Normalize();

	Vec2f offset(_shotspreadrandom.NextFloat() * BULLET_SPREAD,0);
	offset.RotateBy(_shotspreadrandom.NextFloat() * 360.0f, Vec2f());
	
	Vec2f vel = (aimVector * BULLET_SPEED) + offset;

	f32 lifetime = Maths::Min(0.05f + BULLET_RANGE/BULLET_SPEED/32.0f, 1.35f);

	CBitStream params;
	params.write_Vec2f(vel);
	params.write_f32(lifetime);

	Island@ island = getIsland(this);
	if (island !is null && island.centerBlock !is null)//relative positioning
	{
		params.write_bool(true);
		Vec2f rPos = (pos + aimVector*3) - island.centerBlock.getPosition();
		params.write_Vec2f(rPos);
		u32 islandColor = island.centerBlock.getShape().getVars().customData;
		params.write_u32(islandColor);
	}
	else//absolute positioning
	{
		params.write_bool(false);
		Vec2f aPos = pos + aimVector*9;
		params.write_Vec2f(aPos);
	}
	
	this.SendCommand(this.getCommandID("shoot"), params);
}

void Construct(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	Vec2f aimPos = this.getAimPos();
	CBlob@ mBlob = getMap().getBlobAtPosition(aimPos);
	Vec2f aimVector = aimPos - pos;

	Vec2f offset(_shotspreadrandom.NextFloat() * BULLET_SPREAD,0);
	offset.RotateBy(_shotspreadrandom.NextFloat() * 360.0f, Vec2f());
	CSprite@ sprite = this.getSprite();
	
	string currentTool = this.get_string("current tool");

	if (mBlob !is null && aimVector.getLength() <= CONSTRUCT_RANGE)
	{
		if (this.isMyPlayer())
		{
			CBitStream params;
			params.write_Vec2f(pos);
			params.write_Vec2f(aimPos);
			params.write_netid(mBlob.getNetworkID());
			
			this.SendCommand(this.getCommandID("construct"), params);
		}
		
		if (isClient())//effects
		{
			Vec2f barrelPos = pos + Vec2f(0.0f, 0.0f).RotateBy(aimVector.Angle());
			f32 offsetAngle = aimVector.Angle() - (mBlob.getPosition() - pos).Angle(); 
			
			CSpriteLayer@ laser = sprite.getSpriteLayer("laser");
			if (laser !is null)//laser management
			{
				laser.SetVisible(true);
				f32 laserLength = Maths::Max(0.1f, (aimPos - barrelPos).getLength() / 32.0f);						
				laser.ResetTransform();						
				laser.ScaleBy(Vec2f(laserLength, 1.0f));							
				laser.TranslateBy(Vec2f(laserLength*16.0f, + 0.5f));
				laser.RotateBy(offsetAngle, Vec2f());
				laser.setRenderStyle(RenderStyle::light);
			}
		}
		if (sprite.getEmitSoundPaused())
		{
			sprite.SetEmitSoundPaused(false);
		}	
	}
	else
	{
		if (isClient())//effects
		{
			sprite.RemoveSpriteLayer("laser");
		}
		if (!sprite.getEmitSoundPaused())
		{
			sprite.SetEmitSoundPaused(true);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (isServer() && this.getCommandID("get out") == cmd)
	{
		this.server_DetachFromAll();
	}
	else if (this.getCommandID("punch") == cmd && canPunch(this))
	{
		CBlob@ b = getBlobByNetworkID(params.read_u16());
		if (b !is null && b.getName() == this.getName() && b.getDistanceTo(this) < 100.0f)
		{
			Vec2f pos = b.getPosition();
			this.set_u32("punch time", getGameTime());
			directionalSoundPlay("Kick.ogg", pos);
			ParticleBloodSplat(pos, false);

			if (isServer())
				this.server_Hit(b, pos, Vec2f_zero, 0.25f, Hitters::muscles, false);
		}
	}
	else if (this.getCommandID("shoot") == cmd && canShootPistol(this))
	{
		Vec2f velocity = params.read_Vec2f();
		f32 lifetime = params.read_f32();
		Vec2f pos;
		
		if (params.read_bool())//relative positioning
		{
			Vec2f rPos = params.read_Vec2f();
			int islandColor = params.read_u32();
			Island@ island = getIsland(islandColor);
			if (island !is null && island.centerBlock !is null)
			{
				pos = rPos + island.centerBlock.getPosition();
				velocity += island.vel;
			}
			else
			{
				warn("BulletSpawn: island or centerBlock is null");
				Vec2f pos = this.getPosition();//failsafe (bullet will spawn lagging behind player)
			}
		}
		else
			pos = params.read_Vec2f();
		
		if (isServer())
		{
            CBlob@ bullet = server_CreateBlob("bullet", this.getTeamNum(), pos);
            if (bullet !is null)
            {
            	if (this.getPlayer() !is null)
				{
                	bullet.SetDamageOwnerPlayer(this.getPlayer());
                }
                bullet.setVelocity(velocity);
                bullet.server_SetTimeToDie(lifetime); 
            }
    	}
		
		this.set_u32("fire time", getGameTime());
		shotParticles(pos + Vec2f(0,0).RotateBy(-velocity.Angle())*6.0f, velocity.Angle(), true, 0.02f , 0.6f);
		directionalSoundPlay("Gunshot.ogg", pos, 0.75f);
	}
	else if (this.getCommandID("construct") == cmd && canConstruct(this))
	{
		Vec2f pos = params.read_Vec2f();
		Vec2f aimPos = params.read_Vec2f();
		CBlob@ mBlob = getBlobByNetworkID(params.read_netid());
		
		CPlayer@ thisPlayer = this.getPlayer();						
		if (thisPlayer is null) return;		
		
		string currentTool = this.get_string("current tool");
		Vec2f aimVector = aimPos - pos;	 
		
		if (mBlob !is null)
		{
			Island@ island = getIsland(mBlob.getShape().getVars().customData);
				
			const f32 mBlobCost = mBlob.get_u16("cost") > 0 ? (!mBlob.hasTag("coupling") ? mBlob.get_u16("cost") : 1) : 15;
			f32 mBlobHealth = mBlob.getHealth();
			f32 mBlobInitHealth = mBlob.getInitialHealth();
			const f32 initialReclaim = mBlob.get_f32("initial reclaim");
			f32 currentReclaim = mBlob.get_f32("current reclaim");
			
			f32 fullConstructAmount;
			if (mBlob.hasTag("mothership"))
				fullConstructAmount = (0.01f)*mBlobInitHealth;
			else if (mBlobCost > 0)
				fullConstructAmount = (CONSTRUCT_VALUE/mBlobCost)*initialReclaim;
			else
				fullConstructAmount = 0.0f;
							
			if (island !is null)
			{
				string isleOwner = island.owner;
				CBlob@ mBlobOwnerBlob = getBlobByNetworkID(mBlob.get_u16("ownerID"));
				
				if (currentTool == "deconstructor" && !mBlob.hasTag("mothership") && mBlobCost > 0)
				{
					f32 deconstructAmount = 0;
					if ((isleOwner == "" && !island.isMothership) //no owner and is not a mothership
						|| mBlob.get_string("playerOwner") == ""  //no one owns the block
						|| isleOwner == thisPlayer.getUsername()  //we own the island
						|| mBlob.get_string("playerOwner") == thisPlayer.getUsername() //we own the block
						|| mBlob.hasTag("station") || mBlob.hasTag("ministation")) //its a station
					{
						deconstructAmount = fullConstructAmount; 
					}
					else
					{
						deconstructAmount = (1.0f/mBlobCost)*initialReclaim; 
						this.set_bool("reclaimPropertyWarn", true);
					}
					
					if (!mBlob.hasTag("station") && !mBlob.hasTag("ministation") && 
					   (island.isStation || island.isMiniStation) && mBlob.getTeamNum() != this.getTeamNum())
					{
						deconstructAmount = (1.0f/mBlobCost)*initialReclaim; 
						this.set_bool("reclaimPropertyWarn", true);					
					}
					
					if ((currentReclaim - deconstructAmount) <=0)
					{		
						if (mBlob.hasTag("station") || mBlob.hasTag("ministation"))
						{
							if (mBlob.getTeamNum() != this.getTeamNum() && mBlob.getTeamNum() != 255)
							{
								mBlob.server_setTeamNum(255);
							}
						}
						else
						{
							string cName = thisPlayer.getUsername();

							server_addPlayerBooty(cName, mBlobCost*(mBlobHealth/mBlobInitHealth));
							directionalSoundPlay("/ChaChing.ogg", pos);
							mBlob.Tag("disabled");
							mBlob.server_Die();
						}
					}
					else
						mBlob.set_f32("current reclaim", currentReclaim - deconstructAmount);
				}
				else if (currentTool == "reconstructor")
				{			
					f32 reconstructAmount = 0;
					u16 reconstructCost = 0;
					string cName = thisPlayer.getUsername();
					u16 cBooty = server_getPlayerBooty(cName);
					
					if (mBlob.hasTag("mothership"))
					{
						//mothership
						const f32 motherInitHealth = 8.0f;
						if ((mBlobHealth + reconstructAmount) <= motherInitHealth)
						{
							reconstructAmount = fullConstructAmount;
							reconstructCost = CONSTRUCT_VALUE;
						}
						else if ((mBlobHealth + reconstructAmount) > motherInitHealth)
						{
							reconstructAmount = motherInitHealth - mBlobHealth;
							reconstructCost = (CONSTRUCT_VALUE - CONSTRUCT_VALUE*(reconstructAmount/fullConstructAmount));
						}
						
						if (cBooty >= reconstructCost && mBlobHealth < motherInitHealth)
						{
							mBlob.server_SetHealth(mBlobHealth + reconstructAmount);
							server_addPlayerBooty(cName, -reconstructCost);
						}
					}
					else if (mBlob.hasTag("station") || mBlob.hasTag("ministation"))
					{
						//stations
						if ((currentReclaim + reconstructAmount) <= initialReclaim)
						{
							reconstructAmount = fullConstructAmount;
							reconstructCost = CONSTRUCT_VALUE;
						}
						else if ((currentReclaim + reconstructAmount) > initialReclaim)
						{
							reconstructAmount = initialReclaim - currentReclaim;
							reconstructCost = CONSTRUCT_VALUE - CONSTRUCT_VALUE*(reconstructAmount/fullConstructAmount);
							
							if (mBlob.getTeamNum() == 255) //neutral
							{
								mBlob.server_setTeamNum(this.getTeamNum());
							}
						}
						
						mBlob.set_f32("current reclaim", currentReclaim + reconstructAmount);
					}
					else if (currentReclaim < initialReclaim)
					{
						//blocks
						if ((currentReclaim + reconstructAmount) <= initialReclaim)
						{
							reconstructAmount = fullConstructAmount;
							reconstructCost = CONSTRUCT_VALUE;
						}
						else if ((currentReclaim + reconstructAmount) > initialReclaim)
						{
							reconstructAmount = initialReclaim - currentReclaim;
							reconstructCost = CONSTRUCT_VALUE - CONSTRUCT_VALUE*(reconstructAmount/fullConstructAmount);
						}
						
						if ((currentReclaim + reconstructAmount > mBlobHealth) && cBooty >= reconstructCost)
						{
							mBlob.server_SetHealth(Maths::Clamp(mBlobHealth + reconstructAmount, 0.0f, mBlob.getInitialHealth()));
							mBlob.set_f32("current reclaim", currentReclaim + reconstructAmount);
							server_addPlayerBooty(cName, -reconstructCost);
						}
						else if ((currentReclaim + reconstructAmount) <= mBlobHealth)
							mBlob.set_f32("current reclaim", currentReclaim + reconstructAmount);
					}
				}
			}
			
			//laser creation
			if (isClient())//effects
			{
				Vec2f barrelPos = pos + Vec2f(0.0f, 0.0f).RotateBy(aimVector.Angle());
				f32 offsetAngle = aimVector.Angle() - (mBlob.getPosition() - pos).Angle(); 
				
				this.getSprite().RemoveSpriteLayer("laser");
				
				string beamSpriteFilename = currentTool == "deconstructor" ? "ReclaimBeam" : "RepairBeam";
					
				CSpriteLayer@ laser = this.getSprite().addSpriteLayer("laser", beamSpriteFilename + ".png", 32, 16);

				if (laser !is null)//partial length laser
				{
					Animation@ reclaimingAnim = laser.addAnimation("constructing", 1, true);
					int[] reclaimingAnimFrames = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
					reclaimingAnim.AddFrames(reclaimingAnimFrames);
					laser.SetAnimation("constructing");
					laser.SetVisible(true);
					f32 laserLength = Maths::Max(0.1f, (aimPos - barrelPos).getLength() / 32.0f);						
					laser.ResetTransform();						
					laser.ScaleBy(Vec2f(laserLength, 1.0f));							
					laser.TranslateBy(Vec2f(laserLength*16.0f, + 0.5f));
					laser.RotateBy(offsetAngle, Vec2f());
					laser.setRenderStyle(RenderStyle::light);
					laser.SetRelativeZ(-1);
				}
			}
		}
		
		this.set_u32("fire time", getGameTime());
	}
	else if (isServer() && this.getCommandID("releaseOwnership") == cmd)
	{
		CPlayer@ player = this.getPlayer();
		CBlob@ seat = getBlobByNetworkID(params.read_u16());
		
		if (player is null || seat is null) return;
		
		string owner = seat.get_string("playerOwner");
		if (owner == player.getUsername())
		{
			print("$ " + owner + " released seat: ID " + seat.getNetworkID());

			seat.set_string("playerOwner", "");
			seat.Sync("playerOwner", true); //2040865191
		}
	}
	else if (isServer() && this.getCommandID("giveBooty") == cmd)//transfer booty
	{
		CRules@ rules = getRules();
		if (getGameTime() < rules.get_u16("warmup_time")) return;
			
		u8 teamNum = this.getTeamNum();
		CPlayer@ player = this.getPlayer();
		string cName = getCaptainName(teamNum);		
		CPlayer@ captain = getPlayerByUsername(cName);
		
		if (captain is null || player is null) return;
		
		u16 transfer = rules.get_u16("booty_transfer");
		u16 fee = Maths::Round(transfer * rules.get_f32("booty_transfer_fee"));		
		string pName = player.getUsername();
		u16 playerBooty = server_getPlayerBooty(pName);
		if (playerBooty < transfer + fee) return;
			
		if (player !is captain)
		{
			print("$ " + pName + " transfers Booty to captain " + cName);
			u16 captainBooty = server_getPlayerBooty(cName);
			server_addPlayerBooty(pName, -transfer - fee);
			server_addPlayerBooty(cName, transfer);
		}
		else
		{
			CBlob@ core = getMothership(teamNum);
			if (core !is null)
			{
				int coreColor = core.getShape().getVars().customData;
				CBlob@[] crew;
				CBlob@[] humans;
				getBlobsByName("human", @humans);
				for (u8 i = 0; i < humans.length; i++)
				{
					if (humans[i].getTeamNum() == teamNum && humans[i] !is this)
					{
						CBlob@ islandBlob = getIslandBlob(humans[i]);
						if (islandBlob !is null && islandBlob.getShape().getVars().customData == coreColor)
							crew.push_back(humans[i]);
					}
				}
				
				if (crew.length > 0)
				{
					print("$ " + pName + " transfers Booty to crew");
					server_addPlayerBooty(pName, -transfer - fee);
					u16 shareBooty = Maths::Floor(transfer/crew.length);
					for (u8 i = 0; i < crew.length; i++ )
					{
						CPlayer@ crewPlayer = crew[i].getPlayer();						
						if (player is null) continue;
						
						string cName = crewPlayer.getUsername();

						server_addPlayerBooty(cName, shareBooty);
					}
				}
			}
		}
	}
	else if (this.getCommandID("swap tool") == cmd)
	{
		u16 netID = params.read_u16();
		string tool = params.read_string();
		CPlayer@ player = this.getPlayer();
		
		if (player is null) return;
		
		if (tool == "deconstructor" || tool == "reconstructor")
		{
			this.getSprite().SetEmitSound("/ReclaimSound.ogg");
			this.getSprite().SetEmitSoundVolume(0.5f);
			this.getSprite().SetEmitSoundPaused(true);
		}
		
		this.set_string("current tool", tool);
	}
}

void onAttached(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	this.ClearMenus();
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint)
{
	this.set_u16("shipID", detached.getNetworkID());
	this.set_s8("stay count", 3);
}

void onDie(CBlob@ this)
{
	if (isClient() && !this.hasTag("no_gib"))
	{
		CSprite@ sprite = this.getSprite();
		Vec2f pos = this.getPosition();
		
		ParticleBloodSplat(pos, true);
		directionalSoundPlay("BodyGibFall", pos);
		
		if (!sprite.getVars().gibbed) 
		{
			directionalSoundPlay("SR_ManDeath" + (XORRandom(4) + 1), pos, 0.75f);
			sprite.Gib();
		}
	}
	
	//return held blocks
	CRules@ rules = getRules();
	CBlob@[]@ blocks;
	if (this.get("blocks", @blocks) && blocks.size() > 0)                 
	{
		if (isServer())
		{
			CPlayer@ player = this.getPlayer();
			if (player !is null)
			{
				string pName = player.getUsername();
				u16 returnBooty = 0;
				for (uint i = 0; i < blocks.length; ++i)
				{
					CBlob@ block = blocks[i];
					if (!block.hasTag("coupling") && block.getShape().getVars().customData == -1 )
						returnBooty += block.get_u16("cost");
				}
				
				if (returnBooty > 0 && !(getPlayersCount() == 1 || rules.get_bool("freebuild")))
					server_addPlayerBooty(pName, returnBooty);
			}
		}
		Human::clearHeldBlocks(this);
		this.set_bool("blockPlacementWarn", false);
	}

	SetScreenFlash(0, 0, 0, 0, 0.0f);
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	//when enemy is killed: reward this player if hitBlob was on their mothership
	if (hitBlob.getName() == "human" && hitBlob !is this && hitBlob.getHealth() <= 0)
	{
		Island@ pIsle = getIsland(hitBlob);
		CPlayer@ thisPlayer = this.getPlayer();
		u8 teamNum = this.getTeamNum();
		if (thisPlayer !is null && pIsle !is null &&
			pIsle.isMothership && //enemy was on a mothership
			pIsle.centerBlock !is null && pIsle.centerBlock.getTeamNum() == teamNum) //enemy was on our mothership
		{
			if (thisPlayer.isMyPlayer())
				Sound::Play("snes_coin.ogg");

			if (isServer())
			{
				string defenderName = thisPlayer.getUsername();
				u16 reward = 50;
				if (getRules().get_bool("whirlpool")) reward *= 3;
				
				server_addPlayerBooty(defenderName, reward);
				server_updateTotalBooty(teamNum, reward);
			}
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return (this.getTeamNum() != blob.getTeamNum() || 
			(blob.hasTag("solid") && blob.getShape().getVars().customData > 0) || 
			(blob.getShape().isStatic() && !blob.getShape().getConsts().platform));
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData != Hitters::muscles) directionalSoundPlay("ImpactFlesh", worldPoint);
	ParticleBloodSplat(worldPoint, false);
	
	if (this.getTickSinceCreated() > 60) //invincible for a few seconds after spawning
		return damage;
	else
		return 0.0f;
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	if (this.getHealth() > oldHealth)
	{
		if (isClient())
		{
			directionalSoundPlay("Heal.ogg", this.getPosition(), 2.0f);
			
			makeHealParticle(this);
		}
	}
}
