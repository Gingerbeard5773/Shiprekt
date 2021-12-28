#include "BlockCommon.as"
#include "IslandsCommon.as"
#include "WaterEffects.as"
#include "HarpoonForceCommon.as"
#include "ParticleSparks.as"
#include "TileCommon.as";
#include "AccurateSoundPlay.as";

const int FIRE_RATE = 45;
const f32 harpoon_grapple_length = 300.0f;
const f32 harpoon_grapple_slack = 16.0f;
const f32 harpoon_grapple_throw_speed = 20.0f;

const f32 harpoon_grapple_force = 2.0f;
const f32 harpoon_grapple_accel_limit = 1.5f;
const f32 harpoon_grapple_stiffness = 0.1f;

Random _shotspreadrandom(0x11598); //clientside

const string grapple_sync_cmd = "grapple sync";

shared class HarpoonInfo
{
	bool grappling;
	bool reeling;
	u16 grapple_id;
	f32 grapple_ratio;
	f32 cache_angle;
	Vec2f grapple_pos;
	Vec2f grapple_vel;

	HarpoonInfo()
	{
		grappling = false;
		reeling = false;
	}
};

void onInit(CBlob@ this)
{
	this.Tag("harpoon");
	this.Tag("weapon");
	
	this.set_string("seat label", "Control Harpoon");

	CSprite@ sprite = this.getSprite();
	
	LoadSprites(sprite);
	
    CSpriteLayer@ layer = sprite.addSpriteLayer("harpoon", "HarpoonBlock.png", 16, 16);
    if (layer !is null)
    {
    	layer.SetRelativeZ(2);
    	layer.SetLighting(false);
     	Animation@ animFired = layer.addAnimation("fired", FIRE_RATE, false);
        animFired.AddFrame(1);

		Animation@ animSet = layer.addAnimation("set", FIRE_RATE, false);
        animSet.AddFrame(0);
        layer.SetAnimation("set");
    }
	
	HarpoonInfo harpoon;	  
	this.set("harpoonInfo", @harpoon);
	
	this.addCommandID(grapple_sync_cmd);
	this.addCommandID("unhook");
	this.addCommandID("clear attached");
}

void onTick(CBlob@ this)
{	
	if (this.getShape().getVars().customData <= 0) return;
	
	HarpoonInfo@ harpoon;
	if (!this.get("harpoonInfo", @harpoon)) return;
	
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ layer = sprite.getSpriteLayer("harpoon");
	Vec2f pos = this.getPosition();
	Island@ thisIsland = getIsland(this.getShape().getVars().customData);
	
	doRopeUpdate(sprite, this, harpoon);
	
	if (!harpoon.grappling)
		layer.SetAnimation("set");
	
	AttachmentPoint@ seat = this.getAttachmentPoint(0);
	CBlob@ occupier = seat.getOccupied();

	if (occupier !is null)
	{
		Manual(this, occupier);	
		
		const bool left_click = occupier.isKeyJustPressed(key_action1);
		if (left_click)
		{
			if (!harpoon.grappling && !harpoon.reeling) //otherwise grapple PROBLEM BLOCK
			{
				harpoon.grappling = true;
				harpoon.grapple_id = 0xffff;
				harpoon.grapple_pos = pos;
				directionalSoundPlay("HookShot.ogg", pos, 1.0f, XORRandom(2) == 1 ? 1.0f : 1.5f);
				CParticle@ p = ParticleAnimated( "Entities/Effects/Sprites/WhitePuff.png",
									pos,
									this.getVelocity()*0.5f + (occupier.getAimPos() - pos)/(occupier.getAimPos() - pos).getLength(),
									1.0f, 0.5f, 
									2, 
									0.0f, true);			
									
				if (p !is null)
				{
					p.Z = 550;
				}

				harpoon.grapple_ratio = 1.0f; //allow fully extended

				Vec2f direction = occupier.getAimPos() - pos;

				// more intuitive aiming (compensates for gravity and cursor position)
				f32 distance = direction.Normalize();
				if (distance > 1.0f)
				{	
					harpoon.grapple_vel = direction * harpoon_grapple_throw_speed;
				}
				else
				{
					harpoon.grapple_vel = Vec2f_zero;
				}

				SyncGrapple(this);
			}
		}
	}
	
	
	if (harpoon.grappling || harpoon.grapple_id != 0xffff)
	{
		//update grapple
		//TODO move to its own script?
		
		bool ropeTooLong = (harpoon.grapple_pos - pos).getLength() > harpoon_grapple_length;	
		
		bool ropeOutOfBounds = (harpoon.grapple_pos.x < 16.0f 
									|| harpoon.grapple_pos.x > (getMap().tilemapwidth * getMap().tilesize) - 16.0f
									|| harpoon.grapple_pos.y < 16.0f
									|| harpoon.grapple_pos.y > (getMap().tilemapheight * getMap().tilesize) - 16.0f);
		
		if ((ropeTooLong && harpoon.grapple_id == 0xffff) && !harpoon.reeling && !layer.isAnimation("set"))
				directionalSoundPlay("HookReel.ogg", pos);
				
		if (occupier !is null)
		{
			if (occupier.isKeyJustPressed(key_action2) && !harpoon.reeling && !layer.isAnimation("set"))
			{
				directionalSoundPlay("HookReel.ogg", pos);
				harpoon.reeling = true;
			}					
		}
		
		if ((((ropeTooLong || ropeOutOfBounds || isTouchingRock(harpoon.grapple_pos)) && harpoon.grapple_id == 0xffff) || harpoon.reeling) && !layer.isAnimation("set"))
		{
			harpoon.reeling = true;

			const f32 harpoon_grapple_range = harpoon_grapple_length * harpoon.grapple_ratio;
			const f32 harpoon_grapple_force_limit = this.getMass() * harpoon_grapple_accel_limit;

			CMap@ map = this.getMap();

			//reel in
			//TODO: sound
			if(harpoon.grapple_ratio > 0.2f)
				harpoon.grapple_ratio -= 1.0f / getTicksASecond();

			//get the force and offset vectors
			Vec2f force;
			Vec2f offset;
			f32 dist;
			{
				force = harpoon.grapple_pos - pos;
				dist = force.Normalize();
				f32 offdist = dist - harpoon_grapple_range;
				if (offdist > 0)
				{
					offset = force * Maths::Min(8.0f,offdist * harpoon_grapple_stiffness);
					force *= 1000.0f / (harpoon.grapple_pos - pos).getLength();
				}
				else
				{
					force.Set(0,0);
				}
			}
			
			const f32 drag = map.isInWater(harpoon.grapple_pos) ? 0.7f : 0.90f;
			const Vec2f gravity(0,0.5);

			harpoon.grapple_vel = -force;
			
			Vec2f retractBaseMin = (harpoon.grapple_pos - pos);
			retractBaseMin.Normalize();
			Vec2f retract = retractBaseMin*5.0f;
			Vec2f next = harpoon.grapple_pos + harpoon.grapple_vel - retract;
			next -= offset;

			Vec2f dir = next - harpoon.grapple_pos;
			f32 delta = dir.Normalize();
			bool found = false;
			const f32 step = map.tilesize * 0.5f;
			while (delta > 0 && !found) //fake raycast
			{				
				if (delta > step)
				{
					harpoon.grapple_pos += dir * step;
				}
				else
				{
					harpoon.grapple_pos = next;
				}
				delta -= step;
				CBlob@ b = map.getBlobAtPosition(harpoon.grapple_pos);
				if (b !is null)
				{
					if (b is this || b.getName() == "human")
					{
						//can't grapple self if not reeled in

						harpoon.grappling = false;
						SyncGrapple(this);						
						
						directionalSoundPlay("HookReset.ogg", pos);
						harpoon.reeling = false;
					}
				}
			}
		}
		else
		{
			const f32 harpoon_grapple_range = harpoon_grapple_length * harpoon.grapple_ratio;
			const f32 harpoon_grapple_force_limit = this.getMass() * harpoon_grapple_accel_limit;

			CMap@ map = this.getMap();

			//reel in
			//TODO: sound
			if (harpoon.grapple_ratio > 0.2f)
				harpoon.grapple_ratio -= 1.0f / getTicksASecond();

			//get the force and offset vectors
			Vec2f force;
			Vec2f offset;
			f32 dist;
			{
				force = harpoon.grapple_pos - pos;
				dist = force.Normalize();
				f32 offdist = dist - harpoon_grapple_range;
				if (offdist > 0)
				{
					offset = force * Maths::Min(8.0f,offdist * harpoon_grapple_stiffness);
					force *= Maths::Min(harpoon_grapple_force_limit, Maths::Max(0.0f, offdist + harpoon_grapple_slack) * harpoon_grapple_force);
				}
				else
				{
					force.Set(0,0);
				}
			}

			if (harpoon.grapple_id == 0xffff) //not stuck
			{
				const f32 drag = map.isInWater(harpoon.grapple_pos) ? 0.7f : 0.90f;

				harpoon.grapple_vel = (harpoon.grapple_vel);

				Vec2f next = harpoon.grapple_pos + harpoon.grapple_vel;
				next -= offset;

				Vec2f dir = next - harpoon.grapple_pos;
				f32 delta = dir.Normalize();
				bool found = false;
				const f32 step = map.tilesize * 0.5f;
				while (delta > 0 && !found) //fake raycast
				{
					if(delta > step)
					{
						harpoon.grapple_pos += dir * step;
					}
					else
					{
						harpoon.grapple_pos = next;
					}
					delta -= step;
					found = checkGrappleStep(this, harpoon, map, dist);
				}
				
				layer.SetAnimation("fired");
			}
			else //stuck in map -> pull towards pos
			{
				CBlob@ b = null;
				if (harpoon.grapple_id != 0)
				{
					@b = getBlobByNetworkID(harpoon.grapple_id);
					if (b is null)
					{
						harpoon.grapple_id = 0;
					}
				}
				
				if (b !is null)
				{
					if (b.hasTag("block"))
					{
						const int blockType = b.getSprite().getFrame();
						if (b.hasTag("solid"))
						{
							harpoon.grapple_pos = b.getPosition();
							
							// Pull the islands together
							Island@ hitIsland = getIsland(b.getShape().getVars().customData);
							if (hitIsland !is null)
							{
								bool isMyIsland = hitIsland.id == thisIsland.id;
								bool ropeTooLong = (harpoon.grapple_pos - pos).getLength() > harpoon_grapple_length;
								if (!isMyIsland && ropeTooLong)
								{
									Vec2f moveVel;
									Vec2f moveNorm;
									float angleVel;	
								
									const f32 hitMass = hitIsland.mass;
									HarpoonForces(this, b, -1.0f, moveVel, moveNorm, angleVel);
									moveVel /= hitMass;
									angleVel /= hitMass;
									hitIsland.vel += moveVel;
									hitIsland.angle_vel += angleVel*2.0f;
									
									const f32 thisMass = thisIsland.mass;
									HarpoonForces(b, this, -1.0f, moveVel, moveNorm, angleVel);
									moveVel /= thisMass;
									angleVel /= thisMass;
									thisIsland.vel += moveVel;
									thisIsland.angle_vel += angleVel*2.0f;
								}
							}
						}
					}
				}
				else
				{
					harpoon.reeling = true;		
					SyncGrapple(this);
				} 				
			}
		}
	}
}

void Manual(CBlob@ this, CBlob@ occupier)
{
	Vec2f aimpos = occupier.getAimPos();
	Vec2f aimvector = aimpos - this.getPosition();	

	// rotate muzzle
	Rotate(this, aimvector);
	
	occupier.setAngleDegrees(-aimvector.getAngleDegrees());
}

void Rotate(CBlob@ this, Vec2f aimvector)
{
	CSpriteLayer@ layer = this.getSprite().getSpriteLayer("harpoon");
	if(layer !is null)
	{
		layer.ResetTransform();
		layer.RotateBy(-aimvector.getAngleDegrees() - this.getAngleDegrees(), Vec2f_zero);
	}	
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	AttachmentPoint@ seat = this.getAttachmentPoint(0);
	CBlob@ occupier = seat.getOccupied();
	
	if (cmd == this.getCommandID(grapple_sync_cmd))
    {
		HandleGrapple(this, params, true);
	}
	else if (cmd == this.getCommandID("unhook"))
    {
		HarpoonInfo@ harpoon;
		if (!this.get("harpoonInfo", @harpoon)) 
			return;
		
        harpoon.reeling = true;
    }
	else if (cmd == this.getCommandID("clear attached"))
	{
		AttachmentPoint@ seat = this.getAttachmentPoint(0);
		CBlob@ crewmate = seat.getOccupied();
		if (crewmate !is null)
			crewmate.SendCommand(crewmate.getCommandID("get out"));
	}
}

void LoadSprites(CSprite@ this)
{
    string texname = "Entities/Block/Harpoon.png";
	
	//grapple
    this.RemoveSpriteLayer("hook");
    CSpriteLayer@ hook = this.addSpriteLayer("hook", texname , 16, 16, this.getBlob().getTeamNum(), this.getBlob().getSkinNum());

    if (hook !is null)
    {
        Animation@ anim = hook.addAnimation("default", 0, false);
        anim.AddFrame(28);
        hook.SetRelativeZ(101.0f);
        hook.SetVisible(false);
    }
    
    this.RemoveSpriteLayer("loose rope");
    CSpriteLayer@ looseRope = this.addSpriteLayer( "loose rope", texname , 32, 32, this.getBlob().getTeamNum(), this.getBlob().getSkinNum() );

    if (looseRope !is null)
    {
        Animation@ anim = looseRope.addAnimation("default", 1, true);
		array<int> frames = {0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1};
		anim.AddFrames( frames );
        looseRope.SetRelativeZ(100.0f);
        looseRope.SetVisible(false);
    }
	
	this.RemoveSpriteLayer("rope");
    CSpriteLayer@ rope = this.addSpriteLayer("rope", texname , 32, 32, this.getBlob().getTeamNum(), this.getBlob().getSkinNum());

    if (rope !is null)
    {
        Animation@ anim = rope.addAnimation("default", 0, false);
        anim.AddFrame(3);
        rope.SetRelativeZ(100.0f);
        rope.SetVisible(false);
    }
}

void SyncGrapple(CBlob@ this)
{
	HarpoonInfo@ harpoon;
	if (!this.get("harpoonInfo", @harpoon)) return;
	
	CBitStream bt;
	
	bt.write_bool(harpoon.grappling);
	if (harpoon.grappling)
	{
		bt.write_u16(harpoon.grapple_id);
		bt.write_u8(u8(harpoon.grapple_ratio*250));
		bt.write_Vec2f(harpoon.grapple_pos);
		bt.write_Vec2f(harpoon.grapple_vel);
	}
	
	this.SendCommand(this.getCommandID(grapple_sync_cmd), bt);
}

void HandleGrapple(CBlob@ this, CBitStream@ bt, bool apply)
{
	HarpoonInfo@ harpoon;
	if (!this.get("harpoonInfo", @harpoon)) return;
	
	bool grappling;
	u16 grapple_id;
	f32 grapple_ratio;
	Vec2f grapple_pos;
	Vec2f grapple_vel;
	
	grappling = bt.read_bool();
	
	if (grappling)
	{
		grapple_id = bt.read_u16();
		u8 temp = bt.read_u8();
		grapple_ratio = temp / 250.0f;
		grapple_pos = bt.read_Vec2f();
		grapple_vel = bt.read_Vec2f();
	}
	
	if (apply)
	{
		harpoon.grappling = grappling;
		if (harpoon.grappling)
		{
			harpoon.grapple_id = grapple_id;
			harpoon.grapple_ratio = grapple_ratio;
			harpoon.grapple_pos = grapple_pos;
			harpoon.grapple_vel = grapple_vel;
		}
		else
		{
			harpoon.grapple_id = 0xffff;
		}
	}
}

void doRopeUpdate(CSprite@ this, CBlob@ blob, HarpoonInfo@ harpoon)
{
	CSpriteLayer@ looseRope = this.getSpriteLayer("loose rope");
	CSpriteLayer@ rope = this.getSpriteLayer("rope");
	CSpriteLayer@ hook = this.getSpriteLayer("hook");
	
	bool visible = harpoon !is null && harpoon.grappling;
	
	if (!(harpoon.grapple_id == 0xffff) || harpoon.grapple_id == 0 || harpoon.reeling)
	{
		rope.SetVisible(visible);
		looseRope.SetVisible(false);
	}
	else
	{
		looseRope.SetVisible(visible);
		rope.SetVisible(false);	
	}


	hook.SetVisible(visible);
	if (!visible)
	{
		harpoon.reeling = false;
		return;
	}


	Vec2f off = harpoon.grapple_pos - blob.getPosition();
	
	f32 ropelen = Maths::Max(0.1f,off.Length() / 32.0f);
	
	rope.ResetTransform();
	rope.ScaleBy(Vec2f(ropelen,1.0f));	
	rope.TranslateBy(Vec2f(ropelen*16.0f,0.0f));	
	rope.RotateBy(-off.Angle() - blob.getAngleDegrees(), Vec2f());
	
	looseRope.ResetTransform();
	looseRope.ScaleBy(Vec2f(ropelen,1.0f));
	looseRope.TranslateBy(Vec2f(ropelen*16.0f,0.0f));	
	looseRope.RotateBy(-off.Angle() - blob.getAngleDegrees(), Vec2f());
	
	hook.ResetTransform();
	if (harpoon.grapple_id == 0xffff) //still in air
	{
		harpoon.cache_angle = -harpoon.grapple_vel.Angle() - blob.getAngleDegrees();
	}
	hook.RotateBy(harpoon.cache_angle, Vec2f());
	
	hook.TranslateBy(off.RotateBy(-blob.getAngleDegrees(), Vec2f()));
	hook.SetFacingLeft(false);
	
	GUI::DrawLine(blob.getPosition(), harpoon.grapple_pos, SColor(255,255,255,0));
}

bool checkGrappleStep(CBlob@ this, HarpoonInfo@ harpoon, CMap@ map, const f32 dist)
{
	AttachmentPoint@ seat = this.getAttachmentPoint(0);
	CBlob@ occupier = seat.getOccupied();
	
	Island@ thisIsland = getIsland(this.getShape().getVars().customData);

	if (map.getSectorAtPosition(harpoon.grapple_pos, "barrier") !is null) //red barrier
	{
		harpoon.grappling = false;
		SyncGrapple(this);
	
	}
	else
	{
		CBlob@ b = map.getBlobAtPosition(harpoon.grapple_pos);
		if (b !is null)
		{
			Island@ hitIsland = getIsland(b);
			if (b is this || b.getName() == "human" || (!b.hasTag("solid")))
			{
				//can't grapple self if not reeled in
				if (harpoon.grapple_ratio > 0.5f)
					return false;

				harpoon.grappling = false;
				SyncGrapple(this);

				directionalSoundPlay("HookReset.ogg", this.getPosition());

				return true;
			}
			else
			{
				//TODO: Maybe figure out a way to grapple moving blobs
				//		without massive desync + forces :)
				
				Vec2f velocity = harpoon.grapple_vel;			

				harpoon.grapple_id = b.getNetworkID();
				
				SyncGrapple(this);
				
				directionalSoundPlay("crowbar_impact2.ogg", harpoon.grapple_pos);
				sparks1(harpoon.grapple_pos, 0, 3.0f);
				
				return true;
			}
		}
	}

	return false;
}

bool shouldReleaseGrapple(CBlob@ this, HarpoonInfo@ harpoon, CMap@ map)
{
	AttachmentPoint@ seat = this.getAttachmentPoint(0);
	CBlob@ occupier = seat.getOccupied();
	
	if (occupier !is null)
		return occupier.isKeyPressed(key_action2);

	return false;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{   
	HarpoonInfo@ harpoon;
	if (!this.get("harpoonInfo", @harpoon)) 
		return;
	
	CSpriteLayer@ layer = this.getSprite().getSpriteLayer("harpoon");
	
    if ((harpoon.grapple_pos - caller.getPosition()).getLength() > 16.0f || this.getShape().getVars().customData <= 0)
        return;

    if (harpoon.grapple_id != 0xffff && harpoon.grapple_id != 0 && !layer.isAnimation("set"))
	{
        CButton@ unhookButton = caller.CreateGenericButton(1, (harpoon.grapple_pos - this.getPosition())*0.5f, this, this.getCommandID("unhook"), "Unhook Harpoon");
		if (unhookButton !is null) unhookButton.radius = 3.3f; //engine fix
	}
}
