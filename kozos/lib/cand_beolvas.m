function G = cand_beolvas(fname, cfg)
% CAND_BEOLVAS  Rácsfájl (CAND*.csv) beolvasása GA-bemenetté.
%   G = cand_beolvas(fname, cfg)
%
% Várt oszlopok (fejléc szerint keresve, sorrend mindegy):
%   index, W, P, R, deg_val, arc_length, J1..J6
%
%   (A W, P, R oszlop az orientáció-eltérés, dW, dP, dR; a status oszlop
%   a RoboGuide IK eredménye, 0 = sikeres.)
%
% Kimenet (G):
%   G.key_ang   [K x 1]  kulcspontok szöge [fok]
%   G.grid      [n x 1]  a rácsértékek (W, P, R ugyanazon a rácson, pl. -45:3:45)
%   G.n, G.step, G.K     rácspontok száma tengelyenként, rácslépés, kulcspontok száma
%   G.V         [n^3*K x 7]  J1..J6 + "rossz" jelző, lineáris indexelés:
%               lin = iW + n*(iP-1) + n^2*(iR-1) + n^3*(k-1)
%   G.alap_q    [K x 6]  az Alap (0,0,0) csuklószögei a kulcspontokban
%   G.alap_rows az Alap sorai a fájlból (az ALAP_WPR000.csv kiírásához)
%   G.bad_frac, G.ik_hiba_frac  a rossz, ill. a sikertelen IK rácspontok aránya
%
% -------------------------------------------------------------------------
% MIT CSINÁL? A RoboGuide IK eredményét (CAND2.csv: minden kulcspontban
% minden W,P,R rácskombinációhoz a J1..J6) egy gyorsan címezhető táblává
% (G.V) alakítja, amiből a wpr_joints interpolál. Közben:
%   - a J4 és J6 360 fokos ugrásait kibontja (az Alaphoz igazítva),
%   - megjelöli a "rossz" rácspontokat (sikertelen IK, szingularitás
%     közelében, vagy ahol a szomszédhoz képest hirtelen átfordul a csukló).
% -------------------------------------------------------------------------

% A fejléc (első sor) beolvasása, hogy az oszlopokat név szerint találjuk.
fid = fopen(fname, 'r');
% Az első sor vesszőnél szétvágva, szóközök levágva -> oszlopnevek listája.
hdr = strtrim(strsplit(fgetl(fid), ','));
fclose(fid);
% A számadatok beolvasása a 2. sortól (1 = egy sor kihagyása), vesszővel tagolva.
M = dlmread(fname, ',', 1, 0);

% Segédfüggvény: egy oszlopnév -> oszlopindex (kis/nagybetű nem számít).
col = @(name) find(strcmpi(hdr, name), 1);
% A kötelező oszlopok listája.
need = {'index','W','P','R','deg_val','J1','J2','J3','J4','J5','J6'};
% Ellenőrizzük, hogy mind megvan-e; ha nem, érthető hibaüzenet.
for i = 1:numel(need)
    assert(~isempty(col(need{i})), 'Hiányzó oszlop: %s', need{i});
end

% Kulcspont-index soronként (1..K).
kidx = M(:, col('index'));
% A jelölt orientációja soronként.
W = M(:, col('W'));  P = M(:, col('P'));  R = M(:, col('R'));
% A RoboGuide által számolt csuklószögek soronként (N x 6).
Q = M(:, [col('J1') col('J2') col('J3') col('J4') col('J5') col('J6')]);

% A különböző kulcspontok és számuk.
keys = unique(kidx);
K = numel(keys);
% A rács értékei (pl. -45, -42, ..., 45) a W oszlopból.
grid = unique(W);
% Rácspontok száma tengelyenként (pl. 31).
n = numel(grid);
% Biztonsági ellenőrzés: W, P, R ugyanazon a rácson legyen (a kódolás ezt feltételezi).
assert(isequal(grid, unique(P), unique(R)), 'W, P, R rácsa eltér.');
% Teljes-e a rács: K kulcspont * n^3 kombináció sor kell legyen.
assert(size(M,1) == K*n^3, 'Hiányos rács: %d sor, várt %d.', size(M,1), K*n^3);
% Rácslépés (pl. 3 fok).
step = grid(2) - grid(1);

% kulcspont szögek
% Kulcspontonként a szög (deg_val) kiolvasása az első hozzá tartozó sorból.
key_ang = zeros(K,1);
for k = 1:K
    key_ang(k) = M(find(kidx == keys(k), 1), col('deg_val'));
end

% rácsindexek explicit (nem tételezünk fel sorrendet)
% Minden sorhoz kiszámoljuk, hányadik rácspont a W, P, R (1..n). Így a
% CSV sorainak sorrendje mindegy, a tábla mindig helyes lesz.
iW = round((W - grid(1))/step) + 1;
iP = round((P - grid(1))/step) + 1;
iR = round((R - grid(1))/step) + 1;
% A kulcspont sorszáma (1..K) minden sorhoz.
[~, ik] = ismember(kidx, keys);
% Lineáris index a G.V táblában: W a leggyorsabban változó, utána P, R,
% végül a kulcspont. Ugyanezt a képletet használja a wpr_joints.
lin = iW + n*(iP-1) + n^2*(iR-1) + n^3*(ik-1);

% A tábla: 6 csuklószög + 1 "rossz" jelző oszlop.
V = zeros(n^3*K, 7);
% A csuklószögek a helyükre (a 7. oszlopot lent töltjük ki).
V(lin, 1:6) = Q;

% Sikertelen IK: a RoboGuide 'status' oszlopa (0 = sikeres, minden más,
% pl. -1 = nincs megoldás; ilyenkor a J1..J6 mind 0). Ezeket a pontokat
% kifejezetten rossznak jelöljük, nem csak azért, mert a J5 = 0 miatt a
% szingularitásszabály véletlenül elkapja őket. Ha a fájlban nincs status
% oszlop, minden pontot sikeresnek veszünk és figyelmeztetünk.
ik_hiba = false(n^3*K, 1);
if ~isempty(col('status'))
    ik_hiba(lin) = M(:, col('status')) ~= 0;
else
    warning('cand_beolvas:nostatus', ...
        'Nincs status oszlop: %s - a sikertelen IK pontok nem szűrhetők.', fname);
end

% Alap
% A 0 rácsérték indexe (W = P = R = 0 az Alap).
i0 = find(grid == 0);
assert(~isempty(i0), 'A rácsban nincs 0 érték.');
% Az Alap sorai a táblában minden kulcspontra.
alap_lin = i0 + n*(i0-1) + n^2*(i0-1) + n^3*((1:K)'-1);
% Az Alap csuklószögei kulcspontonként (K x 6) - a normáláshoz kell.
alap_q = V(alap_lin, 1:6);
% Az Alapnak minden kulcspontban elérhetőnek kell lennie (ehhez normálunk).
assert(~any(ik_hiba(alap_lin)), ...
    'Az Alap (0,0,0) IK-ja sikertelen a(z) %s fokos kulcspont(ok)ban.', ...
    num2str(key_ang(ik_hiba(alap_lin))'));

% J4, J6 kibontása az Alaphoz képest (±180-as ugrások eltüntetése)
% A J4 és J6 a vezérlőtől -180..+180 között jön; egy rácspont ezért
% 360 fokkal "elugorhat" a szomszédjától, holott a csukló fizikailag
% közel áll. Minden értéket az Alaphoz legközelebbi 360-as megfelelőjére
% hozunk: d = eltérés az Alaptól, mod(d+180,360)-180 a -180..180-ba teszi.
for j = [4 6]
    for k = 1:K
        % A k-adik kulcspont összes sora a táblában.
        r = (1:n^3) + n^3*(k-1);
        d = V(r, j) - alap_q(k, j);
        V(r, j) = alap_q(k, j) + mod(d + 180, 360) - 180;
    end
end

% rossz rácspontok: sikertelen IK, J5 szingularitás vagy J4/J6 átfordulás
% 0) Sikertelen IK (status ~= 0, lásd fent).
% 1) Csuklószingularitás: ha |J5| < 5 fok, a J4 és J6 tengelye közel
%    egybeesik, és kis orientációváltozás is nagy J4/J6 mozgást okoz.
bad = ik_hiba | abs(V(:,5)) < cfg.valid.j5_sing_min;
% 2) Átfordulás: ha két szomszédos rácspont között a J4 vagy J6 több mint
%    30 fokot ugrik, ott a megoldás "átbillen" -> mindkét pont rossz.
for j = [4 6]
    % A j-edik csukló táblája 4D tömbként: W x P x R x kulcspont.
    A = reshape(V(:, j), n, n, n, K);
    % B jelöli, mely pontok szomszédosak egy nagy ugrással.
    B = false(size(A));
    % A három rácsirány (W, P, R) mentén külön nézzük a szomszédokat.
    for ax = 1:3
        % Szomszédos elemek különbsége az ax irányban; nagy ugrás = igaz.
        D = abs(diff(A, 1, ax)) > cfg.valid.flip_jump;
        % Indexelő segédek: minden dimenzióban ':' (teljes), kivéve ax.
        idx1 = repmat({':'}, 1, 4);  idx2 = idx1;
        % idx1 = az ugrás "előtti", idx2 = az "utáni" pontok az ax irányban.
        idx1{ax} = 1:n-1;  idx2{ax} = 2:n;
        % Mindkét érintett pontot megjelöljük.
        B(idx1{:}) = B(idx1{:}) | D;
        B(idx2{:}) = B(idx2{:}) | D;
    end
    % Hozzáadjuk a rossz pontok listájához.
    bad = bad | B(:);
end
% A 7. oszlop: 1 = rossz rácspont, 0 = jó. Interpolációnál ez lesz badk.
V(:, 7) = double(bad);

% A kimeneti struktúra feltöltése.
G.key_ang   = key_ang;
G.grid      = grid;
G.n         = n;
G.step      = step;
G.K         = K;
G.V         = V;
G.alap_q    = alap_q;
% Az Alap teljes sorai a CSV-ből (az ALAP_WPR000.csv kiírásához).
G.alap_rows = M(W==0 & P==0 & R==0, :);
G.hdr       = hdr;
% A rossz rácspontok aránya (tájékoztató kiíráshoz).
G.bad_frac  = mean(bad);
% A sikertelen IK pontok aránya (ezek a rossz pontok között is benne vannak).
G.ik_hiba_frac = mean(ik_hiba);
end
