
/**
 * Vote functor interface
 * override 
 */
 
shared class VoteFunctor {
	VoteFunctor() {}
	void Pass(bool outcome) { /* do your vote action in here - remember to check server/client */ }
};

shared class VoteCheckFunctor {
	VoteCheckFunctor() {}
	bool PlayerCanVote(CPlayer@ player) { return true; }
};

/**
 * The vote object
 */
shared class VoteObject {
	
	VoteObject() {
		@onvotepassed = null;
		@canvote = null;
		maximum_votes = countrequired = getPlayersCount();
		current_yes = current_no = 0;
		timeremaining = 900; //default 30s
		required_percent = 0.5f; //default 50%
		passed = false; 
	}
	
	VoteFunctor@ onvotepassed;
	VoteCheckFunctor@ canvote;
	
	string succeedaction;
	string failaction;
	string cancelaction;
	
	string byuser;
	
	u16[] players; //id of players that have voted explicitly
	
	int countrequired;
	int current_yes;
	int current_no;
	int maximum_votes;
	
	float required_percent;
	
	bool passed; //flag so its just called once
	
	int timeremaining;
};

shared SColor vote_message_colour() { return SColor(0xff444444); }

void Rules_SetVote(CRules@ this, VoteObject@ vote)
{
	if(!Rules_AlreadyHasVote(this))
	{
		this.set("g_vote", vote);
		
		client_AddToChat( "--- A Vote was Started by "+vote.byuser+" ---", vote_message_colour() );
	}
}

VoteObject@ Rules_getVote(CRules@ this)
{
	VoteObject@ vote = null;
	this.get("g_vote", @vote);
	return vote;
}

bool Rules_AlreadyHasVote(CRules@ this)
{
	VoteObject@ tempvote = Rules_getVote(this);
	if(tempvote is null) return false;
	
	return tempvote.timeremaining > 0;
}

//vote methods

bool Vote_Conclusive(VoteObject@ vote)
{
	return (vote.current_yes >= vote.countrequired || 
			vote.current_no >= vote.countrequired);
}

bool Vote_WillPass(VoteObject@ vote)
{
	return (vote.current_yes >= vote.countrequired);
}

void PassVote(VoteObject@ vote)
{	
	if(vote is null || vote.timeremaining < 0) return;
	vote.timeremaining = -1; // so the gui hides and another vote can start

	if(vote.onvotepassed is null) return;
	bool outcome = vote.current_yes > vote.required_percent * (vote.current_yes + vote.current_no);
	
	client_AddToChat( "--- Vote "+(outcome? "passed: " : "failed: ")+
						(vote.current_yes)+" vs "+(vote.current_no)+
						" Must have 70+% yes votes in order to pass. ---", vote_message_colour() );
	vote.onvotepassed.Pass(outcome);
}

void CancelVote(VoteObject@ vote)
{
	vote.timeremaining = 0;
	client_AddToChat("--- Vote cancelled by an Admin ---", vote_message_colour());
}

/**
 * Check if a player should be allowed to vote - note that this
 * doesn't check if they already have voted
 */

bool CanPlayerVote(VoteObject@ vote, CPlayer@ player)
{
	if(player is null)
		return false;
	
	if(vote.canvote is null)
		return true;
	
	return vote.canvote.PlayerCanVote(player);
}

/**
 * Cast a vote from a player, in favour or against
 */
void Vote(VoteObject@ vote, CPlayer@ p, bool favour)
{
	bool voted = false;
	
	u16 p_id = p.getNetworkID();
	for(uint i = 0; i < vote.players.length; ++i)
	{
		if(vote.players[i] == p_id)
		{
			voted = true;
			break;
		}
	}
	
	if(voted)
	{
		//warning about exploits
		warning("double-vote from "+p.getUsername());
	}
	else
	{
		vote.players.push_back(p_id);
		if(favour)
		{
			vote.current_yes++;
		}
		else
		{
			vote.current_no++;
		}
		
		client_AddToChat( "--- "+p.getUsername()+" Voted "+(favour?"In Favour":"Against")+" ---", vote_message_colour() );
	}
	
}

void CalculateVoteThresholds(VoteObject@ vote)
{
	vote.maximum_votes = 0;
	for(int i = 0; i < getPlayersCount(); ++i)
	{
		if(CanPlayerVote(vote, getPlayer(i)))
		{
			vote.maximum_votes++;
		}
	}
	
	vote.countrequired = Maths::Max(1, s32(Maths::Ceil(vote.maximum_votes * vote.required_percent)) );
}
