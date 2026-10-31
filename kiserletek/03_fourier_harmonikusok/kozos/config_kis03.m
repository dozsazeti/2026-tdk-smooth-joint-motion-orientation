function cfg = config_kis03()
% CONFIG_KIS03  Kísérlet 03 (Fourier-harmonikusok száma) beállításai.
%   cfg = config_kis03();
%   A fő beállításból indul (kozos\config.m), és csak ezt írja felül:
%     - 1. kör: harmonikusszám H = 3   (fő futás: cfg.coarse.harmonics)
%     - 2. kör: harmonikusszám H = 4   (fő futás: cfg.k2.H)
%     - minden kimenet a kísérlet saját mappájába kerül
%   Minden más (rács, kulcspontok, GA, költség, normálás, cella, szerszám,
%   LS-sablon) a fő futáséval azonos, hogy csak a harmonikusszám hatása látsszon.
%   A fő futás mappáit (01_racs, 02_ga_durva, 03_kor2_finom, 04_...) csak olvassa.

% A kísérlet gyökere és a projekt gyökere a fájl helyéből számolva
% (...\kiserletek\03_fourier_harmonikusok\kozos).
here   = fileparts(mfilename('fullpath'));
root   = fileparts(here);
gyoker = fileparts(fileparts(root));

addpath(fullfile(gyoker, 'kozos'), fullfile(gyoker, 'kozos', 'lib'));
cfg = beallit();                 % config + útvonalak (a fő rácsot, CAND2.csv-t ellenőrzi)
cfg.ls.logger = true;            % a kísérleti LS-ekben benne van a LOG_ALL

%% Harmonikusok
cfg.kis.H1 = 3;                  % 1. kör (fő futás: cfg.coarse.harmonics)
cfg.kis.H2 = 4;                  % 2. kör (fő futás: cfg.k2.H)
cfg.coarse.harmonics = cfg.kis.H1;

%% Kísérlet mappái
cfg.kis.root = root;

% 1. kör kimenete (ugyanaz a szerkezet, mint a 02_ga_durva\eredmenyek_korlat)
cfg.path.res    = fullfile(root, 'kor1', 'eredmenyek');
cfg.path.res_ga = fullfile(cfg.path.res, '01_ga');
cfg.path.res_el = fullfile(cfg.path.res, '02_elemzes');
cfg.path.abrak  = fullfile(cfg.path.res, 'abrak');
cfg.file.alap    = fullfile(cfg.path.res_ga, 'ALAP_WPR000.csv');
cfg.file.opt_sum = fullfile(cfg.path.res_ga, 'opt_osszesites.csv');

% 2. kör: a fő cfg.k2, de a kísérlet mappáival és harmonikusaival
k2 = fullfile(root, 'kor2');
cfg.k2.root     = k2;
cfg.k2.be       = fullfile(k2, 'roboguide_be');
cfg.k2.vissza   = fullfile(k2, 'roboguide_vissza');
cfg.k2.res      = fullfile(k2, 'eredmenyek');
cfg.k2.abrak    = fullfile(k2, 'eredmenyek', 'abrak');
cfg.k2.ls       = fullfile(root, 'ls');
cfg.k2.cand_txt = fullfile(cfg.k2.be, 'CAND.TXT');
cfg.k2.cand_csv = fullfile(cfg.k2.be, 'CAND.csv');
cfg.k2.joints   = fullfile(cfg.k2.vissza, 'JOINTS.CSV');
cfg.k2.kozep_file = fullfile(cfg.path.res_ga, 'opt_osszesites.csv');   % a KÍSÉRLET 1. körének opt1-e
cfg.k2.kozep_opt  = 1;
cfg.k2.kozep_H    = cfg.kis.H1;
cfg.k2.H          = cfg.kis.H2;

% LS-ek, logok, összevetés
cfg.kis.ls       = fullfile(root, 'ls');
cfg.kis.logdir   = fullfile(root, 'roboguide_log');
cfg.kis.out      = fullfile(root, 'osszevetes');
cfg.kis.alap_log = cfg.file.log_alap;      % közös Alap (a fő futás alap.CSV-je)

d = {cfg.path.res, cfg.path.res_ga, cfg.path.res_el, cfg.path.abrak, cfg.k2.be, cfg.k2.vissza, ...
     cfg.k2.res, cfg.k2.abrak, cfg.kis.ls, cfg.kis.logdir, cfg.kis.out};
for i = 1:numel(d)
    if ~exist(d{i}, 'dir'), mkdir(d{i}); end
end
end
