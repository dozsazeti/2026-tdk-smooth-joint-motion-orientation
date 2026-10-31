function XYZ = kor_xyz(ang, cfg)
% KOR_XYZ  A körpálya pontjai a robot világ-koordinátarendszerében (UF 0).
%   XYZ = kor_xyz(ang, cfg)
%   ang [N x 1]  pályaszög [fok] (0° = a középponttól +X irányban,
%                pozitív irány = az óramutatóval ellentétes, felülről nézve)
%   XYZ [N x 3]  a TCP helye [mm]
%   A kör vízszintes síkban fekszik, középpontja cfg.cella.nullpont,
%   sugara cfg.geom.radius.
ang = ang(:);
XYZ = cfg.cella.nullpont + [cfg.geom.radius*cosd(ang), cfg.geom.radius*sind(ang), zeros(numel(ang), 1)];
end
