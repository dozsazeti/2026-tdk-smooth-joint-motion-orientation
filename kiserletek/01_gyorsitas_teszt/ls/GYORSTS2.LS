/PROG  GYORSTS2
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "GYORSITAS TESZT";
PROG_SIZE	= 0;
CREATE		= DATE 26-10-23  TIME 19:49:35;
MODIFIED	= DATE 26-10-23  TIME 19:49:35;
FILE_NAME	= ;
VERSION		= 0;
LINE_COUNT	= 28;
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
   8: !J2 -30 fok    ;
   9:J P[2] 100% FINE    ;
  10: WAIT 1.00(sec)    ;
  11: !J2 +70 fok    ;
  12:J P[3] 100% FINE    ;
  13: WAIT 1.00(sec)    ;
  14: !J2 -40 fok    ;
  15:J P[4] 100% FINE    ;
  16: WAIT 1.00(sec)    ;
  17: !J3 -40 fok    ;
  18:J P[5] 100% FINE    ;
  19: WAIT 1.00(sec)    ;
  20: !J3 +80 fok    ;
  21:J P[6] 100% FINE    ;
  22: WAIT 1.00(sec)    ;
  23: !J3 -40 fok    ;
  24:J P[7] 100% FINE    ;
  25: WAIT 1.00(sec)    ;
  26: WAIT .10(sec)    ;
  27: F[1]=(OFF)    ;
  28: WAIT .50(sec)    ;
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
	J1=      .000 deg,	J2=   -30.000 deg,	J3=      .000 deg,
	J4=      .000 deg,	J5=      .000 deg,	J6=      .000 deg
};
P[3]{
   GP1:
	UF : 0, UT : 3,	
	J1=      .000 deg,	J2=    40.000 deg,	J3=      .000 deg,
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
	J1=      .000 deg,	J2=      .000 deg,	J3=   -40.000 deg,
	J4=      .000 deg,	J5=      .000 deg,	J6=      .000 deg
};
P[6]{
   GP1:
	UF : 0, UT : 3,	
	J1=      .000 deg,	J2=      .000 deg,	J3=    40.000 deg,
	J4=      .000 deg,	J5=      .000 deg,	J6=      .000 deg
};
P[7]{
   GP1:
	UF : 0, UT : 3,	
	J1=      .000 deg,	J2=      .000 deg,	J3=      .000 deg,
	J4=      .000 deg,	J5=      .000 deg,	J6=      .000 deg
};
/END
