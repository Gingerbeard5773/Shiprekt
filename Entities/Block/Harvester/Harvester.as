#include "WaterEffects.as";
#include "BlockCommon.as";
#include "IslandsCommon.as";
#include "Booty.as";
#include "AccurateSoundPlay.as";
#include "TileCommon.as";
#include "ParticleSparks.as";
 
const f32 BULLET_RANGE = 100.0f;
const f32 DECONSTRUCT_RATE = 10.0f; //higher values = higher recover
const int CONSTRUCT_VALUE = 50;

Random _shotspreadrandom(0x11598); //clientside

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 2;

	this.Tag("weapon");
	this.Tag("machinegun");
	this.Tag("fixed_gun");
	this.addCommandID("fire");
   
	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ layer = sprite.addSpriteLayer("weapon", "Harvester.png", 16, 16);
    if (layer !is null)
    {
        layer.SetRelativeZ(2);
        layer.SetLighting(false);
    }
	
	sprite.SetEmitSound("/ReclaimSound.ogg");
	sprite.SetEmitSoundVolume(0.5f);
	sprite.SetEmitSoundPaused(true);
 
	this.set_u32("fire time", 0);
}
 
void onTick(CBlob@ this)
{
	if (this.getShape().getVars().customData <= 0)//not placed yet
		return;
		
	u32 gameTime = getGameTime();
	
	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ laser = sprite.getSpriteLayer("laser");
	
	//kill laser after a certain time
	if (laser !is null && this.get_u32("fire time") + DECONSTRUCT_RATE < gameTime)
	{
		if (!sprite.getEmitSoundPaused())
		{
			sprite.SetEmitSoundPaused(true);
		}	
		sprite.RemoveSpriteLayer("laser");
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
		
		Island@ island = getIsland(this.getShape().getVars().customData);
		if (island is null) return;

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

				const int blockType = b.getSprite().getFrame();

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
					
					if (b !is null)
					{
						if (blockType == Block::STATION || blockType == Block::MINISTATION) continue;

						Island@ island = getIsland(b.getShape().getVars().customData);

						const f32 bCost = Block::getCost(blockType) > 0 ? Block::getCost(blockType) : 15;
						f32 bHealth = b.getHealth();
						f32 bInitHealth = b.getInitialHealth();
						const f32 initialReclaim = b.get_f32("initial reclaim");
						f32 currentReclaim = b.get_f32("current reclaim");
						
						f32 fullConstructAmount = (CONSTRUCT_VALUE/bCost)*initialReclaim; //fastest reclaim possible

						if (island !is null && bCost > 0)
						{
							string islandOwnerName = island.owner;
							
							if (blockType != Block::MOTHERSHIP5)
							{
								f32 deconstructAmount = 0;
								if ((islandOwnerName == "" && !island.isMothership) //true if no owner for island and island is not a mothership
									|| (b.get_string("playerOwner") == "" && !island.isMothership) //true if no owner for the block and is not on a mothership
									|| (islandOwnerName == thisPlayer.getUsername()) //true if we own the island
									|| (b.get_string("playerOwner") == thisPlayer.getUsername())) //true if we own the specific block
								{
									deconstructAmount = fullConstructAmount; 
								}
								else
								{
									deconstructAmount = (1.0f/bCost)*initialReclaim; //slower reclaim
								}

								if ((currentReclaim - deconstructAmount) <= 0)
								{
									string cName = thisPlayer.getUsername();

									server_addPlayerBooty(cName, bCost*(bHealth/bInitHealth));
									directionalSoundPlay("/ChaChing.ogg", barrelPos);

									b.Tag("disabled");
									b.server_Die();
								}
								else
									b.set_f32("current reclaim", currentReclaim - deconstructAmount);
							}
						}
					}				
					if (killed) break;
				}
			}
		}

		if (!blocked)
		{
			if (sprite.getEmitSoundPaused())
			{
				sprite.SetEmitSoundPaused(false);
			}
		}

		if (!killed && isClient())//full length 'laser'
		{
			setLaser(sprite, aimVector * BULLET_RANGE);
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