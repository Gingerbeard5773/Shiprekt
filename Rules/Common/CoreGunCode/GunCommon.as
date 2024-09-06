funcdef void onFireBulletHandle(CBlob@, f32, Vec2f);

void server_FireBullet(CBlob@ blob, const f32&in angle, const Vec2f&in position) 
{
	CRules@ rules = getRules();

	onFireBulletHandle@ onfirebullet_handle;
	if (rules.get("onFireBullet handle", @onfirebullet_handle))
	{
		onfirebullet_handle(blob, angle, position);
	}
}
