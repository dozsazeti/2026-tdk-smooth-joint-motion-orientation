function G = k2_beolvas(cfg)
% K2_BEOLVAS  CAND.csv (2. kör) + RoboGuide JOINTS.CSV összefűzése GA-bemenetté.
%   G = k2_beolvas(cfg)
%   A CAND.csv és a JOINTS.CSV sorait az (index, candidate_id) kulcs szerint
%   párosítja, majd a cand_beolvas-hoz hasonló, gyorsan címezhető táblát épít.
%
%   G.grid, G.step, G.n, G.K, G.V : mint a cand_beolvas-nál, de a rács a
%                                   középgörbéhez képesti ELTOLÁS (dW,dP,dR)
%   G.kozep   [K x 3]  középgörbe W,P,R a kulcspontokban
%   G.alap_q  [K x 6]  Alap (0,0,0) csuklószögek a kulcspontokban
%   G.key_ang [K x 1]

% A CAND.csv beolvasása (a jelöltek abszolút és eltolás szerinti W,P,R-je).
[C, hc] = csv_olvas(cfg.k2.cand_csv);
% Segédfüggvény: oszlopnév -> index egy adott fejlécben.
col = @(h, n) find(strcmpi(h, n), 1);

% JOINTS.CSV: idx,k,J1..J6,status  (szóközök a számok előtt)
% A RoboGuide kimenet (JOINTS.CSV) fejléce és adatai.
fid = fopen(cfg.k2.joints, 'r');
assert(fid > 0, 'Nincs meg a RoboGuide kimenet: %s', cfg.k2.joints);
hj = strtrim(strsplit(fgetl(fid), ','));
fclose(fid);
Jm = dlmread(cfg.k2.joints, ',', 1, 0);
% Csak annyi oszlop kell, ahány fejlécnév van (a sorvégi üres mezők levágása).
Jm = Jm(:, 1:numel(hj));
% A J1..J6 és a status oszlop helye.
cj = zeros(1,6); for j = 1:6, cj(j) = col(hj, sprintf('J%d', j)); end
cs = col(hj, 'status');

% Párosítás: a CAND minden sorához megkeressük a JOINTS azonos (index,
% jelölt-sorszám) sorát. ok = megvan-e, loc = hol.
[ok, loc] = ismember(C(:, [col(hc,'index') col(hc,'candidate_id')]), Jm(:, 1:2), 'rows');
fprintf('  párosítva: %d / %d sor (JOINTS: %d sor)\n', sum(ok), size(C,1), size(Jm,1));
% Csuklószögek (NaN, ha nincs párja) és status (1 = rossz, ha nincs párja).
Q = NaN(size(C,1), 6);  st = ones(size(C,1), 1);
Q(ok, :) = Jm(loc(ok), cj);
% Ha van status oszlop, azt vesszük át (0 = rendben, -1 = nem elérhető).
if ~isempty(cs), st(ok) = Jm(loc(ok), cs); else, st(ok) = 0; end

% A CAND oszlopai: kulcspont, tipus (0 = rácsjelölt, 1 = Alap), eltolás, abszolút W,P,R.
idx  = C(:, col(hc,'index'));
tip  = C(:, col(hc,'tipus'));
dWPR = C(:, [col(hc,'dW') col(hc,'dP') col(hc,'dR')]);
WPR  = C(:, [col(hc,'W') col(hc,'P') col(hc,'R')]);
keys = unique(idx);  K = numel(keys);
% Az eltolás-rács (-range..range, step lépéssel; 10 / 1 mellett n = 21).
g = (-cfg.k2.range:cfg.k2.step:cfg.k2.range).';  n = numel(g);  h = cfg.k2.step;

% Kimenetek lefoglalása; a "rossz" jelző alapból 1 (ami nincs kitöltve, rossz).
key_ang = zeros(K,1);  kozep = zeros(K,3);  alap_q = NaN(K,6);
V = zeros(n^3*K, 7);  V(:,7) = 1;
% Kulcspontonként:
for k = 1:K
    % A kulcspont sorai, a szöge, az Alap sora (ra) és a rácssorai (rg).
    rk = find(idx == keys(k));
    key_ang(k) = C(rk(1), col(hc,'deg_val'));
    ra = rk(tip(rk) == 1);
    rg = rk(tip(rk) == 0);
    % A középérték = abszolút W,P,R - eltolás (bármelyik rácssorból).
    kozep(k,:) = WPR(rg(1),:) - dWPR(rg(1),:);
    % Az Alap csuklószögei (a normáláshoz).
    if ~isempty(ra), alap_q(k,:) = Q(ra(1),:); end
    % A rácssorok eltolásából rácsindex (1..n), majd lineáris index a táblában.
    ii = round((dWPR(rg,:) + cfg.k2.range)/h) + 1;
    lin = ii(:,1) + n*(ii(:,2)-1) + n^2*(ii(:,3)-1) + n^3*(k-1);
    % Csuklószögek a helyükre; rossz, ha a status nem 0 vagy hiányzik adat.
    V(lin, 1:6) = Q(rg, :);
    V(lin, 7)   = double(st(rg) ~= 0 | any(isnan(Q(rg,:)), 2));
end
% Ha valamelyik kulcspontban nincs Alap, nem tudunk normálni -> hiba.
assert(~any(isnan(alap_q(:))), 'Hiányzik az Alap (0,0,0) IK valamelyik kulcspontban.');

% J4, J6 kibontása: minden értéket a középső (0,0,0 eltolású) rácsponthoz
% legközelebbi 360-as megfelelőjére hozunk, az Alapot is.
i0 = (n+1)/2;
for k = 1:K
    r = (1:n^3) + n^3*(k-1);
    c0 = V(i0 + n*(i0-1) + n^2*(i0-1) + n^3*(k-1), :);
    for j = [4 6]
        V(r, j) = c0(j) + mod(V(r, j) - c0(j) + 180, 360) - 180;
        alap_q(k, j) = c0(j) + mod(alap_q(k, j) - c0(j) + 180, 360) - 180;
    end
end

% Rossz rácspontok: rossz status, J5 szingularitás vagy J4/J6 átfordulás a
% szomszédhoz képest - ugyanaz a logika, mint a cand_beolvas.m-ben.
bad = V(:,7) > 0 | abs(V(:,5)) < cfg.valid.j5_sing_min;
for j = [4 6]
    A = reshape(V(:, j), n, n, n, K);
    B = false(size(A));
    for ax = 1:3
        Dd = abs(diff(A, 1, ax)) > cfg.valid.flip_jump;
        i1 = repmat({':'}, 1, 4);  i2 = i1;  i1{ax} = 1:n-1;  i2{ax} = 2:n;
        B(i1{:}) = B(i1{:}) | Dd;  B(i2{:}) = B(i2{:}) | Dd;
    end
    bad = bad | B(:);
end
V(:,7) = double(bad);

% A kimeneti struktúra.
G.grid = g;  G.step = h;  G.n = n;  G.K = K;  G.V = V;
G.kozep = kozep;  G.alap_q = alap_q;  G.key_ang = key_ang;
G.bad_frac = mean(bad);
end
