program main;

uses sdl, sdl_gfx;

const
	C_REFRESHRATE = 8; {ms}
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR = 0.05;
	C_PHYSIQUE_FROTTEMENT_COEFFICIENT_EAU = 0.1;
	C_PHYSIQUE_VOITURE_VITESSE_AVANT = 1;
	C_PHYSIQUE_VOITURE_VITESSE_ARRIERE = 0.25;
	C_UI_FENETRE_NOM = 'InsaCar Alpha 1.0';
	
type
	T_PHYSIQUE_ELEMENT = record
		dx,dy,ddx,ddy: double;
	end;
	T_UI_ELEMENT = record
		etat: SDL_RECT; {dimension / position}
		surface: PSDL_SURFACE;
		phy: T_PHYSIQUE_ELEMENT;
	end;

var ui_sortie: boolean;
	ui_element_fenetre: T_UI_ELEMENT;
	ui_element_voiture: T_UI_ELEMENT;
	ui_event_event: TSDL_Event;
	ui_event_keys: PUint8;
	i,j,t:integer;
	
begin

if SDL_Init(SDL_INIT_EVERYTHING) = -1 then writeln('erreur init');

ui_element_fenetre.surface := SDL_SetVideoMode(1280, 720, 32, SDL_HWSURFACE or SDL_DOUBLEBUF);

if ui_element_fenetre.surface = NIL then writeln('erreur setVideoMode');

SDL_WM_SetCaption(C_UI_FENETRE_NOM, NIL);


ui_element_voiture.etat.x:=0;
ui_element_voiture.etat.y:=0;
ui_element_voiture.etat.w:=50;
ui_element_voiture.etat.h:=50;
ui_element_voiture.phy.dx:=0;
ui_element_voiture.phy.dy:=0;

ui_element_voiture.surface := SDL_CreateRGBSurface(SDL_HWSURFACE, ui_element_voiture.etat.w, ui_element_voiture.etat.h, 32, 0, 0, 0, 0);


ui_sortie:=True;
while ui_sortie do
begin
	t:=SDL_GetTicks();
	SDL_PollEvent(@ui_event_event);
	if ui_event_event.type_=SDL_QUITEV then ui_sortie:=False;
	
	ui_event_keys := SDL_GetKeyState(NIL);
	if ui_event_keys[SDLK_UP] = SDL_PRESSED then
		ui_element_voiture.phy.dy:=ui_element_voiture.phy.dy-C_PHYSIQUE_VOITURE_VITESSE_AVANT;
	if ui_event_keys[SDLK_DOWN] = SDL_PRESSED then
		ui_element_voiture.phy.dy:=ui_element_voiture.phy.dy+C_PHYSIQUE_VOITURE_VITESSE_AVANT;
	if ui_event_keys[SDLK_LEFT] = SDL_PRESSED then
		ui_element_voiture.phy.dx:=ui_element_voiture.phy.dx-C_PHYSIQUE_VOITURE_VITESSE_AVANT;
	if ui_event_keys[SDLK_RIGHT] = SDL_PRESSED then
		ui_element_voiture.phy.dx:=ui_element_voiture.phy.dx+C_PHYSIQUE_VOITURE_VITESSE_AVANT;
	
	ui_element_voiture.surface := rotozoomSurface(ui_element_voiture.surface, 1.5, 1.0, 1);
	{Moteur physique}
	ui_element_voiture.phy.dx:=ui_element_voiture.phy.dx - C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR*ui_element_voiture.phy.dx;
	ui_element_voiture.phy.dy:=ui_element_voiture.phy.dy - C_PHYSIQUE_FROTTEMENT_COEFFICIENT_AIR*ui_element_voiture.phy.dy;
	ui_element_voiture.etat.x:=Round(ui_element_voiture.etat.x + ui_element_voiture.phy.dx);
	ui_element_voiture.etat.y:=Round(ui_element_voiture.etat.y + ui_element_voiture.phy.dy);
	
	SDL_FillRect(ui_element_fenetre.surface, NIL, SDL_MapRGB(ui_element_fenetre.surface^.format, 19, 200, 209));
	SDL_FillRect(ui_element_voiture.surface, NIL, SDL_MapRGB(ui_element_voiture.surface^.format, 255, 0, 0));
	SDL_BlitSurface(ui_element_voiture.surface, NIL, ui_element_fenetre.surface, @ui_element_voiture.etat);

	SDL_Flip(ui_element_fenetre.surface);
	SDL_Delay(C_REFRESHRATE);
	writeln('Took: ',SDL_GetTicks()-t,'ms');
end;



SDL_FreeSurface(ui_element_voiture.surface);
SDL_Quit();
end.
