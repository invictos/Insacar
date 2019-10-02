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


procedure afficher_hud(var fenetre: T_UI_ELEMENT);
begin
end;
procedure afficher_camera(var fenetre: T_UI_ELEMENT);
begin
end;
procedure course_afficher(var physique: T_PHYSIQUE_TABLEAU; fenetre: T_UI_ELEMENT);
begin
		SDL_FillRect(fenetre.surface, NIL, SDL_MapRGB(fenetre.surface^.format, 19, 200, 209));
		SDL_FillRect(fenetre.enfants.t[0].surface, NIL, SDL_MapRGB(fenetre.enfants.t[0].surface^.format, 255, 0, 0));
		
		fenetre.enfants.t[0].etat.x := fenetre.enfants.t[0].physique^.x;
		fenetre.enfants.t[0].etat.y := fenetre.enfants.t[0].physique^.y;
		SDL_BlitSurface(fenetre.enfants.t[0].surface, NIL, fenetre.surface, @fenetre.enfants.t[0].etat);

end;
procedure course_physique(var physique: T_PHYSIQUE_TABLEAU);
begin
		
		physique.t[0].dr:=physique.t[0].dr - C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR*physique.t[0].dr;

		physique.t[0].x:=Round(physique.t[0].x + sin(physique.t[0].a)*physique.t[0].dr);
		physique.t[0].y:=Round(physique.t[0].y + cos(physique.t[0].a)*physique.t[0].dr);
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
procedure course_arrivee(var fenetre: T_UI_ELEMENT);
begin
end;

procedure course_depart(var fenetre: T_UI_ELEMENT);
begin
end;

procedure partie_course(var physique: T_PHYSIQUE_TABLEAU; fenetre: T_UI_ELEMENT);{Main Loop}
var actif: boolean;
	temps_depart,temps_boucle, temps_total, temps_delay: Integer;
begin
	course_depart(fenetre);
	actif:=true;
	while actif do
	begin
		temps_depart:=SDL_GetTicks();
		
		course_user(physique, actif);

		course_physique(physique);
		
		course_afficher(physique, fenetre);
		
		SDL_Flip(fenetre.surface);
		
		temps_boucle := SDL_GetTicks() - temps_depart;
		
		temps_delay := Round(1000/C_REFRESHRATE)-temps_boucle;
		if temps_delay < 0 then temps_delay:=0;
		SDL_Delay(temps_delay);
		
		
		temps_total:=SDL_GetTicks() - temps_depart;
		writeln('Took ',temps_boucle, 'ms to render. FPS=', 1000 div temps_total);
	end;
	
	course_arrivee(fenetre);
end;

procedure partie_init(c: T_GAMEPLAY_CONFIG; var physique: T_PHYSIQUE_TABLEAU;var fenetre: T_UI_ELEMENT);
begin
	physique.t := GetMem(10*SizeOf(T_PHYSIQUE_ELEMENT));
	
	physique.taille:=physique.taille+1;
	physique.t[0].x := 0;
	physique.t[0].y := 0;
	physique.t[0].dx := 0;
	physique.t[0].dy := 0;
	physique.t[0].a := 0;
	physique.t[0].dr :=0;
	
	fenetre.enfants.t:=GetMem(10 * SizeOf(T_UI_ELEMENT));
	fenetre.enfants.taille:=fenetre.enfants.taille+1;
	fenetre.enfants.t[0].physique:=@physique.t[0];
	fenetre.enfants.t[0].etat.x := 0;
	fenetre.enfants.t[0].etat.y := 0;
	fenetre.enfants.t[0].etat.w := 40;
	fenetre.enfants.t[0].etat.h := 60;
	fenetre.enfants.t[0].surface := SDL_CreateRGBSurface(SDL_HWSURFACE, fenetre.enfants.t[0].etat.w, fenetre.enfants.t[0].etat.h, 32, 0, 0, 0, 0);
end;

procedure jeu_partie(c: T_GAMEPLAY_CONFIG; var fenetre: T_UI_ELEMENT);
var physique : T_PHYSIQUE_TABLEAU;
begin
	physique.taille:=0;
	partie_init(c, physique, fenetre);
	partie_course(physique, fenetre);
end;

procedure jeu_menu(var c: T_GAMEPLAY_CONFIG; fenetre: T_UI_ELEMENT);
begin
	c.circuit:='Monza';
	c.chemin:='pathToMonza';
end;

procedure score(var fenetre: T_UI_ELEMENT);
begin
	
end;

procedure jeu(var fenetre: T_UI_ELEMENT);
var	jeu_config : T_GAMEPLAY_CONFIG;
begin
	jeu_config.circuit:='';
	jeu_config.chemin:='';
	jeu_menu(jeu_config, fenetre);
	jeu_partie(jeu_config, fenetre);
end;

procedure menu(var fenetre: T_UI_ELEMENT);
begin
	jeu(fenetre);
end;

function lancement(): T_UI_ELEMENT;
begin
	writeln('|||', C_UI_FENETRE_NOM, '|||');
	writeln('Lancement...');
	if SDL_Init(SDL_INIT_EVERYTHING) = 0 then
	begin
		lancement.surface := SDL_SetVideoMode(1280, 720, 32, SDL_HWSURFACE or SDL_DOUBLEBUF);
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
