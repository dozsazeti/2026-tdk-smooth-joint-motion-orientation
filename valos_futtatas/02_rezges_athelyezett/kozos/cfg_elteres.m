function cfg_elteres(cfg, cfg_fo)
% CFG_ELTERES  Kiírja, miben tér el ez a beállítás a fő futásétól (kozos\config.m).
%   cfg_elteres(cfg, cfg_fo)
%   Az útvonalakat (cfg.path, cfg.file) és a futtatás saját blokkját
%   (cfg.rez) nem hasonlítja, mert ezek szándékosan mások. Minden más mezőnél
%   kiírja, ha az érték eltér, vagy ha a mező csak az egyikben van meg. Így
%   ellenőrizhető, hogy a módszer a fő futáséval azonos, és csak a kör helye
%   változott.
kihagy = {'path', 'file', 'rez'};
L = {};
L = hasonlit(cfg, cfg_fo, 'cfg', kihagy, L);
if isempty(L)
    fprintf('A beállítás a fő futáséval (kozos\\config.m) minden mezőben azonos.\n');
else
    fprintf('Eltérés a fő futáshoz (kozos\\config.m) képest:\n');
    fprintf('  %s\n', L{:});
end
end

function L = hasonlit(a, b, nev, kihagy, L)
fa = fieldnames(a);  fb = fieldnames(b);
for i = 1:numel(fa)
    f = fa{i};
    if any(strcmp(f, kihagy)), continue; end
    n = [nev '.' f];
    if ~isfield(b, f)
        L{end+1} = sprintf('%s  csak itt van', n); %#ok<AGROW>
    elseif isstruct(a.(f)) && isstruct(b.(f)) && isscalar(a.(f)) && isscalar(b.(f))
        L = hasonlit(a.(f), b.(f), n, {}, L);
    elseif ~isequal(a.(f), b.(f))
        L{end+1} = sprintf('%s  itt: %s   fő futás: %s', n, ertek(a.(f)), ertek(b.(f))); %#ok<AGROW>
    end
end
for i = 1:numel(fb)
    f = fb{i};
    if any(strcmp(f, kihagy)), continue; end
    if ~isfield(a, f)
        L{end+1} = sprintf('%s.%s  csak a fő futásban van (itt nem kell)', nev, f); %#ok<AGROW>
    end
end
end

function s = ertek(v)
if ischar(v), s = ['''' v ''''];
elseif isnumeric(v) && numel(v) <= 6, s = mat2str(v);
else, s = sprintf('[%s %s]', strjoin(string(size(v)), 'x'), class(v));
end
end
