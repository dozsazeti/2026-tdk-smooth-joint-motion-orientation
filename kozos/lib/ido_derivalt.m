function D = ido_derivalt(Lg, N)
% IDO_DERIVALT  Mért csuklószögek IDŐ szerinti deriváltjai (összevetéshez).
%   A kör (0..360°) idejét N egyenlő időlépésre osztja (dt = T/N), a logot
%   erre az egyenletes időrácsra mintavételezi (lineáris interpoláció),
%   majd nyers előre-differenciát számol idő szerint, körkörösen
%   (ugyanaz a képlet, mint az ívhossz szerinti ivhossz_derivalt.m-ben).
%   N = 72 esetén az átlagos lépés ugyanannyi pályaszög (5°), mint az
%   ívhossz szerinti kiértékelésnél.
%
%   D = ido_derivalt(Lg, N),  Lg a log_beolvas kimenete
%
%   D.d{k}   [N x 6]  dq/dt [°/s], d2q/dt2 [°/s^2], d3q/dt3 [°/s^3]
%   D.ang{k} [N x 1]  a derivált helye a körön [deg] (a mért pályaszögből)
%   D.ds     dt [s]   (a mezőnév azonos az ívhosszas változattal)
%   D.T      a kör ideje [s] (a 0° és a 360° pályaszög között eltelt idő)

% Kell az idő oszlop (Time_s) a logból.
assert(~isempty(Lg.t), 'Nincs idő oszlop a logban: %s', Lg.file);
% A 0 és a 360 fokos pályaszöghöz tartozó időpont (interpolálva), és a kör ideje T.
t0 = interp1(Lg.th, Lg.t, 0);
t1 = interp1(Lg.th, Lg.t, 360);
T  = t1 - t0;
% Időlépés: a kör ideje N egyenlő részre osztva (N = 72 -> átlagosan 5 fok).
dt = T / N;
% Az egyenletes időrács és rajta a csuklószögek (lineáris interpoláció).
tg = t0 + (0:N)' * dt;
qg = interp1(Lg.t, Lg.q, tg, 'linear');

% Idő szerinti deriváltak: ugyanaz az előre-differencia, mint ívhossz szerint,
% csak dt-vel osztva -> dq/dt, d2q/dt2, d3q/dt3 (sebesség, gyorsulás, jerk).
d1 = diff(qg, 1, 1) / dt;
d2 = (circshift(d1, -1, 1) - d1) / dt;
d3 = (circshift(d2, -1, 1) - d2) / dt;
D.d = {d1, d2, d3};
% A derivált helye a körön: a felhasznált időpontok közepéhez tartozó pályaszög.
for k = 1:3
    D.ang{k} = mod(interp1(Lg.t, Lg.th, tg(1:N) + k*dt/2, 'linear', 'extrap'), 360);
end
% Kimenetek (a mezőnév ds marad, hogy ugyanazok a függvények kezeljék).
D.ds = dt;
D.n  = N;
D.T  = T;
D.q  = qg(1:N, :);
D.th = interp1(Lg.t, Lg.th, tg(1:N));
end
