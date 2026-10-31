function cfg = config_athelyezett()
% CONFIG_ATHELYEZETT  A rezgésméréses valós futtatás beállításai, áthelyezett körrel.
%   cfg = config_athelyezett();
%
%   A fő beállítás (kozos\config.m) teljes másolata, hogy ebben a mappában
%   minden érték egy helyen látható és átírható legyen. A módszer (rács,
%   kulcspontok, harmonikusszám, GA-beállítások, seedek, normálás, korlátok,
%   szerszám, LS-sablon) a fő futáséval azonos. Eltérés csak ott van, ahol a
%   mérés miatt kell:
%     - a kör középpontja (cfg.cella.nullpont), ezt a méréshez kell átírni
%     - minden útvonal ebbe a mappába mutat (saját rács, saját eredmények)
%     - csak az 1. kör (durva GA) fut, a 2. kör (cfg.k2) és a pályamenti
%       elemzés (cfg.el) beállításai ezért nincsenek benne
%     - a lambda-súlyok esetenként változnak (cfg.rez.esetek)
%   Hogy valóban csak ezek térnek el, az a0_kor_alap kiírja (cfg_elteres.m).
%
%   FONTOS: a kör helye, sugara és a szerszám a RoboGuide-ban számolt
%   rácshoz tartozik. Ha a nullpontot átírod, az a1 -> RoboGuide IK -> a2
%   lépéseket újra le kell futtatni, mielőtt a GA (a3) indul.
%
%   A számoló függvények a fő futás kozos\lib mappájából jönnek (közösek),
%   így a GA, a költség és az LS-írás kódja ugyanaz, mint a fő futásban.

% -------------------------------------------------------------------------
%% ===== Mappák =====
% Ennek a futtatásnak a gyökere (...\valos_futtatas\02_rezges_athelyezett)
% és a projekt gyökere (01_v10) a fájl helyéből számolva.
cfg.path.kozos  = fileparts(mfilename('fullpath'));           % ...\02_rezges_athelyezett\kozos
cfg.path.root   = fileparts(cfg.path.kozos);                  % ...\02_rezges_athelyezett
cfg.path.gyoker = fileparts(fileparts(cfg.path.root));        % ...\01_v10
cfg.path.lib    = fullfile(cfg.path.gyoker, 'kozos', 'lib');  % a közös függvénytár
addpath(cfg.path.lib, fullfile(cfg.path.gyoker, 'kozos'));    % (a kozos\config.m csak az összevetéshez kell)

cfg.path.racs        = fullfile(cfg.path.root, 'racs');
cfg.path.racs_be     = fullfile(cfg.path.racs, 'roboguide_be');      % CAND.TXT, CAND.csv
cfg.path.racs_vissza = fullfile(cfg.path.racs, 'roboguide_vissza');  % JOINTS.CSV
cfg.path.karel       = fullfile(cfg.path.root, 'karel');             % ik_batch.txt

%% ===== A költség normálása =====
% Mint a fő futásban (részletesen: kozos\lib\koltseg_osztok.m).
cfg.cost.norm = 'korlat';
if strcmp(cfg.cost.norm, 'korlat'), cfg.cost.sfx = '_korlat'; else, cfg.cost.sfx = ''; end

%% ===== Fájlok =====
cfg.file.cand_txt    = fullfile(cfg.path.racs_be, 'CAND.TXT');       % a KAREL ik_batch bemenete
cfg.file.cand_csv    = fullfile(cfg.path.racs_be, 'CAND.csv');       % ugyanez + eltérés, szög, ívhossz
cfg.file.joints      = fullfile(cfg.path.racs_vissza, 'JOINTS.CSV'); % a RoboGuide IK kimenete
cfg.file.cand_coarse = fullfile(cfg.path.racs, 'CAND2.csv');         % CAND + JOINTS összefűzve (a GA bemenete)
cfg.file.opt_ls      = 'opt%d_LS_WPR.csv';        % dW, dP, dR fokonként (-10..370°) az LS-hez
cfg.file.opt_key     = 'opt%d_kulcspontok.csv';   % dW, dP, dR + becsült J1..J6 a kulcspontokban

%% ===== Cella és pálya =====
% NULLPONT: a kör középpontja a robot világ-koordinátarendszerében (UF 0)
% [mm]. A Z a kör síkja, ezen a magasságon halad a szerszámpont (TCP).
% >>> A MÉRÉSHEZ EZT KELL ÁTÍRNI <<<  (a fő futásban: [900, -1800, -164])
cfg.cella.nullpont = [900, -1200, 400];   % [X Y Z]
% A padló Z koordinátája a világ-koordinátarendszerben. Csak az ellenőrző
% kiíráshoz kell (milyen magasan van a TCP és a karima a padló felett).
cfg.cella.padlo_z  = -780;                 % [mm]
% A kör sugara. Az ívhossz s = R * szög (radiánban), ezért a deriváltak
% számolásához is kell.
cfg.geom.radius    = 300;                  % [mm]

%% ===== Szerszám (tool frame) =====
% Pontosan azok az értékek, amelyek a robot vezérlőjén a Tool Frame
% képernyőn szerepelnek (a karimához, vagyis a 6. tengely végéhez képest).
cfg.tool.num = 3;                          % a tool frame sorszáma (UT 3 = megfogó)
cfg.tool.xyz = [0, 0, 145];                % a TCP helye a karimához képest [mm]
cfg.tool.wpr = [0, 0, 0];                  % a szerszám elforgatása a karimához képest [fok]
% Alapállás: a robotnak szóló W, P, R, amikor az eltérés (dW, dP, dR) = 0.
cfg.tool.alap_wpr = [180, 0, -90];         % [fok]

%% ===== LS-sablon =====
cfg.ls.ang    = (-10:1:370).';             % [fok] pontok 1°-onként; -10..0 ráfutás, 360..370 kifutás
cfg.ls.seb    = 100;                       % [mm/sec] pályasebesség (L mozgás)
cfg.ls.seb_J  = 50;                        % [%] odaállás az első pontra (J mozgás)
cfg.ls.cnt    = 100;                       % CNT érték
cfg.ls.uf     = 0;                         % user frame (0 = világ)
cfg.ls.ut     = cfg.tool.num;              % tool frame
cfg.ls.config = 'N U T, 0, 0, 0';          % rögzített konfigurációs ág a teljes pályán
cfg.ls.logger = false;                     % valós futás rezgésméréssel: nincs LOG_ALL

%% ===== Költségfüggvény =====
% A fő futás súlyai. A GA-ban esetenként a cfg.rez.esetek lambdája lép a
% helyére, ez az érték csak az alapértelmezés.
cfg.cost.lambda     = [0.2 0.3 0.5];
cfg.cost.j4_weight  = 'atlag';             % csak az 'alap' normálásnál
cfg.cost.j4_index   = 4;
cfg.cost.floor_rel  = 0.05;
% Csuklónkénti korlátok a 'korlat' normáláshoz (J1..J6),
% forrás: kiserletek\01_gyorsitas_teszt.
cfg.cost.lim.v = [  95   90   95  120  120  190];   % [fok/s]
cfg.cost.lim.a = [ 310  210  340  600  580  800];   % [fok/s^2]
cfg.cost.lim.j = [1630 1560 2750 4120 3810 4964];   % [fok/s^3]

%% ===== Referencia, kapu =====
cfg.ref.gate_rel = -0.25;                   % -25% (csak tájékoztató)

%% ===== Durva rács és durva GA =====
cfg.coarse.key_int   = 30;                 % [fok] a kulcspontok távolsága (30 -> 12 kulcspont)
cfg.coarse.range     = 45;                 % ±[fok] a dW, dP, dR rács kiterjedése
cfg.coarse.step      = 3;                  % [fok] rácslépés (31^3 = 29 791 jelölt / kulcspont)
cfg.coarse.n_eval    = 72;                 % kiértékelő pontok a körön (5°-onként)
cfg.coarse.harmonics = 2;                  % harmonikusok száma: 3*(1+2*2) = 15 paraméter

%% ===== Érvényesség (rossz rácspontok) =====
cfg.valid.j5_sing_min = 5;                 % [fok]
cfg.valid.flip_jump   = 30;                % [fok]
cfg.valid.penalty     = 10;

%% ===== Fourier-GA (durva kör) =====
cfg.ga.n_starts     = 8;
cfg.ga.pop_size     = 150;
cfg.ga.max_gen      = 300;
cfg.ga.stall_gen    = 50;
cfg.ga.elite        = 3;
cfg.ga.tour_k       = 3;
cfg.ga.p_mut        = 0.15;
cfg.ga.bound_a0     = 40;                  % ±[fok]
cfg.ga.bound_harm   = 25;                  % ±[fok]
cfg.ga.n_opt        = 5;
cfg.ga.opt_min_dist = 5;                   % [fok]
cfg.ga.seed         = 1;

%% ===== Esetek (lambda-súlyozás) =====
% Név (eredmény-almappa), lambda = [dq/ds  d2q/ds2  d3q/ds3], LS program neve.
% Üres lambda = optimalizálás nélküli alapeset (nincs GA, az LS az Alap).
% A programnév legfeljebb 8 karakter. Az RA_ előtag (Rezgés, Áthelyezett)
% azért más, mint a 01_rezges RZ_ programjai, hogy a vezérlőn ne írják
% felül egymást. Új eset egy újabb oszloppal vehető fel.
cfg.rez.esetek = struct( ...
    'nev',    {'alap',    'l235',          'l100',   'l010',   'l001',   'l055'}, ...
    'lambda', {[],        [0.2 0.3 0.5],   [1 0 0],  [0 1 0],  [0 0 1],  [0 0.5 0.5]}, ...
    'prog',   {'RA_ALAP', 'RA_235',        'RA_100', 'RA_010', 'RA_001', 'RA_055'});
% A közös összevetés súlyozása (minden eset opt1-ét ezzel is kiértékeljük).
cfg.rez.lambda_ref = [0.2 0.3 0.5];

cfg.rez.root  = cfg.path.root;
cfg.rez.res   = fullfile(cfg.path.root, 'eredmenyek');   % esetenként egy almappa + összesítő
cfg.rez.ls    = fullfile(cfg.path.root, 'ls');           % a valós futtatáshoz szánt LS programok
cfg.rez.meres = fullfile(cfg.path.root, 'meres');        % a rezgésmérés fájljai
cfg.file.alap = fullfile(cfg.rez.res, 'ALAP_WPR000.csv'); % az Alap sorai a rácsból

d = {cfg.path.racs, cfg.path.racs_be, cfg.path.racs_vissza, cfg.rez.res, cfg.rez.ls, cfg.rez.meres};
for i = 1:numel(d)
    if ~exist(d{i}, 'dir'), mkdir(d{i}); end
end
end
