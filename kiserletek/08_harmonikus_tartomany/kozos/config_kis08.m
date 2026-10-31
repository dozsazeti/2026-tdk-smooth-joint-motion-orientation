function cfg = config_kis08()
% CONFIG_KIS08  Kísérlet 08 (harmonikusok száma és tartománya) beállításai.
%   cfg = config_kis08();
%   A fő beállításból indul (kozos\config.m), és csak ezt írja felül:
%     - a harmonikusok száma (H) és a harmonikusonkénti tartomány (bound_h)
%     - a durva rács a kísérlet saját másolatából jön (racs\CAND2.csv vagy
%       racs\CAND2.zip), ha az megvan; ha nincs, a fő futás 01_racs\CAND2.csv-jét
%       használja (a kettő ugyanaz az adat)
%     - minden kimenet a kísérlet saját mappájába kerül, futásonként külön
%       almappába (pl. eredmenyek\H6_a40_25-15-10-5-4-3), így a próbák nem
%       írják felül egymást
%   Minden más (kulcspontok, GA-beállítások, költség, normálás, cella,
%   szerszám) a fő futáséval azonos, hogy csak a harmonikusok hatása látsszon.
%   A közös config.m-et és a fő futás mappáit NEM módosítja.
%
%   ITT ÁLLÍTSD: a "Harmonikusok" blokkot (H, bound_a0, bound_h).

% A kísérlet gyökere és a projekt gyökere a fájl helyéből számolva
% (...\kiserletek\08_harmonikus_tartomany\kozos).
here   = fileparts(mfilename('fullpath'));
root   = fileparts(here);
gyoker = fileparts(fileparts(root));

addpath(fullfile(gyoker, 'kozos'), fullfile(gyoker, 'kozos', 'lib'));
cfg = beallit();                 % config + útvonalak (a fő mappákat csak olvassa)

% A fő futás összesítője (02_ga_durva, H = 2) - csak összevetéshez olvassuk.
cfg.kis.ref_sum = cfg.file.opt_sum;
cfg.kis.ref_ls1 = fullfile(cfg.path.res_ga, sprintf(cfg.file.opt_ls, 1));
cfg.kis.ref_H   = cfg.coarse.harmonics;

%% ===== Harmonikusok (ITT ÁLLÍTSD) =====
% H: a harmonikusok száma. Csatornánként 1 + 2H együttható (a0, a1, b1, ..., aH, bH).
cfg.kis.H        = 3;
% a0 tartománya: ±[fok] állandó eltérés (fő futás: cfg.ga.bound_a0 = 40).
cfg.kis.bound_a0 = 40;
% Harmonikusonkénti tartomány: ±[fok] az a_h ÉS a b_h együtthatóra (h = 1..H).
% Hossza pontosan H legyen. (Fő futás: minden harmonikusra 25.)
cfg.kis.bound_h  = [20 10 6];
% Tapasztalat: a költség nagyon érzékeny a magasabb harmonikusokra, ezért
% nagy tartománynál (pl. H = 6, [25 15 10 5 4 3]) a GA nem mozdul el az
% Alapról. Kis magasabb harmonikus tartománnyal működő példák:
%   H = 3: [25 25 1]                 H = 4: [25 25 1 0.5]
%   H = 6: [25 25 0.5 0.25 0.1 0.05]
% A kulcspontokban mindenhol nulla bázisfüggvények kikapcsolása (true ajánlott).
% Pl. 12 kulcspont (30°) és H = 6 esetén sin(6*th) = 0 minden kulcspontban,
% így a b6 nem hat a költségre; ezt 0-ra rögzítjük (lb = ub = 0).
cfg.kis.halott_ki = true;
% Honnan induljon a GA:
%   'alap'    - mint a fő futás: az 1. egyed az Alap (minden együttható 0),
%               a többi véletlen a teljes tartományban
%   'fo_opt1' - az 1. egyed a fő futás (02_ga_durva, H = 2) opt1-e, a
%               magasabb harmonikusok 0-val; a GA az ehhez képesti eltérést
%               keresi. Az elitizmus miatt az eredmény sosem rosszabb az opt1-nél,
%               így az látszik, hogy a magasabb harmonikusok tudnak-e javítani.
cfg.kis.indulas = 'alap';

assert(numel(cfg.kis.bound_h) == cfg.kis.H, ...
    'A bound_h hossza (%d) nem egyezik H-val (%d).', numel(cfg.kis.bound_h), cfg.kis.H);
cfg.coarse.harmonics = cfg.kis.H;

%% ===== GA (alapból a fő futáséval azonos) =====
% Több paraméterhez nagyobb populáció/generációszám kellhet; ha átírod,
% a fő futással (150 / 300) már nem teljesen azonos a beállítás.
% cfg.ga.pop_size = 300;
% cfg.ga.max_gen  = 500;

%% ===== Kísérlet mappái =====
cfg.kis.root = root;

% A rács saját másolata (a CAND2.zip-ből első futáskor kicsomagolva). Ha a
% kísérletnek nincs saját másolata, a fő futás rácsát használjuk
% (cfg.file.cand_coarse, a beallit már ellenőrizte, hogy megvan).
racs = fullfile(root, 'racs');
sajat = fullfile(racs, 'CAND2.csv');
if ~exist(sajat, 'file') && exist(fullfile(racs, 'CAND2.zip'), 'file')
    fprintf('Kicsomagolás: %s\n', fullfile(racs, 'CAND2.zip'));
    unzip(fullfile(racs, 'CAND2.zip'), racs);
end
if exist(sajat, 'file'), cfg.file.cand_coarse = sajat; end
fprintf('Rács: %s\n', cfg.file.cand_coarse);
assert(exist(cfg.file.cand_coarse, 'file') == 2, 'Nincs meg a rács: %s', cfg.file.cand_coarse);

% Futás neve a beállításokból, pl. H6_a40_25-15-10-5-4-3.
cfg.kis.tag = sprintf('H%d_a%g_%s', cfg.kis.H, cfg.kis.bound_a0, ...
    strjoin(arrayfun(@(x) sprintf('%g', x), cfg.kis.bound_h, 'UniformOutput', false), '-'));
if strcmp(cfg.kis.indulas, 'fo_opt1'), cfg.kis.tag = [cfg.kis.tag '_opt1bol']; end

cfg.path.res    = fullfile(root, 'eredmenyek', cfg.kis.tag);
cfg.path.res_ga = cfg.path.res;
cfg.path.res_el = fullfile(cfg.path.res, '02_elemzes');
cfg.path.abrak  = fullfile(cfg.path.res, 'abrak');
cfg.file.alap    = fullfile(cfg.path.res, 'ALAP_WPR000.csv');
cfg.file.opt_sum = fullfile(cfg.path.res, 'opt_osszesites.csv');

d = {cfg.path.res, cfg.path.abrak};
for i = 1:numel(d)
    if ~exist(d{i}, 'dir'), mkdir(d{i}); end
end
end
