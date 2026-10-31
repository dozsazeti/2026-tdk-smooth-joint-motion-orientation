function [XYZ, WPR] = ls_kor(fname, prog, delta, cfg)
% LS_KOR  Körpálya LS program írása a közös sablonnal.
%   [XYZ, WPR] = ls_kor(fname, prog, delta, cfg)
%   fname  - a kimeneti .LS fájl
%   prog   - a program neve (legfeljebb 8 karakter, a vezérlő ezt látja)
%   delta  - [381 x 3] dW, dP, dR pontonként (-10..370°, 1°-onként), vagy
%            [1 x 3] állandó eltérés; [0 0 0] = Alap
%   XYZ, WPR - a kiírt pontok (TCP hely és a robotnak szóló W, P, R),
%            ellenőrzéshez
%
%   A pontok helye a kör (kor_xyz), a robotnak szóló W, P, R-t a delta2tcp
%   számolja, a mozgásparaméterek (sebesség, CNT, frame-ek, konfigurációs
%   ág, logger) a cfg.ls.* beállításokból jönnek. Így minden program csak
%   az orientációban tér el a többitől.
ang = cfg.ls.ang;
if size(delta, 1) == 1, delta = repmat(delta, numel(ang), 1); end
assert(size(delta, 1) == numel(ang), 'A delta sorainak száma (%d) nem egyezik a pontokéval (%d).', ...
    size(delta, 1), numel(ang));
XYZ = kor_xyz(ang, cfg);
WPR = delta2tcp(delta, cfg);
ls_iras(fname, prog, XYZ, WPR, cfg.ls.uf, cfg.ls.ut, cfg.ls.config, ...
        cfg.ls.seb, cfg.ls.seb_J, cfg.ls.cnt, cfg.ls.logger);
fprintf('Kész: %s  (%d pont, %g mm/sec, CNT%d, UF %d / UT %d, logger: %d)\n', fname, numel(ang), ...
    cfg.ls.seb, cfg.ls.cnt, cfg.ls.uf, cfg.ls.ut, cfg.ls.logger);
end
