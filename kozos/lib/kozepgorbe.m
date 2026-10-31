function [p, H] = kozepgorbe(cfg)
% KOZEPGORBE  A 2. kör ablakának középgörbéje (Fourier-paraméterek).
%   [p, H] = kozepgorbe(cfg)
%   A 2. kör rácsa nem az Alap, hanem egy középgörbe (alapból az 1. kör opt1
%   megoldása) körül fut. Ez a függvény a cfg.k2.kozep_file összesítőből
%   (alapból 02_ga_durva\eredmenyek_korlat\01_ga\opt_osszesites.csv) kiolvassa
%   a cfg.k2.kozep_opt sorszámú megoldás W_c1..R_c<nb> oszlopait.
%   Kimenet: p [3*(1+2H) x 1] Fourier-paraméterek (fourier_eval sorrendben), H.
% Az összesítő tábla (1. kör: opt_osszesites.csv) beolvasása.
[T, hdr] = csv_olvas(cfg.k2.kozep_file);
% A középgörbe harmonikusszáma és az együtthatók száma csatornánként.
H = cfg.k2.kozep_H;
nb = 1 + 2*H;
% Az opt = kozep_opt (alapból 1) sor megkeresése.
sor = find(T(:, strcmpi(hdr, 'opt')) == cfg.k2.kozep_opt, 1);
assert(~isempty(sor), 'Nincs opt=%d sor: %s', cfg.k2.kozep_opt, cfg.k2.kozep_file);
% A paramétervektor összerakása a W_c1.., P_c1.., R_c1.. oszlopokból, a
% fourier_eval által várt sorrendben.
p = zeros(3*nb, 1);
c = 'WPR';
for ch = 1:3
    for b = 1:nb
        idx = find(strcmpi(hdr, sprintf('%s_c%d', c(ch), b)), 1);
        assert(~isempty(idx), 'Hiányzó oszlop: %s_c%d', c(ch), b);
        p((ch-1)*nb + b) = T(sor, idx);
    end
end
end
