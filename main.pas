program main;

uses sdl;


const
	CoefF=0.05;
type Objet= record
		x,y,w,h: integer;
		dx,dy,ddx,ddy: Real;
	end;
	
var quit: boolean;
	Pscreen: PSDL_Surface;
	Pcarre: PSDL_Surface;
	Dcarre: Objet;
	event: TSDL_Event;
	keys: PUint8;
begin

if SDL_Init(SDL_INIT_EVERYTHING) = -1 then writeln('erreur init');

Pscreen := SDL_SetVideoMode(1280, 720, 32, SDL_HWSURFACE);

if Pscreen = NIL then writeln('erreur setVideoMode');

SDL_WM_SetCaption('INSACAR', NIL);


Dcarre.x:=0;
Dcarre.y:=0;
Dcarre.dx:=0;
Dcarre.dy:=0;
Dcarre.w:=50;
Dcarre.h:=50;
Pcarre := SDL_CreateRGBSurface(SDL_HWSURFACE, Dcarre.w, Dcarre.h, 32, 0, 0, 0, 0);


quit:=True;
while quit do
begin
	
	SDL_PollEvent(@event);
	
	keys := SDL_GetKeyState(NIL);
	if keys[SDLK_UP] = SDL_PRESSED then
		Dcarre.dy:=Dcarre.dy-1;
	if keys[SDLK_DOWN] = SDL_PRESSED then
		Dcarre.dy:=Dcarre.dy+1;
	if keys[SDLK_LEFT] = SDL_PRESSED then
		Dcarre.dx:=Dcarre.dx-1;
	if keys[SDLK_RIGHT] = SDL_PRESSED then
		Dcarre.dx:=Dcarre.dx+1;
	
	{Moteur physique}
	Dcarre.dx:=Dcarre.dx - CoefF*Dcarre.dx;
	Dcarre.dy:=Dcarre.dy - CoefF*Dcarre.dy;
	Dcarre.x:=Round(Dcarre.x + Dcarre.dx);
	Dcarre.y:=Round(Dcarre.y + Dcarre.dy);
	
	SDL_FillRect(Pscreen, NIL, SDL_MapRGB(Pscreen^.format, 19, 200, 209));
	SDL_FillRect(Pcarre, NIL, SDL_MapRGB(Pcarre^.format, 255, 0, 0));
	SDL_BlitSurface(Pcarre, NIL, Pscreen, @Dcarre);

	SDL_Flip(Pscreen);
	SDL_Delay(25);

end;





SDL_FreeSurface(Pcarre);
SDL_Quit();
end.
