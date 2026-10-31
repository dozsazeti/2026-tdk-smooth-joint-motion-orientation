function wpr = rot2wpr(M)
% ROT2WPR  Forgatási mátrix -> FANUC W, P, R [fok].
%   wpr = rot2wpr(M)
%   A wpr2rot inverze (M = Rz(R) * Ry(P) * Rx(W)).
%   Tartományok: -180 < W, R <= 180,  |P| <= 90.
p = asind(max(-1, min(1, -M(3, 1))));
w = atan2d(M(3, 2), M(3, 3));
r = atan2d(M(2, 1), M(1, 1));
wpr = round([w, p, r] * 1e6) / 1e6;  % numerikus zaj levágása (pl. -1e-14)
wpr(wpr == -180) = 180;              % -180 és 180 ugyanaz, a FANUC 180-at ír
wpr(wpr == 0) = 0;                   % -0 -> 0
end
