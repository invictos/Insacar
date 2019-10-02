program demo;
uses sdl, INSACAR_TYPES;


const
	C_REFRESHRATE = 100; {FPS}
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR = 0.1;
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_EAU = 0.1;
	C_PHYSIQUE_VOITURE_VITESSE_AVANT = 0.5;
	C_PHYSIQUE_VOITURE_ANGLE = 0.03;
	C_PHYSIQUE_VOITURE_VITESSE_ARRIERE = 0.25;
	C_UI_FENETRE_NOM = 'InsaCar Alpha 2.0';


procedure frame_afficher(var element: T_UI_ELEMENT);
var i: Integer;
begin
		SDL_FillRect(element.surface, NIL, SDL_MapRGB(element.surface^.format, element.couleur[0], element.couleur[1], element.couleur[2]));
		for i:=0 to element.enfants.taille-1 do
		begin
			frame_afficher(element.enfants.t[i]);
			SDL_BlitSurface(element.enfants.t[i].surface, NIL, element.surface, @element.enfants.t[i].etat);
		end;
end;

procedure afficher_hud(var fenetre: T_UI_ELEMENT);
begin
end;

procedure afficher_camera(var fenetre: T_UI_ELEMENT);
begin
	fenetre.enfants.t[0].etat.x := fenetre.enfants.t[0].physique^.x;
	fenetre.enfants.t[0].etat.y := fenetre.enfants.t[0].physique^.y;
end;

procedure course_afficher(var physique: T_PHYSIQUE_TABLEAU; fenetre: T_UI_ELEMENT);
begin
	afficher_camera(fenetre);
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
			physique.t[i].x:=Round(physique.t[i].x + sin(physique.t[i].a)*physique.t[i].dr);
			physique.t[i].y:=Round(physique.t[i].y + cos(physique.t[i].a)*physique.t[i].dr);
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
		course_afficher(physique, fenetre);
		
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

procedure partie_init(infoPartie: T_GAMEPLAY; var physique: T_PHYSIQUE_TABLEAU;var fenetre: T_UI_ELEMENT);
var i : Byte;
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
	
	{Physique // CALCUL NB ELEMENT PHYSIQUE = JOUEURS + AUTRES}
	physique.taille := infoPartie.joueurs.taille;
	physique.t := GetMem(physique.taille*SizeOf(T_PHYSIQUE_ELEMENT));
	for i:=0 to physique.taille do
	begin
		physique.t[i].x := 0;
		physique.t[i].y := 0;
		physique.t[i].dx := 0;
		physique.t[i].dy := 0;
		physique.t[i].a := 0;
		physique.t[i].da := 0;
		physique.t[i].r := 0;
		physique.t[i].dr :=0;
	end;
	
	fenetre.typeE:=couleur;
	fenetre.couleur[0]:=19;
	fenetre.couleur[1]:=200;
	fenetre.couleur[2]:=209;
	fenetre.enfants.taille:=1;
	fenetre.enfants.t:=GetMem(fenetre.enfants.taille * SizeOf(T_UI_ELEMENT));
	for i:=0 to fenetre.enfants.taille do
	begin
		fenetre.enfants.t[i].physique:=@physique.t[i];
		fenetre.enfants.t[i].etat.x := 0;
		fenetre.enfants.t[i].etat.y := 0;
		fenetre.enfants.t[i].etat.w := 40;
		fenetre.enfants.t[i].etat.h := 60;
		fenetre.enfants.t[i].surface := SDL_CreateRGBSurface(SDL_HWSURFACE, fenetre.enfants.t[i].etat.w, fenetre.enfants.t[i].etat.h, 32, 0, 0, 0, 0);
		fenetre.enfants.t[i].typeE := couleur;
		fenetre.enfants.t[i].couleur[0]:=255;
		fenetre.enfants.t[i].couleur[1]:=0;
		fenetre.enfants.t[i].couleur[2]:=0;
		fenetre.enfants.t[i].valeur:='';
		fenetre.enfants.t[i].enfants.taille:=0;
	end;
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
		lancement.surface := SDL_SetVideoMode(1920, 1080, 32, SDL_HWSURFACE or SDL_DOUBLEBUF);
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
end;

var fenetre : T_UI_ELEMENT;
begin
	fenetre := lancement();
	menu(fenetre);
end.
