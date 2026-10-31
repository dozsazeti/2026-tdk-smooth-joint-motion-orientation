% =========================================================================
% VALÓS FUTTATÁS / 01 REZGÉS / 3. lépés: a KAREL-időmérés és a RoboGuide
% profiler összevetése (csak idő szerint)
% =========================================================================
% MIT CSINÁL?
%   A LOG_ALL az időt a $FAST_CLOCK tickekből számolja (1 tick = 2 ms). Ez
%   a szkript azt ellenőrzi, hogy az így kapott időtartam egyezik-e a
%   RoboGuide profiler által mért idővel, ugyanazon a hat programon
%   (ls_karel\RZK_*.LS).
%
%   A NAPLÓZÁSI ABLAK
%   Az RZK programok szerkezete:
%       F[1]=(ON) ; WAIT .10 ; RUN LOG_ALL ; WAIT .20 ; J P[1] ... L P[381]
%       ; WAIT .10 ; F[1]=(OFF) ; WAIT .50
%   A LOG_ALL az indulásakor nullázza az időt, és addig mér, amíg F[1] = ON.
%   A log teljes hossza (az utolsó Time_s) ezért:
%       T_log = WAIT .20 + mozgásidő + WAIT .10 = mozgásidő + 0.30 s
%   A WAIT .10 (a RUN előtt) és a WAIT .50 (a végén) a naplózási ablakon
%   kívül esik. A profiler "delay time" (0.91 s) ennek a négy WAIT-nek az
%   összege (0.9 s) plusz a RUN; ebből tehát 0.30 s benne van a logban,
%   ezért a mozgásidővel való összevetésnél ezt hozzá kell adni.
%
%   ÖSSZEVETÉSEK
%   1. abszolút: T_log  vs  profiler mozgásidő + 0.30 s (futásonként, ms-ban)
%   2. lineáris: T_log = a * T_mozgás + b illesztése a hat futásra. Ha a
%      KAREL-óra skálája helyes, a meredekség a ≈ 1 (a futások közti
%      különbségeket is visszaadja).
%   3. tájékoztató: a log csuklószögeiből kijelölt mozgó szakasz hossza és
%      a log utolsó mintájának pályaszöge. (A CNT100 miatt a vezérlő az
%      F[1]=(OFF)-ot a mozgás vége előtt végrehajtja, ezért a log a 370°-os
%      kifutás vége előtt, kb. 367°-nál áll le; a 0..360°-os kör teljes.)
%
% BEMENET:   eredmenyek\profiler_karel_time.xlsx  (nev, total time, motion
%            time, delay time; a RoboGuide profilerből)
%            ls_karel\log\RZK_*.CSV  (a LOG_ALL kimenete)
% KIMENET:   eredmenyek\profiler_ido\  profiler_ido.csv, p_1_idok.png, p_2_elteres.png
% =========================================================================
clear; clc;
%% 0. ÚTVONALAK
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
cfg = config();

%% 1. BEÁLLÍTÁSOK
f_prof = fullfile(root, 'eredmenyek', 'profiler_karel_time.xlsx');
logdir = fullfile(root, 'ls_karel', 'log');
outdir = fullfile(root, 'eredmenyek', 'profiler_ido');
if ~exist(outdir, 'dir'), mkdir(outdir); end
w_log  = 0.20 + 0.10;   % [s] a naplózási ablakba eső WAIT-ek (RUN után .20, F[1]=OFF előtt .10)
tol    = 1e-3;          % [fok] ennél nagyobb csuklószög-változás két minta közt = mozgás
kozep  = cfg.cella.nullpont(1:2);   % a kör középpontja (a pályaszöghöz)

%% 2. PROFILER-IDŐK (Excel)
% A táblázat a "nev" fejlécű sor alatt kezdődik: nev, total, motion, delay.
C  = readcell(f_prof);
r0 = find(cellfun(@(x) ischar(x) && strcmpi(strtrim(x), 'nev'), C(:, 1)), 1);
assert(~isempty(r0), 'Nincs "nev" fejléc az első oszlopban: %s', f_prof);
P  = C(r0+1:end, 1:4);
P  = P(cellfun(@ischar, P(:, 1)), :);
nev   = strtrim(P(:, 1));
T_tot = cell2mat(P(:, 2));
T_mot = cell2mat(P(:, 3));
T_del = cell2mat(P(:, 4));
n = numel(nev);
fprintf('Profiler: %d futás, delay time: %s s\n', n, mat2str(unique(T_del).'));

%% 3. LOGOK
T_log = nan(n, 1);  dt_med = nan(n, 1);  dt_max = nan(n, 1);
T_mozgo = nan(n, 1); t_indul = nan(n, 1); th_veg = nan(n, 1); v_veg = nan(n, 1);
for k = 1:n
    f = fullfile(logdir, [nev{k} '.CSV']);
    M = dlmread(f, ';', 1, 0);
    t = M(:, 1);  q = M(:, 2:7);  xyz = M(:, 8:10);
    % A log hossza: a LOG_ALL a ciklus előtt nullázza az időt, így az
    % utolsó Time_s maga a naplózási ablak hossza.
    T_log(k)  = t(end);
    dt        = diff(t);
    dt_med(k) = median(dt);
    dt_max(k) = max(dt);
    % Mozgó szakasz a csuklószögekből: az utolsó álló mintától az utolsó
    % változásig (ha a log végén még mozog, ez a log vége).
    d  = max(abs(diff(q, 1, 1)), [], 2);
    im = find(d > tol);
    t_indul(k) = t(im(1));
    T_mozgo(k) = t(im(end) + 1) - t(im(1));
    % A log utolsó mintájának pályaszöge (360 fölött, ha már a kifutásban van)
    % és pályasebessége.
    a = mod(atan2d(xyz(end, 2) - kozep(2), xyz(end, 1) - kozep(1)), 360);
    th_veg(k) = a + 360*(a < 180);
    v_veg(k)  = norm(xyz(end, :) - xyz(end-1, :)) / dt(end);
end

%% 4. ÖSSZEVETÉS
% 1. abszolút: a log hossza és a profiler mozgásideje + a logba eső WAIT-ek.
e_ms  = 1000*(T_log - (T_mot + w_log));
e_pct = 100*(T_log - (T_mot + w_log)) ./ T_mot;
% Összehasonlításul: WAIT-korrekció nélkül (mozgásidő, ill. teljes idő).
e_nyers_mot_pct = 100*(T_log - T_mot) ./ T_mot;
e_nyers_tot_pct = 100*(T_log - T_tot) ./ T_tot;
% 2. lineáris illesztés a hat futásra.
pf = polyfit(T_mot, T_log, 1);
R  = corrcoef(T_mot, T_log);  R = R(1, 2);

T = table(nev, T_tot, T_mot, T_del, T_log, e_ms, e_pct, e_nyers_mot_pct, e_nyers_tot_pct, ...
    T_mozgo, t_indul, th_veg, v_veg, 1000*dt_med, 1000*dt_max, ...
    'VariableNames', {'nev','prof_total_s','prof_mozgas_s','prof_delay_s','log_hossz_s', ...
    'elteres_ms','elteres_pct','nyers_vs_mozgas_pct','nyers_vs_total_pct', ...
    'log_mozgo_s','log_indulas_s','log_veg_szog_deg','log_veg_v_mms','dt_median_ms','dt_max_ms'});
writetable(T, fullfile(outdir, 'profiler_ido.csv'));
disp(T(:, {'nev','prof_mozgas_s','log_hossz_s','elteres_ms','elteres_pct','log_veg_szog_deg'}));
fprintf('Log hossza vs profiler mozgásidő + %.2f s:\n', w_log);
fprintf('  átlagos eltérés %+.1f ms, legnagyobb |eltérés| %.1f ms (%.3f%%)\n', ...
    mean(e_ms), max(abs(e_ms)), max(abs(e_pct)));
fprintf('  mintavételi lépés: medián %.0f ms, legnagyobb %.0f ms\n', 1000*median(dt_med), 1000*max(dt_max));
fprintf('Illesztés: T_log = %.4f * T_mozgás %+.3f s,  R = %.4f\n', pf(1), pf(2), R);
fprintf('WAIT-korrekció nélkül: vs mozgásidő %+.2f%%, vs teljes idő %+.2f%% (átlag)\n', ...
    mean(e_nyers_mot_pct), mean(e_nyers_tot_pct));
fprintf('A log utolsó mintája: %.1f..%.1f° pályaszögnél (a kör 360°-ig teljes).\n', min(th_veg), max(th_veg));

%% 5. ÁBRÁK
% p_1: a log hossza a profiler mozgásidejének függvényében, az elvárt
% T_log = T_mozgás + 0.30 s egyenessel.
fh = figure('Color', 'w', 'Position', [100 100 620 460]);
xx = [min(T_mot) - 0.1, max(T_mot) + 0.1];
plot(xx, xx + w_log, 'k--', 'LineWidth', 1); hold on;
plot(T_mot, T_log, 'o', 'MarkerSize', 7, 'MarkerFaceColor', [0.2 0.4 0.8], 'MarkerEdgeColor', 'none');
text(T_mot, T_log, strcat({'  '}, strrep(nev, '_', '\_')), 'FontSize', 8);
grid on; box on;
xlabel('Profiler mozgásidő [s]'); ylabel('KAREL-log hossza [s]');
legend({sprintf('elvárt: mozgásidő + %.2f s', w_log), 'mért'}, 'Location', 'northwest');
title(sprintf('T_{log} = %.4f \\cdot T_{mozgás} %+.3f s,  R = %.4f', pf(1), pf(2), R));
exportgraphics(fh, fullfile(outdir, 'p_1_idok.png'), 'Resolution', cfg.el.png_dpi);

% p_2: az eltérés futásonként, a mintavételi lépés (±medián dt) sávjával.
fh = figure('Color', 'w', 'Position', [100 100 620 400]);
bar(categorical(nev, nev), e_ms, 'FaceColor', [0.2 0.4 0.8]); hold on;
s = 1000*median(dt_med);
yline(s, 'k:'); yline(-s, 'k:');
grid on; box on;
ylabel('T_{log} - (T_{mozgás} + 0.30 s)  [ms]');
title(sprintf('Eltérés futásonként (pontozott: \\pm egy mintavételi lépés, %.0f ms)', s));
exportgraphics(fh, fullfile(outdir, 'p_2_elteres.png'), 'Resolution', cfg.el.png_dpi);

fprintf('Kimenet: %s\n', outdir);
