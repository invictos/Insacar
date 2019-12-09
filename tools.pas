unit tools;

interface
uses sdl, sysutils, INSACAR_TYPES;

function seconde_to_temps(t: LongInt): String;
procedure ajouter_physique(var physique: T_PHYSIQUE_TABLEAU);
procedure ajouter_enfant(var enfants: T_UI_TABLEAU);
function pixel_get(surface: PSDL_Surface; x,y: Integer): TSDL_Color;
function isInElement(element: T_UI_ELEMENT; x, y: Integer): Boolean;
function hitBox(surface: PSDL_Surface; p: SDL_Rect; a: Real; colors: PSDL_Color; t: ShortInt): T_HITBOX_COLOR;
function isSameColor(a: TSDL_Color; b: TSDL_Color): Boolean;

implementation

function seconde_to_temps(t: LongInt): String;
var m,s,ms: Integer;
begin
	m:= t DIV 60000;
	s:= (t MOD 60000) DIV 1000;
	ms:= t MOD 1000;
	seconde_to_temps := concat(intToStr(m), '.', intToStr(s), '.', intToStr(ms));
end;

procedure ajouter_physique(var physique: T_PHYSIQUE_TABLEAU);
var old: ^P_PHYSIQUE_ELEMENT;
	oldExiste: Boolean;
	i: Integer;
begin
	oldExiste := physique.t<>NIL;
	
	if oldExiste then
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
	
	if oldExiste then
		Freemem(old, physique.taille*SizeOf(P_PHYSIQUE_ELEMENT));
	
	physique.taille:=physique.taille+1;
end;

procedure ajouter_enfant(var enfants: T_UI_TABLEAU);
var old: ^P_UI_ELEMENT;
	oldExiste: Boolean;
	i: Integer;
begin
	oldExiste := enfants.t<>NIL;
	
	if oldExiste then
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
	enfants.t[enfants.taille]^.style.a:=255;
	enfants.t[enfants.taille]^.style.enabled:=True;
	enfants.t[enfants.taille]^.style.display:=True;
	enfants.t[enfants.taille]^.enfants.taille:=0;
	enfants.t[enfants.taille]^.enfants.t:=NIL;
	
	if oldExiste then
		Freemem(old, enfants.taille*SizeOf(P_UI_ELEMENT));
	
	enfants.taille:=enfants.taille+1;
end;


function pixel_get(surface: PSDL_Surface; x,y: Integer): TSDL_Color;
var pixels : ^Uint32;
	lock: Boolean;
	inverse: Byte;
begin
	lock:=SDL_MustLock(surface);
	
	if lock then
		SDL_LockSurface(surface);
	
    pixels := surface^.pixels;
    pixel_get := TSDL_Color(pixels[(y * surface^.w )+ x]);
    
    inverse:=pixel_get.r; //Little endian => r / b inversé
    pixel_get.r:=pixel_get.b;
    pixel_get.b:=inverse;
    
    if lock then
		SDL_UnLockSurface(surface);
end;

function hitBoxInList(c: TSDL_Color; colors: PSDL_Color; t: ShortInt): Boolean;
var i: ShortInt;
begin
	i:=0;
	repeat
		hitBoxInList := (colors[i].r=c.r) AND (colors[i].g=c.g) AND (colors[i].b=c.b);
		i:=i+1;
	until (i=t) OR (hitBoxInList=True);
end;

procedure hitBoxAddList(var l: T_HITBOX_COLOR; n: ShortInt; c: TSDL_COLOR);
begin
	setLength(l.data, l.taille+1);
	l.data[l.taille].c:=c;
	l.data[l.taille].n:=n;
	l.taille:=l.taille+1;
end;

function hitBox(surface: PSDL_Surface; p: SDL_Rect; a: Real; colors: PSDL_Color; t: ShortInt): T_HITBOX_COLOR;
var xm, ym, xt, yt: Integer;
	sa,ca: Real;
	i,j,n: ShortInt;
	c : TSDL_Color;
begin
	hitBox.taille:=0;
	n:=1;
	i:=-1;
	a:= -3.141592/180*a; //Deg -> Rad
	sa:=sin(a);
	ca:=cos(a);
	
	xm:=p.x+Round(sa*p.h/2);
	ym:=p.y-Round(ca*p.h/2);
	//writeln('HB',n,'/',xm, '//', ym);
	c:=pixel_get(surface, xm, ym);
	//writeln('HB2/',c.r,',',c.g,',',c.b);
	if hitBoxInList(c, colors, t) then
	begin
		//writeln('g');
		hitBoxAddList(hitBox, n, c);
	end;
	n:=n+1;
	//writeln('HB1F');
	while i<>3 do
	begin
		xt:=xm+i*Round(p.w/2*ca);
		yt:=ym+i*Round(p.w/2*sa);
		//writeln('HB',n,'/',xt, '//', yt);
		c:=pixel_get(surface, xt, yt);
		if hitBoxInList(c, colors, t) then
			hitBoxAddList(hitBox, n, c);
		//writeln('don');
		n:=n+1;
		for j:=1 to 4 do
		begin
			xt:=xt-Round(p.h/4*sa);
			yt:=yt+Round(p.h/4*ca);
			//writeln('HB',n,'/',xt, '//', yt);
			c:=pixel_get(surface, xt, yt);
			if hitBoxInList(c, colors, t) then
				hitBoxAddList(hitBox, n, c);
			n:=n+1;
		end;
		i:=i+2;
	end;
	
	xm:=xm-Round(sa*p.h);
	ym:=ym+Round(ca*p.h);
	//writeln('HB',n,'/',xm, '//', ym);
	c:=pixel_get(surface, xm, ym);
	if hitBoxInList(c, colors, t) then
		hitBoxAddList(hitBox, n, c);
end;

function isInElement(element: T_UI_ELEMENT; x, y: Integer): Boolean;
begin
	isInElement := 	(x > element.etat.x)
				and	(x < (element.etat.x + element.surface^.w))
				and (y > element.etat.y)
				and (y < (element.etat.y + element.surface^.h));
end;

function isSameColor(a,b: TSDL_Color): Boolean;
begin
	isSameColor := (a.r=b.r) AND (a.g=b.g) AND (a.b=b.b);
end;

end.
