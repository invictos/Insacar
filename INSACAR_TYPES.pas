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
		dx,dy,a,da,r,dr: Real;
	end;
	
	T_UI_TABLEAU = record
		t: ^T_UI_ELEMENT;
		taille: Integer;
	end;
	
	T_UI_ELEMENT = record
		etat: SDL_RECT; {dimension / position}
		surface: PSDL_SURFACE;
		typeE:(image, texte, couleur);
		valeur: String;
		couleur: array[0..2] of Byte;
		physique: ^T_PHYSIQUE_ELEMENT;
		enfants: T_UI_TABLEAU;
	end;

	T_GAMEPLAY = record
		temps: record
			debut: Integer;
			fin: Integer;
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
			couleur: (bleu, rouge);
			physique: ^T_PHYSIQUE_ELEMENT;
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
