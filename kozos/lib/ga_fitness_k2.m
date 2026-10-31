function F = ga_fitness_k2(X, pc, G, Op, Dn, cfg, H)
% GA_FITNESS_K2  Költség + büntetés a 2. körben.
%   F = ga_fitness_k2(X, pc, G, Op, Dn, cfg, H)
%   X  [np x N]  a középgörbe Fourier-paramétereihez (pc) képesti eltérések,
%                oszloponként egy egyed
%   G            a 2. kör rácsa (k2_beolvas), Op, Dn, H mint a ga_fitness-ben
%   Ugyanaz a lánc, mint az 1. körben (ga_fitness), csak a rács itt a
%   középgörbéhez képesti eltolásokon van, ezért interpoláció előtt a
%   középgörbe kulcsponti értékét le kell vonni.
%   Büntetés: rossz rácspont közelsége és az ablakon kívüli eltolás [fok].
% Egyedek száma.
N = size(X, 2);
% A teljes Fourier-paraméter: középgörbe + az egyed eltérése.
P = repmat(pc, 1, N) + X;
% A kulcsponti W,P,R ELTÉRÉSE a középértéktől - a 2. kör rácsa eltéréseken van.
E = fourier_eval(P, G.key_ang, H) - repmat(G.kozep, [1 1 N]);
% Interpoláció a ±cfg.k2.range fokos rácsból, utána ugyanaz a költség és
% büntetés, mint az 1. körben (ablakon kívüli eltolás = outk büntetés).
[Qk, badk, outk] = wpr_joints(G, E);
F = koltseg(negyzetosszeg(Op, Qk), Dn, cfg) + cfg.valid.penalty * (sum(badk,1) + sum(outk,1));
end
