function R = ga_kor1(cfg, G, Op, Dn, outdir)
% GA_KOR1  Az 1. kör Fourier-GA-ja egy adott beállítással (súlyozással).
%   R = ga_kor1(cfg, G, Op, Dn, outdir)
%   Lépésenként ugyanaz, mint a fő futás 02_ga_durva\g1_ga_durva (3-5. lépés):
%   független indítások, a különböző megoldások kiválogatása, kimenet. Csak a
%   kimeneti mappa és a cfg.cost.lambda változik esetenként.
%   cfg    - a beállítások (a cfg.cost.lambda az adott eset súlyai)
%   G      - a durva rács (cand_beolvas)
%   Op     - a deriváló operátorok (deriv_ops)
%   Dn     - a normáló osztók (koltseg_osztok); a lambdától függetlenek
%   outdir - ide kerül az opt_osszesites.csv, opt<i>_LS_WPR.csv, opt<i>_kulcspontok.csv
%   R      - az opt1 adatai: p (Fourier-együtthatók), Qk (csuklószögek a
%            kulcspontokban), J, c (deriváltrendenkénti rész), nbad, wl (W,P,R
%            az LS pontjaiban), J_alap, c_alap

if ~exist(outdir, 'dir'), mkdir(outdir); end

% Az Alap költsége ezzel a súlyozással (viszonyítási alap).
[J_alap, c_alap] = koltseg(negyzetosszeg(Op, G.alap_q), Dn, cfg);

%% Fourier-GA
H  = cfg.coarse.harmonics;
nb = 1 + 2*H;
np = 3*nb;
ub = repmat([cfg.ga.bound_a0; repmat(cfg.ga.bound_harm, 2*H, 1)], 3, 1);
lb = -ub;
fit = @(P) ga_fitness(P, G, Op, Dn, cfg, H);

best_p = zeros(np, cfg.ga.n_starts);
best_J = zeros(1, cfg.ga.n_starts);
for s = 1:cfg.ga.n_starts
    seed_rng(cfg.ga.seed + s - 1);
    [best_p(:, s), best_J(s)] = ga_run(fit, lb, ub, cfg.ga);
    fprintf('  indítás %d: költség %.4f  (%+.1f%% vs Alap)\n', ...
        s, best_J(s), 100*(best_J(s)/J_alap - 1));
end

%% Különböző megoldások: opt1..optN (mint a g1-ben)
[~, ord] = sort(best_J);
curves = fourier_eval(best_p, Op.th, H);
opt = [];
for s = ord
    uj = true;
    for v = opt
        d = curves(:,:,s) - curves(:,:,v);
        if sqrt(mean(d(:).^2)) < cfg.ga.opt_min_dist, uj = false; break; end
    end
    if uj, opt(end+1) = s; end %#ok<AGROW>
    if numel(opt) >= cfg.ga.n_opt, break; end
end

%% Kimenet (ugyanaz a formátum, mint a 02_ga_durva\eredmenyek_korlat\01_ga)
hdr = {'opt','inditas','koltseg','vs_alap_pct','d1_pct','d2_pct','d3_pct','rossz_kp', ...
       'W_min','W_max','P_min','P_max','R_min','R_max'};
for c = 'WPR', for b = 1:nb, hdr{end+1} = sprintf('%s_c%d', c, b); end, end %#ok<AGROW>
SUM = [0 0 J_alap zeros(1, numel(hdr)-3)];

fprintf('  opt  költség   vs Alap  dq/ds  d2q/ds2 d3q/ds3\n');
for i = 1:numel(opt)
    s = opt(i);
    p = best_p(:, s);
    wk = fourier_eval(p, G.key_ang, H);
    [Qk, badk] = wpr_joints(G, wk);
    [J, c] = koltseg(negyzetosszeg(Op, Qk), Dn, cfg);
    rel = 100*(c(:)'./c_alap(:)' - 1);
    nbad = sum(badk > 0);
    wl = fourier_eval(p, cfg.ls.ang, H);
    mm = [min(wl); max(wl)];
    fprintf('  %d    %.4f   %+6.1f%%  %+6.1f %+6.1f %+6.1f%s\n', i, J, 100*(J/J_alap-1), rel, ...
        repmat(sprintf('  (%d rossz kp.)', nbad), 1, nbad>0));
    SUM(end+1, :) = [i s J 100*(J/J_alap-1) rel nbad mm(:)' p']; %#ok<AGROW>

    csv_iras(fullfile(outdir, sprintf(cfg.file.opt_ls, i)), ...
        {'ang','W','P','R'}, [cfg.ls.ang wl], '%.4f');
    csv_iras(fullfile(outdir, sprintf(cfg.file.opt_key, i)), ...
        {'deg_val','W','P','R','J1','J2','J3','J4','J5','J6','rossz'}, ...
        [G.key_ang wk Qk badk], '%.4f');

    % Az opt1 adatai a hívónak (az esetek összevetéséhez).
    if i == 1
        R = struct('p', p, 'Qk', Qk, 'J', J, 'c', c, 'nbad', nbad, 'wl', wl, ...
                   'J_alap', J_alap, 'c_alap', c_alap);
    end
end
csv_iras(fullfile(outdir, 'opt_osszesites.csv'), hdr, SUM, '%.6g');
end
