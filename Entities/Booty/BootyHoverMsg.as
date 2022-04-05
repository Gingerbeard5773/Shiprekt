// thanks to Splittingred
#define CLIENT_ONLY
#include "HoverMessageShiprekt.as";
#include "ActorHUDStartPos.as"
int oldBooty = 0;

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	CPlayer@ player = blob.getPlayer();
	
	if (player is null || !player.isMyPlayer())
		return;
	
	CRules@ rules = getRules();
	string userName = player.getUsername();
	u16 currentBooty = rules.get_u16("booty" + userName);
	int diff = currentBooty - oldBooty;
	oldBooty = currentBooty;

	if (diff > 0)
		bootyIncrease(blob, diff); //set message
	else if (diff < 0)
		bootyDecrease(blob, diff); //set message
	
    HoverMessageShiprekt2[]@ messages;
    if (blob.get("messages", @messages))
	{
        for (uint i = 0; i < messages.length; i++)
		{
            HoverMessageShiprekt2 @message = messages[i];
            message.draw(getActorHUDStartPosition(blob, 6) +  Vec2f(70 , -4));

            if (message.isExpired())
			{
                messages.removeAt(i);
            }
        }
    }
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	HoverMessageShiprekt2[]@ messages;	
	if (blob.get("messages",@messages))
	{
		for (uint i = 0; i < messages.length; i++)
		{
			HoverMessageShiprekt2 @message = messages[i];
			message.draw(getActorHUDStartPosition(blob, 6) +  Vec2f(70 , -4));
		}
	}
}

void bootyIncrease(CBlob@ this, int ammount)
{
	if (this.isMyPlayer())
	{
		if (!this.exists("messages"))
		{
			HoverMessageShiprekt2[] messages;
			this.set("messages", messages);
		}

		this.clear("messages");
		HoverMessageShiprekt2 m("", ammount, SColor(255, 0, 255, 0), 50, 3, false, "+");
		this.push("messages", m);
	}
}

void bootyDecrease(CBlob@ this, int ammount)
{
	if (this.isMyPlayer())
	{
		if (!this.exists("messages"))
		{
			HoverMessageShiprekt2[] messages;
			this.set("messages", messages);
		}

		this.clear("messages");
		HoverMessageShiprekt2 m("", ammount, SColor(255,255,0,0), 50, 3);
		this.push("messages", m);
	}
}
