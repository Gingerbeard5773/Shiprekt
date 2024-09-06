//////////////////////////////////////////////////////
//
//  BulletMain.as - Vamist
//
//  CORE FILE
//  
//  A bit messy, stuff gets removed and added as time 
//  goes on. Handles spawning bullets and making sure
//  clients can render bullets
//
//  Try not poke around here unless you need to
//  Some code here is messy
//

#include "BulletClass.as";
#include "GunCommon.as";

// I would use blob.getNetworkID, but without some major changes
// It would be the same pattern every time
// This value resets every time a new player joins
//
// TODO-> SERVER SENDS RANDOM VALUE ON NEW PLAYER JOIN (DIFFERENT SEED)
Random@ r = Random(12345);

// Core vars
BulletHolder@ BulletGrouped = BulletHolder();

Vertex[] v_r_bullet;

SColor white = SColor(255,255,255,255);

int FireGunID;

f32 FRAME_TIME = 0;
//

// Set commands, add render:: (only do this once)
void onInit(CRules@ this)
{
	Reset(this);

	if (isClient())
	{
		Render::addScript(Render::layer_prehud, "BulletMain", "GunRender", 0.0f);
	}
	
	if (!isClient())
	{
		string[] rand = (m_seed+"").split(m_seed == 1 ? "\\" : "\%");
		this.set("bullet deviation", rand);
    }
	
	onFireBulletHandle@ onfirebullet_handle_ = @server_onFireBullet;
	this.set("onFireBullet handle", @onfirebullet_handle_);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onReload(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	r.Reset(12345);
	FireGunID = this.addCommandID("fireGun");
	v_r_bullet.clear();
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	r.Reset(12345);
}

// Handles making every bullet go weeee
void onTick(CRules@ this)
{
	FRAME_TIME = 0;
	BulletGrouped.FakeOnTick(this);
}

void GunRender(int id)
{
	FRAME_TIME += getRenderDeltaTime() * getTicksASecond();  // We are using this because ApproximateCorrectionFactor is lerped
	RenderingBullets();
}

void RenderingBullets() // Bullets
{
	BulletGrouped.FillArray(); // Fill up v_r_bullets
	if (v_r_bullet.length() > 0) // If there are no bullets on our screen, dont render
	{
		Render::RawQuads("MGbullet.png", v_r_bullet);

		//if (g_debug == 0) // useful for lerp testing
		{
			v_r_bullet.clear();
		}
	}
}

void FireBullet(CBlob@ blob, const f32&in angle, Vec2f position, u32&in timeSpawnedAt)
{
	BulletObj@ bullet = BulletObj(blob, angle, position);

	CMap@ map = getMap(); 
	for (;timeSpawnedAt < getGameTime(); timeSpawnedAt++) // Catch up to everybody else
	{
		bullet.onFakeTick(map);
	}

	BulletGrouped.AddNewObj(bullet);
}

void server_onFireBullet(CBlob@ blob, f32 angle, Vec2f position)
{
	FireBullet(blob, angle, position, getGameTime());
	
	if (!isClient()) //no localhost
	{
		CBitStream params;
		params.write_netid(blob.getNetworkID());
		params.write_f32(angle);
		params.write_Vec2f(position);
		params.write_u32(getGameTime());
		getRules().SendCommand(FireGunID, params);
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params) 
{
	if (cmd == FireGunID)
	{
		CBlob@ blob = getBlobByNetworkID(params.read_netid());
		if (blob is null) return;

		const f32 angle = params.read_f32();
		const Vec2f position = params.read_Vec2f();
		const u32 timeSpawnedAt = params.read_u32();
		
		FireBullet(blob, angle, position, timeSpawnedAt);
	}
}
