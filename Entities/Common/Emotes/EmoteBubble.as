// Draw an emoticon

#include "EmotesCommon.as";

void onInit(CBlob@ blob)
{
	blob.addCommandID("emote");

	CSprite@ sprite = blob.getSprite();
	blob.set_string("emote", "");
	blob.set_u32("emotetime", 0);

	dictionary@ packs;
	if (!getRules().get("emote packs", @packs)) return;
	string[] tokens = packs.getKeys();

	for (uint i = 0; i < tokens.size(); i++)
	{
		EmotePack@ pack;
		packs.get(tokens[i], @pack);

		//init emote layer
		CSpriteLayer@ layer = sprite.addSpriteLayer("bubble" + pack.token, pack.filePath, 32, 32, blob.getTeamNum(), 0);
		layer.SetIgnoreParentFacing(true);
		layer.SetFacingLeft(false);

		if (layer !is null)
		{
			layer.SetOffset(Vec2f(0, -sprite.getBlob().getRadius() * 1.5f - 16));
			layer.SetRelativeZ(100.0f);
			{
				Animation@ anim = layer.addAnimation("default", 0, true);

				for (int i = 0; i < pack.emotes.size(); i++)
				{
					anim.AddFrame(i);
				}
			}
			layer.SetVisible(false);
			layer.SetHUD(true);
		}
	}
}

void onTick(CBlob@ blob)
{
	blob.getCurrentScript().tickFrequency = 6;

	if (!blob.getShape().isStatic())
	{
		dictionary@ packs;
		if (!getRules().get("emote packs", @packs)) return;
		string[] tokens = packs.getKeys();

		const string emoteName = blob.get_string("emote");
		Emote@ emote = getEmote(emoteName);
		for (uint i = 0; i < tokens.size(); i++)
		{
			EmotePack@ pack;
			packs.get(tokens[i], @pack);

			CSpriteLayer@ layer = blob.getSprite().getSpriteLayer("bubble" + pack.token);
			if (layer is null) continue;

			bool visible = false;

			bool correctPack = emote !is null && emote.pack.token == pack.token;
			bool shouldDisplay = is_emote(blob);
			bool canDisplay = !blob.hasTag("dead") && !blob.isInInventory();

			if (correctPack && shouldDisplay && canDisplay)
			{
				blob.getCurrentScript().tickFrequency = 1;

				visible = !isMouseOverEmote(layer);
				layer.animation.frame = emote.index;

				layer.ResetTransform();
				layer.SetFacingLeft(false);

				CCamera@ camera = getCamera();
				if (camera !is null)
				{
					const bool isPointing = emoteName == "up" || emoteName == "down" || emoteName == "left" || emoteName == "right";
					if (isPointing)
					{
						Emote@ pointer = getEmote("up");
						if (pointer is null) return;

						layer.animation.frame = pointer.index;

						Vec2f aimVec;
						const int direction = blob.getAimDirection(aimVec);
						//const f32 camRotation = blob.isMyPlayer() ? camera.getRotation() : blob.get_f32("camera rotation");
						const f32 camRotation = camera.getRotation();
						Vec2f blobCamVec = Vec2f(0.0f, 1.0f);
							blobCamVec.RotateBy(camRotation);
						Vec2f localCamVec = Vec2f(0.0f, 1.0f);
							localCamVec.RotateBy(camera.getRotation());

						if (localCamVec.AngleWith(aimVec) < 0)
							layer.SetFacingLeft(true);

						const f32 angle = 180 + blobCamVec.AngleWith(aimVec) + camRotation - blob.getAngleDegrees();
						layer.RotateBy(angle, -layer.getOffset()); 
					}
					else
					{
						const f32 angle = camera.getRotation() - blob.getAngleDegrees();
						layer.RotateBy(angle, -layer.getOffset()); 
					}
				}
			}

			layer.SetVisible(visible);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	// For now, this is just a command for setting emote for crates
	if (cmd == this.getCommandID("emote") && isServer())
	{
		CPlayer@ p = getNet().getActiveCommandPlayer();
		if (p is null) return;

		CBlob@ b = p.getBlob();
		if (b is null) return;

		if (b !is this) return;

		if (this.isInInventory())
		{
			CBlob@ inventoryblob = this.getInventoryBlob();
			if (inventoryblob !is null && inventoryblob.getName() == "crate"
				&& inventoryblob.exists("emote"))
			{
				inventoryblob.set_string("emote", b.get_string("emote"));
				inventoryblob.Sync("emote", true);
				inventoryblob.set_u32("emotetime", b.get_u32("emotetime"));
				inventoryblob.Sync("emotetime", true);
			}
		}
	}
}
