#include "HumanCommon.as";
#include "WaterEffects.as";
#include "ShipsCommon.as";
#include "Booty.as";
#include "AccurateSoundPlay.as";
#include "TileCommon.as";
#include "Hitters.as";
#include "ParticleSparks.as";
#include "ParticleHeal.as";
#include "BlockCosts.as";
#include "ShiprektTranslation.as";

const int CONSTRUCT_VALUE = 5;
const int CONSTRUCT_RANGE = 48;
const f32 MOTHERSHIP_HEAL = 0.1f;
const f32 BULLET_SPREAD = 0.2f;
const f32 BULLET_SPEED = 9.0f;
const f32 BULLET_RANGE = 350.0f;
const Vec2f BUILD_MENU_SIZE = Vec2f(6, 4);
const Vec2f BUILD_MENU_TEST = Vec2f(6, 4); //for testing, only activates when sv_test is on
const Vec2f TOOLS_MENU_SIZE = Vec2f(2, 6);

//global is fine since only used with isMyPlayer
int useClickTime = 0;
bool buildMenuOpen = false;
Random _shotspreadrandom(0x11598);

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
	this.addCommandID("run over");
	
	this.chatBubbleOffset = Vec2f(0.0f, 10.0f);
	
	this.SetMapEdgeFlags(u8(CBlob::map_collide_up) |
		u8(CBlob::map_collide_down) |
		u8(CBlob::map_collide_sides));
	
	this.set_bool("justMenuClicked", false);
	this.set_bool("getting block", false);
	this.set_bool("onGround", true); //client to server isOnGround()
	this.set_string("last buy", "coupling");
	this.set_string("current tool", "pistol");
	this.set_u32("fire time", 0);
	this.set_u32("punch time", 0);
	this.set_f32("camera rotation", 0);
	
	if (this.isMyPlayer())
	{	
		CBlob@ core = getMothership(this.getTeamNum());
		if (core !is null) 
		{
			this.setPosition(core.getPosition());
			this.set_u16("shipID", core.getNetworkID());
			this.set_s8("stay count", 3);
		}
	}
	
	this.getShape().getVars().onground = true;
	directionalSoundPlay("Respawn", this.getPosition(), 2.5f);
}

void onTick(CBlob@ this)
{
	Move(this);

	if (this.isMyPlayer())
	{
		PlayerControls(this);
	}

	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ laser = sprite.getSpriteLayer("laser");
	
	// stop reclaim effects
	if (this.isKeyJustReleased(key_action2) || (!this.isKeyPressed(key_action2) && laser !is null ? laser.isVisible() : false) || this.isAttached())
	{
		this.set_bool("reclaimPropertyWarn", false);
		if (isClient())
		{
			if (!sprite.getEmitSoundPaused())
			{
				sprite.SetEmitSoundPaused(true);
			}
			sprite.RemoveSpriteLayer("laser");
		}
	}
}

void Move(CBlob@ this)
{
	const bool blobInitialized = this.getTickSinceCreated() > 30; //solves some strange problems, 1 full second
	const bool myPlayer = this.isMyPlayer();
	const bool isBot = isServer() && this.getPlayer() !is null && this.getPlayer().isBot();
	Vec2f pos = this.getPosition();	
	Vec2f aimpos = this.getAimPos();
	Vec2f forward = aimpos - pos;
	CShape@ shape = this.getShape();
	CSprite@ sprite = this.getSprite();
	
	if (!this.isAttached())
	{
		if (myPlayer && blobInitialized)
		{
			const f32 camRotation = getCamera().getRotation();
			if (this.get_f32("camera rotation") != camRotation && this.exists("camera rotation"))
			{
				this.set_f32("camera rotation", camRotation);
				this.Sync("camera rotation", false); //1732223106 !! has a history of causing bad deltas !!
			}
		}
		
		const f32 camRotation = myPlayer ? getCamera().getRotation() : this.get_f32("camera rotation");
		
		const bool up = this.isKeyPressed(key_up);
		const bool down = this.isKeyPressed(key_down);
		const bool left = this.isKeyPressed(key_left);
		const bool right = this.isKeyPressed(key_right);	
		const bool punch = this.isKeyPressed(key_action1);
		const bool shoot = this.isKeyPressed(key_action2);
		Ship@ ship = getShip(this);
		shape.getVars().onground = ship !is null || isTouchingLand(pos);
		
		if (myPlayer || isBot)
		{
			if (this.get_bool("onGround") != this.isOnGround() && blobInitialized)
			{
				this.set_bool("onGround", this.isOnGround());
				this.Sync("onGround", false); //1954602763
			}
		}

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

		if (!this.get_bool("onGround"))
		{
			if (isTouchingShoal(pos))
			{
				moveVel *= 0.8f;
			}
			else
			{
				moveVel *= Human::swimSlow;
			}

			if (isClient())
			{
				const u32 gameTime = getGameTime();
				u8 tickStep = v_fastrender ? 15 : 5;

				if ((gameTime + this.getNetworkID()) % tickStep == 0)
					MakeWaterParticle(pos, Vec2f()); 

				if (this.wasOnGround() && gameTime - this.get_u32("lastSplash") > 45)
				{
					directionalSoundPlay("SplashFast", pos);
					this.set_u32("lastSplash", gameTime);
				}
			}
		}
		else
		{		
			// punch
			if (punch && !Human::isHoldingBlocks(this) && canPunch(this))
			{
				Punch(this);
			}
			
			//when on our mothership
			if (ship !is null && ship.isMothership && ship.centerBlock !is null)
			{
				CBlob@ thisCore = getMothership(this.getTeamNum());
				if (thisCore !is null && thisCore.getShape().getVars().customData == ship.centerBlock.getShape().getVars().customData)
				{
					moveVel *= 1.35f; //speedup on own mothership
					
					if (isServer() && getGameTime() % 60 == 0) //heal on own mothership
					{
						this.server_Heal(MOTHERSHIP_HEAL);
					}
				}
			}
		}
		
		//tool actions
		if (shoot && !punch)
		{
			string currentTool = this.get_string("current tool");
			
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
		if (this.get_bool("onGround") || !getRules().get_bool("whirlpool"))
		{
			moveVel.RotateBy(camRotation);
			this.setVelocity(moveVel);
		}

		// face

		f32 angle = camRotation;
		forward.Normalize();
		
		if (!sprite.isAnimation("walk") && !sprite.isAnimation("swim"))
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
		if (myPlayer || isBot)
		{
			CBlob@ shipBlob = getShipBlob(this);
			if (shipBlob !is null)
			{
				this.set_u16("shipID", shipBlob.getNetworkID());	
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
					else if (!shipBlob.hasTag("solid") && ((!up && !left && !right && !down) || !blobInitialized))
					{
						Ship@ blobship = getShip(shipBlob.getShape().getVars().customData);
						if (blobship !is null && blobship.vel.Length() > 1.0f)
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
	    }
	    else if (this.isKeyJustReleased(key_use))
	    {
	    	bool tapped = (getGameTime() - useClickTime) < 10; 
			this.ClickClosestInteractButton(tapped ? this.getPosition() : this.getAimPos(), this.getRadius()*2);
	        this.ClearButtons();
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
	if (hud.hasButtons() && this.isKeyPressed(key_action1) && !this.ClickClosestInteractButton(this.getAimPos(), 2.0f)) {}

	// click grid menus
    if (hud.hasButtons())
    {
        if (this.isKeyJustPressed(key_action1))
        {
		    CGridMenu@ gmenu;
		    CGridButton@ gbutton;
		    this.ClickGridMenu(0, gmenu, gbutton); 
	    }
	}
	
	//build menu
	if (this.isKeyJustPressed(key_inventory))
	{
		CBlob@ core = getMothership(this.getTeamNum());
		if (core !is null && !core.hasTag("critical"))
		{
			Ship@ pShip = getShip(this);
			bool canShop = pShip !is null && pShip.centerBlock !is null 
							&& ((pShip.centerBlock.getShape().getVars().customData == core.getShape().getVars().customData) 
							|| ((pShip.isStation || pShip.isSecondaryCore) && pShip.centerBlock.getTeamNum() == this.getTeamNum()));

			if (!Human::isHoldingBlocks(this) && !this.isAttached())
			{
				if (!hud.hasButtons())
				{
					if (this.get_bool("getting block"))
					{
						this.set_bool("getting block", false);
						this.Sync("getting block", false);
						this.getSprite().PlaySound("join");
					}
					else if (canShop)
					{
						buildMenuOpen = true;
						this.set_bool("justMenuClicked", true);

						Sound::Play("buttonclick.ogg");
						BuildShopMenu(this, core, Trans::Components, Vec2f(0,0), (pShip.isStation || pShip.isSecondaryCore) && !pShip.isMothership);
					}
				} 
				else if (hud.hasMenus())
				{
					this.ClearMenus();
					Sound::Play("buttonclick.ogg");
					
					if (buildMenuOpen)
					{
						CBitStream params;
						params.write_netid(this.getNetworkID());
						params.write_string(this.get_string("last buy"));
						params.write_u16(getCost(this.get_string("last buy")));
						params.write_bool(false);
						core.SendCommand(core.getCommandID("buyBlock"), params);
					}
					
					buildMenuOpen = false;
					this.set_bool("justMenuClicked", false);
				}
			}
			else if (Human::isHoldingBlocks(this))
			{
				CBitStream params;
				params.write_netid(this.getNetworkID());
				core.SendCommand(core.getCommandID("returnBlocks"), params);
			}
		}
	}
	
	//required so block placing doesn't happen on same tick as block returning
	if (this.get_bool("getting block"))
	{
		CBlob@ core = getMothership(this.getTeamNum());
		if (core !is null && !core.hasTag("critical"))
		{
			CBitStream params;
			params.write_netid(this.getNetworkID());
			params.write_string(this.get_string("last buy"));
			params.write_u16(getCost(this.get_string("last buy")));
			params.write_bool(true);
			core.SendCommand(core.getCommandID("buyBlock"), params);
		}
	}
	
	if (this.isKeyJustReleased(key_action1))
	{
		this.set_bool("justMenuClicked", false);
	}

	//tools menu
	if (toolsKey && !this.isAttached())
	{
		if (!hud.hasButtons())
		{
			buildMenuOpen = false;
			
			Sound::Play("buttonclick.ogg");
			BuildToolsMenu(this, Trans::ToolsMenu, Vec2f(0,0));
			
		} 
		else if (hud.hasMenus())
		{
			this.ClearMenus();
			Sound::Play("buttonclick.ogg");
		}
	}
}

void BuildShopMenu(CBlob@ this, CBlob@ core, string desc, Vec2f offset, bool isStation = false)
{
	CGridMenu@ menu = CreateGridMenu(this.getScreenPos() + offset, core, sv_test ? BUILD_MENU_TEST : BUILD_MENU_SIZE, desc);
	if (menu !is null) 
	{
		const bool warmup = getRules().isWarmup();
		menu.deleteAfterClick = true;
		
		string description;
		{ //Seat
			description = Trans::SeatDesc;
			AddBlock(this, menu, "seat", "$SEAT$", Trans::Seat, description, core, 0.5f);
		}
		{ //Propeller
			description = Trans::EngineDesc;
			AddBlock(this, menu, "propeller", "$PROPELLER$", Trans::Engine, description, core, 1.0f);
		}
		{ //Ram Engine
			description = Trans::RamEngineDesc;
			AddBlock(this, menu, "ramengine", "$RAMENGINE$", Trans::RamEngine, description, core, 1.25f);
		}
		{ //Coupling
			description = Trans::CouplingDesc;
			AddBlock(this, menu, "coupling", "$COUPLING$", Trans::Coupling, description, core, 0.1f);
		}
		{ //Wooden Hull
			description = Trans::WoodHullDesc;
			AddBlock(this, menu, "solid", "$SOLID$", Trans::Hull, description, core, 0.75f);
		}
		{ //Wooden Platform
			description = Trans::PlatformDesc;
			AddBlock(this, menu, "platform", "$WOOD$", Trans::Platform, description, core, 0.2f);
		}
		{ //Wooden Door
			description = Trans::DoorDesc;
			AddBlock(this, menu, "door", "$DOOR$", Trans::Door, description, core, 1.0f);
		}
		{ //Wooden Plank
			description = "Acts as a one way exit. Collides with projectiles and blocks only on the front side.";
			AddBlock(this, menu, "plank", "$PLANK$", "Wooden Plank", description, core, 0.7f);
		}
		{ //Harpoon
			description = Trans::HarpoonDesc;
			AddBlock(this, menu, "harpoon", "$HARPOON$", Trans::Harpoon, description, core, 2.0f);
		}
		{ //Harvester
			description = Trans::HarvesterDesc;
			AddBlock(this, menu, "harvester", "$HARVESTER$", Trans::Harvester, description, core, 2.0f);
		}
		{ //Patcher
			description = Trans::PatcherDesc;
			AddBlock(this, menu, "patcher", "$PATCHER$", Trans::Patcher, description, core, 3.0f);
		}
		{ //Anti Ram Hull
			description = Trans::AntiRamDesc;
			AddBlock(this, menu, "antiram", "$ANTIRAM$", Trans::AntiRam, description, core, 0.75f);
		}
		{ //Repulsor
			description = Trans::RepulsorDesc;
			AddBlock(this, menu, "repulsor", "$REPULSOR$", Trans::Repulsor, description, core, 0.25f);
		}
		{ //Decoy Core
			description = Trans::DecoyCoreDesc;
			AddBlock(this, menu, "decoycore", "$DECOYCORE$", Trans::DecoyCore, description, core, 6.0f);
		}
		{ //Ram Hull
			description = Trans::RamDesc;
			AddBlock(this, menu, "ram", "$RAM$", Trans::Ram, description, core, 2.0f, warmup);
		}
		{ //Auxilliary Core
			description = Trans::AuxillDesc;
			CGridButton@ button = AddBlock(this, menu, "secondarycore", "$SECONDARYCORE$", Trans::Auxilliary, description, core, 12.0f);
			button.SetEnabled(!isStation && !warmup);
		}
		{ //Bomb
			description = Trans::BombDesc;
			AddBlock(this, menu, "bomb", "$BOMB$", Trans::Bomb, description, core, 2.0f, warmup);
		}
		{ //Point Defense
			description = Trans::PointDefDesc+"\n"+Trans::AmmoCap+": 30";
			AddBlock(this, menu, "pointdefense", "$POINTDEFENSE$", Trans::PointDefense, description, core, 3.5f, warmup);
		}
		{ //Flak
			description = Trans::FlakDesc+"\n"+Trans::AmmoCap+": 30";
			AddBlock(this, menu, "flak", "$FLAK$", Trans::FlakCannon, description, core, 2.5f, warmup);
		}
		{ //Machinegun
			description = Trans::MGDesc+"\n"+Trans::AmmoCap+": 250";
			AddBlock(this, menu, "machinegun", "$MACHINEGUN$", Trans::Machinegun, description, core, 2.0f, warmup);
		}
		{ //AP Cannon
			description = Trans::CannonDesc+"\n"+Trans::AmmoCap+": 12";
			AddBlock(this, menu, "cannon", "$CANNON$", Trans::Cannon, description, core, 3.25f, warmup);
		}
		{ //Missile Launcher
			description = Trans::LauncherDesc+"\n"+Trans::AmmoCap+": 8";
			AddBlock(this, menu, "launcher", "$LAUNCHER$", Trans::Launcher, description, core, 4.5f, warmup);
		}
	}
}

CGridButton@ AddBlock(CBlob@ this, CGridMenu@ menu, string block, string icon, string bname, string desc, CBlob@ core, f32 weight, bool isWeapon = false)
{
	//Add a block to the build menu
	u16 cost = getCost(block);
	
	CBitStream params;
	params.write_netid(this.getNetworkID());
	params.write_string(block);
	params.write_u16(cost);
	params.write_bool(false);
			
	CGridButton@ button = menu.AddButton(icon, bname + " $" + cost, core.getCommandID("buyBlock"), params);

	const bool selected = this.get_string("last buy") == block;
	if (selected) button.SetSelected(2);
			
	button.SetHoverText(isWeapon ? Trans::WarmupWarning+".\n" :
						desc + "\n"+ Trans::Weight+": " + weight * 100 + "rkt\n" + (selected ? "\n"+Trans::BuyAgain+"\n" : ""));
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
			description = Trans::PistolDesc;
			AddTool(this, menu, "$PISTOL$", Trans::Pistol, description, "pistol");
		}
		{ //Deconstructor
			description = Trans::DeconstDesc;
			AddTool(this, menu, "$DECONSTRUCTOR$", Trans::Deconstructor, description, "deconstructor");
		}
		{ //Reconstructor
			description = Trans::ReconstDesc;
			AddTool(this, menu, "$RECONSTRUCTOR$", Trans::Reconstructor, description, "reconstructor");
		}
	}
}

CGridButton@ AddTool(CBlob@ this, CGridMenu@ menu, string icon, string toolName, string desc, string currentTool)
{
	//Add a tool to the tools menu
	CBitStream params;
	params.write_string(currentTool);
	
	CGridButton@ button = menu.AddButton(icon, toolName, this.getCommandID("swap tool"), params);
			
	if (this.get_string("current tool") == currentTool)
		button.SetSelected(2);
			
	button.SetHoverText(desc);
	return button;
}

void Punch(CBlob@ this)
{
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();
	Vec2f aimVector = this.getAimPos() - pos;
	
    HitInfo@[] hitInfos;
	if (this.isMyPlayer() && map.getHitInfosFromArc(pos, -aimVector.Angle(), 120.0f, 10.0f, this, @hitInfos))
	{
		const int hitLength = hitInfos.length;
		for (uint i = 0; i < hitLength; i++)
		{
			CBlob@ b = hitInfos[i].blob;
			if (b is null) continue;
			//dirty fix: get occupier if seat
			if (b.hasTag("hasSeat"))
			{
				AttachmentPoint@ seat = b.getAttachmentPoint(0);
				@b = seat.getOccupied();
			}
			if (b !is null && b.getName() == "human" && b.getTeamNum() != this.getTeamNum())
			{
				//check to make sure we aren't hitting through blocks
				bool hitBlock = false;
				Vec2f dir = b.getPosition() - this.getPosition();
				HitInfo@[] rayInfos;
				if (map.getHitInfosFromRay(this.getPosition(), -dir.Angle(), dir.Length(), this, @rayInfos))
				{
					const int rayLength = rayInfos.length;
					for (uint q = 0; q < rayLength; q++)
					{
						CBlob@ block = rayInfos[q].blob;
						if (block !is null && block.hasTag("solid"))
						{
							hitBlock = true;
							break;
						}
					}
				}
				
				if (!hitBlock)
				{
					CBitStream params;
					params.write_netid(b.getNetworkID());
					this.SendCommand(this.getCommandID("punch"), params);
					return;
				}
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
	aimVector.Normalize();

	Vec2f offset(_shotspreadrandom.NextFloat() * BULLET_SPREAD,0);
	offset.RotateBy(_shotspreadrandom.NextFloat() * 360.0f, Vec2f());
	
	Vec2f vel = (aimVector * BULLET_SPEED) + offset;

	f32 lifetime = Maths::Min(0.05f + BULLET_RANGE/BULLET_SPEED/32.0f, 1.35f);

	CBitStream params;
	params.write_Vec2f(vel);
	params.write_f32(lifetime);

	Ship@ ship = getShip(this);
	if (ship !is null && ship.centerBlock !is null)//relative positioning
	{
		params.write_bool(true);
		Vec2f rPos = (pos + aimVector*3) - ship.centerBlock.getPosition();
		params.write_Vec2f(rPos);
		u32 shipColor = ship.centerBlock.getShape().getVars().customData;
		params.write_u32(shipColor);
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
	Vec2f aimVector = aimPos - pos;

	CSprite@ sprite = this.getSprite();

	CBlob@ mBlob = getMap().getBlobAtPosition(aimPos);
	if (mBlob !is null && mBlob.getShape().getVars().customData > 0 && aimVector.getLength() <= CONSTRUCT_RANGE && !mBlob.hasTag("station"))
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
			
			if (sprite.getEmitSoundPaused())
			{
				sprite.SetEmitSoundPaused(false);
			}
		}	
	}
	else
	{
		if (isClient())//effects
		{
			sprite.RemoveSpriteLayer("laser");
			
			if (!sprite.getEmitSoundPaused())
			{
				sprite.SetEmitSoundPaused(true);
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (isServer() && this.getCommandID("get out") == cmd)
	{
		this.server_DetachFromAll();
	}
	else if (this.getCommandID("punch") == cmd && canPunch(this))
	{
		CBlob@ b = getBlobByNetworkID(params.read_netid());
		if (b !is null && b.getName() == this.getName() && b.getDistanceTo(this) < 100.0f)
		{
			Vec2f pos = b.getPosition();
			this.set_u32("punch time", getGameTime());
			if (isClient())
			{
				directionalSoundPlay("Kick.ogg", pos);
				ParticleBloodSplat(pos, false);
			}

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
			int shipColor = params.read_u32();
			Ship@ ship = getShip(shipColor);
			if (ship !is null && ship.centerBlock !is null)
			{
				pos = rPos + ship.centerBlock.getPosition();
				velocity += ship.vel;
			}
			else
			{
				warn("BulletSpawn: ship or centerBlock is null");
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
		if (isClient())
		{
			shotParticles(pos + Vec2f(0,0).RotateBy(-velocity.Angle())*6.0f, velocity.Angle(), true, 0.02f , 0.6f);
			directionalSoundPlay("Gunshot.ogg", pos, 0.75f);
		}
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
			Ship@ ship = getShip(mBlob.getShape().getVars().customData);
				
			const f32 mBlobCost = !mBlob.hasTag("coupling") ? getCost(mBlob.getName(), true) : 1;
			f32 mBlobHealth = mBlob.getHealth();
			f32 mBlobInitHealth = mBlob.getInitialHealth();
			f32 currentReclaim = mBlob.get_f32("current reclaim");
			
			f32 fullConstructAmount;
			if (mBlob.hasTag("mothership"))
				fullConstructAmount = (0.01f)*mBlobInitHealth;
			else if (mBlobCost > 0)
				fullConstructAmount = (CONSTRUCT_VALUE/mBlobCost)*mBlobInitHealth;
			else
				fullConstructAmount = 0.0f;
							
			if (ship !is null)
			{
				string shipOwner = ship.owner;
				
				if (currentTool == "deconstructor" && !mBlob.hasTag("mothership") && mBlobCost > 0)
				{
					f32 deconstructAmount = 0;
					if ((shipOwner == "" && !ship.isMothership) //no owner and is not a mothership
						|| (mBlob.get_string("playerOwner") == "" && (!ship.isMothership || mBlob.getTeamNum() == this.getTeamNum()))  //no one owns the block and is not a mothership
						|| shipOwner == thisPlayer.getUsername()  //we own the ship
						|| mBlob.get_string("playerOwner") == thisPlayer.getUsername()) //we own the block
					{
						if (mBlob.hasTag("weapon")) fullConstructAmount *= 3;
						deconstructAmount = fullConstructAmount; 
					}
					else
					{
						deconstructAmount = (1.0f/mBlobCost)*mBlobInitHealth; 
						this.set_bool("reclaimPropertyWarn", true);
					}
					
					if (ship.isStation && mBlob.getTeamNum() != this.getTeamNum())
					{
						deconstructAmount = (1.0f/mBlobCost)*mBlobInitHealth; 
						this.set_bool("reclaimPropertyWarn", true);					
					}
					
					if ((currentReclaim - deconstructAmount) <= 0)
					{
						server_addPlayerBooty(thisPlayer.getUsername(), (!mBlob.hasTag("coupling") ? getCost(mBlob.getName()) : 1) *(mBlobHealth/mBlobInitHealth));
						directionalSoundPlay("/ChaChing.ogg", pos);
						mBlob.Tag("disabled");
						mBlob.server_Die();
					}
					else
						mBlob.sub_f32("current reclaim", deconstructAmount);
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
						if ((mBlobHealth + reconstructAmount) <= mBlobInitHealth)
						{
							reconstructAmount = fullConstructAmount;
							reconstructCost = CONSTRUCT_VALUE;
						}
						else if ((mBlobHealth + reconstructAmount) > mBlobInitHealth)
						{
							reconstructAmount = mBlobInitHealth - mBlobHealth;
							reconstructCost = (CONSTRUCT_VALUE - CONSTRUCT_VALUE*(reconstructAmount/fullConstructAmount));
						}
						
						if (cBooty >= reconstructCost && mBlobHealth < mBlobInitHealth)
						{
							mBlob.server_SetHealth(mBlobHealth + reconstructAmount);
							server_addPlayerBooty(cName, -reconstructCost);
						}
					}
					else if (currentReclaim < mBlobInitHealth)
					{
						//blocks
						if ((currentReclaim + reconstructAmount) <= mBlobInitHealth)
						{
							reconstructAmount = fullConstructAmount;
							reconstructCost = CONSTRUCT_VALUE;
						}
						else if ((currentReclaim + reconstructAmount) > mBlobInitHealth)
						{
							reconstructAmount = mBlobInitHealth - currentReclaim;
							reconstructCost = CONSTRUCT_VALUE - CONSTRUCT_VALUE*(reconstructAmount/fullConstructAmount);
						}
						
						if ((currentReclaim + reconstructAmount > mBlobHealth) && cBooty >= reconstructCost)
						{
							mBlob.server_SetHealth(Maths::Clamp(mBlobHealth + reconstructAmount, 0.0f, mBlobInitHealth));
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
				
				CSprite@ sprite = this.getSprite();
				sprite.RemoveSpriteLayer("laser");
				
				string beamSpriteFilename = currentTool == "deconstructor" ? "ReclaimBeam" : "RepairBeam";
					
				CSpriteLayer@ laser = sprite.addSpriteLayer("laser", beamSpriteFilename + ".png", 32, 16);
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
		CBlob@ seat = getBlobByNetworkID(params.read_netid());
		
		if (player is null || seat is null) return;
		
		if (this.isAttached()) this.server_DetachFromAll();
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
		if (rules.isWarmup()) return;
			
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
				const int humansLength = humans.length;
				for (u8 i = 0; i < humansLength; i++)
				{
					if (humans[i].getTeamNum() == teamNum && humans[i] !is this)
					{
						CBlob@ shipBlob = getShipBlob(humans[i]);
						if (shipBlob !is null && shipBlob.getShape().getVars().customData == coreColor)
							crew.push_back(humans[i]);
					}
				}
				
				const int crewLength = crew.length;
				if (crewLength > 0)
				{
					print("$ " + pName + " transfers Booty to crew");
					server_addPlayerBooty(pName, -transfer - fee);
					u16 shareBooty = Maths::Floor(transfer/crewLength);
					for (u8 i = 0; i < crewLength; i++)
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
		const string tool = params.read_string();
		
		CPlayer@ player = this.getPlayer();
		if (player is null) return;
		
		if (tool == "deconstructor" || tool == "reconstructor")
		{
			if (isClient())
			{
				CSprite@ sprite = this.getSprite();
				sprite.SetEmitSound("/ReclaimSound.ogg");
				sprite.SetEmitSoundVolume(0.5f);
				sprite.SetEmitSoundPaused(true);
			}
		}
		
		this.set_string("current tool", tool);
	}
	else if (this.getCommandID("run over") == cmd)
	{
		CBlob@ block = getBlobByNetworkID(params.read_netid());
		if (block is null) return;
		
		Vec2f pos = this.getPosition();
		
		if (block !is this)
		{
			//death when run-over by a ship
			Ship@ ship = getShip(block.getShape().getVars().customData);
			if (ship !is null)
			{
				//set the damage owner so the ship's owner gets the kill
				CPlayer@ owner = getPlayerByUsername(ship.owner);
				if (owner !is null)
					block.SetDamageOwnerPlayer(owner);
			}
			
			if (isClient())
			{
				directionalSoundPlay("WoodHeavyHit2", pos, 1.2f); //oof
				if (XORRandom(5) == 0) directionalSoundPlay("Wilhelm", pos);
			}
			
			if (isServer())
				block.server_Hit(this, pos, Vec2f_zero, 5.0f, Hitters::muscles, false);
		}
		else
		{
			//death when standing over a destroyed block
			if (isClient())
				directionalSoundPlay("destroy_ladder", pos);
			if (isServer())
				this.server_Hit(this, pos, Vec2f_zero, 5.0f, Hitters::muscles, false);
		}
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	this.getShape().getVars().onground = true;
	this.set_u16("shipID", detached.getNetworkID());
	this.set_s8("stay count", 3);
}

void onDie(CBlob@ this)
{
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
					if (!block.hasTag("coupling") && block.getShape().getVars().customData == -1)
						returnBooty += getCost(block.getName());
				}
				
				if (returnBooty > 0 && !rules.get_bool("freebuild"))
					server_addPlayerBooty(pName, returnBooty);
			}
		}
		Human::clearHeldBlocks(this);
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return (this.getTeamNum() != blob.getTeamNum() || 
			(blob.hasTag("solid") && blob.getShape().getVars().customData > 0) || blob.getShape().isStatic());
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.getTickSinceCreated() < 60) //invincible for a few seconds after spawning
		return 0.0f;
		
	Vec2f pos = this.getPosition();
	
	//when this is killed: reward hitter player, done in onHit to reward from owned blobs
	if (hitterBlob !is null && this.getHealth() - damage <= 0)
	{
		CPlayer@ hitterPlayer = hitterBlob.getDamageOwnerPlayer();
		u8 teamNum = this.getTeamNum();
		u8 hitterTeam = hitterBlob.getTeamNum();
		if (hitterPlayer !is null && hitterTeam != teamNum)
		{
			u16 reward = 15;
			
			if (hitterPlayer.getBlob() !is null)
			{
				Ship@ pShip = getShip(hitterPlayer.getBlob());
				if (pShip !is null && pShip.isMothership && //this is on a mothership
					pShip.centerBlock !is null && pShip.centerBlock.getTeamNum() == teamNum) //hitter is on this mothership
				{
					if (hitterPlayer.isMyPlayer() && isClient())
						Sound::Play("snes_coin.ogg");
					
					//reward extra if hitter is on our mothership
					reward = 50;
				}
				else
				{
					if (hitterPlayer.isMyPlayer() && isClient())
						Sound::Play("coinpick.ogg");
				}
			}
			
			if (isServer())
			{
				if (getRules().get_bool("whirlpool")) reward *= 3;
				server_addPlayerBooty(hitterPlayer.getUsername(), reward);
				server_updateTotalBooty(hitterTeam, reward);
			}
		}
		
		if (isClient())
		{
			ParticleBloodSplat(pos, true);
			directionalSoundPlay("BodyGibFall", pos);
			directionalSoundPlay("SR_ManDeath" + (XORRandom(4) + 1), pos, 0.75f);
			
			this.getSprite().Gib();
		}
	}
	
	if (isClient())
	{
		if (customData != Hitters::muscles) directionalSoundPlay("ImpactFlesh", worldPoint);
		ParticleBloodSplat(worldPoint, false);
		
		if (damage > 1.45f) //sound for anything 2 heart+
			directionalSoundPlay("ArgLong", pos, 1.0f, this.getSexNum() == 0 ? 1.0f : 1.5f);
		else if (damage > 0.45f)
			directionalSoundPlay("ArgShort.ogg", pos, 1.0f, this.getSexNum() == 0 ? 1.0f : 1.5f);
	}
	
	return damage;
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
