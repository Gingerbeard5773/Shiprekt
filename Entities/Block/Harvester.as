#include "WaterEffects.as"
#include "BlockCommon.as"
#include "IslandsCommon.as"
#include "Booty.as"
#include "AccurateSoundPlay.as"
 
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
	this.addCommandID("disable");
   
	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ layer = sprite.addSpriteLayer("weapon", 16, 16);
    if (layer !is null)
    {
        layer.SetRelativeZ(2);
        layer.SetLighting( false );
        Animation@ anim = layer.addAnimation("fire", Maths::Round( DECONSTRUCT_RATE ), false);
        anim.AddFrame(Block::HARVESTER_A2);
        anim.AddFrame(Block::HARVESTER_A1);

		Animation@ anim3 = layer.addAnimation("default", 1, false);
		anim3.AddFrame(Block::HARVESTER_A1);
        layer.SetAnimation("default");  
    }
	
	sprite.SetEmitSound("/ReclaimSound.ogg");
	sprite.SetEmitSoundVolume(0.5f);
	sprite.SetEmitSoundPaused(true);
 
	this.set_u32("fire time", 0);
}
 
void onTick( CBlob@ this )
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
	
	//don't shoot if docked on mothership
	if (isServer() && (gameTime + this.getNetworkID() * 33) % 15 == 0)//every 1 sec
	{	
		Island@ isle = getIsland(this.getShape().getVars().customData);
		if (isle !is null)
		{
			if (isle.isMothership)
			{			
				//don't shoot if docked on mothership
				//CBlob@ core = getMothership( this.getTeamNum() );
				//if ( core !is null )
				//	this.set_bool( "mShipDocked", !coreLinkedDirectional( this, gameTime, core.getPosition() ) ); //very buggy
				this.set_bool("mShipDocked", false);
			} 
			else
				this.set_bool("mShipDocked", false);
		}
	}
}
 
bool canShoot(CBlob@ this)
{
	return (this.get_u32("fire time") + DECONSTRUCT_RATE < getGameTime());
}
 
void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("fire"))
    {
		if (!canShoot(this)) return;
		
		u16 shooterID;
		if (!params.saferead_u16(shooterID)) return;
			
		CBlob@ shooter = getBlobByNetworkID( shooterID );
		if (shooter is null) return;
		
		Island@ island = getIsland( this.getShape().getVars().customData );
		if (island is null) return;

		this.set_u32("fire time", getGameTime());
			
		//effects
		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ layer = sprite.getSpriteLayer("weapon");
		layer.SetAnimation("default");
	   
		Vec2f aimVector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());
		   		
		Vec2f barrelPos = this.getPosition();

		//hit stuff		
		u8 teamNum = shooter.getTeamNum();//teamNum of the player firing
		HitInfo@[] hitInfos;
		CMap@ map = this.getMap();
		bool killed = false;
		bool blocked = false;
			
		if (map.getHitInfosFromRay( barrelPos, -aimVector.Angle(), BULLET_RANGE, this, @hitInfos))
			for (uint i = 0; i < hitInfos.length; i++)
			{
				HitInfo@ hi = hitInfos[i];
				CBlob@ b = hi.blob;	  
				if (b is null || b is this) continue;

				const int color = b.getShape().getVars().customData;
				const int blockType = b.getSprite().getFrame();
				const bool isBlock = b.getName() == "block";

				if (isBlock)
				{
					killed = true;
					
					if (isClient())//effects
					{
						sprite.RemoveSpriteLayer("laser");
						CSpriteLayer@ laser = sprite.addSpriteLayer("laser", "ReclaimBeam.png", 16, 16);
						if (laser !is null)//partial length laser
						{
							Animation@ anim = laser.addAnimation( "default", 1, false );
							int[] frames = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
							anim.AddFrames(frames);
							laser.SetVisible(true);
							f32 laserLength = Maths::Max(0.1f, (hi.hitpos - barrelPos).getLength() / 16.0f);						
							laser.ResetTransform();						
							laser.ScaleBy(Vec2f(laserLength, 1.0f));							
							laser.TranslateBy( Vec2f(laserLength*8.0f, 0.0f));							
							laser.RotateBy(0.0f, Vec2f());
							laser.setRenderStyle(RenderStyle::light);
							laser.SetRelativeZ(1);
						}

						hitEffects(b, hi.hitpos);
					}			
								
					CPlayer@ thisPlayer = shooter.getPlayer();						
					if (thisPlayer is null) return;		
					
					Vec2f aimVector = hi.hitpos - barrelPos;	 
					
					if (b !is null)
					{		
						CRules@ rules = getRules();
						const int blockType = b.getSprite().getFrame();

						if (blockType == Block::STATION || blockType == Block::MINISTATION) continue;

						Island@ island = getIsland(b.getShape().getVars().customData);
							
						const f32 bCost = b.get_u32("cost");
						f32 bHealth = b.getHealth();
						f32 bInitHealth = b.getInitialHealth();
						const f32 initialReclaim = b.get_f32("initial reclaim");
						f32 currentReclaim = b.get_f32("current reclaim");
						
						f32 fullConstructAmount;
						if (bCost > 0)
							fullConstructAmount = (CONSTRUCT_VALUE/bCost)*initialReclaim;
						else
							fullConstructAmount = 0.0f;
										
						if (island !is null && bCost > 0)
						{
							string islandOwnerName = island.owner;
							CBlob@ mBlobOwnerBlob = getBlobByNetworkID(b.get_u16("ownerID"));
							
							if (!(blockType == Block::MOTHERSHIP5))
							{
								f32 deconstructAmount = 0;
								if ( (islandOwnerName == "" && !island.isMothership)
									|| (islandOwnerName == "" && b.get_string( "playerOwner" ) == "")
									|| (islandOwnerName == thisPlayer.getUsername())
									|| (b.get_string( "playerOwner" ) == thisPlayer.getUsername()))
								{
									deconstructAmount = fullConstructAmount; 
								}
								else
								{
									deconstructAmount = (1.0f/bCost)*initialReclaim;
								}				
								
								if ((currentReclaim - deconstructAmount) <= 0)
								{
									string cName = thisPlayer.getUsername();
									u16 cBooty = server_getPlayerBooty( cName );

									server_setPlayerBooty(cName, cBooty + bCost*(bHealth/bInitHealth));
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
		
		if (!blocked)
		{
			if (sprite.getEmitSoundPaused())
			{
				sprite.SetEmitSoundPaused(false);
			}
		}
		
		if (!killed && isClient())//full length 'laser'
		{
			sprite.RemoveSpriteLayer("laser");
			CSpriteLayer@ laser = sprite.addSpriteLayer("laser", "ReclaimBeam.png", 16, 16);
			if (laser !is null)
			{
				Animation@ anim = laser.addAnimation( "default", 1, false );
				int[] frames = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
				anim.AddFrames(frames);
				laser.SetVisible(true);
				f32 laserLength = Maths::Max(0.1f, (aimVector * (BULLET_RANGE)).getLength() / 16.0f);						
				laser.ResetTransform();						
				laser.ScaleBy( Vec2f(laserLength, 1.0f) );							
				laser.TranslateBy( Vec2f(laserLength*8.0f, 0.0f) );								
				laser.RotateBy(0.0f, Vec2f());
				laser.setRenderStyle(RenderStyle::light);
				laser.SetRelativeZ(1);
			}
			
			MakeWaterParticle(barrelPos + aimVector * (BULLET_RANGE), Vec2f_zero);
		}
    }
}

void hitEffects(CBlob@ hitBlob, Vec2f worldPoint)
{
	CSprite@ sprite = hitBlob.getSprite();
	const int blockType = sprite.getFrame();

	sparks(worldPoint, 4);
}

void sparks(Vec2f pos, int amount)
{
	Random _sprk_r;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 1.0f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixel( pos, vel, SColor( 255, 255, 128+_sprk_r.NextRanged(128), _sprk_r.NextRanged(128)), true );
        if (p is null) return; //bail if we stop getting particles

        p.timeout = 10 + _sprk_r.NextRanged(20);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.95f;
    }
}
