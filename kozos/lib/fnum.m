function s = fnum(v)
% FNUM  Szám a FANUC LS formátumában: 3 tizedes, 9 karakter széles mező,
%   a 0 egészrész nélkül (pl. 0.500 -> '.500', -0.250 -> '-.250', 0 -> '.000').
%   Az ls_iras és a kísérletek LS-írói használják a pozíciók kiírásához.
s = sprintf('%.3f', v);
if strcmp(s, '-0.000'), s = '0.000'; end
s = regexprep(s, '^(-?)0\.', '$1.');
s = sprintf('%9s', s);
end
