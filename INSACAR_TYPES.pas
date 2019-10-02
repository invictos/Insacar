unit INSACAR_TYPES;

interface
uses sdl;

type
	T_PHYSIQUE_TABLEAU = record
		t: ^T_PHYSIQUE_ELEMENT;
		taille: Integer;
	end;
	T_PHYSIQUE_ELEMENT = record
		x,y: Integer;
		dx,dy,a,da,dr: Real;
		nom: String;
	end;
	T_UI_TABLEAU = record
		t: ^T_UI_ELEMENT;
		taille: Integer;
	end;
	T_UI_ELEMENT = record
		etat: SDL_RECT; {dimension / position}
		surface: PSDL_SURFACE;
		physique: ^T_PHYSIQUE_ELEMENT;
		enfants: T_UI_TABLEAU;
	end;

	T_GAMEPLAY_CONFIG = record
		circuit: String;
		chemin: String;
	end;

implementation
begin
end.
