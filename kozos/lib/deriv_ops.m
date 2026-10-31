function Op = deriv_ops(key_ang, n_eval, radius)
% DERIV_OPS  Lineáris operátorok: kulcsponti értékek -> 1., 2., 3. derivált
%            ÍVHOSSZ szerint (dq/ds, d2q/ds2, d3q/ds3) a zárt körön.
%   Op = deriv_ops(key_ang, n_eval, radius)
%   key_ang [K x 1]  a kulcspontok szöge [fok], radius a kör sugara [mm]
%   Op.A{1..3}  [n_eval x K]   d^k q / ds^k  =  Op.A{k} * q_key
%   Op.M        [n_eval x K]   q(s) a kiértékelő pontokban (periodikus spline)
%   Op.th       [n_eval x 1]   a kiértékelő pontok szöge [fok]
%   Op.ds       ívhossz-lépés [mm]
%
% Lépések: periodikus köbös spline a kulcspontokon -> egyenletes mintavétel
% n_eval pontban -> nyers (előre) véges differencia, körkörösen.
% Minden lépés lineáris, ezért egyszer kiszámoljuk mátrixként.
%
% -------------------------------------------------------------------------
% MIÉRT MÁTRIX?
%   A spline-illesztés és a differenciaképzés is LINEÁRIS művelet a
%   kulcsponti értékekben: ha q_key kétszeresére nő, a derivált is.
%   Ezért az egész lánc egyetlen mátrixszal leírható: d^k q/ds^k = A{k}*q_key.
%   A mátrixokat EGYSZER számoljuk ki (itt), a GA pedig minden egyednél
%   csak egy mátrixszorzást végez -> nagyon gyors kiértékelés.
% MIÉRT ÍVHOSSZ SZERINT?
%   A rácshoz és a kulcspontokhoz nem tartozik idő (az csak valódi futásból
%   lenne), ezért a pálya ívhossza (s = R*th) szerint deriválunk. Az
%   ívhossz szerinti derivált geometriai mennyiség (°/mm, °/mm^2, °/mm^3),
%   nem sebesség, gyorsulás vagy jerk. Állandó v pályasebességnél a kettő
%   kapcsolata d^k q/dt^k = v^k * d^k q/ds^k; hogy a valós futásban ez
%   mennyire teljesül, azt a 04_roboguide_osszevetes ellenőrzi
%   (ido_ivhossz_vizsgalat.m).
% -------------------------------------------------------------------------

% Kulcsponti szögek oszlopvektorként (pl. 30, 60, ..., 360).
key_ang = key_ang(:);
% Kulcspontok száma (pl. 12).
K = numel(key_ang);
% Kiértékelő szögek: n_eval darab egyenletesen a körön, 0-tól 360-step-ig
% (pl. n_eval = 72 -> 0, 5, 10, ..., 355 fok). A 360 nincs benne, mert az
% azonos a 0-val (zárt kör).
th = (0:n_eval-1)' * 360/n_eval;          % kiértékelő szögek [deg]

% periodikus spline: 3 ponttal kibővítve mindkét oldalon
% A MATLAB spline() nem periodikus, ezért a kulcspontokat "körbeérve"
% megtoldjuk: elé tesszük az utolsó 3-at (-360 fokkal eltolva), mögé az
% első 3-at (+360 fokkal). Így a 0° és 360° környékén is mindkét oldalon
% vannak szomszédok, és a görbe gyakorlatilag periodikusan záródik.
pad = 3;
% A kibővített szögvektor: [utolsó 3 - 360, összes kulcspont, első 3 + 360].
xe = [key_ang(end-pad+1:end)-360; key_ang; key_ang(1:pad)+360];
% M lesz a spline-mátrix: n_eval sor (kiértékelő pont) x K oszlop (kulcspont).
M = zeros(n_eval, K);
% Trükk: a spline lineáris, ezért elég kiszámolni, mi lesz a görbe, ha
% CSAK a c-edik kulcspont értéke 1, a többi 0 (ez a c-edik "bázisgörbe").
% Tetszőleges kulcsponti értékekre a görbe ezek súlyozott összege: M*q_key.
for c = 1:K
    % Egységvektor: csak a c-edik kulcspont 1.
    e = zeros(K,1);  e(c) = 1;
    % Ugyanúgy kibővítjük, mint a szögeket (periodikus megtoldás).
    ye = [e(end-pad+1:end); e; e(1:pad)];
    % Köbös spline a kibővített pontokon, kiértékelve a th szögekben.
    % Ez lesz M c-edik oszlopa.
    M(:, c) = spline(xe, ye, th);
end

% Ívhossz-lépés két kiértékelő pont között: a kör kerülete / pontok száma.
% R = 300 mm, n_eval = 72 esetén ds = 2*pi*300/72 = 26.18 mm (5 fok).
ds = 2*pi*radius / n_eval;
% Egységmátrix az előre-differencia mátrix felépítéséhez.
I = eye(n_eval);
% D az előre véges differencia mátrix: (D*q)(i) = (q(i+1) - q(i)) / ds.
% circshift(I,-1,1): az egységmátrix sorait eggyel feljebb tolja, így az
% i-edik sor az (i+1)-edik elemet választja ki. Körkörös, tehát az utolsó
% pont "következője" az első -> a kör zártsága a deriválásban is megvan.
D = (circshift(I, -1, 1) - I) / ds;       % (q(i+1)-q(i))/ds, körkörösen

% Kimenet: a spline-mátrix (magukhoz a q(s) értékekhez, pl. rajzoláshoz).
Op.M  = M;
% Az ívhossz-lépés (a négyzetösszeg integrálközelítéséhez kell).
Op.ds = ds;
% A kiértékelő szögek (rajzoláshoz, szektorokhoz).
Op.th = th;
% A három derivált-operátor: 1. derivált = D*M, 2. = D*D*M, 3. = D*D*D*M.
% A 2. és 3. derivált az előre-differencia ismételt alkalmazása, pl.
% D*D*q = (q(i+2) - 2q(i+1) + q(i)) / ds^2.
Op.A  = {D*M, D*D*M, D*D*D*M};
end
