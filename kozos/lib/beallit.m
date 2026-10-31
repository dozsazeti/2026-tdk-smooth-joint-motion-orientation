function cfg = beallit()
% BEALLIT  Közös indítás a durva GA lépéseihez (02_ga_durva, g1..g3).
%   cfg = beallit();
%
%   1. betölti a beállításokat (kozos\config.m) és a függvénytárat (kozos\lib),
%   2. létrehozza az eredménymappákat, ha még nincsenek meg,
%   3. ellenőrzi, hogy a durva rács (01_racs\CAND2.csv) elérhető-e.
%   Ha a CAND2.csv nincs meg, de mellette van egy CAND2.zip (pl. mert a nagy
%   fájl tömörítve került a tárolóba), automatikusan kicsomagolja.
here = fileparts(mfilename('fullpath'));      % ...\kozos\lib
addpath(fileparts(here));                     % a config.m helye (kozos)
cfg = config();
addpath(cfg.path.lib);
% Eredménymappák létrehozása.
d = {cfg.path.res, cfg.path.res_ga, cfg.path.res_el, cfg.path.abrak};
for i = 1:numel(d)
    if ~exist(d{i}, 'dir'), mkdir(d{i}); end
end
% A durva rács megléte (szükség esetén kicsomagolás).
[zd, zn] = fileparts(cfg.file.cand_coarse);
zf = fullfile(zd, [zn '.zip']);
if ~exist(cfg.file.cand_coarse, 'file') && exist(zf, 'file')
    fprintf('Kicsomagolás: %s -> %s\n', zf, zd);
    unzip(zf, zd);
end
assert(exist(cfg.file.cand_coarse, 'file') == 2, ...
    'Nincs meg a durva rács: %s  (előbb a 01_racs lépéseit kell lefuttatni)', cfg.file.cand_coarse);
end
