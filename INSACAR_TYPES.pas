{*---------------------------------------------------------------------------------------------
 *  Copyright (c) InsaCar. <antoine.camusat@insa-rouen.fr> <anas.katim@insa-rouen.fr> <aleksi.mouvier@insa-rouen.fr>
 *  Licensed under GNU General Public License. See LICENSE in the project root for license information.
 *--------------------------------------------------------------------------------------------*}

unit INSACAR_TYPES;

interface
uses sdl, sdl_ttf;

type
	T_RENDER_ETAT = record
		rect: TSDL_Rect;
		a: Byte;
	end;
	T_RENDER_STYLE = record
		enabled, display: Boolean;
		a : Byte;
		zoom: Real;
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
		parent: ^T_UI_ELEMENT;
	end;
	P_UI_ELEMENT = ^T_UI_ELEMENT;
	
	T_GAMEPLAY = record
		temps: record
			debut: Integer;
			fin: Integer;
			last: LongInt;
			dt: Double;
		end;
		map: record
			base : PSDL_Surface;
			current : ^PSDL_Surface;
		end;
		zoom: Double;
		hud: record	
            temps : P_UI_ELEMENT;
            global : P_UI_ELEMENT;
            actuelTour : P_UI_ELEMENT;
            nom_premier : P_UI_ELEMENT;
        end;
		config: ^T_CONFIG; //PAR JEU_PARTIE
		joueurs : record
			t: ^T_JOUEUR; //PARTIE
			taille: Integer;
		end;
		actif : boolean;
	end;
	
	T_JOUEUR = record
		voiture: record
			chemin: String;
			surface: PSDL_SURFACE;
			current: ^PSDL_Surface;
			physique: ^T_PHYSIQUE_ELEMENT;
			ui: P_UI_ELEMENT;
		end;
		hud : record 
			vitesse : P_UI_ELEMENT;
			secteur: array[0..3] of P_UI_ELEMENT;
		end;
		temps : record
			secteur: array[0..3] of LongInt;
			tours: array[1..3] of LongInt;
			actuel: ShortInt;
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
	T_SCORE = record
		nom: String;
		temps: LongInt;
	end;
	T_SCORES = array of T_SCORE;
	
implementation
begin
end.
