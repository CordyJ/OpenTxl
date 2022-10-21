% Convert HTML to XHTML in TXL 10.5
% Jim Cordy, Queen's, September 2007

include "simplehtml.grm"

rule main 
    replace [program] 
	P [program] 
    construct NewP [program] 
	P [checkForShortLoneTagBegins]
	  [checkForSequenceLoneTagBegins]
	  [checkForLoneTagBegins]
	  [normalizeTagNames]
    deconstruct not NewP
        P
    by
	NewP
end rule

rule checkForShortLoneTagBegins
    construct ShortTags [repeat id]
        'br 'input 'img 'hr
    replace [repeat element]
        < TagId [id] Attributes [repeat attribute] >
	Rest [repeat element]
    deconstruct * [id] ShortTags
        TagId
    construct _ [id]
        TagId [putp "*** Warning, missing end tag for '<%>' added"]
    construct Tag [element]
        < TagId Attributes >
	</ TagId>
    by
        Tag
	Rest
end rule


rule checkForSequenceLoneTagBegins
    construct SequenceTags [repeat id]
        'p 'li
    replace [repeat element]
        < TagId [id] Attributes [repeat attribute] >
	Rest [repeat element]
    deconstruct * [id] SequenceTags
        TagId
    skipping [element]
    deconstruct * Rest
        < TagId _ [repeat attribute] >
	_ [repeat element]    
    construct _ [id]
        TagId [putp "*** Warning, missing end tag for '<%>' added"]
    construct Tag [element]
        < TagId Attributes >
    construct NewElements [repeat element]
        Tag
	Rest [closeSequence TagId]
    construct FixedElements [repeat element]
        _ [reparse NewElements]
    by
	FixedElements
end rule

function closeSequence  TagId [id]
    skipping [element]
    replace * [repeat element]
        < TagId Attributes [repeat attribute] >
	Rest [repeat element]
    construct Tag [element]
        < TagId Attributes >
    construct TagEndElement [tag_end]
	</ TagId >
    construct TagEnd [element]
	TagEndElement
    by
	TagEnd
	Tag
	Rest
end function

rule checkForLoneTagBegins
    replace [repeat element]
        < TagId [id] Attributes [repeat attribute] >
	Rest [repeat element]
    construct _ [id]
        TagId [putp "*** Warning, missing end tag for '<%>' added"]
    by
        < TagId Attributes >
	    Rest 
	</ TagId >
end rule

rule normalizeTagNames
    replace $ [tag]
        < TagId [id] Attributes [repeat attribute] >
	    Elements [repeat element]
	</ EndTagId [id] >
    by
        < TagId [tolower] Attributes [normalizeAttributeNames] >
	    Elements 
	</ EndTagId [tolower] >
end rule

rule normalizeAttributeNames
    replace $ [attribute]
        AttributeId [id] OptValue [opt equals_attribute_value]
    by
        AttributeId [tolower] OptValue [quoteUnquotedValues]
end rule

function quoteUnquotedValues
    replace * [attribute_value]
        Value [attribute_value]
    deconstruct not Value
        _ [stringlit]
    construct StringValue [stringlit]
	_ [quote Value]
    by
        StringValue
end function
