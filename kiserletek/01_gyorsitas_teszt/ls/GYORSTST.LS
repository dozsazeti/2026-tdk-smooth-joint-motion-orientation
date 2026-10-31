/PROG  GYORSTST
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "GYORSITAS TESZT";
PROG_SIZE	= 0;
CREATE		= DATE 26-10-23  TIME 19:49:35;
MODIFIED	= DATE 26-10-23  TIME 19:49:35;
FILE_NAME	= ;
VERSION		= 0;
LINE_COUNT	= 46;
MEMORY_SIZE	= 0;
PROTECT		= READ_WRITE;
TCD:  STACK_SIZE	= 0,
      TASK_PRIORITY	= 50,
      TIME_SLICE	= 0,
      BUSY_LAMP_OFF	= 0,
      ABORT_REQUEST	= 0,
      PAUSE_REQUEST	= 0;
DEFAULT_GROUP	= 1,*,*,*,*;
CONTROL_CODE	= 00000000 00000000;
/APPL
  SPOT : TRUE ; 
  SPOT Welding Equipment Number : 1 ;
/MN
   1: F[1]=(ON)    ;
   2: WAIT .10(sec)    ;
   3: RUN LOG_ALL    ;
   4: WAIT .20(sec)    ;
   5: !kiindulas: alapallas    ;
   6:J P[1] 100% FINE    ;
   7: WAIT 1.00(sec)    ;
   8: !J1 -90 fok    ;
   9:J P[2] 100% FINE    ;
  10: WAIT 1.00(sec)    ;
  11: !J1 +180 fok    ;
  12:J P[3] 100% FINE    ;
  13: WAIT 1.00(sec)    ;
  14: !J1 -90 fok    ;
  15:J P[4] 100% FINE    ;
  16: WAIT 1.00(sec)    ;
  17: !J4 -90 fok    ;
  18:J P[5] 100% FINE    ;
  19: WAIT 1.00(sec)    ;
  20: !J4 +180 fok    ;
  21:J P[6] 100% FINE    ;
  22: WAIT 1.00(sec)    ;
  23: !J4 -90 fok    ;
  24:J P[7] 100% FINE    ;
  25: WAIT 1.00(sec)    ;
  26: !J6 -180 fok    ;
  27:J P[8] 100% FINE    ;
  28: WAIT 1.00(sec)    ;
  29: !J6 +360 fok    ;
  30:J P[9] 100% FINE    ;
  31: WAIT 1.00(sec)    ;
  32: !J6 -180 fok    ;
  33:J P[10] 100% FINE    ;
  34: WAIT 1.00(sec)    ;
  35: !J5 -90 fok    ;
  36:J P[11] 100% FINE    ;
  37: WAIT 1.00(sec)    ;
  38: !J5 +180 fok    ;
  39:J P[12] 100% FINE    ;
  40: WAIT 1.00(sec)    ;
  41: !J5 -90 fok    ;
  42:J P[13] 100% FINE    ;
  43: WAIT 1.00(sec)    ;
  44: WAIT .10(sec)    ;
  45: F[1]=(OFF)    ;
  46: WAIT .50(sec)    ;
/POS
P[1]{
   GP1:
	UF : 0, UT : 3,	
	J1=      .000 deg,	J2=      .000 deg,	J3=      .000 deg,
	J4=      .000 deg,	J5=      .000 deg,	J6=      .000 deg
};
P[2]{
   GP1:
	UF : 0, UT : 3,	
	J1=   -90.000 deg,	J2=      .000 deg,	J3=      .000 deg,
	J4=      .000 deg,	J5=      .000 deg,	J6=      .000 deg
};
P[3]{
   GP1:
	UF : 0, UT : 3,	
	J1=    90.000 deg,	J2=      .000 deg,	J3=      .000 deg,
	J4=      .000 deg,	J5=      .000 deg,	J6=      .000 deg
};
P[4]{
   GP1:
	UF : 0, UT : 3,	
	J1=      .000 deg,	J2=      .000 deg,	J3=      .000 deg,
	J4=      .000 deg,	J5=      .000 deg,	J6=      .000 deg
};
P[5]{
   GP1:
	UF : 0, UT : 3,	
	J1=      .000 deg,	J2=      .000 deg,	J3=      .000 deg,
	J4=   -90.000 deg,	J5=      .000 deg,	J6=      .000 deg
};
P[6]{
   GP1:
	UF : 0, UT : 3,	
	J1=      .000 deg,	J2=      .000 deg,	J3=      .000 deg,
	J4=    90.000 deg,	J5=      .000 deg,	J6=      .000 deg
};
P[7]{
   GP1:
	UF : 0, UT : 3,	
	J1=      .000 deg,	J2=      .000 deg,	J3=      .000 deg,
	J4=      .000 deg,	J5=      .000 deg,	J6=      .000 deg
};
P[8]{
   GP1:
	UF : 0, UT : 3,	
	J1=      .000 deg,	J2=      .000 deg,	J3=      .000 deg,
	J4=      .000 deg,	J5=      .000 deg,	J6=  -180.000 deg
};
P[9]{
   GP1:
	UF : 0, UT : 3,	
	J1=      .000 deg,	J2=      .000 deg,	J3=      .000 deg,
	J4=      .000 deg,	J5=      .000 deg,	J6=   180.000 deg
};
P[10]{
   GP1:
	UF : 0, UT : 3,	
	J1=      .000 deg,	J2=      .000 deg,	J3=      .000 deg,
	J4=      .000 deg,	J5=      .000 deg,	J6=      .000 deg
};
P[11]{
   GP1:
	UF : 0, UT : 3,	
	J1=      .000 deg,	J2=      .000 deg,	J3=      .000 deg,
	J4=      .000 deg,	J5=   -90.000 deg,	J6=      .000 deg
};
P[12]{
   GP1:
	UF : 0, UT : 3,	
	J1=      .000 deg,	J2=      .000 deg,	J3=      .000 deg,
	J4=      .000 deg,	J5=    90.000 deg,	J6=      .000 deg
};
P[13]{
   GP1:
	UF : 0, UT : 3,	
	J1=      .000 deg,	J2=      .000 deg,	J3=      .000 deg,
	J4=      .000 deg,	J5=      .000 deg,	J6=      .000 deg
};
/END
