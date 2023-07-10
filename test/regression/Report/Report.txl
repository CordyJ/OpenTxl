% Report.Txl
% Written by Medha Shukla Sarkar, June 1996
% Copyright 1996, Legasys Corp.


% Generate report which describes the structure of the system bridge from the
% factbase

% v1.1. June 1996

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LS COBOL standard grammar, fact and annotation overrides                    %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include "LSCobol.grm"
include "RenamingOverrides.grm"


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                              Local Overrides                               %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

define program
        [repeat prolog_fact]
end define

% These should really be defined in the file RenamingOverrides.Grammar
% They are presently defined in BridgeFacts.Grammar and I have
% copied them here. --- M.S.S. 6/6/96

define prolog_fact
        [comp_fact]
    |   [move_fact]
    |   [movelit_fact]
    |   [date_fact]
    |   [done_flag]
    |   [name_fact]
    |   [program_fact]
    |   [value_fact] 
    |   [pic_fact]
    |   [global_fact] 
    |   [usage_fact]
    |   [redefine_fact]
    |   [redefined_by_fact]
    |   [rename_fact]
    |   [field_fact]
        % The above two facts are nonterminals so that they can be extracted
        % directly using the TXL '^' function.
    |   [call_fact]
    |   [arg_fact]
    |   [entry_fact]
    |   [param_fact]
    |   [docall_fact]
    |   [alias_fact]
    |   [arglit_fact]
    |   [field_size_fact]
    |   [level_01_fact]
    |   [level_77_fact]
    |   [occurs_fact]
    |   [file_fact]             % M.S.S. 15/5/96
    |   [filerec_fact]          % M.S.S. 16/5/96
    |   [sysfile_fact]          % M.S.S. 16/5/96
    |   [conflict_fact]         %% T.D. 16/5/96
    |   [no_trans_fact]         %% T.D. 18/5/96
    |   [change_pic_fact]       %% T.D. 18/5/96
        |   [fileRecTypeFact]  %% M.S.S. 7/6/96
        |   [isReportFact]  %% M.S.S. 7/6/96
        |   [transTagFact]  %% M.S.S. 7/6/96
        |   [transCasefact] %% M.S.S. 7/6/96
end define

define fileRecTypeFact
    [NL] [NL] '$ 'FileRecType '( [fileName], [recordName] ') '$ [EX]
end define

define fileName
    [newNameClause]
end define

define recordName
    [newNameClause]
end define

% The following facts are not defined anywhere yet. They should eventually
% be defined in the file RenamingOverrides.Grammar.

define isReportFact
    [NL] [NL] '$ IsReport '( [fileName] ') '$ [EX]
end define

define transTagFact
    [NL] [NL] '$ 'TransactionTag '( [recordName], [fieldName] ') '$ [EX]
end define

define fieldName
    [newNameClause]
end define

define transCasefact
    [NL] [NL] '$ 'TransactionCase '( [fieldName], [value], [newNameOrPath] ') '$ [EX]
end define

define value
    [literal]
  | [number]
end define

define newNameOrPath
    [newNameClause]
  | [path]
end define

define path
   '{'{ [repeat id] '}'}
end define


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                  main                                  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function main

        construct RuleVer [stringlit]
                _ [+ "Report v1.1 (June 6, 1996)"]
                  [print]

    replace [program]
                Facts [repeat prolog_fact]

        construct Msg [stringlit]
                _ [message "Summary Section:"]
                                
% To print out files that do not contain 2Y Dates

        construct FileFacts [repeat file_fact]
            _ [^ Facts] % extract all the file facts from the factbase
                
        construct File_Names [repeat newNameClause]
            _ [^ FileFacts] % extract filenames from the file facts
                
                
% to find all files with YY in them

        construct Files2Y [repeat newNameClause]
                _ [add2YFiles Facts each File_Names]
                  [message "Files that contain 2Y Date"]
                  [print]
                
% to find the report files from the YY files

        construct ReportFiles [repeat newNameClause]
                _ [addReport Facts each Files2Y]
                  [message "Report Files"]
                  [print]
                  
% to find the YY files which are not report files
 
        construct NoReportFiles [repeat newNameClause]
                _ [removeFiles ReportFiles each Files2Y]
                  [message "Files that are not Reports"]
                  [print]
                  
% to process the transaction facts on NoReportFiles
        
                construct TransFiles [repeat newNameClause]
                        _ [checkTransFiles Facts each NoReportFiles]
                        

% files that do not have YY dates in them

        construct No2YFiles [ repeat newNameClause]
            _ [removeFiles Files2Y each File_Names]
                  [message "Files that do not contain 2Y Dates"]
                  [print]
                 
    construct Empty [repeat prolog_fact]
         % Empty
                  
        by
        
           Empty
                
end function

function only2Y DateFact [date_fact]

        deconstruct DateFact
                '$ 'Date '( N1 [newNameClause], "YY", Num [number], HowDate [how_date] ') '$
                
        replace [repeat date_fact]
                DFact [repeat date_fact]
                
        by
                DateFact
                DFact

end function

function add2YFiles Facts [repeat prolog_fact] File_Name [newNameClause]

        replace [repeat newNameClause]
                Files [repeat newNameClause]
                
        %extract all the date facts from the factbase

    construct Alldatefacts [repeat date_fact]
                _ [^ Facts]
                
% to extract those dates with YY in them

        construct Dates2Y [repeat date_fact]
                _ [only2Y each Alldatefacts]
                
% to extract all the filerec facts from the factbase
        construct Allfilerecfacts [repeat filerec_fact]
                _ [^ Facts]
                
% to extract all filerec names from the file rec facts corresponding 
% to the filename
        construct FileRecNames [repeat newNameClause]
                _ [findRecNames File_Name each Allfilerecfacts]

% extract all filerectype facts from the factbase
        construct Allrectypefacts [repeat fileRecTypeFact]
                _ [^ Facts]

% extract relevant record names from the filerectypefacts               
        construct RecTypeNames [repeat newNameClause]
                _ [findRecTypes Allrectypefacts each FileRecNames]
                
        construct AllrecNames [repeat newNameClause]
                FileRecNames [. RecTypeNames]
                
% check the dates which correspond to the rectypenames
        construct Flag [id]
                'No
                
        construct New_Flag [id]
                Flag [checkDateandRecnames Dates2Y each AllrecNames]
                
        
        where not Flag [= New_Flag]
        
        by
        
                File_Name Files
                
end function

function findRecNames FileName [newNameClause] filerecfact [filerec_fact]
        
        deconstruct filerecfact
                '$ 'FileRec '(FileName, recordname [newNameClause]') '$
                
        replace [repeat newNameClause]
                N [repeat newNameClause]
        by
                recordname N
        
end function

function findRecTypes RecTypeFacts [repeat fileRecTypeFact] RecName [newNameClause]

        replace [repeat newNameClause]
                N [repeat newNameClause]
                
        construct N1 [repeat newNameClause]
                N [findeachRecType RecName each RecTypeFacts]
                
        by
                N1 
                
end function

function findeachRecType RecName [newNameClause] RecTypeFact [fileRecTypeFact]

        deconstruct RecName
                R1 [repeat id+]
                
        deconstruct RecTypeFact
                '$ 'FileRecType '(N1 [newNameClause], N2 [newNameClause]') '$
                
        deconstruct * [repeat id+] N1
                R1
                
        replace [repeat newNameClause]
                N3 [repeat newNameClause]
        by
                N2 N3
                
end function

function checkDateandRecnames Dates2Y [repeat date_fact] RecTypeName [newNameClause]

        replace [id]
                F [id]
        by
                F [checkDate RecTypeName each Dates2Y]
                
end function

function checkDate RecTypeName [newNameClause] Date2Y [date_fact] 

        deconstruct * [repeat id+] RecTypeName
                F1 [repeat id+]
                
        deconstruct * [repeat id+] Date2Y
                F1
                
        replace [id]
                'No
        by
                'Yes
                
end function

function addReport Facts [repeat prolog_fact] FileName [newNameClause]
        
        replace [repeat newNameClause]
                Files [repeat newNameClause]
                
% extract all report facts from the database
        construct ReportFacts [repeat isReportFact]
                _ [^ Facts]
                
        construct Flag [id]
                'No
                
        construct New_Flag [id]
                Flag [checkReport FileName each ReportFacts]
                
        where not Flag [= New_Flag]
        
        by
                FileName
                Files
                
end function

function checkReport FileName [newNameClause] ReportFact [isReportFact]

        deconstruct ReportFact
                '$ 'IsReport '(FileName') '$
                
        replace [id]
                'No
        by
                'Yes
end function


function removeFiles File2Y [repeat newNameClause] FileName [newNameClause]

        replace [repeat newNameClause]
                N [repeat newNameClause]
                
        construct Flag [id]
                'No
                
        construct Flag1 [id]
                'Yes
                
        construct New_Flag [id]
                Flag1 [checkFile2Y FileName each File2Y]
                
        where not Flag [= New_Flag]
        
        by
        
                FileName N
                
end function

function checkFile2Y FileName [newNameClause] File2Y [newNameClause]

        deconstruct FileName
                File2Y
                
        replace [id]
                F [id]
        by
                'No
                
end function

function checkTransFiles Facts [repeat prolog_fact] File_Name [newNameClause]

        replace [repeat newNameClause]
                Files [repeat newNameClause]
                
% to extract all the filerec facts from the factbase
        construct Allfilerecfacts [repeat filerec_fact]
                _ [^ Facts]
                
% to extract all filerec names from the file rec facts corresponding 
% to the filename
        construct FileRecNames [repeat newNameClause]
                _ [findRecNames File_Name each Allfilerecfacts]

% extract all filerectype facts from the factbase
        construct Allrectypefacts [repeat fileRecTypeFact]
                _ [^ Facts]

% extract relevant record names from the filerectypefacts               
        construct RecTypeNames [repeat newNameClause]
                _ [findRecTypes Allrectypefacts each FileRecNames]
                
        construct AllrecNames [repeat newNameClause]
                FileRecNames [. RecTypeNames]
                
% extract all transtag facts

        construct Alltranstagfacts [repeat transTagFact]
                _ [^ Facts]
                
% to extract those transtag facts which have rec names in them

        construct TransTag [repeat transTagFact]
                _ [findTransTag Alltranstagfacts each AllrecNames]
                  [message "transtag that match the recordnames"]
                  [print]
                  
% extract fieldnames from the transtag facts

        construct fieldnames [repeat fieldName]
                _ [findfieldnames TransTag]
                  [message "fieldName"]
                  [print]
                  
% extract all transcase facts

        construct Alltranscasefacts [repeat transCasefact]
                _ [^ Facts]
                
% to extract those transtag facts which have rec names in them

        construct TransCase [repeat transCasefact]
                _ [findTransCase Alltranscasefacts each fieldnames]
                  [message "transcase that match the fieldnames"]
                  [print]
                
% check the dates which correspond to the rectypenames
%       construct Flag [id]
        %       'No
                
%       construct New_Flag [id]
%               Flag [checkDateandRecnames Dates2Y each AllrecNames]
                
        
%       where not Flag [= New_Flag]
        
        by
        
                File_Name Files
                
end function

function findTransCase Alltranscasefacts [repeat transCasefact] FieldName [fieldName]

        replace [repeat transCasefact]
                Transtagfacts [repeat transCasefact]
                                
                construct transfiles [repeat transCasefact]
                        _ [checkTransCase FieldName each Alltranscasefacts]

                construct alltfacts [repeat transCasefact]
                        Transtagfacts [. transfiles]
        by
        
                alltfacts
                
end function

function checkTransCase FieldName [fieldName] Transfact [transCasefact]

        deconstruct Transfact
                '$ 'TransactionCase '(FieldName, value1 [value], nncPath [newNameOrPath] ') '$
                
        replace [repeat transCasefact]
          Tfacts [repeat transCasefact]
          
         by
                Transfact
                Tfacts
                
end function

function findTransTag Alltranstagfacts [repeat transTagFact] RecName [newNameClause]

        replace [repeat transTagFact]
                Transtagfacts [repeat transTagFact]
                                
                construct transfiles [repeat transTagFact]
                        _ [checkTransRec RecName each Alltranstagfacts]

                construct alltfacts [repeat transTagFact]
                        Transtagfacts [. transfiles]
        by
        
                alltfacts
                
end function

function checkTransRec RecName [newNameClause] Transfact [transTagFact]

        deconstruct Transfact
                '$ 'TransactionTag '(RecName, field [fieldName]') '$
                
        replace [repeat transTagFact]
          Tfacts [repeat transTagFact]
          
         by
                Transfact
                Tfacts
                
end function

function findfieldnames TransTag [repeat transTagFact]

        replace [repeat fieldName]
                fields [repeat fieldName]
                
        by
                fields [getfieldname each TransTag]
                
end function

function getfieldname Transtag [transTagFact]

        deconstruct * [fieldName] Transtag
                FieldName [fieldName]
                
        replace [repeat fieldName]
                Fields [repeat fieldName]
                
        by
                FieldName
                Fields
                
end function
