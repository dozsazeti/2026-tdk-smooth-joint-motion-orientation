function R = ido_ivhossz_vizsgalat(F, Ds, cfg, out, lepes, szektor, kozep)
% IDO_IVHOSSZ_VIZSGALAT  Ívhossz szerinti vs idő szerinti deriválás a mért futásokon.
%
%   Cél: igazolni, hogy a GA-ban (és a Fourier-közelítésben) használt ÍVHOSSZ
%   szerinti deriváltak (dq/ds, d2q/ds2, d3q/ds3) jól közelítik a szakirodalomban
%   mérvadó IDŐ szerinti értékeket (sebesség, gyorsulás, jerk: dq/dt, d2q/dt2, d3q/dt3).
%
%   Elmélet: ha a pályasebesség v = ds/dt állandó, akkor
%       d^k q / dt^k = v^k * d^k q / ds^k,
%   vagyis a két mérték csak egy állandó szorzóban tér el, így a %-os változások
%   és a korrelációk azonosak. Ha v ingadozik, az eltérés ezt méri.
%
%   Vizsgálat (minden futásra, ugyanazon a logon):
%     1. költség mindkét módszerrel, ugyanazzal a képlettel (a ref-hez normálva)
%        -> %-os változás az Alaphoz képest, ívhossz vs idő
%     2. pontonkénti korreláció (Pearson r) csuklónként és deriváltrendenként
%        + a skálázási tényező (idő/ívhossz) összevetése v_atl^k-val
%     3. szektoronkénti %-os változások korrelációja (ívhossz vs idő)
%     4. érzékenység az időlépésre (N = 72, 144, 360, 720)
%
%   R = ido_ivhossz_vizsgalat(F, Ds, cfg, out, lepes, szektor, kozep)
%   F       a futások listája (osszehasonlitas.mlx: nev, log, ...); az 1. a ref (Alap)
%   Ds      az ívhossz szerinti deriváltak (ivhossz_derivalt) futásonként
%   out     kimeneti mappa (CSV + PNG),  lepes  mintavétel a körön [fok]
%   szektor szektorméret [fok],  kozep  a kör középpontja (X, Y) [mm]
%   Kimenet: R.Js, R.Jt (költség ívhossz, ill. idő szerint), R.rsek, R.vatl

% Futások száma és nevei; a minták száma ugyanannyi, mint ívhossz szerint;
% normált lambda; feliratok.
ne = numel(F);
nev = {F.nev};
N = round(360 / lepes);                     % ugyanannyi minta, mint az ívhossz szerint
lam = cfg.cost.lambda / sum(cfg.cost.lambda);
mn  = {'1. derivált', '2. derivált', '3. derivált'};

%% Idő szerinti deriváltak
% IDŐ SZERINTI DERIVÁLTAK minden futásra, az átlagos pályasebesség
% (2*pi*R / a kör ideje) és a logolt v_TCP statisztikája (átlag, szórás, min, max).
for e = 1:ne
    Lg = log_beolvas(F(e).log, kozep);
    Dt(e) = ido_derivalt(Lg, N); %#ok<AGROW>
    vatl(e) = 2*pi*cfg.geom.radius / Dt(e).T; %#ok<AGROW>
    if ~isempty(Lg.v)
        b = Lg.th >= 0 & Lg.th <= 360;
        vlog(e, :) = [mean(Lg.v(b)) std(Lg.v(b)) min(Lg.v(b)) max(Lg.v(b))]; %#ok<AGROW>
    else
        vlog(e, :) = NaN(1, 4); %#ok<AGROW>
    end
    Lgs{e} = Lg; %#ok<AGROW>
end

% Pályasebesség-táblázat a konzolra.
fprintf('\n==================== ÍVHOSSZ vs IDŐ SZERINTI DERIVÁLÁS ====================\n');
fprintf('Pályasebesség a körön (programozott: %g mm/s):\n', cfg.ls.seb);
fprintf('  futás   kör ideje   v_atl = 2*pi*R/T   v_TCP (log): átlag  szórás   min    max  [mm/s]\n');
for e = 1:ne
    fprintf('  %-5s   %7.1f s   %8.2f mm/s        %8.2f %7.2f %6.2f %6.2f\n', nev{e}, Dt(e).T, vatl(e), vlog(e,:));
end

%% 1. Költség mindkét módszerrel
% 1) KÖLTSÉG MINDKÉT MÓDSZERREL: négyzetösszegek ívhossz (Ss) és idő (St)
% szerint, mindkettő a saját ref-jéhez normálva, ugyanazzal a koltseg.m-mel.
Ss = zeros(3,6,ne);  St = zeros(3,6,ne);
for e = 1:ne
    for k = 1:3
        Ss(k,:,e) = sum(Ds(e).d{k}.^2, 1) * Ds(e).ds;
        St(k,:,e) = sum(Dt(e).d{k}.^2, 1) * Dt(e).ds;
    end
end
Dns = koltseg_osztok(Ss(:,:,1), cfg);  [Js, cs] = koltseg(Ss, Dns, cfg);
Dnt = koltseg_osztok(St(:,:,1), cfg);  [Jt, ct] = koltseg(St, Dnt, cfg);

% A %-os változások a ref-hez képest mindkét módszerrel, és a különbségük
% (%-pontban). Ha kicsi, az ívhossz szerinti költség jól helyettesíti az időst.
fprintf('\n1) Költség, változás a ref-hez képest (ugyanaz a képlet, %d minta a körön):\n', N);
fprintf('  futás   ívhossz: össz   d1      d2      d3   |  idő: össz    d1      d2      d3   | eltérés (össz)\n');
T1 = [];
for e = 2:ne
    a = 100*(Js(e)/Js(1)-1);  b = 100*(Jt(e)/Jt(1)-1);
    ra = 100*(cs(:,e)./cs(:,1)-1);  rb = 100*(ct(:,e)./ct(:,1)-1);
    fprintf('  %-5s   %+7.1f%%  %+6.1f  %+6.1f  %+6.1f  | %+7.1f%%  %+6.1f  %+6.1f  %+6.1f  | %+5.1f %%-pont\n', ...
        nev{e}, a, ra, b, rb, b - a);
    T1 = [T1; e-1, a, ra', b, rb', b-a]; %#ok<AGROW>
end
if ne > 2
    fprintf('  %s vs %s:  ívhossz %+.2f%%,  idő %+.2f%%\n', nev{ne}, nev{ne-1}, ...
        100*(Js(ne)/Js(ne-1)-1), 100*(Jt(ne)/Jt(ne-1)-1));
end
% A költség-összevetés CSV-be.
csv_iras(fullfile(out, 'ido_vs_ivhossz_koltseg.csv'), {'futas','ivh_ossz_pct','ivh_d1_pct','ivh_d2_pct','ivh_d3_pct', ...
    'ido_ossz_pct','ido_d1_pct','ido_d2_pct','ido_d3_pct','elteres_pontban'}, T1);

%% 2. Pontonkénti korreláció és skálázás
% 2) PONTONKÉNTI KORRELÁCIÓ: ugyanazon a pályaszögön az idő szerinti és az
% ívhossz szerinti derivált Pearson-korrelációja csuklónként; és a skála
% (idő/ívhossz arány), amit az elmélet szerint v_atl^k-nak kell közelítenie.
fprintf('\n2) Pontonkénti korreláció (Pearson r) az ívhossz és az idő szerinti derivált közt,\n');
fprintf('   ugyanazon a pályaszögön; skála = idő/ívhossz (legkisebb négyzetes), elmélet: v_atl^k\n');
% A csuklók sorrendje a kiírásban (a J4 a végén, mert az Alapban ~0).
jr = [1 2 3 5 6 4];
T2 = [];
for e = 1:ne
    fprintf('  %s:\n           r: J1     J2     J3     J5     J6     J4    |  skála (J1..J6 együtt)   v_atl^k\n', nev{e});
    for k = 1:3
        % Az idő-derivált helyei rendezve, periodikusan megtoldva, majd interpolálva
        % az ívhossz-derivált helyeire -> pontonként összevethető.
        as = Ds(e).ang{k};  at = Dt(e).ang{k};
        [at, o] = sort(at);  yt = Dt(e).d{k}(o, :);
        ate = [at - 360; at; at + 360];  yte = [yt; yt; yt];
        yti = interp1(ate, yte, as, 'linear');               % idő-derivált az ívhossz-pontokban
        ys = Ds(e).d{k};
        % Korreláció csuklónként (ha egyik sem konstans).
        % PEARSON-FÉLE KORRELÁCIÓS EGYÜTTHATÓ (dolgozat: eq:pearson, 4. fejezet,
        % "Ívhossz és idő szerinti kiértékelés"). A j-edik csuklóra és a k-adik
        % deriváltrendre, az N = 72 mintavételezési pontban (5°-onként):
        %
        %   r = sum_i (x_i - x_atl)(y_i - y_atl) /
        %       ( sqrt(sum_i (x_i - x_atl)^2) * sqrt(sum_i (y_i - y_atl)^2) )
        %
        %   x_i = ys(i,j)  : d^k q_j / ds^k az i-edik pontban (ivhossz_derivalt.m,
        %                    egyenletes pályaszög-rács, 5°)
        %   y_i = yti(i,j) : d^k q_j / dt^k ugyanabban a pályaszögben; az
        %                    egyenletes időrácson (T/72) számolt idő szerinti
        %                    deriváltból (ido_derivalt.m) lineáris interpolációval
        %   x_atl, y_atl   : az átlaguk a pálya mentén
        % A corrcoef(x, y) 2x2-es mátrixot ad, a c(1,2) elem maga az r.
        % Az r állandó szorzóra érzéketlen, ezért a v^k-val való skálázás nem
        % változtat rajta: az r csak a két görbe alakjának egyezését méri.
        r = NaN(1, 6);
        for j = 1:6
            if std(ys(:,j)) > 1e-12 && std(yti(:,j)) > 1e-12
                c = corrcoef(ys(:,j), yti(:,j));  r(j) = c(1,2);
            end
        end
        % Skála: legkisebb négyzetes szorzó, amivel az ívhossz-derivált az időst adja.
        sk = sum(sum(ys .* yti)) / sum(sum(ys.^2));
        fprintf('  %-9s %s  |  %10.4g              %10.4g\n', mn{k}, sprintf('%6.3f ', r(jr)), sk, vatl(e)^k);
        T2 = [T2; e-1, k, r, sk, vatl(e)^k]; %#ok<AGROW>
        Ri{e,k} = yti; %#ok<AGROW>
    end
end
% A korrelációs tábla CSV-be.
csv_iras(fullfile(out, 'ido_vs_ivhossz_pontonkent_r.csv'), [{'futas','derivalt'}, ...
    arrayfun(@(j) sprintf('r_J%d', j), 1:6, 'UniformOutput', false), {'skala','v_atl_k'}], T2);

%% 3. Szektoronkénti változások korrelációja
% 3) SZEKTORONKÉNTI VÁLTOZÁSOK: mindkét módszerrel szektoronként a
% hozzájárulás, a változás %-ban, és a két módszer változásainak korrelációja
% (r, R^2) és lineáris illesztése (idő = a*ívhossz + b).
ns = 360 / szektor;
sek = @(D, Dn) szektor_osszeg(D, Dn, lam, szektor);
Ps = zeros(ne, ns);  Pt = zeros(ne, ns);
for e = 1:ne
    Ps(e,:) = sek(Ds(e), Dns);
    Pt(e,:) = sek(Dt(e), Dnt);
end
Vs = 100*(Ps(2:end,:) ./ repmat(Ps(1,:), ne-1, 1) - 1);
Vt = 100*(Pt(2:end,:) ./ repmat(Pt(1,:), ne-1, 1) - 1);
c = corrcoef(Vs(:), Vt(:));  rsek = c(1,2);
pf = polyfit(Vs(:), Vt(:), 1);
% A szektorprofilok korrelációja (a nagyság szerinti eloszlás hasonlósága).
cp = corrcoef(Ps(:), Pt(:)/sum(Pt(1,:))*sum(Ps(1,:)));  rpr = cp(1,2);
% Szektortábla a konzolra.
fprintf('\n3) Szektoronkénti (%d°) %%-os változás a ref-hez képest:\n', szektor);
fprintf('  szektor  '); for e = 2:ne, fprintf('  %4s ívh.   %4s idő ', nev{e}, nev{e}); end; fprintf('\n');
for s = 1:ns
    fprintf('  %3d-%3d°', (s-1)*szektor, s*szektor);
    for e = 1:ne-1, fprintf('   %+6.1f%%   %+6.1f%%', Vs(e,s), Vt(e,s)); end
    fprintf('\n');
end
fprintf('  korreláció a szektorváltozások közt (%d pont): r = %.3f,  R^2 = %.3f,  idő = %.3f*ívhossz %+.2f\n', ...
    numel(Vs), rsek, rsek^2, pf(1), pf(2));
fprintf('  a szektor-hozzájárulások profiljának korrelációja (minden futás): r = %.3f\n', rpr);
% A szektor-összevetés CSV-be.
T3 = [];
for e = 1:ne-1
    T3 = [T3; repmat(e, ns, 1), ((0:ns-1)*szektor)', ((1:ns)*szektor)', Vs(e,:)', Vt(e,:)']; %#ok<AGROW>
end
csv_iras(fullfile(out, 'ido_vs_ivhossz_szektor.csv'), {'futas','szog_tol','szog_ig','ivh_valt_pct','ido_valt_pct'}, T3);

%% 4. Érzékenység az időlépésre
% 4) ÉRZÉKENYSÉG AZ IDŐLÉPÉSRE: az idő szerinti összköltség változása
% különböző időlépésekkel (N, 2N, 5N, 10N). Ha erősen függ tőle, a
% finom időlépés a mintavételi zajt erősíti (főleg a 3. deriváltban).
Nlist = [N 2*N 5*N 10*N];
fprintf('\n4) Érzékenység az időlépésre (idő szerinti összköltség változása a ref-hez képest):\n');
fprintf('     N    dt [s]   ~pályaszög  '); fprintf('  %s      ', nev{2:end}); fprintf('\n');
T4 = [];
for Nn = Nlist
    Sx = zeros(3,6,ne);
    for e = 1:ne
        Dx = ido_derivalt(Lgs{e}, Nn);
        for k = 1:3, Sx(k,:,e) = sum(Dx.d{k}.^2, 1) * Dx.ds; end
    end
    Jx = koltseg(Sx, koltseg_osztok(Sx(:,:,1), cfg), cfg);
    fprintf('  %5d   %6.3f    %5.2f°   ', Nn, Dt(1).T/Nn, 360/Nn);
    fprintf('  %+7.1f%%  ', 100*(Jx(2:end)/Jx(1)-1)); fprintf('\n');
    T4 = [T4; Nn, Dt(1).T/Nn, 360/Nn, 100*(Jx(2:end)/Jx(1)-1)]; %#ok<AGROW>
end
fprintf('  (A robot CNT%d-zal 1°-onként (%.1f mm) pontokon halad, a pályasebesség pontonként\n', ...
    cfg.ls.cnt, cfg.geom.radius*pi/180);
fprintf('   ingadozhat; ~1°-os időlépésnél ez a d3q/dt3-ban felerősödik, ezért ott nem értelmezhető.)\n');
csv_iras(fullfile(out, 'ido_vs_ivhossz_lepes.csv'), [{'N','dt_s','szog_fok'}, ...
    cellfun(@(x) [x '_pct'], nev(2:end), 'UniformOutput', false)], T4);

%% Ábrák
% ÁBRÁK: 5. szektorváltozások szórásdiagramja (ívhossz vs idő);
% 6. a deriváltak v^k-val skálázva, ívhossz vs idő; 7. a mért pályasebesség.
szin = [0 0 0; 0 0.447 0.741; 0.85 0.325 0.098; 0.466 0.674 0.188];
r = '-r150';

f5 = figure('Name', 'Ívhossz vs idő: szektorváltozások', 'Color', 'w', 'Position', [80 60 900 800]);
hold on; grid on; box on; axis equal;
lim = [min([Vs(:); Vt(:)]) - 5, max([Vs(:); Vt(:)]) + 5];
plot(lim, lim, 'k--');
for e = 1:ne-1, plot(Vs(e,:), Vt(e,:), 'o', 'Color', szin(e+1,:), 'MarkerFaceColor', szin(e+1,:), 'MarkerSize', 7); end
xlim(lim); ylim(lim);
xlabel('ívhossz szerinti változás a ref-hez képest [%]');
ylabel('idő szerinti változás a ref-hez képest [%]');
legend([{'y = x'}, nev(2:end)], 'Location', 'northwest');
title(sprintf('Szektoronként (%d°): r = %.3f, R^2 = %.3f', szektor, rsek, rsek^2));
print(f5, fullfile(out, 'm_5_ido_vs_ivhossz_szektor.png'), '-dpng', r);

f6 = figure('Name', 'Ívhossz vs idő: deriváltak (v_atl^k-val skálázva)', 'Color', 'w', 'Position', [80 60 1400 850]);
eg = {'°/s', '°/s^2', '°/s^3'};
for k = 1:3
    for jj = 1:3
        j = [3 5 6]; j = j(jj);
        subplot(3, 3, (k-1)*3 + jj); hold on; grid on; box on;
        for e = [1 ne]
            [a, o] = sort(Ds(e).ang{k});
            plot(a, Ds(e).d{k}(o, j) * vatl(e)^k, '-', 'Color', szin(e,:), 'LineWidth', 1.5);
            plot(a, Ri{e,k}(o, j), ':', 'Color', szin(e,:), 'LineWidth', 1.5);
        end
        xlim([0 360]); set(gca, 'XTick', 0:60:360);
        if k == 1, title(sprintf('J%d', j)); end
        if jj == 1, ylabel(sprintf('d^%dq/dt^%d [%s]', k, k, eg{k})); end
        if k == 3, xlabel('Pályaszög [°]'); end
        if k == 1 && jj == 1
            legend({sprintf('%s: ívh. * v^k', nev{1}), sprintf('%s: idő', nev{1}), ...
                    sprintf('%s: ívh. * v^k', nev{ne}), sprintf('%s: idő', nev{ne})}, 'Location', 'best');
        end
    end
end
print(f6, fullfile(out, 'm_6_ido_vs_ivhossz_derivaltak.png'), '-dpng', r);

f7 = figure('Name', 'Pályasebesség (v_TCP) a körön', 'Color', 'w', 'Position', [80 60 1200 800]);
subplot(2,1,1); hold on; grid on; box on;
for e = 1:ne
    if ~isempty(Lgs{e}.v)
        g = (0:1:359)' + 0.5;                       % 1°-os átlag
        va = arrayfun(@(x) mean(Lgs{e}.v(Lgs{e}.th >= x-0.5 & Lgs{e}.th < x+0.5)), g);
        plot(g, va, '-', 'Color', szin(e,:), 'LineWidth', 1.5);
    end
end
plot([0 360], [1 1]*cfg.ls.seb, 'r--');
xlim([0 360]); set(gca, 'XTick', 0:30:360); ylabel('v_{TCP}, 1°-os átlag [mm/s]');
legend([nev, {sprintf('programozott %g mm/s', cfg.ls.seb)}], 'Location', 'best');
title(sprintf('Átlagos pályasebesség: %s', strjoin(arrayfun(@(e) sprintf('%s %.2f mm/s', nev{e}, vatl(e)), 1:ne, 'UniformOutput', false), ', ')));
subplot(2,1,2); hold on; grid on; box on;
for e = 1:ne
    if ~isempty(Lgs{e}.v)
        b = Lgs{e}.th >= 180 & Lgs{e}.th <= 186;
        plot(Lgs{e}.th(b), Lgs{e}.v(b), '.-', 'Color', szin(e,:));
    end
end
plot([180 186], [1 1]*cfg.ls.seb, 'r--');
xlim([180 186]); xlabel('Pályaszög [°]'); ylabel('v_{TCP} [mm/s]');
title(sprintf('Részlet (180..186°): a pályasebesség az 1°-os pontok között (CNT%d)', cfg.ls.cnt));
print(f7, fullfile(out, 'm_7_palyasebesseg.png'), '-dpng', r);

% Visszaadott összefoglaló: költségek, szektor-korreláció, átlagsebességek.
R.Js = Js; R.Jt = Jt; R.rsek = rsek; R.vatl = vatl;
end

function P = szektor_osszeg(D, Dn, lam, szektor)
% Segédfüggvény: szektoronkénti költség-hozzájárulás egy derivált-készletből
% (ugyanaz a képlet, mint a lokalis_hozzajarulas.m-ben).
ns = 360 / szektor;
P = zeros(1, ns);
for k = 1:3
    h = lam(k) * (D.d{k}.^2 * D.ds) ./ repmat(Dn(k,:), D.n, 1) / 6;
    idx = floor(D.ang{k} / szektor) + 1;
    % A 360 fokra eső pont az utolsó szektorba kerüljön.
    idx(idx > ns) = ns;
    for s = 1:ns, P(s) = P(s) + sum(sum(h(idx == s, :))); end
end
end
