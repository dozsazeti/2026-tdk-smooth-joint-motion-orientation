% =========================================================================
% VALÓS FUTTATÁS / 01 REZGÉS / 1. lépés: 1. körös Fourier-GA súlyozásonként
% =========================================================================
% MIT CSINÁL?
%   A fő futás 02_ga_durva\g1_ga_durva lépését futtatja le minden esetre
%   (kozos\config_rezges.m, cfg.rez.esetek), csak a költségfüggvény
%   lambda-súlyai térnek el:
%       alap   optimalizálás nélkül (nincs GA)
%       l235   0.2 / 0.3 / 0.5   (a fő futás súlyai)
%       l100   1 / 0 / 0         (csak dq/ds)
%       l010   0 / 1 / 0         (csak d2q/ds2)
%       l001   0 / 0 / 1         (csak d3q/ds3)
%       l055   0 / 0.5 / 0.5     (d2q/ds2 + d3q/ds3)
%   Minden más (rács, harmonikusszám, GA-beállítások, seedek, normálás) a fő
%   futáséval azonos. Az összevetés az 1. kör (opt1) szintjén történik.
%
%   Mivel a súlyozás miatt az egyes esetek saját költsége nem összemérhető,
%   minden eset opt1-ét a közös 0.2 / 0.3 / 0.5 súlyozással is kiértékeljük,
%   és kiírjuk a deriváltrendenkénti változást is (ez a súlytól független).
%
% BEÁLLÍTÁS: kozos\config_rezges.m
% BEMENET:   a fő futás 01_racs\CAND2.csv rácsa
% KIMENET:   eredmenyek\<eset>\  (opt_osszesites.csv, opt<i>_LS_WPR.csv,
%                                 opt<i>_kulcspontok.csv)
%            eredmenyek\osszesites_esetek.csv  (az esetek opt1-e egymás mellett)
% KÖVETKEZŐ: r2_ls_generalas.m
% FUTÁSIDŐ:  esetenként annyi, mint egy g1 futás (5 GA-eset).
% =========================================================================
clear; clc;
%% 0. ÚTVONALAK
% A projekt gyökere az a mappa, amelyben a kozos\config.m van (innen legfeljebb
% három szintet lépünk felfelé), így a teljes mappa bárhová másolható.
gyoker = '';
try, gyoker = fileparts(matlab.desktop.editor.getActiveFilename); catch, end
jeloltek = {gyoker, pwd};
for c = 1:numel(jeloltek)
    gyoker = jeloltek{c};
    for i = 1:3
        if isempty(gyoker) || isfile(fullfile(gyoker, 'kozos', 'config.m')), break; end
        gyoker = fileparts(gyoker);
    end
    if ~isempty(gyoker) && isfile(fullfile(gyoker, 'kozos', 'config.m')), break; end
end
assert(~isempty(gyoker) && isfile(fullfile(gyoker, 'kozos', 'config.m')), ...
    'Nem található a kozos\config.m. Állítsd a MATLAB aktuális mappáját a szkript mappájára.');
addpath(fullfile(gyoker, 'kozos'), fullfile(gyoker, 'kozos', 'lib'));
root = fullfile(gyoker, 'valos_futtatas', '01_rezges');
addpath(fullfile(root, 'kozos'));
cfg = config_rezges();

%% 1. Beolvasás, deriváló operátorok, normálás (minden esetre közös)
fprintf('Beolvasás: %s\n', cfg.file.cand_coarse);
G = cand_beolvas(cfg.file.cand_coarse, cfg);
fprintf('  %d kulcspont, rács %g..%g / %g°, rossz rácspontok: %.2f%%\n', ...
    G.K, G.grid(1), G.grid(end), G.step, 100*G.bad_frac);
Op = deriv_ops(G.key_ang, cfg.coarse.n_eval, cfg.geom.radius);
S_alap = negyzetosszeg(Op, G.alap_q);
% A normáló osztók nem függenek a lambdától, ezért egyszer számoljuk.
Dn = koltseg_osztok(S_alap, cfg);
csv_iras(fullfile(cfg.rez.res, 'ALAP_WPR000.csv'), G.hdr, G.alap_rows, '%.4f');

% A közös összevetés súlyozása és az Alap költsége vele.
cfg_ref = cfg;
cfg_ref.cost.lambda = cfg.rez.lambda_ref;
J_alap_ref = koltseg(S_alap, Dn, cfg_ref);

%% 2. GA esetenként
E = cfg.rez.esetek;
n = numel(E);
nev = {E.nev}';
l = nan(n, 3); J_sajat_pct = nan(n, 1); J_ref_pct = nan(n, 1);
d_pct = nan(n, 3); nbad = nan(n, 1); mm = nan(n, 6); perc = nan(n, 1);
for k = 1:n
    if isempty(E(k).lambda)
        % Alapeset: nincs GA, minden változás 0.
        l(k, :) = 0; J_sajat_pct(k) = 0; J_ref_pct(k) = 0; d_pct(k, :) = 0; nbad(k) = 0;
        mm(k, :) = 0; perc(k) = 0;
        continue
    end
    c = cfg;
    c.cost.lambda = E(k).lambda;
    l(k, :) = E(k).lambda;
    fprintf('\n=== %s: lambda = %g / %g / %g ===\n', E(k).nev, E(k).lambda);
    t0 = tic;
    R = ga_kor1(c, G, Op, Dn, fullfile(cfg.rez.res, E(k).nev));
    perc(k) = toc(t0)/60;

    J_sajat_pct(k) = 100*(R.J/R.J_alap - 1);
    J_ref_pct(k)   = 100*(koltseg(negyzetosszeg(Op, R.Qk), Dn, cfg_ref)/J_alap_ref - 1);
    d_pct(k, :)    = 100*(R.c(:)'./R.c_alap(:)' - 1);
    nbad(k)        = R.nbad;
    mm(k, :)       = reshape([min(R.wl); max(R.wl)], 1, []);
    fprintf('  opt1: saját költség %+.1f%%, közös (0.2/0.3/0.5) %+.1f%%,  %.1f perc\n', ...
        J_sajat_pct(k), J_ref_pct(k), perc(k));
    if any(abs(R.wl(:)) > cfg.coarse.range)
        fprintf('  !! A görbe valahol kilóg a ±%g°-os rácsból, ellenőrizd.\n', cfg.coarse.range);
    end
end

%% 3. Összesítés
T = table(nev, l(:,1), l(:,2), l(:,3), J_sajat_pct, J_ref_pct, d_pct(:,1), d_pct(:,2), d_pct(:,3), ...
    nbad, mm(:,1), mm(:,2), mm(:,3), mm(:,4), mm(:,5), mm(:,6), perc, ...
    'VariableNames', {'eset','l1','l2','l3','sajat_vs_alap_pct','kozos_vs_alap_pct', ...
    'd1_pct','d2_pct','d3_pct','rossz_kp','W_min','W_max','P_min','P_max','R_min','R_max','perc'});
writetable(T, fullfile(cfg.rez.res, 'osszesites_esetek.csv'));
disp(T(:, {'eset','l1','l2','l3','kozos_vs_alap_pct','d1_pct','d2_pct','d3_pct','rossz_kp'}));
fprintf('Kimenet: %s\n', cfg.rez.res);
