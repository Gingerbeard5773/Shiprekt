//shiprekt HUD
#include "ActorHUDStartPos.as"
#include "IslandsCommon.as"

const int slotsSize = 8;
const SColor tipsColor = SColor(255, 255, 255, 255);
const f32 MSHIP_DAMAGE_ALERT = 3.0f;

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
	this.getBlob().set_u8("gui_HUD_slots_width", slotsSize);
}

void onTick(CSprite@ this)
{
	if (g_videorecording)
		return;

    CBlob@ blob = this.getBlob();
	if (blob is null) return;
	Vec2f tl = getActorHUDStartPosition(blob, slotsSize);	
	CPlayer@ player = blob.getPlayer();  
	if (player is null) return;
	CRules@ rules = getRules();
	string name = player.getUsername();
	u16 pBooty = rules.get_u16("booty" + name);
	CControls@ controls = getControls();
	
	// seat relinquish
	if ((controls.getMouseScreenPos() - tl - Vec2f(100, 20)).Length() < 15.0f)
	{
		if (controls.isKeyJustPressed(KEY_LBUTTON) && !blob.isAttached())
		{
			u16 seatID = 0;
			CBlob@[] blobs;
			getMap().getBlobsInRadius(blob.getPosition(), 8.0f, @blobs);
			for (int i = 0; i < blobs.length(); i++)
				if (blobs[i].hasTag("control") && blobs[i].get_string("playerOwner") == name)
				{
					seatID = blobs[i].getNetworkID();
					break;
				}
			
			if (seatID > 0)
			{
				CBitStream params;
				params.write_u16(seatID);
				blob.SendCommand( blob.getCommandID("releaseOwnership"), params);
				Sound::Play("LoadingTick2.ogg");
			}
		}
	}
	
	// transfer booty
	if ((controls.getMouseScreenPos() - tl - Vec2f(146, 20)).Length() < 15.0f)
	{
		CRules@ rules = getRules();
		u16 BOOTY_TRANSFER = rules.get_u16("booty_transfer");
		f32 BOOTY_TRANSFER_FEE = rules.get_f32( "booty_transfer_fee");//% of transfer
		u16 fee = Maths::Round(BOOTY_TRANSFER * BOOTY_TRANSFER_FEE);
		if (getGameTime() > rules.get_u16("warmup_time"))
		{
			if (pBooty >= BOOTY_TRANSFER + fee)
			{
				if (controls.isKeyJustPressed(KEY_LBUTTON))
				{
					blob.SendCommand(blob.getCommandID("giveBooty"));
					Sound::Play("LoadingTick2.ogg");
				}
			}
		}
	}
}

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

    CBlob@ blob = this.getBlob();
	if (blob is null) return;
	CPlayer@ player = blob.getPlayer();  
	if (player is null) return;
	
	CRules@ rules = getRules();
	Vec2f tl = getActorHUDStartPosition(blob, slotsSize);								
	u8 teamNum = player.getTeamNum();
	string name = player.getUsername();
	string captainName = getCaptainName(teamNum);
	bool isCaptain = name == captainName;
	u16 pBooty = rules.get_u16("booty" + name);
	CBlob@ teamCore = getMothership(teamNum);
	CControls@ controls = getControls();
	f32 screenHeight = getScreenHeight();
	f32 screenWidth = getScreenWidth();
	u32 gameTime = getGameTime();
	
	//			Draw HUD Icons and Status text
	DrawShipStatus(blob, name, tl, controls);
	DrawCoreStatus(teamCore, tl, controls);
	DrawStationStatus(teamCore, tl, controls);
	DrawMiniStationStatus(teamCore, tl, controls);
	DrawResources(blob, pBooty, isCaptain, tl, controls);
	
	//			Gameplay Tips
	//Seat produce couplings help
	if (blob.isAttached() && blob.get_bool("drawCouplingsHelp"))
		GUI::DrawText("Couplings ready. Press the Inventory key to take.",  tl + Vec2f(240, 20), tipsColor);
	
	//Can't place blocks on mothership
	if (blob.get_bool("blockPlacementWarn"))
		GUI::DrawText("You can only place Couplings and Repulsors directly on the Mothership during warm-up\n"
					+ "press [F] to get a refund on your blocks", controls.getMouseScreenPos() + Vec2f(-200, -40), tipsColor);
	
	//Seat couplings help
	if (blob.isAttached() && blob.get_bool("drawSeatHelp"))
	{
		GUI::DrawText("PRESS AND HOLD SPACEBAR TO RELEASE COUPLINGS", Vec2f(screenWidth/2 - 150, screenHeight/3 + Maths::Sin(gameTime/4.5f) * 4.5f), tipsColor);
		GUI::DrawText("Use left click to release them individually or right click to release all the couplings you've placed", Vec2f(screenWidth/2 - 300, screenHeight/3 + 15 + Maths::Sin(gameTime/4.5f ) * 4.5f ), tipsColor );
	}

	//Reclaiming other property is slower
	if (blob.get_bool("reclaimPropertyWarn"))
	{
		GUI::DrawText("You are reclaiming someone else's property. Progress will be slower.", Vec2f(screenWidth/2 - 340, screenHeight/2 + 310 + Maths::Sin(gameTime/4.5f) * 4.5f), tipsColor);
	}	
	
	//warm-up/freebuild
	if (getPlayersCount() == 1)
		GUI::DrawText("Free Building Mode - Waiting for players to join.", Vec2f(screenWidth/2 - 240, 15), tipsColor);
	else if (rules.get_bool("freebuild"))
		GUI::DrawText("Free Building Mode", Vec2f(screenWidth/2 - 75, 15), tipsColor);
	else
	{
		int WARMUP_TIME = rules.get_u16("warmup_time") - gameTime;
		if (WARMUP_TIME > 0)
		{
			u8 seconds = Maths::Round(WARMUP_TIME/30 % 60);
			string warmupText = "Warm-UP time " + Maths::Round(WARMUP_TIME/30/60) + ":" + (seconds > 9 ? "" : "0") + seconds;
			GUI::DrawText(warmupText, Vec2f(screenWidth/2 - 75, 15), tipsColor);
		}
	}
	
	if (rules.get_bool("display_flak_team_max"))
		GUI::DrawText("Sorry but you reached the limit of flaks allowed for a team", Vec2f(screenWidth/2 - 205, 40), tipsColor);
	if (rules.get_bool("display_flak_total_max"))
		GUI::DrawText("Sorry but the limit of active flaks on the server is reached. Try destroying some of them first",  Vec2f(screenWidth/2 - 320, 60), tipsColor);
	
	//mothership alerts
	if (teamCore !is null)
	{
		bool mShipNear = blob.getDistanceTo(teamCore) < 900.0f;
		bool mShipOnScreen = teamCore.isOnScreen();
		f32 mShipDMG = rules.get_f32("msDMG" + teamNum);
		
		if (name == captainName && !mShipOnScreen)//is Captain and abandoned mothership?
			GUI::DrawText("> You are your Team's Captain <\n\nDon't abandon the Mothership!", Vec2f(screenWidth/2 - 100, screenHeight/3 + Maths::Sin(gameTime/4.5f) * 4.5f), SColor(255, 235, 35, 35));
		else//mothership under attack alert
		{
			if (mShipNear || mShipDMG < MSHIP_DAMAGE_ALERT - 1.0f)
				blob.set_bool("msAlert", false);
			else if (!mShipNear && mShipDMG > MSHIP_DAMAGE_ALERT)
				blob.set_bool("msAlert", true);
				
			if (blob.get_bool("msAlert"))
				GUI::DrawText("YOUR MOTHERSHIP IS UNDER ATTACK!!", Vec2f(screenWidth/2 - 135, screenHeight/3 + Maths::Sin(gameTime/4.5f) * 4.5f), tipsColor);
		}
		
		//poor and no captain: sharks for income
		if (mShipOnScreen && captainName == "" && pBooty < rules.get_u16("bootyRefillLimit") && mShipDMG == 0)
			GUI::DrawText("[ Kill Sharks to gain some Booty ]", Vec2f(220, 60 + Maths::Sin(gameTime/4.5f) * 4.5f), tipsColor);
	}		
}

void DrawShipStatus(CBlob@ this, string name, Vec2f tl, CControls@ controls)
{
	Island@ island = getIsland(this);	
	if (island !is null)
	{
		CPlayer@ islandOwner = getPlayerByUsername(island.owner);
		
		//Owner name text (top left)
		if (island.owner != "" && island.owner != "*")
		{
			string lastChar = island.owner.substr( island.owner.length() -1);
			string ownership = island.owner + (lastChar == "s" ? "'" : "'s") + " ship";
			Vec2f size;
			GUI::GetTextDimensions(ownership, size);
			GUI::DrawText(ownership, Vec2f(Maths::Max(4.0f, 69.0f - size.x/2.0f), 3.0f), SColor(255, 255, 255, 255));
		}
		
		//icon
		if (islandOwner is null || (islandOwner !is null && islandOwner.getTeamNum() == this.getTeamNum()))
		{
			if (name == island.owner || island.owner == "*")
				GUI::DrawIconByName("$CAPTAIN$", tl + Vec2f(67, -12));
			else if (island.owner != "")
				GUI::DrawIconByName("$CREW$", tl + Vec2f(67, -11));
			else
				GUI::DrawIconByName("$FREEMAN$", tl + Vec2f(67, -12));
		}
		else
			GUI::DrawIconByName("$ASSAIL$", tl + Vec2f(67, -11));		
		
		//Speed
		u16 speed = island.vel.Length() * 30;
		GUI::DrawText("Speed : " + speed + " kilorekts/h", Vec2f(24, getScreenHeight() - 24), tipsColor);
	}
	else	
		GUI::DrawIconByName("$SEA$", tl + Vec2f(67, -12));
		
	//GUI buttons text/function
	if ((controls.getMouseScreenPos() - tl - Vec2f(100, 20) ).Length() < 15.0f)
	{
		GUI::DrawText("Click to relinquish ownership of a nearby seat", tl + Vec2f(-25, -25), tipsColor);
	}
}

void DrawCoreStatus( CBlob@ core, Vec2f tl, CControls@ controls )
{
	if (core is null) return;
	
    GUI::DrawIcon("InteractionIconsBig.png", 30, Vec2f(32,32), tl + Vec2f( -12, -12), 1.0f, core.getTeamNum());

	u8 health = Maths::Min(100, Maths::Round(core.getHealth()/8.0f * 100));
	
	SColor col;
	if (health <= 10)
		col = SColor(255, 255, 0, 0);
	else if (health < 50)
		col = SColor(255, 255, 255, 0);
	else
		col = SColor(255, 255, 255, 255);

	GUI::DrawText( health + "%", tl + Vec2f(37, 11), col );
	
	//GUI buttons text/function
	if ((controls.getMouseScreenPos() - (tl + Vec2f(17, 20))).Length() < 15.0f)
		GUI::DrawText( "Team Core Health",  tl + Vec2f(-45, -25), tipsColor);
}

void DrawStationStatus(CBlob@ station, Vec2f tl, CControls@ controls)
{
	if (station is null) return;
	
    GUI::DrawIcon("Station.png", 0, Vec2f(16,16), tl + Vec2f(210, 4), 1.0f, station.getTeamNum());

	u8 health = Maths::Min( 100, Maths::Round(station.getHealth()/8.0f * 100));
	
	SColor col;
	if (health <= 10)
		col = SColor(255, 255, 0, 0);
	else if (health < 50)
		col = SColor(255, 255, 255, 0);
	else
		col = SColor(255, 255, 255, 255);
		
	CBlob@[] stations;
	getBlobsByTag("station", @stations);
	
	u16 totalStationCount = stations.length;
	u16 teamStationCount = 0;
	for (u8 u = 0; u < stations.length; u++)
	{
		CBlob@ station = stations[u];
		if (station is null )
			continue;
	
		if (stations[u].getTeamNum() == getLocalPlayer().getTeamNum())
			teamStationCount++;
	}

	GUI::DrawText(teamStationCount + "/" + totalStationCount + " (+"+teamStationCount*4+")", tl + Vec2f(246, 6), col);
	
	//GUI buttons text/function
	if ((controls.getMouseScreenPos() - (tl + Vec2f(-98, 20))).Length() < 15.0f)
		GUI::DrawText("Captured Bases",  tl + Vec2f(-156, -25), tipsColor);
}

void DrawMiniStationStatus(CBlob@ ministation, Vec2f tl, CControls@ controls)
{
	if (ministation is null) return;

	u8 health = Maths::Min(100, Maths::Round(ministation.getHealth()/8.0f * 100));
	
	SColor col;
	if (health <= 10)
		col = SColor(255, 255, 0, 0);
	else if (health < 50)
		col = SColor(255, 255, 255, 0);
	else
		col = SColor(255, 255, 255, 255);
		
	CBlob@[] ministations;
	getBlobsByTag("ministation", @ministations);
	
	u16 totalMiniStationCount = ministations.length;
	u16 teamMiniStationCount = 0;
	for (u8 u = 0; u < ministations.length; u++)
	{
		CBlob@ ministation = ministations[u];
		if (ministation is null)
			continue;
	
		if (ministations[u].getTeamNum() == getLocalPlayer().getTeamNum())
			teamMiniStationCount++;
	}

	GUI::DrawText( teamMiniStationCount + "/" + totalMiniStationCount + " (+"+teamMiniStationCount+")", tl + Vec2f(246, 18), col);
	
	//GUI buttons text/function
	if ((controls.getMouseScreenPos() - (tl + Vec2f(-98, 20))).Length() < 15.0f)
		GUI::DrawText("Captured Mini Bases", tl + Vec2f(-156, -25), tipsColor);
}

void DrawResources(CBlob@ this, u16 pBooty, bool isCaptain, Vec2f tl, CControls@ controls)
{
	GUI::DrawIconByName("$BOOTY$", tl + Vec2f(111, -12));

	SColor col;
	if (pBooty < 10)
		col = SColor(255, 255, 0, 0);
	else if (pBooty <= 100)
		col = SColor(255, 255, 255, 0);
	else
		col = SColor(255, 255, 255, 255);
		
	GUI::DrawText("" + pBooty, tl + Vec2f(158 , 11), col);
	//GUI buttons text/function
	if ((controls.getMouseScreenPos() - tl - Vec2f(146, 20)).Length() < 15.0f)
	{
		CRules@ rules = getRules();
		u16 BOOTY_TRANSFER = rules.get_u16( "booty_transfer");
		f32 BOOTY_TRANSFER_FEE = rules.get_f32("booty_transfer_fee");//% of transfer
		u16 fee = Maths::Round(BOOTY_TRANSFER * BOOTY_TRANSFER_FEE);
		if (getGameTime() > rules.get_u16("warmup_time"))
		{
			if (pBooty >= BOOTY_TRANSFER + fee)
			{
				string feeString = fee > 0 ? (" for " + (BOOTY_TRANSFER + fee) + " Booty") : "";
				if (!isCaptain)
					GUI::DrawText("Click to transfer " + BOOTY_TRANSFER + " Booty to your Captain" + feeString, tl + Vec2f(35, -25), tipsColor);
				else
					GUI::DrawText("Click to transfer " + BOOTY_TRANSFER + " Booty among your Mothership Crew" + feeString, tl + Vec2f(35, -25), tipsColor);
			}
			else
				GUI::DrawText("Click to transfer Booty (" + (BOOTY_TRANSFER + fee) + " Booty minimum)", tl + Vec2f(35, -25), tipsColor);
		}
		else
			GUI::DrawText("Click to transfer Booty (enabled after warm-up)", tl + Vec2f(35, -25), tipsColor);
	}
}
