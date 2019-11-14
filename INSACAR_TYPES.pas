unit INSACAR_TYPES;

interface
uses sdl, sdl_ttf;

type

	
	T_PHYSIQUE_TABLEAU = record
		t: ^P_PHYSIQUE_ELEMENT;
		taille: Integer;
	end;
	
	T_PHYSIQUE_ELEMENT = record
		x,y: Real;
		dx,dy,a,da,r,dr: Real;
	end;
	P_PHYSIQUE_ELEMENT = ^T_PHYSIQUE_ELEMENT;
	
	T_UI_TABLEAU = record
		t: ^P_UI_ELEMENT;
		taille: Integer;
	end;
	
	T_UI_ELEMENT = record
		etat: SDL_RECT; {dimension / position}
		surface: PSDL_SURFACE;
		rsurface: PSDL_SURFACE;
		typeE:(null, image, texte, couleur);
		valeur : String;
		couleur: TSDL_Color;
		police: PTTF_Font;
		physique: ^T_PHYSIQUE_ELEMENT;
		enfants: T_UI_TABLEAU;
	end;
	P_UI_ELEMENT = ^T_UI_ELEMENT;
	
	T_GAMEPLAY = record
		temps: record
			debut: Integer;
			fin: Integer;
			last: LongInt;
			dt: Double;
		end;
		config: ^T_CONFIG;
		joueurs : record
			t: ^T_JOUEUR;
			taille: Integer;
		end;
	end;
	
	T_JOUEUR = record
		nom: String;
		voiture: record
			couleur: PSDL_SURFACE;
			physique: ^T_PHYSIQUE_ELEMENT;
			ui: ^T_UI_ELEMENT;
		end;
		temps : record
			debut: Integer;
			secteur: array[1..3] of Integer;
		end;
		nbTour: Integer;
	end;
	
	T_CONFIG = record
		circuit : record
			nom: String;
			chemin: String;
		end;
		nbTour: Integer;
		mode: boolean;
	end;

implementation
begin
end.
