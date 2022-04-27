#include "ShipsCommon.as";
#include "AccurateSoundPlay.as";
#include "ParticleHeal.as";

// onInit: called from engine after blob is created with server_CreateBlob()

void onInit(CBlob@ this)
{
	this.Tag("block");
	
	CSprite@ sprite = this.getSprite();
	sprite.SetZ(310.0f);
	sprite.asLayer().SetLighting(false);
	
	ShapeConsts@ consts = this.getShape().getConsts();
	consts.net_threshold_multiplier = -1.0f;
    consts.mapCollisions = false; //ships.as gives own collision
	
	//this.SetMapEdgeFlags(u8(CBlob::map_collide_none) | u8(CBlob::map_collide_nodeath));
	
	this.set_f32("current reclaim", this.getInitialHealth());
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() < 1) //accounts for time after block production
	{
		//Set Owner
		if (isServer())
		{
			CBlob@ owner = getBlobByNetworkID(this.get_netid("ownerID"));    
			if (owner !is null)
			{
				this.set_string("playerOwner", owner.getPlayer().getUsername());
				this.Sync("playerOwner", true); //2040865191 PROPERTY
			}
		}
	}
	
	//collide even when going super speeds (to avoid clipping)
	const int color = this.getShape().getVars().customData;
	if (color > 0)
	{
		Ship@ ship = getShip(color);
		if (ship !is null && !ship.isStation && ship.mass < 3.0f)
		{
			Vec2f velnorm = ship.vel; 
			const f32 vellen = velnorm.Normalize();		
			
			if (vellen > 8.0f) 
			{
				Vec2f pos = this.getPosition();
				HitInfo@[] hitInfos;
				if (getMap().getHitInfosFromRay(pos, -ship.vel.Angle(), ship.vel.Length()*2.0f, this, @hitInfos))
				{
					//HitInfo objects are sorted, first come closest hits
					const u8 hitLength = hitInfos.length;
					for (u8 i = 0; i < hitLength; i++)
					{
						CBlob@ blob = hitInfos[i].blob;	  
						if (blob is null || blob is this) continue;
						
						const int other_color = blob.getShape().getVars().customData;
						if (color == other_color) break;
						
						if (other_color > 0)
						{
							Ship@ other_ship = getShip(other_color);
							if (other_ship !is null)
							{
								bool docking = (this.hasTag("coupling") || blob.hasTag("coupling")) 
													&& ((ship.isMothership || other_ship.isMothership) || (ship.isStation || other_ship.isStation))
													//&& this.getTeamNum() == blob.getTeamNum()
													&& ((!ship.isMothership && ship.owner != "") || (!other_ship.isMothership && other_ship.owner != ""));
													
								bool ramming = this.hasTag("ramming") || blob.hasTag("ramming");

								velnorm.Normalize();

								if (!ship.colliding && !docking && !ramming)
								{
									ship.colliding = true; //only collide once per tick
									CollisionResponse1(ship, other_ship, pos + velnorm, docking);
								}
								break;
							}
						}
					}
				}
			}
		}
	}
}

// onCollision: called once from the engine when a collision happens; 
// blob is null when it is a tilemap collision
// needs to be redone!!

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return (this.getShape().getVars().customData > 0 && this.getTickSinceCreated() > 0);
}

bool doesCollideWithPlank(CBlob@ plank, Vec2f blobPos)
{
	//done by position rather than velocity since blocks are never actually given a velocity (ship.as)
	Vec2f direction = Vec2f(0.0f, -1.0f).RotateBy(plank.getAngleDegrees());
	f32 hitAngle = direction.AngleWith(plank.getPosition() - blobPos);

	return !(hitAngle > -90.0f && hitAngle < 90.0f);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob is null || this.hasTag("dead") || blob.hasTag("dead"))
		return;

	const int color = this.getShape().getVars().customData;
	if (color <= 0) return;
	
	const int other_color = blob.getShape().getVars().customData;

	if (other_color > 0 && color != other_color) // block vs block
	{
		if (blob.hasTag("plank") ? !doesCollideWithPlank(blob, this.getPosition()) : false)
			return;
		if (this.hasTag("plank") ? !doesCollideWithPlank(this, blob.getPosition()) : false)
			return;
	
		bool docking = false;
		
		Ship@ ship = getShip(color);
		Ship@ other_ship = getShip(other_color);
		
		if (ship !is null && other_ship !is null)
		{
			if (ship.vel.Length() < 0.01f && other_ship.vel.Length() < 0.01f)
				return;
				
			docking = (this.hasTag("coupling") || blob.hasTag("coupling")) 
					&& ((ship.isMothership || other_ship.isMothership) || (ship.isSecondaryCore || other_ship.isSecondaryCore) || (ship.isStation || other_ship.isStation))
					//&& this.getTeamNum() == blob.getTeamNum()
					&& ((!ship.isMothership && !ship.isSecondaryCore && ship.owner != "") || (!other_ship.isMothership && !other_ship.isSecondaryCore && other_ship.owner != ""));
								
			bool ramming = this.hasTag("ramming") || blob.hasTag("ramming");
			
			if (!ship.colliding && !docking && !ramming)
			{
				ship.colliding = true; //only collide once per tick
				CollisionResponse1(ship, other_ship, point1, docking);
			}
		}
		
		//TODO: isolate collision code in each blob's script rather than here
		if (!(this.hasTag("station") || blob.hasTag("station")))
		{
			if (docking) //force ship merge
			{
				getRules().set_bool("dirty ships", true);
				directionalSoundPlay("mechanical_click", blob.getPosition());
			}
			else if (isServer())
			{
				// these are checked separately so that seats/ram engines don't break from coups/repulsors
				if (this.hasTag("coupling") || this.hasTag("repulsor"))
					Die(this);
				else if (blob.hasTag("coupling") || blob.hasTag("repulsor"))
					Die(blob);
				else
				{ 
					if (this.hasTag("seat"))
						Die(this);
					if (blob.hasTag("seat"))
						Die(blob);

					if (this.hasTag("ramengine"))
					{
						if (blob.hasTag("antiram") || blob.hasTag("core"))
							this.server_Hit(blob, point1, Vec2f_zero, 0.6f, 0, true);
						else if (blob.hasTag("propeller"))
							this.server_Hit(blob, point1, Vec2f_zero, 2.1f, 0, true);
						else if (blob.hasTag("platform") || blob.hasTag("ramengine"))
							Die(blob);
						else
							this.server_Hit(blob, point1, Vec2f_zero, 1.0f, 0, true);
							
						Die(this);
					}
					else if (this.hasTag("ram"))
					{
						if (blob.hasTag("antiram"))
						{
							this.server_Hit(blob, point1, Vec2f_zero, 2.0f, 0, true);
							Die(this);
						}
						else if (blob.hasTag("propeller"))
						{
							this.server_Hit(this, point1, Vec2f_zero, 2.2f, 0, true);
							Die(blob);
						}
						else if (blob.hasTag("hull") || blob.hasTag("ram") || blob.hasTag("plank"))
						{
							Die(this);
							Die(blob);
						}
						else if (blob.hasTag("core"))
						{
							this.server_Hit(blob, point1, Vec2f_zero, 1.0f, 0, true);
							Die(this);
						}
						else if (blob.hasTag("weapon"))
						{
							if (blob.getHealth() >= this.getHealth())
							{
								Die(this);
								this.server_Hit(blob, point1, Vec2f_zero, this.hasTag("solid") ? this.getHealth() : this.getHealth()/2.0f, 0, true);
							}
							else blob.server_Hit(this, point1, Vec2f_zero, 2.0f, 0, true);
						}
						else if (!blob.hasTag("solid"))
						{
							this.server_Hit(this, point1, Vec2f_zero, 1.1f, 0, true);
							Die(blob);
						}
					}
					else if (this.hasTag("bomb")) //bombs annihilate all
					{
						if (blob.hasTag("mothership"))
							this.server_Hit(blob, point1, Vec2f_zero, 2.7f, 0, true);
						else Die(blob);
						Die(this);
					}
				}
			}
		}
	}
	else if (other_color == 0)
	{
		// solid block vs player
		if ((this.hasTag("solid") || (this.hasTag("door") && this.getShape().getConsts().collidable)) && blob.getName() == "human")
		{
			if (isClient() && !blob.isAttached() && blob.getAirTime() > 4) //air time is time spent on water
			{
				//kill player by impact
				Ship@ ship = getShip(color);
				if (ship !is null && (ship.vel.LengthSquared() > 5.0f || Maths::Abs(ship.angle_vel) > 1.75f || blob.getOldVelocity().LengthSquared() > 9.0f))
				{
					Vec2f blockSide(5.0f, 0.0f);
					blockSide.RotateBy(-ship.vel.Angle());
					const bool noSideHits = ((this.getPosition() + blockSide) - point1).Length() < 4.15f; //dont die if we arent in block's path
					
					if (!noSideHits)
						directionalSoundPlay("Scrape1", point1);
					
					if ((blob.isMyPlayer() || (blob.getPlayer() !is null && blob.getPlayer().isBot())) && 
						noSideHits && blob.getTeamNum() != this.getTeamNum())
					{
						CBitStream params;
						params.write_netid(this.getNetworkID());
						blob.SendCommand(blob.getCommandID("run over"), params);
					}
				}
			}
		}
	}
}

void CollisionResponse1(Ship@ ship, Ship@ other_ship, Vec2f point1, bool docking = false)
{		
	if (ship.mass <= 0 || other_ship.mass <= 0)
		return;
	
	Vec2f velnorm = ship.vel; 
	const f32 vellen = velnorm.Normalize();
	Vec2f other_velnorm = other_ship.vel; 
	const f32 other_vellen = other_velnorm.Normalize();
	
	Vec2f colvec1 = point1 - ship.pos;
	Vec2f colvec2 = point1 - other_ship.pos;
	colvec1.Normalize();
	colvec2.Normalize();
	
	const f32 massratio1 = other_ship.mass/(ship.mass+other_ship.mass);
	const f32 massratio2 = ship.mass/(ship.mass+other_ship.mass);
	
	if (other_ship.isStation)
	{
		ship.vel += colvec1 * -vellen - colvec1*0.7f;
	}
	else
	{
		ship.vel = ClampSpeed(ship.vel + colvec1 * -other_vellen * massratio1 * 2 - colvec1*0.2f, 20);
		other_ship.vel = ClampSpeed(other_ship.vel + colvec2 * -vellen * massratio2 * 2 - colvec2*0.2f, 20);
	}
	
	if (isClient())
	{
		//effects
		u8 shake = (vellen * ship.mass + other_vellen * other_ship.mass)*0.5f;
		ShakeScreen(Maths::Min(shake, 100), 12, point1);
		directionalSoundPlay(shake > 25 ? "WoodHeavyBump" : "WoodLightBump", point1);
	}
}

Vec2f ClampSpeed(Vec2f vel, f32 cap)
{
	return Vec2f(Maths::Clamp(vel.x, -cap, cap), Maths::Clamp(vel.y, -cap, cap));
}

void onDie(CBlob@ this)
{
	//gib the sprite
	if (this.getShape().getVars().customData > 0)
		this.getSprite().Gib();

	if (isClient())
	{
		//kill humans standing on top. done locally because lag makes server unable to catch the overlapping playerblobs
		if (!this.hasTag("coupling") && !this.hasTag("repulsor") && !this.hasTag("disabled"))
		{
			CBlob@ localBlob = getLocalPlayerBlob();
			if (localBlob !is null && localBlob.get_u16("shipID") == this.getNetworkID())
			{
				if (localBlob.isMyPlayer() && localBlob.getDistanceTo(this) < 6.5f)
				{
					CBitStream params;
					params.write_netid(localBlob.getNetworkID());
					localBlob.SendCommand(localBlob.getCommandID("run over"), params);
				}
			}
		}
	}
}

void Die(CBlob@ this)
{
	if (!isServer()) return;
	
	this.Tag("dead");
	this.server_Die();
}

//mothership damage alerts
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	const int color = this.getShape().getVars().customData;
	if (color < 0) return 0.0f; // unplaced blocks are invincible
	
	u8 teamNum = this.getTeamNum();
	
	Ship@ ship = getShip(color);
	if (ship is null) return damage;

	if (teamNum != hitterBlob.getTeamNum() && ship.isMothership)
	{
		CRules@ rules = getRules();
		
		f32 msDMG = rules.get_f32("msDMG" + teamNum);
		if (msDMG < 8.0f)
			getRules().set_f32("msDMG" + teamNum, msDMG + (this.hasTag("mothership") ? 5.0f : 1.0f) * damage);
	}
	
	return damage;
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	if (this.getShape().getVars().customData <= 0) return;
	
	const bool isCore = this.hasTag("mothership");
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
			if (hp > oldHealth)
			{
				makeHealParticle(this, "HealParticle2"); //cute green particles
			}
		}
	}
}

void onGib(CSprite@ this)
{
	Vec2f pos = this.getBlob().getPosition();
	directionalSoundPlay("destroy_wood", pos);
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	if (!isServer()) //awkward fix for blob team changes wiping up the frame state (rest on ships.as)
	{
		CSprite@ sprite = this.getSprite();
		u8 frame = this.get_u8("frame");
		if (sprite.getFrame() == 0 && frame != 0)
			sprite.SetFrame(frame);
	}
}

// network

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	stream.write_u8(this.getSprite().getFrame());
	stream.write_netid(this.get_netid("ownerID"));
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	u8 type = 0;
	u16 ownerID = 0; //netid
	
	if (!stream.saferead_u8(type))
	{
		warn("Block::onReceiveCreateData - missing type");
		return false;	
	}

	if (!stream.saferead_netid(ownerID))
	{
		warn("Block::onReceiveCreateData - missing ownerID");
		return false;	
	}

	this.getSprite().SetFrame(type);

	CBlob@ owner = getBlobByNetworkID(ownerID);
	if (owner !is null)
	{
	    owner.push("blocks", @this);
		this.getShape().getVars().customData = -1; // don't push on ship
	}

	return true;
}
