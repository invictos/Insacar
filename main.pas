program demo;


uses sdl, sdl_ttf, sdl_image, sdl_gfx, INSACAR_TYPES, sysutils, strutils;

const
	C_REFRESHRATE = 90; {FPS} // TEST COMMIT
	C_UI_FENETRE_WIDTH = 1600;
	C_UI_FENETRE_HEIGHT = 900;
	//test
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR = 0.2; // kg.s^(-1)
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_EAU = 0.1;
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_TERRE = 2;
	
	C_PHYSIQUE_VOITURE_ACCELERATION_AVANT = 5.6; // m.s^(-2)
	C_PHYSIQUE_VOITURE_ACCELERATION_ARRIERE = 12;// m.s^(-2)
	C_PHYSIQUE_VOITURE_ANGLE = 90; // Deg.s^(-1)
	
	C_UI_FENETRE_NOM = 'InsaCar Alpha 2.0';

procedure frame_afficher_low(var element: T_UI_ELEMENT; var frame: PSDL_Surface; etat: SDL_Rect);
var i : Integer;
		s : ansiString;
begin
	case element.typeE of
		couleur:
		begin
			SDL_SetAlpha(element.surface, SDL_SRCALPHA, element.couleur.unused);
			SDL_FillRect(element.surface, NIL, SDL_MapRGB(element.surface^.format, element.couleur.r, element.couleur.g, element.couleur.b));
		end;
		texte:
		begin
			s:= element.valeur;
			element.surface := TTF_RenderText_Blended(element.police, Pchar(s), element.couleur);
		end;
		image:
		begin
		end;
	end;
	etat.x:=etat.x+element.etat.x;
	etat.y:=etat.y+element.etat.y;
	SDL_BlitSurface(element.surface, NIL, frame, @etat);
	if (element.typeE = texte) AND (element.enfants.taille <> 0) AND (element.surface <> NIL) then
		etat.x:=etat.x + element.surface^.w;
	for i:=0 to element.enfants.taille-1 do
	begin
		frame_afficher_low(element.enfants.t[i]^, frame, etat);
	end;
end;

procedure frame_afficher(var element: T_UI_ELEMENT);
var etat: SDL_Rect;
begin
	etat.x:=0;
	etat.y:=0;
	frame_afficher_low(element,element.surface,etat);
end;

procedure afficher_hud(var fenetre: T_UI_ELEMENT);
begin
end;

procedure afficher_camera(var infoPartie: T_GAMEPLAY; var fenetre: T_UI_ELEMENT);
var i : Integer;
begin
	for i:=0 to infoPartie.joueurs.taille-1 do
	begin
		infoPartie.joueurs.t[i].voiture.ui^.surface := rotozoomSurface(infoPartie.joueurs.t[i].voiture.couleur, infoPartie.joueurs.t[i].voiture.physique^.a, 1, 1);
		SDL_SetAlpha(infoPartie.joueurs.t[i].voiture.ui^.surface, SDL_SRCALPHA , 0);
		SDL_SetColorKey(infoPartie.joueurs.t[i].voiture.ui^.surface, SDL_SRCCOLORKEY or SDL_RLEACCEL, SDL_MapRGB(infoPartie.joueurs.t[i].voiture.ui^.surface^.format, 255, 255, 255));
		
		fenetre.enfants.t[0]^.etat.x := -Round(infoPartie.joueurs.t[i].voiture.physique^.x-C_UI_FENETRE_WIDTH/2);
		fenetre.enfants.t[0]^.etat.y := -Round(infoPartie.joueurs.t[i].voiture.physique^.y-C_UI_FENETRE_HEIGHT/2);
		
		infoPartie.joueurs.t[i].voiture.ui^.etat.x := Round(C_UI_FENETRE_WIDTH/2-infoPartie.joueurs.t[i].voiture.ui^.surface^.w/2);
		infoPartie.joueurs.t[i].voiture.ui^.etat.y := Round(C_UI_FENETRE_HEIGHT/2-infoPartie.joueurs.t[i].voiture.ui^.surface^.h/2);
		
		
	end;
end;

function pixel_get(surface: PSDL_Surface; x,y: Integer): Uint32;
var pixels : ^Uint32;
begin
    //Convert the pixels to 32 bit
    pixels := surface^.pixels;
    //Get the requested pixel
    pixel_get := pixels[(y * surface^.w )+ x];
end;

function pixel_testLine(surface: PSDL_Surface; x1,y1,x2,y2: Integer; c: array of TSDL_Color; t: Integer): Boolean;
var x,y,ax,ay,i,l: Integer;
	pixels : ^Uint32;
	colors: array[0..3] of Byte;
	p: Byte;
	s: ansiString;
begin
	x:=x2-x1;
	y:=y2-y1;
	writeln('testt1');
	l:=Round(sqrt(x*x+y*y));
	ax:= Round(x/l);
	ay:=Round(y/l);
	writeln('testt2');
	x:=x1;
	y:=y1;
	writeln('testt3');
	pixel_testLine:=false;
	pixels := surface^.pixels;
	writeln('testt4');
	repeat
		s:=intToBin(pixels[(y * surface^.w )+ x],32);
		writeln('testtt1');
		writeln(s);
{
		colors[0]:=p[0];
		colors[1]:=p[1];
		colors[2]:=p[2];
}
		writeln('testtt2');
		x:=x+ax;
		y:=y+ay;
		writeln('testtt3');
		for i:=0 to t-1 do
		begin
			if (c[i].r=colors[0]) AND (c[i].g=colors[1]) AND (c[i].b=colors[2]) then
				pixel_testLine:=False;
		end;
		writeln('testtt4');
	until (not pixel_testLine);
end;


function seconde_to_temps(t: LongInt): String;
var m,s,ms: Integer;
begin
	m:= t DIV 60000;
	s:= (t MOD 60000) DIV 1000;
	ms:= t MOD 1000;
	seconde_to_temps := concat(intToStr(m), '.', intToStr(s), '.', intToStr(ms));
end;
procedure course_afficher(var infoPartie: T_GAMEPLAY; var physique: T_PHYSIQUE_TABLEAU; var fenetre: T_UI_ELEMENT);
begin
	afficher_camera(infoPartie, fenetre);
	afficher_hud(fenetre);
end;

procedure course_gameplay(var infoPartie: T_GAMEPLAY; var circuit: PSDL_Surface);
var c: array[0..0] of TSDL_Color;
	x1,x2,y1,y2,xm,ym: Integer;
begin
	infoPartie.hud.vitesse^.valeur:=IntToStr(Round(-infoPartie.joueurs.t[0].voiture.physique^.dr/2.5)); //Normalement /25 mais physique <> S.I.
	infoPartie.hud.temps_tour^.valeur:= seconde_to_temps(infoPartie.temps.last-infoPartie.temps.debut);
	//SDL_LockSurface(circuit);
	//SDL_GetRgb(pixel_get(circuit, Round(infoPartie.joueurs.t[0].voiture.physique^.x),Round(infoPartie.joueurs.t[0].voiture.physique^.y)) , circuit^.format, @infoPartie.hud.vitesse^.couleur.r, @infoPartie.hud.vitesse^.couleur.g, @infoPartie.hud.vitesse^.couleur.b);
	
	c[0].r:=57;
	c[0].g:=181;
	c[0].b:=74;
	if infoPartie.joueurs.t[0].voiture.ui^.surface <> NIL then
	begin
		writeln('test');
		xm:=Round(infoPartie.joueurs.t[0].voiture.physique^.x-sin(3.141592/180*infoPartie.joueurs.t[0].voiture.physique^.a)*infoPartie.joueurs.t[0].voiture.couleur^.h/2);
		ym:=Round(infoPartie.joueurs.t[0].voiture.physique^.y-cos(3.141592/180*infoPartie.joueurs.t[0].voiture.physique^.a)*infoPartie.joueurs.t[0].voiture.couleur^.h/2);
		x1:=Round(xm-cos(3.141592/180*infoPartie.joueurs.t[0].voiture.physique^.a)*infoPartie.joueurs.t[0].voiture.ui^.surface^.w/2);
		y1:=Round(xm-sin(3.141592/180*infoPartie.joueurs.t[0].voiture.physique^.a)*infoPartie.joueurs.t[0].voiture.ui^.surface^.w/2);
		x2:=Round(xm+cos(3.141592/180*infoPartie.joueurs.t[0].voiture.physique^.a)*infoPartie.joueurs.t[0].voiture.ui^.surface^.w/2);
		y2:=Round(xm+sin(3.141592/180*infoPartie.joueurs.t[0].voiture.physique^.a)*infoPartie.joueurs.t[0].voiture.ui^.surface^.w/2);
		writeln('test1');
		SDL_GetRgb(pixel_get(circuit, xm, ym), circuit^.format, @infoPartie.hud.vitesse^.couleur.r, @infoPartie.hud.vitesse^.couleur.g, @infoPartie.hud.vitesse^.couleur.b);
		writeln('test2');
		infoPartie.hud.debug^.etat.x:=Round(xm-(infoPartie.joueurs.t[0].voiture.physique^.x-C_UI_FENETRE_WIDTH/2));
		infoPartie.hud.debug^.etat.y:=Round(ym-(infoPartie.joueurs.t[0].voiture.physique^.y-C_UI_FENETRE_HEIGHT/2));
		writeln('test3');
		writeln(x1,'/',y1,'//',x2,'/',y2);
		writeln(infoPartie.joueurs.t[0].voiture.physique^.a);
		writeln('test4');
		if pixel_testLine(circuit, x1, y1, x2, y2, c, 1) then
		begin
			infoPartie.hud.temps_tour^.couleur.r:=255;
			infoPartie.hud.temps_tour^.couleur.g:=0;
			infoPartie.hud.temps_tour^.couleur.b:=0;
		end else
		begin
			infoPartie.hud.temps_tour^.couleur.r:=255;
			infoPartie.hud.temps_tour^.couleur.g:=255;
			infoPartie.hud.temps_tour^.couleur.b:=255;
		end;
		writeln('test5');
	end;
	//SDL_UnLockSurface(circuit);
end;

procedure frame_physique(var physique: T_PHYSIQUE_TABLEAU; var infoPartie: T_GAMEPLAY);
var i : Integer;
	c : TSDL_Color;
begin
	for i:=0 to physique.taille-1 do
		begin
			SDL_GetRGB(pixel_get(infoPartie.map, Round(physique.t[i]^.x), Round(physique.t[i]^.y)), infoPartie.map^.format, @c.r, @c.g, @c.b);
			writeln(concat(intToStr(c.r),'/',intToStr(c.g),'/',intToStr(c.b)));
			if(c.r=57) AND (c.g=181) AND (c.b=74) then
				physique.t[i]^.dr:=physique.t[i]^.dr - infoPartie.temps.dt*C_PHYSIQUE_FROTTEMENT_COEFFICIENT_TERRE*physique.t[i]^.dr
			else
				physique.t[i]^.dr:=physique.t[i]^.dr - infoPartie.temps.dt*C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR*physique.t[i]^.dr;
			physique.t[i]^.x:=physique.t[i]^.x + infoPartie.temps.dt*sin(3.141592/180*physique.t[i]^.a)*physique.t[i]^.dr;
			physique.t[i]^.y:=physique.t[i]^.y + infoPartie.temps.dt*cos(3.141592/180*physique.t[i]^.a)*physique.t[i]^.dr;
			writeln('Physique:',i,'/',Round(physique.t[i]^.x),'+',Round(physique.t[i]^.y));
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
begin
	course_depart(fenetre);
	actif:=true;
	while actif do
	begin
		infoPartie.temps.dt:=(SDL_GetTicks()-infoPartie.temps.last)/1000;
		//writeln('DT: ',infoPartie.temps.dt);
		infoPartie.temps.last := SDL_GetTicks();
		writeln('1');
		timer[0]:=SDL_GetTicks();
		
		course_user(infoPartie, actif);
		timer[3]:=SDL_GetTicks();
		writeln('2');
		frame_physique(physique, infoPartie);
		timer[4]:=SDL_GetTicks();
		
		writeln('3');
		course_gameplay(infoPartie, fenetre.enfants.t[0]^.surface);
		timer[5]:=SDL_GetTicks();
		
		writeln('4');
		course_afficher(infoPartie, physique, fenetre);
		timer[6]:=SDL_GetTicks();
		writeln('5');
		frame_afficher(fenetre);
		timer[7]:=SDL_GetTicks();
		writeln('6');
		SDL_Flip(fenetre.surface);
		writeln('7');
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
	enfants.t[enfants.taille]^.couleur.unused:=255; //Hack alpha
	enfants.t[enfants.taille]^.physique:=NIL;
	enfants.t[enfants.taille]^.enfants.taille:=0;
	enfants.t[enfants.taille]^.enfants.t:=NIL;
	
	Freemem(old, enfants.taille*SizeOf(T_UI_ELEMENT));
	enfants.taille:=enfants.taille+1;
end;


procedure partie_init(var infoPartie: T_GAMEPLAY; var physique: T_PHYSIQUE_TABLEAU; var fenetre: T_UI_ELEMENT);
var i: Integer;
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
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := SDL_DisplayFormat(IMG_Load(Pchar(infoPartie.config^.circuit.chemin)));
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.w := fenetre.enfants.t[fenetre.enfants.taille-1]^.surface^.w;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.h := fenetre.enfants.t[fenetre.enfants.taille-1]^.surface^.h;
	infoPartie.map := fenetre.enfants.t[fenetre.enfants.taille-1]^.surface;
	
	//Joueurs
	infoPartie.joueurs.taille := infoPartie.config^.joueurs.taille;
	infoPartie.joueurs.t := GetMem(infoPartie.config^.joueurs.taille*SizeOf(T_JOUEUR));
	
	for i:=0 to infoPartie.config^.joueurs.taille do
		infoPartie.joueurs.t[i].config := @infoPartie.config^.joueurs.t[i];

	//Boucle a faire sur joueurs.t
	ajouter_physique(physique);
	ajouter_enfant(fenetre.enfants);
	infoPartie.joueurs.t[0].voiture.physique := @physique.t[physique.taille-1]^;
	infoPartie.joueurs.t[0].voiture.ui := @fenetre.enfants.t[fenetre.enfants.taille-1]^;
	infoPartie.joueurs.t[0].voiture.ui^.typeE := image;
	
	infoPartie.joueurs.t[0].voiture.couleur := IMG_Load(Pchar(infoPartie.joueurs.t[0].config^.skin));

	infoPartie.joueurs.t[0].voiture.physique^.x := 200;
	infoPartie.joueurs.t[0].voiture.physique^.y := 200;

	fenetre.enfants.t[fenetre.enfants.taille-1]^.physique:=@physique.t[physique.taille-1]^; {UTILISER PHYSIQUE DANS UI ? }
	//fin boucle
	
	//HUD Fond
	ajouter_enfant(fenetre.enfants);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := couleur;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.couleur.r:=0;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.couleur.g:=0;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.couleur.b:=0;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.couleur.unused:=128;
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

	//HUD Debug
	ajouter_enfant(fenetre.enfants);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := couleur;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.couleur.b:=255;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.w:=10;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.h:=10;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface:= SDL_CreateRGBSurface(0, fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.w, fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.h, 32, 0,0,0,0);
	infoPartie.hud.debug:=fenetre.enfants.t[fenetre.enfants.taille-1];
	
end;

procedure jeu_partie(var config: T_CONFIG; fenetre: T_UI_ELEMENT);
var physique : T_PHYSIQUE_TABLEAU;
	infoPartie: T_GAMEPLAY;
begin
	infoPartie.config := @config;
	partie_init(infoPartie, physique, fenetre);
	partie_course(infoPartie, physique, fenetre);
end;

function isInElement(element: T_UI_ELEMENT; x, y: Integer): Boolean;
begin
	isInElement := 	(x > element.etat.x)
				and	(x < (element.etat.x + element.surface^.w))
				and (y > element.etat.y)
				and (y < (element.etat.y + element.surface^.h));
end;

procedure jeu_menu(fenetre: T_UI_ELEMENT);
var event_sdl: TSDL_Event;
	panel1, panel2, panel3, txt, champTxt, txt3, champTxt3: P_UI_ELEMENT;
	actuelCircuit, actuelSkin: Integer;
	actif: Boolean;
	pseudo, tempPseudo, pseudo2, tempPseudo2 : String;
	event_clavier : PUInt8;
	tabCircuit : array [0..2] of ansiString;
	tabSkin, tabMiniCircuit : array [0..2] of PSDL_Surface;
	timer: array[0..2] of LongInt;
	config : T_CONFIG;
	
begin
	pseudo := '';
	tempPseudo:= '';
	
	pseudo2 := '';
	tempPseudo2 := '';
	
	actuelCircuit :=1;
	actuelSkin :=1;
	
	tabSkin[0] := IMG_Load('voiture.png');
	tabSkin[1] := IMG_Load('voiture2.png');
	tabSkin[2] := IMG_Load('formule1.png');

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
					config.joueurs.taille := 1;
					config.joueurs.t := GetMem(config.joueurs.taille*SizeOf(T_JOUEUR_CONFIG));
					case actuelSkin of 
						0 : config.joueurs.t[0].skin := 'voiture.png';
						1 : config.joueurs.t[0].skin := 'voiture2.png';
						2 : config.joueurs.t[0].skin := 'formule1.png';
					end;
					
						
					config.joueurs.t[0].nom := pseudo;
			//		config.mode := panel1^.enfants.t[panel1^.enfants.taille-7]^.valeur = 'Contre-la-montre';		
					jeu_partie(config, fenetre);
				end;
				
				if panel2^.enfants.t[panel2^.enfants.taille-3]^.valeur = '1' then
				begin
					tempPseudo := pseudo;
					
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
					tempPseudo2 := pseudo2;
					
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
			panel3^.couleur.unused := 0;
		end
		else
		begin
		
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
			if (actuelSkin-1 >= 0) and (actuelSkin-1<=2) then
			begin
				actuelSkin := actuelSkin-1;
		
				panel2^.enfants.t[panel2^.enfants.taille-4]^.surface := tabSkin[actuelSkin];
			end;
		panel2^.enfants.t[4]^.valeur := '0';
		end;
		
		
		if panel2^.enfants.t[5]^.valeur = '1' then 
		begin
			if (actuelSkin+1 >= 0) and (actuelSkin+1<=2) then
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
	config: T_CONFIG;
begin
	fenetre.typeE:=couleur;
	fenetre.couleur.r:=197;
	fenetre.couleur.g:=197;
	fenetre.couleur.b:=197;

	fenetre.enfants.taille := 0;
	
	ajouter_enfant(fenetre.enfants);
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := IMG_Load('menu/background1.png'); 
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
						config.circuit.chemin:='./circuits/first.png';
						config.nbTour:= 3;
						config.joueurs.taille:= 1;
						config.joueurs.t := GetMem(config.joueurs.taille*SizeOf(T_JOUEUR_CONFIG));
						config.joueurs.t[0].skin:='voiture2.png';
						config.joueurs.t[0].nom:='Antoine';
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
		lancement.surface := SDL_SetVideoMode(C_UI_FENETRE_WIDTH, C_UI_FENETRE_HEIGHT, 32, SDL_RESIZABLE or SDL_HWSURFACE or SDL_DOUBLEBUF);
		if lancement.surface <> NIL then
		begin
			SDL_WM_SetCaption(C_UI_FENETRE_NOM, NIL);
			lancement.etat.x:=0;
			lancement.etat.y:=0;
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

//Pointeurs pour surnom => mieux ?
