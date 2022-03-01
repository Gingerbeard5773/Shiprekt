
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
	Captain       = Translate("Captain\\Капитан\\Capitão"),
	Total         = Translate("Total\\Всего\\Total"),
	Wooden        = Translate("Wooden\\Деревянный\\de madeira"),
	Booty         = Translate("Booty\\Добыча\\Saque"),
	Core          = Translate("Core\\Сердце\\Núcleo"),
	Mothership    = Translate("Mothership\\Главный корабль\\Navio-mãe"),
	Miniship      = Translate("Miniship\\Мини корабль\\Mini-navio"),
	Weight        = Translate("Weight\\Вес\\Peso"),
	Team          = Translate("Team\\Комманда\\Time"),
	
	//Colors
	Blue          = Translate("Blue\\Синие\\Azul"),
	Red           = Translate("Red\\Красные\\Vermelho"),
	Green         = Translate("Green\\Зелёные\\Verde"),
	Purple        = Translate("Purple\\Фиолетовые\\Roxo"),
	Orange        = Translate("Orange\\Оранжевые\\Laranja"),
	Cyan          = Translate("Cyan\\Бирюзовые\\Ciano"),
	NavyBlue      = Translate("Navy Blue\\Тёмно-синие\\Azul-marinho"),
	Beige         = Translate("Beige\\Бежевые\\Bege"),
	
	//Hud
	CoreHealth    = Translate("Team Core Health\\Здоровье сердца комманды\\Vida do Núcleo do Time"),
	Relinquish    = Translate("Click to relinquish ownership of a nearby seat\\Нажми чтобы завладеть ближайшим креслом\\Vida do Núcleo do Time"),
	Transfer      = Translate("Click to transfer {booty} Booty to\\Нажми чтобы отдать {booty} Добычу\\Clique para transferir {booty} Saque para a"),
	ShipCrew      = Translate("your Mothership Crew\\всем в своей комманде\\tripulação do seu Navio-mãe"),
	Bases         = Translate("Captured Bases\\Захваченные базы\\Bases Capturadas"),
	FreeMode      = Translate("Free Building Mode - Waiting for players to join.\\Режим свободного строительства - Ждём пока присоединятся люди.\\Modo de Construção Livre - Aguardando a entrada de jogadores."),
	KillSharks    = Translate("Kill sharks to gain some Booty\\Убивай акул для получения Добычи\\Mate tubarões para ganhar um pouco de Saque"),
	CouplingRDY   = Translate("Couplings ready.\nPress [{key}] to take.\\Соединения готовы. \nНажми [{key}] чтобы создать.\\Acoplamentos prontos.\nPressione [{key}] para pegar."),
	ShipAttack    = Translate("YOUR MOTHERSHIP IS UNDER ATTACK!!\\ВАШ ГЛАВНЫЙ КОРАБЛЬ ПОД АТАКОЙ!!\\SEU NAVIO-MÃE ESTÁ SOB ATAQUE!!"),
	Abandon       = Translate("> You are your Team's Captain <\n\nDon't abandon the Mothership!\\> Вы капитан комманды <\n\nНе покидайте корабль!\\> Você é o Capitão do seu Time <\n\nNão abandone o Navio-mãe!"),
	ReducedCosts  = Translate("Costs reduced during warmup\\Цены уменьшены во время подготовки\\Custos reduzidos durante o aquecimento"),
	
	//Votes
	Vote          = Translate("Vote\\Голосование\\Vote"),
	SuddenDeath   = Translate("Sudden Death\\Внезапная смерть\\Morte Súbita"),
	Freebuild     = Translate("Freebuild\\Свободное строительство\\Construção Livre"),
	
	//Help menu
	Version       = Translate("Version\\Версия\\Versão"),
	Go_to_the     = Translate("Go to the\\Перейти\\Vá para o"),
	ChangePage    = Translate("Press Left Click to change page | F1 to toggle this help Box (or type !help)\\Нажмите ЛКМ чтобы сменить страницу | F1 чтобы открыть это окно (или введите !help в чате)\\Pressione o Botão Esquerdo para mudar de página | F1 para habilitar essa Caixa de ajuda (ou digite !help)"),
	ClickIcons    = Translate("Click these Icons for Control and Booty functions!\\Нажмите эти иконки для управления и функций Добычи\\Clique nesses Ícones para funções de Controle e Saque!"),
	FastGraphics  = Translate("Having lag issues? Turn on Faster Graphics in KAG video settings for possible improvement!\\Проблемы с лагами? Включите Faster Graphics в настройках видео для возможного улучшения!\\Vivenciando problemas de rede? Habilite os Gráficos Rápidos nas configurações de vídeo do KAG para uma possível melhora!"),
	
	//How to play
	HowToPlay     = Translate("How to Play\\Как играть\\Como Jogar"),
	GatherX       = Translate("Gather Xs for Booty. Xs have more Booty the closer they spawn to the map center.\\Стойте на Х-ах для Добычи. Х-ы ближе к центру карты дают больше Добычи.\\Colha Xs por Saque. Quanto mais perto do centro do mapa os Xs nascem, mais Saque eles têm."),
	EngineWeak    = Translate("Engines are very weak! Use wood hull blocks as armor or Miniships will eat through them!\\Двигатели очень слабые! Используй деревянные каркасные блоки для защиты корабля!\\Motores estão muito fracos! Use blocos de casco de madeira como armadura ou Mini-navios irão devorar tudo!"),
	YieldX        = Translate("Xs yield little Booty, but weapons reward a lot per hit to enemy ships!\\Х-ы дают мало Добычи, но стрельба по вражеским кораблям гораздо больше!\\Xs rendem pouco Saque, mas as armas recompensam muito por acerto aos navios inimigos!"),
	Docking       = Translate("Couplings stick to your Mothership on collision. Use them to dock with it.\\Соединения прилипают к Главному кораблю при соприкосновении с ним. Используй их для стыковки.\\Os acoplamentos aderem ao seu Navio-mãe em caso de colisão. Use-os para atracar."),
	OtherTips     = Translate("Other Tips\\Прочие подсказки\\Outras Dicas"),
	Leaderboard   = Translate("The higher a team is on the leaderboard, the more Booty you get for attacking them.\\Чем выше комманда в таблице, тем больше Добычи получишь за атаку на них.\\Quanto mais alto um time está na tabela de classificação, mais Saque você ganhará ao atacá-los."),
	BlockWeight   = Translate("Each block has a different weight. The heavier, the more they slow your ship down.\\Каждый блок имеет разный вес. Чем тяжелее твой корабль, тем медленнее он будет.\\Cada bloco tem um peso diferente. Quanto mais pesado for, mais devagar seu navio ficará."),
	
	//Controls
	Controls      = Translate("Controls\\Управление\\Controles"),
	Hold          = Translate("<hold>\\<зажми>\\<segure>"),
	GetBlocks     = Translate("get Blocks while aboard your Mothership. Produces couplings while in a seat.\\взять блок когда на главном корабле. Создаёт соединеие когда в кресле.\\pegar Blocos enquanto estiver a bordo de seu Navio-mãe. Produzir acoplamentos enquanto estiver em um assento."),
	RotateBlocks  = Translate("rotate blocks while building or release couplings when sitting.\\повернуть блок когда строишь или убирает соединения когда в кресле.\\rotacionar blocos enquanto constrói ou soltar acoplamentos enquanto estiver sentado."),
	Punch         = Translate("punch when standing or fire Machineguns when sitting.\\удар когда стоишь или выстрел из пулеметов когда сидишь.\\socar enquanto estiver de pé ou atirar com Metralhadoras enquanto estiver sentado."),
	FireGun       = Translate("fire handgun or fire Cannons when sitting.\\выстрел пистолета или выстрел из пушек когда сидишь.\\atirar com uma arma de fogo ou atirar com Canhões enquanto estiver sentado."),
	PointEmote    = Translate("show point emote.\\показать эмоцию-указатель.\\mostrar o emote de apontar."),
	Zoom          = Translate("zoom in/out.\\приблизить/отдалить\\dar zoom para dentro/fora."),
	ToolsMenu     = Translate("access the tools menu.\\открыть меню инструментов.\\acessar o menu de ferramentas."),
	ScaleCompass  = Translate("scale the Compass 2x. Tap to toggle. Hold for a quick view.\\увеличит компас в 2 раза. Нажми для удержания или зажми для временного просмотра.\\escalar a Bússola 2x. Clique para habilitar. Sgure para uma olhada breve."),
	
	//Build menu
	Components    = Translate("Components\\Компоненты\\Componentes"),
	AmmoCap       = Translate("AmmoCap\\Боеприпасы\\Munição"),
	Seat          = Translate("Seat\\Кресло\\Assento"),
	Engine        = Translate("Standard Engine\\Стандартный Двигатель\\Motor Padrão"),
	RamEngine     = Translate("Ram Engine\\Быстрый Двигатель\\Motor de Aríete"),
	Coupling      = Translate("Coupling\\Соединение\\Acoplamento"),
	Hull          = Translate("Wooden Hull\\Каркас\\Casco de madeira"),
	Platform      = Translate("Wooden Platform\\Платформа\\Plataforma de madeira"),
	Door          = Translate("Wooden Door\\Дверь\\Porta de madeira"),
	Piston        = Translate("Wooden Piston\\Поршень\\Pistão de madeira"),
	Harpoon       = Translate("Harpoon\\Гарпун\\Harpão"),
	Harvester     = Translate("Harvester\\Ломатель\\Colheitadeira"),
	Patcher       = Translate("Patcher\\Чинитель\\Reparador"),
	AntiRam       = Translate("Anti-Ram\\Анти-Таран\\Anti-Aríete"),
	Repulsor      = Translate("Repulsor\\Репульсор\\Repulsor"),
	Ram           = Translate("Ram\\Таран\\Aríete"),
	Auxilliary    = Translate("Auxilliary Core\\Вспомогательное Сердце\\Núcleo Auxiliar"),
	PointDefense  = Translate("Point Defense\\Защитная турель\\Defesa de Ponto"),
	FlakCannon    = Translate("Flak Cannon\\Зенитная Пушка\\Canhão Antiaéreo"),
	Machinegun    = Translate("Machinegun\\Пулемёт\\Metralhadora"),
	Cannon        = Translate("Cannon\\Пушка\\Canhão"),
	Launcher      = Translate("Missile Launcher\\Ракетная Установка\\Lança-Mísseis"),
	DecoyCore     = Translate("Decoy Core\\Фальшивое Сердце\\Núcleo de Distração"),
	
	SeatDesc      = Translate("Use it to control your ship. It can also release and produce Couplings.\nBreaks on impact.\\Используйте его, чтобы управлять своим кораблем. Он также может освобождать и производить соединения.\nЛомается при ударе.\\Use-o para controlar seu navio. Ele Também pode liberar e produzir Acoplamentos.\nQuebra com impacto."),
	EngineDesc    = Translate("A ship motor with some armor plating for protection.\\Корабельный мотор с броней для защиты.\\Um motor de navio com um pouco de blindagem para proteção."),
	RamEngineDesc = Translate("An engine that trades protection for extra power.\\Двигатель без защиты но с дополнительной мощностью.\\Um motor que troca proteção por potência extra."),
	CouplingDesc  = Translate("A versatile block used to hold and release other blocks.\\Универсальный блок, используемый для удержания и освобождения других блоков.\\Um bloco versátil usado para segurar e soltar outros blocos."),
	WoodHullDesc  = Translate("A very tough block for protecting delicate components.\\Очень прочный блок для защиты хрупких блоков.\\Um bloco bem duro para proteger componentes delicados."),
	PlatformDesc  = Translate("A good quality wooden floor panel. Get that deck shining.\\Качественная деревянная панель для пола.\\Um painel de piso de madeira de boa qualidade. Deixe o convés brilhando."),
	DoorDesc      = Translate("A wooden door. Useful for ship security.\\Деревянная дверь. Полезно для охраны корабля.\\Útil para a segurança do navio."),
	PistonDesc    = Translate("A piston. Can be used to push and pull segments of a ship.\\Поршень. Используется, чтобы толкать и тянуть сегменты корабля.\\Um pistão. Pode ser utilizado para empurrar e puxar segmentos de um navio."),
	HarpoonDesc   = Translate("A manual-fire harpoon launcher. Can be used for grabbing, towing, or water skiing!\\Гарпунная пусковая установка с ручным огнем. Может использоваться для захвата, буксировки или катания на водных лыжах!\\Um lançador de harpão de fogo manual. Pode ser utilizado para agarrar, rebocar ou esqui-aquático!"),
	HarvesterDesc = Translate("An industrial-sized deconstructor that allows you to quickly mine resources from ship debris.\\Деконструктор промышленных размеров, позволяющий быстро добывать ресурсы из корабельных обломков.\\Um desconstrutor de tamanho industrial que permite extrair rapidamente recursos de detritos de navios."),
	PatcherDesc   = Translate("Emits a regenerative beam that can repair multiple components at once.\\Излучает регенеративный луч, который может восстанавливать несколько блоков одновременно.\\Emite um feixe regenerativo que pode reparar múltiplos componentes de uma vez."),
	AntiRamDesc   = Translate("Can absorb and negate multiple ram components, however weak against projectiles.\\Может поглощать и блокировать несколько блоков Тарана, однако слаб против снарядов.\\Pode absorver e negar múltiplos componentes de aríete, entretanto é fraco contra projéteis."),
	RepulsorDesc  = Translate("Explodes pushing blocks away. Can be triggered remotely or by impact. Activates in a chain.\\Взрывается, отталкивая блоки. Может запускаться дистанционно или ударом. Активируется по цепочке.\\Explode empurrando blocos para longe. Pode ser acionado remotamente ou por impacto. Ativa em uma cadeia."),
	RamDesc       = Translate("A rigid block that fractures on contact with other blocks. Will destroy itself as well as the block it hits.\\Жесткий блок, который ломается при контакте с другими блоками. Уничтожает себя, а также блок, в который попадает.\\Um bloco rígido que fratura em contato com outros blocos. Destruirá a si mesmo, assim como o bloco que atingir."),
	AuxillaryDesc = Translate("Similar to the Mothership core. Very powerful - gives greater independence to support ships.\\Подобно Сердцу главного корабля. Очень мощный - дает большую независимость мини-кораблям.\\Semelhante ao núcleo do Navio-mãe. Muito poderoso - fornece maior independência para navios de suporte."),
	BombDesc      = Translate("Explodes on contact. Very useful against Solid blocks.\\Взрывается при контакте. Очень полезно против твёрдых блоков.\\Explode em contato. Muito útil contra blocos Sólidos."),
	PointDefDesc  = Translate("A short-ranged automated defensive turret. Neutralizes airborne projectiles such as flak.\\Автоматическая оборонительная турель ближнего действия. Нейтрализует летающие снаряды, такие как снаряды зенитных пушек.\\Uma torre de defesa automatizada de curta distância. Neutraliza projéteis no ar como um antiaéreo."),
	FlakDesc      = Translate("A long-ranged automated defensive turret that fires explosive shells with a proximity fuse.\\Автоматизированная защитная турель дальнего действия, стреляющая разрывными снарядами с взрывателем дальности.\\Uma torre de defesa automatizada de longa distância que dispara projéteis explosivos com um fusível de proximidade."),
	MGDesc        = Translate("A fixed rapid-fire, lightweight, machinegun that fires high-velocity projectiles.\nEffective against engines.\\Неподвижный скорострельный легкий пулемет, стреляющий высокоскоростными снарядами.\nЭффективен против двигателей.\\Uma metralhadora fixa leve e de alta cadência que dispara projéteis de alta velocidade.\nEficaz contra motores."),
	CannonDesc    = Translate("A fixed cannon that fires momentum-bearing armor-piercing shells.\\Стационарная пушка, которая стреляет бронебойными снарядами с импульсом.\\Um canhão fixo que dispara projéteis perfurantes com impulso."),
	LauncherDesc  = Translate("A fixed tube that fires a slow missile with short-ranged guidance.\nVery effective against armored ships.\\Неподвижная труба, стреляющая медленной ракетой с малой дальностью наведения.\nОчень эффективна против бронированных кораблей.\\Um tubo fixo que dispara um míssil lento com orientação de curto alcance."),
	DecoyCoreDesc = Translate("A fake core to fool enemies. Replaces the Mothership on the compass.\\Фальшивое сердце, чтобы одурачить врагов. Заменяет главное сердце на компасе.\\Um núcleo falso para enganar inimigos. Substitui o Navio-mãe na bússola."),
	
	//Tools
	Pistol        = Translate("Pistol\\Пистолет\\Pistola"),
	PistolDesc    = Translate("A basic, ranged, personal defense weapon.\\Обычное средство персональной защиты дальнего действия.\\Uma arma básica de defesa pessoal à distância."),
	Deconstructor = Translate("Deconstructor\\Деконструктор\\Desconstrutor"),
	DeconstDesc   = Translate("A tool that can reclaim ship parts for booty.\\A tool that can reclaim ship parts for booty. Инструмент для разборки частей корабля на Добычу.\\Uma ferramenta que consegue recuperar partes do navio para saque."),
	Reconstructor = Translate("Reconstructor\\Реконструктор\\Reconstrutor"),
	ReconstDesc   = Translate("A tool that can repair ship parts at the cost of booty.\\Инструмент для починки частей корабля за Добычу.\\Uma ferramenta que consegue reparar partes do navio ao custo de saque."),
	
	//Help Tips
	Tip0          = Translate("pistols deal fair damage to Mothership Cores, but Machineguns are not effective at all!\\пистолеты наносят приличный урон Сердцу главного корабля, а Пулеметы совсем не эффективны!\\pistolas causam dano decente aos Núcleos de Navios-mãe, porém Metralhadoras não são nem um pouco eficazes!"),
	Tip1          = Translate("target enemy ships that are higher on the leaderboard to get bigger rewards.\\атакуйте вражеские корабли, которые выше в таблице, чтобы получить большие награды.\\mire em navios inimigos que se encontram mais alto na tabela de classificação para conseguir recompensas melhores."),
	Tip2          = Translate("machineguns and flak obliterate engines. Motherships need to place Solid blocks to counter this!\\пулеметы и зенитки уничтожают двигатели. Главные корабли должны размещать каркасные блоки, чтобы противостоять этому!\\metralhadoras e antiaéreos dizimam motores. Navios-mãe precisam colocar blocos Sólidos para combater isso!"),
	Tip3          = Translate("weapons don't stack! If you line them up only the outmost one will fire.\\оружие не стакается! Если вы выстроите их в линию, сработает только крайние из них.\\armas não empilham! Se você alinhá-las, apenas a mais distante irá disparar."),
	Tip4          = Translate("flak cannons get a fire rate boost when they are manned.\\зенитные пушки получают повышение скорострельности, когда они пилотируются.\\canhões antiaéreos recebem um impulso de taxa de cadência quando são controlados manualmente."),
	Tip5          = Translate("while on a Miniship, don't bother gathering Xs until they disappear. Instead always look for bigger Xs.\\находясь на мини-корабле, не утруждайте себя сбором Х-ов пока они не исчезнут. Вместо этого всегда ищите большие Х-ы.\\enquanto estiver em um Mini-navio, não se preocupe em coletar Xs até desaparecerem. Em vez disso, sempre procure por Xs maiores."),
	Tip6          = Translate("removing heavy blocks on Sudden Death doesn't help! Heavier ships are pulled less by the Whirlpool.\\снятие тяжелых блоков во время Внезапной Смерти не помогает! Водоворот меньше притягивает более тяжелые корабли.\\remover blocos pesados na Morte Súbita não ajuda! Navios mais pesados são puxados menos pelo Redemoinho."),
	Tip7          = Translate("docking: press [F]. Place the couplings on your Miniship. Bump the couplings against your Mothership.\\стыковка: нажмите [F]. Поместите Соединения на свой мини-корабль. Коснитесь Соединениями о свой главный корабль.\\atracando: pressione [F]. Coloque os acoplamentos no seu Mini-navio. Bata os acoplamentos contra seu Navio-mãe."),
	Tip8          = Translate("launching torpedoes: accelerate so the torpedo engine starts and break the coupling with spacebar.\\запуск торпед: разгонитесь до запуска торпедного двигателя и разорвите Соединение пробелом.\\lançando torpedos: acelere para que o motor do torpedo dê partida e quebre o acoplamento com a barra de espaço."),
	Tip9          = Translate("an engine's propeller blades destroy blocks, so be mindful of where you dock!\\лопасти пропеллера двигателя разрушают блоки, так что следите за тем, где вы швартуетесь!\\as pás da hélice de um motor destroem blocos, então fique atento de onde irá atracar!"),
	Tip10         = Translate("destroy an enemy core so your whole team gets a Bounty! High ranking teams give bigger rewards.\\уничтожьте вражеское сердце, чтобы вся ваша команда получила награду! Команды с выше в таблтце дают больше награды.\\destrua um núcleo inimigo para que seu time inteiro consiga uma Recompensa! Times com alta classificação dão recompensas maiores."),
	Tip11         = Translate("transfer Booty to your teammates by clicking the Coin icon at the lower HUD.\\передайте Добычу своим товарищам по команде, щелкнув значок монеты внизу.\\transfira Saque para seus colegas de equipe clicando no ícone de Moeda no HUD inferior."),
	Tip12         = Translate("relinquish ownership of a seat by standing next to it and clicking the Star icon at the lower HUD.\\отказаться от права собственности на кресло, встав рядом с ним и щелкнув значок звездочки в низу.\\renuncie a liderança de um assento ao ficar em pé próximo a ele e clicar no ícone da Estrela no HUD inferior."),
	Tip13         = Translate("double tap the [F] key to re-purchase the last bought item while on your Mothership.\\дважды нажмите клавишу [F], чтобы повторно купить последний купленный предмет, находясь на главном корабле.\\clique duas vezes na tecla [F] para comprar novamente o último item que você havia comprado enquanto está no seu Navio-mãe."),
	Tip14         = Translate("you can check how many enemy Motherships you have destroyed on the Tab board.\\Вы можете проверить, сколько вражеских главных кораблей вы уничтожили на вкладке Tab.\\você pode checar quantos Navios-mãe inimios você já destruiu na tabela do Tab."),
	Tip15         = Translate("have the urge to point at something? Press and hold middle click.\\есть желание указать на что-то? Нажмите и удерживайте колёсико мыши.\\sente a necessidade de apontar para algo? Pressione e segure o botão do meio do mouse."),
	Tip16         = Translate("you can break Couplings and activate Repulsors post torpedo launch if you keep your spacebar pressed.\\вы можете сломать Соединеия и активировать репульсоры после запуска торпеды, если будете удерживать клавишу пробела.\\você pode quebrar Acoplamentos e ativar Repulsores após o lançamento de torpedo se você mantiver sua barra de espaço pressionada."),
	Tip17         = Translate("break all the Couplings you've placed on your ship by holding spacebar and right clicking.\\сломайте все соединения, которые вы разместили на своем корабле, удерживая клавишу пробела и щелкая правой кнопкой мыши.\\quebre todos os Acoplamentos que você colocou no seu navio ao segurar a barra de espaço e clicar com o botão direito."),
	Tip18         = Translate("injured blocks cause less damage on collision.\\поврежденные блоки наносят меньше урона при столкновении.\\blocos danificados causam menos dano em colisões."),
	Tip19         = Translate("strafe mode activates only the engines perpendicular to your ship.\\«режим стрейфа» активирует только двигатели, перпендикулярные вашему кораблю.\\o modo strafe ativa apenas os motores perpendiculares ao seu navio."),
	Tip20         = Translate("players get a walk speed boost while aboard their Mothership.\\игроки получают повышение скорости ходьбы на борту своего главного корабля.\\jogadores ganham um impulso de velocidade de caminhada enquanto estiverem a bordo de seus Navios-mãe."),
	Tip21         = Translate("players get healed over time while aboard their Mothership.\\игроки со временем исцеляются, находясь на борту своего главного корабля.\\jogadores são curados com o passar do tempo enquanto estiverem a bordo de seus Navios-mãe."),
	Tip22         = Translate("adding more blocks to a ship will decrease its turning speed.\\добавление дополнительных блоков к кораблю уменьшает его скорость поворота.\\adicionar mais blocos para um navio irá reduzir sua velocidade de giro."),
	Tip23         = Translate("stolen enemy ships convert to your team after some seconds of driving them.\\украденные вражеские корабли меняют команду на вашу после нескольких секунд управления ими.\\navios inimigos roubados são convertidos ao seu time após alguns segundos dirigindo-os."),
	Tip24         = Translate("kill sharks or enemy players to get a small Booty reward.\\убивайте акул или вражеских игроков, чтобы получить небольшую Добычу.\\mate tubarões ou jogadores inimigos para ganhar uma pequena recompensa de Saque."),
	Tip25         = Translate("crewmates get an Xs gathering boost while aboard their Mothership at the expense of their captain.\\товарищи по команде получают ускорение сбора X-ов на борту своего материнского корабля за счет своего капитана.\\tripulantes ganham um impulso de coleta de Xs enquanto estiverem a bordo de seus Navios-mãe às custas de seu capitão."),
	Tip26         = Translate("Xs give more Booty the closer they are to the center of the map.\\Х-ы дают больше добычи, чем ближе они к центру карты.\\Xs fornecem mais Saque conforme estão mais perto do centro do mapa."),
	Tip27         = Translate("repulsors will activate propellers in near vicinity on detonation.\\репульсоры активируют пропеллеры в непосредственной близости от детонации.\\repulsores ativarão as hélices nas proximidades na detonação."),
	Tip28         = Translate("keep an eye on your torpedoes, they can change direction if they bounce off the border!\\следите за своими торпедами, они могут изменить направление, если отскочат от границы карты!\\fique de olho em seus torpedos, eles podem mudar de direção se baterem no limite do mapa!"),
	Tip29         = Translate("killing players while you're onboard their mothership gives you 3x the Booty reward!\\убивая игроков, пока вы находитесь на борту их материнского корабля, вы получаете в 3 раза больше добычи!\\matar jogadores enquanto você estiver no Navio-mãe deles fornecerá 3x a recompensa de Saque!"),
	Tip30         = Translate("auxilliary cores can be improvised into high-end explosives.\\вспомогательные сердца могут быть импровизированы в высококлассные взрывчатые вещества.\\núcleos auxiliares podem ser improvisados em explosivos de alta qualidade.");
}
