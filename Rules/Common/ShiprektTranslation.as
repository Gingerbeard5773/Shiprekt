
//translated strings for shiprekt

//works by seperating each language by token '\\'
//in order- english, russian, portegeuse, polish, french
//"Translation\\перевод\\tradução\\tłumaczenie\\Traduction"

//Translators: GoldenGuy, Moz

//TODO: perhaps switch to a dictionary once kag updates to staging
//Could also seperate languages by namespaces and then call from namespaces from namespaces depending on locale, this would enable the ability to seperate languages by file

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
	//if (g_locale == "fr")
		//return tokens[4];
	if (g_locale == "pl")
		return tokens[3];
	
	return tokens[0];
}

namespace Trans
{
	const string
	
	//Generic
	Captain       = Translate("Captain\\Капитан\\Capitão\\Kapitan"),
	Total         = Translate("Total\\Всего\\Total\\Łączny"),
	Wooden        = Translate("Wooden\\Деревянный\\de madeira\\Drewniany"),
	Booty         = Translate("Booty\\Добыча\\Saque\\Łup"),
	Core          = Translate("Core\\Сердце\\Núcleo\\Rdzeń"),
	Mothership    = Translate("Mothership\\Главный корабль\\Navio-mãe\\Mothership"),
	Miniship      = Translate("Miniship\\Мини корабль\\Mini-navio\\Ministatek"),
	Ship          = Translate("Ship\\Корабль\\Navio\\Statek"),
	Speed         = Translate("Speed\\Скорость\\Velocidade\\Prędkość"),
	Weight        = Translate("Weight\\Вес\\Peso\\Ciężar"),
	Team          = Translate("Team\\Комманда\\Time\\Zespół"),
	
	//Hud
	CoreHealth    = Translate("Team Core Health\\Здоровье сердца комманды\\Vida do Núcleo do Time\\Podstawowa kondycja zespołu"),
	Relinquish    = Translate("Click to relinquish ownership of a nearby seat\\Нажми чтобы завладеть ближайшим креслом\\Clique para renunciar a liderança de um assento próximo\\Kliknij, aby zrzec się prawa własności do pobliskiej siedziby"),
	Transfer      = Translate("Click to transfer {booty} Booty to\\Нажми чтобы отдать {booty} Добычу\\Clique para transferir {booty} Saque para a\\Kliknij, aby przenieść {booty} Booty do"),
	ShipCrew      = Translate("your Mothership Crew\\всем в своей комманде\\tripulação do seu Navio-mãe\\Załoga statku-matki"),
	Bases         = Translate("Captured Bases\\Захваченные базы\\Bases Capturadas\\Zdobyte bazy"),
	FreeMode      = Translate("Free Building Mode - Waiting for players to join.\\Режим свободного строительства - Ждём пока присоединятся люди.\\Modo de Construção Livre - Aguardando a entrada de jogadores.\\Darmowy tryb budowania - Oczekiwanie na dołączenie graczy."),
	KillSharks    = Translate("Kill sharks to gain some Booty\\Убивай акул для получения Добычи\\Mate tubarões para ganhar um pouco de Saque\\Zabij rekiny, aby zdobyć trochę łupów"),
	CouplingRDY   = Translate("Couplings ready.\nPress [{key}] to take.\\Соединения готовы. \nНажми [{key}] чтобы создать.\\Acoplamentos prontos.\nPressione [{key}] para pegar.\\Złącza gotowe.\nNaciśnij [{key}], aby wziąć."),
	ShipAttack    = Translate("YOUR MOTHERSHIP IS UNDER ATTACK!!\\ВАШ ГЛАВНЫЙ КОРАБЛЬ ПОД АТАКОЙ!!\\SEU NAVIO-MÃE ESTÁ SOB ATAQUE!!\\TWÓJ STATEK-MATKA JEST ATAKOWANY!!"),
	Abandon       = Translate("> You are your Team's Captain <\n\nDon't abandon the Mothership!\\> Вы капитан комманды <\n\nНе покидайте корабль!\\> Você é o Capitão do seu Time <\n\nNão abandone o Navio-mãe!\\> Jesteś kapitanem swojego zespołu <\n\nNie porzucaj statku-matki!"),
	ReducedCosts  = Translate("Costs reduced during warmup\\Цены уменьшены во время подготовки\\Custos reduzidos durante o aquecimento\\Zmniejszone koszty podczas rozgrzewki"),
	Reclaiming    = Translate("You are reclaiming someone else's property. Progress will be slower\\##\\Você está reivindicando a propriedade de outra pessoa. O progresso será mais lento\\Odzyskujesz cudzą własność. Postęp będzie wolniejszy"),
	WarmupPlacing = Translate("You can only place Couplings and Repulsors on the Mothership during warm-up\\#\\Você só pode colocar Acoplamntos e Repulsores no Navio-mãe durante o aquecimento\\Sprzęgła i repulsory można umieszczać na statku-matce tylko podczas rozgrzewki"),
	ReleaseCoup1  = Translate("Use left click to release them individually or right click to release all the couplings you've placed\\##\\Use o botão esquerdo para soltá-los individualmente ou botão direito para soltar todos os acoplamentos que você colocou\\Użyj lewego przycisku myszy, aby zwolnić je pojedynczo lub kliknij prawym przyciskiem myszy, aby zwolnić wszystkie umieszczone złącza"),
	ReleaseCoup2  = Translate("PRESS AND HOLD SPACEBAR TO RELEASE COUPLINGS\\##\\PRESSIONE E SEGURE A BARRA DE ESPAÇO PARA LIBERAR ACOPLAMENTOS\\NACIŚNIJ I PRZYTRZYMAJ SPACJĘ, ABY ZWOLNIĆ ŁĄCZNIKI"),
	FlaksLimit    = Translate("Flaks limit reached!\\##\\Limite de antiaéreos alcançado!\\Osiągnięto limit flaków!"),
	BootyTransW   = Translate("Click to transfer Booty (enabled after warm-up)\\##\\Clique para transferir Saque (habilitado após aquecimento)\\Kliknij, aby przenieść Booty (włączone po rozgrzewce)"),
	BootyTransM   = Translate("Click to transfer Booty ({booty} Booty minimum)\\##\\Clique para transferir Saque ({booty} Saque mínimo)\\Kliknij, aby przenieść łup (minimum {booty})"),
	FindNewTip    = Translate("Press Right Click to find another tip\\##\\Pressione Botão Direito para achar outra dica\\Naciśnij prawym przyciskiem myszy, aby znaleźć kolejną wskazówkę"),
	Respawn       = Translate("Respawning...\\##\\Renascendo...\\Odradzanie..."),
	RespawnSoon   = Translate("Respawning soon...\\##\\Renascendo em breve...\\Odrodzenie wkrótce..."),
	
	//Votes
	Vote          = Translate("Vote\\Голосование\\Vote\\Głosować"),
	SuddenDeath   = Translate("Sudden Death\\Внезапная смерть\\Morte Súbita\\Nagła śmierć"),
	Freebuild     = Translate("Freebuild\\Свободное строительство\\Construção Livre\\Tryb swobodnej budowy"),
	FreebuildMode = Translate("Free-build mode\\##\\Modo de Construção Livre\\Tryb swobodnej budowy"),
	SpeedThings   = Translate("Speed things up!\\##\\Acelere as coisas!\\Przyspiesz wszystko!"),
	ActiveDeath   = Translate("Sudden Death is already active!\\##\\Morte Súbita já está ativa!\\Nagła śmierć jest już aktywna!"),
	DeathStarted  = Translate("Sudden Death Started! Focus on destroying your enemies' engines so they can't escape the Whirlpool!\\##\\Morte Súbita Começou! Foque em destruir os motores de seus inimigos para que eles não consigam escapar do Redemoinho!\\Rozpoczęła się nagła śmierć! Skoncentruj się na niszczeniu silników wrogów, aby nie mogli uciec z Whirlpool!"),
	AttackReward  = Translate("Players get a huge Booty reward bonus from direct attacks.\\##\\Jogadores ganham uma enorme recompensa bonus de Saque com ataques diretos.\\Gracze otrzymują ogromną premię za łupy z bezpośrednich ataków."),
	WeightNote    = Translate("Note: removing heavy blocks from your ship doesn't help! Heavier ships are pulled less by the Whirlpool\\##\\Aviso: remover blocos pesados do seu navio não ajuda! Navios mais pesados são menos puxados pelo Redemoinho\\Uwaga: usuwanie ciężkich bloków ze statku nie pomaga! Cięższe statki są mniej ciągnięte przez Whirlpool"),
	BuildEnabled  = Translate("Free building mode enabled. Blocks are free! Start a new free building mode vote to return to the normal game mode\\##\\Modo de construção livre habilitado. Blocos são grátis! Inicie uma nova votação de modo de construção livre para retornar ao modo de jogo normal\\Włączony tryb swobodnego budowania. Bloki są darmowe! Rozpocznij nowy darmowy głos w trybie budowania, aby powrócić do normalnego trybu gry"),
	BuildDisabled = Translate("Free building mode disabled. Start a new free building mode vote to return to the free building game mode\\##\\Modo de construção livre desabilitado. Inicie uma nova votação de modo de construção livre para retornar ao modo de jogo de construção\\ryb swobodnego budowania wyłączony. Rozpocznij nowy darmowy głos w trybie budowania, aby powrócić do darmowego trybu budowania"),
	SwitchTime    = Translate("Time left to switch again:\\##\\Tempo restante para mudar novamente:\\Pozostały czas na ponowne przełączenie:"),
	Minutes       = Translate("minutes\\##\\minutos\\minuty"),
	TooLong       = Translate("Match taking too long?\\##\\Partida demorando demais?\\Mecz trwa zbyt długo?"),
	Enable        = Translate("Enable\\##\\Habilitar\\Włączać"),
	Disable       = Translate("Disable\\##\\Desabilitar\\Wyłączyć"),
	Failed        = Translate("Failed\\##\\Falhou\\Przegrany"),
	
	//Help menu
	Welcome       = Translate("Welcome to Shiprekt! Made by Strathos, Chrispin, and various other community members.\nLast changes and fixes by\\##\\Bem-vindo ao Shiprekt! Feito por Strathos, Chrispin e diversos membros da comunidade.\nÚltimas mudanças e correções por\\Witamy w Shiprekt! Wykonane przez Strathosa, Chrispina i różnych innych członków społeczności.\nOstatnie zmiany i poprawki autorstwa"),
	Version       = Translate("Version\\Версия\\Versão\\Wersja"),
	LastChanges   = Translate("Last Changes\\##\\Últimas mudanças\\Ostatnie zmiany"),
	Go_to_the     = Translate("Go to the\\Перейти\\Vá para o\\Przejdź do"),
	ChangePage    = Translate("Press Left Click to change page | F1 to toggle this help Box (or type !help)\\Нажмите ЛКМ чтобы сменить страницу | F1 чтобы открыть это окно (или введите !help в чате)\\Pressione o Botão Esquerdo para mudar de página | F1 para habilitar essa Caixa de ajuda (ou digite !help)\\Naciśnij przycisk left click, aby zmienić | strony F1, aby przełączyć tę pomoc Box (lub wpisz !help)"),
	ClickIcons    = Translate("Click these Icons for Control and Booty functions!\\Нажмите эти иконки для управления и функций Добычи\\Clique nesses Ícones para funções de Controle e Saque!\\Kliknij te ikony, aby uzyskać funkcje sterowania i łupów!"),
	FastGraphics  = Translate("Having lag issues? Turn on Faster Graphics in KAG video settings for possible improvement!\\Проблемы с лагами? Включите Faster Graphics в настройках видео для возможного улучшения!\\Vivenciando problemas de rede? Habilite os Gráficos Rápidos nas configurações de vídeo do KAG para uma possível melhora!\\Masz problemy z opóźnieniami? Włącz Szybszą grafikę w ustawieniach wideo KAG, aby uzyskać możliwą poprawę!"),
	Caption1      = Translate("Use Propellers and Couplings to build Torpedoes\\##\\Use Hélices e Acoplamentos para construir Torpedos\\Użyj śmigieł i sprzęgieł do budowy torped"),
	Caption2      = Translate("Couplings let you dock with your Mothership\\##\\Acoplamentos lhe permitem atracar com seu Navio-mãe\\Złącza umożliwiają dokowanie do statku-matki"),
	Caption3      = Translate("Use Couplings to build new ships\\##\\Use Acoplamentos para construir novos navios\\Użyj sprzęgieł do budowy nowych statków"),
	Caption4      = Translate("Navigate to Xs to gather Booty\\##\\Navegue até Xs para coletar Saque\\Przejdź do Xs, aby zebrać Łup"),
	
	//How to play
	HowToPlay     = Translate("How to Play\\Как играть\\Como Jogar\\Jak grać"),
	GatherX       = Translate("Gather Xs for Booty. Xs have more Booty the closer they spawn to the map center.\\Стойте на Х-ах для Добычи. Х-ы ближе к центру карты дают больше Добычи.\\Colha Xs por Saque. Quanto mais perto do centro do mapa os Xs nascem, mais Saque eles têm.\\Zbierz Xs dla Booty. Xs mają więcej Łupów, im bliżej odradzają się do centrum mapy."),
	EngineWeak    = Translate("Engines are very weak! Use wood hull blocks as armor or Miniships will eat through them!\\Двигатели очень слабые! Используй деревянные каркасные блоки для защиты корабля!\\Motores estão muito fracos! Use blocos de casco de madeira como armadura ou Mini-navios irão devorar tudo!\\Silniki są bardzo słabe! Użyj drewnianych bloków kadłuba jako zbroi lub ministatki zjedzą przez nie!"),
	YieldX        = Translate("Xs yield little Booty, but weapons reward a lot per hit to enemy ships!\\Х-ы дают мало Добычи, но стрельба по вражеским кораблям гораздо больше!\\Xs rendem pouco Saque, mas as armas recompensam muito por acerto aos navios inimigos!\\Xs dają mały łup, ale broń nagradza dużo za trafienie wrogich statków!"),
	Docking       = Translate("Couplings stick to your Mothership on collision. Use them to dock with it.\\Соединения прилипают к Главному кораблю при соприкосновении с ним. Используй их для стыковки.\\Os acoplamentos aderem ao seu Navio-mãe em caso de colisão. Use-os para atracar.\\Sprzęgła przyklejają się do twojego statku-matki podczas kolizji. Użyj ich, aby zadokować z nim."),
	OtherTips     = Translate("Other Tips\\Прочие подсказки\\Outras Dicas\\Inne wskazówki"),
	Leaderboard   = Translate("The higher a team is on the leaderboard, the more Booty you get for attacking them.\\Чем выше комманда в таблице, тем больше Добычи получишь за атаку на них.\\Quanto mais alto um time está na tabela de classificação, mais Saque você ganhará ao atacá-los.\\Im wyżej drużyna znajduje się w tabeli liderów, tym więcej łupów dostajesz za atakowanie jej."),
	BlockWeight   = Translate("Each block has a different weight. The heavier, the more they slow your ship down.\\Каждый блок имеет разный вес. Чем тяжелее твой корабль, тем медленнее он будет.\\Cada bloco tem um peso diferente. Quanto mais pesado for, mais devagar seu navio ficará.\\Każdy blok ma inną wagę. Im cięższy,  tym bardziej spowalniają twój statek."),
	
	//Controls
	Controls      = Translate("Controls\\Управление\\Controles\\Formantów"),
	Hold          = Translate("<hold>\\<зажми>\\<segure>\\<hold>"),
	GetBlocks     = Translate("get Blocks while aboard your Mothership. Produces couplings while in a seat.\\взять блок когда на главном корабле. Создаёт соединеие когда в кресле.\\pegar Blocos enquanto estiver a bordo de seu Navio-mãe. Produzir acoplamentos enquanto estiver em um assento.\\zdobądź Bloki na pokładzie statku-matki. Wytwarza sprzęgła w fotelu."),
	RotateBlocks  = Translate("rotate blocks while building or release couplings when sitting.\\повернуть блок когда строишь или убирает соединения когда в кресле.\\rotacionar blocos enquanto constrói ou soltar acoplamentos enquanto estiver sentado.\\obracaj bloki podczas budowania lub zwalniania sprzęgieł podczas siedzenia."),
	Punch         = Translate("punch when standing or fire Machineguns when sitting.\\удар когда стоишь или выстрел из пулеметов когда сидишь.\\socar enquanto estiver de pé ou atirar com Metralhadoras enquanto estiver sentado.\\uderzać podczas stania lub strzelać z karabinów maszynowych podczas siedzenia."),
	FireGun       = Translate("fire handgun or fire Cannons when sitting.\\выстрел пистолета или выстрел из пушек когда сидишь.\\atirar com uma arma de fogo ou atirar com Canhões enquanto estiver sentado.\\strzelaj z pistoletu lub strzelaj z armat podczas siedzenia."),
	PointEmote    = Translate("show point emote.\\показать эмоцию-указатель.\\mostrar o emote de apontar.\\pokaż emotkę punktu."),
	Zoom          = Translate("zoom in/out.\\приблизить/отдалить\\dar zoom para dentro/fora.\\powiększanie/pomniejszanie."),
	AccessTools   = Translate("access the tools menu.\\открыть меню инструментов.\\acessar o menu de ferramentas.\\przejdź do menu narzędzi."),
	ScaleCompass  = Translate("scale the Compass 2x. Tap to toggle. Hold for a quick view.\\увеличит компас в 2 раза. Нажми для удержания или зажми для временного просмотра.\\escalar a Bússola 2x. Clique para habilitar. Sgure para uma olhada breve.\\skaluj Kompas 2x. Dotknij, aby przełączyć. Przytrzymaj, aby wyświetlić szybki widok."),
	Strafe        = Translate("toggle engines strafe mode\\##\\habilitar o modo strafe dos motores\\włącz tryb strafe silników"),
	
	//Build menu
	Components    = Translate("Components\\Компоненты\\Componentes\\Składniki"),
	AmmoCap       = Translate("AmmoCap\\Боеприпасы\\Munição\\Amunicja"),
	WarmupWarning = Translate("Weapons are enabled after the warm-up time ends\\##\\Armas são habilitadas depois que o tempo do aquecimendo acabar\\Bronie są włączone po zakończeniu czasu rozgrzewania"),
	BuyAgain      = Translate("Press the inventory key to buy again.\\##\\Pressione a tecla de inventário para comprar novamente.\\Naciśnij klawisz ekwipunku, aby kupić ponownie."),
	Seat          = Translate("Seat\\Кресло\\Assento\\Siedzenie"),
	Engine        = Translate("Standard Engine\\Стандартный Двигатель\\Motor Padrão\\Standardowy silnik"),
	RamEngine     = Translate("Ram Engine\\Быстрый Двигатель\\Motor de Aríete\\Silnik Baran"),
	Coupling      = Translate("Coupling\\Соединение\\Acoplamento\\Sprzęg"),
	Hull          = Translate("Wooden Hull\\Каркас\\Casco de madeira\\Kadłub"),
	Platform      = Translate("Wooden Platform\\Платформа\\Plataforma de madeira\\Podest"),
	Door          = Translate("Wooden Door\\Дверь\\Porta de madeira\\Drzwi"),
	Piston        = Translate("Wooden Piston\\Поршень\\Pistão de madeira\\Tłok"),
	Harpoon       = Translate("Harpoon\\Гарпун\\Harpão\\Harpun"),
	Harvester     = Translate("Harvester\\Ломатель\\Colheitadeira\\Żniwiarka"),
	Patcher       = Translate("Patcher\\Чинитель\\Reparador\\Łatacz"),
	AntiRam       = Translate("Anti-Ram\\Анти-Таран\\Anti-Aríete\\Anty-Baran"),
	Repulsor      = Translate("Repulsor\\Репульсор\\Repulsor\\Repulsor"),
	Ram           = Translate("Ram Hull\\Таран\\Aríete\\Baran"),
	Auxilliary    = Translate("Auxilliary Core\\Вспомогательное Сердце\\Núcleo Auxiliar\\Rdzeń pomocniczy"),
	Bomb          = Translate("Bomb\\##\\Bomba\\Bomba"),
	PointDefense  = Translate("Point Defense\\Защитная турель\\Defesa de Ponto\\Obrona punktowa"),
	FlakCannon    = Translate("Flak Cannon\\Зенитная Пушка\\Canhão Antiaéreo\\Działo"),
	Machinegun    = Translate("Machinegun\\Пулемёт\\Metralhadora\\Karabin maszynowy"),
	Cannon        = Translate("Cannon\\Пушка\\Canhão\\Armata"),
	Launcher      = Translate("Missile Launcher\\Ракетная Установка\\Lança-Mísseis\\Wyrzutnia pocisków"),
	DecoyCore     = Translate("Decoy Core\\Фальшивое Сердце\\Núcleo de Distração\\Rdzeń wabika"),
	
	SeatDesc      = Translate("Use it to control your ship. It can also release and produce Couplings.\nBreaks on impact.\\Используйте его, чтобы управлять своим кораблем. Он также может освобождать и производить соединения.\nЛомается при ударе.\\Use-o para controlar seu navio. Ele Também pode liberar e produzir Acoplamentos.\nQuebra com impacto.\\Użyj go do kontrolowania swojego statku. Może również uwalniać i produkować sprzęgła.\nPrzerwy przy uderzeniu."),
	EngineDesc    = Translate("A ship motor with some armor plating for protection.\\Корабельный мотор с броней для защиты.\\Um motor de navio com um pouco de blindagem para proteção.\\Silnik okrętowy z pewnym pancerzem dla ochrony."),
	RamEngineDesc = Translate("An engine that trades protection for extra power.\\Двигатель без защиты но с дополнительной мощностью.\\Um motor que troca proteção por potência extra.\\Silnik, który zamienia ochronę na dodatkową moc."),
	CouplingDesc  = Translate("A versatile block used to hold and release other blocks.\\Универсальный блок, используемый для удержания и освобождения других блоков.\\Um bloco versátil usado para segurar e soltar outros blocos.\\Uniwersalny blok służący do przytrzymywania i zwalniania innych bloków."),
	WoodHullDesc  = Translate("A very tough block for protecting delicate components.\\Очень прочный блок для защиты хрупких блоков.\\Um bloco bem duro para proteger componentes delicados.\\Bardzo wytrzymały blok do ochrony delikatnych elementów."),
	PlatformDesc  = Translate("A good quality wooden floor panel. Get that deck shining.\\Качественная деревянная панель для пола.\\Um painel de piso de madeira de boa qualidade. Deixe o convés brilhando.\\Dobrej jakości drewniany panel podłogowy. Spraw, aby ta talia lśniła."),
	DoorDesc      = Translate("A wooden door. Useful for ship security.\\Деревянная дверь. Полезно для охраны корабля.\\Útil para a segurança do navio.\\Drewniane drzwi. Przydatny do ochrony statku."),
	PistonDesc    = Translate("A piston. Can be used to push and pull segments of a ship.\\Поршень. Используется, чтобы толкать и тянуть сегменты корабля.\\Um pistão. Pode ser utilizado para empurrar e puxar segmentos de um navio.\\Tłok. Może być używany do pchania i ciągnięcia segmentów statku."),
	HarpoonDesc   = Translate("A manual-fire harpoon launcher. Can be used for grabbing, towing, or water skiing!\\Гарпунная пусковая установка с ручным огнем. Может использоваться для захвата, буксировки или катания на водных лыжах!\\Um lançador de harpão de fogo manual. Pode ser utilizado para agarrar, rebocar ou esqui-aquático!\\Wyrzutnia harpunów ręcznego ognia. Może być używany do chwytania, holowania lub jazdy na nartach wodnych!"),
	HarvesterDesc = Translate("An industrial-sized deconstructor that allows you to quickly mine resources from ship debris.\\Деконструктор промышленных размеров, позволяющий быстро добывать ресурсы из корабельных обломков.\\Um desconstrutor de tamanho industrial que permite extrair rapidamente recursos de detritos de navios.\\Dekonstruktor wielkości przemysłowej, który pozwala szybko wydobywać zasoby z gruzu statku."),
	PatcherDesc   = Translate("Emits a regenerative beam that can repair multiple components at once.\\Излучает регенеративный луч, который может восстанавливать несколько блоков одновременно.\\Emite um feixe regenerativo que pode reparar múltiplos componentes de uma vez.\\Emituje wiązkę regeneracyjną, która może naprawiać wiele komponentów jednocześnie."),
	AntiRamDesc   = Translate("Can absorb and negate multiple ram components, however weak against projectiles.\\Может поглощать и блокировать несколько блоков Тарана, однако слаб против снарядов.\\Pode absorver e negar múltiplos componentes de aríete, entretanto é fraco contra projéteis.\\Może absorbować i negować wiele elementów barana, jednak słabych przeciwko pociskom."),
	RepulsorDesc  = Translate("Explodes pushing blocks away. Can be triggered remotely or by impact. Activates in a chain.\\Взрывается, отталкивая блоки. Может запускаться дистанционно или ударом. Активируется по цепочке.\\Explode empurrando blocos para longe. Pode ser acionado remotamente ou por impacto. Ativa em uma cadeia.\\Wybucha odpychając bloki. Może być wyzwalany zdalnie lub przez uderzenie. Aktywuje się w łańcuchu."),
	RamDesc       = Translate("A rigid block that fractures on contact with other blocks. Will destroy itself as well as the block it hits.\\Жесткий блок, который ломается при контакте с другими блоками. Уничтожает себя, а также блок, в который попадает.\\Um bloco rígido que fratura em contato com outros blocos. Destruirá a si mesmo, assim como o bloco que atingir.\\Sztywny blok, który pęka w kontakcie z innymi blokami. Zniszczy siebie, a także blok, w który uderzy."),
	AuxillDesc    = Translate("Similar to the Mothership core. Very powerful - gives greater independence to support ships.\\Подобно Сердцу главного корабля. Очень мощный - дает большую независимость мини-кораблям.\\Semelhante ao núcleo do Navio-mãe. Muito poderoso - fornece maior independência para navios de suporte.\\Podobny do rdzenia Statku-Matki. Bardzo potężny - daje większą niezależność do wspierania statków."),
	BombDesc      = Translate("Explodes on contact. Very useful against Solid blocks.\\Взрывается при контакте. Очень полезно против твёрдых блоков.\\Explode em contato. Muito útil contra blocos Sólidos.\\Wybucha w kontakcie. Bardzo przydatny przeciwko blokom solidnym."),
	PointDefDesc  = Translate("A short-ranged automated defensive turret. Neutralizes airborne projectiles such as flak.\\Автоматическая оборонительная турель ближнего действия. Нейтрализует летающие снаряды, такие как снаряды зенитных пушек.\\Uma torre de defesa automatizada de curta distância. Neutraliza projéteis no ar como um antiaéreo.\\Zautomatyzowana wieża obronna o krótkim zasięgu. Neutralizuje pociski unoszące się w powietrzu, takie jak."),
	FlakDesc      = Translate("A long-ranged automated defensive turret that fires explosive shells with a proximity fuse.\\Автоматизированная защитная турель дальнего действия, стреляющая разрывными снарядами с взрывателем дальности.\\Uma torre de defesa automatizada de longa distância que dispara projéteis explosivos com um fusível de proximidade.\\Zautomatyzowana wieża obronna dalekiego zasięgu, która wystrzeliwuje pociski wybuchowe z zapalnikiem zbliżeniowym."),
	MGDesc        = Translate("A fixed rapid-fire, lightweight, machinegun that fires high-velocity projectiles.\nEffective against engines.\\Неподвижный скорострельный легкий пулемет, стреляющий высокоскоростными снарядами.\nЭффективен против двигателей.\\Uma metralhadora fixa leve e de alta cadência que dispara projéteis de alta velocidade.\nEficaz contra motores.\\Stały szybkostrzelny, lekki karabin maszynowy, który strzela pociskami o dużej prędkości.\nSkuteczny przeciwko silnikom."),
	CannonDesc    = Translate("A fixed cannon that fires momentum-bearing armor-piercing shells.\\Стационарная пушка, которая стреляет бронебойными снарядами с импульсом.\\Um canhão fixo que dispara projéteis perfurantes com impulso.\\Stałe działo, które wystrzeliwuje pociski przeciwpancerne z pędem."),
	LauncherDesc  = Translate("A fixed tube that fires a slow missile with short-ranged guidance.\nVery effective against armored ships.\\Неподвижная труба, стреляющая медленной ракетой с малой дальностью наведения.\nОчень эффективна против бронированных кораблей.\\Um tubo fixo que dispara um míssil lento com orientação de curto alcance.\\Stała rura, która wystrzeliwuje powolny pocisk z naprowadzaniem na krótki dystans.\nBardzo skuteczny przeciwko okrętom pancernym."),
	DecoyCoreDesc = Translate("A fake core to fool enemies. Replaces the Mothership on the compass.\\Фальшивое сердце, чтобы одурачить врагов. Заменяет главное сердце на компасе.\\Um núcleo falso para enganar inimigos. Substitui o Navio-mãe na bússola.\\Fałszywy rdzeń do oszukiwania wrogów. Zastępuje statek macierzysty na kompasie."),
	
	//Tools
	ToolsMenu     = Translate("Tools Menu\\##\\Menu de Ferramentas\\Menu narzędzi"),
	Pistol        = Translate("Pistol\\Пистолет\\Pistola\\Pistolet"),
	PistolDesc    = Translate("A basic, ranged, personal defense weapon.\\Обычное средство персональной защиты дальнего действия.\\Uma arma básica de defesa pessoal à distância.\\Podstawowa, dystansowa, osobista broń obronna."),
	Deconstructor = Translate("Deconstructor\\Деконструктор\\Desconstrutor\\Dekonstruktor"),
	DeconstDesc   = Translate("A tool that can reclaim ship parts for booty.\\Инструмент для разборки частей корабля на Добычу.\\Uma ferramenta que consegue recuperar partes do navio para saque.\\Narzędzie, które może odzyskać części do statku na łupy."),
	Reconstructor = Translate("Reconstructor\\Реконструктор\\Reconstrutor\\Rekonstruktor"),
	ReconstDesc   = Translate("A tool that can repair ship parts at the cost of booty.\\Инструмент для починки частей корабля за Добычу.\\Uma ferramenta que consegue reparar partes do navio ao custo de saque.\\Narzędzie, które może naprawiać części do statków kosztem łupów."),
	
	//Events
	SettingFree   = Translate("{playercount} player(s) in map. Setting freebuild mode until more players join.\\##\\##\\{playercount} graczy na mapie. Ustawiam tryb swobodnej budowy, dopóki nie dołączy więcej graczy."),
	CoreKill      = Translate("Congratulations! A Core Kill was added to your Scoreboard.\\##\\##\\Gratulacje! Do tablicy wyników dodano główne zabójstwo."),
	TeamBounty    = Translate("{winnerteam} gets {reward} Booty for destroying {killedteam}\\##\\##\\{winnerteam} dostaje {reward} łup za zniszczenie {killedteam}");
}

//arrays for indexing purposes

const string[] teamColors =
{
	Translate("Blue\\Синие\\Azul\\Niebieski"),
	Translate("Red\\Красные\\Vermelho\\Czerwony"),
	Translate("Green\\Зелёные\\Verde\\Zielony"),
	Translate("Purple\\Фиолетовые\\Roxo\\Purpura"),
	Translate("Orange\\Оранжевые\\Laranja\\Pomarańcza"),
	Translate("Cyan\\Бирюзовые\\Ciano\\Błękitny"),
	Translate("Navy Blue\\Тёмно-синие\\Azul-marinho\\Granatowy"),
	Translate("Beige\\Бежевые\\Bege\\Beż")
};
	
const string[] shiprektTips =
{
	Translate("Pistols deal fair damage to Mothership Cores, but Machineguns are not effective at all!\\пистолеты наносят приличный урон Сердцу главного корабля, а Пулеметы совсем не эффективны!\\pistolas causam dano decente aos Núcleos de Navios-mãe, porém Metralhadoras não são nem um pouco eficazes!\\pistolety zadają uczciwe obrażenia rdzeniom statku-matki, ale karabiny maszynowe nie są w ogóle skuteczne!"),
	Translate("Target enemy ships that are higher on the leaderboard to get bigger rewards.\\атакуйте вражеские корабли, которые выше в таблице, чтобы получить большие награды.\\mire em navios inimigos que se encontram mais alto na tabela de classificação para conseguir recompensas melhores.\\celuj w wrogie okręty, które znajdują się wyżej w tabeli liderów, aby uzyskać większe nagrody."),
	Translate("Machineguns and flak obliterate engines. Motherships need to place Solid blocks to counter this!\\пулеметы и зенитки уничтожают двигатели. Главные корабли должны размещать каркасные блоки, чтобы противостоять этому!\\metralhadoras e antiaéreos dizimam motores. Navios-mãe precisam colocar blocos Sólidos para combater isso!\\karabiny maszynowe i zacierają silniki. Statki-matki muszą umieszczać solidne bloki, aby temu przeciwdziałać!"),
	Translate("Weapons don't stack! If you line them up only the outmost one will fire.\\оружие не стакается! Если вы выстроите их в линию, сработает только крайние из них.\\armas não empilham! Se você alinhá-las, apenas a mais distante irá disparar.\\broń nie kumuluje się! Jeśli ustawisz je w linii, tylko najwyższy z nich wystrzeli."),
	Translate("Flak cannons get a fire rate boost when they are manned.\\зенитные пушки получают повышение скорострельности, когда они пилотируются.\\canhões antiaéreos recebem um impulso de taxa de cadência quando são controlados manualmente.\\armaty zwiększają szybkostrzelność, gdy są obsadzone."),
	Translate("While on a Miniship, don't bother gathering Xs until they disappear. Instead always look for bigger Xs.\\находясь на мини-корабле, не утруждайте себя сбором Х-ов пока они не исчезнут. Вместо этого всегда ищите большие Х-ы.\\enquanto estiver em um Mini-navio, não se preocupe em coletar Xs até desaparecerem. Em vez disso, sempre procure por Xs maiores.\\będąc na Minisłodzie, nie zawracaj sobie głowy zbieraniem Xs, dopóki nie znikną. Zamiast tego zawsze szukaj większych Xs."),
	Translate("Removing heavy blocks on Sudden Death doesn't help! Heavier ships are pulled less by the Whirlpool.\\снятие тяжелых блоков во время Внезапной Смерти не помогает! Водоворот меньше притягивает более тяжелые корабли.\\remover blocos pesados na Morte Súbita não ajuda! Navios mais pesados são puxados menos pelo Redemoinho.\\usuwanie ciężkich bloków na Sudden Death nie pomaga! Cięższe statki są mniej ciągnięte przez Whirlpool."),
	Translate("Docking: press [F]. Place the couplings on your Miniship. Bump the couplings against your Mothership.\\стыковка: нажмите [F]. Поместите Соединения на свой мини-корабль. Коснитесь Соединениями о свой главный корабль.\\atracando: pressione [F]. Coloque os acoplamentos no seu Mini-navio. Bata os acoplamentos contra seu Navio-mãe.\\dokowanie: naciśnij [F]. Umieść sprzęgła na swoim miniokręgu. Uderz w sprzężenia o swój Statek-Matkę."),
	Translate("Launching torpedoes: accelerate so the torpedo engine starts and break the coupling with spacebar.\\запуск торпед: разгонитесь до запуска торпедного двигателя и разорвите Соединение пробелом.\\lançando torpedos: acelere para que o motor do torpedo dê partida e quebre o acoplamento com a barra de espaço.\\wystrzeliwanie torped: przyspiesz, aby silnik torpedowy uruchomił się i przerwał sprzęg z spacją."),
	Translate("An engine's propeller blades destroy blocks, so be mindful of where you dock!\\лопасти пропеллера двигателя разрушают блоки, так что следите за тем, где вы швартуетесь!\\as pás da hélice de um motor destroem blocos, então fique atento de onde irá atracar!\\łopaty śmigła silnika niszczą bloki, więc pamiętaj o tym, gdzie dokujesz!"),
	Translate("Destroy an enemy core so your whole team gets a Bounty! High ranking teams give bigger rewards.\\уничтожьте вражеское сердце, чтобы вся ваша команда получила награду! Команды с выше в таблтце дают больше награды.\\destrua um núcleo inimigo para que seu time inteiro consiga uma Recompensa! Times com alta classificação dão recompensas maiores.\\zniszcz rdzeń wroga, aby cała twoja drużyna otrzymała bounty! Wysoko postawione zespoły dają większe nagrody."),
	Translate("Transfer Booty to your teammates by clicking the Coin icon at the lower HUD.\\передайте Добычу своим товарищам по команде, щелкнув значок монеты внизу.\\transfira Saque para seus colegas de equipe clicando no ícone de Moeda no HUD inferior.\\przekaż łup kolegom z drużyny, klikając ikonę Monety na dolnym HUD."),
	Translate("Relinquish ownership of a seat by standing next to it and clicking the Star icon at the lower HUD.\\отказаться от права собственности на кресло, встав рядом с ним и щелкнув значок звездочки в низу.\\renuncie a liderança de um assento ao ficar em pé próximo a ele e clicar no ícone da Estrela no HUD inferior.\\zrzekaj się własności miejsca, stojąc obok niego i klikając ikonę gwiazdki na dolnym HUD."),
	Translate("Double tap the [F] key to re-purchase the last bought item while on your Mothership.\\дважды нажмите клавишу [F], чтобы повторно купить последний купленный предмет, находясь на главном корабле.\\clique duas vezes na tecla [F] para comprar novamente o último item que você havia comprado enquanto está no seu Navio-mãe.\\dotknij dwukrotnie [F], aby ponownie kupić ostatnio kupiony przedmiot na statku-matce."),
	Translate("You can check how many enemy Motherships you have destroyed on the Tab board.\\Вы можете проверить, сколько вражеских главных кораблей вы уничтожили на вкладке Tab.\\você pode checar quantos Navios-mãe inimios você já destruiu na tabela do Tab.\\możesz sprawdzić, ile wrogich statków-matek zniszczyłeś na planszy Tab."),
	Translate("Have the urge to point at something? Press and hold middle click.\\есть желание указать на что-то? Нажмите и удерживайте колёсико мыши.\\sente a necessidade de apontar para algo? Pressione e segure o botão do meio do mouse.\\masz ochotę na coś wskazać? Naciśnij i przytrzymaj środkowy przycisk myszy."),
	Translate("You can break Couplings and activate Repulsors post torpedo launch if you keep your spacebar pressed.\\вы можете сломать Соединеия и активировать репульсоры после запуска торпеды, если будете удерживать клавишу пробела.\\você pode quebrar Acoplamentos e ativar Repulsores após o lançamento de torpedo se você mantiver sua barra de espaço pressionada.\\możesz złamać sprzęgła i aktywować repulsory po wystrzeleniu torpedy, jeśli będziesz trzymał wciśnięty spację."),
	Translate("Break all the Couplings you've placed on your ship by holding spacebar and right clicking.\\сломайте все соединения, которые вы разместили на своем корабле, удерживая клавишу пробела и щелкая правой кнопкой мыши.\\quebre todos os Acoplamentos que você colocou no seu navio ao segurar a barra de espaço e clicar com o botão direito.\\złam wszystkie sprzęgła umieszczone na statku, przytrzymując spację i klikając prawym przyciskiem myszy."),
	Translate("Injured blocks cause less damage on collision.\\поврежденные блоки наносят меньше урона при столкновении.\\blocos danificados causam menos dano em colisões.\\uszkodzone bloki powodują mniejsze uszkodzenia podczas kolizji."),
	Translate("Strafe mode activates only the engines perpendicular to your ship.\\«режим стрейфа» активирует только двигатели, перпендикулярные вашему кораблю.\\o modo strafe ativa apenas os motores perpendiculares ao seu navio.\\'tryb strafe' aktywuje tylko silniki prostopadłe do twojego statku."),
	Translate("Players get a walk speed boost while aboard their Mothership.\\игроки получают повышение скорости ходьбы на борту своего главного корабля.\\jogadores ganham um impulso de velocidade de caminhada enquanto estiverem a bordo de seus Navios-mãe.\\gracze otrzymują zwiększenie prędkości chodu na pokładzie swojego statku-matki."),
	Translate("Players get healed over time while aboard their Mothership.\\игроки со временем исцеляются, находясь на борту своего главного корабля.\\jogadores são curados com o passar do tempo enquanto estiverem a bordo de seus Navios-mãe.\\gracze zostają uzdrowieni z czasem na pokładzie swojego statku-matki."),
	Translate("Adding more blocks to a ship will decrease its turning speed.\\добавление дополнительных блоков к кораблю уменьшает его скорость поворота.\\adicionar mais blocos para um navio irá reduzir sua velocidade de giro.\\dodanie większej liczby bloków do statku zmniejszy jego prędkość obrotową."),
	Translate("Stolen enemy ships convert to your team after some seconds of driving them.\\украденные вражеские корабли меняют команду на вашу после нескольких секунд управления ими.\\navios inimigos roubados são convertidos ao seu time após alguns segundos dirigindo-os.\\Skradzione wrogie okręty zamieniają się w twoją drużynę po kilku sekundach prowadzenia ich."),
	Translate("Kill sharks or enemy players to get a small Booty reward.\\убивайте акул или вражеских игроков, чтобы получить небольшую Добычу.\\mate tubarões ou jogadores inimigos para ganhar uma pequena recompensa de Saque.\\zabij rekiny lub wrogich graczy, aby otrzymać małą nagrodę Booty."),
	Translate("Crewmates get an Xs gathering boost while aboard their Mothership at the expense of their captain.\\товарищи по команде получают ускорение сбора X-ов на борту своего материнского корабля за счет своего капитана.\\tripulantes ganham um impulso de coleta de Xs enquanto estiverem a bordo de seus Navios-mãe às custas de seu capitão.\\Członkowie załogi otrzymują premię do zbierania Xs na pokładzie statku macierzystego kosztem swojego kapitana."),
	Translate("Xs give more Booty the closer they are to the center of the map.\\Х-ы дают больше добычи, чем ближе они к центру карты.\\Xs fornecem mais Saque conforme estão mais perto do centro do mapa.\\Xs dają więcej Łupów, im bliżej są środka mapy."),
	Translate("Repulsors will activate propellers in near vicinity on detonation.\\репульсоры активируют пропеллеры в непосредственной близости от детонации.\\repulsores ativarão as hélices nas proximidades na detonação.\\odpychacze aktywują śmigła w pobliżu podczas detonacji."),
	Translate("Keep an eye on your torpedoes, they can change direction if they bounce off the border!\\следите за своими торпедами, они могут изменить направление, если отскочат от границы карты!\\fique de olho em seus torpedos, eles podem mudar de direção se baterem no limite do mapa!\\miej oko na swoje torpedy, mogą zmienić kierunek, jeśli odbiją się od granicy!"),
	Translate("Killing players while you're onboard their mothership gives you 3x the Booty reward!\\убивая игроков, пока вы находитесь на борту их материнского корабля, вы получаете в 3 раза больше добычи!\\matar jogadores enquanto você estiver no Navio-mãe deles fornecerá 3x a recompensa de Saque!\\Zabijanie graczy, gdy jesteś na pokładzie ich statku-matki, daje ci 3x nagrodę Booty!"),
	Translate("Auxilliary cores can be improvised into high-end explosives.\\вспомогательные сердца могут быть импровизированы в высококлассные взрывчатые вещества.\\núcleos auxiliares podem ser improvisados em explosivos de alta qualidade.\\rdzenie pomocnicze można improwizować w wysokiej klasy materiały wybuchowe.")
};
