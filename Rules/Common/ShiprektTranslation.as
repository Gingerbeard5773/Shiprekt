
//translated strings for shiprekt

//works by seperating each language by token '\\'
//in order- english, russian, portegeuse, french, polish
//"Translation\\перевод\\tradução\\Traduction\\tłumaczenie"

//TODO: perhaps switch to a dictionary once kag updates to staging

string Translate(string words)
{
	//drm idea: do split("\%") to stop mod from loading
	string[]@ tokens = words.split("\\");
	if (g_locale == "en")
		return tokens[0];
	if (g_locale == "ru")
		return tokens[1];
	if (g_locale == "fr")
		return tokens[2];
	if (g_locale == "pl")
		return tokens[3];
	
	return tokens[0];
}

namespace Trans
{
	const string
	
	//Generic
	Captain       = Translate("Captain\\"),
	Total         = Translate("Total\\"),
	Wooden        = Translate("Wooden\\"),
	Booty         = Translate("Booty\\"),
	Core          = Translate("Core\\"),
	Mothership    = Translate("Mothership\\"),
	Miniship      = Translate("Miniship\\"),
	Weight        = Translate("Weight\\"),
	Team          = Translate("Team\\"),
	
	//Colors
	Blue          = Translate("Blue\\"),
	Red           = Translate("Red\\"),
	Green         = Translate("Green\\"),
	Purple        = Translate("Purple\\"),
	Orange        = Translate("Orange\\"),
	Cyan          = Translate("Cyan\\"),
	NavyBlue      = Translate("Navy Blue\\"),
	Beige         = Translate("Beige\\"),
	
	//Hud
	CoreHealth    = Translate("Team Core Health\\"),
	Relinquish    = Translate("Click to relinquish ownership of a nearby seat\\"),
	Transfer      = Translate("Click to transfer {booty} Booty to\\"),
	ShipCrew      = Translate("your Mothership Crew\\"),
	Bases         = Translate("Captured Bases\\"),
	FreeMode      = Translate("Free Building Mode - Waiting for players to join.\\"),
	KillSharks    = Translate("Kill sharks to gain some Booty\\"),
	CouplingRDY   = Translate("Couplings ready.\nPress [{key}] to take.\\"),
	ShipAttack    = Translate("YOUR MOTHERSHIP IS UNDER ATTACK!!\\"),
	Abandon       = Translate("You are your Team's Captain <\n\nDon't abandon the Mothership!\\"),
	ReducedCosts  = Translate("Costs reduced during warmup\\"),
	
	//Votes
	Vote          = Translate("Vote\\"),
	SuddenDeath   = Translate("Sudden Death\\"),
	Freebuild     = Translate("Freebuild\\"),
	
	//Help menu
	Version       = Translate("Version\\"),
	Go_to_the     = Translate("Go to the\\"),
	ChangePage    = Translate("Press Left Click to change page | F1 to toggle this help Box (or type !help)\\"),
	ClickIcons    = Translate("Click these Icons for Control and Booty functions!\\"),
	FastGraphics  = Translate("Having lag issues? Turn on Faster Graphics in KAG video settings for possible improvement!\\"),
	
	//How to play
	HowToPlay     = Translate("How to Play\\"),
	GatherX       = Translate("Gather Xs for Booty. Xs have more Booty the closer they spawn to the map center.\\"),
	EngineWeak    = Translate("Engines are very weak! Use wood hull blocks as armor or Miniships will eat through them!\\"),
	YieldX        = Translate("Xs yield little Booty, but weapons reward a lot per hit to enemy ships!\\"),
	Docking       = Translate("Couplings stick to your Mothership on collision. Use them to dock with it.\\"),
	OtherTips     = Translate("Other Tips\\"),
	Leaderboard   = Translate("The higher a team is on the leaderboard, the more Booty you get for attacking them.\\"),
	BlockWeight   = Translate("Each block has a different weight. The heavier, the more they slow your ship down.\\"),
	
	//Controls
	Controls      = Translate("Controls\\"),
	Hold          = Translate("<hold>\\"),
	GetBlocks     = Translate("get Blocks while aboard your Mothership. Produces couplings while in a seat.\\"),
	RotateBlocks  = Translate("rotate blocks while building or release couplings when sitting.\\"),
	Punch         = Translate("punch when standing or fire Machineguns when sitting.\\"),
	FireGun       = Translate("fire handgun or fire Cannons when sitting.\\"),
	PointEmote    = Translate("show point emote.\\"),
	Zoom          = Translate("zoom in/out.\\"),
	ToolsMenu     = Translate("access the tools menu.\\"),
	ScaleCompass  = Translate("scale the Compass 2x. Tap to toggle. Hold for a quick view.\\"),
	
	//Build menu
	Components    = Translate("Components\\"),
	AmmoCap       = Translate("AmmoCap\\"),
	Seat          = Translate("Seat\\"),
	Engine        = Translate("Standard Engine.\\"),
	RamEngine     = Translate("Ram Engine\\"),
	Coupling      = Translate("Coupling\\"),
	Hull          = Translate("Hull\\"),
	Platform      = Translate("Platform\\"),
	Door          = Translate("Door\\"),
	Piston        = Translate("Piston\\"),
	Harpoon       = Translate("Harpoon\\"),
	Harvester     = Translate("Harvester\\"),
	Patcher       = Translate("Patcher\\"),
	AntiRam       = Translate("Anti-Ram\\"),
	Repulsor      = Translate("Repulsor\\"),
	Ram           = Translate("Ram\\"),
	Auxilliary    = Translate("Auxilliary Core\\"),
	PointDefense  = Translate("Point Defense\\"),
	FlakCannon    = Translate("Flak Cannon\\"),
	Machinegun    = Translate("Machinegun\\"),
	Cannon        = Translate("Cannon\\"),
	Launcher      = Translate("Missile Launcher\\"),
	DecoyCore     = Translate("Decoy Core\\"),
	
	SeatDesc 	  = Translate("Use it to control your ship. It can also release and produce Couplings.\nBreaks on impact.\\"),
	EngineDesc    = Translate("A ship motor with some armor plating for protection.\\"),
	RamEngineDesc = Translate("An engine that trades protection for extra power.\\"),
	CouplingDesc  = Translate("A versatile block used to hold and release other blocks.\\"),
	WoodHullDesc  = Translate("A very tough block for protecting delicate components.\\"),
	PlatformDesc  = Translate("A good quality wooden floor panel. Get that deck shining.\\"),
	DoorDesc      = Translate("A wooden door. Useful for ship security.\\"),
	PistonDesc	  = Translate("A piston. Can be used to push and pull segments of a ship.\\"),
	HarpoonDesc	  = Translate("A manual-fire harpoon launcher. Can be used for grabbing, towing, or water skiing!\\"),
	HarvesterDesc = Translate("An industrial-sized deconstructor that allows you to quickly mine resources from ship debris.\\"),
	PatcherDesc   = Translate("Emits a regenerative beam that can repair multiple components at once.\\"),
	AntiRamDesc   = Translate("Can absorb and negate multiple ram components, however weak against projectiles.\\"),
	RepulsorDesc  = Translate("Explodes pushing blocks away. Can be triggered remotely or by impact. Activates in a chain.\\"),
	RamDesc       = Translate("A rigid block that fractures on contact with other blocks. Will destroy itself as well as the block it hits.\\"),
	AuxillaryDesc = Translate("Similar to the Mothership core. Very powerful - gives greater independence to support ships.\\"),
	BombDesc      = Translate("Explodes on contact. Very useful against Solid blocks.\\"),
	PointDefDesc  = Translate("A short-ranged automated defensive turret. Neutralizes airborne projectiles such as flak.\\"),
	FlakDesc      = Translate("A long-ranged automated defensive turret that fires explosive shells with a proximity fuse.\\"),
	MGDesc        = Translate("A fixed rapid-fire, lightweight, machinegun that fires high-velocity projectiles.\nEffective against engines.\\"),
	CannonDesc    = Translate("A fixed cannon that fires momentum-bearing armor-piercing shells.\\"),
	LauncherDesc  = Translate("A fixed tube that fires a slow missile with short-ranged guidance.\nVery effective against armored ships.\\"),
	DecoyCoreDesc = Translate("A fake core to fool enemies. Replaces the Mothership on the compass.\\"),
	
	//Tools
	Pistol        = Translate("Pistol\\"),
	PistolDesc    = Translate("A basic, ranged, personal defence weapon.\\"),
	Deconstructor = Translate("Deconstructor\\"),
	DeconstDesc   = Translate("A tool that can reclaim ship parts for booty.\\"),
	Reconstructor = Translate("Reconstructor\\"),
	ReconstDesc   = Translate("A tool that can repair ship parts at the cost of booty.\\"),
	
	//Help Tips
	Tip0          = Translate("pistols deal fair damage to Mothership Cores, but Machineguns are not effective at all!\\"),
	Tip1          = Translate("target enemy ships that are higher on the leaderboard to get bigger rewards.\\"),
	Tip2          = Translate("machineguns and flak obliterate engines. Motherships need to place Solid blocks to counter this!\\"),
	Tip3          = Translate("weapons don't stack! If you line them up only the outmost one will fire.\\"),
	Tip4          = Translate("flak cannons get a fire rate boost when they are manned.\\"),
	Tip5          = Translate("while on a Miniship, don't bother gathering Xs until they disappear. Instead always look for bigger Xs.\\"),
	Tip6          = Translate("removing heavy blocks on Sudden Death doesn't help! Heavier ships are pulled less by the Whirlpool.\\"),
	Tip7          = Translate("docking: press [F]. Place the couplings on your Miniship. Bump the couplings against your Mothership.\\"),
	Tip8          = Translate("launching torpedoes: accelerate so the torpedo engine starts and break the coupling with spacebar.\\"),
	Tip9          = Translate("an engine's propeller blades destroy blocks, so be mindful of where you dock!\\"),
	Tip10         = Translate("destroy an enemy core so your whole team gets a Bounty! High ranking teams give bigger rewards.\\"),
	Tip11         = Translate("transfer Booty to your teammates by clicking the Coin icon at the lower HUD.\\"),
	Tip12         = Translate("relinquish ownership of a seat by standing next to it and clicking the Star icon at the lower HUD.\\"),
	Tip13         = Translate("double tap the [F] key to re-purchase the last bought item while on your Mothership.\\"),
	Tip14         = Translate("you can check how many enemy Motherships you have destroyed on the Tab board.\\"),
	Tip15         = Translate("have the urge to point at something? Press and hold middle click.\\"),
	Tip16         = Translate("you can break Couplings and activate Repulsors post torpedo launch if you keep your spacebar pressed.\\"),
	Tip17         = Translate("break all the Couplings you've placed on your ship by holding spacebar and right clicking.\\"),
	Tip18         = Translate("injured blocks cause less damage on collision.\\"),
	Tip19         = Translate("strafe mode activates only the engines perpendicular to your ship.\\"),
	Tip20         = Translate("players get a walk speed boost while aboard their Mothership.\\"),
	Tip21         = Translate("players get healed over time while aboard their Mothership.\\"),
	Tip22         = Translate("adding more blocks to a ship will decrease its turning speed.\\"),
	Tip23         = Translate("stolen enemy ships convert to your team after some seconds of driving them.\\"),
	Tip24         = Translate("kill sharks or enemy players to get a small Booty reward.\\"),
	Tip25         = Translate("crewmates get an Xs gathering boost while aboard their Mothership at the expense of their captain.\\"),
	Tip26         = Translate("Xs give more Booty the closer they are to the center of the map.\\"),
	Tip27         = Translate("repulsors will activate propellers in near vicinity on detonation.\\"),
	Tip28         = Translate("keep an eye on your torpedoes, they can change direction if they bounce off the border!\\"),
	Tip29         = Translate("killing players while you're onboard their mothership gives you 3x the Booty reward!\\"),
	Tip30         = Translate("auxilliary cores can be improvised into high-end explosives.\\");
}
