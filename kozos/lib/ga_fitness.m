function F = ga_fitness(P, G, Op, Dn, cfg, H)
% GA_FITNESS  Költség + büntetés egy populációra (oszloponként egy egyed).
%   Büntetés: rossz kulcspont (szingularitás/átfordulás közelsége) és
%   a rácson kívüli W,P,R érték [deg].
%
% -------------------------------------------------------------------------
% EZ A GA "CÉLFÜGGVÉNYE": egy egyed (Fourier-paraméterek) -> egy szám.
% Minél kisebb, annál jobb. A lánc:
%   Fourier-paraméterek -> W,P,R a kulcspontokban -> csuklószögek a rácsból
%   -> ívhossz szerinti deriváltak négyzetösszege -> normált költség
%   + büntetés, ha a megoldás rossz rácsrészre vagy a rácson kívülre esik.
%   F = ga_fitness(P, G, Op, Dn, cfg, H)
%   P   [np x N]  N egyed paraméterei (oszloponként)
%   G   rács (cand_beolvas kimenete), Op deriváló operátorok (deriv_ops),
%   Dn  normáló osztók (koltseg_osztok), H harmonikusok száma
% -------------------------------------------------------------------------

% 1) Fourier-görbe kiértékelése CSAK a kulcspontokban (pl. 12 db, 30°-onként),
%    mert csak ott ismerjük a csuklószögeket (ott van RoboGuide IK-rács).
WPR = fourier_eval(P, G.key_ang, H);            % K x 3 x N
% 2) Minden kulcspontban a W,P,R értékhez tartozó J1..J6 interpolálása a
%    rácsból. badk: mennyire esik "rossz" rácspont közelébe (0..1),
%    outk: hány fokkal lóg ki a rácsból.
[Qk, badk, outk] = wpr_joints(G, WPR);
% 3) A kulcsponti csuklószögekből spline + véges differencia: az 1., 2., 3.
%    ívhossz szerinti derivált négyzetösszege csuklónként (3 x 6 x N).
S = negyzetosszeg(Op, Qk);
% 4) Költség: a négyzetösszegek normálva (Dn) és lambda-súlyozva (koltseg.m).
%    Büntetés: cfg.valid.penalty (10) * (rossz kulcspontok "száma" +
%    rácson kívüli fokok összege). A sum(...,1) a kulcspontokra összegez,
%    így minden egyedre egy szám jön ki. A büntetés olyan nagy, hogy a GA
%    gyorsan "megtanulja" elkerülni ezeket a tartományokat.
F = koltseg(S, Dn, cfg) + cfg.valid.penalty * (sum(badk,1) + sum(outk,1));
end
