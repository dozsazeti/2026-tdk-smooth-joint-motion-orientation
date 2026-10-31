function forgat(fok)
% FORGAT  Az aktuális tengely X-feliratainak elforgatása 'fok' fokkal.
%   Csak ábrázoláshoz kell. Ha a MATLAB/Octave verzió nem ismeri ezt a
%   beállítást, csendben kihagyja (try/catch), hogy az ábra emiatt ne
%   álljon le.
try
    set(gca, 'XTickLabelRotation', fok);
catch
end
end
