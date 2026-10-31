function q = p_atvalt(p, H1, H2)
% P_ATVALT  Fourier-paramétervektor átírása H1 harmonikusról H2-re
%   (a hiányzó magasabb harmonikusok 0-k, a fölöslegesek elhagyva).
%   q = p_atvalt(p, H1, H2)
%   p: [3*(1+2*H1) x N]  ->  q: [3*(1+2*H2) x N]
%   A 2. kör ezzel írja át a 2 harmonikusos középgörbét 3 harmonikusos
%   alakra; a hozzáadott harmonikus együtthatói 0-k, így a görbe nem változik.
% Együtthatók száma csatornánként a két alakban, és a közös rész hossza.
nb1 = 1 + 2*H1;  nb2 = 1 + 2*H2;  m = min(nb1, nb2);
N = size(p, 2);
% Új vektor: csupa 0, ide másoljuk a meglévő együtthatókat.
q = zeros(3*nb2, N);
% Csatornánként (W, P, R) az első m együtthatót (a0, a1, b1, ...) átmásoljuk;
% a hiányzó magasabb harmonikusok 0-k maradnak -> a görbe nem változik.
for ch = 1:3
    q((ch-1)*nb2 + (1:m), :) = p((ch-1)*nb1 + (1:m), :);
end
end
