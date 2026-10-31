function L = lokalis_hozzajarulas(Op, q_key, Dn, cfg)
% LOKALIS_HOZZAJARULAS  A költség felbontása a kör mentén.
%   Ugyanazokkal az operátorokkal és osztókkal számol, mint a GA, ezért
%   a pontonkénti hozzájárulások összege PONTOSAN a koltseg.m értéke.
%
%   L = lokalis_hozzajarulas(Op, q_key, Dn, cfg)
%   Op    a deriv_ops kimenete,  Dn  a koltseg_osztok kimenete
%   q_key [K x 6]  csuklószögek a kulcspontokban
%   L.d{k}   [n x 6]  k-adik derivált ívhossz szerint (1 = dq/ds [°/mm],
%                     2 = d2q/ds2 [°/mm^2], 3 = d3q/ds3 [°/mm^3]), csuklónként
%   L.ang{k} [n x 1]  a k-adik derivált helye a körön [deg]
%                     (előre differencia -> a felhasznált pontok közepe)
%   L.h{k}   [n x 6]  hozzájárulás az összköltséghez, mintánként és csuklónként
%   L.J      összköltség (= sum minden L.h)
%   L.Jk     [1 x 3]  az 1., 2., 3. derivált része az összköltségben
%
% -------------------------------------------------------------------------
% MIRE JÓ? A koltseg.m egyetlen számot ad. Ez a függvény ugyanazt a számot
% "szétteríti" a kör mentén: melyik szakasz, melyik csukló, melyik
% deriváltrend mennyit ad hozzá. Így látszik, HOL javított az optimalizálás.
% -------------------------------------------------------------------------

% Kiértékelő pontok száma (pl. 72) és a köztük lévő szöglépés (pl. 5 fok).
n = numel(Op.th);
step = 360 / n;
% Normált lambda-súlyok (sorvektor), ugyanúgy, mint a koltseg.m-ben.
lam = cfg.cost.lambda(:)' / sum(cfg.cost.lambda);
% Kimeneti cellák lefoglalása a 3 deriváltrendhez.
L.d = cell(1,3);  L.ang = cell(1,3);  L.h = cell(1,3);
L.Jk = zeros(1,3);
% Deriváltrendenként.
for k = 1:3
    % A k-adik derivált minden kiértékelő pontban, minden csuklóra.
    Y = Op.A{k} * q_key;                               % n x 6
    L.d{k} = Y;
    % Hová tartozik a derivált a körön: az előre-differencia a th, th+step,
    % ..., th+k*step pontokat használja, ezek közepe th + k*step/2.
    % mod 360: a kör végén visszafordul 0-ra.
    L.ang{k} = mod(Op.th + k*step/2, 360);
    % Pontonkénti hozzájárulás: lambda * (derivált^2 * ds) / osztó / 6.
    % Ezek összege a pontokra és csuklókra pontosan a koltseg.m-ben
    % számolt lambda * átlag(S/Dn) - a /6 a 6 csuklóra vett átlag.
    L.h{k} = lam(k) * (Y.^2 * Op.ds) ./ repmat(Dn(k,:), n, 1) / 6;
    % A k-adik deriváltrend teljes része az összköltségben.
    L.Jk(k) = sum(L.h{k}(:));
end
% Összköltség = a három rész összege (= koltseg.m eredménye).
L.J = sum(L.Jk);
end
