program demo;
uses sdl, sdl_ttf, sdl_image, sdl_gfx, INSACAR_TYPES;


const
	C_REFRESHRATE = 100; {FPS}
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR = 0.01;
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_EAU = 0.1;
	C_PHYSIQUE_VOITURE_VITESSE_AVANT = 0.1;
	C_PHYSIQUE_VOITURE_ANGLE = 1;
	C_PHYSIQUE_VOITURE_VITESSE_ARRIERE = 0.25;
	C_UI_FENETRE_NOM = 'InsaCar Alpha 2.0';
	

procedure frame_afficher(var element: T_UI_ELEMENT);
var i: Integer;
	police: PTTF_Font;
begin
	case element.typeE of
		couleur:
		begin
			SDL_FillRect(element.surface, NIL, SDL_MapRGB(element.surface^.format, element.couleur.r, element.couleur.g, element.couleur.b));
		end;
		texte:
		begin
			police := TTF_OpenFont('arial.ttf',55);
			element.surface := TTF_RenderText_Solid(police, 'jouer', element.couleur);
		end;
		image:
		begin
		end;
	end;
	for i:=0 to element.enfants.taille-1 do
	begin
		frame_afficher(element.enfants.t[i]);
		SDL_BlitSurface(element.enfants.t[i].surface, NIL, element.surface, @element.enfants.t[i].etat);
	end;
end;

procedure afficher_hud(var fenetre: T_UI_ELEMENT);
begin
end;

procedure afficher_camera(var infoPartie: T_GAMEPLAY; var fenetre: T_UI_ELEMENT);
var i : Integer;
begin
	{for i:=0 to fenetre.enfants.taille-1 do
	begin
		fenetre.enfants.t[i].surface := rotozoomSurface(infoPartie.joueurs.t[i].voiture.couleur, infoPartie.joueurs.t[i].voiture.physique^.a, 1.0, 1);
		fenetre.enfants.t[i].etat.x := Round(fenetre.enfants.t[i].physique^.x-fenetre.enfants.t[i].surface^.w/2);
		fenetre.enfants.t[i].etat.y := Round(fenetre.enfants.t[i].physique^.y-fenetre.enfants.t[i].surface^.h/2);
	end;}
	for i:=0 to fenetre.enfants.taille-1 do
	begin
		fenetre.enfants.t[i].surface := rotozoomSurface(infoPartie.joueurs.t[i].voiture.couleur, infoPartie.joueurs.t[i].voiture.physique^.a, 1.0, 1);
		fenetre.enfants.t[i].etat.x := Round(fenetre.enfants.t[i].physique^.x-fenetre.enfants.t[i].surface^.w/2);
		fenetre.enfants.t[i].etat.y := Round(fenetre.enfants.t[i].physique^.y-fenetre.enfants.t[i].surface^.h/2);
	end;
end;

procedure course_afficher(var infoPartie: T_GAMEPLAY; var physique: T_PHYSIQUE_TABLEAU; fenetre: T_UI_ELEMENT);
begin
	afficher_camera(infoPartie, fenetre);
	afficher_hud(fenetre);
end;

procedure course_gameplay(var infoPartie: T_GAMEPLAY);
begin
end;

procedure frame_physique(var physique: T_PHYSIQUE_TABLEAU);
var i : Integer;
begin
	for i:=0 to physique.taille do
		begin
			physique.t[i].dr:=physique.t[i].dr - C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR*physique.t[i].dr;
			physique.t[i].x:=Round(physique.t[i].x + sin(3.141592/180*physique.t[i].a)*physique.t[i].dr);
			physique.t[i].y:=Round(physique.t[i].y + cos(3.141592/180*physique.t[i].a)*physique.t[i].dr);
		end;
end;

procedure course_user(var physique: T_PHYSIQUE_TABLEAU;var actif: boolean);
var event_sdl: TSDL_Event;
	event_clavier: PUint8;
begin
	SDL_PollEvent(@event_sdl);
	if event_sdl.type_=SDL_QUITEV then actif:=False;
	
	event_clavier := SDL_GetKeyState(NIL);
	if event_clavier[SDLK_UP] = SDL_PRESSED then
		physique.t[0].dr := physique.t[0].dr - C_PHYSIQUE_VOITURE_VITESSE_AVANT;
		
	if event_clavier[SDLK_DOWN] = SDL_PRESSED then
		physique.t[0].dr := physique.t[0].dr + C_PHYSIQUE_VOITURE_VITESSE_AVANT;
		
	if event_clavier[SDLK_LEFT] = SDL_PRESSED then
		physique.t[0].a := physique.t[0].a + C_PHYSIQUE_VOITURE_ANGLE;
		
	if event_clavier[SDLK_RIGHT] = SDL_PRESSED then
		physique.t[0].a := physique.t[0].a - C_PHYSIQUE_VOITURE_ANGLE;

end;

procedure course_arrivee(var infoPartie; var fenetre: T_UI_ELEMENT);
begin
end;

procedure course_depart(var fenetre: T_UI_ELEMENT);
begin
end;

procedure partie_course(var infoPartie: T_GAMEPLAY; var physique: T_PHYSIQUE_TABLEAU; fenetre: T_UI_ELEMENT);{Main Loop}
var actif: boolean;
	timer: array[0..2] of Integer; {départ, boucle, delay}
begin
	course_depart(fenetre);
	actif:=true;
	while actif do
	begin
		timer[0]:=SDL_GetTicks();
		
		course_user(physique, actif);
		frame_physique(physique);
		course_gameplay(infoPartie);
		course_afficher(infoPartie, physique, fenetre);
		
		frame_afficher(fenetre);
		SDL_Flip(fenetre.surface);
		
		timer[1] := SDL_GetTicks() - timer[0];
		timer[2] := Round(1000/C_REFRESHRATE)-timer[1];
		if timer[2] < 0 then timer[2]:=0;
		SDL_Delay(timer[2]);
		writeln('Took ',timer[1], 'ms to render. FPS=', 1000 div (SDL_GetTicks() - timer[0]));
	end;
	
	course_arrivee(infoPartie, fenetre);
end;

{UNIT ? ?? }
procedure ajouter_physique(var physique: T_PHYSIQUE_TABLEAU);
var old: ^T_PHYSIQUE_ELEMENT;
	i: Integer;
begin
	old:=physique.t;
	physique.t := GetMem((physique.taille+1)*SizeOf(T_PHYSIQUE_ELEMENT));
	
	for i:=0 to physique.taille-1 do
		physique.t[i]:=old[i];
		
	physique.t[physique.taille].x := 0;
	physique.t[physique.taille].y := 0;
	physique.t[physique.taille].dx := 0;
	physique.t[physique.taille].dy := 0;
	physique.t[physique.taille].a := 0;
	physique.t[physique.taille].da := 0;
	physique.t[physique.taille].r := 0;
	physique.t[physique.taille].dr :=0;
	
	Freemem(old, physique.taille*SizeOf(T_PHYSIQUE_ELEMENT));
	physique.taille:=physique.taille+1;
end;

procedure ajouter_enfant(var enfants: T_UI_TABLEAU);
var old: ^T_UI_ELEMENT;
	i: Integer;
begin
	
	old:=enfants.t;
	enfants.t := GetMem((enfants.taille+1)*SizeOf(T_UI_ELEMENT));
	
	for i:=0 to enfants.taille-1 do
		enfants.t[i]:=old[i];
	
	enfants.t[enfants.taille].etat.x := 0;
	enfants.t[enfants.taille].etat.y := 0;
	enfants.t[enfants.taille].etat.w := 0;
	enfants.t[enfants.taille].etat.h := 0;
	enfants.t[enfants.taille].surface := NIL;
	enfants.t[enfants.taille].typeE := null;
	enfants.t[enfants.taille].valeur:='';
	enfants.t[enfants.taille].couleur.r:=0;
	enfants.t[enfants.taille].couleur.g:=0;
	enfants.t[enfants.taille].couleur.b:=0;
	enfants.t[enfants.taille].physique:=NIL;
	enfants.t[enfants.taille].enfants.taille:=0;
	enfants.t[enfants.taille].enfants.t:=NIL;
	
	Freemem(old, enfants.taille*SizeOf(T_UI_ELEMENT));
	enfants.taille:=enfants.taille+1;
end;

{UNIT ? ?? }

procedure partie_init(var infoPartie: T_GAMEPLAY; var physique: T_PHYSIQUE_TABLEAU;var fenetre: T_UI_ELEMENT);
begin
	{Gameplay}
	infoPartie.temps.debut:=0;
	infoPartie.temps.fin:=0;
	{Joueurs}
	if(infoPartie.config^.mode) then
		infoPartie.joueurs.taille := 1
	else
		infoPartie.joueurs.taille := 2;
	
	infoPartie.joueurs.t := GetMem(infoPartie.joueurs.taille*SizeOf(T_JOUEUR));
	
	physique.taille:=0;
	ajouter_physique(physique);
	
	fenetre.enfants.taille:=0;
	ajouter_enfant(fenetre.enfants);
		
	infoPartie.joueurs.t[0].voiture.physique := @physique.t[physique.taille-1];
	infoPartie.joueurs.t[0].voiture.ui := @fenetre.enfants.t[fenetre.enfants.taille-1];
	
	infoPartie.joueurs.t[0].voiture.ui^.typeE := image;
	infoPartie.joueurs.t[0].voiture.couleur := IMG_Load('voiture.png');
	
	infoPartie.joueurs.t[0].voiture.physique^.x := Round(infoPartie.joueurs.t[0].voiture.couleur^.w / 2);
	infoPartie.joueurs.t[0].voiture.physique^.y := Round(infoPartie.joueurs.t[0].voiture.couleur^.h / 2);
	
	fenetre.enfants.t[fenetre.enfants.taille-1].physique:=@physique.t[physique.taille-1]; {UTILISER PHYSIQUE DANS UI ? }
	
	fenetre.typeE:=couleur;
	fenetre.couleur.r:=19;
	fenetre.couleur.g:=200;
	fenetre.couleur.b:=209;	
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
	config.circuit.nom:='Monza';
	config.circuit.chemin:='pathToMonza';
	config.nbTour:= 3;
	config.mode:= True;
	jeu_partie(config, fenetre);
end;

procedure score(var fenetre: T_UI_ELEMENT);
begin
	
end;

procedure menu(var fenetre: T_UI_ELEMENT);
begin
	jeu_menu(fenetre);
end;

function lancement(): T_UI_ELEMENT;
begin
	writeln('|||', C_UI_FENETRE_NOM, '|||');
	writeln('Lancement...');
	if SDL_Init(SDL_INIT_EVERYTHING) = 0 then
	begin
		TTF_Init();
		lancement.surface := SDL_SetVideoMode(1600, 900, 32, SDL_HWSURFACE or SDL_DOUBLEBUF);
		if lancement.surface <> NIL then
			SDL_WM_SetCaption(C_UI_FENETRE_NOM, NIL)
		else
		begin
			writeln('Erreur setVideoMode');
		end;
	end
	else
	begin
		writeln('Erreur Initialisation');
	end;
	
	{FIN DU PROGRAMME}
	TTF_Quit();
end;

var fenetre : T_UI_ELEMENT;
begin
	fenetre := lancement();
	menu(fenetre);
end.
