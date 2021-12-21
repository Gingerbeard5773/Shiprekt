#include "IslandsCommon.as";
#include "BlockCommon.as";
#include "MakeDustParticle.as";
#include "AccurateSoundPlay.as";
#include "ParticleHeal.as";

u8 DAMAGE_FRAMES = 3;
// onInit: called from engine after blob is created with server_CreateBlob()

void onInit(CBlob@ this)
{
	CSprite @sprite = this.getSprite();
	sprite.SetZ(510.0f);
	CShape @shape = this.getShape();
	sprite.asLayer().SetLighting(false);
	shape.getConsts().net_threshold_multiplier = -1.0f;
	this.SetMapEdgeFlags(u8(CBlob::map_collide_none) | u8(CBlob::map_collide_nodeath));
}

void onTick (CBlob@ this)
{
	CSprite@ thisSprite = this.getSprite();
	
	if (this.getTickSinceCreated() < 1) //accounts for time after block production
	{
		CRules@ rules = getRules();
		const int blockType = thisSprite.getFrame();
		
		this.set_f32("initial reclaim", this.getHealth());		
		if (blockType == Block::STATION || blockType == Block::MINISTATION)
		{
			this.set_f32("current reclaim", 0.0f);
		}
		else
		{
			this.set_f32("current reclaim", this.getHealth());
		}
		
		//Set Owner
		if (isServer())
		{
			CBlob@ owner = getBlobByNetworkID(this.get_u16("ownerID"));    
			if (owner !is null)
			{
				this.set_string("playerOwner", owner.getPlayer().getUsername());
				this.Sync("playerOwner", true); //2040865191 PROPERTY
			}
		}
	}
	
	//path predicted collisions
	const int color = this.getShape().getVars().customData;
	if (color > 0)
	{
		Island@ island = getIsland(color);
		if (island !is null && !island.isStation && !island.isMiniStation)
		{
			Vec2f velnorm = island.vel; 
			const f32 vellen = velnorm.Normalize();		
			
			if (vellen > 4.0f) 
			{						
				bool dontHitMore = false;
			
				HitInfo@[] hitInfos;
				if (getMap().getHitInfosFromRay(this.getPosition(), -island.vel.Angle(), island.vel.Length()*2.0f, this, @hitInfos))
				{
					//HitInfo objects are sorted, first come closest hits
					for (uint i = 0; i < hitInfos.length; i++)
					{
						CBlob@ blob =  hitInfos[i].blob;	  
						if (blob is null || blob is this || dontHitMore) 
							continue;
						
						const int other_color = blob.getShape().getVars().customData;
						
						if (color == other_color) break;
						
						if (other_color > 0)
						{
							Island@ other_island = getIsland(other_color);
						
							if (other_island !is null)
							{
								const int blockType = thisSprite.getFrame();
								const int other_blockType = blob.getSprite().getFrame();
								
								bool docking = (blockType == Block::COUPLING || other_blockType == Block::COUPLING) 
													&& ((island.isMothership || other_island.isMothership) || (island.isStation || other_island.isStation) || (island.isMiniStation || other_island.isMiniStation))
													&& this.getTeamNum() == blob.getTeamNum()
													&& ((!island.isMothership && island.owner != "") || (!other_island.isMothership && other_island.owner != ""));
													
								bool ramming = ( blockType == Block::RAM || other_blockType == Block::RAM
													|| blockType == Block::FAKERAM || other_blockType == Block::FAKERAM
													|| blockType == Block::RAMENGINE || other_blockType == Block::RAMENGINE
													|| blockType == Block::SEAT || other_blockType == Block::SEAT 
													|| blockType == Block::COUPLING || other_blockType == Block::COUPLING);

								Vec2f velnorm = island.vel; 
								velnorm.Normalize();

								if ((!docking && !ramming))
								{
									CollisionResponse1( island, other_island, this.getPosition()+velnorm, docking );
								}
								dontHitMore = true;
							}
						}
					}
				}
			}
		}
	}
	
 	// push merged ships away from each other
	if (this.get_bool("colliding")) this.set_bool("colliding", false); 
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	if (!isServer()) //awkward fix for blob team changes wiping up the frame state (rest on islands.as)
	{
		CSprite@ sprite = this.getSprite();
		u8 frame = this.get_u8("frame");
		if (sprite.getFrame() == 0 && frame != 0)
			sprite.SetFrame(frame);
	}
}

// onCollision: called once from the engine when a collision happens; 
// blob is null when it is a tilemap collision
// needs to be redone!!

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob is null || this.hasTag("noCollide") || blob.hasTag("noCollide"))	return;

	const int color = this.getShape().getVars().customData;
	const int other_color = blob.getShape().getVars().customData;

	if (color > 0 && other_color > 0 && color != other_color) // block vs block
	{
		Island@ island = getIsland(color);
		Island@ other_island = getIsland(other_color);
	
		const int blockType = this.getSprite().getFrame();
		const bool solid = Block::isSolid(blockType);
		const int other_blockType = blob.getSprite().getFrame();
		const bool other_solid = Block::isSolid(other_blockType);
		bool docking;
		bool ramming;
		
		if (island !is null && other_island !is null)
		{
			if (island.vel.Length() < 0.01f && other_island.vel.Length() < 0.01f )
				return;
				
			docking = (blockType == Block::COUPLING || other_blockType == Block::COUPLING) 
								&& ((island.isMothership || other_island.isMothership) || (island.isStation || other_island.isStation) || (island.isMiniStation || other_island.isMiniStation))
								&& this.getTeamNum() == blob.getTeamNum()
								&& ((!island.isMothership && island.owner != "") || (!other_island.isMothership && other_island.owner != ""));
								
			ramming = (blockType == Block::RAM || other_blockType == Block::RAM
							|| blockType == Block::FAKERAM || other_blockType == Block::FAKERAM
							|| blockType == Block::RAMENGINE || other_blockType == Block::RAMENGINE
							|| blockType == Block::SEAT || other_blockType == Block::SEAT
							|| blockType == Block::COUPLING || other_blockType == Block::COUPLING);
		}
		else docking = false;
			
		if (island !is null && !docking && !ramming)
		{
			bool shouldCollide = true;
			for (uint i = 0; i < island.blocks.length; ++i)
			{
				IslandBlock@ isle_block = island.blocks[i];
				if (isle_block is null) continue;

				CBlob@ block = getBlobByNetworkID(isle_block.blobID);
				if (block is null) continue;
				
				if (block.get_bool("colliding"))
					shouldCollide = false;
			}
			
			if (shouldCollide)
				this.set_bool("colliding", true);		
			
			if (this.get_bool("colliding"))
			{
				CollisionResponse1(island, other_island, point1, docking);
			}
		}		
		
		if (isServer() && 
			!(blockType == Block::STATION || other_blockType == Block::STATION) && 
			!(blockType == Block::MINISTATION || other_blockType == Block::MINISTATION) ) // how to clean this up
		{
			if (docking)//force island merge
				getRules().set_bool("dirty islands", true);
			else
			{
				// these are checked separately so that seats/ram engines don't break from coups/repulsors
				if (blockType == Block::COUPLING || other_blockType == Block::COUPLING) // how to clean this up
				{
					if (blockType == Block::COUPLING) Die(this);
					if (other_blockType == Block::COUPLING) Die(blob);
				}
				else if (Block::isRepulsor(blockType) || Block::isRepulsor(other_blockType)) // how to clean this up
				{
					if (Block::isRepulsor(blockType)) Die(this);
					if (Block::isRepulsor(other_blockType)) Die(blob);
				}
				else
				{ 
					switch (blockType)
					{
						case Block::SEAT:
						case Block::FAKERAM:
						case Block::MACHINEGUN_A1: // closed seat... what the fuk
							Die(this);
							break;

						case Block::RAMENGINE:
							switch (other_blockType)
							{
								case Block::ANTIRAM:
									this.server_Hit(blob, point1, Vec2f_zero, 0.6f, 0, true);
									break;
								case Block::PROPELLER:
									this.server_Hit(blob, point1, Vec2f_zero, 2.1f, 0, true);
									break;
								case Block::PLATFORM:
								case Block::RAMENGINE:
									Die(blob);
									break;
								default:
									this.server_Hit(blob, point1, Vec2f_zero, 1.1f, 0, true);
									break;
							}
							Die(this);
							break;

						case Block::RAM:
							switch (other_blockType)
							{
								case Block::ANTIRAM:
									this.server_Hit(blob, point1, Vec2f_zero, 2.0f, 0, true);
									Die(this);
									break;

								case Block::PROPELLER:
									this.server_Hit( this, point1, Vec2f_zero, 2.2f, 0, true);
									Die(blob);
									break;

								case Block::SOLID:
								case Block::RAM:
									Die(this);
									Die(blob);
									break;

								case Block::MOTHERSHIP5:
								case Block::SECONDARYCORE:
								case Block::DECOYCORE:
									Die(this);
									break;

								default:
									if (blob.hasTag("weapon"))
									{
										if (blob.getHealth() >= this.getHealth())
										{
											Die(this);
											this.server_Hit(blob, point1, Vec2f_zero, solid ? this.getHealth() : this.getHealth()/2.0f, 0, true);
											break;
										}
										else blob.server_Hit(this, point1, Vec2f_zero, 2.0f, 0, true);
									}
									else if (!other_solid && other_island !is null) 
										this.server_Hit(this, point1, Vec2f_zero, 1.1f, 0, true);
									Die(blob);
									break;
							}
							break;

						default:
							if (Block::isBomb(blockType)) //bombs annihilate all
							{
								if (other_blockType == Block::MOTHERSHIP5)
									this.server_Hit(blob, point1, Vec2f_zero, 2.7f, 0, true);
								else Die(blob);
								Die(this);
							}
							break;
					}
					switch (other_blockType)
					{
						case Block::SEAT:
						case Block::FAKERAM:
						case Block::MACHINEGUN_A1:
							Die(blob);
							break;
					}
				}
			}
		}
	}
	else if (other_color == 0 && color > 0)
	{
		int blockType = this.getSprite().getFrame();
		// solid block vs player
		if (Block::isSolid(blockType))
		{
			Vec2f pos = blob.getPosition();
			
			if (isClient() && !blob.isAttached() && blob.getName() == "human" && blob.isMyPlayer())
			{
				//kill by impact
				Island@ island = getIsland(color);
				if (island !is null && this.getTeamNum() != blob.getTeamNum() && (getGameTime() - blob.get_u32("groundTouch time") < 15)/*longer wasOnGround*/
					&& (island.vel.LengthSquared() > 4.0f || Maths::Abs(island.angle_vel) > 1.75f || blob.getOldVelocity().LengthSquared() > 9.0f))
				{

					CPlayer@ player = blob.getPlayer();
					if (player !is null)
					{
						player.client_ChangeTeam(44);//this makes the sv kill the playerblob (Respawning.as)
						blob.Tag("dead");
					}
				}
				
				//set position collision
				blob.setPosition(pos + normal * -blob.getRadius() * 0.55f);
			}
		}
	}
}

void CollisionResponse1(Island@ island, Island@ other_island, Vec2f point1, bool docking = false)
{
	if (island is null || other_island is null)
		return;
		
	if (island.mass <= 0 || other_island.mass <= 0)
		return;
	
	Vec2f velnorm = island.vel; 
	const f32 vellen = velnorm.Normalize();
	Vec2f other_velnorm = other_island.vel; 
	const f32 other_vellen = other_velnorm.Normalize();
	
	Vec2f colvec1 = point1 - island.pos;
	Vec2f colvec2 = point1 - other_island.pos;
	colvec1.Normalize();
	colvec2.Normalize();

	const f32 veltransfer = 1.0f;
	const f32 veldamp = 1.0f;
	const f32 dirscale = 1.0f;
	f32 reactionScale1 = 1.0f;
	if (other_island.beached)
		reactionScale1 *= 2;
	f32 reactionScale2 = 1.0f;
	if (island.beached )
		reactionScale2 *= 2;
	const f32 massratio1 = other_island.mass/(island.mass+other_island.mass);
	const f32 massratio2 = island.mass/(island.mass+other_island.mass);
	island.vel *= veldamp;
	other_island.vel *= veldamp;
	
	if (other_island.isStation || other_island.isMiniStation)
	{
		if (island.beached)
			island.vel += colvec1 * -vellen * dirscale * veltransfer - colvec1*1.0f;
		else
			island.vel += colvec1 * -vellen * dirscale * veltransfer - colvec1*0.4f;
	}
	else
	{
		island.vel += colvec1 * -other_vellen * dirscale * massratio1 * veltransfer * reactionScale1 - colvec1*0.2f;
		other_island.vel += colvec2 * -vellen * dirscale * massratio2 * veltransfer * reactionScale2 - colvec2*0.2f;
	}
	
	//effects
	int shake = (vellen * island.mass + other_vellen * other_island.mass)*0.5f;
	ShakeScreen(shake, 12, point1);
	directionalSoundPlay(shake > 25 ? "WoodHeavyBump" : "WoodLightBump", point1);
}

void CollisionResponse2( Island@ island, Island@ other_island, Vec2f point1 )
{
	if (island is null || other_island is null)
		return;
		
	if (island.mass <= 0 || other_island.mass <= 0)
		return;
	
	Vec2f velnorm = island.vel; 
	const f32 vellen = velnorm.Normalize();
	Vec2f other_velnorm = other_island.vel; 
	const f32 other_vellen = other_velnorm.Normalize();

	Vec2f colvec1 = point1 - island.pos;
	Vec2f colvec2 = point1 - other_island.pos;
	colvec1.Normalize();
	colvec2.Normalize();

	const f32 veltransfer = 1.0f;
	const f32 veldamp = 1.0f;
	const f32 dirscale = 0.1f;
	const f32 massratio1 = other_island.mass/(island.mass+other_island.mass);
	const f32 massratio2 = island.mass/(island.mass+other_island.mass);
	
	island.vel *= veldamp;
	other_island.vel *= veldamp;
	island.pos += -colvec1*0.2f;
	other_island.pos += -colvec2*0.2f;
	island.vel += colvec1 * -other_vellen * dirscale * massratio1 * veltransfer - colvec1*0.1f;
	other_island.vel += colvec2 * -vellen * dirscale * massratio2 * veltransfer - colvec2*0.1f;
}

void onDie(CBlob@ this)
{
	//gib the sprite
	if (this.getShape().getVars().customData > 0)
		this.getSprite().Gib();

	if (isClient())
	{
		//kill humans standing on top. done locally because lag makes server unable to catch the overlapping playerblobs
		int type = this.getSprite().getFrame();
		if (type != Block::COUPLING && !Block::isRepulsor(type))
		{
			CBlob@ localBlob = getLocalPlayerBlob();
			if (localBlob !is null && localBlob.get_u16("shipID") == this.getNetworkID())
			{
				CPlayer@ player = localBlob.getPlayer();
				if (player !is null && localBlob.getDistanceTo(this) < 6.5f)
				{
					player.client_ChangeTeam(44);//this makes the sv kill the playerblob (Respawning.as)
					localBlob.Tag("dead");
				}
			}
		}
	}
	
	if (isServer() && this.hasTag("seat"))
	{
		AttachmentPoint@ seat = this.getAttachmentPoint(0);
		CBlob@ b = seat.getOccupied();
		if (b !is null) b.server_Die();
	}
}

void Die(CBlob@ this)
{
	if (!isServer()) return;
	
	this.Tag("noCollide");
	this.server_Die();
}

//mothership damage alerts
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	const int color = this.getShape().getVars().customData;
	if (color < 0) return 0.0f;
	
	int teamNum = this.getTeamNum();

	if (teamNum!= hitterBlob.getTeamNum() && isMothership(this))
	{
		CRules@ rules = getRules();
		
		f32 msDMG = rules.get_f32("msDMG" + teamNum);
		if (msDMG < 8.0f)
			getRules().set_f32("msDMG" + teamNum, msDMG + (this.hasTag("mothership") ? 5.0f : 1.0f) * damage);
	}
	
	return damage;
}

//damage layers
void onHealthChange(CBlob@ this, f32 oldHealth)
{
	const bool isCore = this.hasTag("mothership") || this.hasTag("secondaryCore");

	const f32 hp = this.getHealth();

	if (hp <= 0.0f && !isCore) this.server_Die();
	else
	{
		//update reclaim status
		if (hp < this.get_f32("current reclaim") && !isCore)
		{
			this.set_f32("current reclaim", hp);
		}
		
		if (isClient())
		{
			int blockType = this.getSprite().getFrame();
			const f32 initHealth = this.getInitialHealth();

			//add damage layers
			f32 step = initHealth / (DAMAGE_FRAMES + 1); //health divided equally into segments which tell when to change dmg frame
			f32 currentStep = Maths::Floor(oldHealth/step) * step; //what is the step we are on?
			
			if (Block::isSolid(blockType) && hp < currentStep && hp <= initHealth - step && !isCore) //update frame if past health margins
			{
				int bFrame = blockType == Block::RAM ? 9 : blockType == Block::ANTIRAM ? 46 : 5; //5 default- for propellers

				if (blockType != Block::RAMENGINE && blockType != Block::POINTDEFENSE && blockType != Block::FAKERAM)
				{
					const int frame = (oldHealth > initHealth * 0.5f) ? bFrame : bFrame + 1;	
					CSprite@ sprite = this.getSprite();
					CSpriteLayer@ layer = sprite.addSpriteLayer("dmg"+sprite.getSpriteLayerCount());
					if (layer !is null)
					{
						layer.SetRelativeZ(1+frame);
						layer.SetLighting(false);
						layer.SetFrame(frame);
						layer.RotateBy(XORRandom(4) * 90, Vec2f_zero);
					}
				}

				for (int i = 0; i < 2; ++i) //wood chips on frame change
				{
					CParticle@ p = makeGibParticle("Woodparts", this.getPosition(), getRandomVelocity(0, 0.3f, XORRandom(360)),
													0, XORRandom(6), Vec2f(8, 8), 0.0f, 0, "");
					if (p !is null)
					{
						//p.Z = 550.0f;
						p.damping = 0.98f;
					}
				}
				
				MakeDustParticle(this.getPosition(), "/dust2.png");
			}
			else if (hp > oldHealth)
			{
				//remove damage frames on heal
				if (Maths::Floor(hp) > currentStep)
				{
					CSprite@ sprite = this.getSprite();
					sprite.RemoveSpriteLayer("dmg"+(sprite.getSpriteLayerCount()-1));
				}

				makeHealParticle(this, "HealParticle2"); //cute green particles
			}
		}
	}
}

void onGib(CSprite@ this)
{
	Vec2f pos = this.getBlob().getPosition();
	//MakeDustParticle(pos, "/DustSmall.png");
	directionalSoundPlay("destroy_wood", pos);
}
// network

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	stream.write_u8(Block::getType(this));
	stream.write_netid(this.get_u16("ownerID"));
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	u8 type = 0;
	u16 ownerID = 0;

	if (!stream.saferead_u8(type))
	{
		warn("Block::onReceiveCreateData - missing type");
		return false;	
	}
	if (!stream.saferead_u16(ownerID))
	{
		warn("Block::onReceiveCreateData - missing ownerID");
		return false;	
	}

	this.getSprite().SetFrame(type);

	CBlob@ owner = getBlobByNetworkID(ownerID);
	if (owner !is null)
	{
	    owner.push("blocks", @this);
		this.getShape().getVars().customData = -1; // don't push on island
	}

	return true;
}
