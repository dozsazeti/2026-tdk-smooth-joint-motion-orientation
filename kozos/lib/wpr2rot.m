function M = wpr2rot(wpr)
% WPR2ROT  FANUC W, P, R [fok] -> forgatási mátrix.
%   M = wpr2rot(wpr),  wpr [1 x 3]
%   A FANUC konvenciója szerint a W az X, a P az Y, az R a Z tengely körüli
%   elforgatás a rögzített (user frame) tengelyek körül, ebben a sorrendben,
%   így  M = Rz(R) * Ry(P) * Rx(W).
w = wpr(1);  p = wpr(2);  r = wpr(3);
Rx = [1 0 0; 0 cosd(w) -sind(w); 0 sind(w) cosd(w)];
Ry = [cosd(p) 0 sind(p); 0 1 0; -sind(p) 0 cosd(p)];
Rz = [cosd(r) -sind(r) 0; sind(r) cosd(r) 0; 0 0 1];
M = Rz * Ry * Rx;
end
