#include "IslandsCommon.as"
#include "HumanCommon.as"
#include "BlockCommon.as"
#include "BlockProduction.as"
#include "PropellerForceCommon.as"

const u16 COUPLINGS_COOLDOWN = 8 * 30;
const u16 CREW_COUPLINGS_LEASE = 10 * 30;//time till the captain can control crew's couplings
const u16 UNUSED_RESET = 2 * 60 * 30;
const u8 CANNON_FIRE_CYCLE = 15;

void onInit( CBlob@ this )
{
	//Set Owner/couplingsCooldown
	if ( getNet().isServer() )
	{
		this.set( "couplingCooldown", 0 );
		
		CBlob@ owner = getBlobByNetworkID( this.get_u16( "ownerID" ) );    
		if ( owner !is null )
			server_setOwner( this, owner.getPlayer().getUsername() );
		else
			server_setOwner( this, "" );
			
		u16[] left_propellers, strafe_left_propellers, strafe_right_propellers, right_propellers, up_propellers, down_propellers, machineguns, cannons;					
		this.set( "left_propellers", left_propellers );
		this.set( "strafe_left_propellers", strafe_left_propellers );
		this.set( "strafe_right_propellers", strafe_right_propellers );
		this.set( "right_propellers", right_propellers );
		this.set( "up_propellers", up_propellers );
		this.set( "down_propellers", down_propellers );
		this.set( "machineguns", machineguns );
		this.set( "cannons", cannons );
		
		this.set_bool( "kUD", false );
		this.set_bool( "kLR", false );
		this.set_u32( "lastCannonFire", getGameTime() );
		this.set_u8( "cannonFireIndex", 0 );
		this.set_u32( "lastActive", getGameTime() );
		this.set_u32( "lastOwnerUpdate", 0 );
	}
	
	this.set_string("seat label", "Steering seat");
	this.set_bool( "canProduceCoupling", false );
	this.set_u8("seat icon", 7);
	this.Tag("seat");
	this.Tag("control");
	
	//anim
	CSprite@ sprite = this.getSprite();
    if(sprite !is null)
    {
        //default
        {
            Animation@ anim = sprite.addAnimation("default", 0, false);
            anim.AddFrame(Block::SEAT);
        }
        //folding
        {
            Animation@ anim = sprite.addAnimation("fold", 4, false);

            int[] frames = {Block::SEAT, Block::SEAT+1, Block::SEAT+2, Block::SEAT+3, Block::SEAT+4 };

            anim.AddFrames(frames);
        }
    }
}

void onTick( CBlob@ this )
{
	if (this.getShape().getVars().customData <= 0)
		return;	
	bool isServer = getNet().isServer();
	u32 gameTime = getGameTime();
	u8 teamNum =this.getTeamNum();
	string seatOwner = this.get_string( "playerOwner" );
	
	if ( isServer )
	{
		this.get( "playerOwner", seatOwner );
		//clear ownership on player leave/change team or seat not used
		CPlayer@ ownerPlayer = getPlayerByUsername( seatOwner );
		if ( ownerPlayer is null || ownerPlayer.getTeamNum() != teamNum || gameTime - this.get_u32( "lastActive" ) > UNUSED_RESET )
		{
			server_setOwner( this, "" );
			//print( "** Clearing ownership: " + seatOwner + ( ownerPlayer is null ? " left" : " changed team/not used" ) );
		}
		
		//fail-safe. force owner update
		if ( gameTime - this.get_u32( "lastOwnerUpdate" ) > 90 )
		{
			this.Sync( "playerOwner", true );
			this.set_u32( "lastOwnerUpdate", gameTime );
		}
	}
				
    this.getSprite().SetAnimation( seatOwner != "" ? "default": "fold" );//update sprite

	Island@ island = getIsland(this.getShape().getVars().customData);
	if ( island is null )	return;
	
	AttachmentPoint@ seat = this.getAttachmentPoint(0);
	CBlob@ occupier = seat.getOccupied();
	if ( occupier !is null )
	{
		int seatColor = this.getShape().getVars().customData;
		const f32 angle = this.getAngleDegrees();
		occupier.setAngleDegrees( angle );
				
		CPlayer@ player = occupier.getPlayer();
		if ( player is null )	return;

		CRules@ rules = getRules();
		CHUD@ HUD = getHUD();
		string occupierName = player.getUsername();
		u8 occupierTeam = occupier.getTeamNum();
		const bool isCaptain = island.owner == occupierName || island.owner == "*" || island.owner == "";
		const bool canHijack = seatOwner == island.owner && occupierTeam != teamNum;
			
		const bool up = occupier.isKeyPressed( key_up );
		const bool left = occupier.isKeyPressed( key_left );
		const bool right = occupier.isKeyPressed( key_right );
		const bool down = occupier.isKeyPressed( key_down );
		const bool space = occupier.isKeyPressed( key_action3 );	
		const bool inv = occupier.isKeyPressed( key_inventory );
		const bool strafe = occupier.isKeyPressed( key_pickup ) || occupier.isKeyPressed( key_taunts );
		const bool left_click = occupier.isKeyPressed( key_action1 );	
		const bool right_click = occupier.isKeyPressed( key_action2 );	

		//client-side couplings managing functions
		if ( player.isMyPlayer() )
		{
			//show help tip
			occupier.set_bool( "drawSeatHelp", island.owner != "" && occupierTeam == teamNum && !isCaptain && occupierName == seatOwner );
			
			//couplings help tip
			occupier.set_bool( "drawCouplingsHelp", this.get_bool( "canProduceCoupling" ) );

			//gather couplings and flak
			CBlob@[] couplings, flak;
			for (uint b_iter = 0; b_iter < island.blocks.length; ++b_iter)
			{
				IslandBlock@ isle_block = island.blocks[b_iter];
				if(isle_block is null) continue;

				CBlob@ block = getBlobByNetworkID( isle_block.blobID );
				if(block is null) continue;
				
				//gather couplings
				if (block.hasTag("coupling") && !block.hasTag("_coupling_hitspace"))
					couplings.push_back(block);
				else if ( block.hasTag( "flak" ) )
					flak.push_back(block);
			}
			
			
			//Show coupling/flak/repulsor buttons on spacebar down
			if ( occupier.isKeyJustPressed( key_action3 ) )
			{
				//couplings on ship
				for (uint i = 0; i < couplings.length; ++i)
				{
					CBlob@ c = couplings[i];
					bool isOwner = c.get_string( "playerOwner" ) == occupierName;
					if ( isCaptain )
					{
						CButton@ button;
						bool oldEnough = c.getTickSinceCreated() > CREW_COUPLINGS_LEASE || c.getTeamNum() != occupierTeam;
						if ( isOwner || oldEnough )
							@button = occupier.CreateGenericButton( isOwner ? 2 : 1, Vec2f_zero, c, c.getCommandID("decouple"), isOwner ? "Decouple" : "Decouple (crew's)" );
						else
							@button = occupier.CreateGenericButton( 0, Vec2f_zero, c, 0, "Can't decouple yet (crew's)" );
							
						if ( button !is null )	button.enableRadius = 999.0f;
					} 
					else if ( isOwner )
					{
						CButton@ button = occupier.CreateGenericButton( 2, Vec2f_zero, c, c.getCommandID("decouple"), "Decouple" );
						if ( button !is null )	button.enableRadius = 999.0f;
					}
				}
				
				//repulsors on screen
				CBlob@[] repulsors;	
				getBlobsByTag( "repulsor", @repulsors );
				for (uint b_iter = 0; b_iter < repulsors.length; ++b_iter)
				{
					CBlob@ r = repulsors[b_iter];
					int color = r.getShape().getVars().customData;
					if ( color > 0 && r.isOnScreen() && !r.hasTag("activated" ) && r.get_string( "playerOwner" ) == occupierName || ( isCaptain && seatColor == color ) )
					{
						CButton@ button = occupier.CreateGenericButton( 8, Vec2f_zero, r, r.getCommandID("chainReaction"), "Activate" );
						if ( button !is null )	button.enableRadius = 999.0f;
					}
				}
				
				//flak on ship: detach player
				if ( isCaptain )
					for (uint b_iter = 0; b_iter < flak.length; ++b_iter)
					{
						CBlob@ f = flak[b_iter];
						if ( f.hasAttached() )
						{
							CButton@ button = occupier.CreateGenericButton( 5, Vec2f_zero, f, f.getCommandID("clear attached"), "Push Crewmate Out" );
							if ( button !is null )	button.enableRadius = 999.0f;
						}
					}
			}
			
			//hax: update can't-decouplers
			if ( isCaptain && space )
			{
				for (uint i = 0; i < couplings.length; ++i)
				{
					CBlob@ c = couplings[i];
					if ( c.get_string( "playerOwner" ) != occupierName && c.getTickSinceCreated() == CREW_COUPLINGS_LEASE )
					{
						occupier.ClickClosestInteractButton( c.getPosition(), 0.0f );
						
						CButton@ button = occupier.CreateGenericButton( 1, Vec2f_zero, c, c.getCommandID("decouple"), "Decouple (crew's)" );
						if ( button !is null )	button.enableRadius = 999.0f;
					}
				}
			}

			//Kill coupling/turret buttons on spacebar up
			if ( occupier.isKeyJustReleased( key_action3 ) )
				occupier.ClearButtons();
		
			//Release all couplings on spacebar + right click
			if ( space && HUD.hasButtons() && right_click )
				for ( uint i = 0; i < couplings.length; ++i )
					if ( couplings[i].get_string( "playerOwner" ) == occupierName )
					{
						couplings[i].Tag("_coupling_hitspace");
						couplings[i].SendCommand(couplings[i].getCommandID("decouple"));
					}
				
		}
		
		//******svOnly below
		if ( !isServer )
			return;
	
		if ( occupierName == seatOwner )
			this.set_u32( "lastActive", gameTime );
		else
			this.set_u32( "lastActive", Maths::Max( 0, this.get_u32( "lastActive" ) - 3 ) );//resets 4x faster if enemy is using it
			
		if ( seatOwner == "" )//Re-set empty seat's owner to occupier
		{
			//print( "** Re-setting seat owner: " + occupierName );
			server_setOwner( this, occupierName );
		}	
		
		//Produce coupling
		u32 couplingCooldown;
		this.get( "couplingCooldown", couplingCooldown );
		bool canProduceCoupling = gameTime > couplingCooldown;
		this.set_bool( "canProduceCoupling", canProduceCoupling );
		this.Sync( "canProduceCoupling", true );
		
		if ( inv && canProduceCoupling && !Human::isHoldingBlocks(occupier) )
		{
			this.set( "couplingCooldown", gameTime + COUPLINGS_COOLDOWN );
			ProduceBlock( rules, occupier, Block::COUPLING, 2 );
		}
		
		//update if islands changed
		if ( this.get_bool( "updateArrays" ) && ( gameTime + this.getNetworkID() ) % 10 == 0 )
			updateArrays( this, island );
		
		if ( space && left_click )//so when a player undocks the ship stops
		{
			this.set_bool( "kUD", true );
			this.set_bool( "kLR", true );
		}
		
		//island controlling: only ship 'captain' OR enemy can steer /direct fire
		if ( isCaptain || canHijack )
		{
			// gather propellers, couplings, machineguns and cannons
			u16[] left_propellers, strafe_left_propellers, strafe_right_propellers, right_propellers, up_propellers, down_propellers, machineguns, cannons;					
			this.get( "left_propellers", left_propellers );
			this.get( "strafe_left_propellers", strafe_left_propellers );
			this.get( "strafe_right_propellers", strafe_right_propellers );
			this.get( "right_propellers", right_propellers );
			this.get( "up_propellers", up_propellers );
			this.get( "down_propellers", down_propellers );
			this.get( "machineguns", machineguns );
			this.get( "cannons", cannons );

			//propellers
			bool teamInsensitive = !island.isMothership || island.owner != "*";//it's a mini or mship isn't merged with another mship (every side controlls their props)
			
			//reset			
			if ( this.get_bool( "kUD" ) && !up && !down  )
			{
				this.set_bool( "kUD", false );
	
				for (uint i = 0; i < up_propellers.length; ++i)
				{
					CBlob@ prop = getBlobByNetworkID( up_propellers[i] );
					if ( prop !is null && seatColor == prop.getShape().getVars().customData && ( teamInsensitive || occupierTeam == prop.getTeamNum() ) )
						prop.set_f32("power", 0);
				}
				
				for (uint i = 0; i < down_propellers.length; ++i)
				{
					CBlob@ prop = getBlobByNetworkID( down_propellers[i] );
					if ( prop !is null && seatColor == prop.getShape().getVars().customData && ( teamInsensitive || occupierTeam == prop.getTeamNum() ) )
						prop.set_f32("power", 0);
				}
			}
			if ( this.get_bool( "kLR" ) && ( strafe || ( !left && !right ) ) )
			{
				this.set_bool( "kLR", false );

				for (uint i = 0; i < left_propellers.length; ++i)
				{
					CBlob@ prop = getBlobByNetworkID( left_propellers[i] );
					if ( prop !is null && seatColor == prop.getShape().getVars().customData && ( teamInsensitive || occupierTeam == prop.getTeamNum() ) )
						prop.set_f32("power", 0);
				}
				
				for (uint i = 0; i < right_propellers.length; ++i)
				{
					CBlob@ prop = getBlobByNetworkID( right_propellers[i] );
					if ( prop !is null && seatColor == prop.getShape().getVars().customData && ( teamInsensitive || occupierTeam == prop.getTeamNum() ) )
						prop.set_f32("power", 0);
				}
			}
			
			//power to use
			f32 power, reverse_power;
			if ( island.isMothership )
			{
				power = -1.05f;
				reverse_power = 0.15f;
			} else
			{
				power = -1.0f;
				reverse_power = 0.1f;
			}
			
			//movement modes
			if ( up || down )
			{
				this.set_bool( "kUD", true );

				for (uint i = 0; i < up_propellers.length; ++i)
				{
					CBlob@ prop = getBlobByNetworkID( up_propellers[i] );
					if ( prop !is null && seatColor == prop.getShape().getVars().customData && ( teamInsensitive || occupierTeam == prop.getTeamNum() ) )
					{
						prop.set_u32( "onTime", gameTime );
						prop.set_f32("power", up ? power * prop.get_f32("powerFactor") : reverse_power * prop.get_f32("powerFactor"));
					}
				}
				for (uint i = 0; i < down_propellers.length; ++i)
				{
					CBlob@ prop = getBlobByNetworkID( down_propellers[i] );
					if ( prop !is null && seatColor == prop.getShape().getVars().customData && ( teamInsensitive || occupierTeam == prop.getTeamNum() ) )
					{
						prop.set_u32( "onTime", gameTime );
						prop.set_f32("power", down ? power * prop.get_f32("powerFactor") : reverse_power * prop.get_f32("powerFactor"));
					}
				}
			}
			
			if ( left || right )
			{
				this.set_bool( "kLR", true );

				if ( !strafe )
				{
					for (uint i = 0; i < left_propellers.length; ++i)
					{
						CBlob@ prop = getBlobByNetworkID( left_propellers[i] );
						if ( prop !is null && seatColor == prop.getShape().getVars().customData &&  ( teamInsensitive || occupierTeam == prop.getTeamNum() ) )
						{
							prop.set_u32( "onTime", gameTime );
							prop.set_f32("power", left ? power * prop.get_f32("powerFactor") : reverse_power * prop.get_f32("powerFactor"));
						}
					}
					for (uint i = 0; i < right_propellers.length; ++i)
					{
						CBlob@ prop = getBlobByNetworkID( right_propellers[i] );
						if ( prop !is null && seatColor == prop.getShape().getVars().customData && ( teamInsensitive || occupierTeam == prop.getTeamNum() ) )
						{
							prop.set_u32( "onTime", gameTime );
							prop.set_f32("power", right ? power * prop.get_f32("powerFactor") : reverse_power * prop.get_f32("powerFactor"));
						}
					}
				} else
				{
					u8 maxStrafers = Maths::Round( Maths::FastSqrt( island.mass )/3.0f );
					for (uint i = 0; i < strafe_left_propellers.length; ++i)
					{
						CBlob@ prop = getBlobByNetworkID( strafe_left_propellers[i] );
						f32 oDrive = i < maxStrafers ? 2.0f : 1.0f;
						if ( prop !is null && seatColor == prop.getShape().getVars().customData && ( teamInsensitive || occupierTeam == prop.getTeamNum() ) )
						{
							prop.set_u32( "onTime", gameTime );
							prop.set_f32("power", left ? oDrive * power * prop.get_f32("powerFactor") : reverse_power * prop.get_f32("powerFactor"));
						}
					}
					for (uint i = 0; i < strafe_right_propellers.length; ++i)
					{
						CBlob@ prop = getBlobByNetworkID( strafe_right_propellers[i] );
						f32 oDrive = i < maxStrafers ? 2.0f : 1.0f;
						if ( prop !is null && seatColor == prop.getShape().getVars().customData && ( teamInsensitive || occupierTeam == prop.getTeamNum() ) )
						{
							prop.set_u32( "onTime", gameTime );
							prop.set_f32("power", right ? oDrive * power * prop.get_f32("powerFactor") : reverse_power * prop.get_f32("powerFactor"));
						}
					}
				}
			}
			
			if ( !space && !Human::isHoldingBlocks( occupier ) && !Human::wasHoldingBlocks( occupier ) )
			{
				//machineguns on left click
				if ( left_click )
				{
					Vec2f aim = occupier.getAimPos() - this.getPosition();//relative to seat
					for (uint i = 0; i < machineguns.length; ++i)
					{
						CBlob@ weap = getBlobByNetworkID( machineguns[i] );
						if ( weap is null || weap.get_bool( "mShipDocked" ) )
							continue;
						
						Vec2f dirFacing = Vec2f(1, 0).RotateBy( weap.getAngleDegrees() );
						if ( Maths::Abs( dirFacing.AngleWith( aim ) ) < 40 )
						{
							CBitStream bs;
							bs.write_u16( occupier.getNetworkID() );
							weap.SendCommand(weap.getCommandID("fire"), bs);
						}
					}
				}
				//cannons on right click
				if ( right_click && cannons.length > 0 && this.get_u32( "lastCannonFire" ) + CANNON_FIRE_CYCLE < gameTime )
				{
					CBlob@[] fireCannons;
					Vec2f aim = occupier.getAimPos() - this.getPosition();//relative to seat
					
					for (uint i = 0; i < cannons.length; ++i)
					{
						CBlob@ weap = getBlobByNetworkID( cannons[i] );
						if ( weap is null || !weap.get_bool( "fire ready" ) || weap.get_bool( "mShipDocked" ) )
							continue;
						
						Vec2f dirFacing = Vec2f(1, 0).RotateBy( weap.getAngleDegrees() );
						if ( Maths::Abs( dirFacing.AngleWith( aim ) ) < 40 )
							fireCannons.push_back( weap );
					}
					
					if ( fireCannons.length > 0 )
					{
						u8 index = this.get_u8( "cannonFireIndex" );
						CBlob@ weap = fireCannons[ index % fireCannons.length ];
						CBitStream bs;
						bs.write_u16( occupier.getNetworkID() );
						weap.SendCommand(weap.getCommandID("fire"), bs);
						this.set_u32( "lastCannonFire", gameTime );
						this.set_u8( "cannonFireIndex", index + 1 );
					}
				}
			}
		}
	}
	else if ( isServer && island.owner == seatOwner )//captain seats release rates
	{
		if ( island.pos != island.old_pos )//keep extra seats alive while the mothership moves
			this.set_u32( "lastActive", gameTime );
		else//release seat faster for when captain abandons the ship
			this.set_u32( "lastActive", Maths::Max( 0, this.get_u32( "lastActive" ) - 2 ) );
	}
}

//stop props on sit down if possible
void onAttach( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint )
{
	if ( getNet().isServer() )
	{
		this.set_bool( "kUD", true );
		this.set_bool( "kLR", true );
	}
}

//keep props alive onDetach
void onDetach( CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint )
{
	if ( getNet().isServer() )
	{
		this.set_bool( "kUD", false );
		this.set_bool( "kLR", false );
	}
}

void updateArrays( CBlob@ this, Island@ island )
{
	this.set_bool( "updateArrays", false );

	u16[] left_propellers, strafe_left_propellers, strafe_right_propellers, right_propellers, up_propellers, down_propellers, machineguns, cannons;					
	for (uint b_iter = 0; b_iter < island.blocks.length; ++b_iter)
	{
		IslandBlock@ isle_block = island.blocks[b_iter];
		if(isle_block is null) continue;

		CBlob@ block = getBlobByNetworkID( isle_block.blobID );
		if(block is null) continue;
					
		//machineguns
		if (block.hasTag("machinegun"))
			machineguns.push_back(block.getNetworkID());
		
		if (block.hasTag("cannon"))
			cannons.push_back(block.getNetworkID());
		
		//propellers
		if ( block.hasTag("propeller") )
		{
			Vec2f _veltemp, velNorm;
			float angleVel;
			PropellerForces(block, island, 1.0f, _veltemp, velNorm, angleVel);

			velNorm.RotateBy(-this.getAngleDegrees());
			
			const float angleLimit = 0.05f;
			const float forceLimit = 0.01f;
			const float forceLimit_side = 0.2f;

			if ( angleVel < -angleLimit || ( velNorm.y < -forceLimit_side && angleVel < angleLimit ) )
				right_propellers.push_back(block.getNetworkID());
			else if ( angleVel > angleLimit || ( velNorm.y > forceLimit_side && angleVel > -angleLimit ) )
				left_propellers.push_back(block.getNetworkID());
			
			if ( Maths::Abs( velNorm.x ) < forceLimit )
			{
				if ( velNorm.y < -forceLimit_side )
					strafe_right_propellers.push_back(block.getNetworkID());
				else if ( velNorm.y > forceLimit_side )
					strafe_left_propellers.push_back(block.getNetworkID());
			}
					
			if ( velNorm.x > forceLimit )
				down_propellers.push_back(block.getNetworkID());
			else if ( velNorm.x < -forceLimit )
				up_propellers.push_back(block.getNetworkID());
		}
	}
	
	cannons.sortAsc();
	
	this.set( "left_propellers", left_propellers );
	this.set( "strafe_left_propellers", strafe_left_propellers );
	this.set( "strafe_right_propellers", strafe_right_propellers );
	this.set( "right_propellers", right_propellers );
	this.set( "up_propellers", up_propellers );
	this.set( "down_propellers", down_propellers );
	this.set( "machineguns", machineguns );
	this.set( "cannons", cannons );
}

void server_setOwner( CBlob@ this, string owner )
{
	//print( "" + this.getNetworkID() + " seat setOwner: " + owner );
	this.set( "playerOwner", owner );
	this.set_string( "playerOwner", owner );
	this.Sync( "playerOwner", true );
	this.set_u32( "lastOwnerUpdate", getGameTime() );
}