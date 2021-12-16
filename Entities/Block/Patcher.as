#include "WaterEffects.as";
#include "BlockCommon.as";
#include "IslandsCommon.as";
#include "Booty.as";
#include "AccurateSoundPlay.as";
#include "TileCommon.as";
#include "ParticleSparks.as";
 
const f32 BULLET_RANGE = 100.0f;
const f32 CONSTRUCT_RATE = 14.0f; //higher values = higher recover
const int CONSTRUCT_VALUE = 5;
const int NUM_HEALS = 5;

Random _shotspreadrandom(0x11598); //clientside

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 2;

	this.Tag("weapon");
	this.Tag("machinegun");
	this.Tag("fixed_gun");
	this.addCommandID("fire");
	this.addCommandID("disable");
   
	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ layer = sprite.addSpriteLayer("weapon", 16, 16);
    if (layer !is null)
    {
        layer.SetRelativeZ(2);
        layer.SetLighting(false);
        layer.SetFrame(Block::PATCHER_A1);  
    }
	
	sprite.SetEmitSound("/ReclaimSound.ogg");
	sprite.SetEmitSoundVolume(0.5f);
	sprite.SetEmitSoundPaused(true);
 
	this.set_u32("fire time", 0);
}
 
void onTick(CBlob@ this)
{
	if (this.getShape().getVars().customData <= 0 )//not placed yet
		return;
		
	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ laser = sprite.getSpriteLayer("laser");
	
	//kill laser after a certain time
	if (laser !is null && this.get_u32("fire time") + CONSTRUCT_RATE < getGameTime())
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
	return (this.get_u32("fire time") + CONSTRUCT_RATE < getGameTime());
}
 
void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("fire"))
    {
		if (!canShoot(this))
			return;
		
		u16 shooterID;
		if (!params.saferead_u16(shooterID))
			return;
			
		CBlob@ shooter = getBlobByNetworkID(shooterID);
		if (shooter is null)
			return;
		
		Island@ island = getIsland(this.getShape().getVars().customData);
		if (island is null)
			return;

		this.set_u32("fire time", getGameTime());
			
		//effects
		CSprite@ sprite = this.getSprite();
	   
		Vec2f aimVector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());
		   		
		Vec2f barrelPos = this.getPosition();

		//hit stuff		
		HitInfo@[] hitInfos;
		u8 count = 0;
			
		if (getMap().getHitInfosFromRay(barrelPos, -aimVector.Angle(), BULLET_RANGE, this, @hitInfos))
		{
			for (uint i = 0; i < hitInfos.length; i++)
			{
				HitInfo@ hi = hitInfos[i];
				CBlob@ b = hi.blob;	  
				if (b is null || b is this) continue;

				const int color = b.getShape().getVars().customData;
				const int blockType = b.getSprite().getFrame();
				const bool isBlock = b.getName() == "block";


				if (isBlock && color > 0)
				{					
					if (isClient())//effects
					{
						sparks(hi.hitpos, 4);
					}			

					if (count >= NUM_HEALS) continue;
								
					CPlayer@ thisPlayer = shooter.getPlayer();						
					if (thisPlayer is null) 
						return;		
					
					Island@ otherIsland = getIsland(color);
					bool isMyShip = otherIsland !is null && otherIsland is island;
 
					f32 reconstructAmount = 0;
					u16 reconstructCost = 0;
					string cName = thisPlayer.getUsername();
					u16 cBooty = server_getPlayerBooty(cName);
					f32 mBlobHealth = b.getHealth();
					f32 mMaxHealth = b.getInitialHealth();
					const f32 mBlobCost = Block::getCost(blockType) > 0 ? Block::getCost(blockType) : 15;
					const f32 initialReclaim = b.get_f32("initial reclaim");
					f32 currentReclaim = b.get_f32("current reclaim");

					f32 fullConstructAmount;
					if (blockType != Block::MOTHERSHIP5)
						fullConstructAmount = Maths::Min(1.0f, CONSTRUCT_VALUE/mBlobCost)*initialReclaim;
					else
						fullConstructAmount = (0.01f)*mMaxHealth; //mothership
					
					if (blockType == Block::MOTHERSHIP5)
					{
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
						
						if (mBlobHealth < mMaxHealth)
							reconstructCost *= isMyShip ? 1.0f : 0.20f;
						else
							reconstructCost = 0;

						if (cBooty >= reconstructCost && mBlobHealth < motherInitHealth)
						{
							b.server_SetHealth(mBlobHealth + reconstructAmount);
							server_addPlayerBooty(cName, -reconstructCost);
						}
					}
					else if (blockType == Block::STATION || blockType == Block::MINISTATION)
					{							
						if ((currentReclaim + reconstructAmount) <= initialReclaim)
						{
							reconstructAmount = fullConstructAmount;
							reconstructCost = CONSTRUCT_VALUE;
						}
						else if ((currentReclaim + reconstructAmount) > initialReclaim)
						{
							reconstructAmount = initialReclaim - currentReclaim;
							reconstructCost = CONSTRUCT_VALUE - CONSTRUCT_VALUE*(reconstructAmount/fullConstructAmount);
							
							if (mBlobHealth < mMaxHealth)
								reconstructCost *= isMyShip ? 1.0f : 0.20f;
							else
								reconstructCost = 0;

							if (b.getTeamNum() == 255) //neutral
							{
								b.server_setTeamNum(this.getTeamNum());
								b.getSprite().SetFrame(blockType);
							}
						}
						
						b.set_f32("current reclaim", Maths::Min(mMaxHealth, currentReclaim + reconstructAmount));
					}
					else if (currentReclaim < initialReclaim)
					{					
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
						
						if (mBlobHealth < mMaxHealth)
							reconstructCost *= isMyShip ? 1.0f : 0.20f;
						else
							reconstructCost = 0;

						if (cBooty >= reconstructCost)
						{
							b.server_SetHealth( Maths::Min(mMaxHealth, mBlobHealth + reconstructAmount));
							b.set_f32("current reclaim", Maths::Min(mMaxHealth, currentReclaim + reconstructAmount));
							server_addPlayerBooty(cName, -reconstructCost);
							count++;
						}
						else if ((currentReclaim + reconstructAmount) < mBlobHealth)
							b.set_f32("current reclaim", Maths::Min(mMaxHealth, currentReclaim + reconstructAmount));
					}
				}
			}
		}
		
		if (sprite.getEmitSoundPaused())
		{
			sprite.SetEmitSoundPaused(false);
		}

		if (isClient())//full length 'laser'
		{
			setLaser(sprite, aimVector * (BULLET_RANGE));
		}
    }
}

void setLaser(CSprite@ this, Vec2f lengthPos)
{
	this.RemoveSpriteLayer("laser");
	CSpriteLayer@ laser = this.addSpriteLayer("laser", "repairBeam.png", 16, 16);
	if (laser !is null)
	{
		Animation@ anim = laser.addAnimation("default", 1, false);
		int[] frames = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
		anim.AddFrames(frames);
		laser.SetVisible(true);
		f32 laserLength = Maths::Max(0.1f, (lengthPos).getLength() / 16.0f);						
		laser.ResetTransform();						
		laser.ScaleBy(Vec2f(laserLength, 1.0f));							
		laser.TranslateBy( Vec2f(laserLength*8.0f, 0.0f));								
		laser.RotateBy(0.0f, Vec2f());
		laser.setRenderStyle(RenderStyle::light);
		laser.SetRelativeZ(1);
	}
}