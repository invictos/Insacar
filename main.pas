program demo;
uses sdl, sdl_ttf, sdl_image, sdl_gfx, INSACAR_TYPES, dos,sysutils;

const
	C_REFRESHRATE = 90; {FPS}
	C_UI_FENETRE_WIDTH = 1600;
	C_UI_FENETRE_HEIGHT = 900;

	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR = 0.2; // kg.s^(-1)
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_EAU = 0.1;
	//ca marche ?
	C_PHYSIQUE_VOITURE_ACCELERATION_AVANT = 5.6; // m.s^(-2)
	C_PHYSIQUE_VOITURE_ACCELERATION_ARRIERE = 12;// m.s^(-2)
	C_PHYSIQUE_VOITURE_ANGLE = 90; // Deg.s^(-1)

	C_UI_FENETRE_NOM = 'InsaCar Alpha 2.0';

procedure frame_afficher(var element: T_UI_ELEMENT);
var i: Integer;
begin
	case element.typeE of
		couleur:
		begin
			SDL_FillRect(element.surface, NIL, SDL_MapRGB(element.surface^.format, element.couleur.r, element.couleur.g, element.couleur.b));
		end;
		texte:
		begin
			writeln(SDL_GetError());
			element.surface := TTF_RenderText_Solid(element.police, @element.valeur[1], element.couleur);
		end;
		image:
		begin
		end;
	end;
	for i:=0 to element.enfants.taille-1 do
	begin
		frame_afficher(element.enfants.t[i]^);
		if (element.enfants.t[i]^.typeE = image) and (element.enfants.t[i]^.valeur = 'background') then
			SDL_BlitSurface(element.enfants.t[i]^.surface, NIL, element.surface, @element.enfants.t[i]^.etat)
		else
			SDL_BlitSurface(element.enfants.t[i]^.surface, NIL, element.surface, @element.enfants.t[i]^.etat);
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
		{infoPartie.joueurs.t[i].voiture.ui^.surface := rotozoomSurface(infoPartie.joueurs.t[i].voiture.couleur, infoPartie.joueurs.t[i].voiture.physique^.a, 1.0, 1);
		infoPartie.joueurs.t[i].voiture.ui^.etat.x := Round(infoPartie.joueurs.t[i].voiture.physique^.x-infoPartie.joueurs.t[i].voiture.ui^.surface^.w/2);
		infoPartie.joueurs.t[i].voiture.ui^.etat.y := Round(infoPartie.joueurs.t[i].voiture.physique^.y-infoPartie.joueurs.t[i].voiture.ui^.surface^.h/2);
		writeln('UI:',i,'/',infoPartie.joueurs.t[i].voiture.ui^.etat.x,'+',infoPartie.joueurs.t[i].voiture.ui^.etat.y);}

		infoPartie.joueurs.t[i].voiture.ui^.surface := rotozoomSurface(infoPartie.joueurs.t[i].voiture.couleur, infoPartie.joueurs.t[i].voiture.physique^.a, 1.0, 1);
		infoPartie.joueurs.t[i].voiture.ui^.etat.x := Round(C_UI_FENETRE_WIDTH/2-infoPartie.joueurs.t[i].voiture.ui^.surface^.w/2);
		infoPartie.joueurs.t[i].voiture.ui^.etat.y := Round(C_UI_FENETRE_HEIGHT/2-infoPartie.joueurs.t[i].voiture.ui^.surface^.h/2);
		fenetre.enfants.t[0]^.etat.x := Round(-infoPartie.joueurs.t[i].voiture.physique^.x);
		fenetre.enfants.t[0]^.etat.y := Round(-infoPartie.joueurs.t[i].voiture.physique^.y);

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

procedure frame_physique(var physique: T_PHYSIQUE_TABLEAU; var infoPartie: T_GAMEPLAY);
var i : Integer;
begin
	for i:=0 to physique.taille-1 do
		begin
			physique.t[i]^.dr:=physique.t[i]^.dr - infoPartie.temps.dt*C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR*physique.t[i]^.dr;
			physique.t[i]^.x:=physique.t[i]^.x + infoPartie.temps.dt*sin(3.141592/180*physique.t[i]^.a)*physique.t[i]^.dr;
			physique.t[i]^.y:=physique.t[i]^.y + infoPartie.temps.dt*cos(3.141592/180*physique.t[i]^.a)*physique.t[i]^.dr;
			writeln('Physique:',i,'/',physique.t[i]^.x,'+',physique.t[i]^.y);
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
	writeln('DR:',infoPartie.joueurs.t[0].voiture.physique^.dr);
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
		writeln('DT: ',infoPartie.temps.dt);
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

		frame_afficher(fenetre);
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


{
function ajouter_physique(var physique: T_PHYSIQUE_TABLEAU): P_PHYSIQUE_ELEMENT;
var old: ^T_PHYSIQUE_ELEMENT;
	i: Integer;
begin
	old:=physique.t;
	physique.t := GetMem((physique.taille+1)*SizeOf(T_PHYSIQUE_ELEMENT));

	for i:=0 to physique.taille-1 do
		physique.t[i]:=old[i];

	ajouter_physique := @physique.t[physique.taille];

	ajouter_physique^.x := 0;
	ajouter_physique^.y := 0;
	ajouter_physique^.dx := 0;
	ajouter_physique^.dy := 0;
	ajouter_physique^.a := 0;
	ajouter_physique^.da := 0;
	ajouter_physique^.r := 0;
	ajouter_physique^.dr :=0;

	Freemem(old, physique.taille*SizeOf(T_PHYSIQUE_ELEMENT));
	physique.taille:=physique.taille+1;
end;

function ajouter_enfant(var enfants: T_UI_TABLEAU): P_UI_ELEMENT;
var old: ^T_UI_ELEMENT;
	i: Integer;
begin

	old:=enfants.t;
	enfants.t := GetMem((enfants.taille+1)*SizeOf(T_UI_ELEMENT));

	for i:=0 to enfants.taille-1 do
		enfants.t[i]:=old[i];

	ajouter_enfant := @enfants.t[enfants.taille];

	ajouter_enfant^.etat.x := 0;
	ajouter_enfant^.etat.y := 0;
	ajouter_enfant^.etat.w := 0;
	ajouter_enfant^.etat.h := 0;
	ajouter_enfant^.surface := NIL;
	ajouter_enfant^.typeE := null;
	ajouter_enfant^.valeur:='';
	ajouter_enfant^.couleur.r:=0;
	ajouter_enfant^.couleur.g:=0;
	ajouter_enfant^.couleur.b:=0;
	ajouter_enfant^.physique:=NIL;
	ajouter_enfant^.enfants.taille:=0;
	ajouter_enfant^.enfants.t:=NIL;

	Freemem(old, enfants.taille*SizeOf(T_UI_ELEMENT));
	enfants.taille:=enfants.taille+1;
end;
}
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
	{infoPartie.joueurs.t[0].voiture.ui^.enfants.taille := 0;
	ajouter_enfant(infoPartie.joueurs.t[0].voiture.ui^.enfants);
	infoPartie.joueurs.t[0].voiture.ui^.enfants.t[infoPartie.joueurs.t[0].voiture.ui^.enfants.taille-1]^.typeE := texte;
	infoPartie.joueurs.t[0].voiture.ui^.enfants.t[infoPartie.joueurs.t[0].voiture.ui^.enfants.taille-1]^.valeur := 'test'#0;
	infoPartie.joueurs.t[0].voiture.ui^.enfants.t[infoPartie.joueurs.t[0].voiture.ui^.enfants.taille-1]^.police := TTF_OpenFont('arial.ttf',25);
	infoPartie.joueurs.t[0].voiture.ui^.enfants.t[infoPartie.joueurs.t[0].voiture.ui^.enfants.taille-1]^.couleur.r :=0;
	infoPartie.joueurs.t[0].voiture.ui^.enfants.t[infoPartie.joueurs.t[0].voiture.ui^.enfants.taille-1]^.couleur.g :=0;
	infoPartie.joueurs.t[0].voiture.ui^.enfants.t[infoPartie.joueurs.t[0].voiture.ui^.enfants.taille-1]^.couleur.b :=0;}
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
procedure score( fenetre: T_UI_ELEMENT);
var	event_sdl: TSDL_Event;
        fichier : Text;
        i,j,max,k: integer;
	tabreturn : array [0..2] of PSDL_SURFACE;
	actif : Boolean;
        arial,titre : PTTF_Font;
        recup : array [0..2,0..16] of string;
begin

	fenetre.couleur.r:=243;
	fenetre.couleur.g:=243;
	fenetre.couleur.b:=215;

	fenetre.enfants.taille:=0;
        titre := TTF_OpenFont('arial.ttf',50);
        arial := TTF_Openfont('arial.ttf',20);
	tabreturn[1]:= SDL_DisplayFormat(IMG_Load('menu/buttons/tutorielbutton1.png'));
	tabreturn[0]:= SDL_DisplayFormat(IMG_Load('menu/buttons/tutorielbutton0.png'));
	tabreturn[2]:=SDL_DisplayFormat(IMG_Load('menu/buttons/tutorielbutton2.png'));
        Assign(fichier, 'scorereg.txt');
        reset(fichier);

        for k:=1 to 2 do
        begin
	        ajouter_enfant(fenetre.enfants);                                         //tableau des scores
                if k=1 then
	        fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 100
                else
                fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x:=800;

                fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 80 ;
	        fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := SDL_DisplayFormat(IMG_Load('jeu_menu/grey_panel.png'));
                fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;

                 max:=0;


        //interieur des scores tableau

                while (not(Eof(fichier)) and (max<16)) do

                        begin
                        for i:=0 to 2 do
                                begin
                                readln(fichier,recup[i,max]);
                                end;
                                max:= max+1;
                                end;

                for j:=0 to max-1 do
                        begin
                        for i:=0 to 2do
                                begin
                                ajouter_enfant(fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants);
                                fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.t[fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.taille-1]^.typeE:=texte;
                                fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.t[fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.taille-1]^.etat.x:=((i*200)+40);
                                fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.t[fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.taille-1]^.etat.y := ((j*40)+20);
                                fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.t[fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.taille-1]^.police := arial;
                                end;
                                fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.t[fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.taille-3]^.valeur:=recup[0,j]  ;
                                fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.t[fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.taille-2]^.valeur:=recup[1,j] ;
                                fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.t[fenetre.enfants.t[fenetre.enfants.taille-1]^.enfants.taille-1]^.valeur:=recup[2,j];

                        end;



                For i:=0 to 2 do                                                   //titre des colonnes
                        begin
                        ajouter_enfant(fenetre.enfants);

	                fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE:= texte;
	                fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := (fenetre.enfants.t[fenetre.enfants.taille-2-i]^.etat.x + ((i*200)+40));
	                fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y:= (fenetre.enfants.t[fenetre.enfants.taille-2-i]^.etat.y-40);
                        fenetre.enfants.t[fenetre.enfants.taille-1]^.police:= titre;
                        end;
                        fenetre.enfants.t[fenetre.enfants.taille-3]^.valeur :='Pseudo';
                        fenetre.enfants.t[fenetre.enfants.taille-2]^.valeur :='Date';
                        fenetre.enfants.t[fenetre.enfants.taille-1]^.valeur :='Record';

        end;



	ajouter_enfant(fenetre.enfants);           //bouton retour



	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 1300;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 800;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.surface :=tabreturn[0] ;
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;



        close(fichier);

        actif := True;

	while actif do
	begin
		while SDL_PollEvent(@event_sdl) = 1 do
		begin
			case event_sdl.type_ of

			SDL_QUITEV : actif:=False;

			SDL_MOUSEMOTION :
			begin


				if ((event_sdl.motion.x) > fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x) and (event_sdl.motion.x < (fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x + fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.w))
		and (event_sdl.motion.y > (fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y)) and (event_sdl.motion.y < (fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y + fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.h)) then
					begin
						fenetre.enfants.t[fenetre.enfants.taille-1]^.surface :=tabreturn[2];
						fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 1275;
						fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 800;
						frame_afficher(fenetre);
						SDL_FLip(fenetre.surface);
					end
					else
					begin
						fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := tabreturn[0];
						fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x := 1300;
						fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 800;
					end;



			end;
			SDL_MOUSEBUTTONDOWN :
			begin
				writeln( 'Mouse button pressed : Button index : ', event_sdl.button.button );


					if (event_sdl.motion.x > fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x)
                                        and (event_sdl.motion.x < (fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x + fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.w))
					and ((event_sdl.motion.y > fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y)
                                        and (event_sdl.motion.y < fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y + fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.h))
					and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
						begin
								fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := tabreturn[1];
								frame_afficher(fenetre);
								SDL_FLip(fenetre.surface);
								Sleep(300);
								actif:=False;

						end;



			end;

			end;

			frame_afficher(fenetre);
			SDL_FLip(fenetre.surface);
		end;
	end;

end;
procedure menu(var fenetre: T_UI_ELEMENT);
var	event_sdl: TSDL_Event;
	actif : Boolean;

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
	fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y := 0;
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
	fenetre.enfants.t[fenetre.enfants.taille-1]^.typeE := image;
	

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
							
					
					if ((event_sdl.motion.x > fenetre.enfants.t[fenetre.enfants.taille-4]^.etat.x) and (event_sdl.motion.x < fenetre.enfants.t[fenetre.enfants.taille-4]^.etat.x + fenetre.enfants.t[fenetre.enfants.taille-4]^.etat.w))
						and ((event_sdl.motion.y > fenetre.enfants.t[fenetre.enfants.taille-4]^.etat.y) and (event_sdl.motion.y < fenetre.enfants.t[fenetre.enfants.taille-4]^.etat.y + fenetre.enfants.t[fenetre.enfants.taille-4]^.etat.h)) then
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
					
					
					if ((event_sdl.motion.x > fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.x) and (event_sdl.motion.x < fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.x + fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.w))
						and ((event_sdl.motion.y > fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.y) and (event_sdl.motion.y < fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.y + fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.h)) then
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
					
					
					if ((event_sdl.motion.x > fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.x) and (event_sdl.motion.x < fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.x + fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.w))
						and ((event_sdl.motion.y > fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.y) and (event_sdl.motion.y < fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.y + fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.h)) then
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
					
					
					if ((event_sdl.motion.x > fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x) and (event_sdl.motion.x < fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x + fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.w))
						and ((event_sdl.motion.y > fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y) and (event_sdl.motion.y < fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y + fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.h)) then
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
							
					if (((event_sdl.motion.x > fenetre.enfants.t[fenetre.enfants.taille-4]^.etat.x) and (event_sdl.motion.x < fenetre.enfants.t[fenetre.enfants.taille-4]^.etat.x + fenetre.enfants.t[fenetre.enfants.taille-4]^.etat.w))
						and ((event_sdl.motion.y > fenetre.enfants.t[fenetre.enfants.taille-4]^.etat.y) and (event_sdl.motion.y < fenetre.enfants.t[fenetre.enfants.taille-4]^.etat.y + fenetre.enfants.t[fenetre.enfants.taille-4]^.etat.h)))
						and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
						begin
								fenetre.enfants.t[fenetre.enfants.taille-4]^.surface := IMG_Load('menu/buttons/jouerbutton1.png');
								frame_afficher(fenetre);
								SDL_FLip(fenetre.surface);
								Sleep(300);
								jeu_menu(fenetre);
							
						end;
					if (((event_sdl.motion.x > fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.x) and (event_sdl.motion.x < fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.x + fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.w))
						and ((event_sdl.motion.y > fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.y) and (event_sdl.motion.y < fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.y + fenetre.enfants.t[fenetre.enfants.taille-3]^.etat.h)))
						and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
						begin
								fenetre.enfants.t[fenetre.enfants.taille-3]^.surface := IMG_Load('menu/buttons/scoresbutton1.png');
								frame_afficher(fenetre);
								SDL_FLip(fenetre.surface);
								Sleep(300);
								score(fenetre);
								//actif:=False;
						
						end;	
					if (((event_sdl.motion.x > fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.x) and (event_sdl.motion.x < fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.x + fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.w))
						and ((event_sdl.motion.y > fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.y) and (event_sdl.motion.y < fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.y + fenetre.enfants.t[fenetre.enfants.taille-2]^.etat.h)))
						and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
						begin
								fenetre.enfants.t[fenetre.enfants.taille-2]^.surface := IMG_Load('menu/buttons/tutorielbutton1.png');
								frame_afficher(fenetre);
								SDL_FLip(fenetre.surface);
								Sleep(300);
								//tutoriel(fenetre);
									
						end;
					
					if (((event_sdl.motion.x > fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x) and (event_sdl.motion.x < fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.x + fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.w))
						and ((event_sdl.motion.y > fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y) and (event_sdl.motion.y < fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.y + fenetre.enfants.t[fenetre.enfants.taille-1]^.etat.h)))
						and (event_sdl.button.state = SDL_PRESSED) and (event_sdl.button.button = 1) then
						begin
								fenetre.enfants.t[fenetre.enfants.taille-1]^.surface := IMG_Load('menu/buttons/quitterbutton1.png');
								frame_afficher(fenetre);
								SDL_FLip(fenetre.surface);
								Sleep(300);
								actif:=False ;
						end;
				
				end;
			end;
		end;
		
		
		frame_afficher(fenetre);
		SDL_FLip(fenetre.surface);
	end;
	//SDL_Delay(5000);

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
	
	TTF_Quit();
end.
