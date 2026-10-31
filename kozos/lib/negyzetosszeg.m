function S = negyzetosszeg(Op, Qk)
% NEGYZETOSSZEG  Az ívhossz szerinti 1., 2., 3. derivált négyzetösszege csuklónként.
%   S = negyzetosszeg(Op, Qk)
%   Op               a deriv_ops kimenete
%   Qk [K x 6 x N]   csuklószögek a K kulcspontban, N egyedre
%   S  [3 x 6 x N]   sor: dq/ds, d2q/ds2, d3q/ds3; oszlop: J1..J6
%
% -------------------------------------------------------------------------
% Mit mér? S(d, j) ~ integrál a körön (d^d q_j / ds^d)^2 ds.
%   A négyzet miatt a nagy, hirtelen deriváltak (csúcsok) erősen számítanak,
%   és az előjel nem számít. A ds-sel szorzás az összeget integrállá teszi
%   (független lesz a mintavételi pontok számától).
% -------------------------------------------------------------------------

% Egyedek száma (a GA egész populációt ad át egyszerre).
N = size(Qk, 3);
% Kimenet: 3 deriváltrend x 6 csukló x N egyed.
S = zeros(3, 6, N);
% Csuklónként (J1..J6) külön számolunk.
for j = 1:6
    % A j-edik csukló kulcsponti szögei minden egyedre: K x N mátrix
    % (oszloponként egy egyed). Így egy mátrixszorzással minden egyed megvan.
    q = reshape(Qk(:, j, :), [], N);       % K x N
    % Deriváltrendenként (1., 2., 3.).
    for d = 1:3
        % A d-edik derivált a kiértékelő pontokban: n_eval x N.
        Y = Op.A{d} * q;
        % Négyzetre emelés, összegzés a pontokra (1. dimenzió), szorzás ds-sel
        % = a derivált négyzetének integrálja. A reshape a 3D tömbbe teszi.
        S(d, j, :) = reshape(sum(Y.^2, 1) * Op.ds, 1, 1, N);
    end
end
end
