Szerszámorientáció optimalizálása zárt körpályán (FANUC R-2000iB/210F, Fourier-GA)
==================================================================================

Ez a tároló egy TDK-dolgozathoz készült teljes számítási folyamatot tartalmaz. A vizsgált feladatban egy FANUC R-2000iB/210F ipari robot (R-30iA vezérlő) szerszámpontja (TCP) egy rögzített, vízszintes körpályán halad, a szerszám orientációja (W, P, R) viszont mindhárom szögben szabadon választható egy tartományon belül. A cél az, hogy az orientációt úgy válasszuk meg a teljes kör mentén, hogy a csuklómozgás a lehető legsimább legyen.

Az orientáció változását a teljes zárt pályán három Fourier-sor írja le, ezek együtthatóit genetikus algoritmus (GA) keresi. A GA nem hívja közvetlenül a robotvezérlőt, hanem egy előre kiszámolt inverz kinematikai rácsból interpolál, amelyet a FANUC RoboGuide számolt ki egy KAREL programmal. A simasági költség a csuklószögek ívhossz szerinti első, második és harmadik deriváltjának súlyozott négyzetösszege. Az optimalizált orientációból LS program készül, amelyet a RoboGuide-ban lefuttatunk, a csuklószögeket egy KAREL naplózó program rögzíti, és a futásból ugyanazzal a költségfüggvénnyel számoljuk ki a javulást, mint amit a GA becsült.

A dolgozat eredményei ennek a mappának a tartalmából, a lent leírt sorrendű futtatással készültek.

------------------------------------------------------------------------

Tartalom
========

1. Követelmények
2. Mappaszerkezet
3. Jelölések és koordináta-rendszerek
4. A módszer röviden
5. Futtatási leírás lépésről lépésre
6. Kísérletek
7. Beállítások (kozos/config.m)
8. Kimenetek összefoglalása
9. A függvénytár (kozos/lib)
10. Megjegyzések a reprodukálhatósághoz

------------------------------------------------------------------------

Követelmények
=============

- MATLAB R2020a vagy újabb (a kód R2026a alatt készült). Külön toolbox nem kell. A szkriptek Live Script (.mlx) formátumúak, a függvények sima .m fájlok.
- FANUC RoboGuide egy R-2000iB/210F robottal és R-30iA vezérlővel felépített munkacellával, a valós cellának megfelelő szerszámmal (UT 3) és világ-koordinátarendszerrel (UF 0).
- KAREL fordító (a RoboGuide része), a .txt kiterjesztéssel tárolt KAREL forrásokat .kl néven kell lefordítani.

A szkripteket a MATLAB-ban megnyitva a Run gombbal kell futtatni. Az útvonalakat minden szkript maga állítja be: megkeresi a kozos\config.m fájlt a saját helyétől felfelé haladva, ezért a mappa bárhová másolható, abszolút elérési utat sehol nem kell átírni. Ha a szkript ezt mégsem találja (pl. mert nem a Live Editorból fut), a MATLAB aktuális mappáját a szkript mappájára kell állítani.

Mappaszerkezet
==============

A számozott mappák a futtatás sorrendjét követik.

    .
    ├── README.txt                     ez a leírás
    ├── kozos/                         minden lépés közös része
    │   ├── config.m                   AZ ÖSSZES BEÁLLÍTÁS egy helyen
    │   ├── lib/                       a függvénytár (költség, GA, rács, LS-írás, log-beolvasás)
    │   └── karel/
    │       ├── LOG_ALL.txt            naplózó KAREL program (ezt kell a vezérlőre tölteni)
    │       └── LOG_ALL_magyarazott.txt  ugyanez soronként elmagyarázva (dokumentáció)
    ├── 00_korpalya/
    │   └── kor_generalas.mlx          az alapeset (Alap) LS programja
    ├── 01_racs/
    │   ├── r1_cand_generalas.mlx      jelöltfájl a RoboGuide IK-hoz (CAND.TXT, CAND.csv)
    │   ├── karel/ik_batch.txt         RoboGuide IK KAREL program
    │   └── r2_cand2_osszefuz.mlx      CAND.csv + JOINTS.CSV -> CAND2.csv (a GA bemenete)
    ├── 02_ga_durva/
    │   ├── g1_ga_durva.mlx            Fourier-GA a durva rácson (12 kulcspont, H = 2)
    │   ├── g2_abra_ga.mlx             ábrák a GA eredményeiből
    │   ├── g3_elemzes_ivhossz.mlx     a költség felbontása a kör mentén
    │   ├── g4_ls_generalas.mlx        LS programok a RoboGuide-futáshoz (ALAP_L, OPT1_L)
    │   ├── g5_fourier_gorbek.mlx      Fourier-együtthatók, görbék, harmonikusok
    │   └── g6_fourier_3d.mlx          3D-s megjelenítés (Δ-tér, karima pályája)
    ├── 03_kor2_finom/
    │   ├── k1_cand_generalas.mlx      finom jelöltfájl az opt1 körül (24 kulcspont)
    │   ├── k2_ga_finom.mlx            Fourier-GA a finom rácson (H = 3)
    │   └── k3_ls_generalas.mlx        OPT2_L LS program
    ├── 04_roboguide_osszevetes/
    │   └── osszehasonlitas.mlx        a RoboGuide-futások kiértékelése (ívhossz és idő szerint)
    └── kiserletek/                    kiegészítő vizsgálatok (a fő futás mappáit csak olvassák)
        ├── 01_gyorsitas_teszt/        csuklókorlátok mérése (a költség csuklósúlyaihoz)
        ├── 02_modell_pontossag/       a GA-modell pontossága (rács-interpoláció, spline, végrehajtás)
        ├── 03_fourier_harmonikusok/   1. kör H = 3, 2. kör H = 4
        ├── 04_cnt/                    a CNT hatása (1, 25, 50, 75, 100)
        ├── 05_allando_wpr/            a legjobb állandó orientáció
        ├── 06_kulcspont_visszateszt/  GA-interpoláció vs. pontos IK a kulcspontokban
        ├── 07_spline_mintavetel/      a spline mintavételezése: 5° (eredeti), 3°, 1°
        ├── 08_harmonikus_tartomany/   több harmonikus, harmonikusonként szűkített tartománnyal
        ├── 09_ga_konvergencia/        a durva GA konvergenciája generációnként, mind a 8 indításra
        ├── 10_ido_ivhossz/            ívhossz és idő szerinti kiértékelés megfeleltetése csuklónként
        └── 12_harmonikus_konvergencia/  harmonikusszám növelése meleg indítással (H = 2..5)
    valos_futtatas/                    kipróbálás valós roboton, rezgésméréssel (lásd lent)
        ├── 01_rezges/                 a rezgésméréshez készült első változat
        └── 02_rezges_athelyezett/     ugyanaz az eljárás áthelyezett körön, a mérés kiértékelésével

A futtatás közben a lépések maguk hozzák létre a kimeneti almappákat (roboguide_be, roboguide_vissza, eredmenyek_korlat, ls, roboguide_log).

Jelölések és koordináta-rendszerek
==================================

- UF 0 a robot világ-koordinátarendszere, a kör középpontja ebben adott (cfg.cella.nullpont).
- UT 3 a szerszám tool frame-je (cfg.tool.*), eltolása a karimához képest (0, 0, 145) mm, elforgatás nélkül. A robot ennek a TCP-jét vezeti a körön.
- Alapállás a lefelé néző szerszám, UT 3-mal W, P, R = 180°, 0°, −90° (cfg.tool.alap_wpr).
- dW, dP, dR az orientáció eltérése az alapálláshoz képest, vagyis a robotnak szóló W, P, R szögek változása. A GA ezt keresi, és a rácsfájlokban (CAND.csv, CAND2.csv) valamint a GA kimeneteiben a W, P, R oszlop mindig ezt az eltérést jelenti. A robotnak szóló érték csak a CAND.TXT-be és az LS programokba kerül, ezt a kozos/lib/delta2tcp.m számolja (W, P, R = alapállás + eltérés, a W a ±180°-nál átfordul, pl. 183° → −177°).
- Pályaszög (th) 0° a kör középpontjától +X irányban. Az LS programok −10°-tól 370°-ig 1°-onként tartalmaznak pontot, így a mért kör (0–360°) előtt és után van rá- és kifutás.
- Ívhossz szerinti derivált (dq/ds, d²q/ds², d³q/ds³, s = R·th) geometriai mennyiség, mértékegysége °/mm, °/mm², °/mm³. Nem azonos a csukló sebességével, gyorsulásával és jerkjével, ezeket a neveket a kód csak az idő szerinti deriváltakra használja.
- Konfigurációs ág a teljes pályán rögzített ('N U T, 0, 0, 0'), csak a póz változik.

A módszer röviden
=================

1. Rács (01_racs). A kör 12 kulcspontjában (30°-onként) minden dW, dP, dR ∈ [−45°, 45°] kombinációra 3°-os lépéssel (31³ = 29 791 jelölt kulcspontonként) a RoboGuide kiszámolja a J1..J6 csuklószögeket. A rossz rácspontokat (sikertelen IK, |J5| < 5° csuklószingularitás közelében, J4/J6 átfordulás a szomszédhoz képest) a beolvasás megjelöli.
2. Durva GA (02_ga_durva). A dW(th), dP(th), dR(th) görbéket csatornánként egy H = 2 harmonikusos Fourier-sor írja le (15 paraméter). Egy paraméterkészlet kiértékelésekor a görbét a kulcspontokban mintavételezzük, a csuklószögeket a rácsból trilineáris interpolációval kapjuk, a kulcspontokra periodikus köbös spline-t illesztünk, 72 pontban (5°-onként) mintavételezzük, és véges differenciával képezzük az ívhossz szerinti 1., 2., 3. deriváltat. A költség ezek négyzetösszegéből adódik (λ = 0,2 / 0,3 / 0,5), a csuklók súlyát a mért csuklókorlátok adják, és úgy van normálva, hogy az Alap költsége pontosan 1 legyen. A rossz rácspontok közelsége és a rácson kívüli érték büntetést kap.
3. Finom GA (03_kor2_finom). A durva kör legjobb megoldása (opt1) körül 24 kulcsponton (15°-onként) egy ±10°-os, 1°-os lépésű rács készül, és egy H = 3 harmonikusos GA a középgörbe együtthatóihoz képesti eltérést keresi.
4. Ellenőrzés RoboGuide-ban (04_roboguide_osszevetes). Az Alap, az opt1 és az opt2 LS programját a RoboGuide-ban lefuttatjuk, a LOG_ALL naplózza a csuklószögeket, és a naplóból ugyanazzal a költségfüggvénnyel számolunk. Így a GA által becsült és a RoboGuide-ban mért javulás közvetlenül összevethető. Kiegészítésként a szkript ugyanezt idő szerint is kiszámolja, és megvizsgálja, mennyire követi az idő szerinti költség az ívhossz szerintit.

Futtatási leírás lépésről lépésre
=================================

0. Előkészítés (egyszer)
------------------------

1. A kozos/config.m-ben ellenőrizni kell a cella adatait. A kör középpontja (cfg.cella.nullpont), a sugár (cfg.geom.radius) és a szerszám (cfg.tool.num, cfg.tool.xyz, cfg.tool.wpr) a RoboGuide-cella (és valós futtatásnál a vezérlő) értékeivel egyezzen meg. Ha ezek közül bármelyik változik, a 01-es lépéstől mindent újra kell futtatni.
2. A RoboGuide munkacellában a Tool Frame 3 (UT 3) értékeit a cfg.tool.xyz / cfg.tool.wpr szerint kell beállítani, mégpedig a szerszám UTOOL fülén (ez a vezérlő tool frame-je). A General fülön megadott hely csak a CAD-modell elhelyezése, a mozgásra és az IK-ra nincs hatása. Mérés előtt UF 0 / UT 3 legyen aktív.
3. A KAREL programok lefordítása és betöltése a virtuális vezérlőre:
   - kozos/karel/LOG_ALL.txt → mentés LOG_ALL.kl néven, fordítás, betöltés. Erre minden olyan LS programnak szüksége van, amelyben RUN LOG_ALL szerepel.
   - 01_racs/karel/ik_batch.txt → mentés ik_batch.kl néven, fordítás, betöltés.
   A KAREL forrásokban a kommentek szándékosan ékezet nélküliek, mert a fordító ANSI kódolást vár.

1. Alapeset (00_korpalya)
-------------------------

- Futtatás: 00_korpalya/kor_generalas.mlx
- Kimenet: 00_korpalya/ls/ALAP.LS, ALAP_pontok.csv
- Az ALAP.LS betölthető a RoboGuide-ba (és a valós vezérlőre), ezzel ellenőrizhető, hogy a körpálya az alapállással elérhető, és a cella beállításai rendben vannak. A konzolra kiírt TCP- és karimamagasság a pendanton is összevethető.

2. Inverz kinematikai rács (01_racs)
------------------------------------

1. Futtatás: 01_racs/r1_cand_generalas.mlx
   Kimenet: 01_racs/roboguide_be/CAND.TXT (357 492 sor) és CAND.csv.
2. A CAND.TXT-t a virtuális vezérlő UD1: eszközére kell másolni (a RoboGuide munkacellában a robot UD1 mappájába).
3. A RoboGuide-ban le kell futtatni az ik_batch programot (pl. egy CALL IK_BATCH sort tartalmazó TP programmal), UF 0 / UT 3 mellett. A program soronként kiszámolja a csuklószögeket, és a végén kiírja az elérhető és a nem elérhető jelöltek számát.
4. Az eredményként kapott UD1:JOINTS.CSV-t a 01_racs/roboguide_vissza/ mappába kell másolni.
5. Futtatás: 01_racs/r2_cand2_osszefuz.mlx
   Kimenet: 01_racs/CAND2.csv (a GA bemenete). A konzolra kiírt Alap-csuklószögekben a J5 ne legyen 0 közelében.

3. Durva GA (02_ga_durva)
-------------------------

1. g1_ga_durva.mlx a Fourier-GA (8 független indítás, a gépi teljesítménytől függően néhány perc). Kimenet: 02_ga_durva/eredmenyek_korlat/01_ga/ (opt_osszesites.csv, opt<i>_LS_WPR.csv, opt<i>_kulcspontok.csv, ALAP_WPR000.csv).
2. g2_abra_ga.mlx ábrák (eredmenyek_korlat/abrak/ga_*.png).
3. g3_elemzes_ivhossz.mlx a költség felbontása a kör mentén (eredmenyek_korlat/02_elemzes/, abrak/el_*.png). A szkript ellenőrzi, hogy a felbontás összege megegyezik a GA által kiírt költséggel.
4. g4_ls_generalas.mlx LS programok a méréshez: 02_ga_durva/ls/ALAP_L.LS és OPT1_L.LS. Mindkettőben be van kapcsolva a naplózás (F[1], RUN LOG_ALL).
5. RoboGuide-futás (UF 0 / UT 3):
   - ALAP_L lefuttatása, majd a UD1:K1.CSV mentése 04_roboguide_osszevetes/roboguide_log/alap.CSV néven,
   - OPT1_L lefuttatása, majd a UD1:K1.CSV mentése .../roboguide_log/opt1.CSV néven.
   A K1.CSV-t a LOG_ALL minden futásnál felülírja, ezért a két futás között át kell másolni.
6. g5_fourier_gorbek.mlx és g6_fourier_3d.mlx kiegészítő ábrák (eredmenyek_korlat/01_ga/fourier/). A g5 utolsó ábrája csak akkor készül el, ha a 03-as lépés már lefutott, ezért a g5 a 4. lépés után újra futtatható.

4. Finom GA (03_kor2_finom)
---------------------------

1. k1_cand_generalas.mlx a finom jelöltfájl az opt1 körül. Kimenet: 03_kor2_finom/roboguide_be/CAND.TXT (222 288 sor) és CAND.csv.
2. RoboGuide IK ugyanúgy, mint a 2. lépésben (CAND.TXT → UD1:, ik_batch, a JOINTS.CSV a 03_kor2_finom/roboguide_vissza/ mappába).
3. k2_ga_finom.mlx a Fourier-GA a finom rácson. Kimenet: 03_kor2_finom/eredmenyek_korlat/ (k2_osszesites.csv, jelolt<i>_LS_WPR.csv, jelolt<i>_kulcspontok.csv, szektorok.csv, abrak/). Az Alap és az opt1 költségét a szkript a 24 kulcspontos modellben újra kiszámolja, így a jelöltek ugyanazon a modellen hasonlíthatók össze velük.
4. k3_ls_generalas.mlx az OPT2_L LS program (03_kor2_finom/ls/OPT2_L.LS) a kiválasztott jelöltből (alapból jelölt1).
5. RoboGuide-futás, majd a UD1:K1.CSV mentése 04_roboguide_osszevetes/roboguide_log/opt2.CSV néven.

5. Kiértékelés (04_roboguide_osszevetes)
----------------------------------------

- Futtatás: 04_roboguide_osszevetes/osszehasonlitas.mlx
- Bemenet: roboguide_log/alap.CSV (kötelező), opt1.CSV, opt2.CSV (amelyik megvan).
- Kimenet: 04_roboguide_osszevetes/eredmenyek_korlat/
  - osszeg_csuklonkent.csv négyzetösszegek és változások csuklónként, deriváltrendenként,
  - szektorok.csv mért és GA-becsült változás 30°-os szektoronként,
  - pontonkent_<futás>.csv, hozzajarulas_csuklonkent.csv, futasok.txt,
  - ido_vs_ivhossz_*.csv az ívhossz és az idő szerinti deriválás összevetése,
  - m_1..m_8_*.png ábrák.

A konzolon megjelenik minden futás költsége az Alaphoz viszonyítva (ívhossz szerint, 5°-os mintavétellel), deriváltrendenként és szektoronként, a GA-becsléssel együtt.

Kísérletek
==========

A kísérletek a fő futás mappáit (01_racs … 04_roboguide_osszevetes) csak olvassák, a saját kimenetüket a saját mappájukba írják. Mindegyik a kozos/config.m-ből indul, a 03-as és a 08-as kísérlet ezt egy saját config fájllal (kozos/config_kis03.m, kozos/config_kis08.m) egészíti ki, amely csak a vizsgált beállítást írja felül. A kísérleti LS programokban mindig benne van a naplózás (RUN LOG_ALL). A RoboGuide IK minden kísérletnél ugyanaz az ik_batch program, mint a fő futásban (UF 0 / UT 3).

| Kísérlet | Mikor futtatható |
|---|---|
| 01_gyorsitas_teszt | bármikor, a fő futástól független |
| 02_modell_pontossag | a fő futás 02, 03 és 04 lépése után (opt1, opt2 és a logok kellenek) |
| 03_fourier_harmonikusok | a fő futás után (saját GA-k, saját 2. köri IK) |
| 04_cnt | a 02_ga_durva opt1-e után |
| 05_allando_wpr | a 01_racs és 02_ga_durva után (a k2-höz a fő futás logjai is kellenek) |
| 06_kulcspont_visszateszt | a 01_racs és 02_ga_durva után |
| 07_spline_mintavetel | a 02_ga_durva után (a mérési részhez a 04 logjai is kellenek) |
| 08_harmonikus_tartomany | a 01_racs után (a fő futás opt1-ével vet össze) |
| 09_ga_konvergencia | a 01_racs után (az ellenőrzéshez a 02_ga_durva eredménye is kell) |
| 10_ido_ivhossz | a 04_roboguide_osszevetes logjai után (az ismételhetőséghez a 04_cnt CNT100-as logjai is) |

01: csuklókorlátok mérése
-------------------------

A költségben a hat csukló közös skálára hozásához (cfg.cost.norm = 'korlat') csuklónkénti sebesség-, gyorsulás- és jerk-korlát kell (cfg.cost.lim). Ezeket egycsuklós, 100%-os mozgásokból határoztuk meg.

1. karel/PARAM_LEK.txt → PARAM_LEK.kl, fordítás és futtatás a vezérlőn. Kiolvassa a csuklónkénti $JNTVELLIM (és a $ACCEL_TIME1/2) rendszerváltozókat a UD1:PARAM.CSV fájlba. A tárolóban lévő PARAM.CSV a RoboGuide-ból kiolvasott érték.
2. t1_ls_generalas.mlx megírja a GYORSTST.LS (J1, J4, J6, J5) és GYORSTS2.LS (J2, J3) tesztprogramot. Egyszerre mindig csak egy csukló mozog, J típusú mozgással, 100%-on.
3. A két programot a RoboGuide-ban 100%-os override mellett kell lefuttatni (a valós cellában a megfogó- és CNC-modellel, ütközésvizsgálattal), a naplókat log/gyors.CSV és log/gyors2.CSV néven menteni.
4. t2_kiertekeles.mlx kikeresi az egycsuklós mozgásokat, és mindegyikre meghatározza a legnagyobb sebességet, gyorsulást és jerket. A deriváltakat egyenletes időrácsra vett, Savitzky-Golay szűrővel simított csuklószögből számolja, mert a log időbélyegei néhány ms-ot ingadoznak. A sebességkorlát a vezérlő $JNTVELLIM értéke, a gyorsulás- és jerk-korlát a mért legnagyobb érték. Kimenet: eredmenyek/csuklokorlatok.csv, mozgasok.csv, mozgásonként egy ábra, és a konzolon a config.m-be beírandó cfg.cost.lim sorok. Ha ezek eltérnek a configban lévőktől, a configot frissíteni kell, és a 02-es lépéstől újra kell futtatni.

02: a GA-modell pontossága
--------------------------

A GA-becslés két egyszerűsítésen alapul, mégpedig a kulcspontokban a rácsból interpolált csuklószögön és a kulcspontok közötti spline-on, a RoboGuide-futásban ehhez jön a végrehajtás. A kísérlet ezt négy szinten választja szét (A GA-modell, B pontos IK a kulcspontokban + spline, C pontos IK mind a 72 pontban, D RoboGuide-futás).

1. m1_ik_bemenet.mlx → roboguide_be/CAND.TXT (Alap, opt1, opt2, 5°-onként).
2. RoboGuide IK (ik_batch) → roboguide_vissza/JOINTS.CSV.
3. m2_kiertekeles.mlx → eredmenyek/koltseg_szintek.csv, csuklo_hibak.csv, ábrák.
4. m3_racs_kihagyasos.mlx (RoboGuide nélkül) kihagyásos teszt a durva rácson (6°-os ritkított rácsból interpolálja a kihagyott pontokat), és a GA kulcsponti becslésének összevetése a futás logjával.

03: a Fourier-harmonikusok száma
--------------------------------

Tájékozódó próba, nem része a végleges futásnak (a régi szerszámbeállítással készült, a v10-ben nem futott újra).

Ugyanaz a két kör, mint a fő futásban, de az 1. körben H = 3, a 2. körben H = 4 harmonikussal (beállítás: kozos/config_kis03.m). A durva rács és az Alap log közös a fő futással.

1. k1_ga_durva.mlx → kor1/eredmenyek/01_ga/
2. k2_ls_opt1.mlx → ls/OPT1_H3.LS → RoboGuide-futás → roboguide_log/opt1_h3.CSV
3. k3_cand_kor2.mlx → kor2/roboguide_be/CAND.TXT → RoboGuide IK → kor2/roboguide_vissza/JOINTS.CSV
4. k4_ga_finom.mlx → kor2/eredmenyek/
5. k5_ls_opt2.mlx → ls/OPT2_H4.LS → RoboGuide-futás → roboguide_log/opt2_h4.CSV
6. k6_osszevetes.mlx → osszevetes/ (fő futás H2/H3 vs. kísérlet H3/H4, GA-becslés és RoboGuide-ban mért érték)

04: a CNT hatása
----------------

Az Alap és a fő futás opt1-e CNT = 1, 25, 50, 75, 100 mellett, minden más a cfg.ls szerint. A GA nem fut újra, mert a CNT nincs a modellben. A viszonyítás az Alap a fő futás CNT-jével (cfg.ls.cnt).

1. k1_ls_generalas.mlx → ls/ALAPC001..ALAPC100.LS, OPT1C001..OPT1C100.LS
2. RoboGuide: mind a 10 program, a logok roboguide_log/alap_c001.CSV … opt1_c100.CSV néven.
3. k2_kiertekeles.mlx költség (ívhossz és idő szerint), kör ideje, pályasebesség, pályaeltérés a programozott pontoktól.
4. k3_kiegeszito_abrak.mlx kiegészítő ábrák (ehhez mind a 10 log kell).

05: a legjobb állandó orientáció
--------------------------------

Állandó dW, dP, dR a kör mentén, teljes kereséssel a durva rácson (konst1), illetve az opt1 Fourier-görbéinek átlaga (konst2).

1. k1_allando_racs.mlx → eredmenyek/, ls/KONST1.LS, KONST2.LS
2. RoboGuide: KONST1, KONST2 → roboguide_log/konst1.CSV, konst2.CSV
3. k2_kiertekeles.mlx (az Alap, opt1, opt2 a fő futás logjaiból)

06: kulcsponti visszateszt
--------------------------

Mennyire tér el a GA által használt, rácsból interpolált csuklószög a RoboGuide pontos IK-jától pontosan a GA kulcspontjaiban, és a környezetükben (rácspont-kontroll, cellaközép, véletlen pontok)?

1. k1_cand_kulcspontok.mlx → roboguide_be/CAND.TXT
2. RoboGuide IK (ik_batch) → roboguide_vissza/JOINTS.CSV
3. k2_kiertekeles.mlx → eredmenyek/hibak_soronkent.csv, hibak_osszesites.csv (típusonként RMS és max eltérés), koltseg_kulcspont.csv (megoldásonként a költség interpolált és pontos kulcsponti csuklószögekkel), v1_hiba_tipusonkent.png, v2_opt1_kulcspontok.png

07: a spline mintavételezése
----------------------------

Elég-e, hogy a GA a kulcspontokra illesztett köbös spline-t 5°-onként (72 pontban) értékeli ki? A s1_spline_teszt.mlx ugyanazt a költséget 5°, 3° és 1° mintavétellel számolja ki. A modellben (Alap és opt1–opt5 a 02_ga_durva kulcspontjaiból) kétféle spline-nal: a kódban használt, 3-3 ponttal körbetoldott spline()-nal (kozos/lib/deriv_ops.m) és egy valódi periodikus köbös spline-nal (a szkript végén lévő helyi függvény). A mérésben a fő futás naplóiból (alap, opt1, opt2), ivhossz_derivalt szerint. Az osztók minden lépésnél az Alapból adódnak, így az Alap költsége mindig 1. A szkript 5°-nál ellenőrzi, hogy a kódbeli spline pontosan a GA-költséget adja vissza. Nincs RoboGuide-lépés.

Kimenet (eredmenyek/): spline_modell.csv, spline_meres.csv, futasok.txt, s_1_koltseg.png (a javulás a lépés függvényében), s_2_d3_opt1.png (az opt1 J5 harmadik deriváltja a kör mentén).

08: harmonikusok száma és tartománya
------------------------------------

Tájékozódó próba, nem része a végleges futásnak (a régi szerszámbeállítással készült, a v10-ben nem futott újra).

Ad-e jobb megoldást a durva GA, ha több harmonikust engedünk, de a magasabb harmonikusok tartományát harmonikusonként szűkítjük? Beállítás: kozos/config_kis08.m (H, bound_a0, bound_h, indulás az Alapból vagy a fő futás opt1-éből). Futtatás: k1_ga_harmonikus.mlx, a kimenet futásonként külön mappába kerül (eredmenyek/H.._a.._tartomanyok/, benne beallitasok.txt). A rács a kísérlet saját másolata (racs/CAND2.csv vagy racs/CAND2.zip), ha nincs ilyen, a fő futás 01_racs/CAND2.csv-je. Az eredmény GA-becslés, RoboGuide-futáshoz a 02_ga_durva/g4_ls_generalas mintájára LS kell.

09: a GA konvergenciája
-----------------------

Hogyan javul a durva GA legjobb megoldása a generációk során, mikor áll le az egyes indítás, és mennyire térnek el egymástól a független indítások? A k1_ga_konvergencia.mlx ugyanazt a GA-t futtatja, mint a 02_ga_durva/g1_ga_durva (ugyanaz a rács, költség, beállítás és seed), de generációnként elmenti a legjobb fitneszt, a populáció mediánját és kvartiliseit, valamint a mutáció szórását. A GA-lépés a szkript végén lévő ga_run_naplo függvény, amely soronként megegyezik a kozos/lib/ga_run.m-mel, így azonos seeddel azonos eredményt ad. A szkript ezt a végén ellenőrzi az opt_osszesites.csv-vel. A fő futás eredményeit nem írja felül. Nincs RoboGuide-lépés.

Kimenet (eredmenyek/): konvergencia.csv (generációnként), inditasok.csv (indításonként a generációk száma és a végső költség), c_1_konvergencia.png (a legjobb megoldás javulása a generációk függvényében, mind a 8 indításra), c_2_populacio.png (a legjobb indítás populációja és a mutáció szórása).

10: ívhossz és idő szerinti kiértékelés
---------------------------------------

Mennyire feleltethető meg egymásnak az ívhossz szerinti (GA) és az idő szerinti (sebesség, gyorsulás, rántás) kiértékelés? Az i1_ido_ivhossz.mlx a fő futás naplóiból (alap, opt1, opt2) mindkét módszerrel kiszámolja a deriváltakat 5°, 10° és 15° lépéssel, csuklónként és deriváltrendenként a pontonkénti korrelációt, a költséget és a javulást, valamint a költség pálya menti eloszlását. Az ismételhetőséghez a 04_cnt CNT100-as Alap és opt1 naplóját is beolvassa (ugyanaz a program, másik futás). Nincs RoboGuide-lépés.

Kimenet (eredmenyek/): korrelacio.csv, javulas.csv, palya_r.csv, ismetles.csv, i_1_d1.png … i_3_d3.png (mind a 6 csukló deriváltjai, ívhossz · v^k és idő szerint), i_4_korrelacio.png (korreláció a lépésköz függvényében), i_5_szoras_d3.png, i_6_javulas.png, i_7_palya.png, i_8_ismetles.png (két külön futás összevetése).

Beállítások (kozos/config.m)
============================

Minden beállítás ebben az egy fájlban van, a szkriptekben nincs rögzített érték. A legfontosabbak:

| Csoport | Mező | Érték | Jelentés |
|---|---|---|---|
| Cella | cfg.cella.nullpont | [900 −1800 −164] mm | a kör középpontja (UF 0) |
| | cfg.geom.radius | 300 mm | a kör sugara |
| Szerszám | cfg.tool.num / xyz / wpr | 3 / [0 0 145] mm / [0 0 0]° | a vezérlő Tool Frame értékei |
| | cfg.tool.alap_wpr | [180 0 −90]° | alapállás (dW, dP, dR = 0) |
| LS | cfg.ls.seb, cfg.ls.cnt | 100 mm/s, CNT100 | pályasebesség, simítás |
| | cfg.ls.config | 'N U T, 0, 0, 0' | rögzített konfigurációs ág |
| Költség | cfg.cost.lambda | [0,2 0,3 0,5] | súlyok: dq/ds, d²q/ds², d³q/ds³ |
| | cfg.cost.norm | 'korlat' | csuklósúlyok a mért korlátokból |
| | cfg.cost.lim.v / .a / .j | lásd a fájlt | csuklókorlátok (kísérlet 01) |
| Durva rács | cfg.coarse.key_int / range / step | 30° / ±45° / 3° | 12 kulcspont, 31³ jelölt |
| | cfg.coarse.harmonics | 2 | 15 Fourier-paraméter |
| GA | cfg.ga.* | 8 indítás, 150 egyed, ≤300 generáció | lásd a fájl kommentjeit |
| Finom kör | cfg.k2.key_ang / range / step / H | 15°-onként / ±10° / 1° / 3 | 24 kulcspont, 21³ jelölt, 21 paraméter |

A fájl minden sorához részletes komment tartozik.

Valós futtatás (valos_futtatas)
===============================

Az eljárás valós ipari roboton is kipróbálásra került. A mérés nem a fő futás körén, hanem egy áthelyezett körön készült (középpont X, Y, Z = 900, −1200, 400 mm), ezért a 02_rezges_athelyezett mappában a teljes eljárás ehhez a körhöz újra lefut: saját rács (RoboGuide IK), majd az 1. kör Fourier-GA-ja hat súlyozással (Alap, 0.2 / 0.3 / 0.5, 1 / 0 / 0, 0 / 1 / 0, 0 / 0 / 1, 0 / 0.5 / 0.5). A beállítás a kozos/config_athelyezett.m, a számoló függvények a fő futás kozos/lib mappájából jönnek.

A lépések sorrendje és a kimenetek a 02_rezges_athelyezett/README.txt-ben vannak (a0..a5: rács, GA, LS programok, a6: a rezgésmérés kiértékelése, a7: Alap és l235 összevetése, a8: a RoboGuide-ban mért költség). A rezgésmérő szenzor nyers fájljai a méretük miatt nincsenek a tárolóban, a mérések hozzárendelése (program, ismétlés, szenzorirány) a mert_adatok/.../sorrend.txt-ben található.

Kimenetek összefoglalása
========================

| Lépés | Fájl | Tartalom |
|---|---|---|
| 01 | 01_racs/CAND2.csv | minden jelölt: eltérés, robotnak szóló W, P, R, J1..J6, status |
| 02 | 02_ga_durva/eredmenyek_korlat/01_ga/opt_osszesites.csv | Alap és opt1..optN költsége, változás az Alaphoz, Fourier-együtthatók |
| 02 | .../01_ga/opt<i>_LS_WPR.csv | dW, dP, dR fokonként −10..370° |
| 02 | .../02_elemzes/szektorok.csv | GA-becsült hozzájárulás szektoronként |
| 02 | 02_ga_durva/ls/ALAP_L.LS, OPT1_L.LS | a RoboGuide-ban futtatott programok |
| 03 | 03_kor2_finom/eredmenyek_korlat/k2_osszesites.csv | Alap, opt1 (24 kulcspontos modell), jelöltek |
| 03 | 03_kor2_finom/ls/OPT2_L.LS | a RoboGuide-ban futtatott program |
| 04 | 04_roboguide_osszevetes/eredmenyek_korlat/.csv, .png | a RoboGuide-futásokból számolt költség és ábrák |

Az összesítő táblákban a koltseg oszlop az Alaphoz normált költség (Alap = 1), a vs_alap_pct ennek százalékos változása, a d1_pct, d2_pct, d3_pct az egyes deriváltrendek változása.

A függvénytár (kozos/lib)
=========================

| Függvény | Feladat |
|---|---|
| config.m (a kozos mappában) | minden beállítás |
| beallit.m | a GA-lépések közös indítása (config, mappák, rács ellenőrzése) |
| kor_xyz.m, delta2tcp.m, wpr2rot.m, rot2wpr.m | körpálya pontjai, eltérés → robotnak szóló W, P, R, forgatási mátrixok |
| ls_kor.m, ls_iras.m, fnum.m | LS program írása a közös sablonnal |
| cand_beolvas.m, k2_beolvas.m | a RoboGuide IK rács beolvasása, rossz rácspontok jelölése |
| wpr_joints.m | trilineáris interpoláció a rácsban (csuklószögek tetszőleges dW, dP, dR-hez) |
| fourier_eval.m, p_atvalt.m, kozepgorbe.m | Fourier-görbék kiértékelése, átírása, a 2. kör középgörbéje |
| deriv_ops.m, negyzetosszeg.m | ívhossz szerinti deriváló operátorok, négyzetösszegek |
| koltseg_osztok.m, koltseg.m | normáló osztók és a költségfüggvény |
| lokalis_hozzajarulas.m | a költség felbontása a kör mentén |
| ga_run.m, ga_fitness.m, ga_fitness_k2.m, seed_rng.m | valós kódolású GA és a célfüggvények |
| log_beolvas.m, ivhossz_derivalt.m, ido_derivalt.m, ido_ivhossz_vizsgalat.m | RoboGuide-naplók beolvasása, ívhossz és idő szerinti deriválás, összevetés |
| csv_iras.m, csv_olvas.m, forgat.m | segédfüggvények |

Minden függvény elején részletes leírás van a bemenetekről, a kimenetekről és a működésről.

Megjegyzések a reprodukálhatósághoz
===================================

- A GA véletlenszám-generátora rögzített seeddel indul (cfg.ga.seed, az indítások seed, seed+1, ...), ezért ugyanazon a MATLAB-verzión a GA eredménye számjegyre megismételhető.
- A GA költsége becslés (rács-interpoláció és spline a kulcspontok között), a RoboGuide-naplóból számolt érték az ellenőrzés. A kettő a kiírásokban mindig külön szerepel.
- A RoboGuide-ból kapott napló szimulációs adat, nem valós robotos mérés.
- A nagy, újragenerálható köztes fájlok (CAND.TXT, CAND.csv, CAND2.csv) a .gitignore miatt nem kerülnek a tárolóba, ezeket az r1, r2 és k1 szkriptek bármikor újra előállítják. A RoboGuide IK eredménye (JOINTS.CSV) és a futások naplói viszont benne vannak, így az r1 és r2 újrafuttatása után a 02-es lépéstől minden számítás RoboGuide nélkül is megismételhető.
