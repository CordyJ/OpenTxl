% Analyze and rename hierarchy of HIPAA documents
% Jim Cordy
% Feb 2007

% Usage:  txl inputdoc.txt AnalyzeHierarhcy.txl > outputdoc.txt

% This program analyzes the structure of a HIPAA or similar form document using 
% hierarchical grammar and reformats it to reflect its hierarchical form.
% It then annotates every sub(sub*)section label with its complete path, 
% for example converting "(A)" to "?164.514(d)(3)(ii)(A)"


% Grammar for HIPAA hierarchy
include "HIPAA_Hierarchy.grm"


% Add complete paths to all subsection labels
function main
	replace [program]
		HipaaDoc [program]
	by
		HipaaDoc [addImplicitSubsectionLabels]
		         [annotateSections]
end function

rule addImplicitSubsectionLabels
	replace [opt subsection_label]
	by
		(a)
end rule

rule annotateSections
	skipping [subsection]
	replace $ [section]
		Label [section_label] Space [space] Title [section_title]
		    SubSections [repeat subsection]
	by
		Label Space Title 
		    SubSections [annotateWithSectionLabel Label]
		                [annotateSubsections]
end rule

rule annotateWithSectionLabel Label [section_label]
	replace $ [opt annotate_section_label]
	by
		Label
end rule

rule annotateSubsections
	skipping [subsubsection]
	replace $ [subsection]
		Label [subsection_label] 
		    SubSubsections [repeat subsubsection]
	by
		Label 
		    SubSubsections [annotateWithSubsectionLabel Label]
		                   [annotateSubSubsections]
end rule

rule annotateWithSubsectionLabel Label [subsection_label]
	replace $ [opt annotate_subsection_label]
	by
		Label
end rule

rule annotateSubSubsections
	skipping [subsubsubsection]
	replace $ [subsubsection]
		Label [subsubsection_label] 
		    SubSubSubSubsections [repeat subsubsubsection]
	by
		Label 
		    SubSubSubSubsections [annotateWithSubSubsectionLabel Label]
		                         [annotateSubSubSubsections]
end rule

rule annotateWithSubSubsectionLabel Label [subsubsection_label]
	replace $ [opt annotate_subsubsection_label]
	by
		Label
end rule

rule annotateSubSubSubsections
	skipping [subsubsubsubsubsection]
	replace $ [subsubsubsection]
		Label [subsubsubsection_label] 
		    SubSubSubSubSubsections [repeat subsubsubsubsection]
	by
		Label 
		    SubSubSubSubSubsections [annotateWithSubSubSubsectionLabel Label]
		                            [annotateSubSubSubSubsections]
end rule

rule annotateWithSubSubSubsectionLabel Label [subsubsubsection_label]
	replace $ [opt annotate_subsubsubsection_label]
	by
		Label
end rule

rule annotateSubSubSubSubsections
	skipping [subsubsubsubsubsections]
	replace $ [subsubsubsubsection]
		Label [subsubsubsubsection_label] 
		    Paragraphs [repeat paragraph]
		    SubSubSubSubSubSubsections [subsubsubsubsubsections]
	by
		Label 
		    Paragraphs
		    SubSubSubSubSubSubsections [annotateWithSubSubSubSubsectionLabel Label]
end rule

rule annotateWithSubSubSubSubsectionLabel Label [subsubsubsubsection_label]
	replace $ [opt annotate_subsubsubsubsection_label]
	by
		Label 
end rule
