function csv_iras(fname, hdr, M, prec)
% CSV_IRAS  Fejléc + számmátrix kiírása CSV fájlba (vesszővel tagolva).
%   csv_iras(fname, hdr, M, prec)
%   fname - a kimeneti fájl (ha létezik, felülírja)
%   hdr   - cellatömb az oszlopnevekkel
%   M     - a számadatok mátrixa (soronként egy rekord)
%   prec  - számformátum (pl. '%.4f'); ha nincs megadva, 6 értékes jegy
if nargin < 4, prec = '%.6g'; end
% Az első sorba a vesszővel összefűzött fejléc kerül.
fid = fopen(fname, 'w');
fprintf(fid, '%s\n', strjoin(hdr, ','));
fclose(fid);
% Az adatok hozzáfűzése a fejléc alá a megadott pontossággal.
if ~isempty(M)
    dlmwrite(fname, M, '-append', 'precision', prec);
end
end
