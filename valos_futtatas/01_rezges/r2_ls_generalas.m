% =========================================================================
% VALÓS FUTTATÁS / 01 REZGÉS / 2. lépés: LS programok a valós roboton futtatáshoz
% =========================================================================
% MIT CSINÁL?
%   Minden esetre (kozos\config_rezges.m, cfg.rez.esetek) megírja az LS
%   programot az r1_ga_sulyozas opt1 eredményéből (eredmenyek\<eset>\
%   opt1_LS_WPR.csv). Az alapeset az Alap (dW, dP, dR = 0) ugyanazzal a
%   sablonnal. A sablon a fő futásé (kozos\config.m, cfg.ls.*): UF 0 / UT 3,
%   'N U T, 0, 0, 0', J P[1] 50% FINE, majd L 100mm/sec CNT100, -10..370°
%   1°-onként; LOG_ALL nélkül (rezgésmérés).
%
% KIMENET:   ls\RZ_ALAP.LS, RZ_235.LS, RZ_100.LS, RZ_010.LS, RZ_001.LS, RZ_055.LS
%            (+ <PROG>_pontok.csv: X, Y, Z, dW, dP, dR, W, P, R pontonként)
% KÖVETKEZŐ: a programok futtatása a valós roboton (UF 0 / UT 3) rezgésméréssel;
%            a mérési fájlok a meres mappába kerülnek.
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
addpath(fullfile(root, 'kozos'));
cfg = config_rezges();

%% LS programok
E = cfg.rez.esetek;
n = numel(cfg.ls.ang);
hdr = {'ang','X','Y','Z','dW','dP','dR','W','P','R'};
for k = 1:numel(E)
    if isempty(E(k).lambda)
        D = zeros(n, 3);                                 % Alap
    else
        f = fullfile(cfg.rez.res, E(k).nev, sprintf(cfg.file.opt_ls, 1));
        [Wo, hw] = csv_olvas(f);
        assert(isequal(round(Wo(:, strcmpi(hw, 'ang'))), cfg.ls.ang), 'A %s szögei nem -10..370 / 1°.', f);
        D = Wo(:, [find(strcmpi(hw, 'W')) find(strcmpi(hw, 'P')) find(strcmpi(hw, 'R'))]);
        fprintf('%s: dW %.1f..%.1f, dP %.1f..%.1f, dR %.1f..%.1f fok\n', E(k).nev, ...
            min(D(:,1)), max(D(:,1)), min(D(:,2)), max(D(:,2)), min(D(:,3)), max(D(:,3)));
        if any(abs(D(:)) > cfg.coarse.range)
            fprintf('  !! A görbe valahol kilóg a ±%g°-os rácsból, ellenőrizd.\n', cfg.coarse.range);
        end
    end
    [XYZ, WPR] = ls_kor(fullfile(cfg.rez.ls, [E(k).prog '.LS']), E(k).prog, D, cfg);
    csv_iras(fullfile(cfg.rez.ls, [E(k).prog '_pontok.csv']), hdr, [cfg.ls.ang, XYZ, D, WPR], '%.3f');
end

fprintf('\nA programok: %s\n', cfg.rez.ls);
fprintf('Futtatás előtt UF %d / UT %d legyen aktív a vezérlőn.\n', cfg.ls.uf, cfg.ls.ut);
fprintf('Érdemes előbb a RoboGuide-ban végigfuttatni őket (elérhetőség, konfigurációs ág).\n');
