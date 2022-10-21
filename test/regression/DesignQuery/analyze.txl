% Design factbase analyzer
% J.R. Cordy, 21.12.94, Revised 9.1.95
% Copyright 1994,1995 by James R. Cordy - all rights reserved

#pragma -raw -w 120

define program
	[repeat fact]
end define

define fact
    	[predicate] ( [list entity] ) . [NL] [!]
end define

define entity
	[repeat id] [id] [opt number]	
end define

define predicate
	[entitypredicate]
    |	[usepredicate] [opt 'indirect]
    |	contains
    |	exports
    |	[importpredicate]
    |	[argumentpredicate]
end define

define entitypredicate
	constant | pervasive_constant | [parameterpredicate]
    |	variable | 'function | procedure | module | program | library
end define

define parameterpredicate
	const_parameter | var_parameter
end define

define usepredicate
    	[readpredicate]
    |	[writepredicate]
end define

define readpredicate
	read_ref | calls
end define

define writepredicate
	write_ref | var_argument_ref 
end define

define importpredicate
	imports | imports_var
end define

define argumentpredicate
	const_argument | var_argument
end define

% include "TxlExternals"


function main
    replace [program]
	FB [repeat fact]
    construct EntityId [id]
	'enterident
	%% _  [message '"Please input the entity you are interested in:"] 
	 %% [get]
    construct EntityPredicates [repeat fact]
	_ [entityInfo FB FB EntityId 1] 
    by
	% nada!
	EntityPredicates
end function

function nl
    construct NL [id]
	_ [message ""]
    match * [id]
	NONE_I_KNOW
end function

function entityInfo FB [repeat fact] WorkingFB [repeat fact] EntityId [id] SN [number]
    deconstruct * [repeat fact] WorkingFB
	EntityKind [entitypredicate] ( Context [repeat id] EntityId N [opt number] ).
	RestFB [repeat fact]
    construct SNstring [stringlit]
	_ [quote SN]
    construct EntityInfoMessage [stringlit]
	SNstring [+ '". '"] [quote EntityId] [+ '"' is a "] [quote EntityKind] [print]
    construct Entity [entity]
	Context EntityId N
    construct EntityFact [fact]
	EntityKind ( Entity ).
    construct SNP1 [number]
	SN [+ 1]

    replace [repeat fact]
	EntityFactsSoFar [repeat fact]
    by
	EntityFactsSoFar [. EntityFact]

			 % Order of these subrules is important!
			 % Later ones depend on earlier ones.

			 [nl] [containmentInfo FB Entity]
			 [nl] [importsInfo FB FB Entity]
			 [nl] [exportsInfo FB FB Entity]
			 [nl] [containsInfo FB FB Entity]

			 [nl] [calledInfo FB FB Entity]
			 [nl] [readInfo FB FB Entity]
			 [nl] [writtenInfo FB FB Entity]

			 [nl] [calledIndirectlyInfo FB Entity]
			 [nl] [readIndirectlyInfo FB Entity]
			 [nl] [writtenIndirectlyInfo FB Entity]

			 [nl] [callsInfo FB FB Entity]
			 [nl] [readsInfo FB FB Entity]
			 [nl] [writesInfo FB FB Entity]

			 [nl] [callsIndirectlyInfo FB Entity]
			 [nl] [readsIndirectlyInfo FB Entity]
			 [nl] [writesIndirectlyInfo FB Entity]

			 [nl] [valueParameterInfo FB FB FB Entity]
			 [nl] [referenceParameterInfo FB FB FB Entity]

			 [nl] [entityInfo FB RestFB EntityId SNP1] 
end function

function containmentInfo FB [repeat fact] Entity [entity]
    deconstruct * [fact] FB
        contains ( ContainingEntity [entity], Entity ).
    deconstruct ContainingEntity
	ContainingContext [repeat id] ContainingId [id]
    deconstruct * [fact] FB
	ContainingEntityKind [entitypredicate] ( ContainingEntity ).
    construct ContainmentMessage [stringlit]
        _ [+ '"    contained in "] [quote ContainingEntityKind] 
	  [+ '" '"] [quote ContainingId] [+ '"'"]
	  [immediateContainmentInfo FB ContainingEntity] [print]

    replace * [repeat fact]
        % tail
    by  
	contains ( ContainingEntity, Entity ).
end function

function calledInfo FB [repeat fact] WorkingFB [repeat fact] Entity [entity]
    deconstruct * [repeat fact] WorkingFB
	calls ( CallingEntity [entity], Entity ). 
	RestFB [repeat fact]
    deconstruct CallingEntity
	CallingContext [repeat id] CallingId [id]
    deconstruct * [fact] FB
	CallingEntityKind [entitypredicate] ( CallingEntity ).
    construct CalledMessage [stringlit]
        _ [+ '"    called by "] [quote CallingEntityKind] 
	  [+ '" '"] [quote CallingId] [+ '"'"]
	  [immediateContainmentInfo FB CallingEntity] [print]
    construct CalledFact [repeat fact]
	calls ( CallingEntity, Entity ).

    replace * [repeat fact]
	% tail
    by  
        CalledFact [calledInfo FB RestFB Entity]
end function

function readInfo FB [repeat fact] WorkingFB [repeat fact] Entity [entity]
    deconstruct * [repeat fact] WorkingFB
	read_ref ( ReadingEntity [entity], Entity ). 
	RestFB [repeat fact]
    deconstruct ReadingEntity
	ReadingContext [repeat id] ReadingId [id]
    deconstruct * [fact] FB
	ReadingEntityKind [entitypredicate] ( ReadingEntity ).
    construct ReadByMessage [stringlit]
        _ [+ '"    read by "] [quote ReadingEntityKind] 
	  [+ '" '"] [quote ReadingId] [+ '"'"]
	  [immediateContainmentInfo FB ReadingEntity] [print]
    construct ReadByFact [repeat fact]
	read_ref ( ReadingEntity, Entity ).

    replace * [repeat fact]
	% tail
    by  
        ReadByFact [readInfo FB RestFB Entity]
end function

function writtenInfo FB [repeat fact] WorkingFB [repeat fact] Entity [entity]
    deconstruct * [repeat fact] WorkingFB
	WriteKind [writepredicate] ( WritingEntity [entity], Entity ). 
	RestFB [repeat fact]
    deconstruct WritingEntity
	WritingContext [repeat id] WritingId [id]
    deconstruct * [fact] FB
	WritingEntityKind [entitypredicate] ( WritingEntity ).
    construct WrittenByMessage [stringlit]
        _ [+ '"    written by "] [quote WritingEntityKind] 
	  [+ '" '"] [quote WritingId] [+ '"'"]
	  [immediateContainmentInfo FB WritingEntity] [print]
    construct WrittenByFact [repeat fact]
	WriteKind ( WritingEntity, Entity ).

    replace * [repeat fact]
	% tail
    by  
        WrittenByFact [writtenInfo FB RestFB Entity]
end function

function readsInfo FB [repeat fact] WorkingFB [repeat fact] Entity [entity]
    deconstruct * [repeat fact] WorkingFB
	read_ref ( Entity, ReadEntity [entity] ). 
	RestFB [repeat fact]
    deconstruct ReadEntity
	ReadContext [repeat id] ReadId [id]
    deconstruct * [fact] FB
	ReadEntityKind [entitypredicate] ( ReadEntity ).
    construct ReadsMessage [stringlit]
        _ [+ '"    reads "] [quote ReadEntityKind] 
	  [+ '" '"] [quote ReadId] [+ '"'"]
	  [immediateContainmentInfo FB ReadEntity] [print]
    construct ReadsFact [repeat fact]
	read_ref ( Entity, ReadEntity ).

    replace * [repeat fact]
	% tail
    by  
        ReadsFact [readsInfo FB RestFB Entity]
end function

function callsInfo FB [repeat fact] WorkingFB [repeat fact] Entity [entity]
    deconstruct * [repeat fact] WorkingFB
	calls ( Entity, CalledEntity [entity] ). 
	RestFB [repeat fact]
    deconstruct CalledEntity
	CalledContext [repeat id] CalledId [id]
    deconstruct * [fact] FB
	CalledEntityKind [entitypredicate] ( CalledEntity ).
    construct CallsMessage [stringlit]
        _ [+ '"    calls "] [quote CalledEntityKind] 
	  [+ '" '"] [quote CalledId] [+ '"'"]
	  [immediateContainmentInfo FB CalledEntity] [print]
    construct CallsFact [repeat fact]
	calls ( Entity, CalledEntity ).

    replace * [repeat fact]
	% tail
    by  
        CallsFact [callsInfo FB RestFB Entity]
end function

function writesInfo FB [repeat fact] WorkingFB [repeat fact] Entity [entity]
    deconstruct * [repeat fact] WorkingFB
	WriteKind [writepredicate] ( Entity, WrittenEntity [entity] ). 
	RestFB [repeat fact]
    deconstruct WrittenEntity
	WrittenContext [repeat id] WrittenId [id]
    deconstruct * [fact] FB
	WrittenEntityKind [entitypredicate] ( WrittenEntity ).
    construct WritesMessage [stringlit]
        _ [+ '"    writes "] [quote WrittenEntityKind] 
	  [+ '" '"] [quote WrittenId] [+ '"'"]
	  [immediateContainmentInfo FB WrittenEntity] [print]
    construct WritesFact [repeat fact]
	WriteKind ( Entity, WrittenEntity ).

    replace * [repeat fact]
	% tail
    by  
        WritesFact [writesInfo FB RestFB Entity]
end function

function containsInfo FB [repeat fact] WorkingFB [repeat fact] Entity [entity]
    deconstruct * [repeat fact] WorkingFB
	contains ( Entity, ContainedEntity [entity] ). 
	RestFB [repeat fact]
    deconstruct ContainedEntity
	ContainedContext [repeat id] ContainedId [id]
    deconstruct * [fact] FB
	ContainedEntityKind [entitypredicate] ( ContainedEntity ).
    construct ContainsMessage [stringlit]
        _ [+ '"    contains "] [quote ContainedEntityKind] 
	  [+ '" '"] [quote ContainedId] [+ '"'"] [print]
    construct ContainsFact [repeat fact]
	contains ( Entity, ContainedEntity ).

    replace * [repeat fact]
	% tail
    by  
        ContainsFact [containsInfo FB RestFB Entity]
end function

function importsInfo FB [repeat fact] WorkingFB [repeat fact] Entity [entity]
    deconstruct * [repeat fact] WorkingFB
	ImportsKind [importpredicate] ( Entity, ImportedEntity [entity] ). 
	RestFB [repeat fact]
    deconstruct ImportedEntity
	ImportedContext [repeat id] ImportedId [id]
    deconstruct * [fact] FB
	ImportedEntityKind [entitypredicate] ( ImportedEntity ).
    construct ImportsMessage [stringlit]
        _ [+ '"    imports "] [quote ImportedEntityKind] 
	  [+ '" '"] [quote ImportedId] [+ '"'"] [print]
    construct ImportsFact [repeat fact]
	ImportsKind ( Entity, ImportedEntity ).

    replace * [repeat fact]
	% tail
    by  
        ImportsFact [importsInfo FB RestFB Entity]
end function

function exportsInfo FB [repeat fact] WorkingFB [repeat fact] Entity [entity]
    deconstruct * [repeat fact] WorkingFB
	exports ( Entity, ExportedEntity [entity] ). 
	RestFB [repeat fact]
    deconstruct ExportedEntity
	ExportedContext [repeat id] ExportedId [id]
    deconstruct * [fact] FB
	ExportedEntityKind [entitypredicate] ( ExportedEntity ).
    construct ExportsMessage [stringlit]
        _ [+ '"    exports "] [quote ExportedEntityKind] 
	  [+ '" '"] [quote ExportedId] [+ '"'"] [print]
    construct ExportsFact [repeat fact]
	exports ( Entity, ExportedEntity ).

    replace * [repeat fact]
	% tail
    by  
        ExportsFact [exportsInfo FB RestFB Entity]
end function

function calledIndirectlyInfo FB [repeat fact] Entity [entity] 
    construct CALLS [usepredicate]
	calls
    replace * [repeat fact] 
	calls ( CallingEntity [entity], Entity ). 
	RestOfFacts [repeat fact]
    by  
	calls ( CallingEntity, Entity ). 
        RestOfFacts [indirectUsedInfo CALLS '"called" FB FB CallingEntity Entity]
		    [calledIndirectlyInfo FB Entity]
end function

function readIndirectlyInfo FB [repeat fact] Entity [entity] 
    construct READ_REF [usepredicate]
	read_ref
    replace * [repeat fact] 
	read_ref ( ReadingEntity [entity], Entity ). 
	RestOfFacts [repeat fact]
    by  
	read_ref ( ReadingEntity, Entity ). 
        RestOfFacts [indirectUsedInfo READ_REF '"read" FB FB ReadingEntity Entity]
		    [readIndirectlyInfo FB Entity]
end function

function writtenIndirectlyInfo FB [repeat fact] Entity [entity] 
    construct WRITE_REF [usepredicate]
	write_ref
    replace * [repeat fact] 
	WriteKind [writepredicate] ( WritingEntity [entity], Entity ). 
	RestOfFacts [repeat fact]
    by  
	WriteKind ( WritingEntity, Entity ). 
        RestOfFacts [indirectUsedInfo WRITE_REF '"written" FB FB WritingEntity Entity]
		    [writtenIndirectlyInfo FB Entity]
end function

function indirectUsedInfo Use [usepredicate] UseDescription [stringlit]
	FB [repeat fact] WorkingFB [repeat fact] IndirectEntity [entity] Entity [entity] 
    deconstruct * [repeat fact] WorkingFB
	calls ( CallingEntity [entity], IndirectEntity ). 
	RestFB [repeat fact]
    replace [repeat fact]
	FactsSoFar [repeat fact]
    by  
        FactsSoFar [addIndirectUser Use UseDescription FB CallingEntity Entity]
		   [indirectUsedInfo Use UseDescription FB RestFB IndirectEntity Entity]
end function

function addIndirectUser Use [usepredicate] UseDescription [stringlit] 
	FB [repeat fact] CallingEntity [entity] Entity [entity]
    replace [repeat fact]
	FactsSoFar [repeat fact]
    construct IndirectUseFact [fact]
	Use indirect ( CallingEntity, Entity ). 
    where not
	FactsSoFar [contains IndirectUseFact]
    deconstruct CallingEntity
	CallerContext [repeat id] CallerId [id]
    deconstruct * [fact] FB
	CallingEntityKind [entitypredicate] ( CallingEntity ).
    construct CallerMessage [stringlit]
        _ [+ '"    "] [+ UseDescription] [+ '" indirectly by "] [quote CallingEntityKind] 
	  [+ '" '"] [quote CallerId] [+ '"'"]
	  [immediateContainmentInfo FB CallingEntity] [print]
    by
	FactsSoFar [. IndirectUseFact] 
		   [indirectUsedInfo Use UseDescription FB FB CallingEntity Entity]
end function

function callsIndirectlyInfo FB [repeat fact] Entity [entity]
    replace * [repeat fact]
	calls ( Entity, CalledEntity [entity] ). 
	RestOfFacts [repeat fact]
    by  
	calls ( Entity, CalledEntity ). 
        RestOfFacts [indirectCallInfo FB FB CalledEntity Entity]
end function

function indirectCallInfo FB [repeat fact] WorkingFB [repeat fact] 
	IndirectEntity [entity] Entity [entity]
    deconstruct * [repeat fact] WorkingFB
	calls ( IndirectEntity, CalledEntity [entity] ). 
	RestFB [repeat fact]
    replace [repeat fact]
	FactsSoFar [repeat fact]
    by  
        FactsSoFar [addIndirectCalled FB Entity CalledEntity]
		   [indirectCallInfo FB RestFB IndirectEntity Entity]
end function

function addIndirectCalled FB [repeat fact] Entity [entity] CalledEntity [entity]
    replace [repeat fact]
	FactsSoFar [repeat fact]
    construct IndirectFact [fact]
	calls indirect ( Entity, CalledEntity ). 
    where not
	FactsSoFar [contains IndirectFact]
    deconstruct CalledEntity
	CalledContext [repeat id] CalledId [id]
    deconstruct * [fact] FB
	CalledEntityKind [entitypredicate] ( CalledEntity ).
    construct CalledMessage [stringlit]
        _ [+ '"    indirectly calls "] [quote CalledEntityKind] 
	  [+ '" '"] [quote CalledId] [+ '"'"]
	  [immediateContainmentInfo FB CalledEntity] [print]
    by
	FactsSoFar [. IndirectFact] 
		   [indirectCallInfo FB FB CalledEntity Entity]
end function

% assumes that callsIndirectlyInfo is already done
function readsIndirectlyInfo FB [repeat fact] Entity [entity]
    replace * [repeat fact]
	calls Indirect [opt 'indirect] ( Entity, CalledEntity [entity] ). 
	RestOfFacts [repeat fact]
    by  
	calls Indirect ( Entity, CalledEntity ). 
        RestOfFacts [indirectReadInfo FB FB CalledEntity Entity]
		    [readsIndirectlyInfo FB Entity]
end function

function indirectReadInfo FB [repeat fact] WorkingFB [repeat fact] 
	IndirectEntity [entity] Entity [entity]
    deconstruct * [repeat fact] WorkingFB
	read_ref ( IndirectEntity, ReadEntity [entity] ). 
	RestFB [repeat fact]
    replace [repeat fact]
	FactsSoFar [repeat fact]
    by  
        FactsSoFar [addIndirectRead FB Entity ReadEntity]
		   [indirectReadInfo FB RestFB IndirectEntity Entity]
end function

function addIndirectRead FB [repeat fact] Entity [entity] ReadEntity [entity]
    replace [repeat fact]
	FactsSoFar [repeat fact]
    construct IndirectFact [fact]
	read_ref indirect ( Entity, ReadEntity ). 
    where not
	FactsSoFar [contains IndirectFact]
    deconstruct ReadEntity
	ReadContext [repeat id] ReadId [id]
    deconstruct * [fact] FB
	ReadEntityKind [entitypredicate] ( ReadEntity ).
    construct ReadMessage [stringlit]
        _ [+ '"    indirectly reads "] [quote ReadEntityKind] 
	  [+ '" '"] [quote ReadId] [+ '"'"]
	  [immediateContainmentInfo FB ReadEntity] [print]
    by
	FactsSoFar [. IndirectFact] 
end function

function writesIndirectlyInfo FB [repeat fact] Entity [entity]
    replace * [repeat fact]
	calls Indirect [opt 'indirect] ( Entity, CalledEntity [entity] ). 
	RestOfFacts [repeat fact]
    by  
	calls Indirect ( Entity, CalledEntity ). 
        RestOfFacts [indirectWriteInfo FB FB CalledEntity Entity]
		    [writesIndirectlyInfo FB Entity]
end function

function indirectWriteInfo FB [repeat fact] WorkingFB [repeat fact] 
	IndirectEntity [entity] Entity [entity]
    deconstruct * [repeat fact] WorkingFB
	WriteKind [writepredicate] ( IndirectEntity, WrittenEntity [entity] ). 
	RestFB [repeat fact]
    replace [repeat fact]
	FactsSoFar [repeat fact]
    by  
        FactsSoFar [addIndirectWrite FB Entity WrittenEntity]
		   [indirectWriteInfo FB RestFB IndirectEntity Entity]
end function

function addIndirectWrite FB [repeat fact] Entity [entity] WrittenEntity [entity]
    replace [repeat fact]
	FactsSoFar [repeat fact]
    construct IndirectFact [fact]
	write_ref indirect ( Entity, WrittenEntity ). 
    where not
	FactsSoFar [contains IndirectFact]
    deconstruct WrittenEntity
	WrittenContext [repeat id] WrittenId [id]
    deconstruct * [fact] FB
	WrittenEntityKind [entitypredicate] ( WrittenEntity ).
    construct WrittenMessage [stringlit]
        _ [+ '"    indirectly writes "] [quote WrittenEntityKind] 
	  [+ '" '"] [quote WrittenId] [+ '"'"]
	  [immediateContainmentInfo FB WrittenEntity] [print]
    by
	FactsSoFar [. IndirectFact] 
end function

function immediateContainmentInfo FB [repeat fact] Entity [entity]
    deconstruct Entity
	ContainingContext [repeat id] EntityId [id] 
    deconstruct * ContainingContext
	ContainingId [id]
    where not
	ContainingId [= 'MAIN]
    construct ContainingEntity [entity]
	ContainingContext [butlast] ContainingId
    deconstruct * [fact] FB
	ContainingEntityKind [entitypredicate] ( ContainingEntity ).
    construct ContainmentMessageString [stringlit]
        _ [+ '" of "] [quote ContainingEntityKind] 
	  [+ '" '"] [quote ContainingId] [+ '"'"]
    replace [stringlit]
	MessageSoFar [stringlit]
    by
	MessageSoFar [+ ContainmentMessageString]
end function

function butlast
    replace * [repeat id]
	_ [id]
    by
	% nada
end function

function referenceParameterInfo FB [repeat fact] ArgumentsFB [repeat fact] WorkingFB [repeat fact] Entity [entity]
    deconstruct * [repeat fact] WorkingFB
	contains ( Entity, FormalEntity [entity] ). 
	RestWorkingFB [repeat fact]
    deconstruct * [fact] FB
	ParameterKind [parameterpredicate] ( FormalEntity ). 
    replace [repeat fact]
	ParameterFactsSoFar [repeat fact]
    by
        ParameterFactsSoFar
	    [varArgumentInfo FB FB FormalEntity Entity]
	    [referenceParameterInfo FB FB RestWorkingFB Entity]
end function

function varArgumentInfo FB [repeat fact] WorkingFB [repeat fact] 
	FormalEntity [entity] Entity [entity]
    deconstruct * [repeat fact] WorkingFB
	var_argument ( ArgumentEntity [entity], FormalEntity ). 
	RestWorkingFB [repeat fact]
    replace [repeat fact]
	ParameterFactsSoFar [repeat fact]
    by  
        ParameterFactsSoFar [addVarArgument FB ArgumentEntity FormalEntity Entity]
			    [varArgumentInfo FB RestWorkingFB FormalEntity Entity]
end function

function addVarArgument FB [repeat fact] ArgumentEntity [entity] FormalEntity [entity] Entity [entity]
    replace [repeat fact]
	FactsSoFar [repeat fact]
    construct ArgumentFact [fact]
	var_argument ( ArgumentEntity, FormalEntity ).
    where not
	FactsSoFar [contains ArgumentFact]
    deconstruct ArgumentEntity
	ArgumentContext [repeat id] ArgumentId [id]
    deconstruct * [fact] FB
	ArgumentEntityKind [entitypredicate] ( ArgumentEntity ).
    construct ArgumentMessage [stringlit]
        _ [+ '"    writes as reference parameter "] [quote ArgumentEntityKind] 
	  [+ '" '"] [quote ArgumentId] [+ '"'"]
	  [immediateContainmentInfo FB ArgumentEntity] [print]
    construct IndirectFact [fact]
	write_ref indirect ( Entity, ArgumentEntity ).
    by
	FactsSoFar [. ArgumentFact] 
		   [. IndirectFact]
end function

function valueParameterInfo FB [repeat fact] ArgumentsFB [repeat fact] WorkingFB [repeat fact] Entity [entity]
    deconstruct * [repeat fact] WorkingFB
	contains ( Entity, FormalEntity [entity] ). 
	RestWorkingFB [repeat fact]
    deconstruct * [fact] FB
	ParameterKind [parameterpredicate] ( FormalEntity ). 
    replace [repeat fact]
	ParameterFactsSoFar [repeat fact]
    by
        ParameterFactsSoFar
	    [constArgumentInfo FB FB FormalEntity Entity]
	    [valueParameterInfo FB FB RestWorkingFB Entity]
end function

function constArgumentInfo FB [repeat fact] WorkingFB [repeat fact] 
	FormalEntity [entity] Entity [entity]
    deconstruct * [repeat fact] WorkingFB
	const_argument ( ArgumentEntity [entity], FormalEntity ). 
	RestWorkingFB [repeat fact]
    replace [repeat fact]
	ParameterFactsSoFar [repeat fact]
    by  
        ParameterFactsSoFar [addConstArgument FB ArgumentEntity FormalEntity Entity]
			    [constArgumentInfo FB RestWorkingFB FormalEntity Entity]
end function

function addConstArgument FB [repeat fact] ArgumentEntity [entity] FormalEntity [entity] Entity [entity]
    replace [repeat fact]
	FactsSoFar [repeat fact]
    construct ArgumentFact [fact]
	const_argument ( ArgumentEntity, FormalEntity ). 
    where not
	FactsSoFar [contains ArgumentFact]
    deconstruct ArgumentEntity
	ArgumentContext [repeat id] ArgumentId [id]
    deconstruct * [fact] FB
	ArgumentEntityKind [entitypredicate] ( ArgumentEntity ).
    construct ArgumentMessage [stringlit]
        _ [+ '"    reads as value parameter "] [quote ArgumentEntityKind] 
	  [+ '" '"] [quote ArgumentId] [+ '"'"]
	  [immediateContainmentInfo FB ArgumentEntity] [print]
    construct IndirectFact [fact]
	read_ref indirect ( ArgumentEntity, Entity ).
    by
	FactsSoFar [. ArgumentFact] 
		   [. IndirectFact]
end function

function contains Fact [fact]
    match * [fact]
	Fact
end function
