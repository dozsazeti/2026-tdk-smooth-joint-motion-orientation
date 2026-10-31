function cfg = config()
% CONFIG  A teljes folyamat közös beállításai (valós cella: UF 0, UT 3).
%   cfg = config();
%
%   Minden szkript (00_korpalya ... 04_roboguide_osszevetes, kiserletek) és
%   minden függvény (kozos\lib) innen olvassa a beállításokat, így egy érték
%   csak egy helyen szerepel. Ha valamit módosítani kell (pl. a kör helyét
%   vagy a szerszámot), azt csak ebben a fájlban kell megtenni.
%
%   ÖSSZETARTOZÓ BEÁLLÍTÁSOK
%   A kör helye (cfg.cella.nullpont), a kör sugara (cfg.geom.radius), a
%   szerszám (cfg.tool.*) és a RoboGuide-ban számolt inverz kinematikai rács
%   (01_racs) összetartozik. A rács csuklószögei ugyanis ezekkel az
%   értékekkel készültek, ezért ha bármelyik megváltozik, a rácsot (CAND.TXT,
%   RoboGuide IK, CAND2.csv) újra le kell generálni, különben a GA egy másik
%   geometriára számolt csuklószögekkel dolgozna.
%
%   AZ ORIENTÁCIÓ JELÖLÉSE
%   A GA a dW, dP, dR eltérést keresi, vagyis a robotnak szóló W, P, R
%   szögek változását a megadott alapálláshoz (cfg.tool.alap_wpr) képest. A
%   rácsfájlokban (CAND.csv, CAND2.csv) és a GA kimeneteiben a W, P, R
%   oszlop ezt az eltérést jelenti. A robotnak szóló W, P, R értéket csak a
%   CAND.TXT-be és az LS programokba írjuk ki, ezt a delta2tcp függvény
%   számolja:  W, P, R = alap_wpr + (dW, dP, dR).
%
%   A kód MATLAB-ban fut (R2019b vagy újabb), külön toolbox nem kell.

% -------------------------------------------------------------------------
%% ===== Mappák =====
% A config.m a kozos mappában van, a projekt gyökere eggyel feljebb. Az
% útvonalakat a fájl helyéből számoljuk, így a teljes mappa bárhová
% másolható, abszolút elérési utat nem kell átírni.
cfg.path.kozos = fileparts(mfilename('fullpath'));            % ...\kozos
cfg.path.root  = fileparts(cfg.path.kozos);                    % a projekt gyökere
cfg.path.lib   = fullfile(cfg.path.kozos, 'lib');
% A lépések mappái (a szám a futtatás sorrendje).
cfg.path.kor        = fullfile(cfg.path.root, '00_korpalya');
cfg.path.racs       = fullfile(cfg.path.root, '01_racs');
cfg.path.racs_be    = fullfile(cfg.path.racs, 'roboguide_be');     % CAND.TXT, CAND.csv
cfg.path.racs_vissza= fullfile(cfg.path.racs, 'roboguide_vissza'); % JOINTS.CSV
cfg.path.ga         = fullfile(cfg.path.root, '02_ga_durva');
cfg.path.k2         = fullfile(cfg.path.root, '03_kor2_finom');
cfg.path.ossz       = fullfile(cfg.path.root, '04_roboguide_osszevetes');
cfg.path.log        = fullfile(cfg.path.ossz, 'roboguide_log');     % a RoboGuide-futások logjai
cfg.path.kis        = fullfile(cfg.path.root, 'kiserletek');

%% ===== A költség normálása =====
% A költségben a hat csukló deriváltjait közös skálára kell hozni, mielőtt
% átlagoljuk őket (részletesen: kozos\lib\koltseg_osztok.m).
%   'korlat' : a csuklók egymáshoz viszonyított súlyát a csuklónként mért
%              sebesség-, gyorsulás- és jerk-korlátok adják (cfg.cost.lim).
%              A dolgozat eredményei ezzel készültek.
%   'alap'   : minden csukló a saját Alap-értékéhez van normálva, a J4 az
%              Alapban közel áll, ezért annak osztója a többi öt csukló
%              átlaga (cfg.cost.j4_weight). Összehasonlításra megtartott
%              változat.
cfg.cost.norm = 'korlat';
% A normálás neve az eredménymappák nevébe is bekerül (eredmenyek_korlat),
% így a két változat eredményei nem írják felül egymást.
if strcmp(cfg.cost.norm, 'korlat'), cfg.cost.sfx = '_korlat'; else, cfg.cost.sfx = ''; end

% A durva GA eredményei (02_ga_durva).
cfg.path.res    = fullfile(cfg.path.ga, ['eredmenyek' cfg.cost.sfx]);
cfg.path.res_ga = fullfile(cfg.path.res, '01_ga');        % g1 kimenete
cfg.path.res_el = fullfile(cfg.path.res, '02_elemzes');   % g3 kimenete
cfg.path.abrak  = fullfile(cfg.path.res, 'abrak');        % g2, g3 ábrái
cfg.path.ls_ga  = fullfile(cfg.path.ga, 'ls');            % g4 LS programjai

%% ===== Fájlok =====
cfg.file.cand_txt    = fullfile(cfg.path.racs_be, 'CAND.TXT');      % a KAREL ik_batch bemenete
cfg.file.cand_csv    = fullfile(cfg.path.racs_be, 'CAND.csv');      % ugyanez + eltérés, szög, ívhossz
cfg.file.joints      = fullfile(cfg.path.racs_vissza, 'JOINTS.CSV'); % a RoboGuide IK kimenete
cfg.file.cand_coarse = fullfile(cfg.path.racs, 'CAND2.csv');        % CAND + JOINTS összefűzve (a GA bemenete)
cfg.file.alap        = fullfile(cfg.path.res_ga, 'ALAP_WPR000.csv'); % az Alap sorai a rácsból
cfg.file.opt_sum     = fullfile(cfg.path.res_ga, 'opt_osszesites.csv');
cfg.file.opt_ls      = 'opt%d_LS_WPR.csv';        % dW, dP, dR fokonként (-10..370°) az LS-hez
cfg.file.opt_key     = 'opt%d_kulcspontok.csv';   % dW, dP, dR + becsült J1..J6 a kulcspontokban
% A RoboGuide-futások logjai (a LOG_ALL kimenete, UD1:K1.CSV átnevezve).
% Ezeket olvassa a 04_roboguide_osszevetes.
cfg.file.log_alap    = fullfile(cfg.path.log, 'alap.CSV');   % 02_ga_durva\ls\ALAP_L.LS futása
cfg.file.log_opt1    = fullfile(cfg.path.log, 'opt1.CSV');   % 02_ga_durva\ls\OPT1_L.LS futása
cfg.file.log_opt2    = fullfile(cfg.path.log, 'opt2.CSV');   % 03_kor2_finom\ls\OPT2_L.LS futása

%% ===== Cella és pálya =====
% NULLPONT: a kör középpontja a robot világ-koordinátarendszerében (UF 0)
% [mm]. A Z a kör síkja, ezen a magasságon halad a szerszámpont (TCP).
cfg.cella.nullpont = [900, -1800, -164];   % [X Y Z]
% A padló Z koordinátája a világ-koordinátarendszerben. Csak az ellenőrző
% kiíráshoz kell (milyen magasan van a TCP és a karima a padló felett).
cfg.cella.padlo_z  = -780;                 % [mm]
% A kör sugara. Az ívhossz s = R * szög (radiánban), ezért a deriváltak
% számolásához is kell.
cfg.geom.radius    = 300;                  % [mm]

%% ===== Szerszám (tool frame) =====
% Pontosan azok az értékek, amelyek a robot vezérlőjén a Tool Frame
% képernyőn szerepelnek (a karimához, vagyis a 6. tengely végéhez képest).
% Másik szerszámnál csak ezt a blokkot kell átírni (és a rácsot újra
% generálni).
cfg.tool.num = 3;                          % a tool frame sorszáma (UT 3 = megfogó)
cfg.tool.xyz = [0, 0, 145];           % a TCP helye a karimához képest [mm]
cfg.tool.wpr = [0, 0, 0];                  % a szerszám elforgatása a karimához képest [fok]
% Alapállás: a robotnak szóló W, P, R, amikor az eltérés (dW, dP, dR) = 0.
% UT 3-mal a 180 / 0 / -90 lefelé néző szerszámot jelent, az ALAP.LS is
% ezzel fut. A rács ekörül fut:  W, P, R = alapállás + (-45..45).
cfg.tool.alap_wpr = [180, 0, -90];         % [fok]

%% ===== LS-sablon =====
% Minden LS program (ALAP, ALAP_L, OPT1_L, OPT2_L) ugyanezzel a sablonnal
% készül, így a futások csak az orientációban térnek el egymástól.
cfg.ls.ang    = (-10:1:370).';             % [fok] pontok 1°-onként; -10..0 ráfutás, 360..370 kifutás
cfg.ls.seb    = 100;                       % [mm/sec] pályasebesség (L mozgás)
cfg.ls.seb_J  = 50;                        % [%] odaállás az első pontra (J mozgás)
cfg.ls.cnt    = 100;                       % CNT érték (folyamatos átmenet a pontok között)
cfg.ls.uf     = 0;                         % user frame (0 = világ)
cfg.ls.ut     = cfg.tool.num;              % tool frame
cfg.ls.config = 'N U T, 0, 0, 0';          % rögzített konfigurációs ág a teljes pályán
cfg.ls.logger = false;                     % true: F[1] / RUN LOG_ALL sorok a mozgás köré (méréshez)

%% ===== Költségfüggvény =====
% Egyetlen definíció, ezt használja a GA és a RoboGuide-futások kiértékelése
% is (kozos\lib\koltseg.m).
% Súlyok az ívhossz szerinti deriváltakra: [dq/ds  d2q/ds2  d3q/ds3].
% A koltseg.m az összegüket 1-re normálja, így csak az arányuk számít.
cfg.cost.lambda     = [0.2 0.3 0.5];
% Csak az 'alap' normálásnál használt beállítások (koltseg_osztok.m).
cfg.cost.j4_weight  = 'atlag';             % 'atlag' | 'padlo'
cfg.cost.j4_index   = 4;                   % a J4 sorszáma a csuklók között
cfg.cost.floor_rel  = 0.05;                % padló: a többi csukló mediánjának 5%-a
% Csuklónkénti korlátok a 'korlat' normáláshoz (J1..J6).
% Forrás: kiserletek\01_gyorsitas_teszt (egycsuklós, 100%-os mozgások a
% RoboGuide-ban). A v a vezérlő $JNTVELLIM értéke, az a és j a mozgásokban
% mért (simított) legnagyobb érték.
cfg.cost.lim.v = [  95   90   95  120  120  190];   % [fok/s]
cfg.cost.lim.a = [ 310  210  340  600  580  800];   % [fok/s^2]
cfg.cost.lim.j = [1630 1560 2750 4120 3810 4964];   % [fok/s^3]

%% ===== Referencia, kapu =====
% Tájékoztató küszöb: a megoldástól legalább ekkora relatív költségcsökkenést
% várunk az Alaphoz képest. Csak a kiírásokban és az ábrákon jelenik meg,
% a GA működését nem befolyásolja.
cfg.ref.gate_rel = -0.25;                   % -25%

%% ===== Durva rács (01_racs) és durva GA (02_ga_durva) =====
cfg.coarse.key_int   = 30;                 % [fok] a kulcspontok távolsága (30 -> 12 kulcspont)
cfg.coarse.range     = 45;                 % ±[fok] a dW, dP, dR rács kiterjedése
cfg.coarse.step      = 3;                  % [fok] rácslépés (31^3 = 29 791 jelölt / kulcspont)
cfg.coarse.n_eval    = 72;                 % kiértékelő pontok a körön (5°-onként)
cfg.coarse.harmonics = 2;                  % harmonikusok száma: 3*(1+2*2) = 15 paraméter

%% ===== Érvényesség (rossz rácspontok) =====
cfg.valid.j5_sing_min = 5;                 % [fok] |J5| < 5 -> csuklószingularitás közeli rácspont
cfg.valid.flip_jump   = 30;                % [fok] ennél nagyobb J4/J6 ugrás szomszédos rácspontok közt = átfordulás
cfg.valid.penalty     = 10;                % büntetés rossz kulcspontonként és rácson kívüli fokonként

%% ===== Fourier-GA (durva kör) =====
cfg.ga.n_starts     = 8;                   % független GA-indítások száma (különböző seed)
cfg.ga.pop_size     = 150;                 % populáció mérete
cfg.ga.max_gen      = 300;                 % generációk legnagyobb száma
cfg.ga.stall_gen    = 50;                  % leállás, ha ennyi generáción át nincs javulás
cfg.ga.elite        = 3;                   % változatlanul továbbvitt legjobb egyedek
cfg.ga.tour_k       = 3;                   % a verseny-szelekció résztvevőinek száma
cfg.ga.p_mut        = 0.15;                % egy paraméter mutációjának valószínűsége
cfg.ga.bound_a0     = 40;                  % ±[fok] korlát a középértékre (a0)
cfg.ga.bound_harm   = 25;                  % ±[fok] korlát a harmonikus amplitúdókra (a_h, b_h)
cfg.ga.n_opt        = 5;                   % legfeljebb ennyi különböző megoldást tartunk meg
cfg.ga.opt_min_dist = 5;                   % [fok] RMS-eltérés, ami alatt két megoldás azonos
cfg.ga.seed         = 1;                   % az első indítás seedje (a többié seed+1, seed+2, ...)

%% ===== 2. kör (finom, 03_kor2_finom) =====
% 24 kulcspont 15°-onként. Minden kulcspontban egy ±range fokos, step
% lépésű eltérés-rács a középgörbe (az 1. kör opt1 megoldása) körül, plusz
% egy Alap jelölt. Range = 10, step = 1 mellett ez 21^3 = 9261 rácsjelölt
% kulcspontonként. A Fourier-GA itt 3 harmonikussal dolgozik, és a
% középgörbe Fourier-együtthatóihoz képesti eltérést keresi.
cfg.k2.root     = cfg.path.k2;
cfg.k2.be       = fullfile(cfg.path.k2, 'roboguide_be');       % CAND.TXT, CAND.csv
cfg.k2.vissza   = fullfile(cfg.path.k2, 'roboguide_vissza');   % JOINTS.CSV
cfg.k2.res      = fullfile(cfg.path.k2, ['eredmenyek' cfg.cost.sfx]);
cfg.k2.abrak    = fullfile(cfg.k2.res, 'abrak');
cfg.k2.ls       = fullfile(cfg.path.k2, 'ls');
cfg.k2.cand_txt = fullfile(cfg.k2.be, 'CAND.TXT');
cfg.k2.cand_csv = fullfile(cfg.k2.be, 'CAND.csv');
cfg.k2.joints   = fullfile(cfg.k2.vissza, 'JOINTS.CSV');
% A középgörbe: az 1. kör összesítőjének opt = 1 sora, a harmonikusszáma
% az 1. köré (cfg.coarse.harmonics).
cfg.k2.kozep_file = fullfile(cfg.path.res_ga, 'opt_osszesites.csv');
cfg.k2.kozep_opt  = 1;
cfg.k2.kozep_H    = cfg.coarse.harmonics;
cfg.k2.key_ang  = (15:15:360).';           % 24 kulcspont [fok]
cfg.k2.range    = 10;                      % ±[fok] a rács kiterjedése a középgörbe körül
cfg.k2.step     = 1;                       % [fok] rácslépés
cfg.k2.n_eval   = 72;                      % kiértékelő pontok a körön (5°-onként)
cfg.k2.H        = 3;                       % harmonikusok a 2. körben: 3*(1+2*3) = 21 paraméter
cfg.k2.szel     = 3.5;                     % [fok] ennél nagyobb kulcsponti eltolásnál a k2 figyelmeztet
% A 2. kör GA-beállításai: az 1. körével azonosak, kivéve az alábbiakat.
cfg.k2.ga              = cfg.ga;
cfg.k2.ga.pop_size     = 200;
cfg.k2.ga.bound_d      = 4;                % ±[fok] korlát minden Fourier-együttható eltérésére
cfg.k2.ga.n_opt        = 5;
cfg.k2.ga.opt_min_dist = 1;                % [fok]

%% ===== Pályamenti elemzés (g3) =====
cfg.el.sector    = 30;                     % [fok] szektorméret a költség felbontásához
cfg.el.opt_abra  = 1;                      % melyik opt-ról készüljenek a részletes ábrák
cfg.el.png_dpi   = 150;                    % az elmentett ábrák felbontása

end
