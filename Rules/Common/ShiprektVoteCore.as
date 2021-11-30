
//voting generic update and render

#include "ShiprektVoteCommon.as"

//extended vote functionality

//globals
const float _vis_width = 400.0f;

Vec2f getTopLeft()
{
	return Vec2f(getScreenWidth()*0.45f - _vis_width*0.5f, getScreenHeight() - 195 - getFloatingBox());
}

float getFloatingBox()
{
	return ((Maths::Sin(getGameTime() / 10.0f) + 1.0f) * 3.0f);
}

/**
 * get the rectangle for clicking, the votes will be on either side of this
 */
void getClickRectangle(Vec2f &out top, Vec2f &out bottom)
{
	top = Vec2f(getTopLeft().x + 15, getTopLeft().y + 30);
	bottom = top + Vec2f(_vis_width-30, 40);
}

/**
 * get the position for abstain and cancel buttons from topleft
 */

void getExtraPositions(Vec2f tl, bool can_cancel, Vec2f &out abstain, Vec2f &out cancel)
{
	if(can_cancel)
	{
		abstain = tl + Vec2f(_vis_width*0.25f, 115);
		cancel = abstain + Vec2f(_vis_width*0.5f, 0);
	}
	else
	{
		abstain = tl + Vec2f(_vis_width*0.5f, 115);
		cancel = Vec2f();
	}
}


void RenderVote(VoteObject@ vote)
{
	if(vote.timeremaining > 0)
	{
		Vec2f tl = getTopLeft();
		Vec2f top = Vec2f(tl.x, tl.y);
		Vec2f bottom = top + Vec2f(_vis_width, 130);

		Vec2f abstain, cancel;
		const bool can_cancel = getSecurity().checkAccess_Feature(getLocalPlayer(), "vote_cancel");
		getExtraPositions(tl, can_cancel, abstain, cancel);
		
		if(!CanPlayerVote(vote,getLocalPlayer()))
		{
			top.x += _vis_width*0.2f;
			bottom.x -= _vis_width*0.2f;
			top.y += 80;
			
			GUI::DrawButtonPressed( top - Vec2f(10,10), bottom + Vec2f(10,10) );
			GUI::DrawText( " Voting In Progress...   ("+Maths::Ceil(vote.timeremaining/30.0f) +"s)\n" ,
				top+Vec2f(10,0), bottom, color_white, true, true, false );
		}
		else if(!g_have_voted)
		{
			//build vote display

			//bounds
			GUI::DrawButtonPressed(top - Vec2f(10, 10), bottom + Vec2f(10, 10));
					
			//alert!	
			int _modtime = getGameTime() % 100;
			if(_modtime <= 50)
			{
				GUI::DrawText( "!! Vote In Progress !!" ,
					top + Vec2f(_vis_width*0.3f,0), bottom, color_white, true, true, false );
			}
			else
			{
				GUI::DrawText( "!! Click To Vote !!" ,
					top + Vec2f(_vis_width*0.34f,0), bottom, color_white, true, true, false );
			}
			
			//caster and time remaining
			GUI::DrawText( "Cast by: " + vote.byuser ,
				top + Vec2f(_vis_width*0.5f,80), bottom, color_white, true, true, false );
			
			GUI::DrawText( "Time Remaining: " +  Maths::Ceil(vote.timeremaining/30.0f) +"s.",
				top + Vec2f(0,80), bottom, color_white, true, true, false );

			Vec2f _top, _bottom;
			getClickRectangle(_top, _bottom);

			//positive action
			{
				_top.x -= 7.0f;
				_bottom = _top + Vec2f(_vis_width*0.5f - 15, 30);
				GUI::DrawButton(_top - Vec2f(10, 10), _bottom + Vec2f(10, 10));
				GUI::DrawText(vote.succeedaction,
					_top, _bottom, color_white, true, true, false);
			}

			//negative action
			{
				_top.x += 15.0f;
				_top = _top + Vec2f(_vis_width*0.5f, 0);
				_bottom = _top + Vec2f(_vis_width*0.5f - 30, 30);
				GUI::DrawButton(_top - Vec2f(10, 10), _bottom + Vec2f(10, 10));
				GUI::DrawText(vote.failaction,
					_top, _bottom, color_white, true, true, false);
			}
			
			//abstain action
			{
				GUI::DrawButton(abstain - Vec2f(60, 15), abstain + Vec2f(60, 15));
				GUI::DrawText("Abstain",
					abstain - Vec2f(50, 10), abstain + Vec2f(50, 10), color_white, true, true, false);
			}

			//cancel action
			if(can_cancel)
			{
				GUI::DrawButton(cancel - Vec2f(60, 15), cancel + Vec2f(60, 15));
				GUI::DrawText(vote.cancelaction,
					cancel - Vec2f(50, 10), cancel + Vec2f(50, 10), color_white, true, true, false);
			}
			
			
		}
		else
		{
			top.x += _vis_width*0.2f;
			bottom.x -= _vis_width*0.2f;
			top.y += 80;
			
			s32 move_down = (getGameTime() - g_vote_timevar) / 3;
			
			top.y += move_down;
			bottom.y += move_down;
			
			if(bottom.y < getScreenHeight())
			{
				GUI::DrawButtonPressed( top - Vec2f(10,10), bottom + Vec2f(10,10) );
				GUI::DrawText( " Thanks For Voting!   ("+Maths::Ceil(vote.timeremaining/30.0f) +"s)\n" ,
					top+Vec2f(10,0), bottom, color_white, true, true, false );
			}
		}
	}
}


void UpdateVote(VoteObject@ vote)
{
	if(vote.timeremaining > 0)
	{
		vote.timeremaining--;
		
		CRules@ rules = getRules();
		
		CalculateVoteThresholds(vote);
		
		if(getNet().isServer() && (
			//time up
			(vote.timeremaining == 0) ||
			//decision made
			Vote_Conclusive(vote) ) )
		{
			PassVote(vote); //pass it serverside
			
			CBitStream params;
			rules.SendCommand(rules.getCommandID(voteend_id), params);
		}
		
		CPlayer@ localplayer = getLocalPlayer();
		
		if (getNet().isClient() && CanPlayerVote(vote, localplayer) && !g_have_voted)
		{
			u16 id = 0xffff;
			if(localplayer !is null)
				id = getLocalPlayer().getNetworkID();
			
			bool voted = false;
			bool favour = true;
			
			CControls@ controls = getControls();
			if(controls !is null)
			{
				//Geti | heres how it checks the click
				if( controls.mousePressed1 )
				{
					Vec2f _top, _bottom;
					getClickRectangle(_top, _bottom);

					Vec2f abstain, cancel;
					const bool can_cancel = getSecurity().checkAccess_Feature(getLocalPlayer(), "vote_cancel");
					getExtraPositions(getTopLeft(), can_cancel, abstain, cancel);

					Vec2f mousepos = controls.getMouseScreenPos();
					
					//clicking on the vote buttons
					if(mousepos.x > _top.x && mousepos.y > (_top.y - 10) &&
						mousepos.x < _bottom.x && mousepos.y < _bottom.y)
					{
						voted = true;
						if(mousepos.x > (_top.x + _bottom.x)*0.5f)
						{
							favour = false;
						}
					}
					//clicking the cancel button
					else if(can_cancel &&
							Maths::Abs(cancel.x - mousepos.x) < 60 &&
							Maths::Abs(cancel.y - mousepos.y) < 15)
					{
						CBitStream params;
						params.write_u16(id);
						rules.SendCommand(rules.getCommandID(votecancel_id), params);
					}
					//clicking the abstain button
					else if(Maths::Abs(abstain.x - mousepos.x) < 60 &&
							Maths::Abs(abstain.y - mousepos.y) < 15)
					{
						g_have_voted = true;
						g_vote_timevar = getGameTime()-300;
					}
				}
			}
			
			if(voted)
			{
				CBitStream params;
				params.write_u16(id);
				rules.SendCommand(rules.getCommandID(favour ? voteyes_id : voteno_id), params);
				
				g_have_voted = true;
				g_vote_timevar = getGameTime();
			}
		}
	}
}


//hooks

void onRender( CRules@ this )
{
	if(Rules_AlreadyHasVote(this))
	{
		VoteObject@ vote = Rules_getVote(this);
		RenderVote(vote);
	}
}

bool g_have_voted = false;
s32 g_vote_timevar = 0;

void onTick( CRules@ this )
{
	if(Rules_AlreadyHasVote(this))
	{
		UpdateVote(Rules_getVote(this));
	}
	else
	{
		g_have_voted = false;
		g_vote_timevar = getGameTime();
	}
}

const string voteyes_id = "_vote: yes";		//client "yes" vote
const string voteno_id = "_vote: no";		//client "no" vote
const string voteend_id = "_vote: ended";	//server "vote over"
const string votecancel_id = "_vote: cancel";

void onInit(CRules@ this)
{
	this.addCommandID(voteyes_id);
	this.addCommandID(voteno_id);
	this.addCommandID(voteend_id);
	this.addCommandID(votecancel_id);
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	//always allow passing the vote, even if its expired
	if(cmd == this.getCommandID(voteend_id))
	{
		PassVote(Rules_getVote(this));
	}
	
	if(!Rules_AlreadyHasVote(this)) return;
	
	VoteObject@ vote = Rules_getVote(this);
	u16 id;
	
	if(cmd == this.getCommandID(voteyes_id))
	{
		if(!params.saferead_u16(id))
			return;
		
		CPlayer@ player = getPlayerByNetworkId(id);
		if(CanPlayerVote(vote, player ))
		{
			Vote(vote, player, true);
		}
	}
	else if(cmd == this.getCommandID(voteno_id))
	{
		if(!params.saferead_u16(id))
			return;
		
		CPlayer@ player = getPlayerByNetworkId(id);
		if(CanPlayerVote(vote, player ))
		{
			Vote(vote, player, false);
		}
	}
	else if (cmd == this.getCommandID(votecancel_id))
	{
		CancelVote(vote);
	}
}
