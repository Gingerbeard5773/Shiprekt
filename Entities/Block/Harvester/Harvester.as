#include "WaterEffects.as";
#include "ShipsCommon.as";
#include "Booty.as";
#include "AccurateSoundPlay.as";
#include "TileCommon.as";
#include "ParticleSparks.as";
#include "BlockCosts.as";
 
const f32 BULLET_RANGE = 100.0f;
const f32 DECONSTRUCT_RATE = 10.0f; //higher values = higher recover
const int CONSTRUCT_VALUE = 50;

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 2;

	this.Tag("weapon");
	this.Tag("machinegun");
	this.Tag("fixed_gun");

	this.set_f32("weight", 2.0f);

	this.addCommandID("fire");

	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		sprite.SetRelativeZ(2);
		sprite.SetEmitSound("/ReclaimSound.ogg");
		sprite.SetEmitSoundVolume(0.5f);
		sprite.SetEmitSoundPaused(true);
	}

	this.set_u32("fire time", 0);
}
 
void onTick(CBlob@ this)
{
	if (this.getShape().getVars().customData <= 0)//not placed yet
		return;
	
	if (isClient())
	{
		//kill laser after a certain time
		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ laser = sprite.getSpriteLayer("laser");
		if (laser !is null && this.get_u32("fire time") + DECONSTRUCT_RATE < getGameTime())
		{
			if (!sprite.getEmitSoundPaused())
			{
				sprite.SetEmitSoundPaused(true);
			}
			sprite.RemoveSpriteLayer("laser");
		}
	}
}
 
bool canShoot(CBlob@ this)
{
	return (this.get_u32("fire time") + DECONSTRUCT_RATE < getGameTime());
}
 
void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("fire"))
    {
		if (!canShoot(this)) return;
		
		u16 shooterID;
		if (!params.saferead_u16(shooterID)) return;
			
		CBlob@ shooter = getBlobByNetworkID(shooterID);
		if (shooter is null) return;
		
		Ship@ ship = getShip(this.getShape().getVars().customData);
		if (ship is null) return;

		this.set_u32("fire time", getGameTime());
			
		//effects
		CSprite@ sprite = this.getSprite();
	   
		Vec2f aimVector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());
		
		Vec2f barrelPos = this.getPosition();

		//hit stuff
		HitInfo@[] hitInfos;
		bool killed = false;
		bool blocked = false;
			
		if (getMap().getHitInfosFromRay(barrelPos, -aimVector.Angle(), BULLET_RANGE, this, @hitInfos))
		{
			for (uint i = 0; i < hitInfos.length; i++)
			{
				HitInfo@ hi = hitInfos[i];
				CBlob@ b = hi.blob;	  
				if (b is null || b is this) continue;
				
				if (b.hasTag("station")) continue;

				if (b.hasTag("block") && b.getShape().getVars().customData > 0)
				{
					killed = true;
					
					if (isClient())//effects
					{
						setLaser(sprite, hi.hitpos - barrelPos);
						sparks(hi.hitpos, 4);
					}			

					CPlayer@ thisPlayer = shooter.getPlayer();						
					if (thisPlayer is null) return; 

					const f32 bCost = !b.hasTag("coupling") ? getCost(b.getName(), true) : 1;
					const f32 initialHealth = b.getInitialHealth();
					f32 currentReclaim = b.get_f32("current reclaim");

					Ship@ ship = getShip(b.getShape().getVars().customData);
					if (ship !is null && bCost > 0)
					{
						f32 fullConstructAmount = (CONSTRUCT_VALUE/bCost)*initialHealth; //fastest reclaim possible
						string shipOwnerName = ship.owner;
						
						if (!b.hasTag("mothership"))
						{
							f32 deconstructAmount = 0;
							if ((shipOwnerName == "" && !ship.isMothership) //true if no owner for ship and ship is not a mothership
								|| (b.get_string("playerOwner") == "" && !ship.isMothership) //true if no owner for the block and is not on a mothership
								|| (shipOwnerName == thisPlayer.getUsername()) //true if we own the ship
								|| (b.get_string("playerOwner") == thisPlayer.getUsername())) //true if we own the specific block
							{
								deconstructAmount = fullConstructAmount; 
							}
							else
							{
								deconstructAmount = (1.0f/bCost)*initialHealth; //slower reclaim
							}

							if ((currentReclaim - deconstructAmount) <= 0)
							{
								string cName = thisPlayer.getUsername();

								server_addPlayerBooty(cName, getCost(b.getName())*(b.getHealth()/initialHealth));
								directionalSoundPlay("/ChaChing.ogg", barrelPos);

								b.Tag("disabled");
								b.server_Die();
							}
							else
								b.set_f32("current reclaim", currentReclaim - deconstructAmount);
						}
					}			
					if (killed) break;
				}
			}
		}
		
		if (isClient())
		{
			if (!blocked)
			{
				if (sprite.getEmitSoundPaused())
				{
					sprite.SetEmitSoundPaused(false);
				}
			}

			if (!killed)//full length 'laser'
			{
				setLaser(sprite, aimVector * BULLET_RANGE);
			}
		}
    }
}

void setLaser(CSprite@ this, Vec2f lengthPos)
{
	this.RemoveSpriteLayer("laser");
	
	CSpriteLayer@ laser = this.addSpriteLayer("laser", "ReclaimBeam.png", 16, 16);
	if (laser !is null)
	{
		Animation@ anim = laser.addAnimation("default", 1, false);
		int[] frames = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
		anim.AddFrames(frames);
		laser.SetVisible(true);
		f32 laserLength = Maths::Max(0.1f, (lengthPos).getLength() / 16.0f);						
		laser.ResetTransform();						
		laser.ScaleBy(Vec2f(laserLength, 1.0f));							
		laser.TranslateBy(Vec2f(laserLength*8.0f, 0.0f));								
		laser.RotateBy(0.0f, Vec2f());
		laser.setRenderStyle(RenderStyle::light);
		laser.SetRelativeZ(1);
	}
}
