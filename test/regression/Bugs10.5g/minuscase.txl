% Demo of problems with built-in functions in the presence of -case
#pragma -case

define program 
    [repeat id] 
end define 

function main 
    replace [program] 
        InputId [id] 

    % Show input id
    construct _ [id]
        InputId [putp "The input id is: % (should be AbCd)"]

    % Create an id
    construct InternalId [id]
        'EfGh
    construct _ [id]
        InternalId [putp "The internal id is: % (should be EfGh)"]

    % Test all the operations
    where
        InputId [TestEquals InternalId]
    where 
        InputId [TestConcat InternalId]
    where
        InputId [TestUnderscore InternalId]
    where
        InputId [TestSubstr InternalId]

    % Everything ok!
    construct _ [id]
        _ [message ""]
    by
        'All_OK
end function

function TestEquals InternalId [id]
    match [id]
        InputId [id]

    % Test [=]
    construct _ [id]
        _ [message ""] [message "Test [=]"]

    construct _ [id] _ [message "where InputId [= InputId]"]
    where InputId [= InputId]
    construct _ [id] _ [message "OK"]

    construct _ [id] _ [message "where InputId [= 'AbCd]"]
    where InputId [= 'AbCd]
    construct _ [id] _ [message "OK"]

    construct _ [id] _ [message "where InputId [= 'abcd]"]
    where InputId [= 'abcd]
    construct _ [id] _ [message "OK"]

    construct _ [id] _ [message "where not InputId [= InternalId]"]
    where not InputId [= InternalId]
    construct _ [id] _ [message "OK"]

    construct _ [id] _ [message "where InternalId [= 'EfGh]"]
    where InternalId [= 'EfGh]
    construct _ [id] _ [message "OK"]

    construct _ [id] _ [message "where InternalId [= 'efgh]"]
    where InternalId [= 'efgh]
    construct _ [id] _ [message "OK"]

end function

function TestConcat InternalId [id]
    match [id]
        InputId [id]

    % Test [+]
    construct _ [id]
        _ [message ""] [message "Test [+]"]

    construct NullInputId [id] _ [+ InputId]
         [message "construct NullInputId [id] _ [+ InputId]"]
    construct SNullInputId [stringlit] _ [unparse NullInputId]
    where SNullInputId [= "AbCd"]
    construct _ [id] _ [message "OK"]
        
    construct InputIdNull [id] InputId [+ ""]
         [message "construct InputIdNull [id] InputId [+ \"\"]"]
    construct SInputIdNull [stringlit] _ [unparse InputIdNull]
    where SInputIdNull [= "AbCd"]
    construct _ [id] _ [message "OK"]

    construct InputIdInputId [id] InputId [+ InputId]
         [message "construct InputIdInputId [id] InputId [+ InputId]"]
    construct SInputIdInputId [stringlit] _ [unparse InputIdInputId]
    where SInputIdInputId [= "AbCdAbCd"]
    construct _ [id] _ [message "OK"]

    construct InternalIdInternalId [id] InternalId [+ InternalId]
         [message "construct InternalIdInternalId [id] InternalId [+ InternalId]"]
    construct SInternalIdInternalId [stringlit] _ [unparse InternalIdInternalId]
    where SInternalIdInternalId [= "EfGhEfGh"]
    construct _ [id] _ [message "OK"]

    construct InputIdInternalId [id] InputId [+ InternalId]
         [message "construct InputIdInternalId [id] InputId [+ InternalId]"]
    construct SInputIdInternalId [stringlit] _ [unparse InputIdInternalId]
    where SInputIdInternalId [= "AbCdEfGh"]
    construct _ [id] _ [message "OK"]

    construct InputIdLiteral [id] InputId [+ 'WxYz]
         [message "construct InputIdLiteral [id] InputId [+ 'WxYz]"]
    construct SInputIdLiteral [stringlit] _ [unparse InputIdLiteral]
    where SInputIdLiteral [= "AbCdWxYz"]
    construct _ [id] _ [message "OK"]
    
end function

function TestUnderscore InternalId [id]
    match [id]
        InputId [id]

    % Test [_]
    construct _ [id]
        _ [message ""] [message "Test [_]"]

    construct USNullInputId [id] _ [_ InputId]
         [message "construct USNullInputId [id] _ [_ InputId]"]
    construct SUSNullInputId [stringlit] _ [unparse USNullInputId]
    where SUSNullInputId [= "_AbCd"]
    construct _ [id] _ [message "OK"]
        
    construct USInputIdInputId [id] InputId [_ InputId]
         [message "construct USInputIdInputId [id] InputId [_ InputId]"]
    construct SUSInputIdInputId [stringlit] _ [unparse USInputIdInputId]
    where SUSInputIdInputId [= "AbCd_AbCd"]
    construct _ [id] _ [message "OK"]

    construct USInternalIdInternalId [id] InternalId [_ InternalId]
         [message "construct USInternalIdInternalId [id] InternalId [_ InternalId]"]
    construct SUSInternalIdInternalId [stringlit] _ [unparse USInternalIdInternalId]
    where SUSInternalIdInternalId [= "EfGh_EfGh"]
    construct _ [id] _ [message "OK"]

    construct USInputIdInternalId [id] InputId [_ InternalId]
         [message "construct USInputIdInternalId [id] InputId [_ InternalId]"]
    construct SUSInputIdInternalId [stringlit] _ [unparse USInputIdInternalId]
    where SUSInputIdInternalId [= "AbCd_EfGh"]
    construct _ [id] _ [message "OK"]

    construct USInputIdLiteral [id] InputId [_ 'WxYz]
         [message "construct USInputIdLiteral [id] InputId [_ 'WxYz]"]
    construct SUSInputIdLiteral [stringlit] _ [unparse USInputIdLiteral]
    where SUSInputIdLiteral [= "AbCd_WxYz"]
    construct _ [id] _ [message "OK"]

end function

function TestSubstr InternalId [id]
    match [id]
        InputId [id]

    % Test [:]
    construct _ [id]
        _ [message ""] [message "Test [:]"]

    construct InputId12 [id] InputId [: 1 2]
         [message "construct InputId12 [id] InputId [: 1 2]"]
    construct SInputId12 [stringlit] _ [unparse InputId12]
    where SInputId12 [= "Ab"]
    construct _ [id] _ [message "OK"]

    construct InputId23 [id] InputId [: 2 3]
         [message "construct InputId23 [id] InputId [: 2 3]"]
    construct SInputId23 [stringlit] _ [unparse InputId23]
    where SInputId23 [= "bC"]
    construct _ [id] _ [message "OK"]

    construct InternalId34 [id] InternalId [: 3 4]
         [message "construct InternalId34 [id] InternalId [: 3 4]"]
    construct SInternalId34 [stringlit] _ [unparse InternalId34]
    where SInternalId34 [= "Gh"]
    construct _ [id] _ [message "OK"]

end function 
