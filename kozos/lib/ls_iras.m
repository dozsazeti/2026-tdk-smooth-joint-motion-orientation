function ls_iras(fname, prog, XYZ, WPR, uf, ut, config, seb, seb_J, cnt, logger)
% LS_IRAS  FANUC TP program írása ASCII (.LS) formátumban.
%   ls_iras(fname, prog, XYZ, WPR, uf, ut, config, seb, seb_J, cnt, logger)
%   XYZ, WPR [N x 3] - a pontok (TCP hely [mm] és a robotnak szóló W, P, R
%                      [fok]) a megadott user frame-ben (uf) és tool frame-mel (ut)
%   config           - a konfigurációs ág (pl. 'N U T, 0, 0, 0'), minden pontban ugyanaz
%   seb [mm/sec]     - pályasebesség a lineáris (L) mozgásokhoz
%   seb_J [%]        - az első pontra odaálló J mozgás sebessége
%   cnt              - CNT érték (0..100): mennyire simíthatja a vezérlő a
%                      pontok közti átmenetet; 100 = legnagyobb simítás
%   logger           - true esetén a mozgás köré kerülnek a naplózó sorok
%
%   A fájl szerkezete (/PROG, /ATTR, /APPL, /MN, /POS, /END) a valós roboton
%   is lefutott ALAP.LS programét követi, CRLF sorvégekkel, így ugyanaz a
%   fájl betölthető a RoboGuide-ba és a valós vezérlőre is.
%
%   A program mozgásai: J P[1] (odaállás FINE-nal), majd L P[2] ... L P[N]
%   a megadott sebességgel és CNT-vel. Ha logger = true, a mozgás előtt
%   F[1] = ON és RUN LOG_ALL indítja a naplózó KAREL programot (külön
%   taszkként, a mozgással párhuzamosan), a mozgás után F[1] = OFF állítja le.
n = size(XYZ, 1);

% A /MN (programtörzs) sorai.
mn = {sprintf('J P[1] %d%% FINE    ', seb_J)};
for i = 2:n
    mn{end+1} = sprintf('L P[%d] %gmm/sec CNT%d    ', i, seb, cnt); %#ok<AGROW>
end
if logger
    % A rövid várakozások biztosítják, hogy a logger már fusson, mire a
    % robot elindul, és a mozgás végét is rögzítse, mielőtt leáll.
    mn = [{' F[1]=(ON)    ', ' WAIT .10(sec)    ', ' RUN LOG_ALL    ', ' WAIT .20(sec)    '}, mn, ...
          {' WAIT .10(sec)    ', ' F[1]=(OFF)    '}];
end
mn{end+1} = ' WAIT .50(sec)    ';

% Fejléc (/ATTR, /APPL), a CREATE / MODIFIED dátum a generálás ideje.
ido = now;
nl  = sprintf('\r\n');
fid = fopen(fname, 'w');
assert(fid > 0, 'Nem írható: %s', fname);
fprintf(fid, ['/PROG  %s' nl], prog);
fprintf(fid, ['/ATTR' nl]);
fprintf(fid, ['OWNER\t\t= MNEDITOR;' nl]);
fprintf(fid, ['COMMENT\t\t= "";' nl]);
fprintf(fid, ['PROG_SIZE\t= 0;' nl]);
fprintf(fid, ['CREATE\t\t= DATE %s  TIME %s;' nl], datestr(ido, 'yy-mm-dd'), datestr(ido, 'HH:MM:SS'));
fprintf(fid, ['MODIFIED\t= DATE %s  TIME %s;' nl], datestr(ido, 'yy-mm-dd'), datestr(ido, 'HH:MM:SS'));
fprintf(fid, ['FILE_NAME\t= ;' nl]);
fprintf(fid, ['VERSION\t\t= 0;' nl]);
fprintf(fid, ['LINE_COUNT\t= %d;' nl], numel(mn));
fprintf(fid, ['MEMORY_SIZE\t= 0;' nl]);
fprintf(fid, ['PROTECT\t\t= READ_WRITE;' nl]);
fprintf(fid, ['TCD:  STACK_SIZE\t= 0,' nl]);
fprintf(fid, ['      TASK_PRIORITY\t= 50,' nl]);
fprintf(fid, ['      TIME_SLICE\t= 0,' nl]);
fprintf(fid, ['      BUSY_LAMP_OFF\t= 0,' nl]);
fprintf(fid, ['      ABORT_REQUEST\t= 0,' nl]);
fprintf(fid, ['      PAUSE_REQUEST\t= 0;' nl]);
fprintf(fid, ['DEFAULT_GROUP\t= 1,*,*,*,*;' nl]);
fprintf(fid, ['CONTROL_CODE\t= 00000000 00000000;' nl]);
fprintf(fid, ['/APPL' nl]);
fprintf(fid, ['  SPOT : TRUE ; ' nl]);
fprintf(fid, ['  SPOT Welding Equipment Number : 1 ;' nl]);
% A programtörzs: sorszám, utasítás, pontosvessző.
fprintf(fid, ['/MN' nl]);
for i = 1:numel(mn)
    fprintf(fid, ['%4d:%s;' nl], i, mn{i});
end
% A pozíciók: frame-ek, konfigurációs ág, X Y Z [mm], W P R [fok].
fprintf(fid, ['/POS' nl]);
for i = 1:n
    fprintf(fid, ['P[%d]{' nl], i);
    fprintf(fid, ['   GP1:' nl]);
    fprintf(fid, ['\tUF : %d, UT : %d,\t\tCONFIG : ''%s'',' nl], uf, ut, config);
    fprintf(fid, ['\tX = %s  mm,\tY = %s  mm,\tZ = %s  mm,' nl], fnum(XYZ(i,1)), fnum(XYZ(i,2)), fnum(XYZ(i,3)));
    fprintf(fid, ['\tW = %s deg,\tP = %s deg,\tR = %s deg' nl], fnum(WPR(i,1)), fnum(WPR(i,2)), fnum(WPR(i,3)));
    fprintf(fid, ['};' nl]);
end
fprintf(fid, ['/END' nl]);
fclose(fid);
end
