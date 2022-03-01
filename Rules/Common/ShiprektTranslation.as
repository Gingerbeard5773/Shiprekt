
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
	if (g_locale == "br")
		return tokens[2];
	if (g_locale == "fr")
		return tokens[3];
	if (g_locale == "pl")
		return tokens[4];
	
	return tokens[0];
}

namespace Trans
{
	const string
	
	//Generic
	Captain       = Translate("Captain\\\\Capitão"),
	Total         = Translate("Total\\\\Total"),
	Wooden        = Translate("Wooden\\\\de madeira"),
	Booty         = Translate("Booty\\\\Saque"),
	Core          = Translate("Core\\\\Núcleo"),
	Mothership    = Translate("Mothership\\\\Navio-mãe"),
	Miniship      = Translate("Miniship\\\\Mini-navio"),
	Weight        = Translate("Weight\\\\Peso"),
	Team          = Translate("Team\\\\Time"),
	
	//Colors
	Blue          = Translate("Blue\\\\Azul"),
	Red           = Translate("Red\\\\Vermelho"),
	Green         = Translate("Green\\\\Verde"),
	Purple        = Translate("Purple\\\\Roxo"),
	Orange        = Translate("Orange\\\\Laranja"),
	Cyan          = Translate("Cyan\\\\Ciano"),
	NavyBlue      = Translate("Navy Blue\\\\Azul-marinho"),
	Beige         = Translate("Beige\\\\Bege"),
	
	//Hud
	CoreHealth    = Translate("Team Core Health\\\\Vida do Núcleo do Time"),
	Relinquish    = Translate("Click to relinquish ownership of a nearby seat\\\\Vida do Núcleo do Time"),
	Transfer      = Translate("Click to transfer {booty} Booty to\\\\Clique para transferir {booty} Saque para a"),
	ShipCrew      = Translate("your Mothership Crew\\\\tripulação do seu Navio-mãe"),
	Bases         = Translate("Captured Bases\\\\Bases Capturadas"),
	FreeMode      = Translate("Free Building Mode - Waiting for players to join.\\\\Modo de Construção Livre - Aguardando a entrada de jogadores."),
	KillSharks    = Translate("Kill sharks to gain some Booty\\\\Mate tubarões para ganhar um pouco de Saque"),
	CouplingRDY   = Translate("Couplings ready.\nPress [{key}] to take.\\\\Acoplamentos prontos.\nPressione [{key}] para pegar."),
	ShipAttack    = Translate("YOUR MOTHERSHIP IS UNDER ATTACK!!\\\\SEU NAVIO-MÃE ESTÁ SOB ATAQUE!!"),
	Abandon       = Translate("> You are your Team's Captain <\n\nDon't abandon the Mothership!\\\\> Você é o Capitão do seu Time <\n\nNão abandone o Navio-mãe!"),
	ReducedCosts  = Translate("Costs reduced during warmup\\\\Custos reduzidos durante o aquecimento"),
	
	//Votes
	Vote          = Translate("Vote\\\\Vote"),
	SuddenDeath   = Translate("Sudden Death\\\\Morte Súbita"),
	Freebuild     = Translate("Freebuild\\\\Construção Livre"),
	
	//Help menu
	Version       = Translate("Version\\\\Versão"),
	Go_to_the     = Translate("Go to the\\\\Vá para o"),
	ChangePage    = Translate("Press Left Click to change page | F1 to toggle this help Box (or type !help)\\\\Pressione o Botão Esquerdo para mudar de página | F1 para habilitar essa Caixa de ajuda (ou digite !help)"),
	ClickIcons    = Translate("Click these Icons for Control and Booty functions!\\\\Clique nesses Ícones para funções de Controle e Saque!"),
	FastGraphics  = Translate("Having lag issues? Turn on Faster Graphics in KAG video settings for possible improvement!\\\\Vivenciando problemas de rede? Habilite os Gráficos Rápidos nas configurações de vídeo do KAG para uma possível melhora!"),
	
	//How to play
	HowToPlay     = Translate("How to Play\\\\Como Jogar"),
	GatherX       = Translate("Gather Xs for Booty. Xs have more Booty the closer they spawn to the map center.\\\\Colha Xs por Saque. Quanto mais perto do centro do mapa os Xs nascem, mais Saque eles têm."),
	EngineWeak    = Translate("Engines are very weak! Use wood hull blocks as armor or Miniships will eat through them!\\\\Motores estão muito fracos! Use blocos de casco de madeira como armadura ou Mini-navios irão devorar tudo!"),
	YieldX        = Translate("Xs yield little Booty, but weapons reward a lot per hit to enemy ships!\\\\Xs rendem pouco Saque, mas as armas recompensam muito por acerto aos navios inimigos!"),
	Docking       = Translate("Couplings stick to your Mothership on collision. Use them to dock with it.\\\\Os acoplamentos aderem ao seu Navio-mãe em caso de colisão. Use-os para atracar."),
	OtherTips     = Translate("Other Tips\\\\Outras Dicas"),
	Leaderboard   = Translate("The higher a team is on the leaderboard, the more Booty you get for attacking them.\\\\Quanto mais alto um time está na tabela de classificação, mais Saque você ganhará ao atacá-los."),
	BlockWeight   = Translate("Each block has a different weight. The heavier, the more they slow your ship down.\\\\Cada bloco tem um peso diferente. Quanto mais pesado for, mais devagar seu navio ficará."),
	
	//Controls
	Controls      = Translate("Controls\\\\Controles"),
	Hold          = Translate("<hold>\\\\<segure>"),
	GetBlocks     = Translate("get Blocks while aboard your Mothership. Produces couplings while in a seat.\\\\pegar Blocos enquanto estiver a bordo de seu Navio-mãe. Produzir acoplamentos enquanto estiver em um assento."),
	RotateBlocks  = Translate("rotate blocks while building or release couplings when sitting.\\\\rotacionar blocos enquanto constrói ou soltar acoplamentos enquanto estiver sentado."),
	Punch         = Translate("punch when standing or fire Machineguns when sitting.\\\\socar enquanto estiver de pé ou atirar com Metralhadoras enquanto estiver sentado."),
	FireGun       = Translate("fire handgun or fire Cannons when sitting.\\\\atirar com uma arma de fogo ou atirar com Canhões enquanto estiver sentado."),
	PointEmote    = Translate("show point emote.\\\\mostrar o emote de apontar."),
	Zoom          = Translate("zoom in/out.\\\\dar zoom para dentro/fora."),
	ToolsMenu     = Translate("access the tools menu.\\\\acessar o menu de ferramentas."),
	ScaleCompass  = Translate("scale the Compass 2x. Tap to toggle. Hold for a quick view.\\\\escalar a Bússola 2x. Clique para habilitar. Sgure para uma olhada breve."),
	
	//Build menu
	Components    = Translate("Components\\\\Componentes"),
	AmmoCap       = Translate("AmmoCap\\\\Munição"),
	Seat          = Translate("Seat\\\\Assento"),
	Engine        = Translate("Standard Engine.\\\\Motor Padrão"),
	RamEngine     = Translate("Ram Engine\\\\Motor de Aríete"),
	Coupling      = Translate("Coupling\\\\Acoplamento"),
	Hull          = Translate("Wooden Hull\\\\Casco de madeira"),
	Platform      = Translate("Wooden Platform\\\\Plataforma de madeira"),
	Door          = Translate("Wooden Door\\\\Porta de madeira"),
	Piston        = Translate("Wooden Piston\\\\Pistão de madeira"),
	Harpoon       = Translate("Harpoon\\\\Harpão"),
	Harvester     = Translate("Harvester\\\\Colheitadeira"),
	Patcher       = Translate("Patcher\\\\Reparador"),
	AntiRam       = Translate("Anti-Ram\\\\Anti-Aríete"),
	Repulsor      = Translate("Repulsor\\\\Repulsor"),
	Ram           = Translate("Ram\\\\Aríete"),
	Auxilliary    = Translate("Auxilliary Core\\\\Núcleo Auxiliar"),
	PointDefense  = Translate("Point Defense\\\\Defesa de Ponto"),
	FlakCannon    = Translate("Flak Cannon\\\\Canhão Antiaéreo"),
	Machinegun    = Translate("Machinegun\\\\Metralhadora"),
	Cannon        = Translate("Cannon\\\\Canhão"),
	Launcher      = Translate("Missile Launcher\\\\Lança-Mísseis"),
	DecoyCore     = Translate("Decoy Core\\\\Núcleo de Distração"),
	
	SeatDesc      = Translate("Use it to control your ship. It can also release and produce Couplings.\nBreaks on impact.\\\\Use-o para controlar seu navio. Ele Também pode liberar e produzir Acoplamentos.\nQuebra com impacto."),
	EngineDesc    = Translate("A ship motor with some armor plating for protection.\\\\Um motor de navio com um pouco de blindagem para proteção."),
	RamEngineDesc = Translate("An engine that trades protection for extra power.\\\\Um motor que troca proteção por potência extra."),
	CouplingDesc  = Translate("A versatile block used to hold and release other blocks.\\\\Um bloco versátil usado para segurar e soltar outros blocos."),
	WoodHullDesc  = Translate("A very tough block for protecting delicate components.\\\\Um bloco bem duro para proteger componentes delicados."),
	PlatformDesc  = Translate("A good quality wooden floor panel. Get that deck shining.\\\\Um painel de piso de madeira de boa qualidade. Deixe o convés brilhando."),
	DoorDesc      = Translate("A wooden door. Useful for ship security.\\\\Útil para a segurança do navio."),
	PistonDesc    = Translate("A piston. Can be used to push and pull segments of a ship.\\\\Um pistão. Pode ser utilizado para empurrar e puxar segmentos de um navio."),
	HarpoonDesc   = Translate("A manual-fire harpoon launcher. Can be used for grabbing, towing, or water skiing!\\\\Um lançador de harpão de fogo manual. Pode ser utilizado para agarrar, rebocar ou esqui-aquático!"),
	HarvesterDesc = Translate("An industrial-sized deconstructor that allows you to quickly mine resources from ship debris.\\\\Um desconstrutor de tamanho industrial que permite extrair rapidamente recursos de detritos de navios."),
	PatcherDesc   = Translate("Emits a regenerative beam that can repair multiple components at once.\\\\Emite um feixe regenerativo que pode reparar múltiplos componentes de uma vez."),
	AntiRamDesc   = Translate("Can absorb and negate multiple ram components, however weak against projectiles.\\\\Pode absorver e negar múltiplos componentes de aríete, entretanto é fraco contra projéteis."),
	RepulsorDesc  = Translate("Explodes pushing blocks away. Can be triggered remotely or by impact. Activates in a chain.\\\\Explode empurrando blocos para longe. Pode ser acionado remotamente ou por impacto. Ativa em uma cadeia."),
	RamDesc       = Translate("A rigid block that fractures on contact with other blocks. Will destroy itself as well as the block it hits.\\\\Um bloco rígido que fratura em contato com outros blocos. Destruirá a si mesmo, assim como o bloco que atingir."),
	AuxillaryDesc = Translate("Similar to the Mothership core. Very powerful - gives greater independence to support ships.\\\\Semelhante ao núcleo do Navio-mãe. Muito poderoso - fornece maior independência para navios de suporte."),
	BombDesc      = Translate("Explodes on contact. Very useful against Solid blocks.\\\\Explode em contato. Muito útil contra blocos Sólidos."),
	PointDefDesc  = Translate("A short-ranged automated defensive turret. Neutralizes airborne projectiles such as flak.\\\\Uma torre de defesa automatizada de curta distância. Neutraliza projéteis no ar como um antiaéreo."),
	FlakDesc      = Translate("A long-ranged automated defensive turret that fires explosive shells with a proximity fuse.\\\\Uma torre de defesa automatizada de longa distância que dispara projéteis explosivos com um fusível de proximidade."),
	MGDesc        = Translate("A fixed rapid-fire, lightweight, machinegun that fires high-velocity projectiles.\nEffective against engines.\\\\Uma metralhadora fixa leve e de alta cadência que dispara projéteis de alta velocidade.\nEficaz contra motores."),
	CannonDesc    = Translate("A fixed cannon that fires momentum-bearing armor-piercing shells.\\\\Um canhão fixo que dispara projéteis perfurantes com impulso."),
	LauncherDesc  = Translate("A fixed tube that fires a slow missile with short-ranged guidance.\nVery effective against armored ships.\\\\Um tubo fixo que dispara um míssil lento com orientação de curto alcance."),
	DecoyCoreDesc = Translate("A fake core to fool enemies. Replaces the Mothership on the compass.\\\\Um núcleo falso para enganar inimigos. Substitui o Navio-mãe na bússola."),
	
	//Tools
	Pistol        = Translate("Pistol\\\\Pistola"),
	PistolDesc    = Translate("A basic, ranged, personal defense weapon.\\\\Uma arma básica de defesa pessoal à distância."),
	Deconstructor = Translate("Deconstructor\\\\Desconstrutor"),
	DeconstDesc   = Translate("A tool that can reclaim ship parts for booty.\\\\Uma ferramenta que consegue recuperar partes do navio para saque."),
	Reconstructor = Translate("Reconstructor\\\\Reconstrutor"),
	ReconstDesc   = Translate("A tool that can repair ship parts at the cost of booty.\\\\Uma ferramenta que consegue reparar partes do navio ao custo de saque."),
	
	//Help Tips
	Tip0          = Translate("pistols deal fair damage to Mothership Cores, but Machineguns are not effective at all!\\\\pistolas causam dano decente aos Núcleos de Navios-mãe, porém Metralhadoras não são nem um pouco eficazes!"),
	Tip1          = Translate("target enemy ships that are higher on the leaderboard to get bigger rewards.\\\\mire em navios inimigos que se encontram mais alto na tabela de classificação para conseguir recompensas melhores."),
	Tip2          = Translate("machineguns and flak obliterate engines. Motherships need to place Solid blocks to counter this!\\\\metralhadoras e antiaéreos dizimam motores. Navios-mãe precisam colocar blocos Sólidos para combater isso!"),
	Tip3          = Translate("weapons don't stack! If you line them up only the outmost one will fire.\\\\armas não empilham! Se você alinhá-las, apenas a mais distante irá disparar."),
	Tip4          = Translate("flak cannons get a fire rate boost when they are manned.\\\\canhões antiaéreos recebem um impulso de taxa de cadência quando são controlados manualmente."),
	Tip5          = Translate("while on a Miniship, don't bother gathering Xs until they disappear. Instead always look for bigger Xs.\\\\enquanto estiver em um Mini-navio, não se preocupe em coletar Xs até desaparecerem. Em vez disso, sempre procure por Xs maiores."),
	Tip6          = Translate("removing heavy blocks on Sudden Death doesn't help! Heavier ships are pulled less by the Whirlpool.\\\\remover blocos pesados na Morte Súbita não ajuda! Navios mais pesados são puxados menos pelo Redemoinho."),
	Tip7          = Translate("docking: press [F]. Place the couplings on your Miniship. Bump the couplings against your Mothership.\\\\atracando: pressione [F]. Coloque os acoplamentos no seu Mini-navio. Bata os acoplamentos contra seu Navio-mãe."),
	Tip8          = Translate("launching torpedoes: accelerate so the torpedo engine starts and break the coupling with spacebar.\\\\lançando torpedos: acelere para que o motor do torpedo dê partida e quebre o acoplamento com a barra de espaço."),
	Tip9          = Translate("an engine's propeller blades destroy blocks, so be mindful of where you dock!\\\\as pás da hélice de um motor destroem blocos, então fique atento de onde irá atracar!"),
	Tip10         = Translate("destroy an enemy core so your whole team gets a Bounty! High ranking teams give bigger rewards.\\\\destrua um núcleo inimigo para que seu time inteiro consiga uma Recompensa! Times com alta classificação dão recompensas maiores."),
	Tip11         = Translate("transfer Booty to your teammates by clicking the Coin icon at the lower HUD.\\\\transfira Saque para seus colegas de equipe clicando no ícone de Moeda no HUD inferior."),
	Tip12         = Translate("relinquish ownership of a seat by standing next to it and clicking the Star icon at the lower HUD.\\\\renuncie a liderança de um assento ao ficar em pé próximo a ele e clicar no ícone da Estrela no HUD inferior."),
	Tip13         = Translate("double tap the [F] key to re-purchase the last bought item while on your Mothership.\\\\clique duas vezes na tecla [F] para comprar novamente o último item que você havia comprado enquanto está no seu Navio-mãe."),
	Tip14         = Translate("you can check how many enemy Motherships you have destroyed on the Tab board.\\\\você pode checar quantos Navios-mãe inimios você já destruiu na tabela do Tab."),
	Tip15         = Translate("have the urge to point at something? Press and hold middle click.\\\\sente a necessidade de apontar para algo? Pressione e segure o botão do meio do mouse."),
	Tip16         = Translate("you can break Couplings and activate Repulsors post torpedo launch if you keep your spacebar pressed.\\\\você pode quebrar Acoplamentos e ativar Repulsores após o lançamento de torpedo se você mantiver sua barra de espaço pressionada."),
	Tip17         = Translate("break all the Couplings you've placed on your ship by holding spacebar and right clicking.\\\\quebre todos os Acoplamentos que você colocou no seu navio ao segurar a barra de espaço e clicar com o botão direito."),
	Tip18         = Translate("injured blocks cause less damage on collision.\\\\blocos danificados causam menos dano em colisões."),
	Tip19         = Translate("strafe mode activates only the engines perpendicular to your ship.\\\\o modo strafe ativa apenas os motores perpendiculares ao seu navio."),
	Tip20         = Translate("players get a walk speed boost while aboard their Mothership.\\\\jogadores ganham um impulso de velocidade de caminhada enquanto estiverem a bordo de seus Navios-mãe."),
	Tip21         = Translate("players get healed over time while aboard their Mothership.\\\\jogadores são curados com o passar do tempo enquanto estiverem a bordo de seus Navios-mãe."),
	Tip22         = Translate("adding more blocks to a ship will decrease its turning speed.\\\\adicionar mais blocos para um navio irá reduzir sua velocidade de giro."),
	Tip23         = Translate("stolen enemy ships convert to your team after some seconds of driving them.\\\\navios inimigos roubados são convertidos ao seu time após alguns segundos dirigindo-os."),
	Tip24         = Translate("kill sharks or enemy players to get a small Booty reward.\\\\mate tubarões ou jogadores inimigos para ganhar uma pequena recompensa de Saque."),
	Tip25         = Translate("crewmates get an Xs gathering boost while aboard their Mothership at the expense of their captain.\\\\tripulantes ganham um impulso de coleta de Xs enquanto estiverem a bordo de seus Navios-mãe às custas de seu capitão."),
	Tip26         = Translate("Xs give more Booty the closer they are to the center of the map.\\\\Xs fornecem mais Saque conforme estão mais perto do centro do mapa."),
	Tip27         = Translate("repulsors will activate propellers in near vicinity on detonation.\\\\repulsores ativarão as hélices nas proximidades na detonação."),
	Tip28         = Translate("keep an eye on your torpedoes, they can change direction if they bounce off the border!\\\\fique de olho em seus torpedos, eles podem mudar de direção se baterem no limite do mapa!"),
	Tip29         = Translate("killing players while you're onboard their mothership gives you 3x the Booty reward!\\\\matar jogadores enquanto você estiver no Navio-mãe deles fornecerá 3x a recompensa de Saque!"),
	Tip30         = Translate("auxilliary cores can be improvised into high-end explosives.\\\\núcleos auxiliares podem ser improvisados em explosivos de alta qualidade.");
}
