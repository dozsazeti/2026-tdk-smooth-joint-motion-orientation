function D = ivhossz_derivalt(Lg, lepes, R_kor)
% IVHOSSZ_DERIVALT  Mért csuklószögek ívhossz szerinti deriváltjai.
%   A logot egyenletes pályaszög-rácsra mintavételezi (0..360°, 'lepes'
%   fokonként, lineáris interpoláció), majd nyers előre-differenciát számol
%   s = R*th szerint, körkörösen (360° = 0°), ugyanúgy, mint az elmélet
%   (deriv_ops.m). Az első deriváltnál a 360°-os mért érték zárja a kört,
%   a többinél a körkörös eltolás.
%
%   D = ivhossz_derivalt(Lg, lepes, R_kor)
%   Lg     a log_beolvas kimenete,  lepes  a mintavétel a körön [fok],
%   R_kor  a kör sugara [mm]
%
%   D.d{k}   [n x 6]  dq/ds, d2q/ds2, d3q/ds3   (°/mm, °/mm^2, °/mm^3)
%   D.ang{k} [n x 1]  a derivált helye a körön [deg]
%   D.q      [n x 6]  mintavételezett csuklószögek (0..360-lepes)
%   D.zar    [1 x 6]  q(360) - q(0): zárási eltérés (ideálisan ~0)

% Mintapontok száma a körön (5 fokos lépésnél 72) és a pályaszögek 0..360
% (a 360 is benne van, hogy az első deriváltnál a kör a mért értékkel záródjon).
n = round(360 / lepes);
thg = (0:n)' * lepes;                         % 0..360 (n+1 pont)
% A log a teljes kört lefedi-e (a kifutás miatt -10..370 kell legyen).
assert(Lg.th(1) <= 0 && Lg.th(end) >= 360, ...
    'A log nem fedi le a 0..360° tartományt (%g..%g°): %s', Lg.th(1), Lg.th(end), Lg.file);
% A mért csuklószögek lineáris interpolálása az egyenletes pályaszög-rácsra
% (a log mintái időben egyenletesek, nem szögben).
qg = interp1(Lg.th, Lg.q, thg, 'linear');
% Ívhossz-lépés: R * lépés (radiánban), 5 foknál 26.18 mm.
ds = R_kor * deg2rad(lepes);

% 1. derivált: előre-differencia (q(i+1)-q(i))/ds; a 360 fokos pont zárja a kört.
d1 = diff(qg, 1, 1) / ds;                     % dq/ds,   n x 6, a 360°-os ponttal zárva
% 2. és 3. derivált: az előző derivált előre-differenciája, körkörösen -
% ugyanaz a séma, mint a deriv_ops.m-ben, így a mért és a becsült összevethető.
d2 = (circshift(d1, -1, 1) - d1) / ds;        % d2q/ds2
d3 = (circshift(d2, -1, 1) - d2) / ds;        % d3q/ds3

% A deriváltak és a helyük a körön (a felhasznált pontok közepe: +0.5, +1, +1.5 lépés).
D.d   = {d1, d2, d3};
D.ang = {mod(thg(1:n) + 0.5*lepes, 360), mod(thg(1:n) + 1.0*lepes, 360), mod(thg(1:n) + 1.5*lepes, 360)};
% A mintavételezett szögek, a lépés, és a zárási eltérés: q(360)-q(0)
% (ha nagy, a kör eleje és vége nem ugyanott van a csuklótérben).
D.q   = qg(1:n, :);
D.th  = thg(1:n);
D.ds  = ds;
D.n   = n;
D.zar = qg(end, :) - qg(1, :);
end
