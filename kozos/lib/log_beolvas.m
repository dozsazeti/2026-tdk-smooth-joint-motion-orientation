function Lg = log_beolvas(fname, kozep)
% LOG_BEOLVAS  RoboGuide log (CSV) beolvasása, oszlopok fejléc szerint.
%   Kötelező: J1..J6 és X, Y (a pályaszöghöz). Opcionális: Z, idő (Time_s), v_TCP.
%   Az idő csak az idő szerinti összevető deriváláshoz kell (ido_derivalt.m);
%   a fő kiértékelés ívhossz szerinti.
%   Az oszlopnév elején/végén lehet egység vagy szóköz (pl. "J1 [deg]", "X(mm)").
%
%   Lg.th   [n x 1]  pályaszög [deg], folytonosan (pl. -10..370)
%   Lg.q    [n x 6]  J1..J6 [deg], J4/J6 kibontva (nincs ±360-as ugrás)
%   Lg.xyz  [n x 3]
%   Lg.t    [n x 1]  idő [s] (ha van), különben []
%   Lg.v    [n x 1]  v_TCP [mm/s], különben []
%
%   Lg = log_beolvas(fname, kozep)
%   kozep [1 x 2]  a kör középpontja (X, Y) [mm], ehhez képest számoljuk a
%                  pályaszöget (alapból [0 0]).
%   A LOG_ALL kimenete pontosvesszővel tagolt, 13 oszlopos
%   (Time_s;J1..J6;X;Y;Z;W;P;R). A függvény tabulátorral vagy vesszővel
%   tagolt, más oszlopsorrendű logot is beolvas, mert az oszlopokat név
%   szerint keresi.

if nargin < 2, kozep = [0 0]; end
fid = fopen(fname, 'r');
assert(fid > 0, 'Nem található: %s', fname);
% A fejléc (első sor) beolvasása.
sor1 = fgetl(fid);
fclose(fid);
% Elválasztó felismerése: pontosvessző (LOG_ALL), tabulátor vagy vessző.
if any(sor1 == ';'), sep = ';'; elseif any(sor1 == sprintf('\t')), sep = sprintf('\t'); else, sep = ','; end
% Oszlopnevek; ha nem bontható fel, hiba.
hdr = strtrim(strsplit(sor1, sep));
if numel(hdr) < 3
    error('Nem sikerült a fejlécet felbontani: %s', fname);
end
% A számadatok a 2. sortól; csak annyi oszlop, ahány fejlécnév van.
M = dlmread(fname, sep, 1, 0);
M = M(:, 1:numel(hdr));

% Oszlopnév-tisztítás: kisbetű, egységek és zárójelek elhagyása, így pl.
% "J1 [deg]" és "J1" is megtalálható.
tisztit = @(s) lower(regexprep(s, '[\s\[\]\(\)]|deg|mm|sec|ms|°', ''));
h = cellfun(tisztit, hdr, 'UniformOutput', false);
% Segédfüggvény: a lehetséges nevek közül az első megtalált oszlop indexe.
keres = @(nevek) find(ismember(h, nevek), 1);

% A J1..J6, X, Y, Z, idő és v_TCP oszlopok megkeresése.
cj = zeros(1, 6);
for j = 1:6
    c = keres({sprintf('j%d', j), sprintf('joint%d', j), sprintf('jnt%d', j)});
    assert(~isempty(c), 'Nincs J%d oszlop a %s fájlban. Fejléc: %s', j, fname, strjoin(hdr, ', '));
    cj(j) = c;
end
cx = keres({'x'});  cy = keres({'y'});  cz = keres({'z'});
assert(~isempty(cx) && ~isempty(cy), 'Nincs X/Y oszlop a %s fájlban. Fejléc: %s', fname, strjoin(hdr, ', '));
ct = keres({'time_s', 'time', 't', 'ido'});
cv = keres({'v_tcp', 'vtcp'});

% A csuklószögek; a J4 és J6 kibontása (a ±180-as ugrások eltüntetése).
q = M(:, cj);
for j = [4 6]
    q(:, j) = rad2deg(unwrap(deg2rad(q(:, j))));
end
% A TCP pozíció (X, Y, és ha van, Z).
xyz = [M(:, cx) M(:, cy)];
if ~isempty(cz), xyz(:, 3) = M(:, cz); else, xyz(:, 3) = NaN; end

% Pályaszög minden mintára: atan2 a kör középpontjához képest, kibontva
% (folytonos, pl. -10..370), hogy a kör második fele ne ugorjon vissza.
th = rad2deg(unwrap(atan2(xyz(:,2) - kozep(2), xyz(:,1) - kozep(1))));
% Ha fordított irányban haladt, előjelet váltunk.
if th(end) < th(1), th = -th; end           % ha a log fordított irányú lenne

% A kör kiválasztása: a log a program indítása előtti pozícióval kezdődik
% (pl. az előző futás vége, +10°), onnan J mozgással áll a P[1]-re (-10°),
% majd körbemegy 370°-ig. Ezért a vég = a legnagyobb pályaszög, a kezdet =
% az utolsó minimum előtte. Ezen belül csak az előrehaladó minták maradnak
% (állás, CNT-n belüli apró visszalépés kiszűrése).
% A kör vége = a legnagyobb pályaszög (370 fok).
[~, ie] = max(th);
% Kezdete = az utolsó minimum előtte (a -10 fokos kezdőpont, P[1]).
[~, ib] = min(flipud(th(1:ie)));  ib = ie - ib + 1;
% A kijelölt szakasz.
seg = false(size(th));  seg(ib:ie) = true;
% Csak az előrehaladó minták maradnak: ahol a szög nő, és nem kisebb az
% addigi maximumnál (állás és CNT-n belüli apró visszalépés kiszűrése).
cm = -inf(size(th));  cm(ib:ie) = cummax(th(ib:ie));
jo = seg & [true; diff(th) > 1e-6] & th >= cm;
% A kimeneti struktúra: pályaszög, csuklószögek, pozíció, idő, v_TCP.
Lg.th  = th(jo);
Lg.q   = q(jo, :);
Lg.xyz = xyz(jo, :);
if ~isempty(ct), Lg.t = M(jo, ct); else, Lg.t = []; end
if ~isempty(cv)
    Lg.v = M(jo, cv);                       % ha a log tartalmaz v_TCP oszlopot, azt vesszük át
elseif ~isempty(ct) && ~isempty(cz)
    % A LOG_ALL nem ír v_TCP oszlopot, ezért itt számoljuk: két egymás
    % utáni minta XYZ-távolsága osztva az eltelt idővel.
    tt = M(:, ct);
    vv = [0; sqrt(sum(diff(xyz, 1, 1).^2, 2)) ./ max(diff(tt), eps)];
    Lg.v = vv(jo);
else
    Lg.v = [];
end
Lg.hdr = hdr;
Lg.file = fname;
end
