% Parser-based entity markup for HIPAA
% Nadia Kiyavitskaya & Jim Cordy
% Feb 2007

% Usage:  txl input.txt MarkupEntities.txl > output.txt

% Case-insensitive character and line-level processing with wide lines
% (-nomultiline corrects for a bug in TXL 10.4d)
#pragma -w 64000 -case -char -newline -nomultiline 

% Parse as a sequence of lines, since that will scale up and token parsing won't 
define program
	[repeat line]
end define

% Within a line parse words and tokens
define line
	[repeat word_or_other] [newline]
end define

define word_or_other
	[id] | [not newline] [token]
end define

% Use the parser to recognize base entities for us
include "Entities.grm"

redefine word_or_other
	[entity] | ...
end redefine

% Use the parser to recognize modal verbs for us
define modal_verb
	[root_modal_verb] [opt 'not]
end define 

define root_modal_verb
	'must | 'can | 'could | 'should | 'may
end define

redefine word_or_other
	[modal_verb] | ...
end redefine

% Allow for markup - this is less error-prone that doing it as tokens
redefine word_or_other
	[markup] | ...
end redefine

define markup
	'< [SPOFF] [id] '> [SPON] [repeat word_or_other] < [SPOFF] '/ [id] '> [SPON] 
end define


% Make one pass over the lines of the file, marking up entities

rule main
	replace $ [line]
		L [line]
	by
		L [markupActors]
		  [markupDates]
		  [markupEvents]
		  [markupInformations]
		  [markupPolicies]
		  [unmarkModalVerbs]
end rule


% Rules for marking up entity classes

rule markupActors
	skipping [markup]
	replace $ [repeat word_or_other]
		A [actor] Rest [repeat word_or_other]
	by
		'< 'Actor '> A '< '/ 'Actor '> Rest
end rule

rule markupDates
	skipping [markup]
	replace $ [repeat word_or_other]
		A [date] Rest [repeat word_or_other]
	by
		'< 'Date '> A '< '/ 'Date '> Rest 
end rule

rule markupEvents
	skipping [markup]
	replace $ [repeat word_or_other]
		A [event] Rest [repeat word_or_other]
	by
		'< 'Event '> A '< '/ 'Event '> Rest 
end rule

rule markupInformations
	skipping [markup]
	replace $ [repeat word_or_other]
		A [information] Rest [repeat word_or_other]
	by
		'< 'Information '> A '< '/ 'Information '> Rest 
end rule

rule markupPolicies
	skipping [markup]
	replace $ [repeat word_or_other]
		A [policy] Rest [repeat word_or_other]
	by
		'< 'Policy '> A '< '/ 'Policy '> Rest 
end rule


% Remove markups of modal verbs

rule unmarkModalVerbs
	replace $ [repeat word_or_other]
		ModalVerb [modal_verb] '< _[id] '> Content [id] '< '/ _ [id] '>
		Rest [repeat word_or_other]
	by
		ModalVerb Content Rest 
end rule
