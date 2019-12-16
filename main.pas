{*---------------------------------------------------------------------------------------------
 *  Copyright (c) InsaCar. <antoine.camusat@insa-rouen.fr> <anas.katim@insa-rouen.fr> <aleksi.mouvier@insa-rouen.fr>
 *  Licensed under GNU General Public License. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*}

program demo;


uses sdl, sdl_ttf, sdl_image, sdl_gfx, INSACAR_TYPES, sysutils, strutils, tools, crt;

const
	C_UI_FENETRE_NOM = 'InsaCar Alpha 2.0';
	C_REFRESHRATE = 90; //Images par secondes
	C_UI_FENETRE_WIDTH = 1600;//Taille fenêtre
	C_UI_FENETRE_HEIGHT = 900;
	C_UI_ZOOM_W = 70 ; //% Max zoom 2 joueurs
	C_UI_ZOOM_H = 70 ;
	
	//Physique
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR = 0.2; // kg.s^(-1)
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_EAU = 0.1; // kg.s^(-1)
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_TERRE = 5; // kg.s^(-1)
	
	C_PHYSIQUE_VOITURE_ACCELERATION_AVANT = 5.6; // m.s^(-2)
	C_PHYSIQUE_VOITURE_ACCELERATION_ARRIERE = 3;// m.s^(-2)
	C_PHYSIQUE_VOITURE_ACCELERATION_FREIN = 12;// m.s^(-2)
	C_PHYSIQUE_VOITURE_ANGLE = 90; // Deg.s^(-1)

procedure frame_afficher_low(var element: T_UI_ELEMENT; var frame: PSDL_Surface; etat: T_RENDER_ETAT);
var i : Integer;
		s : ansiString;
begin
	case element.typeE of
		couleur:
		begin
			//Rendu couleur
			SDL_FillRect(element.surface, NIL, SDL_MapRGBA(element.surface^.format, element.couleur.r, element.couleur.g, element.couleur.b, 255));
		end;
		
		texte:
		begin
			//Suppression ancien texte
			SDL_FreeSurface(element.surface);
			//Convertion ansiString (null-terminated)
			s:= element.valeur;
			//Rendu Texte
			element.surface := TTF_RenderText_Blended(element.police, Pchar(s), element.couleur);
		end;
	end;

	//Application des styles
	if element.style.enabled then
	begin
		//Transparence
		if element.style.a<>255 then
			SDL_SetAlpha(element.surface, SDL_SRCALPHA, element.style.a);
	end;

	//Calcul position
	etat.rect.x:=etat.rect.x+element.etat.x;
	etat.rect.y:=etat.rect.y+element.etat.y;

	//Rendu SDL
	SDL_BlitSurface(element.surface, NIL, frame, @etat.rect);
	
	//PostRendu (curseur)
	if (element.typeE = texte) AND (element.enfants.taille <> 0) AND (element.surface <> NIL) then
		etat.rect.x:=etat.rect.x + element.surface^.w;
	
	//Rendu enfants
	for i:=0 to element.enfants.taille-1 do
		//Test affichage
		if element.enfants.t[i]^.style.display then
			frame_afficher_low(element.enfants.t[i]^, frame, etat);
end;

procedure frame_afficher(var element: T_UI_ELEMENT);
var etat: T_RENDER_ETAT;
begin
	//Initialisation
	etat.rect.x:=0;
	etat.rect.y:=0;
	etat.a:=255;
	
	//Lancement fonction récursive
	frame_afficher_low(element,element.surface,etat);
end;

procedure afficher_hud(var infoPartie: T_GAMEPLAY; var fenetre: T_UI_ELEMENT);
var i: ShortInt;
begin
	//Temps géneral
	infoPartie.hud.temps^.valeur:= seconde_to_temps(infoPartie.temps.last-infoPartie.temps.debut);
	
	//Premier
	if infoPartie.joueurs.taille = 2 then
	begin
		if (infoPartie.joueurs.t[infoPartie.premier].nbTour < infoPartie.joueurs.t[(infoPartie.premier+1) MOD 2].nbTour)
		OR ((infoPartie.joueurs.t[infoPartie.premier].nbTour = infoPartie.joueurs.t[(infoPartie.premier+1) MOD 2].nbTour) AND (infoPartie.joueurs.t[infoPartie.premier].temps.actuel < infoPartie.joueurs.t[(infoPartie.premier+1) MOD 2].temps.actuel)) then
		begin
			infoPartie.premier := (infoPartie.premier+1) MOD 2;
			infoPartie.hud.nom_premier^.valeur := concat('Premier : ', infoPartie.joueurs.t[infoPartie.premier].nom);
		end;
	end;
	
	//Tour
	infoPartie.hud.actuelTour^.valeur := intToStr(infoPartie.joueurs.t[infoPartie.premier].nbTour);
	
	//Joueurs J1/J2
	for i:=0 to infoPartie.joueurs.taille-1 do
	begin
		//Affichage vitesse
		infoPartie.joueurs.t[i].hud.vitesse^.valeur:=Concat(IntToStr(Round(-infoPartie.joueurs.t[i].voiture.physique^.dr/2.5)),' km/h');
		
		//Affichage temps secteurs
		if infoPartie.joueurs.t[i].temps.actuel <> 0 then
			infoPartie.joueurs.t[i].hud.secteur[infoPartie.joueurs.t[i].temps.actuel-1]^.valeur := concat('S',intToStr(infoPartie.joueurs.t[i].temps.actuel), ' : ',seconde_to_temps(infoPartie.temps.last-infoPartie.joueurs.t[i].temps.secteur[infoPartie.joueurs.t[i].temps.actuel-1]));
	end;
end;

procedure afficher_camera(var infoPartie: T_GAMEPLAY; var fenetre: T_UI_ELEMENT);
var i : Integer;
	centre, zoom, distance: array[0..1] of Real;
	zoomFinal: Real;
begin
	//Initialisation
	zoomFinal := 1;
	
	//Calcul centre par rapport au J1
	centre[0] := infoPartie.zoom*infoPartie.joueurs.t[0].voiture.physique^.x/infoPartie.joueurs.taille;
	centre[1] := infoPartie.zoom*infoPartie.joueurs.t[0].voiture.physique^.y/infoPartie.joueurs.taille;

	//Calcul zoom si J2
	if infoPartie.joueurs.taille=2 then
	begin
		//Distance entre voitures
		distance[0] := sqrt((infoPartie.joueurs.t[0].voiture.physique^.x-infoPartie.joueurs.t[1].voiture.physique^.x)*(infoPartie.joueurs.t[0].voiture.physique^.x-infoPartie.joueurs.t[1].voiture.physique^.x));
		distance[1] := sqrt((infoPartie.joueurs.t[0].voiture.physique^.y-infoPartie.joueurs.t[1].voiture.physique^.y)*(infoPartie.joueurs.t[0].voiture.physique^.y-infoPartie.joueurs.t[1].voiture.physique^.y));
		
		//Calcul zoom nécessaire
		if distance[0] <> 0 then
			 zoom[0] := (C_UI_ZOOM_W/100*C_UI_FENETRE_WIDTH)/distance[0];
			
		if distance[1] <> 0 then
			 zoom[1] := (C_UI_ZOOM_H/100*C_UI_FENETRE_HEIGHT)/distance[1];
		
		//Zoom final et arrondi
		zoomFinal := Round(ZoomMin(zoom[0], zoom[1])*5000)/5000;

		//Calcul centre par rapport au J2
		centre[0] := centre[0] + infoPartie.zoom*infoPartie.joueurs.t[1].voiture.physique^.x/2;
		centre[1] := centre[1] + infoPartie.zoom*infoPartie.joueurs.t[1].voiture.physique^.y/2;
	end;
	
	//Test changement zoom
	if zoomFinal <> infoPartie.zoom then
	begin
		//Nouveau zoom
		infoPartie.zoom:=zoomFinal;
		
		//Libération surface ancienne map
		SDL_FreeSurface(infoPartie.map.current^);
		
		//Nouvelle map
		infoPartie.map.current^ := zoomSurface(infoPartie.map.base, infoPartie.zoom, infoPartie.zoom, 0);
	end;

	//Placement carte
	fenetre.enfants.t[0]^.etat.x := -Round(centre[0]-C_UI_FENETRE_WIDTH/2);
	fenetre.enfants.t[0]^.etat.y := -Round(centre[1]-C_UI_FENETRE_HEIGHT/2);
	
	//Placement Joueurs
	for i:=0 to infoPartie.joueurs.taille-1 do
	begin
		//Libération surface
		SDL_freeSurface(infoPartie.joueurs.t[i].voiture.ui^.surface);
		
		//Nouvelle surface
		infoPartie.joueurs.t[i].voiture.ui^.surface := rotozoomSurface(infoPartie.joueurs.t[i].voiture.surface, infoPartie.joueurs.t[i].voiture.physique^.a, infoPartie.zoom, 1);
		
		//Placement joueur
		infoPartie.joueurs.t[i].voiture.ui^.etat.x := Round(infoPartie.zoom*infoPartie.joueurs.t[i].voiture.physique^.x+fenetre.enfants.t[0]^.etat.x-infoPartie.joueurs.t[i].voiture.ui^.surface^.w/2);
		infoPartie.joueurs.t[i].voiture.ui^.etat.y := Round(infoPartie.zoom*infoPartie.joueurs.t[i].voiture.physique^.y+fenetre.enfants.t[0]^.etat.y-infoPartie.joueurs.t[i].voiture.ui^.surface^.h/2);
	end;
end;

procedure course_afficher(var infoPartie: T_GAMEPLAY; var physique: T_PHYSIQUE_TABLEAU; var fenetre: T_UI_ELEMENT);
begin
	//Affichage caméra (circuit+voitures)
	afficher_camera(infoPartie, fenetre);
	
	//Affichage HUD (Informations)
	afficher_hud(infoPartie, fenetre);
end;

procedure course_gameplay(var infoPartie: T_GAMEPLAY; var circuit: PSDL_Surface);
var c: array of TSDL_Color;
	p: SDL_Rect;
	hit: T_HITBOX_COLOR;
	i,j: ShortInt;
begin
	//Initialisation couleurs
	setLength(c,3);
	
	c[0].r:=247; //Orange
	c[0].g:=147;
	c[0].b:=30;
	
	c[1].r:=252; //Jaune CP1
	c[1].g:=238;
	c[1].b:=31;
	
	c[2].r:=252; //Jaune CP2
	c[2].g:=238;
	c[2].b:=32;
	
	//Test J1/J2
	for i:=0 to infoPartie.joueurs.taille-1 do
	begin
		//Etat de la voiture
		p.x := Round(infoPartie.joueurs.t[i].voiture.physique^.x);
		p.y := Round(infoPartie.joueurs.t[i].voiture.physique^.y);
		p.w := infoPartie.joueurs.t[i].voiture.surface^.w;
		p.h := infoPartie.joueurs.t[i].voiture.surface^.h;
		
		//Calcul collisions
		hit := hitBox(infoPartie.map.base, p, infoPartie.joueurs.t[i].voiture.physique^.a, c);
		
		//Utilisation collisions
		for j:=0 to hit.taille-1 do
			//Hit ligne secteur actuel + 1
			if (hit.data[j].n=1) AND isSameColor(c[infoPartie.joueurs.t[i].temps.actuel MOD 3],hit.data[j].c) then
			begin
				if infoPartie.joueurs.t[i].temps.actuel = 3 then
				begin
					infoPartie.joueurs.t[i].nbTour := infoPartie.joueurs.t[i].nbTour + 1;
					infoPartie.joueurs.t[i].temps.tours[infoPartie.joueurs.t[i].nbTour-1] := infoPartie.temps.last-infoPartie.joueurs.t[i].temps.secteur[0];
				end;
				//Temps passage ligne
				infoPartie.joueurs.t[i].temps.secteur[infoPartie.joueurs.t[i].temps.actuel MOD 3] := infoPartie.temps.last;
				
				//Incrémentation secteur courant
				infoPartie.joueurs.t[i].temps.actuel := (infoPartie.joueurs.t[i].temps.actuel MOD 3) + 1;
			end;
	end;
	
	if infoPartie.config^.nbTour = infoPartie.joueurs.t[0].nbTour-1 then
		infoPartie.actif := False;
end;

procedure frame_physique(var physique: T_PHYSIQUE_TABLEAU; var infoPartie: T_GAMEPLAY);
var i : ShortInt;
	c: array of TSDL_Color;
	hb : T_HITBOX_COLOR;
	p : SDL_Rect;
begin
	//Initialisation couleurs
	setLength(c,1);
	c[0].r:=57;
	c[0].g:=181;
	c[0].b:=74;
	
	//Joueurs J1/J2
	for i:=0 to physique.taille-1 do
	begin
		//Coordonnées joueur
		p.x := Round(infoPartie.joueurs.t[i].voiture.physique^.x);
		p.y := Round(infoPartie.joueurs.t[i].voiture.physique^.y);
		p.w := infoPartie.joueurs.t[i].voiture.surface^.w-10;
		p.h := infoPartie.joueurs.t[i].voiture.surface^.h-10;
		
		//Test collisions
		hb := hitBox(infoPartie.map.base, p, infoPartie.joueurs.t[i].voiture.physique^.a, c);
		
		//Calcul frottements

		if hb.taille<>0 then
			physique.t[i]^.dr:=physique.t[i]^.dr - infoPartie.temps.dt*C_PHYSIQUE_FROTTEMENT_COEFFICIENT_TERRE*physique.t[i]^.dr
		else

			physique.t[i]^.dr:=physique.t[i]^.dr - infoPartie.temps.dt*C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR*physique.t[i]^.dr;
		
		//Calcul positions
		physique.t[i]^.x:=physique.t[i]^.x + infoPartie.temps.dt*sin(3.141592/180*physique.t[i]^.a)*physique.t[i]^.dr;
		physique.t[i]^.y:=physique.t[i]^.y + infoPartie.temps.dt*cos(3.141592/180*physique.t[i]^.a)*physique.t[i]^.dr;
	end;
end;

procedure course_user(var infoPartie: T_GAMEPLAY);
var event_sdl: TSDL_Event;
	event_clavier: PUint8;
begin
	//Vérification fermeture fenêtre
	SDL_PollEvent(@event_sdl);
	if event_sdl.type_=SDL_QUITEV then
		infoPartie.actif:=False;
	
	//Etat clavier
	event_clavier := SDL_GetKeyState(NIL);
	
	//J1 Avant ou frein (si Marche arriere)
	{$IFDEF WINDOWS} //Bug azerty->querty windows
	if event_clavier[SDLK_Q] = SDL_PRESSED then
	{$ENDIF}
	{$IFDEF LINUX}
	if event_clavier[SDLK_A] = SDL_PRESSED then	
	{$ENDIF}
		if infoPartie.joueurs.t[0].voiture.physique^.dr < 0 then 
			infoPartie.joueurs.t[0].voiture.physique^.dr := infoPartie.joueurs.t[0].voiture.physique^.dr - infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ACCELERATION_AVANT*25
		else
			infoPartie.joueurs.t[0].voiture.physique^.dr := infoPartie.joueurs.t[0].voiture.physique^.dr - infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ACCELERATION_FREIN*25;
	
	//J1 Frein ou marche arrière
	if event_clavier[SDLK_TAB] = SDL_PRESSED then
		if infoPartie.joueurs.t[0].voiture.physique^.dr < 0 then 
			infoPartie.joueurs.t[0].voiture.physique^.dr := infoPartie.joueurs.t[0].voiture.physique^.dr + infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ACCELERATION_FREIN*25
		else
			infoPartie.joueurs.t[0].voiture.physique^.dr := infoPartie.joueurs.t[0].voiture.physique^.dr + infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ACCELERATION_ARRIERE*25;
	
	//J1 Gauche
	if event_clavier[SDLK_R] = SDL_PRESSED then
		infoPartie.joueurs.t[0].voiture.physique^.a := infoPartie.joueurs.t[0].voiture.physique^.a + infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ANGLE;
	
	//J1 Droite
	if event_clavier[SDLK_Y] = SDL_PRESSED then
		infoPartie.joueurs.t[0].voiture.physique^.a := infoPartie.joueurs.t[0].voiture.physique^.a - infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ANGLE;
	
	//Si joueurs 2
	if infoPartie.joueurs.taille=2 then
	begin
		//J2 Avant ou frein (si Marche arriere)
		if event_clavier[SDLK_RCTRL] = SDL_PRESSED then
			if infoPartie.joueurs.t[1].voiture.physique^.dr < 0 then
				infoPartie.joueurs.t[1].voiture.physique^.dr := infoPartie.joueurs.t[1].voiture.physique^.dr - infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ACCELERATION_AVANT*25
			else
				infoPartie.joueurs.t[1].voiture.physique^.dr := infoPartie.joueurs.t[1].voiture.physique^.dr - infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ACCELERATION_FREIN*25;
		
		//J2 Frein ou marche arrière
		if event_clavier[SDLK_MENU] = SDL_PRESSED then
			if infoPartie.joueurs.t[1].voiture.physique^.dr < 0 then 
				infoPartie.joueurs.t[1].voiture.physique^.dr := infoPartie.joueurs.t[1].voiture.physique^.dr + infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ACCELERATION_FREIN*25
			else
				infoPartie.joueurs.t[1].voiture.physique^.dr := infoPartie.joueurs.t[1].voiture.physique^.dr + infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ACCELERATION_ARRIERE*25;
		
		//J2 Gauche
		if event_clavier[SDLK_KP1] = SDL_PRESSED then
			infoPartie.joueurs.t[1].voiture.physique^.a := infoPartie.joueurs.t[1].voiture.physique^.a + infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ANGLE;
		
		//J2 Droite
		if event_clavier[SDLK_KP3] = SDL_PRESSED then
			infoPartie.joueurs.t[1].voiture.physique^.a := infoPartie.joueurs.t[1].voiture.physique^.a - infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ANGLE;
	end;
	
	if event_clavier[SDLK_H] = SDL_PRESSED then
		infoPartie.actif := False;
		
end;

procedure course_arrivee(var infoPartie: T_GAMEPLAY; var fenetre: T_UI_ELEMENT);
var actif : Boolean;
	event_sdl: TSDL_Event;
	panel : P_UI_ELEMENT;
	scores : T_SCORES;
	i: ShortInt;
begin
	//Cacher le HUD
	infoPartie.hud.global^.style.display := False;
	
	//Calcul meilleur tour
	setLength(scores, infoPartie.joueurs.taille);
	for i:=0 to length(scores)-1 do
	begin
			scores[i].nom := infoPartie.joueurs.t[i].nom;
			scores[i].temps := min(infoPartie.joueurs.t[i].temps.tours);
	end;
	
	//Panneau fin
	ajouter_enfant(fenetre);
	panel := fenetre.enfants.t[fenetre.enfants.taille-1];
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;				
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x:=500;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y:=150;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := IMG_Load('grey_panel.png');
		
		//Texte 'fin de course'
		ajouter_enfant(panel^);
		panel^.enfants.t[panel^.enfants.taille-1]^.typeE := texte;
		panel^.enfants.t[panel^.enfants.taille-1]^.valeur := 'FIN DE LA COURSE';
		panel^.enfants.t[panel^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
		panel^.enfants.t[panel^.enfants.taille-1]^.etat.x := 190;
		panel^.enfants.t[panel^.enfants.taille-1]^.etat.y := 35;
		
		//Texte nom circuit
		ajouter_enfant(panel^);
		panel^.enfants.t[panel^.enfants.taille-1]^.typeE := texte;
		panel^.enfants.t[panel^.enfants.taille-1]^.valeur := Concat('Circuit : ',infoPartie.config^.circuit.nom);
		panel^.enfants.t[panel^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
		panel^.enfants.t[panel^.enfants.taille-1]^.etat.x := 40;
		panel^.enfants.t[panel^.enfants.taille-1]^.etat.y := 100;
		
		//Record circuit
		ajouter_enfant(panel^);
		panel^.enfants.t[panel^.enfants.taille-1]^.typeE := texte;
		panel^.enfants.t[panel^.enfants.taille-1]^.valeur := Concat('Record circuit : ');//////////////////////////////////////////////////////////////////////////////
		panel^.enfants.t[panel^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
		panel^.enfants.t[panel^.enfants.taille-1]^.etat.x := 40;
		panel^.enfants.t[panel^.enfants.taille-1]^.etat.y := 150;	
		
		//Texte 'resume course'
		ajouter_enfant(panel^);
		panel^.enfants.t[panel^.enfants.taille-1]^.typeE := texte;
		panel^.enfants.t[panel^.enfants.taille-1]^.valeur := 'RESUME DE LA COURSE';
		panel^.enfants.t[panel^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
		panel^.enfants.t[panel^.enfants.taille-1]^.etat.x := 150;
		panel^.enfants.t[panel^.enfants.taille-1]^.etat.y := 250;	
		
		
		//Nom J1
		for i:=0 to infoPartie.joueurs.taille-1 do
		begin
			ajouter_enfant(panel^);
			panel^.enfants.t[panel^.enfants.taille-1]^.typeE := texte;
			panel^.enfants.t[panel^.enfants.taille-1]^.valeur := infoPartie.joueurs.t[i].nom;
			panel^.enfants.t[panel^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
			panel^.enfants.t[panel^.enfants.taille-1]^.etat.x := 170+230*i;
			panel^.enfants.t[panel^.enfants.taille-1]^.etat.y := 310;
			
			ajouter_enfant(panel^);
			panel^.enfants.t[panel^.enfants.taille-1]^.typeE := texte;
			panel^.enfants.t[panel^.enfants.taille-1]^.valeur := concat('T1 : ', seconde_to_temps(infoPartie.joueurs.t[i].temps.tours[1]));
			panel^.enfants.t[panel^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
			panel^.enfants.t[panel^.enfants.taille-1]^.etat.x := 50+300*i;
			panel^.enfants.t[panel^.enfants.taille-1]^.etat.y := 360;
			
			ajouter_enfant(panel^);
			panel^.enfants.t[panel^.enfants.taille-1]^.typeE := texte;
			panel^.enfants.t[panel^.enfants.taille-1]^.valeur := concat('T2 : ', seconde_to_temps(infoPartie.joueurs.t[i].temps.tours[2]));
			panel^.enfants.t[panel^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
			panel^.enfants.t[panel^.enfants.taille-1]^.etat.x := 50+300*i;
			panel^.enfants.t[panel^.enfants.taille-1]^.etat.y := 410;
			
			ajouter_enfant(panel^);
			panel^.enfants.t[panel^.enfants.taille-1]^.typeE := texte;
			panel^.enfants.t[panel^.enfants.taille-1]^.valeur := concat('T3 : ', seconde_to_temps(infoPartie.joueurs.t[i].temps.tours[3]));
			panel^.enfants.t[panel^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
			panel^.enfants.t[panel^.enfants.taille-1]^.etat.x := 50+300*i;
			panel^.enfants.t[panel^.enfants.taille-1]^.etat.y := 460;		
			
			ajouter_enfant(panel^);
			panel^.enfants.t[panel^.enfants.taille-1]^.typeE := texte;
			panel^.enfants.t[panel^.enfants.taille-1]^.valeur := 'Final : ';
			panel^.enfants.t[panel^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
			panel^.enfants.t[panel^.enfants.taille-1]^.etat.x := 40+300*i;
			panel^.enfants.t[panel^.enfants.taille-1]^.etat.y := 520;
		end;
				  
		if infoPartie.joueurs.taille = 1 then
		begin
			ajouter_enfant(panel^);
			panel^.enfants.t[panel^.enfants.taille-1]^.typeE := texte;
			panel^.enfants.t[panel^.enfants.taille-1]^.valeur := Concat('Record personnel : ');
			panel^.enfants.t[panel^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
			panel^.enfants.t[panel^.enfants.taille-1]^.etat.x := 40;
			panel^.enfants.t[panel^.enfants.taille-1]^.etat.y := 200;	
		end;
		
		ajouter_enfant(panel^);
		panel^.enfants.t[panel^.enfants.taille-1]^.typeE := image;
		panel^.enfants.t[panel^.enfants.taille-1]^.etat.x := 50;
		panel^.enfants.t[panel^.enfants.taille-1]^.etat.y := 600;
		panel^.enfants.t[panel^.enfants.taille-1]^.surface := IMG_Load('jeu_menu/back-button.png');
		
	actif := True;
	
	while actif do
	begin
		while SDL_PollEvent(@event_sdl) = 1 do
			if (event_sdl.type_ = SDL_QUITEV)
				OR (event_sdl.key.keysym.sym = 13)
				OR ((event_sdl.type_ = SDL_MOUSEBUTTONDOWN)	AND isInElement(panel^.enfants.t[panel^.enfants.taille-1]^, event_sdl.motion.x, event_sdl.motion.y)) then
				actif := False;
		
		frame_afficher(fenetre);
		SDL_Flip(fenetre.surface);
	end;


	scoreMaj(concat('circuits/',infoPartie.config^.circuit.nom, '.dat'), scores);
end;

procedure course_depart(var infoPartie: T_GAMEPLAY; var fenetre: T_UI_ELEMENT);
var i: ShortInt;
begin
	//Affichage circuit
	afficher_camera(infoPartie, fenetre);
	
	//Masquer HUD
	infoPartie.hud.global^.style.display := False;
	
	//Feu
	ajouter_enfant(fenetre);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;					
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x:=100;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y:=100;
	
	//Décompte
	for i:=0 to 2 do
	begin
		//Affichage feu
		fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := IMG_Load(Pchar(concat('feu/feu', intToStr(i), '.png')));
		
		//Rendu
		frame_afficher(fenetre);
		SDL_Flip(fenetre.surface);
		
		//Délai
		Sleep(1000);
		SDL_FreeSurface(fenetre.enfants.t[fenetre.enfants.taille-1]^.surface);
	end;
	
	//Cacher feu/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	fenetre.enfants.t[fenetre.enfants.taille-1]^.style.display := False;
	
	//Afficher HUD
	infoPartie.hud.global^.style.display := True;
   
	//Démarage temps
	infoPartie.temps.debut := SDL_GetTicks();
	infoPartie.temps.last := infoPartie.temps.debut;
end;

procedure partie_course(var infoPartie: T_GAMEPLAY; var physique: T_PHYSIQUE_TABLEAU; fenetre: T_UI_ELEMENT);{Main Loop}
var	timer: array[0..7] of LongInt; {départ, boucle, delay,user,physique,gameplay,courseAfficher,frameAfficher}
	x,y: tcrtcoord;
begin
	//Procédure départ
	course_depart(infoPartie, fenetre);
	
	//Boucle de jeu
	infoPartie.actif:=True;
	while infoPartie.actif do
	begin
		//Calcul dt pour interpolation
		infoPartie.temps.dt := (SDL_GetTicks()-infoPartie.temps.last)/1000;
		
		//Nouveau temps
		infoPartie.temps.last := SDL_GetTicks();
		
		//Intéraction utilisateur
		course_user(infoPartie);

		//Mouvements physique
		frame_physique(physique, infoPartie);

		//Evenements gameplay
		course_gameplay(infoPartie, fenetre.enfants.t[0]^.surface);

		//Affichage
		course_afficher(infoPartie, physique, fenetre);

		//Rendu
		frame_afficher(fenetre);

		//Mise a jour écran
		SDL_Flip(fenetre.surface);
		
		//Calcul temps éxecution
		timer[0] := SDL_GetTicks() - infoPartie.temps.last;
		
		//Calcul délai
		timer[1] := Round(1000/C_REFRESHRATE)-timer[0];
		if timer[1] < 0 then
			timer[1]:=0;
		
		//Délai
		SDL_Delay(timer[1]);
		
		//Affichage console
		x:= WhereX();
		y:= WhereY();
		gotoxy(1,1);
		writeln('|||||',C_UI_FENETRE_NOM,'|||||');
		write('Took ',timer[0], 'ms to render. FPS=');
		ClrEol();
		write(1000 div timer[0]);
		gotoxy(x,y);
	end;
	
	course_arrivee(infoPartie, fenetre);
end;

procedure partie_init(var infoPartie: T_GAMEPLAY; var physique: T_PHYSIQUE_TABLEAU; var fenetre: T_UI_ELEMENT);
var i,j: Integer;
	fond_hd, fond_hg, fond_j1, fond_j2, circuit_nom, temps_texte, j1_pseudo, j2_pseudo,tour_texte1,tour_texte2: P_UI_ELEMENT;
	
begin
	infoPartie.temps.debut:=0;
	infoPartie.temps.fin:=0;
	infoPartie.temps.last:=0;
	infoPartie.temps.dt:=0;
	infoPartie.zoom:=1.000001;
	infoPartie.map.current := NIL;
	infoPartie.premier := 0;
	fenetre.enfants.taille:=0;
	physique.taille:=0;
	
	//Fond ecran
	fenetre.typeE:=couleur;
	fenetre.couleur.r:=57;
	fenetre.couleur.g:=181;
	fenetre.couleur.b:=74;
	fenetre.style.a:=255;
	
	//Load Map
	ajouter_enfant(fenetre);
	imageLoad(infoPartie.config^.circuit.chemin, infoPartie.map.base, false);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.style.enabled:=False; //Desactive styles ( lag )
	infoPartie.map.current := @fenetre.enfants.t[fenetre.enfants.taille-1]^.surface;
	
	//Joueurs

	infoPartie.joueurs.taille := infoPartie.config^.joueurs.taille;
	GetMem(infoPartie.joueurs.t, infoPartie.joueurs.taille*SizeOf(T_JOUEUR));
	
	for i:=0 to infoPartie.joueurs.taille-1 do
	begin
		infoPartie.joueurs.t[i].voiture.chemin := infoPartie.config^.joueurs.t[i].chemin;
		infoPartie.joueurs.t[i].nom := infoPartie.config^.joueurs.t[i].nom;
		infoPartie.joueurs.t[i].temps.actuel := 0;
		infoPartie.joueurs.t[i].nbTour := 1;
		for j:=1 to 3 do
			infoPartie.joueurs.t[i].temps.tours[j]:=0;
		
		ajouter_physique(physique);
		ajouter_enfant(fenetre);
		imageLoad(infoPartie.joueurs.t[i].voiture.chemin, infoPartie.joueurs.t[i].voiture.surface, True);
		infoPartie.joueurs.t[i].voiture.physique := physique.t[physique.taille-1];

		infoPartie.joueurs.t[i].voiture.physique^.x := 150+i;
		infoPartie.joueurs.t[i].voiture.physique^.y := 1100+i;

		infoPartie.joueurs.t[i].voiture.ui := fenetre.enfants.t[fenetre.enfants.taille-1];
		infoPartie.joueurs.t[i].voiture.ui^.typeE := image;
		
	end;
	
	FreeMem(infoPartie.config^.joueurs.t, infoPartie.config^.joueurs.taille*SizeOf(T_CONFIG_JOUEUR));
	infoPartie.config^.joueurs.taille:=0;
   
	//fin boucle
	
	//afficher_camera(infoPartie,fenetre);
	
	//Global
	ajouter_enfant(fenetre);
	infoPartie.hud.global := fenetre.enfants.t[fenetre.enfants.taille-1];
	infoPartie.hud.global^.typeE := couleur;
	infoPartie.hud.global^.couleur.r:=0;
	infoPartie.hud.global^.couleur.g:=0;
	infoPartie.hud.global^.couleur.b:=0;
	infoPartie.hud.global^.style.a :=0;
	infoPartie.hud.global^.etat.w:=1600;
	infoPartie.hud.global^.etat.h:=900;
	infoPartie.hud.global^.surface:= SDL_CreateRGBSurface(0, fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.w, fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.h, 32, 0,0,0,0);
	
		//HUD Fond HautDroite
		ajouter_enfant(infoPartie.hud.global^);
		fond_hd := infoPartie.hud.global^.enfants.t[infoPartie.hud.global^.enfants.taille-1];
		fond_hd^.typeE := couleur;
		fond_hd^.couleur.r:=0;
		fond_hd^.couleur.g:=0;
		fond_hd^.couleur.b:=0;
		fond_hd^.style.a :=128;
		fond_hd^.etat.w:=300;
		fond_hd^.etat.h:=90;
		fond_hd^.etat.x:=1300;
		fond_hd^.surface:= SDL_CreateRGBSurface(0,fond_hd^.etat.w,fond_hd^.etat.h, 32, 0,0,0,0);
	
			fond_hd^.enfants.taille := 0;
		   
			//HUD Circuit nom
			ajouter_enfant(fond_hd^);										
			circuit_nom:=fond_hd^.enfants.t[fond_hd^.enfants.taille-1];
			circuit_nom^.typeE := texte;
			circuit_nom^.valeur := Concat('Circuit : ',infoPartie.config^.circuit.nom);
			circuit_nom^.police := TTF_OpenFont('arial.ttf',25);
			circuit_nom^.couleur.r :=0;
			circuit_nom^.couleur.g :=0;
			circuit_nom^.couleur.b :=0;
			circuit_nom^.etat.x:=5;
			circuit_nom^.etat.y:=10;
			
			//HUD Temps texte
			ajouter_enfant(fond_hd^);
			temps_texte:=fond_hd^.enfants.t[fond_hd^.enfants.taille-1];
			temps_texte^.typeE := texte;
			temps_texte^.valeur := 'Temps : ';
			temps_texte^.police := TTF_OpenFont('arial.ttf',25);
			temps_texte^.couleur.r :=0;
			temps_texte^.couleur.g :=0;
			temps_texte^.couleur.b :=0;
			temps_texte^.etat.x:=5;
			temps_texte^.etat.y:=50;
			
			//HUD Temps valeur
			ajouter_enfant(fond_hd^);
			infoPartie.hud.temps:=fond_hd^.enfants.t[fond_hd^.enfants.taille-1];
			infoPartie.hud.temps^.typeE := texte;
			infoPartie.hud.temps^.valeur := infoPartie.hud.temps^.valeur;
			infoPartie.hud.temps^.police := TTF_OpenFont('arial.ttf',25);
			infoPartie.hud.temps^.couleur.r :=0;
			infoPartie.hud.temps^.couleur.g :=0;
			infoPartie.hud.temps^.couleur.b :=0;
			infoPartie.hud.temps^.etat.x:=100;
			infoPartie.hud.temps^.etat.y:=50;
		
		//HUD Fond J1
		ajouter_enfant(infoPartie.hud.global^);
		fond_j1 :=infoPartie.hud.global^.enfants.t[infoPartie.hud.global^.enfants.taille-1];
		fond_j1^.typeE := couleur;
		fond_j1^.couleur.r:=0;
		fond_j1^.couleur.g:=0;
		fond_j1^.couleur.b:=0;
		fond_j1^.style.a :=128;
		fond_j1^.etat.w:=200;
		fond_j1^.etat.h:=200; 
		fond_j1^.etat.x:=0;
		fond_j1^.etat.y:=700;
		fond_j1^.surface:= SDL_CreateRGBSurface(0, fond_j1^.etat.w, fond_j1^.etat.h, 32, 0,0,0,0);
		
			fond_j1^.enfants.taille :=0;
			
			//HUD Pseudo J1
			ajouter_enfant(fond_j1^);
			j1_pseudo:= fond_j1^.enfants.t[fond_j1^.enfants.taille-1];
			j1_pseudo^.typeE := texte;
			j1_pseudo^.valeur := Concat('J1 : ',infoPartie.joueurs.t[0].nom);
			j1_pseudo^.police := TTF_OpenFont('arial.ttf',25);
			j1_pseudo^.couleur.r :=235;
			j1_pseudo^.couleur.g :=130;
			j1_pseudo^.couleur.b :=24;
			j1_pseudo^.etat.x:=5;
			j1_pseudo^.etat.y:=5;

			//HUD Vitesse
			ajouter_enfant(fond_j1^);
			infoPartie.joueurs.t[0].hud.vitesse:=fond_j1^.enfants.t[fond_j1^.enfants.taille-1];
			infoPartie.joueurs.t[0].hud.vitesse^.typeE := texte;
			infoPartie.joueurs.t[0].hud.vitesse^.valeur := 'iVitesse';
			infoPartie.joueurs.t[0].hud.vitesse^.police := TTF_OpenFont('arial.ttf',25);
			infoPartie.joueurs.t[0].hud.vitesse^.couleur.r :=0;
			infoPartie.joueurs.t[0].hud.vitesse^.couleur.g :=0;
			infoPartie.joueurs.t[0].hud.vitesse^.couleur.b :=0;
			infoPartie.joueurs.t[0].hud.vitesse^.etat.x := 5;
			infoPartie.joueurs.t[0].hud.vitesse^.etat.y := 40;
			
			//HUD Secteur 1
			ajouter_enfant(fond_j1^);
			infoPartie.joueurs.t[0].hud.secteur[0] := fond_j1^.enfants.t[fond_j1^.enfants.taille-1];
			infoPartie.joueurs.t[0].hud.secteur[0]^.typeE := texte;
			infoPartie.joueurs.t[0].hud.secteur[0]^.police := TTF_OpenFont('arial.ttf',25);
			infoPartie.joueurs.t[0].hud.secteur[0]^.couleur.r :=0;
			infoPartie.joueurs.t[0].hud.secteur[0]^.couleur.g :=0;
			infoPartie.joueurs.t[0].hud.secteur[0]^.couleur.b :=0;
			infoPartie.joueurs.t[0].hud.secteur[0]^.etat.x := 5;
			infoPartie.joueurs.t[0].hud.secteur[0]^.etat.y := 90;
			
			//HUD Secteur 2
			ajouter_enfant(fond_j1^);
			infoPartie.joueurs.t[0].hud.secteur[1] := fond_j1^.enfants.t[fond_j1^.enfants.taille-1];
			infoPartie.joueurs.t[0].hud.secteur[1]^.typeE := texte;
			infoPartie.joueurs.t[0].hud.secteur[1]^.police := TTF_OpenFont('arial.ttf',25);
			infoPartie.joueurs.t[0].hud.secteur[1]^.couleur.r :=0;
			infoPartie.joueurs.t[0].hud.secteur[1]^.couleur.g :=0;
			infoPartie.joueurs.t[0].hud.secteur[1]^.couleur.b :=0;
			infoPartie.joueurs.t[0].hud.secteur[1]^.etat.x := 5;
			infoPartie.joueurs.t[0].hud.secteur[1]^.etat.y := 120;
			
			//HUD Secteur 3
			ajouter_enfant(fond_j1^);
			infoPartie.joueurs.t[0].hud.secteur[2] := fond_j1^.enfants.t[fond_j1^.enfants.taille-1];
			infoPartie.joueurs.t[0].hud.secteur[2]^.typeE := texte;
			infoPartie.joueurs.t[0].hud.secteur[2]^.police := TTF_OpenFont('arial.ttf',25);
			infoPartie.joueurs.t[0].hud.secteur[2]^.couleur.r :=0;
			infoPartie.joueurs.t[0].hud.secteur[2]^.couleur.g :=0;
			infoPartie.joueurs.t[0].hud.secteur[2]^.couleur.b :=0;
			infoPartie.joueurs.t[0].hud.secteur[2]^.etat.x := 5;
			infoPartie.joueurs.t[0].hud.secteur[2]^.etat.y := 150;
			
		//HUD Fond HG
		ajouter_enfant(infoPartie.hud.global^);
		fond_hg := infoPartie.hud.global^.enfants.t[infoPartie.hud.global^.enfants.taille-1];
		fond_hg^.typeE := couleur;
		fond_hg^.couleur.r:=0;
		fond_hg^.couleur.g:=0;
		fond_hg^.couleur.b:=0;
		fond_hg^.style.a :=128;
		fond_hg^.etat.w:=250;
		fond_hg^.etat.h:=50;
		fond_hg^.surface:= SDL_CreateRGBSurface(0, fond_hg^.etat.w, fond_hg^.etat.h, 32, 0,0,0,0);
	   
			fond_hg^.enfants.taille := 0;
			
			ajouter_enfant(fond_hg^);
			tour_texte1 :=fond_hg^.enfants.t[fond_hg^.enfants.taille-1];
			tour_texte1^.typeE := texte;
			tour_texte1^.valeur := 'Tour ';
			tour_texte1^.police := TTF_OpenFont('arial.ttf',25);
			tour_texte1^.couleur.r :=235;
			tour_texte1^.couleur.g :=130;
			tour_texte1^.couleur.b :=24;
			tour_texte1^.etat.x:=5;
			tour_texte1^.etat.y:=10;
			
			//HUD Tour actuel
			ajouter_enfant(fond_hg^);
			infoPartie.hud.actuelTour :=fond_hg^.enfants.t[fond_hg^.enfants.taille-1];
			infoPartie.hud.actuelTour^.typeE := texte;
			infoPartie.hud.actuelTour^.valeur := '1';
			infoPartie.hud.actuelTour^.police := TTF_OpenFont('arial.ttf',25);
			infoPartie.hud.actuelTour^.couleur.r :=235;
			infoPartie.hud.actuelTour^.couleur.g :=130;
			infoPartie.hud.actuelTour^.couleur.b :=24;
			infoPartie.hud.actuelTour^.etat.x:=60;
			infoPartie.hud.actuelTour^.etat.y:=10;		
   
			ajouter_enfant(fond_hg^);
			tour_texte2 :=fond_hg^.enfants.t[fond_hg^.enfants.taille-1];
			tour_texte2^.typeE := texte;
			tour_texte2^.valeur := Concat(' / ',IntToStr(infoPartie.config^.nbTour));
			tour_texte2^.police := TTF_OpenFont('arial.ttf',25);
			tour_texte2^.couleur.r :=235;
			tour_texte2^.couleur.g :=130;
			tour_texte2^.couleur.b :=24;
			tour_texte2^.etat.x:=70;
			tour_texte2^.etat.y:=10;

	if infoPartie.joueurs.taille = 2 then
	begin
		//HUD Fond J2
		ajouter_enfant(infoPartie.hud.global^);
		fond_j2 := infoPartie.hud.global^.enfants.t[infoPartie.hud.global^.enfants.taille-1];
		fond_j2^.typeE := couleur;
		fond_j2^.couleur.r:=0;
		fond_j2^.couleur.g:=0;
		fond_j2^.couleur.b:=0;
		fond_j2^.style.a :=128;
		fond_j2^.etat.w:=170;
		fond_j2^.etat.h:=200;
		fond_j2^.etat.x:=1430;
		fond_j2^.etat.y:=700;
		fond_j2^.surface:= SDL_CreateRGBSurface(0, fond_j2^.etat.w, fond_j2^.etat.h, 32, 0,0,0,0);

			fond_j2^.enfants.taille :=0;

			//HUD Pseudo J2
			ajouter_enfant(fond_j2^);
			j2_pseudo :=fond_j2^.enfants.t[fond_j2^.enfants.taille-1];
			j2_pseudo^.typeE := texte;
			j2_pseudo^.valeur := Concat('J2 : ',infoPartie.joueurs.t[1].nom);
			j2_pseudo^.police := TTF_OpenFont('arial.ttf',25);
			j2_pseudo^.couleur.r :=235;
			j2_pseudo^.couleur.g :=130;
			j2_pseudo^.couleur.b :=24;
			j2_pseudo^.etat.x:=5;
			j2_pseudo^.etat.y:=5;	

			//HUD Vitesse
			ajouter_enfant(fond_j2^);
			infoPartie.joueurs.t[1].hud.vitesse:=fond_j2^.enfants.t[fond_j2^.enfants.taille-1];
			infoPartie.joueurs.t[1].hud.vitesse^.typeE := texte;
			infoPartie.joueurs.t[1].hud.vitesse^.valeur := 'iVitesse';
			infoPartie.joueurs.t[1].hud.vitesse^.police := TTF_OpenFont('arial.ttf',25);
			infoPartie.joueurs.t[1].hud.vitesse^.couleur.r :=0;
			infoPartie.joueurs.t[1].hud.vitesse^.couleur.g :=0;
			infoPartie.joueurs.t[1].hud.vitesse^.couleur.b :=0;
			infoPartie.joueurs.t[1].hud.vitesse^.etat.x := 5;
			infoPartie.joueurs.t[1].hud.vitesse^.etat.y := 40;
			
			//HUD Secteur 1
			ajouter_enfant(fond_j2^);
			infoPartie.joueurs.t[1].hud.secteur[0] := fond_j2^.enfants.t[fond_j2^.enfants.taille-1];
			infoPartie.joueurs.t[1].hud.secteur[0]^.typeE := texte;
			infoPartie.joueurs.t[1].hud.secteur[0]^.valeur := 'secteur 1';
			infoPartie.joueurs.t[1].hud.secteur[0]^.police := TTF_OpenFont('arial.ttf',25);
			infoPartie.joueurs.t[1].hud.secteur[0]^.couleur.r :=0;
			infoPartie.joueurs.t[1].hud.secteur[0]^.couleur.g :=0;
			infoPartie.joueurs.t[1].hud.secteur[0]^.couleur.b :=0;
			infoPartie.joueurs.t[1].hud.secteur[0]^.etat.x := 5;
			infoPartie.joueurs.t[1].hud.secteur[0]^.etat.y := 70;
			
			//HUD Secteur 2
			ajouter_enfant(fond_j2^);
			infoPartie.joueurs.t[1].hud.secteur[1] := fond_j2^.enfants.t[fond_j2^.enfants.taille-1];
			infoPartie.joueurs.t[1].hud.secteur[1]^.typeE := texte;
			infoPartie.joueurs.t[1].hud.secteur[1]^.valeur := 'secteur 2';
			infoPartie.joueurs.t[1].hud.secteur[1]^.police := TTF_OpenFont('arial.ttf',25);
			infoPartie.joueurs.t[1].hud.secteur[1]^.couleur.r :=0;
			infoPartie.joueurs.t[1].hud.secteur[1]^.couleur.g :=0;
			infoPartie.joueurs.t[1].hud.secteur[1]^.couleur.b :=0;
			infoPartie.joueurs.t[1].hud.secteur[1]^.etat.x := 5;
			infoPartie.joueurs.t[1].hud.secteur[1]^.etat.y := 100;
			
			//HUD Secteur 3
			ajouter_enfant(fond_j2^);
			infoPartie.joueurs.t[1].hud.secteur[2] := fond_j2^.enfants.t[fond_j2^.enfants.taille-1];
			infoPartie.joueurs.t[1].hud.secteur[2]^.typeE := texte;
			infoPartie.joueurs.t[1].hud.secteur[2]^.valeur := 'secteur 3';
			infoPartie.joueurs.t[1].hud.secteur[2]^.police := TTF_OpenFont('arial.ttf',25);
			infoPartie.joueurs.t[1].hud.secteur[2]^.couleur.r :=0;
			infoPartie.joueurs.t[1].hud.secteur[2]^.couleur.g :=0;
			infoPartie.joueurs.t[1].hud.secteur[2]^.couleur.b :=0;
			infoPartie.joueurs.t[1].hud.secteur[2]^.etat.x := 5;
			infoPartie.joueurs.t[1].hud.secteur[2]^.etat.y := 130;
		
		fond_hg^.etat.h:=100;
		fond_hg^.surface:= SDL_CreateRGBSurface(0, fond_hg^.etat.w, fond_hg^.etat.h, 32, 0,0,0,0);
		   
		//HUD premier
		ajouter_enfant(fond_hg^);
		infoPartie.hud.nom_premier:=fond_hg^.enfants.t[fond_hg^.enfants.taille-1];
		infoPartie.hud.nom_premier^.typeE := texte;
		infoPartie.hud.nom_premier^.valeur := Concat('Premier : ',infoPartie.joueurs.t[0].nom);
		infoPartie.hud.nom_premier^.police := TTF_OpenFont('arial.ttf',25);
		infoPartie.hud.nom_premier^.couleur.r :=235;
		infoPartie.hud.nom_premier^.couleur.g :=130;
		infoPartie.hud.nom_premier^.couleur.b :=24;
		infoPartie.hud.nom_premier^.etat.x:=5;
		infoPartie.hud.nom_premier^.etat.y:=50;
	end;
		
end;

procedure jeu_partie(var config: T_CONFIG; fenetre: T_UI_ELEMENT);
var physique : T_PHYSIQUE_TABLEAU;
	infoPartie: T_GAMEPLAY;
begin
	infoPartie.config := @config;
	partie_init(infoPartie, physique, fenetre);
	partie_course(infoPartie, physique, fenetre);
end;

procedure jeu_menu(fenetre: T_UI_ELEMENT);
var event_sdl: TSDL_Event;
	champTexte: array[1..2] of P_UI_ELEMENT;
	panel: array[1..3] of P_UI_ELEMENT;
	tabSkin : array [0..4] of PSDL_Surface;
	tabMiniCircuit : array [0..1] of PSDL_Surface;
	
	tabCircuit : array [0..1] of ansiString;
  tabMode : array [0..1] of ansiString;
	
	actuelMode, actuelCircuit: ShortInt;
	actuelSkin: array[0..1] of ShortInt;
	
	pseudo : array[0..1] of String;
	
	timer: array[0..2] of LongInt;
	config : T_CONFIG;
	actif: Boolean;
	i,j: ShortInt;
begin
	//Initialisation
	pseudo[0] := ''; //Pseudo J1
	pseudo[1] := ''; //Pseudo J2
	
	actuelSkin[0] := 0; //skin J1
	actuelSkin[1] := 0; //skin J2
	
	actuelMode := 0; //mode de jeu
	actuelCircuit :=0; //circuit
	
	//Texte mode de jeu
	tabMode[0] := 'Contre-la-montre'; 
	tabMode[1] := '1 vs 1';

	//Texte nom circuits
	tabCircuit[0] := 'first';
	tabCircuit[1] := 'demo';

	//chargement images skin
	tabSkin[0] := IMG_Load('voitures/rouge.png');
	tabSkin[1] := IMG_Load('voitures/jaune.png');
	tabSkin[2] := IMG_Load('voitures/bleu.png');
	tabSkin[3] := IMG_Load('voitures/voiture.png');
	tabSkin[4] := IMG_Load('voitures/carreRouge.png');
	
	//Chargement images circuits
	tabMiniCircuit[0] := IMG_Load('circuits/firstmini.png');
	tabMiniCircuit[1] :=  IMG_Load('circuits/demomini.png');
	
	//Couleur de fond
	fenetre.couleur.r:=243;
	fenetre.couleur.g:=243;
	fenetre.couleur.b:=215;
	
	//Vider affichage
	fenetre.enfants.taille:=0;
	
	//Bouton retour
	ajouter_enfant(fenetre);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 45;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 800;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := IMG_Load('jeu_menu/back-button.png'); 
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;	
	
	//Prévisualisation circuit
	ajouter_enfant(fenetre);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 200;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 525;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := tabMiniCircuit[actuelCircuit];
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;	
	
	//Panneau mode de jeu
	ajouter_enfant(fenetre);
	panel[1] := fenetre.enfants.t[fenetre.enfants.taille-1];
	panel[1]^.etat.x := 150;
	panel[1]^.etat.y := 75;
	panel[1]^.surface := IMG_Load('jeu_menu/grey_panel.png'); 
	panel[1]^.typeE := image;	
		
		//Texte 'Mode de Jeu'
		ajouter_enfant(panel[1]^);
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.typeE := texte;
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.valeur := 'Mode de jeu';
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.etat.x := 50;
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.etat.y := 77;	
		
		//Mode de jeu
		ajouter_enfant(panel[1]^);
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.typeE := texte;
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.valeur := 'Contre-la-montre';
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.etat.x := 300;
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.etat.y := 80;
		
		//Texte 'Circuit'
		ajouter_enfant(panel[1]^);
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.typeE := texte;
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.valeur := 'Circuit';
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.etat.x := 90;
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.etat.y := 250;
		
		//Nom circuit
		ajouter_enfant(panel[1]^);
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.typeE := texte;
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.valeur := tabCircuit[actuelCircuit];
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.etat.x := 355;
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.etat.y := 250;
		
		//Bouton gauche mode de jeu
		ajouter_enfant(panel[1]^);	
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.etat.x := 250; 
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.etat.y := 80;
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.surface := IMG_Load('jeu_menu/blue_sliderLeft.png');  
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.typeE := image;
		
		//Bouton droit mode de jeu
		ajouter_enfant(panel[1]^);	
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.etat.x := 500; 
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.etat.y := 80;
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.surface := IMG_Load('jeu_menu/blue_sliderRight.png'); 
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.typeE := image;
		
		//Bouton gauche circuit
		ajouter_enfant(panel[1]^);	
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.etat.x := 250; 
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.etat.y := 250;
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.surface :=IMG_Load('jeu_menu/blue_sliderLeft.png'); 
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.typeE := image;
		
		//Bouton droit circuit
		ajouter_enfant(panel[1]^);	
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.etat.x := 500; 
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.etat.y := 250;
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.surface :=IMG_Load('jeu_menu/blue_sliderRight.png'); 
		panel[1]^.enfants.t[panel[1]^.enfants.taille-1]^.typeE := image;
	
	//Boucle Panneau J1,J2
	for i:=0 to 1 do
	begin
		//Panneau
		ajouter_enfant(fenetre);
		panel[2+i] := fenetre.enfants.t[fenetre.enfants.taille-1];	
		panel[2+i]^.etat.x := 900; 
		panel[2+i]^.etat.y := 75+425*i;
		panel[2+i]^.surface := IMG_Load('jeu_menu/grey_panel.png'); 
		panel[2+i]^.typeE := image;
			
			//Texte 'pseudo'
			ajouter_enfant(panel[2+i]^);
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.typeE := texte;
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.valeur := 'Pseudo';
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.etat.x := 80;
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.etat.y := 90;
			
			//Texte 'skin'
			ajouter_enfant(panel[2+i]^);
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.typeE := texte;
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.valeur := 'Skin';
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.etat.x := 80;
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.etat.y := 250;
			
			//Nom skin
			ajouter_enfant(panel[2+i]^);
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.etat.x := 370;
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.etat.y := 235;
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.surface := tabSkin[actuelSkin[i]];
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.typeE := image;
				
			//Champ texte pseudo
			ajouter_enfant(panel[2+i]^);																	
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.etat.x := 300;                                         
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.etat.y := 80;
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.surface := IMG_Load('jeu_menu/grey_button05.png'); 
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.typeE := image;
			
				//Texte pseudo
				ajouter_enfant(panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^);
				champTexte[1+i] := panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.enfants.t[0];
				champTexte[1+i]^.etat.x := 15; 						
				champTexte[1+i]^.etat.y := 12; 																			
				champTexte[1+i]^.typeE := texte;					
				champTexte[1+i]^.police := TTF_OpenFont('arial.ttf',20);		
				champTexte[1+i]^.valeur := pseudo[i];
					
					//Curseur
					ajouter_enfant(champTexte[1+i]^);
					champTexte[1+i]^.enfants.t[0]^.valeur := 'curseur';					
					champTexte[1+i]^.enfants.t[0]^.etat.y := 3; 									
					champTexte[1+i]^.enfants.t[0]^.etat.w := 2;
					champTexte[1+i]^.enfants.t[0]^.etat.h := 20;									
					champTexte[1+i]^.enfants.t[0]^.surface := SDL_CreateRGBSurface(SDL_HWSURFACE, champTexte[1+i]^.enfants.t[0]^.etat.w, champTexte[1+i]^.enfants.t[0]^.etat.h, 32, 0, 0, 0, 0);									
					champTexte[1+i]^.enfants.t[0]^.typeE := couleur;
				
			//Bouton gauche skin
			ajouter_enfant(panel[2+i]^);
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.etat.x := 250; 
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.etat.y := 250;
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.surface := IMG_Load('jeu_menu/blue_sliderLeft.png'); 
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.typeE := image;
			
			//Bouton droit skin
			ajouter_enfant(panel[2+i]^);
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.etat.x := 500; 
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.etat.y := 250;
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.surface := IMG_Load('jeu_menu/blue_sliderRight.png'); 
			panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-1]^.typeE := image;
	end;
	
	//Boucle affichage
	actif := True;
	while actif do
	begin
		//Stocker temps
		timer[0]:=SDL_GetTicks();
		
		//Interaction utilisateur
		while SDL_PollEvent(@event_sdl) = 1 do
		begin
			case event_sdl.type_ of
				SDL_QUITEV : actif:=False; //Click croix fenetre
				
				SDL_MOUSEBUTTONDOWN : //Click souris
				begin
					writeln( 'Mouse button pressed : Button index : ',event_sdl.button.button);
					
					//Bouton retour
					if isInElement(fenetre.enfants.t[fenetre.enfants.taille-5]^, event_sdl.motion.x, event_sdl.motion.y) and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
					begin
						Sleep(200);
						actif:=False;
					end;
					
					//Désélectionner champs pseudo
					if isInElement(fenetre,event_sdl.motion.x,event_sdl.motion.y) and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
					begin
						panel[2]^.enfants.t[panel[2]^.enfants.taille-3]^.valeur := '0';
						panel[3]^.enfants.t[panel[3]^.enfants.taille-3]^.valeur := '0';
					end;
					
					//Boutons panneau mode de jeu
					for i:=1 to 4 do
						if isInElement(panel[1]^.enfants.t[panel[1]^.enfants.taille-i]^, event_sdl.motion.x, event_sdl.motion.y) and (event_sdl.button.state = SDL_PRESSED)	and (event_sdl.button.button = 1) then
							panel[1]^.enfants.t[panel[1]^.enfants.taille-i]^.valeur := '1';
					
					//Boutons panneaux J1/J2
					for i:=0 to 1 do 
						for j:=1 to 3 do //Boucle boutons
							if isInElement(panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-j]^, event_sdl.motion.x, event_sdl.motion.y) and (event_sdl.button.state = SDL_PRESSED)	and (event_sdl.button.button = 1) then
								panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-j]^.valeur := '1';
				end;
				
				SDL_KEYDOWN : //Touche clavier
				begin
					
					//champ texte actif J1/J2
					for i:=0 to 1 do 
						if panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-3]^.valeur = '1' then
							updatePseudo(event_sdl.key.keysym.sym, pseudo[i]);
						
					//Touche 'Entrée'
					if event_sdl.key.keysym.sym = 13 then
					begin
						//Retour au menu en fin de partie
						actif := False;

						
						//Remplissage configuration
						config.circuit.nom := tabCircuit[actuelCircuit];
						config.circuit.chemin:= './circuits/'+tabCircuit[actuelCircuit]+'.png';
						
						//3 tours
						config.nbTour:= 3;

						
						//Mode 1 ou 2 joueurs
						if panel[3]^.style.display then
							config.joueurs.taille := 2
						else
							config.joueurs.taille := 1;
						
						//Récuperation mémoire J1/J2
						GetMem(config.joueurs.t, config.joueurs.taille*SizeOf(T_CONFIG_JOUEUR));
					
						//J1/J2
						for i:=0 to config.joueurs.taille-1 do
						begin
							//Skin
							case actuelSkin[i] of
								0 : config.joueurs.t[i].chemin := 'voitures/rouge.png';
								1 : config.joueurs.t[i].chemin := 'voitures/jaune.png';
								2 : config.joueurs.t[i].chemin := 'voitures/bleu.png';
								3 : config.joueurs.t[i].chemin := 'voitures/voiture.png';
								4 : config.joueurs.t[i].chemin := 'voitures/carreRouge.png';
							end;
							
							//Pseudo
							config.joueurs.t[i].nom := pseudo[i];
						end;
						
						//Lancement Partie
						jeu_partie(config, fenetre);
					end;
				end;
			end;
		end;
		
		//Sélection mode de jeu (gauche)
		if  panel[1]^.enfants.t[4]^.valeur = '1' then
		begin
			if actuelMode-1<0 then //Effet infini
			begin
				actuelMode := 1;
				panel[1]^.enfants.t[panel[1]^.enfants.taille-7]^.valeur := tabMode[actuelMode];
			end
			else
			begin
				actuelMode := actuelMode-1;
				panel[1]^.enfants.t[panel[1]^.enfants.taille-7]^.valeur := tabMode[actuelMode];
			end;
			
			//Fin évenement
			panel[1]^.enfants.t[4]^.valeur := '0';
		end;
		
		//Sélection mode de jeu (droite)
		if  panel[1]^.enfants.t[5]^.valeur = '1' then
		begin
			if actuelMode+1 > length(tabMode)-1 then //Effet infini
			begin
				actuelMode := 0;
				panel[1]^.enfants.t[panel[1]^.enfants.taille-7]^.valeur := tabMode[actuelMode];
			end
			else
			begin
				actuelMode := actuelMode+1;
				panel[1]^.enfants.t[panel[1]^.enfants.taille-7]^.valeur := tabMode[actuelMode];
			end;
			
			//Fin évenement
			panel[1]^.enfants.t[5]^.valeur := '0';
		end;
		
		//Sélection circuit (gauche)
		if  panel[1]^.enfants.t[6]^.valeur = '1' then
		begin
			if actuelCircuit-1 < 0 then //Effet infini
			begin
				actuelCircuit := length(tabCircuit)-1;
				panel[1]^.enfants.t[panel[1]^.enfants.taille-5]^.valeur := tabCircuit[actuelCircuit];
			end
			else
			begin
				actuelCircuit := actuelCircuit-1;
				panel[1]^.enfants.t[panel[1]^.enfants.taille-5]^.valeur := tabCircuit[actuelCircuit];
			end;

			//Fin évenement
			panel[1]^.enfants.t[6]^.valeur := '0'
		end;
		
		//Sélection circuit (droite)
		if  panel[1]^.enfants.t[7]^.valeur = '1' then
		begin
			if actuelCircuit+1 > length(tabCircuit)-1 then //Effet infini
			begin
				actuelCircuit := 0;
				panel[1]^.enfants.t[panel[1]^.enfants.taille-5]^.valeur := tabCircuit[actuelCircuit];
			end
			else
			begin
				actuelCircuit := actuelCircuit+1;
				panel[1]^.enfants.t[panel[1]^.enfants.taille-5]^.valeur := tabCircuit[actuelCircuit];
			end;
			
			//Fin évenement
			panel[1]^.enfants.t[7]^.valeur := '0';
		end;
		
		//Affichage panneau J1/J2
		for i:=0 to 1 do
		begin
		
			//Champ texte actif
			if panel[2+i]^.enfants.t[3]^.valeur = '1' then 
			begin
				//Curseur clignote toute les 0.25s
				champTexte[1+i]^.enfants.t[0]^.style.display := (SDL_GetTicks() mod 500) < 250;
				
				//Affichage pseudo
				champTexte[1+i]^.valeur := pseudo[i];
			end
			else //Champ texte inactif: cacher curseur
				champTexte[1+i]^.enfants.t[0]^.style.display := False;

			//Sélection skin (gauche)
			if panel[2+i]^.enfants.t[4]^.valeur = '1' then
			begin
				if actuelSkin[i]-1 < 0 then //Effet infini
				begin
					actuelSkin[i] := length(tabSkin)-1;
					panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-4]^.surface := tabSkin[actuelSkin[i]];
				end
				else
				begin
					actuelSkin[i] := actuelSkin[i]-1;
					panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-4]^.surface := tabSkin[actuelSkin[i]];
				end;
				
				//Fin évenement
				panel[2+i]^.enfants.t[4]^.valeur := '0';
			end;
			
			//Sélection skin (droit)
			if panel[2+i]^.enfants.t[5]^.valeur = '1' then 
			begin
				if actuelSkin[i]+1 > length(tabSkin)-1 then //Effet infini
				begin
					actuelSkin[i] := 0;
					panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-4]^.surface := tabSkin[actuelSkin[i]];
				end
				else
				begin
					actuelSkin[i] := actuelSkin[i]+1;
					panel[2+i]^.enfants.t[panel[2+i]^.enfants.taille-4]^.surface := tabSkin[actuelSkin[i]];
				end;
				
				//Fin évenement
				panel[2+i]^.enfants.t[5]^.valeur := '0'; 
			end;
			
		end;
		
		//Affichage circuit miniature en fonction du choix
		fenetre.enfants.t[fenetre.enfants.taille-4]^.surface := tabMiniCircuit[actuelCircuit];
		
		//Affichage panneau J2 en fonction du mode de jeu
		panel[3]^.style.display := actuelMode = 1;
		
		//Rendu
		frame_afficher(fenetre);
		
		//Affichage a l'ecran		
		SDL_FLip(fenetre.surface);

		//Calcul images par seconde et délai
		timer[1] := SDL_GetTicks() - timer[0];
		timer[2] := Round(1000/C_REFRESHRATE)-timer[1];
		
		if timer[2] < 0 then
			timer[2]:=0;
			
		SDL_Delay(timer[2]);
	end;
end;

procedure score(var fenetre: T_UI_ELEMENT);
begin
	
end;

procedure menu(var fenetre: T_UI_ELEMENT);
var	event_sdl : TSDL_Event;
	actif : Boolean;
	boutons: array[0..3,0..2] of PSDL_Surface;
	i : ShortInt;
begin
	//Initialisation
	fenetre.typeE:=couleur;
	fenetre.couleur.r:=197;
	fenetre.couleur.g:=197;
	fenetre.couleur.b:=197;
	
	//Chargement Boutons
	for i:=0 to 2 do
		boutons[0][i] := IMG_Load(Pchar(concat('menu/buttons/jouerbutton',intToStr(i),'.png')));
	for i:=0 to 2 do
		boutons[1][i] := IMG_Load(Pchar(concat('menu/buttons/scoresbutton',intToStr(i),'.png')));
	for i:=0 to 2 do
		boutons[2][i] := IMG_Load(Pchar(concat('menu/buttons/tutorielbutton',intToStr(i),'.png')));
	for i:=0 to 2 do
		boutons[3][i] := IMG_Load(Pchar(concat('menu/buttons/quitterbutton',intToStr(i),'.png')));
		
	//Fond d'écran
	ajouter_enfant(fenetre);
	imageLoad('menu/background1.png',fenetre.enfants.t[fenetre.enfants.taille-1]^.surface, False); 
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;
	
	//Logo
	ajouter_enfant(fenetre);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 150; 
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 75;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := IMG_Load('menu/logo1.png'); 
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;	
	
	//Boutons
	for i:=0 to length(boutons)-1 do
	begin
		ajouter_enfant(fenetre);
		fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := boutons[i][0];
		fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;
	end;
	
	//Boucle affichage
	actif := True;
	while actif do
	begin
		//Interaction utilisateur
		while SDL_PollEvent(@event_sdl) = 1 do
		begin
			case event_sdl.type_ of
				
				SDL_QUITEV : actif:=False; //Click croix fenetre
				
				SDL_MOUSEMOTION: //Mouvement souris
					//Boutons
					for i:=0 to length(boutons)-1 do
					begin
						//Au dessus
						if isInElement(fenetre.enfants.t[fenetre.enfants.taille+-4+i]^, event_sdl.motion.x, event_sdl.motion.y) then
						begin
							fenetre.enfants.t[fenetre.enfants.taille-4+i]^.surface := boutons[i][2];
							fenetre.enfants.t[fenetre.enfants.taille-4+i]^.etat.x := 65;
							fenetre.enfants.t[fenetre.enfants.taille-4+i]^.etat.y := 375+i*125;
						end
						//Ailleurs
						else
						begin
							fenetre.enfants.t[fenetre.enfants.taille-4+i]^.surface := boutons[i][0];
							fenetre.enfants.t[fenetre.enfants.taille-4+i]^.etat.x := 90;
							fenetre.enfants.t[fenetre.enfants.taille-4+i]^.etat.y := 375+i*125;
						end;			
					end;
					
				SDL_MOUSEBUTTONDOWN : //Click souris
				begin
					//Bouton jouer
					if isInElement(fenetre.enfants.t[fenetre.enfants.taille-4]^, event_sdl.motion.x, event_sdl.motion.y) and (event_sdl.button.state = SDL_PRESSED)	and (event_sdl.button.button = 1) then
					begin
						//Bouton enfoncé
						fenetre.enfants.t[fenetre.enfants.taille-4]^.surface := boutons[0][1];
						
						//Rendu
						frame_afficher(fenetre);
						
						//Affichage
						SDL_FLip(fenetre.surface);
						
						//Délai puis jeu_menu
						Sleep(300);
						jeu_menu(fenetre);
					end;
					
					//Bouton scores
					if isInElement(fenetre.enfants.t[fenetre.enfants.taille-3]^, event_sdl.motion.x, event_sdl.motion.y) and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
					begin
						//Bouton enfoncé
						fenetre.enfants.t[fenetre.enfants.taille-3]^.surface := boutons[1][1];
						
						//Rendu
						frame_afficher(fenetre);
						
						//Affichage
						SDL_FLip(fenetre.surface);
						
						//Délai puis score
						Sleep(300);
						test();
						
					end;
					if isInElement(fenetre.enfants.t[fenetre.enfants.taille-2]^, event_sdl.motion.x, event_sdl.motion.y) and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
					begin
						//Bouton enfoncé
						fenetre.enfants.t[fenetre.enfants.taille-2]^.surface := boutons[2][1];
						
						//Rendu
						frame_afficher(fenetre);
						
						//Affichage
						SDL_FLip(fenetre.surface);
						
						//Délai puis tutoriel
						Sleep(300);
						/////////////////////////////////////
						/////////////////////////////////////
						/////////////////////////////////////
						//tutoriel(fenetre);
						/////////////////////////////////////
						/////////////////////////////////////
						/////////////////////////////////////
					end;
					
					if isInElement(fenetre.enfants.t[fenetre.enfants.taille-1]^, event_sdl.motion.x, event_sdl.motion.y) and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
					begin
						//Bouton enfoncé
						fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := boutons[3][1];
						
						//Rendu
						frame_afficher(fenetre);
						
						//Affichage
						SDL_FLip(fenetre.surface);
						
						//Délai puis quitter
						Sleep(300);
						actif:=False;	
					end;
				end;
			end;
		end;
		
		//Rendu
		frame_afficher(fenetre);
		
		//Affichage
		SDL_FLip(fenetre.surface);
	end;
end;

function lancement(): T_UI_ELEMENT;
begin
	//Affichage console
	writeln('|||', C_UI_FENETRE_NOM, '|||');
	writeln('#Lancement...');
	
	//Initialisation librairie SDL
	if SDL_Init(SDL_INIT_TIMER or SDL_INIT_VIDEO) = 0 then
	begin
		//Initialisation librairie TTF
		TTF_Init();
		
		//Création fenetre SDL & surface
		lancement.surface := SDL_SetVideoMode(C_UI_FENETRE_WIDTH, C_UI_FENETRE_HEIGHT, 32, SDL_HWSURFACE or SDL_DOUBLEBUF);
		
		//Validation surface
		if lancement.surface <> NIL then
		begin
			//Titre fenêtre
			SDL_WM_SetCaption(C_UI_FENETRE_NOM, NIL);
			
			//Initialisation
			lancement.etat.x:=0;
			lancement.etat.y:=0;
			lancement.enfants.t:=NIL;
			lancement.enfants.taille:=0;
			lancement.parent:=NIL;
		end else
			//Erreur création fenêtre
			writeln('Erreur setVideoMode'); 
	end	else
		//Erreur initialisation SDL
		writeln('Erreur Initialisation');
end;

var fenetre : T_UI_ELEMENT;
begin
	//Initialisation
	fenetre := lancement();
	//Lancement Menu
	menu(fenetre);
	
	//Déchargement librairie TTF
	TTF_Quit();
	
	//Déchargement librairie SDL
	SDL_Quit();
end.

