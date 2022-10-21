 % 
% BUGGY SDL grammar in TXL
%
% J.Vaucher 14 nov. 1994
% NOTE: This grammar caused the MAC TXLdb7.7a3-68k program to 
%  freeze up
% - with the missing main, TXL went farther and again froze
%  (note there are NON-terminals without [ & ] and some
%   undefined not-terminals )


comments
  /*  */
end comments

keys
 AND BLOCK BOOLEAN CALL CHANNEL CHAR CHARACTER CHARSTRING CONSTANTS
 CREATE DCL DECISION ELSE ENDBLOCK ENDCHANNEL ENDDECISION ENDMACRO
 ENDNEWTYPE ENDPROCEDURE ENDPROCESS ENDSYNTYPE ENDSYSTEM ENV FALSE
 FIRST FIX FLOAT FPAR FROM IN 'IN/OUT' INPUT INTEGER JOIN LAST
 LENGTH LITERALS MACRO MACRODEFINITION MKSTRING MOD NATURAL NEWTYPE
 NEXTSTATE NOT NOW OR OUTPUT PID PROCEDURE PROCESS REAL REM RESET
 RETURN SENDER SELF SET SIGNAL SUBSTRING START STATE STOP STRUCT
 SYNONYM SYNTYPE SYSTEM TASK TIMER TO TRUE XOR VERDICT VIA WITH
end keys

compounds
  '::=  '///
end compounds


define program
    [blockdef]
end define

define blockdef
   BLOCK [blockname] ;      [NL][IN]
      [repeat data_def]    [EX]
   ENDBLOCK [opt id] ;      [NL][NL]
end define

define data_def
   newtype_def
 | syntype_def
end define

define syntype_def
 SYNTYPE syntype_name '=' typeSpec
  [syntype_range]
 ENDSYNTYPE [opt syntype_name]
end define

define syntype_range
   CONSTANTS [range_condition]
end define

define range_condition
 [number] : [number]
end define

% -----Names ---------

define typeSpec
   [id]
end define

define syntype_name
   [id]
end define

define blockname
   [id]
end define

rule main
    match [program]
	P [program]
end rule
