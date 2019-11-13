program demo;
uses sdl, sdl_ttf, sdl_image, sdl_gfx, INSACAR_TYPES, sysutils;

const
	C_REFRESHRATE = 90; {FPS} // TEST COMMIT
	C_UI_FENETRE_WIDTH = 1600;
	C_UI_FENETRE_HEIGHT = 900;
	
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR = 0.2; // kg.s^(-1)
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_EAU = 0.1;
	
	C_PHYSIQUE_VOITURE_ACCELERATION_AVANT = 5.6; // m.s^(-2)
	C_PHYSIQUE_VOITURE_ACCELERATION_ARRIERE = 12;// m.s^(-2)
	C_PHYSIQUE_VOITURE_ANGLE = 90; // Deg.s^(-1)
	
	C_UI_FENETRE_NOM = 'InsaCar Alpha 2.0';

procedure frame_afficher(var element: T_UI_ELEMENT; var frame: PSDL_Surface; etat: SDL_Rect);
var i : Integer;
begin
	case element.typeE of
		couleur:
		begin
			SDL_FillRect(element.surface, NIL, SDL_MapRGB(element.surface^.format, element.couleur.r, element.couleur.g, element.couleur.b));
		end;
		texte:
		begin
			element.surface := TTF_RenderText_Solid(element.police, Pchar(element.valeur), element.couleur);
		end;
		image:
		begin
		end;
	end;
	etat.x:=etat.x+element.etat.x;
	etat.y:=etat.y+element.etat.y;
	SDL_BlitSurface(element.surface, NIL, frame, @etat);
	for i:=0 to element.enfants.taille-1 do
	begin
		frame_afficher(element.enfants.t[i]^, frame, etat);
	end;
end;

procedure afficher_hud(var fenetre: T_UI_ELEMENT);
begin
end;

procedure afficher_camera(var infoPartie: T_GAMEPLAY; var fenetre: T_UI_ELEMENT);
var i : Integer;
begin
	for i:=0 to infoPartie.joueurs.taille-1 do
	begin
		infoPartie.joueurs.t[i].voiture.ui^.surface := rotozoomSurface(infoPartie.joueurs.t[i].voiture.couleur, infoPartie.joueurs.t[i].voiture.physique^.a, 1.0, 1);
		infoPartie.joueurs.t[i].voiture.ui^.etat.x := Round(C_UI_FENETRE_WIDTH/2-infoPartie.joueurs.t[i].voiture.ui^.surface^.w/2);
		infoPartie.joueurs.t[i].voiture.ui^.etat.y := Round(C_UI_FENETRE_HEIGHT/2-infoPartie.joueurs.t[i].voiture.ui^.surface^.h/2);
		fenetre.enfants.t[0]^.etat.x := Round(-infoPartie.joueurs.t[i].voiture.physique^.x);
		fenetre.enfants.t[0]^.etat.y := Round(-infoPartie.joueurs.t[i].voiture.physique^.y);
	end;
end;

procedure course_afficher(var infoPartie: T_GAMEPLAY; var physique: T_PHYSIQUE_TABLEAU; var fenetre: T_UI_ELEMENT);
begin
	afficher_camera(infoPartie, fenetre);
	afficher_hud(fenetre);
end;

procedure course_gameplay(var infoPartie: T_GAMEPLAY);
begin
infoPartie.joueurs.t[0].voiture.ui^.enfants.t[0]^.valeur:=IntToStr(Round(infoPartie.joueurs.t[0].voiture.physique^.a));
end;

procedure frame_physique(var physique: T_PHYSIQUE_TABLEAU; var infoPartie: T_GAMEPLAY);
var i : Integer;
begin
	for i:=0 to physique.taille-1 do
		begin
			physique.t[i]^.dr:=physique.t[i]^.dr - infoPartie.temps.dt*C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR*physique.t[i]^.dr;
			physique.t[i]^.x:=physique.t[i]^.x + infoPartie.temps.dt*sin(3.141592/180*physique.t[i]^.a)*physique.t[i]^.dr;
			physique.t[i]^.y:=physique.t[i]^.y + infoPartie.temps.dt*cos(3.141592/180*physique.t[i]^.a)*physique.t[i]^.dr;
			//writeln('Physique:',i,'/',physique.t[i]^.x,'+',physique.t[i]^.y);
		end;
end;

procedure course_user(var infoPartie: T_GAMEPLAY;var actif: boolean);
var event_sdl: TSDL_Event;
	event_clavier: PUint8;
begin
	SDL_PollEvent(@event_sdl);
	if event_sdl.type_=SDL_QUITEV then actif:=False;
	
	event_clavier := SDL_GetKeyState(NIL);
	if event_clavier[SDLK_SPACE] = SDL_PRESSED then
		infoPartie.joueurs.t[0].voiture.physique^.dr := infoPartie.joueurs.t[0].voiture.physique^.dr - infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ACCELERATION_AVANT*25;
		
	if event_clavier[SDLK_LCTRL] = SDL_PRESSED then
		infoPartie.joueurs.t[0].voiture.physique^.dr := infoPartie.joueurs.t[0].voiture.physique^.dr + infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ACCELERATION_ARRIERE*25;
		
	if event_clavier[SDLK_LEFT] = SDL_PRESSED then
		infoPartie.joueurs.t[0].voiture.physique^.a := infoPartie.joueurs.t[0].voiture.physique^.a + infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ANGLE;
		
	if event_clavier[SDLK_RIGHT] = SDL_PRESSED then
		infoPartie.joueurs.t[0].voiture.physique^.a := infoPartie.joueurs.t[0].voiture.physique^.a - infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ANGLE;
	//writeln('DR:',infoPartie.joueurs.t[0].voiture.physique^.dr);
end;

procedure course_arrivee(var infoPartie; var fenetre: T_UI_ELEMENT);
begin
end;

procedure course_depart(var fenetre: T_UI_ELEMENT);
begin
end;

procedure partie_course(var infoPartie: T_GAMEPLAY; var physique: T_PHYSIQUE_TABLEAU; fenetre: T_UI_ELEMENT);{Main Loop}
var actif: boolean;
	timer: array[0..7] of LongInt; {départ, boucle, delay,user,physique,gameplay,courseAfficher,frameAfficher}
	etat: SDL_Rect;
begin
	course_depart(fenetre);
	actif:=true;
	while actif do
	begin
		infoPartie.temps.dt:=(SDL_GetTicks()-infoPartie.temps.last)/1000;
		//writeln('DT: ',infoPartie.temps.dt);
		infoPartie.temps.last := SDL_GetTicks();
		
		timer[0]:=SDL_GetTicks();
		
		course_user(infoPartie, actif);
		timer[3]:=SDL_GetTicks();
		
		frame_physique(physique, infoPartie);
		timer[4]:=SDL_GetTicks();
		
		
		course_gameplay(infoPartie);
		timer[5]:=SDL_GetTicks();
		
		
		course_afficher(infoPartie, physique, fenetre);
		timer[6]:=SDL_GetTicks();
		etat.x:=0;
		etat.y:=0;
		frame_afficher(fenetre, fenetre.surface, etat);
		timer[7]:=SDL_GetTicks();
		
		SDL_Flip(fenetre.surface);
		
		timer[1] := SDL_GetTicks() - timer[0];
		timer[2] := Round(1000/C_REFRESHRATE)-timer[1];
		if timer[2] < 0 then timer[2]:=0;
		SDL_Delay(timer[2]);
		writeln('Took ',timer[1], 'ms to render. FPS=', 1000 div (SDL_GetTicks() - timer[0]),'///',timer[3]-timer[0],'/',timer[4]-timer[3],'/',timer[5]-timer[4],'/',timer[6]-timer[5],'/',timer[7]-timer[6],'//', timer[2]);
	end;
	
	course_arrivee(infoPartie, fenetre);
end;

procedure ajouter_physique(var physique: T_PHYSIQUE_TABLEAU);
var old: ^P_PHYSIQUE_ELEMENT;
	i: Integer;
begin
	old:=physique.t;
	physique.t := GetMem((physique.taille+1)*SizeOf(P_PHYSIQUE_ELEMENT));
	
	for i:=0 to physique.taille-1 do
		physique.t[i]:=old[i];
	physique.t[physique.taille] := GetMem(SizeOf(T_PHYSIQUE_ELEMENT));
	
	physique.t[physique.taille]^.x := 0;
	physique.t[physique.taille]^.y := 0;
	physique.t[physique.taille]^.dx := 0;
	physique.t[physique.taille]^.dy := 0;
	physique.t[physique.taille]^.a := 0;
	physique.t[physique.taille]^.da := 0;
	physique.t[physique.taille]^.r := 0;
	physique.t[physique.taille]^.dr :=0;
	
	Freemem(old, physique.taille*SizeOf(P_PHYSIQUE_ELEMENT));
	physique.taille:=physique.taille+1;
end;

procedure ajouter_enfant(var enfants: T_UI_TABLEAU);
var old: ^P_UI_ELEMENT;
	i: Integer;
begin
	
	old:=enfants.t;
	enfants.t := GetMem((enfants.taille+1)*SizeOf(P_UI_ELEMENT));
	
	for i:=0 to enfants.taille-1 do
		enfants.t[i]:=old[i];
	
	enfants.t[enfants.taille] := GetMem(SizeOf(T_UI_ELEMENT));
	enfants.t[enfants.taille]^.etat.x := 0;
	enfants.t[enfants.taille]^.etat.y := 0;
	enfants.t[enfants.taille]^.etat.w := 0;
	enfants.t[enfants.taille]^.etat.h := 0;
	enfants.t[enfants.taille]^.surface := NIL;
	enfants.t[enfants.taille]^.typeE := null;
	enfants.t[enfants.taille]^.valeur:='';
	enfants.t[enfants.taille]^.couleur.r:=0;
	enfants.t[enfants.taille]^.couleur.g:=0;
	enfants.t[enfants.taille]^.couleur.b:=0;
	enfants.t[enfants.taille]^.physique:=NIL;
	enfants.t[enfants.taille]^.enfants.taille:=0;
	enfants.t[enfants.taille]^.enfants.t:=NIL;
	
	Freemem(old, enfants.taille*SizeOf(T_UI_ELEMENT));
	enfants.taille:=enfants.taille+1;
end;

procedure partie_init(var infoPartie: T_GAMEPLAY; var physique: T_PHYSIQUE_TABLEAU;var fenetre: T_UI_ELEMENT);
begin
	infoPartie.temps.debut:=0;
	infoPartie.temps.fin:=0;
	fenetre.enfants.taille:=0;
	physique.taille:=0;
	
	//Fond ecran
	fenetre.typeE:=couleur;
	fenetre.couleur.r:=19;
	fenetre.couleur.g:=200;
	fenetre.couleur.b:=209;
	
	//Load Map
	ajouter_enfant(fenetre.enfants);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.valeur := 'background';
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := SDL_DisplayFormat(IMG_Load(@infoPartie.config^.circuit.chemin[1]));
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.w := fenetre.enfants.t[fenetre.enfants.taille-1]^.surface^.w;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.h := fenetre.enfants.t[fenetre.enfants.taille-1]^.surface^.h;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 0;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 0;
	
	//Joueurs
	if(infoPartie.config^.mode) then
		infoPartie.joueurs.taille := 1
	else
		infoPartie.joueurs.taille := 2;
		
	infoPartie.joueurs.t := GetMem(infoPartie.joueurs.taille*SizeOf(T_JOUEUR));
	//Boucle a faire sur joueurs.t
	ajouter_physique(physique);
	ajouter_enfant(fenetre.enfants);
	infoPartie.joueurs.t[0].voiture.physique := @physique.t[physique.taille-1]^;
	infoPartie.joueurs.t[0].voiture.ui := @fenetre.enfants.t[fenetre.enfants.taille-1]^;
	infoPartie.joueurs.t[0].voiture.ui^.typeE := image;
	infoPartie.joueurs.t[0].voiture.couleur := IMG_Load('voiture.png');
	infoPartie.joueurs.t[0].voiture.physique^.x := Round(infoPartie.joueurs.t[0].voiture.couleur^.w / 2);
	infoPartie.joueurs.t[0].voiture.physique^.y := Round(infoPartie.joueurs.t[0].voiture.couleur^.h / 2);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.physique:=@physique.t[physique.taille-1]^; {UTILISER PHYSIQUE DANS UI ? }
	//fin boucle
	//test
	infoPartie.joueurs.t[0].voiture.ui^.enfants.taille := 0;
	ajouter_enfant(infoPartie.joueurs.t[0].voiture.ui^.enfants);
	infoPartie.joueurs.t[0].voiture.ui^.enfants.t[infoPartie.joueurs.t[0].voiture.ui^.enfants.taille-1]^.typeE := texte;
	infoPartie.joueurs.t[0].voiture.ui^.enfants.t[infoPartie.joueurs.t[0].voiture.ui^.enfants.taille-1]^.valeur := 'Load..';
	infoPartie.joueurs.t[0].voiture.ui^.enfants.t[infoPartie.joueurs.t[0].voiture.ui^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
	infoPartie.joueurs.t[0].voiture.ui^.enfants.t[infoPartie.joueurs.t[0].voiture.ui^.enfants.taille-1]^.couleur.r :=0;
	infoPartie.joueurs.t[0].voiture.ui^.enfants.t[infoPartie.joueurs.t[0].voiture.ui^.enfants.taille-1]^.couleur.g :=0;
	infoPartie.joueurs.t[0].voiture.ui^.enfants.t[infoPartie.joueurs.t[0].voiture.ui^.enfants.taille-1]^.couleur.b :=0;
end;

procedure jeu_partie(var config: T_CONFIG; var fenetre: T_UI_ELEMENT);
var physique : T_PHYSIQUE_TABLEAU;
	infoPartie: T_GAMEPLAY;
begin
	infoPartie.config := @config;
	partie_init(infoPartie, physique, fenetre);
	partie_course(infoPartie, physique, fenetre);
end;

procedure jeu_menu(var fenetre: T_UI_ELEMENT);
var config : T_CONFIG;
begin
	config.circuit.nom:='Demo';
	config.circuit.chemin:='./circuits/first.png'#0;
	config.nbTour:= 3;
	config.mode:=True;
	jeu_partie(config, fenetre);
end;

procedure score(var fenetre: T_UI_ELEMENT);
begin
	
end;

procedure menu(var fenetre: T_UI_ELEMENT);
begin
	jeu_menu(fenetre);
end;

function lancement(): T_UI_ELEMENT; //Init SDL, fenetre(nom, surface, taille), TTF
begin
	writeln('|||', C_UI_FENETRE_NOM, '|||');
	writeln('#Lancement...');
	if SDL_Init(SDL_INIT_EVERYTHING) = 0 then
	begin
		TTF_Init();
		lancement.surface := SDL_SetVideoMode(C_UI_FENETRE_WIDTH, C_UI_FENETRE_HEIGHT, 32, SDL_RESIZABLE or SDL_HWSURFACE or SDL_DOUBLEBUF);
		if lancement.surface <> NIL then
		begin
			SDL_WM_SetCaption(C_UI_FENETRE_NOM, NIL);
			lancement.etat.x:=0;
			lancement.etat.y:=0;
		end	else 
		begin
			writeln('Erreur setVideoMode');
		end;
	end
	else
	begin
		writeln('Erreur Initialisation');
	end;
end;

var fenetre : T_UI_ELEMENT;
begin
	fenetre := lancement();
	menu(fenetre);
	
	TTF_Quit();
end.
