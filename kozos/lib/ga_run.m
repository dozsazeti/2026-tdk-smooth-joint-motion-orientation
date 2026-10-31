function [xbest, fbest] = ga_run(fit, lb, ub, o)
% GA_RUN  Valós kódolású GA: verseny-szelekció, BLX-0.3 keresztezés,
%   Gauss-mutáció csökkenő szórással, elitizmus.
%   [xbest, fbest] = ga_run(fit, lb, ub, o)
%   A csupa 0 paramétervektor mindig benne van a kezdő populációban (az 1.
%   körben ez az Alap, a 2. körben a középgörbe), így az elitizmus miatt
%   az eredmény sosem rosszabb ennél.
%
% -------------------------------------------------------------------------
% A GENETIKUS ALGORITMUS LÉNYEGE (ebben a kódban):
%   - Egyed = egy paramétervektor (itt a W,P,R Fourier-együtthatói).
%   - Populáció = sok egyed egyszerre (oszloponként egy).
%   - Fitness = a költség (ga_fitness), KISEBB a jobb.
%   - Generációnként: a legjobbakat változatlanul átvisszük (elitizmus),
%     a többit "szülők" párosításával (keresztezés) és véletlen
%     módosításával (mutáció) hozzuk létre. A szülőket versennyel
%     választjuk: a jobbaknak nagyobb esélyük van szülővé válni.
%   - Leáll, ha elérte a max. generációszámot, vagy ha stall_gen
%     generáción át nem javult a legjobb megoldás.
%   Bemenet:  fit  - függvény, ami egy paramétermátrixra (np x N)
%                    visszaadja a költségeket (1 x N)
%             lb, ub - alsó/felső korlát paraméterenként (np x 1)
%             o    - beállítások (cfg.ga): pop_size, max_gen, stall_gen,
%                    elite, tour_k, p_mut
%   Kimenet:  xbest - a legjobb talált paramétervektor, fbest - a költsége
% -------------------------------------------------------------------------

% np = paraméterek száma (pl. 15), N = populáció mérete (pl. 150).
np = numel(lb);  N = o.pop_size;
% Kezdő populáció: minden paraméter egyenletes eloszlású véletlen szám a
% saját [lb, ub] tartományán belül. repmat: a korlátokat N oszlopra
% sokszorozza; rand(np, N): 0..1 közötti véletlen számok.
X = repmat(lb, 1, N) + repmat(ub - lb, 1, N) .* rand(np, N);
% Az első egyed csupa 0: ez az Alap (W=P=R=0 az 1. körben, ill. maga a
% középgörbe a 2. körben). Az elitizmus miatt a végeredmény így sosem
% lehet rosszabb a kiindulásnál.
X(:, 1) = 0;
% A kezdő populáció költségei (egy hívással az egészre).
F = fit(X);
% Az eddigi legjobb: költség (fbest), helye (ib) és paraméterei (xbest).
% stall = hány generáció óta nem javult a legjobb.
[fbest, ib] = min(F);  xbest = X(:, ib);  stall = 0;
% Generációk ciklusa.
for g = 1:o.max_gen
    % A populáció sorrendje költség szerint növekvően (srt = indexek).
    [~, srt] = sort(F);
    % ELITIZMUS: a legjobb o.elite (pl. 3) egyed változatlanul túlél.
    E = X(:, srt(1:o.elite));
    % Ennyi új "gyereket" kell előállítani, hogy a létszám N maradjon.
    nk = N - o.elite;
    % SZELEKCIÓ (verseny): nk darab első szülő (A) és nk darab második
    % szülő (B). Mindegyiket egy tour_k fős "versenyből" választjuk: a
    % véletlenül kihúzott tour_k egyed közül a legkisebb költségű nyer.
    A = X(:, tour(F, nk, o.tour_k));
    B = X(:, tour(F, nk, o.tour_k));
    % KERESZTEZÉS (BLX-alfa, alfa = 0.3): paraméterenként a két szülő
    % értéke közti intervallumot [lo, lo+d] mindkét irányban 30%-kal
    % kiszélesítjük, és ebből húzunk egyenletesen.
    % lo = a kisebbik szülőérték, d = a két szülő különbsége.
    lo = min(A, B);  d = max(A, B) - lo;
    % Gyerek = lo - 0.3*d + 1.6*d*rand  ->  a [lo-0.3d, hi+0.3d] tartomány.
    % A kiszélesítés miatt a gyerek a szülők "közén kívülre" is kerülhet,
    % így a populáció nem húzódik össze túl gyorsan.
    C = (lo - 0.3*d) + (1.6*d) .* rand(np, nk);
    % MUTÁCIÓ szórása: a generációk előrehaladtával lineárisan csökken
    % (a tartomány 16%-áról 1%-ára). Elején nagy ugrások (felfedezés),
    % a végén finom hangolás.
    sig = (0.15*(1 - g/o.max_gen) + 0.01) * (ub - lb);
    % Melyik gyerek melyik paramétere mutálódik: p_mut (pl. 15%) eséllyel.
    m = rand(np, nk) < o.p_mut;
    % A kiválasztott paraméterekhez normális eloszlású zajt adunk
    % (randn), a fenti szórással.
    C = C + m .* (repmat(sig, 1, nk) .* randn(np, nk));
    % A gyerekeket visszavágjuk a [lb, ub] korlátok közé.
    C = min(max(C, repmat(lb, 1, nk)), repmat(ub, 1, nk));
    % Az új populáció: elitek + gyerekek.
    X = [E C];
    % Költségek: az elitekét már ismerjük (nem számoljuk újra), csak a
    % gyerekeket értékeljük ki -> gyorsabb.
    F = [F(srt(1:o.elite)) fit(C)];
    % A generáció legjobbja.
    [fg, ib] = min(F);
    % Ha érdemben (1e-9-nél többel) jobb az eddigi legjobbnál, frissítjük,
    % és a stall számlálót nullázzuk.
    if fg < fbest - 1e-9
        fbest = fg; xbest = X(:, ib); stall = 0;
    else
        % Különben eggyel több generáció telt el javulás nélkül.
        stall = stall + 1;
    end
    % Korai leállás: ha stall_gen (pl. 50) generáción át nincs javulás.
    if stall >= o.stall_gen, break; end
end
end

function idx = tour(F, n, k)
% TOUR  Verseny-szelekció: n darab győztes indexe, mindegyik k fős versenyből.
% c: k x n mátrix véletlen egyedindexekből (oszloponként egy verseny).
c = randi(numel(F), k, n);
% Minden versenyben (oszlopban) a legkisebb költségű helye (w, 1..k).
[~, w] = min(F(c), [], 1);
% A győztesek tényleges populációs indexei.
idx = c(sub2ind(size(c), w, 1:n));
end
