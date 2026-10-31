function cfg = config_kis12()
% CONFIG_KIS12  Kísérlet 12 (harmonikus-konvergencia meleg indítással) beállításai.
%   cfg = config_kis12();
%   A fő beállításból indul (kozos\config.m), és csak ezt írja felül:
%     - a vizsgált harmonikusszámok sorozata (H_lista)
%     - a keresési ablak az előző optimum körül (ablak_regi, ablak_uj)
%     - a GA leállási feltétele (a teljes generációszám lefut)
%     - a determinisztikus letapogatás tartománya és lépésköze
%     - minden kimenet a kísérlet saját mappájába kerül
%   Minden más (rács, kulcspontok, költség, normálás, populáció, operátorok)
%   a fő futáséval azonos. A közös config.m-et és a fő futás mappáit NEM módosítja.
%
%   ITT ÁLLÍTSD: a "Harmonikusok", a "GA" és a "Letapogatás" blokkot.

% A kísérlet gyökere és a projekt gyökere a fájl helyéből számolva
% (...\kiserletek\12_harmonikus_konvergencia\kozos).
here   = fileparts(mfilename('fullpath'));
root   = fileparts(here);
gyoker = fileparts(fileparts(root));

addpath(fullfile(gyoker, 'kozos'), fullfile(gyoker, 'kozos', 'lib'));
cfg = beallit();                 % config + útvonalak (a fő mappákat csak olvassa)

% A lánc kiindulása: a fő futás (02_ga_durva) opt1-e, H = cfg.coarse.harmonics (2).
cfg.kis.ref_sum = cfg.file.opt_sum;
cfg.kis.ref_H   = cfg.coarse.harmonics;

%% ===== Harmonikusok (ITT ÁLLÍTSD) =====
% A vizsgált harmonikusszámok növekvő sorrendben. Az első elem a fő futás
% H-ja (2). Ezt is lefuttatjuk ugyanazzal a finomító lépéssel, hogy a
% magasabb H-k javulása ne a régi együtthatók utólagos finomhangolásából
% adódjon, hanem valóban az új harmonikusból.
% 12 kulcspontnál legfeljebb H = 5 értelmes: H = 6-nál a sin(6*th) minden
% kulcspontban 0, a magasabb harmonikusok alacsonyabbakra képeződnek le.
cfg.kis.H_lista = [2 3 4 5];
% Keresési ablak az előző optimum körül, ±[fok]:
%   ablak_regi  a már meglévő együtthatókra (ezek már optimalizáltak,
%               ezért csak kis finomítást engedünk)
%   ablak_uj    az újonnan hozzáadott harmonikus a_H, b_H együtthatójára
cfg.kis.ablak_regi = 1;
cfg.kis.ablak_uj   = 3;
% Az abszolút korlát (a fő futáséval azonos), ezen az ablak sem léphet túl.
cfg.kis.bound_a0 = cfg.ga.bound_a0;      % 40
cfg.kis.bound_h  = cfg.ga.bound_harm;    % 25

%% ===== GA (ITT ÁLLÍTSD) =====
% Egy már optimalizált megoldás körül a javulás lassú és kicsi, ezért a
% "50 generáció javulás nélkül" leállás túl korán megállítaná a keresést
% (az első futásban ez történt: minden indítás az 50. generációban leállt).
% Itt a teljes generációszám lefut.
cfg.ga.stall_gen = cfg.ga.max_gen;

%% ===== Letapogatás (ITT ÁLLÍTSD) =====
% GA nélküli, determinisztikus vizsgálat: az előző lépés (H-1) legjobb
% megoldásán minden más együtthatót rögzítve, egy-egy csatorna új
% harmonikusának (a_H, b_H) síkját rácson végigszámoljuk. Ha a legkisebb
% költség az origóban (a_H = b_H = 0) van, az új harmonikus nem javít.
cfg.kis.scan_tart = 2;      % ±[fok] a_H és b_H tartománya
cfg.kis.scan_lep  = 0.1;    % [fok] lépésköz

%% ===== Kísérlet mappái =====
cfg.kis.root = root;
cfg.kis.tag  = sprintf('H%s_ablak%g-%g', strjoin(arrayfun(@(x) sprintf('%d', x), ...
    cfg.kis.H_lista, 'UniformOutput', false), '-'), cfg.kis.ablak_regi, cfg.kis.ablak_uj);
cfg.path.res   = fullfile(root, 'eredmenyek', cfg.kis.tag);
cfg.path.abrak = fullfile(cfg.path.res, 'abrak');
d = {cfg.path.res, cfg.path.abrak};
for i = 1:numel(d)
    if ~exist(d{i}, 'dir'), mkdir(d{i}); end
end
end
