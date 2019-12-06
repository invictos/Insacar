unit INSACAR_TYPES;

interface
uses sdl, sdl_ttf;

type
	T_RENDER_ETAT = record
		rect: TSDL_Rect;
		a,o : Byte;
	end;
	T_RENDER_STYLE = record
		enabled, display: Boolean;
		a : Byte;
	end;
	
	T_HITBOX_COLOR = record
		data : array of record
			n: shortint;
			c: TSDL_Color;
		end;
		taille: shortInt;
	end;
	
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
		typeE:(null, image, texte, couleur);
		valeur : String;
		couleur: TSDL_COLOR;
		style: T_RENDER_STYLE;
		police: PTTF_Font;
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
		hud: record
			vitesse: ^T_UI_ELEMENT;
			temps_tour: ^T_UI_ELEMENT;
			debug: ^T_UI_ELEMENT;
			debug2: ^T_UI_ELEMENT;
		end;
		map: PSDL_Surface;
		config: ^T_CONFIG; //PAR JEU_PARTIE
		joueurs : record
			t: ^T_JOUEUR; //PARTIE
			taille: Integer;
		end;
	end;
	
	T_JOUEUR = record
		voiture: record
			chemin: String;
			surface: PSDL_SURFACE;
			physique: ^T_PHYSIQUE_ELEMENT;
			ui: ^T_UI_ELEMENT;
		end;
		temps : record
			debut: Integer;
			secteur: array[1..3] of Integer;
		end;
		nbTour: Integer;
		nom: String;
	end;
	
	
	T_CONFIG_JOUEUR = record
		nom: String;
		chemin: String;
	end;
	
	T_CONFIG = record
		joueurs : record
			t: ^T_CONFIG_JOUEUR;
			taille: Integer;
		end;
		circuit : record
			nom: String;
			chemin: String;
		end;
		nbTour: Integer;
	end;
implementation
begin
end.
