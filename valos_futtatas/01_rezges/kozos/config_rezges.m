function cfg = config_rezges()
% CONFIG_REZGES  A rezgésméréses valós futtatás (súlyozásvizsgálat) beállításai.
%   cfg = config_rezges();
%   A fő beállításból indul (kozos\config.m), és csak ezt írja felül:
%     - a költségfüggvény lambda-súlyai esetenként változnak (cfg.rez.esetek)
%     - minden kimenet ennek a mappának a saját almappáiba kerül
%   Minden más (rács, kulcspontok, harmonikusszám, GA-beállítások, normálás,
%   cella, szerszám, LS-sablon) a fő futáséval azonos, hogy csak a súlyozás
%   hatása látsszon. A vizsgálat az 1. kör (durva GA, opt1) szintjén történik;
%   a 2. kört a futásidő miatt nem futtatjuk.
%   A fő futás mappáit (01_racs, 02_ga_durva, ...) csak olvassa.
%
%   A futtatások a valós roboton, rezgésméréssel történnek, ezért az LS-ekben
%   nincs LOG_ALL (cfg.ls.logger = false), szerkezetük a 00_korpalya ALAP.LS-é.

% A futtatás gyökere és a projekt gyökere a fájl helyéből számolva
% (...\valos_futtatas\01_rezges\kozos).
here   = fileparts(mfilename('fullpath'));
root   = fileparts(here);
gyoker = fileparts(fileparts(root));

addpath(fullfile(gyoker, 'kozos'), fullfile(gyoker, 'kozos', 'lib'));
cfg = beallit();                 % config + útvonalak (a fő rácsot, CAND2.csv-t ellenőrzi)
cfg.ls.logger = false;           % valós futás rezgésméréssel: nincs LOG_ALL

%% Esetek: név (almappa), lambda = [dq/ds  d2q/ds2  d3q/ds3], LS program neve
% Üres lambda = optimalizálás nélküli alapeset (nincs GA, az LS az Alap).
% A program neve legfeljebb 8 karakter; a szám a súlyok tizedei
% (pl. RZ_235 = 0.2 / 0.3 / 0.5).
cfg.rez.esetek = struct( ...
    'nev',    {'alap',    'l235',          'l100',   'l010',   'l001',   'l055'}, ...
    'lambda', {[],        [0.2 0.3 0.5],   [1 0 0],  [0 1 0],  [0 0 1],  [0 0.5 0.5]}, ...
    'prog',   {'RZ_ALAP', 'RZ_235',        'RZ_100', 'RZ_010', 'RZ_001', 'RZ_055'});

% A közös összevetéshez használt súlyozás: minden eset opt1-ét ezzel is
% kiértékeljük, hogy a különböző súlyozású megoldások egy skálán legyenek.
cfg.rez.lambda_ref = [0.2 0.3 0.5];

%% Mappák
cfg.rez.root = root;
cfg.rez.res  = fullfile(root, 'eredmenyek');   % esetenként egy almappa (GA kimenet) + összesítő
cfg.rez.ls   = fullfile(root, 'ls');           % a valós futtatáshoz szánt LS programok
cfg.rez.meres = fullfile(root, 'meres');       % ide kerülnek a rezgésmérés fájljai

d = {cfg.rez.res, cfg.rez.ls, cfg.rez.meres};
for i = 1:numel(d)
    if ~exist(d{i}, 'dir'), mkdir(d{i}); end
end
end
