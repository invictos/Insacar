program demo;


uses sdl, sdl_ttf, sdl_image, sdl_gfx, INSACAR_TYPES, sysutils, strutils, tools;

const
	C_REFRESHRATE = 90; {FPS} // TEST COMMIT
	C_UI_FENETRE_WIDTH = 1600;
	C_UI_FENETRE_HEIGHT = 900;
	C_UI_ZOOM_W = 70 ;
	C_UI_ZOOM_H = 70 ;
	
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR = 0.2; // kg.s^(-1)
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_EAU = 0.1;
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_TERRE = 5;
	
	C_PHYSIQUE_VOITURE_ACCELERATION_AVANT = 5.6; // m.s^(-2)
	C_PHYSIQUE_VOITURE_ACCELERATION_ARRIERE = 12;// m.s^(-2)
	C_PHYSIQUE_VOITURE_ANGLE = 90; // Deg.s^(-1)
	
	C_UI_FENETRE_NOM = 'InsaCar Alpha 2.0';

procedure frame_afficher_low(var element: T_UI_ELEMENT; var frame: PSDL_Surface; etat: T_RENDER_ETAT);
var i : Integer;
		s : ansiString;
begin
	case element.typeE of
		couleur:
		begin
			SDL_FillRect(element.surface, NIL, SDL_MapRGBA(element.surface^.format, element.couleur.r, element.couleur.g, element.couleur.b, 255));
		end;
		texte:
		begin
			s:= element.valeur;
			SDL_FreeSurface(element.surface);
			element.surface := TTF_RenderText_Blended(element.police, Pchar(s), element.couleur);
		end;
		image:
		begin
		end;
	end;
	//Rendu

	if element.style.enabled then //Test if alpha is active
	begin
		if element.style.a<>255 then
		begin
			SDL_SetAlpha(element.surface, SDL_SRCALPHA, element.style.a);
		end;
	end;

	
	//Position
	etat.rect.x:=etat.rect.x+element.etat.x;
	etat.rect.y:=etat.rect.y+element.etat.y;
	//SDL
	
	SDL_BlitSurface(element.surface, NIL, frame, @etat.rect);
	
	//PostRendu
	if (element.typeE = texte) AND (element.enfants.taille <> 0) AND (element.surface <> NIL) then
		etat.rect.x:=etat.rect.x + element.surface^.w;
	
	//Enfants
	for i:=0 to element.enfants.taille-1 do
		if element.enfants.t[i]^.style.display then
			frame_afficher_low(element.enfants.t[i]^, frame, etat);
end;

procedure frame_afficher(var element: T_UI_ELEMENT);
var etat: T_RENDER_ETAT;
begin
	etat.rect.x:=0;
	etat.rect.y:=0;
	etat.a:=255;
	etat.o:=255;
	//writeln('NEWRENDER');
	frame_afficher_low(element,element.surface,etat);
	//writeln('ENDRENDER');
end;



procedure afficher_hud(var infoPartie: T_GAMEPLAY; var fenetre: T_UI_ELEMENT);
begin
	infoPartie.hud.vitesse^.valeur:=IntToStr(Round(-infoPartie.joueurs.t[0].voiture.physique^.dr/2.5)); //Normalement /25 mais physique <> S.I.
	infoPartie.hud.temps_tour^.valeur:= seconde_to_temps(infoPartie.temps.last-infoPartie.temps.debut);
	infoPartie.hud.temps_tour^.couleur := pixel_get(infoPartie.map.base, Round(infoPartie.joueurs.t[0].voiture.physique^.x) , Round(infoPartie.joueurs.t[0].voiture.physique^.y));
	
{
	infoPartie.hud.secteur[1]^.valeur := seconde_to_temps(infoPartie.joueurs.t[0].temps.secteur[1]-infoPartie.joueurs.t[0].temps.debut);
	infoPartie.hud.secteur[2]^.valeur := seconde_to_temps(infoPartie.joueurs.t[0].temps.secteur[2]-infoPartie.joueurs.t[0].temps.secteur[1]);
	infoPartie.hud.secteur[3]^.valeur := seconde_to_temps(infoPartie.joueurs.t[0].temps.secteur[3]-infoPartie.joueurs.t[0].temps.secteur[2]);
}
	if infoPartie.joueurs.t[0].temps.actuel <> 4 then
		infoPartie.hud.secteur[infoPartie.joueurs.t[0].temps.actuel]^.valeur := seconde_to_temps(infoPartie.temps.last-infoPartie.joueurs.t[0].temps.secteur[infoPartie.joueurs.t[0].temps.actuel-1]);
end;

procedure afficher_camera(var infoPartie: T_GAMEPLAY; var fenetre: T_UI_ELEMENT);
var i : Integer;
	xm,ym: Integer;
	z,w,h, zw, zh: Real;
begin
	xm := 0;
	ym := 0;
	//Map
	if infoPartie.joueurs.taille=2 then
	begin
		w := sqrt((infoPartie.joueurs.t[0].voiture.physique^.x-infoPartie.joueurs.t[1].voiture.physique^.x)*(infoPartie.joueurs.t[0].voiture.physique^.x-infoPartie.joueurs.t[1].voiture.physique^.x));
		h := sqrt((infoPartie.joueurs.t[0].voiture.physique^.y-infoPartie.joueurs.t[1].voiture.physique^.y)*(infoPartie.joueurs.t[0].voiture.physique^.y-infoPartie.joueurs.t[1].voiture.physique^.y));
		
		if w <> 0 then
			 zw := (C_UI_ZOOM_W/100*C_UI_FENETRE_WIDTH)/w
		else zw := 1;
			
		if h <> 0 then
			 zh := (C_UI_ZOOM_H/100*C_UI_FENETRE_HEIGHT)/h
		else zh := 1;
		
		z := ZoomMin(zw, zh);
		
		z := Round(z*5000)/5000;
		writeln('Zoom calc: ', z, 'now : ', infoPartie.zoom);
		if z <> infoPartie.zoom then
		begin
			writeln('ZoomData : ',z,'//',w,'//',h,'///',zw,'/',zh);
			infoPartie.zoom:=z;
{
			infoPartie.map.old := infoPartie.map.ecran;
			infoPartie.map.ecran := infoPartie.map.current^;
}
			SDL_FreeSurface(infoPartie.map.current^);
			infoPartie.map.current^ := zoomSurface(infoPartie.map.base, z, z, 0);
		end;
		writeln('Zoom out: ', z, 'now : ', infoPartie.zoom);
		
		xm:= Round(infoPartie.zoom*infoPartie.joueurs.t[1].voiture.physique^.x/2);
		ym:= Round(infoPartie.zoom*infoPartie.joueurs.t[1].voiture.physique^.y/2);
	end;
		
	xm:=Round(xm+infoPartie.zoom*infoPartie.joueurs.t[0].voiture.physique^.x/2);
	ym:=Round(ym+infoPartie.zoom*infoPartie.joueurs.t[0].voiture.physique^.y/2);

	
	fenetre.enfants.t[0]^.etat.x := -Round(xm-C_UI_FENETRE_WIDTH/2);
	fenetre.enfants.t[0]^.etat.y := -Round(ym-C_UI_FENETRE_HEIGHT/2);


	
	//Joueurs
	for i:=0 to infoPartie.joueurs.taille-1 do
	begin
		SDL_freeSurface(infoPartie.joueurs.t[i].voiture.ui^.surface);
		infoPartie.joueurs.t[i].voiture.ui^.surface := rotozoomSurface(infoPartie.joueurs.t[i].voiture.surface, infoPartie.joueurs.t[i].voiture.physique^.a, infoPartie.zoom, 1);
		infoPartie.joueurs.t[i].voiture.ui^.etat.x := Round(infoPartie.zoom*infoPartie.joueurs.t[i].voiture.physique^.x+fenetre.enfants.t[0]^.etat.x-infoPartie.joueurs.t[i].voiture.ui^.surface^.w/2);
		infoPartie.joueurs.t[i].voiture.ui^.etat.y := Round(infoPartie.zoom*infoPartie.joueurs.t[i].voiture.physique^.y+fenetre.enfants.t[0]^.etat.y-infoPartie.joueurs.t[i].voiture.ui^.surface^.h/2);		
{
		infoPartie.joueurs.t[i].voiture.ui^.etat.x := Round(C_UI_FENETRE_WIDTH/2-infoPartie.joueurs.t[i].voiture.ui^.surface^.w/2);
		infoPartie.joueurs.t[i].voiture.ui^.etat.y := Round(C_UI_FENETRE_HEIGHT/2-infoPartie.joueurs.t[i].voiture.ui^.surface^.h/2);
}
	writeln('JOUEUR ',i+1,':',infoPartie.joueurs.t[i].voiture.physique^.x,'/',infoPartie.joueurs.t[i].voiture.physique^.y);
	writeln('    ',infoPartie.joueurs.t[i].voiture.ui^.etat.x,':',infoPartie.joueurs.t[i].voiture.ui^.etat.y);
	end;
end;

procedure course_afficher(var infoPartie: T_GAMEPLAY; var physique: T_PHYSIQUE_TABLEAU; var fenetre: T_UI_ELEMENT);
begin
	afficher_camera(infoPartie, fenetre);
	afficher_hud(infoPartie, fenetre);
end;

procedure course_gameplay(var infoPartie: T_GAMEPLAY; var circuit: PSDL_Surface);
var c: PSDL_Color;
	p: SDL_Rect;
	t: ShortInt;
	a: T_HITBOX_COLOR;
	i: ShortInt;
	//x1,x2,y1,y2,xm,ym: Integer;
begin
	//infoPartie.hud.vitesse^.couleur := pixel_get(circuit, Round(infoPartie.joueurs.t[0].voiture.physique^.x),Round(infoPartie.joueurs.t[0].voiture.physique^.y));
	if infoPartie.joueurs.t[0].voiture.ui^.surface <> NIL then
	begin
		
		t:=3;
		GetMem(c, t*SizeOf(TSDL_Color));
		c[0].r:=252; //Jaune CP1
		c[0].g:=238;
		c[0].b:=31;
		
		c[1].r:=252; //Jaune CP2
		c[1].g:=238;
		c[1].b:=32;
		
		c[2].r:=247; //Orange
		c[2].g:=147;
		c[2].b:=30;
		
		
		
		p.x := Round(infoPartie.joueurs.t[0].voiture.physique^.x);
		p.y := Round(infoPartie.joueurs.t[0].voiture.physique^.y);
		p.w := infoPartie.joueurs.t[0].voiture.surface^.w;
		p.h := infoPartie.joueurs.t[0].voiture.surface^.h;
		
		//writeln('HBDEBUT');
		a := hitBox(infoPartie.map.base, p, infoPartie.joueurs.t[0].voiture.physique^.a, c, t);
		//writeln('HBFIN');
		for i:=0 to a.taille-1 do
		begin
			writeln('P',a.data[i].n);
			if (a.data[i].n=1) AND isSameColor(c[2],a.data[i].c) AND (infoPartie.joueurs.t[0].temps.actuel > 2) then
			begin
				infoPartie.hud.debug^.couleur.r:=255;
				if(infoPartie.joueurs.t[0].temps.actuel = 3) then
				begin
					infoPartie.joueurs.t[0].temps.secteur[3] := infoPartie.temps.last;				
					writeln('TEMPS TOURS:');
					writeln('S1:',infoPartie.joueurs.t[0].temps.secteur[1]-infoPartie.joueurs.t[0].temps.secteur[0]);
					writeln('S2:',infoPartie.joueurs.t[0].temps.secteur[2]-infoPartie.joueurs.t[0].temps.secteur[1]);
					writeln('S3:',infoPartie.joueurs.t[0].temps.secteur[3]-infoPartie.joueurs.t[0].temps.secteur[2]);
				end;
				infoPartie.joueurs.t[0].temps.secteur[0] := infoPartie.temps.last;
				infoPartie.joueurs.t[0].temps.secteur[1] := 0;
				infoPartie.joueurs.t[0].temps.secteur[2] := 0;
				infoPartie.joueurs.t[0].temps.secteur[3] := 0;
				infoPartie.joueurs.t[0].temps.actuel := 1;
			end;
			if (a.data[i].n=1) AND isSameColor(c[0],a.data[i].c) AND (infoPartie.joueurs.t[0].temps.actuel = 1) then
			begin
				infoPartie.hud.debug^.couleur.r:=128;
				infoPartie.joueurs.t[0].temps.secteur[1] := infoPartie.temps.last;
				infoPartie.joueurs.t[0].temps.actuel := 2;
			end;
			if (a.data[i].n=1) AND isSameColor(c[1],a.data[i].c) AND (infoPartie.joueurs.t[0].temps.actuel = 2) then
			begin
				infoPartie.hud.debug^.couleur.r:=0;
				infoPartie.joueurs.t[0].temps.secteur[2] := infoPartie.temps.last;
				infoPartie.joueurs.t[0].temps.actuel := 3;
			end;
		end;
		Freemem(c, t*SizeOf(TSDL_Color));
		
	end;
end;

procedure frame_physique(var physique: T_PHYSIQUE_TABLEAU; var infoPartie: T_GAMEPLAY);
var i,j : ShortInt;
	c: PSDL_Color;
	hb : T_HITBOX_COLOR;
	p : SDL_Rect;
	t : ShortInt;
begin
	for i:=0 to physique.taille-1 do
		begin
		t:=1;
		GetMem(c, t*SizeOf(TSDL_Color));
		
		c[0].r:=57;
		c[0].g:=181;
		c[0].b:=74;
		
		p.x := Round(infoPartie.joueurs.t[i].voiture.physique^.x);
		p.y := Round(infoPartie.joueurs.t[i].voiture.physique^.y);
		p.w := infoPartie.joueurs.t[i].voiture.surface^.w-10;
		p.h := infoPartie.joueurs.t[i].voiture.surface^.h-10;
		
		hb := hitBox(infoPartie.map.base, p, infoPartie.joueurs.t[i].voiture.physique^.a, c, t);
		//writeln('hb ',hb.taille);
		for j:=0 to hb.taille-1 do
		begin
			if(hb.data[j].n = 2) OR (hb.data[j].n = 1) OR (hb.data[j].n = 7) AND isSameColor(hb.data[j].c,c[0]) then
			begin
				writeln(t,'STOP', hb.data[j].c.r);
				infoPartie.joueurs.t[i].voiture.physique^.dr := 0;
			end;
		end;
		
		if hb.taille<>0 then
			physique.t[i]^.dr:=physique.t[i]^.dr - infoPartie.temps.dt*C_PHYSIQUE_FROTTEMENT_COEFFICIENT_TERRE*physique.t[i]^.dr
		else
			physique.t[i]^.dr:=physique.t[i]^.dr - infoPartie.temps.dt*C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR*physique.t[i]^.dr;
			
		physique.t[i]^.x:=physique.t[i]^.x + infoPartie.temps.dt*sin(3.141592/180*physique.t[i]^.a)*physique.t[i]^.dr;
		physique.t[i]^.y:=physique.t[i]^.y + infoPartie.temps.dt*cos(3.141592/180*physique.t[i]^.a)*physique.t[i]^.dr;
		FreeMem(c, t*SizeOf(TSDL_Color));
	end;
end;

procedure course_user(var infoPartie: T_GAMEPLAY;var actif: boolean);
var event_sdl: TSDL_Event;
	event_clavier: PUint8;
begin
	SDL_PollEvent(@event_sdl);
	if event_sdl.type_=SDL_QUITEV then actif:=False;
	
	event_clavier := SDL_GetKeyState(NIL);
	
	{$IFDEF WINDOWS}
	if event_clavier[SDLK_Q] = SDL_PRESSED then
		infoPartie.joueurs.t[0].voiture.physique^.dr := infoPartie.joueurs.t[0].voiture.physique^.dr - infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ACCELERATION_AVANT*25;
	{$ENDIF}
	{$IFDEF LINUX}
	if event_clavier[SDLK_A] = SDL_PRESSED then
		infoPartie.joueurs.t[0].voiture.physique^.dr := infoPartie.joueurs.t[0].voiture.physique^.dr - infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ACCELERATION_AVANT*25;
	{$ENDIF}
	if event_clavier[SDLK_TAB] = SDL_PRESSED then
		infoPartie.joueurs.t[0].voiture.physique^.dr := infoPartie.joueurs.t[0].voiture.physique^.dr + infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ACCELERATION_ARRIERE*25;
		
	if event_clavier[SDLK_R] = SDL_PRESSED then
		infoPartie.joueurs.t[0].voiture.physique^.a := infoPartie.joueurs.t[0].voiture.physique^.a + infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ANGLE;
		
	if event_clavier[SDLK_Y] = SDL_PRESSED then
		infoPartie.joueurs.t[0].voiture.physique^.a := infoPartie.joueurs.t[0].voiture.physique^.a - infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ANGLE;
	
	if infoPartie.joueurs.taille=2 then
	begin
		if event_clavier[SDLK_RCTRL] = SDL_PRESSED then
			infoPartie.joueurs.t[1].voiture.physique^.dr := infoPartie.joueurs.t[1].voiture.physique^.dr - infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ACCELERATION_AVANT*25;
			
		if event_clavier[SDLK_MENU] = SDL_PRESSED then
			infoPartie.joueurs.t[1].voiture.physique^.dr := infoPartie.joueurs.t[1].voiture.physique^.dr + infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ACCELERATION_ARRIERE*25;
			
		if event_clavier[SDLK_KP1] = SDL_PRESSED then
			infoPartie.joueurs.t[1].voiture.physique^.a := infoPartie.joueurs.t[1].voiture.physique^.a + infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ANGLE;
			
		if event_clavier[SDLK_KP3] = SDL_PRESSED then
			infoPartie.joueurs.t[1].voiture.physique^.a := infoPartie.joueurs.t[1].voiture.physique^.a - infoPartie.temps.dt*C_PHYSIQUE_VOITURE_ANGLE;
	end;
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
begin
	course_depart(fenetre);
	actif:=true;
	while actif do
	begin
		infoPartie.temps.dt:=(SDL_GetTicks()-infoPartie.temps.last)/1000;
		//writeln('DT: ',infoPartie.temps.dt);
		infoPartie.temps.last := SDL_GetTicks();
		//write('1');
		timer[0]:=SDL_GetTicks();
		
		course_user(infoPartie, actif);
		timer[3]:=SDL_GetTicks();
		//write('2');
		frame_physique(physique, infoPartie);
		timer[4]:=SDL_GetTicks();
		
		//write('3');
		course_gameplay(infoPartie, fenetre.enfants.t[0]^.surface);
		timer[5]:=SDL_GetTicks();
		
		//write('4');
		course_afficher(infoPartie, physique, fenetre);
		timer[6]:=SDL_GetTicks();
		//write('5');
		frame_afficher(fenetre);
		timer[7]:=SDL_GetTicks();
		//write('6');
		SDL_Flip(fenetre.surface);
		//writeln('7');
		
		timer[1] := SDL_GetTicks() - timer[0];
		timer[2] := Round(1000/C_REFRESHRATE)-timer[1];
		if timer[2] < 0 then timer[2]:=0;
		SDL_Delay(timer[2]);
		writeln('Took ',timer[1], 'ms to render. FPS=', 1000 div (SDL_GetTicks() - timer[0]),'///',timer[3]-timer[0],'/',timer[4]-timer[3],'/',timer[5]-timer[4],'/',timer[6]-timer[5],'/',timer[7]-timer[6],'//', timer[2]);
	end;
	
	course_arrivee(infoPartie, fenetre);
end;

procedure partie_init(var infoPartie: T_GAMEPLAY; var physique: T_PHYSIQUE_TABLEAU; var fenetre: T_UI_ELEMENT);
var i: Integer;
begin
	infoPartie.temps.debut:=0;
	infoPartie.temps.fin:=0;
	infoPartie.temps.last:=0;
	infoPartie.temps.dt:=0;
	infoPartie.zoom:=0;
	infoPartie.map.current := NIL;
	fenetre.enfants.taille:=0;
	physique.taille:=0;

	//Fond ecran
	fenetre.typeE:=couleur;
	fenetre.couleur.r:=57;
	fenetre.couleur.g:=181;
	fenetre.couleur.b:=74;
	fenetre.style.a:=255;
	
	//Load Map
	ajouter_enfant(fenetre.enfants);
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
		infoPartie.joueurs.t[i].temps.actuel := 4;
		
		ajouter_physique(physique);
		ajouter_enfant(fenetre.enfants);
		infoPartie.joueurs.t[i].voiture.physique := physique.t[physique.taille-1];
		infoPartie.joueurs.t[i].voiture.physique^.x := 400;
		infoPartie.joueurs.t[i].voiture.physique^.y := 350;
		infoPartie.joueurs.t[i].voiture.ui := fenetre.enfants.t[fenetre.enfants.taille-1];
		infoPartie.joueurs.t[i].voiture.ui^.typeE := image;
{
		s:=infoPartie.joueurs.t[i].voiture.chemin;
		temp := IMG_Load(Pchar(s));
		infoPartie.joueurs.t[i].voiture.surface := SDL_DisplayFormatAlpha(temp);
		SDL_FreeSurface(temp);
}
		imageLoad(infoPartie.joueurs.t[i].voiture.chemin, infoPartie.joueurs.t[i].voiture.surface, True);
	end;
	FreeMem(infoPartie.config^.joueurs.t, infoPartie.config^.joueurs.taille*SizeOf(T_CONFIG_JOUEUR));
	infoPartie.config^.joueurs.taille:=0;
	//fin boucle
	
	//HUD Fond
	ajouter_enfant(fenetre.enfants);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := couleur;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.couleur.r:=0;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.couleur.g:=0;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.couleur.b:=0;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.style.a:=128;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.w:=300;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.h:=150;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x:=fenetre.surface^.w-fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.w;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y:=0;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface:= SDL_CreateRGBSurface(0, fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.w, fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.h, 32, 0,0,0,0);

		//HUD Vitesse
		ajouter_enfant(fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants);
		infoPartie.hud.vitesse:=fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.t[fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.taille-1];
		infoPartie.hud.vitesse^.typeE := texte;
		infoPartie.hud.vitesse^.valeur := 'iVitesse';
		infoPartie.hud.vitesse^.police := TTF_OpenFont('arial.ttf',25);
		infoPartie.hud.vitesse^.couleur.r :=0;
		infoPartie.hud.vitesse^.couleur.g :=0;
		infoPartie.hud.vitesse^.couleur.b :=0;
	
		//HUD Temps
		ajouter_enfant(fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants);
		infoPartie.hud.temps_tour:=fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.t[fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.taille-1];
		infoPartie.hud.temps_tour^.typeE := texte;
		infoPartie.hud.temps_tour^.valeur := 'iTempsTour';
		infoPartie.hud.temps_tour^.police := TTF_OpenFont('arial.ttf',25);
		infoPartie.hud.temps_tour^.couleur.r :=0;
		infoPartie.hud.temps_tour^.couleur.g :=0;
		infoPartie.hud.temps_tour^.couleur.b :=0;
		infoPartie.hud.temps_tour^.etat.y:=30;
		
		//HUD Temps S1
		ajouter_enfant(fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants);
		infoPartie.hud.secteur[1]:=fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.t[fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.taille-1];
		infoPartie.hud.secteur[1]^.typeE := texte;
		infoPartie.hud.secteur[1]^.police := TTF_OpenFont('arial.ttf',25);
		infoPartie.hud.secteur[1]^.couleur.r :=0;
		infoPartie.hud.secteur[1]^.couleur.g :=0;
		infoPartie.hud.secteur[1]^.couleur.b :=0;
		infoPartie.hud.secteur[1]^.etat.y:=60;
		
		//HUD Temps S2
		ajouter_enfant(fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants);
		infoPartie.hud.secteur[2]:=fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.t[fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.taille-1];
		infoPartie.hud.secteur[2]^.typeE := texte;
		infoPartie.hud.secteur[2]^.police := TTF_OpenFont('arial.ttf',25);
		infoPartie.hud.secteur[2]^.couleur.r :=0;
		infoPartie.hud.secteur[2]^.couleur.g :=0;
		infoPartie.hud.secteur[2]^.couleur.b :=0;
		infoPartie.hud.secteur[2]^.etat.y:=90;
		
		//HUD Temps S3
		ajouter_enfant(fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants);
		infoPartie.hud.secteur[3]:=fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.t[fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.taille-1];
		infoPartie.hud.secteur[3]^.typeE := texte;
		infoPartie.hud.secteur[3]^.police := TTF_OpenFont('arial.ttf',25);
		infoPartie.hud.secteur[3]^.couleur.r :=0;
		infoPartie.hud.secteur[3]^.couleur.g :=0;
		infoPartie.hud.secteur[3]^.couleur.b :=0;
		infoPartie.hud.secteur[3]^.etat.y:=120;


	//HUD Debug
	ajouter_enfant(fenetre.enfants);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := couleur;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.couleur.b:=255;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.w:=20;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.h:=20;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x:=10;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y:=10;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface:= SDL_CreateRGBSurface(0, fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.w, fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.h, 32, 0,0,0,0);
	infoPartie.hud.debug:=fenetre.enfants.t[fenetre.enfants.taille-1];
	
	ajouter_enfant(fenetre.enfants);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := couleur;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.couleur.r:=255;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.w:=2;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.h:=2;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface:= SDL_CreateRGBSurface(0, fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.w, fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.h, 32, 0,0,0,0);
	infoPartie.hud.debug2:=fenetre.enfants.t[fenetre.enfants.taille-1];

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
	panel1, panel2, panel3, txt, champTxt, txt3, champTxt3: P_UI_ELEMENT;
	actuelCircuit, actuelSkin: Integer;
	actif: Boolean;
	pseudo, pseudo2 : String;
	event_clavier : PUInt8;
	tabCircuit : array [0..2] of ansiString;
	tabMiniCircuit : array [0..2] of PSDL_Surface;
	tabSkin: array[0..4] of PSDL_Surface;
	timer: array[0..2] of LongInt;
	config : T_CONFIG;
	
begin
	pseudo := '';
	
	pseudo2 := '';
	
	actuelCircuit :=1;
	actuelSkin :=1;
	
	tabSkin[0] := IMG_Load('voiture.png');
	tabSkin[1] := IMG_Load('voitures/rouge.png');
	tabSkin[2] := IMG_Load('voitures/jaune.png');
	tabSkin[3] := IMG_Load('voitures/bleu.png');
	tabSkin[4] := IMG_Load('formule1.png');

	tabCircuit[0] := 'first';
	tabCircuit[1] := 'demo';
	tabCircuit[2] := 'Rouen';
	
	tabMiniCircuit[0] := IMG_Load('circuits/firstmini.png');
	tabMiniCircuit[1] :=  IMG_Load('circuits/demomini.png');
	tabMiniCircuit[2] := IMG_Load('formule1.png');
	
	fenetre.couleur.r:=243;
	fenetre.couleur.g:=243;
	fenetre.couleur.b:=215;
	
	fenetre.enfants.taille:=0;
	
	ajouter_enfant(fenetre.enfants);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 45;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 800;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := IMG_Load('jeu_menu/back-button.png'); 
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;	
	
	ajouter_enfant(fenetre.enfants);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 200;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 525;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := IMG_Load('circuits/firstmini.png'); 
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;	
	
	ajouter_enfant(fenetre.enfants);
	panel1 := fenetre.enfants.t[fenetre.enfants.taille-1];
	panel1^.etat.x := 150;
	panel1^.etat.y := 75;
	panel1^.surface := IMG_Load('jeu_menu/grey_panel.png'); 
	panel1^.typeE := image;	
	
	panel1^.enfants.taille := 0;
		
		ajouter_enfant(panel1^.enfants);
		panel1^.enfants.t[panel1^.enfants.taille-1]^.typeE := texte;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.valeur := 'Mode de jeu';
		panel1^.enfants.t[panel1^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
		panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.x := 50;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.y := 77;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.couleur.r :=0;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.couleur.g :=0;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.couleur.b :=0;		
		
		ajouter_enfant(panel1^.enfants);
		panel1^.enfants.t[panel1^.enfants.taille-1]^.typeE := texte;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.valeur := 'Contre-la-montre';
		
		panel1^.enfants.t[panel1^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
		panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.x := 300;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.y := 80;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.couleur.r :=0;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.couleur.g :=0;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.couleur.b :=0;
		
		ajouter_enfant(panel1^.enfants);
		panel1^.enfants.t[panel1^.enfants.taille-1]^.typeE := texte;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.valeur := 'Circuit';
		panel1^.enfants.t[panel1^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
		panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.x := 90;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.y := 250;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.couleur.r :=0;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.couleur.g :=0;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.couleur.b :=0;	
		
		ajouter_enfant(panel1^.enfants);
		panel1^.enfants.t[panel1^.enfants.taille-1]^.typeE := texte;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.valeur := tabCircuit[actuelCircuit];
		panel1^.enfants.t[panel1^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
		panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.x := 355;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.y := 250;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.couleur.r :=0;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.couleur.g :=0;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.couleur.b :=0;
		
		ajouter_enfant(panel1^.enfants);	
		panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.x := 250; 
		panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.y := 80;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.surface := IMG_Load('jeu_menu/blue_sliderLeft.png');  
		panel1^.enfants.t[panel1^.enfants.taille-1]^.typeE := image;
		
		ajouter_enfant(panel1^.enfants);	
		panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.x := 500; 
		panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.y := 80;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.surface := IMG_Load('jeu_menu/blue_sliderRight.png'); 
		panel1^.enfants.t[panel1^.enfants.taille-1]^.typeE := image;
		
		ajouter_enfant(panel1^.enfants);	
		panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.x := 250; 
		panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.y := 250;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.surface :=IMG_Load('jeu_menu/blue_sliderLeft.png'); 
		panel1^.enfants.t[panel1^.enfants.taille-1]^.typeE := image;
		
		ajouter_enfant(panel1^.enfants);	
		panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.x := 500; 
		panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.y := 250;
		panel1^.enfants.t[panel1^.enfants.taille-1]^.surface :=IMG_Load('jeu_menu/blue_sliderRight.png'); 
		panel1^.enfants.t[panel1^.enfants.taille-1]^.typeE := image;
		
	ajouter_enfant(fenetre.enfants);
	panel2 := fenetre.enfants.t[fenetre.enfants.taille-1];	
	panel2^.etat.x := 900; 
	panel2^.etat.y := 75;
	panel2^.surface := IMG_Load('jeu_menu/grey_panel.png'); 
	panel2^.typeE := image;
	
	panel2^.enfants.taille := 0;
		
		ajouter_enfant(panel2^.enfants);
		panel2^.enfants.t[panel2^.enfants.taille-1]^.typeE := texte;
		panel2^.enfants.t[panel2^.enfants.taille-1]^.valeur := 'Pseudo';
		panel2^.enfants.t[panel2^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
		panel2^.enfants.t[panel2^.enfants.taille-1]^.etat.x := 80;
		panel2^.enfants.t[panel2^.enfants.taille-1]^.etat.y := 90;
		panel2^.enfants.t[panel2^.enfants.taille-1]^.couleur.r :=0;
		panel2^.enfants.t[panel2^.enfants.taille-1]^.couleur.g :=0;
		panel2^.enfants.t[panel2^.enfants.taille-1]^.couleur.b :=0;
		
		ajouter_enfant(panel2^.enfants);
		panel2^.enfants.t[panel2^.enfants.taille-1]^.typeE := texte;
		panel2^.enfants.t[panel2^.enfants.taille-1]^.valeur := 'Skin';
		panel2^.enfants.t[panel2^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
		panel2^.enfants.t[panel2^.enfants.taille-1]^.etat.x := 80;
		panel2^.enfants.t[panel2^.enfants.taille-1]^.etat.y := 250;
		panel2^.enfants.t[panel2^.enfants.taille-1]^.couleur.r :=0;
		panel2^.enfants.t[panel2^.enfants.taille-1]^.couleur.g :=0;
		panel2^.enfants.t[panel2^.enfants.taille-1]^.couleur.b :=0;	
		
		ajouter_enfant(panel2^.enfants);
		panel2^.enfants.t[panel2^.enfants.taille-1]^.etat.x := 370;
		panel2^.enfants.t[panel2^.enfants.taille-1]^.etat.y := 235;
		panel2^.enfants.t[panel2^.enfants.taille-1]^.surface := tabSkin[actuelSkin];
		panel2^.enfants.t[panel2^.enfants.taille-1]^.typeE := image;
			
		
		ajouter_enfant(panel2^.enfants);																	
		panel2^.enfants.t[panel2^.enfants.taille-1]^.etat.x := 300;                                         
		panel2^.enfants.t[panel2^.enfants.taille-1]^.etat.y := 80;
		panel2^.enfants.t[panel2^.enfants.taille-1]^.surface := IMG_Load('jeu_menu/grey_button05.png'); 
		panel2^.enfants.t[panel2^.enfants.taille-1]^.typeE := image;
			
			champTxt := panel2^.enfants.t[panel2^.enfants.taille-1];
			champTxt^.enfants.taille := 0;
		
			ajouter_enfant(champTxt^.enfants);				//texte pseudo
			champTxt^.enfants.t[0]^.etat.x := 15; 						
			champTxt^.enfants.t[0]^.etat.y := 12; 																			
			champTxt^.enfants.t[0]^.typeE := texte;					
			champTxt^.enfants.t[0]^.police := TTF_OpenFont('arial.ttf',20);		
			champTxt^.enfants.t[0]^.valeur := pseudo;
			
		
				txt:= champTxt^.enfants.t[0];
				txt^.enfants.taille := 0;
			
				ajouter_enfant(txt^.enfants); 				//curseur
				txt^.enfants.t[0]^.valeur := 'curseur';	
				txt^.enfants.t[0]^.etat.x := 0; 				
				txt^.enfants.t[0]^.etat.y := 3; 									
				txt^.enfants.t[0]^.etat.w := 2;
				txt^.enfants.t[0]^.etat.h := 20;									
				txt^.enfants.t[0]^.surface := SDL_CreateRGBSurface(SDL_HWSURFACE, txt^.enfants.t[0]^.etat.w, txt^.enfants.t[0]^.etat.h, 32, 0, 0, 0, 0);									
				txt^.enfants.t[0]^.typeE := couleur;
				txt^.enfants.t[0]^.couleur.r := 255;
				txt^.enfants.t[0]^.couleur.g := 255;
				txt^.enfants.t[0]^.couleur.b := 255;
			
		
		ajouter_enfant(panel2^.enfants);
		panel2^.enfants.t[panel2^.enfants.taille-1]^.etat.x := 250; 
		panel2^.enfants.t[panel2^.enfants.taille-1]^.etat.y := 250;
		panel2^.enfants.t[panel2^.enfants.taille-1]^.surface := IMG_Load('jeu_menu/blue_sliderLeft.png'); 
		panel2^.enfants.t[panel2^.enfants.taille-1]^.typeE := image;
		
		ajouter_enfant(panel2^.enfants);
		panel2^.enfants.t[panel2^.enfants.taille-1]^.etat.x := 500; 
		panel2^.enfants.t[panel2^.enfants.taille-1]^.etat.y := 250;
		panel2^.enfants.t[panel2^.enfants.taille-1]^.surface := IMG_Load('jeu_menu/blue_sliderRight.png'); 
		panel2^.enfants.t[panel2^.enfants.taille-1]^.typeE := image;
	
	
	//Mode 2 joueurs
	
	ajouter_enfant(fenetre.enfants);
	panel3 := fenetre.enfants.t[fenetre.enfants.taille-1];	
	panel3^.etat.x := 900; 
	panel3^.etat.y := 500;
	panel3^.surface := IMG_Load('jeu_menu/grey_panel.png'); 
	panel3^.typeE := image;
	
	panel3^.enfants.taille := 0;
		
		ajouter_enfant(panel3^.enfants);
		panel3^.enfants.t[panel3^.enfants.taille-1]^.typeE := texte;
		panel3^.enfants.t[panel3^.enfants.taille-1]^.valeur := 'Pseudo';
		panel3^.enfants.t[panel3^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
		panel3^.enfants.t[panel3^.enfants.taille-1]^.etat.x := 80;
		panel3^.enfants.t[panel3^.enfants.taille-1]^.etat.y := 90;
		panel3^.enfants.t[panel3^.enfants.taille-1]^.couleur.r :=0;
		panel3^.enfants.t[panel3^.enfants.taille-1]^.couleur.g :=0;
		panel3^.enfants.t[panel3^.enfants.taille-1]^.couleur.b :=0;
		
		ajouter_enfant(panel3^.enfants);
		panel3^.enfants.t[panel3^.enfants.taille-1]^.typeE := texte;
		panel3^.enfants.t[panel3^.enfants.taille-1]^.valeur := 'Skin';
		panel3^.enfants.t[panel3^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
		panel3^.enfants.t[panel3^.enfants.taille-1]^.etat.x := 80;
		panel3^.enfants.t[panel3^.enfants.taille-1]^.etat.y := 250;
		panel3^.enfants.t[panel3^.enfants.taille-1]^.couleur.r :=0;
		panel3^.enfants.t[panel3^.enfants.taille-1]^.couleur.g :=0;
		panel3^.enfants.t[panel3^.enfants.taille-1]^.couleur.b :=0;	
		
		ajouter_enfant(panel3^.enfants);
		panel3^.enfants.t[panel3^.enfants.taille-1]^.typeE := image;
		panel3^.enfants.t[panel3^.enfants.taille-1]^.surface := tabSkin[actuelSkin];
		panel3^.enfants.t[panel3^.enfants.taille-1]^.etat.x := 360;
		panel3^.enfants.t[panel3^.enfants.taille-1]^.etat.y := 250;
		
		ajouter_enfant(panel3^.enfants);																	
		panel3^.enfants.t[panel3^.enfants.taille-1]^.etat.x := 300;                                         
		panel3^.enfants.t[panel3^.enfants.taille-1]^.etat.y := 80;
		panel3^.enfants.t[panel3^.enfants.taille-1]^.surface := IMG_Load('jeu_menu/grey_button05.png'); 
		panel3^.enfants.t[panel3^.enfants.taille-1]^.typeE := image;
			
			champTxt3 := panel3^.enfants.t[panel3^.enfants.taille-1];
			champTxt3^.enfants.taille := 0;
		
			ajouter_enfant(champTxt3^.enfants);				//texte pseudo
			champTxt3^.enfants.t[0]^.etat.x := 15; 						
			champTxt3^.enfants.t[0]^.etat.y := 12; 																			
			champTxt3^.enfants.t[0]^.typeE := texte;					
			champTxt3^.enfants.t[0]^.police := TTF_OpenFont('arial.ttf',20);		
			champTxt3^.enfants.t[0]^.valeur := pseudo;
			
		
				txt3:= champTxt3^.enfants.t[0];
				txt3^.enfants.taille := 0;
			
				ajouter_enfant(txt3^.enfants); 				//curseur
				txt3^.enfants.t[0]^.valeur := 'curseur';	
				txt3^.enfants.t[0]^.etat.x := 0; 				
				txt3^.enfants.t[0]^.etat.y := 3; 									
				txt3^.enfants.t[0]^.etat.w := 2;
				txt3^.enfants.t[0]^.etat.h := 20;									
				txt3^.enfants.t[0]^.surface := SDL_CreateRGBSurface(SDL_HWSURFACE, txt3^.enfants.t[0]^.etat.w, txt3^.enfants.t[0]^.etat.h, 32, 0, 0, 0, 0);									
				txt3^.enfants.t[0]^.typeE := couleur;
				txt3^.enfants.t[0]^.couleur.r := 255;
				txt3^.enfants.t[0]^.couleur.g := 255;
				txt3^.enfants.t[0]^.couleur.b := 255;
			
		
		ajouter_enfant(panel3^.enfants);
		panel3^.enfants.t[panel3^.enfants.taille-1]^.etat.x := 250; 
		panel3^.enfants.t[panel3^.enfants.taille-1]^.etat.y := 250;
		panel3^.enfants.t[panel3^.enfants.taille-1]^.surface := IMG_Load('jeu_menu/blue_sliderLeft.png'); 
		panel3^.enfants.t[panel3^.enfants.taille-1]^.typeE := image;
		
		ajouter_enfant(panel3^.enfants);
		panel3^.enfants.t[panel3^.enfants.taille-1]^.etat.x := 500; 
		panel3^.enfants.t[panel3^.enfants.taille-1]^.etat.y := 250;
		panel3^.enfants.t[panel3^.enfants.taille-1]^.surface := IMG_Load('jeu_menu/blue_sliderRight.png'); 
		panel3^.enfants.t[panel3^.enfants.taille-1]^.typeE := image;
	
	
	actif := True;
	
	while actif do
	begin
		timer[0]:=SDL_GetTicks();
		
		while SDL_PollEvent(@event_sdl) = 1 do
		begin
			case event_sdl.type_ of
			
			SDL_QUITEV : actif:=False;
									
			SDL_MOUSEMOTION : 
			begin
				writeln( 'X: ', event_sdl.motion.x, ' Y: ', event_sdl.motion.y);
			end;
			
			SDL_MOUSEBUTTONDOWN :
			begin
				writeln( 'Mouse button pressed : Button index : ',event_sdl.button.button);
				
				//Bouton retour
				if isInElement(fenetre.enfants.t[fenetre.enfants.taille-5]^, event_sdl.motion.x, event_sdl.motion.y)
					and (event_sdl.button.state = SDL_PRESSED)
					and (event_sdl.button.button = 1) then
				begin
					Sleep(200);
					actif:=False;
				end;
				
				//Déselectionner les champs pseudo
				if isInElement(fenetre,event_sdl.motion.x,event_sdl.motion.y) 
					and (event_sdl.button.state = SDL_PRESSED)
					and (event_sdl.button.button = 1) then
				begin
					panel2^.enfants.t[panel2^.enfants.taille-3]^.valeur := '0';
					panel3^.enfants.t[panel3^.enfants.taille-3]^.valeur := '0';
				end;
		
				//Boutons panel1
				
				if (((event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.x > panel1^.enfants.t[panel1^.enfants.taille-4]^.etat.x)
					and (event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.x < panel1^.enfants.t[panel1^.enfants.taille-4]^.etat.x + panel1^.enfants.t[panel1^.enfants.taille-4]^.surface^.w)) 
					and ((event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.y > panel1^.enfants.t[panel1^.enfants.taille-4]^.etat.y)
					and (event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.y < panel1^.enfants.t[panel1^.enfants.taille-4]^.etat.y + panel1^.enfants.t[panel1^.enfants.taille-4]^.surface^.h)))
					and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
				begin // CLICK SELECT GAUCHE MODE
					panel1^.enfants.t[panel1^.enfants.taille-4]^.valeur := '1';
				end;
				
				if (((event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.x > panel1^.enfants.t[panel1^.enfants.taille-3]^.etat.x)
					and (event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.x < panel1^.enfants.t[panel1^.enfants.taille-3]^.etat.x + panel1^.enfants.t[panel1^.enfants.taille-3]^.surface^.w)) 
					and ((event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.y > panel1^.enfants.t[panel1^.enfants.taille-3]^.etat.y)
					and (event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.y < panel1^.enfants.t[panel1^.enfants.taille-3]^.etat.y + panel1^.enfants.t[panel1^.enfants.taille-3]^.surface^.h))) 
					and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
				begin // CLICK SELECT DROIT MODE
					panel1^.enfants.t[panel1^.enfants.taille-3]^.valeur := '1';
				end;
				
				if (((event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.x > panel1^.enfants.t[panel1^.enfants.taille-2]^.etat.x)
					and (event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.x < panel1^.enfants.t[panel1^.enfants.taille-2]^.etat.x + panel1^.enfants.t[panel1^.enfants.taille-2]^.surface^.w)) 
					and ((event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.y > panel1^.enfants.t[panel1^.enfants.taille-2]^.etat.y)
					and (event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.y < panel1^.enfants.t[panel1^.enfants.taille-2]^.etat.y + panel1^.enfants.t[panel1^.enfants.taille-2]^.surface^.h))) 
					and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
				begin // CLICK SELECT DROIT CIRCUIT
					panel1^.enfants.t[panel1^.enfants.taille-2]^.valeur := '1';
				end;
				
				if (((event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.x > panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.x)
					and (event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.x < panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.x + panel1^.enfants.t[panel1^.enfants.taille-1]^.surface^.w)) 
					and ((event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.y > panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.y)
					and (event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.y < panel1^.enfants.t[panel1^.enfants.taille-1]^.etat.y + panel1^.enfants.t[panel1^.enfants.taille-1]^.surface^.h))) 
					and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
				begin // CLICK SELECT GAUCHE CIRCUIT
					panel1^.enfants.t[panel1^.enfants.taille-1]^.valeur := '1';
				end;
				
				//Boutons panel2
			
				if (((event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.x > panel2^.enfants.t[panel2^.enfants.taille-3]^.etat.x)
					and (event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.x < panel2^.enfants.t[panel2^.enfants.taille-3]^.etat.x + panel2^.enfants.t[panel2^.enfants.taille-3]^.surface^.w)) 
					and ((event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.y > panel2^.enfants.t[panel2^.enfants.taille-3]^.etat.y)
					and (event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.y < panel2^.enfants.t[panel2^.enfants.taille-3]^.etat.y + panel2^.enfants.t[panel2^.enfants.taille-3]^.surface^.h))) 
					and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
				begin // CLICK PSEUDO
					panel2^.enfants.t[panel2^.enfants.taille-3]^.valeur := '1';
				end;
				if (((event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.x > panel2^.enfants.t[panel2^.enfants.taille-2]^.etat.x)
					and (event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.x < panel2^.enfants.t[panel2^.enfants.taille-2]^.etat.x + panel2^.enfants.t[panel2^.enfants.taille-2]^.surface^.w)) 
					and ((event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.y > panel2^.enfants.t[panel2^.enfants.taille-2]^.etat.y)
					and (event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.y < panel2^.enfants.t[panel2^.enfants.taille-2]^.etat.y + panel2^.enfants.t[panel2^.enfants.taille-2]^.surface^.h))) 
					and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
				begin //CLICK SELECT GAUCHE
					panel2^.enfants.t[panel2^.enfants.taille-2]^.valeur := '1';
				end;
				if (((event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.x > panel2^.enfants.t[panel2^.enfants.taille-1]^.etat.x)
					and (event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.x < panel2^.enfants.t[panel2^.enfants.taille-1]^.etat.x + panel2^.enfants.t[panel2^.enfants.taille-1]^.surface^.w)) 
					and ((event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.y > panel2^.enfants.t[panel2^.enfants.taille-1]^.etat.y)
					and (event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.y < panel2^.enfants.t[panel2^.enfants.taille-1]^.etat.y + panel2^.enfants.t[panel2^.enfants.taille-1]^.surface^.h))) 
					and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
				begin //CLICK SELECT DROITE
					panel2^.enfants.t[panel2^.enfants.taille-1]^.valeur := '1';
				end;
				
				//Boutons panel3

				if (((event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x > panel3^.enfants.t[panel3^.enfants.taille-3]^.etat.x)
					and (event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x < panel3^.enfants.t[panel3^.enfants.taille-3]^.etat.x + panel3^.enfants.t[panel3^.enfants.taille-3]^.surface^.w)) 
					and ((event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y > panel3^.enfants.t[panel3^.enfants.taille-3]^.etat.y)
					and (event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y < panel3^.enfants.t[panel3^.enfants.taille-3]^.etat.y + panel3^.enfants.t[panel3^.enfants.taille-3]^.surface^.h))) 
					and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
				begin // CLICK PSEUDO
					panel3^.enfants.t[panel3^.enfants.taille-3]^.valeur := '1';
				end;
				if (((event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x > panel3^.enfants.t[panel3^.enfants.taille-2]^.etat.x)
					and (event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x < panel3^.enfants.t[panel3^.enfants.taille-2]^.etat.x + panel3^.enfants.t[panel3^.enfants.taille-2]^.surface^.w)) 
					and ((event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y > panel3^.enfants.t[panel3^.enfants.taille-2]^.etat.y)
					and (event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y < panel3^.enfants.t[panel3^.enfants.taille-2]^.etat.y + panel3^.enfants.t[panel3^.enfants.taille-2]^.surface^.h))) 
					and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
				begin //CLICK SELECT GAUCHE
					panel3^.enfants.t[panel3^.enfants.taille-2]^.valeur := '1';
				end;
				if (((event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x > panel3^.enfants.t[panel3^.enfants.taille-1]^.etat.x)
					and (event_sdl.motion.x-fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x < panel3^.enfants.t[panel3^.enfants.taille-1]^.etat.x + panel3^.enfants.t[panel3^.enfants.taille-1]^.surface^.w)) 
					and ((event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y > panel3^.enfants.t[panel3^.enfants.taille-1]^.etat.y)
					and (event_sdl.motion.y-fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y < panel3^.enfants.t[panel3^.enfants.taille-1]^.etat.y + panel3^.enfants.t[panel3^.enfants.taille-1]^.surface^.h))) 
					and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
				begin //CLICK SELECT DROITE
					panel3^.enfants.t[panel3^.enfants.taille-1]^.valeur := '1';
					
				end;
			end;
			
			//Gestion saisie pseudo
			SDL_KEYDOWN :
			begin
			
				if event_sdl.key.keysym.sym = 13 then
				begin
					actif := False;
					
					config.circuit.nom := tabCircuit[actuelCircuit];
					config.circuit.chemin:= './circuits/'+tabCircuit[actuelCircuit]+'.png';
					writeln(config.circuit.chemin);
					config.nbTour:= 3;
					config.joueurs.taille := 2;
					GetMem(config.joueurs.t, config.joueurs.taille*SizeOf(T_CONFIG_JOUEUR));
					case actuelSkin of 
						0 : config.joueurs.t[0].chemin := 'voiture.png';
						1 : config.joueurs.t[0].chemin := 'voitures/rouge.png';
						2 : config.joueurs.t[0].chemin := 'voitures/jaune.png';
						3 : config.joueurs.t[0].chemin := 'voitures/bleu.png';
						4 : config.joueurs.t[0].chemin := 'formule1.png';
					end;
					config.joueurs.t[1].chemin := 'voitures/rouge.png';
					config.joueurs.t[1].nom := pseudo2;
					config.joueurs.t[0].nom := pseudo;
					
					jeu_partie(config, fenetre);
				end;
				
				if panel2^.enfants.t[panel2^.enfants.taille-3]^.valeur = '1' then
				begin
					
					event_clavier := SDL_GetKeyState(NIL);
						
					case event_sdl.key.keysym.sym of 
					
						SDLK_LSHIFT : pseudo := pseudo;				
														
						SDLK_BACKSPACE : Delete(pseudo,Length(pseudo),1);
						
						SDLK_q : if event_clavier[SDLK_LSHIFT] = SDL_PRESSED then pseudo := pseudo +'A'
								 else pseudo := pseudo + 'a';
														
						SDLK_a : if event_clavier[SDLK_LSHIFT] = SDL_PRESSED then pseudo := pseudo +'Q'			
								 else pseudo := pseudo + 'q';
								
						SDLK_w : if event_clavier[SDLK_LSHIFT] = SDL_PRESSED then pseudo := pseudo +'Z'
							   	 else pseudo := pseudo + 'z';
																													//A METTRE SI VOUS ETES SUR WINDOWS
						SDLK_z : if event_clavier[SDLK_LSHIFT] = SDL_PRESSED then pseudo := pseudo +'W'
								 else pseudo := pseudo + 'w';
								
						SDLK_SEMICOLON : if event_clavier[SDLK_LSHIFT] = SDL_PRESSED then pseudo := pseudo +'M'	
										 else pseudo := pseudo + 'm';
										 			
					else
					begin
						writeln(event_sdl.key.keysym.sym);
						if event_clavier[SDLK_LSHIFT] = SDL_PRESSED then
							pseudo := pseudo + Chr(event_sdl.key.keysym.sym-32)	
						else if (event_sdl.key.keysym.sym >=256) and (event_sdl.key.keysym.sym <= 265) then
							pseudo := pseudo + Chr(event_sdl.key.keysym.sym - 208)
						else
							pseudo := pseudo + Chr(event_sdl.key.keysym.sym);  						
					end;
					end;
				end;
				
				if panel3^.enfants.t[panel3^.enfants.taille-3]^.valeur = '1' then
				begin
									
					event_clavier := SDL_GetKeyState(NIL);
						
					case event_sdl.key.keysym.sym of 
					
						SDLK_LSHIFT : pseudo2 := pseudo2;				
														
						SDLK_BACKSPACE : Delete(pseudo2,Length(pseudo2),1);
						
						SDLK_q : if event_clavier[SDLK_LSHIFT] = SDL_PRESSED then pseudo2 := pseudo2 +'A'
								 else pseudo2 := pseudo2 + 'a';
														
						SDLK_a : if event_clavier[SDLK_LSHIFT] = SDL_PRESSED then pseudo2 := pseudo2 +'Q'			
								 else pseudo2 := pseudo2 + 'q';
								
						SDLK_w : if event_clavier[SDLK_LSHIFT] = SDL_PRESSED then pseudo2 := pseudo2 +'Z'
							   	 else pseudo2 := pseudo2 + 'z';
																													//A METTRE SI VOUS ETES SUR WINDOWS
						SDLK_z : if event_clavier[SDLK_LSHIFT] = SDL_PRESSED then pseudo := pseudo +'W'
								 else pseudo2 := pseudo2 + 'w';
								
						SDLK_SEMICOLON : if event_clavier[SDLK_LSHIFT] = SDL_PRESSED then pseudo2 := pseudo2 +'M'	
										 else pseudo2 := pseudo2 + 'm';
										 			
					else
					begin
						writeln(event_sdl.key.keysym.sym);
						if event_clavier[SDLK_LSHIFT] = SDL_PRESSED then
							pseudo2 := pseudo2 + Chr(event_sdl.key.keysym.sym-32)	
						else if (event_sdl.key.keysym.sym >=256) and (event_sdl.key.keysym.sym <= 265) then
							pseudo2 := pseudo2 + Chr(event_sdl.key.keysym.sym - 208)
						else
							pseudo2 := pseudo2 + Chr(event_sdl.key.keysym.sym);  						
					end;
					end;
				end;
			end;
			end;
		end;
		
		//Test sélection des enfants de panel1
		
		if  panel1^.enfants.t[4]^.valeur = '1' then
		begin
			panel1^.enfants.t[panel1^.enfants.taille-7]^.valeur := '1 vs 1';
			panel1^.enfants.t[4]^.valeur := '0';
		end;

		if  panel1^.enfants.t[5]^.valeur = '1' then
		begin
			panel1^.enfants.t[panel1^.enfants.taille-7]^.valeur := 'Contre-la-montre';
			panel1^.enfants.t[5]^.valeur := '0';
		end;
		

		if panel1^.enfants.t[panel1^.enfants.taille-7]^.valeur = 'Contre-la-montre' then
		begin
			panel3^.style.display := False;
		end
		else
		begin
			panel3^.style.display := True;
		end;
		
		if  panel1^.enfants.t[6]^.valeur = '1' then
		begin
			if (actuelCircuit-1 >= 0) and (actuelCircuit-1<=2) then
			begin
				actuelCircuit := actuelCircuit-1;
				panel1^.enfants.t[panel1^.enfants.taille-5]^.valeur := tabCircuit[actuelCircuit];
			end;					
			panel1^.enfants.t[6]^.valeur := '0'
		end;
		
		if  panel1^.enfants.t[7]^.valeur = '1' then
		begin
			if (actuelCircuit+1 >= 0) and (actuelCircuit+1<=2) then
			begin
				actuelCircuit := actuelCircuit+1;
				panel1^.enfants.t[panel1^.enfants.taille-5]^.valeur := tabCircuit[actuelCircuit];
			end;
			panel1^.enfants.t[7]^.valeur := '0'
		end;			
		
		//Affichage circuit miniature en fonction du choix
		
		if tabCircuit[actuelCircuit] = 'first' then
		begin
			fenetre.enfants.t[fenetre.enfants.taille-4]^.surface := tabMiniCircuit[0];
		end;
		
		if tabCircuit[actuelCircuit] = 'demo' then
		begin
			fenetre.enfants.t[fenetre.enfants.taille-4]^.surface := tabMiniCircuit[1];
		end;
	
		if tabCircuit[actuelCircuit] = 'Rouen' then
		begin
			fenetre.enfants.t[fenetre.enfants.taille-4]^.surface := tabMiniCircuit[2];
		end;

		//Test sélection des enfants de panel2
		
		if panel2^.enfants.t[3]^.valeur = '1' then 
		begin
			if(SDL_GetTicks() mod 9) = 0 then
			begin					
				txt^.enfants.t[0]^.couleur.r:=0;										
				txt^.enfants.t[0]^.couleur.g:=0;											
				txt^.enfants.t[0]^.couleur.b:=0;
			end 
			else
			begin
				txt^.enfants.t[0]^.couleur.r:=255;										
				txt^.enfants.t[0]^.couleur.g:=255;											
				txt^.enfants.t[0]^.couleur.b:=255;
			end;
			
		champTxt^.enfants.t[0]^.valeur := pseudo;
		end;
		
		
		if panel2^.enfants.t[4]^.valeur = '1' then 
		begin
			if (actuelSkin-1 >= 0) and (actuelSkin-1<=4) then
			begin
				actuelSkin := actuelSkin-1;
		
				panel2^.enfants.t[panel2^.enfants.taille-4]^.surface := tabSkin[actuelSkin];
			end;
		panel2^.enfants.t[4]^.valeur := '0';
		end;
		
		
		if panel2^.enfants.t[5]^.valeur = '1' then 
		begin
			if (actuelSkin+1 >= 0) and (actuelSkin+1<=4) then
			begin
				actuelSkin := actuelSkin+1;
				panel2^.enfants.t[panel2^.enfants.taille-4]^.surface := tabSkin[actuelSkin];
			end;
			panel2^.enfants.t[5]^.valeur := '0'; 
		end;

		//Test sélection des enfants de panel3
		
		if panel3^.enfants.t[3]^.valeur = '1' then 
		begin
			if(SDL_GetTicks() mod 9) = 0 then
			begin					
				txt3^.enfants.t[0]^.couleur.r:=0;										
				txt3^.enfants.t[0]^.couleur.g:=0;											
				txt3^.enfants.t[0]^.couleur.b:=0;
			end 
			else
			begin
				txt3^.enfants.t[0]^.couleur.r:=255;										
				txt3^.enfants.t[0]^.couleur.g:=255;											
				txt3^.enfants.t[0]^.couleur.b:=255;
			end;
			
		champTxt3^.enfants.t[0]^.valeur := pseudo2;
		end;
		
		
		if panel3^.enfants.t[4]^.valeur = '1' then 
		begin
			if (actuelSkin-1 >= 0) and (actuelSkin-1<=2) then
			begin
				actuelSkin := actuelSkin-1;
		
				panel3^.enfants.t[panel3^.enfants.taille-4]^.surface := tabSkin[actuelSkin];
			end;
		panel3^.enfants.t[4]^.valeur := '0';
		end;
		
		
		if panel3^.enfants.t[5]^.valeur = '1' then 
		begin
			if (actuelSkin+1 >= 0) and (actuelSkin+1<=2) then
			begin
				actuelSkin := actuelSkin+1;
				panel3^.enfants.t[panel3^.enfants.taille-4]^.surface := tabSkin[actuelSkin];
			end;
			panel3^.enfants.t[5]^.valeur := '0'; 
		end;
		
		
		frame_afficher(fenetre);		
		SDL_FLip(fenetre.surface);

		
		timer[1] := SDL_GetTicks() - timer[0];
		timer[2] := Round(1000/C_REFRESHRATE)-timer[1];
		if timer[2] < 0 then timer[2]:=0;
		SDL_Delay(timer[2]);
		//writeln('Took ',timer[1], 'ms to render. FPS=', 1000 div (SDL_GetTicks() - timer[0]));

	end;
end;

procedure score(var fenetre: T_UI_ELEMENT);
begin
	
end;

procedure menu(var fenetre: T_UI_ELEMENT);
var	event_sdl : TSDL_Event;
	actif : Boolean;
	config: T_CONFIG; //ATTENTION 123
begin
	fenetre.typeE:=couleur;
	fenetre.couleur.r:=197;
	fenetre.couleur.g:=197;
	fenetre.couleur.b:=197;

	fenetre.enfants.taille := 0;
	
	ajouter_enfant(fenetre.enfants);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := SDL_DisplayFormatAlpha(IMG_Load('menu/background1.png')); 
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;
	
	ajouter_enfant(fenetre.enfants);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 150; 
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 75;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := IMG_Load('menu/logo1.png'); 
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;	
	
	
	ajouter_enfant(fenetre.enfants);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 0;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := IMG_Load('menu/buttons/jouerbutton0.png'); 
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;
	
	ajouter_enfant(fenetre.enfants);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 90;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 650;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface :=IMG_Load('menu/buttons/scoresbutton0.png'); 
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;
	
	ajouter_enfant(fenetre.enfants);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 90; 
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 775;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := IMG_Load('menu/buttons/tutorielbutton0.png');
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;
	
	
	ajouter_enfant(fenetre.enfants);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 90; 
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 900;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := IMG_Load('menu/buttons/quitterbutton0.png'); 
	

	actif := True;
	
	
	while actif do
	begin		
		while SDL_PollEvent(@event_sdl) = 1 do
		begin
			case event_sdl.type_ of
				
				SDL_QUITEV : actif:=False;
				
				SDL_MOUSEMOTION: 
				begin
					writeln( '  X: ', event_sdl.motion.x, '   Y: ', event_sdl.motion.y,
					' dX: ', event_sdl.motion.xrel, '   dY: ', event_sdl.motion.yrel );
							
					
					if isInElement(fenetre.enfants.t[fenetre.enfants.taille-4]^, event_sdl.motion.x, event_sdl.motion.y) then
					begin
						fenetre.enfants.t[fenetre.enfants.taille-4]^.surface := IMG_Load('menu/buttons/jouerbutton2.png');
						fenetre.enfants.t[fenetre.enfants.taille-4]^.etat.x := 65;
						fenetre.enfants.t[fenetre.enfants.taille-4]^.etat.y := 375;
						frame_afficher(fenetre);
						SDL_FLip(fenetre.surface);
					end
					else
					begin
						fenetre.enfants.t[fenetre.enfants.taille-4]^.surface := IMG_Load('menu/buttons/jouerbutton0.png');
						fenetre.enfants.t[fenetre.enfants.taille-4]^.etat.x := 90; 
						fenetre.enfants.t[fenetre.enfants.taille-4]^.etat.y := 375;
					end;			
					
					
					if isInElement(fenetre.enfants.t[fenetre.enfants.taille-3]^, event_sdl.motion.x, event_sdl.motion.y) then
					begin
						fenetre.enfants.t[fenetre.enfants.taille-3]^.surface := IMG_Load('menu/buttons/scoresbutton2.png');
						fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.x := 65;
						fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.y := 500;
						frame_afficher(fenetre);
						SDL_FLip(fenetre.surface);
					
					end
					else
					begin
						fenetre.enfants.t[fenetre.enfants.taille-3]^.surface := IMG_Load('menu/buttons/scoresbutton0.png');
						fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.x := 90; 
						fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.y := 500;
				
					end;			
					
					
					if isInElement(fenetre.enfants.t[fenetre.enfants.taille-2]^, event_sdl.motion.x, event_sdl.motion.y) then
					begin
						fenetre.enfants.t[fenetre.enfants.taille-2]^.surface := IMG_Load('menu/buttons/tutorielbutton2.png');
						fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.x := 65;
						fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.y := 625;
						frame_afficher(fenetre);
						SDL_FLip(fenetre.surface);
					
					end
					else
					begin
						fenetre.enfants.t[fenetre.enfants.taille-2]^.surface := IMG_Load('menu/buttons/tutorielbutton0.png');
						fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.x := 90; 
						fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.y := 625;
				
					end;
					
					
					if isInElement(fenetre.enfants.t[fenetre.enfants.taille-1]^, event_sdl.motion.x, event_sdl.motion.y) then
					begin
						fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := IMG_Load('menu/buttons/quitterbutton2.png');
						fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 65;
						fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 750;
						frame_afficher(fenetre);
						SDL_FLip(fenetre.surface);
					
					end
					else
					begin
						fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := IMG_Load('menu/buttons/quitterbutton0.png');
						fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 90; 
						fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 750;
						
					end;						
				end;
					
					
				SDL_MOUSEBUTTONDOWN :
				begin
					writeln( 'Mouse button pressed : Button index : ', event_sdl.button.button );
							
					if isInElement(fenetre.enfants.t[fenetre.enfants.taille-4]^, event_sdl.motion.x, event_sdl.motion.y)
						and (event_sdl.button.state = SDL_PRESSED)
						and (event_sdl.button.button = 1) then
					begin
						fenetre.enfants.t[fenetre.enfants.taille-4]^.surface := IMG_Load('menu/buttons/jouerbutton1.png');
						frame_afficher(fenetre);
						SDL_FLip(fenetre.surface);
						Sleep(300);
						jeu_menu(fenetre);
						//actif:=False;
					end;
					if isInElement(fenetre.enfants.t[fenetre.enfants.taille-3]^, event_sdl.motion.x, event_sdl.motion.y)
						and (event_sdl.button.state = SDL_PRESSED)
						and (event_sdl.button.button = 1) then
					begin
						fenetre.enfants.t[fenetre.enfants.taille-3]^.surface := IMG_Load('menu/buttons/scoresbutton1.png');
						frame_afficher(fenetre);
						SDL_FLip(fenetre.surface);
						Sleep(300);
						score(fenetre);
						//actif:=False;	
					end;
					if isInElement(fenetre.enfants.t[fenetre.enfants.taille-2]^, event_sdl.motion.x, event_sdl.motion.y)
						and (event_sdl.button.state = SDL_PRESSED)
						and (event_sdl.button.button = 1) then
					begin
						fenetre.enfants.t[fenetre.enfants.taille-2]^.surface := IMG_Load('menu/buttons/tutorielbutton1.png');
						frame_afficher(fenetre);
						SDL_FLip(fenetre.surface);
						Sleep(25);
						//temp Hack
							config.circuit.nom:='Demo';
							config.circuit.chemin:='circuits/first.png';
							config.nbTour:= 3;
							config.joueurs.taille:= 1;
							GetMem(config.joueurs.t, config.joueurs.taille*SizeOf(T_CONFIG_JOUEUR));
							config.joueurs.t[config.joueurs.taille-1].chemin:='voiture2.png';
							config.joueurs.t[config.joueurs.taille-1].nom:='Antoine';
							jeu_partie(config, fenetre);
						//actif:=False;
					end;
					
					if isInElement(fenetre.enfants.t[fenetre.enfants.taille-1]^, event_sdl.motion.x, event_sdl.motion.y)
						and (event_sdl.button.state = SDL_PRESSED)
						and (event_sdl.button.button = 1) then
					begin
						fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := IMG_Load('menu/buttons/quitterbutton1.png');
						frame_afficher(fenetre);
						SDL_FLip(fenetre.surface);
						Sleep(300);
						actif:=False;	
					end;
				end;
			end;
		end;	
		frame_afficher(fenetre);
		SDL_FLip(fenetre.surface);
	end;
end;

function lancement(): T_UI_ELEMENT; //Init SDL, fenetre(nom, surface, taille), TTF
begin
	writeln('|||', C_UI_FENETRE_NOM, '|||');
	writeln('#Lancement...');
	if SDL_Init(SDL_INIT_EVERYTHING) = 0 then
	begin
		TTF_Init();
		lancement.surface := SDL_SetVideoMode(C_UI_FENETRE_WIDTH, C_UI_FENETRE_HEIGHT, 32, SDL_HWSURFACE or SDL_DOUBLEBUF);
		if lancement.surface <> NIL then
		begin
			SDL_WM_SetCaption(C_UI_FENETRE_NOM, NIL);
			lancement.etat.x:=0;
			lancement.etat.y:=0;
			lancement.enfants.t:=NIL;
		end else
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
	SDL_Quit();
end.

