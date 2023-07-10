% RStoFB.Txl: Derive ER factbase from a relational schema
% Rateb Abu-Hamdeh, August 1993
% Completely restructured by Jim Cordy, October 1994
% And again to be consistent with the revised paper, February 1995
% Corrected cardinalities, May 1995

include "rddl.Grammar"
include "fb.Grammar"

define program
        [repeat tableDefinition_or_predicateSequence] 
end define

define tableDefinition_or_predicateSequence
        [tableDefinition] 
    |   [repeat predicate] 
end define

function main
    replace [program]
        Tables [repeat tableDefinition_or_predicateSequence]
    by
        Tables [ProcessSecondaryRelations]
            [ProcessPrimaryRelations]
            [ProcessWeakSecondaryRelations]
            [ProcessWeakPrimaryRelations]
end function


rule ProcessPrimaryRelations
    % If none of the foreign keys is contained in the primary key,
    % then the table is a primary relation 

    replace [tableDefinition_or_predicateSequence]
        CREATE TABLE EntityName [id] ( AttributeDefinitions [list attributeDefinition] ) 
        UniqueStatements [repeat uniqueConstraint]
        PRIMARY KEY ( PrimaryKey [attributelist] ) 
        ForeignKeyStatements [repeat foreignKeyDefinition]

    % Get all the foreign keys
    construct ForeignKeys [repeat attributelist]
        _ [^ ForeignKeyStatements]

    % None of the foreign keys is completely contained in the primary key
    where not
        PrimaryKey [contains each ForeignKeys]

    % Get the foreign key attribute set
    construct ForeignKeyAttributes [repeat attribute]
        _ [^ ForeignKeys]

    % Get the primary key attribute set
    construct PrimaryKeyAttributes [repeat attribute]
        _ [^ PrimaryKey]

    % Compute (foreign key attribute set) - (primary key attribute set)
    construct ReducedForeignKeyAttributes [repeat attribute]
        ForeignKeyAttributes [remove each PrimaryKeyAttributes]

    % Compute (defined attribute set) - (reduced foreign key attribute set)
    construct ReducedAttributeDefinitions [repeat attributeDefinition]
        _ [. each AttributeDefinitions] 
            [removeAttributeDefinition each ReducedForeignKeyAttributes]

    construct EntityPredicate [repeat predicate]
        entity ( EntityName ) 

    construct EntityAttributePredicates [repeat predicate]
        _ [addEntityAttributePredicate EntityName each ReducedAttributeDefinitions]

    construct PrimaryKeyPredicates [repeat predicate]
        _ [addPrimaryKeyPredicates_Atomic EntityName PrimaryKey]
           [addPrimaryKeyPredicates_Composite EntityName PrimaryKey]

    construct UniquePredicates [repeat predicate]
        _ [addUniquePredicate_Atomic EntityName ForeignKeyAttributes each UniqueStatements]
            [addUniquePredicate_Composite EntityName ForeignKeyAttributes each UniqueStatements]

    construct BinaryRelationPredicates [repeat predicate]
        _ [addBinaryRelationPredicatesCommented EntityName AttributeDefinitions 
                each ForeignKeyStatements]
            [addBinaryRelationPredicates EntityName AttributeDefinitions UniqueStatements
                each ForeignKeyStatements]
    by
        EntityPredicate
            [. EntityAttributePredicates]
            [. PrimaryKeyPredicates]
            [. UniquePredicates]
            [. BinaryRelationPredicates]
end rule


rule ProcessWeakPrimaryRelations
    % If there is at least one foreign key statement,
    % and the foreign key attributes of every foreign key are a proper subset 
    % of the primary key attributes,
    % and there are attribute definitions that are not part of the primary key,
    % then the table represents a weak primary relation.

    replace [tableDefinition_or_predicateSequence]
        CREATE TABLE EntityName [id] ( AttributeDefinitions [list attributeDefinition] ) 
        UniqueStatements [repeat uniqueConstraint]
        PRIMARY KEY ( PrimaryKey [list attribute] ) 
        ForeignKeyStatements [repeat foreignKeyDefinition]

    % There is at least one foreign key statement 
    deconstruct ForeignKeyStatements
        IdentifyingRelComment [opt IdentifyingRelComment]
        FOREIGN KEY ( _ [list attribute] ) REFERENCES _ [table] 
            _ [opt SpecialComment]
        Rest [repeat foreignKeyDefinition]

    % Get the primary, foreign and defined attribute sets
    construct PrimaryKeyAttributes [repeat attribute]
        _ [^ PrimaryKey]
    construct ForeignKeyAttributes [repeat attribute]
        _ [^ ForeignKeyStatements]
    construct DefinedAttributes [repeat attribute]
        _ [^ AttributeDefinitions]

    % All of the foreign key attributes are a subset of the primary key 
    where
        PrimaryKeyAttributes [containsEvery ForeignKeyAttributes]
    where not
        ForeignKeyAttributes [containsEvery PrimaryKeyAttributes]

    % Some defined attributes are not part of the primary key 
    where not
        PrimaryKeyAttributes [containsEvery DefinedAttributes]

    construct IdentifyingRelName [id]
        EntityName [_ 'IdentRel] [useIdentifyingRelNameAdvice IdentifyingRelComment]

    construct Role [role]
        EntityName [useIdentifyingRelRoleAdvice IdentifyingRelComment]

    construct DefaultConstraint [constraint]
        (1, 1) 

    construct Constraint [constraint]
        DefaultConstraint [useIdentifyingRelConstraintAdvice IdentifyingRelComment]

    construct ReducedAttributeDefinitions [repeat attributeDefinition]
        _ [. each AttributeDefinitions] 
            [removeAttributeDefinition each ForeignKeyAttributes]

    construct ReducedPrimaryKeyAttributes [repeat attribute]
        _ [. each PrimaryKey] 
            [remove each ForeignKeyAttributes]

    construct WeakEntityPredicate [repeat predicate]
        weakEntity ( EntityName, IdentifyingRelName ) 

    construct EntityAttributePredicates [repeat predicate]
        _ [addEntityAttributePredicate EntityName each ReducedAttributeDefinitions]

    construct PartialKeyPredicates [repeat predicate]
        _ [addPartialKeyPredicates_Atomic EntityName ReducedPrimaryKeyAttributes]
            [addPartialKeyPredicates_Composite EntityName ReducedPrimaryKeyAttributes]

    construct IdentifyingRelationshipPredicates [repeat predicate]
        _ [addIdentifyingRelationshipPredicates EntityName IdentifyingRelName 
                Constraint Role ForeignKeyStatements]
    by
        WeakEntityPredicate
            [. EntityAttributePredicates]
            [. PartialKeyPredicates]
            [. IdentifyingRelationshipPredicates]
end rule


rule ProcessSecondaryRelations
    % If all primary attributes are foreign key attributes and vice versa, 
    % then the table represents a secondary relation.

    replace [tableDefinition_or_predicateSequence]
        CREATE TABLE RelName [id] ( AttributeDefinitions [list attributeDefinition] ) 
        UniqueStatements [repeat uniqueConstraint]
        PRIMARY KEY ( PrimaryKey [list attribute] ) 
        ForeignKeyStatements [repeat foreignKeyDefinition]

    % Get the primary and foreign key attribute sets
    construct PrimaryKeyAttributes [repeat attribute]
        _ [^ PrimaryKey]
    construct ForeignKeyAttributes [repeat attribute]
        _ [^ ForeignKeyStatements]

    % The primary attribute set = foreign attribute set 
    where
        PrimaryKeyAttributes [containsEvery ForeignKeyAttributes]
    where
        ForeignKeyAttributes [containsEvery PrimaryKeyAttributes]

    construct Participation [arity]
        Binary  % assume binary unless otherwise

    construct RelationshipPredicate [repeat predicate]
        relationship (RelName, Participation [checkNary ForeignKeyStatements] )

    construct AttributePredicates [repeat predicate]
        _ [addRelationshipAttributePredicate RelName each AttributeDefinitions]

    construct EntityInRelationshipPredicates [repeat predicate]
        _ [addEntityInRelationshipPredicateCommented RelName each ForeignKeyStatements]
            [addEntityInRelationshipPredicate RelName each ForeignKeyStatements]

    by
        RelationshipPredicate 
            [. AttributePredicates] 
            [. EntityInRelationshipPredicates]
end rule


rule ProcessWeakSecondaryRelations
    % If there is exactly one foreign key statement,
    % and the foreign key attributes are a proper subset of the primary key,
    % and the attribute definitions are all primary key attributes,
    % then the table represents a weak secondary relation.

    replace [tableDefinition_or_predicateSequence]
        CREATE TABLE AttributeName [id] ( AttributeDefinitions [list attributeDefinition] ) 
        UniqueStatements [repeat uniqueConstraint]
        PRIMARY KEY ( PrimaryKey [list attribute] ) 
        FOREIGN KEY ( ForeignKey [list attribute] ) REFERENCES EntityName [id]

    % Get the primary, foreign and defined attribute sets
    construct PrimaryKeyAttributes [repeat attribute]
        _ [^ PrimaryKey]
    construct ForeignKeyAttributes [repeat attribute]
        _ [^ ForeignKey]
    construct DefinedAttributes [repeat attribute]
        _ [^ AttributeDefinitions]

    % The foreign key attribute set is a proper subset of the primary key
    where
        PrimaryKeyAttributes [containsEvery ForeignKeyAttributes]
    where not
        ForeignKeyAttributes [containsEvery PrimaryKeyAttributes]

    % All defined attributes are in the primary key
    where
        PrimaryKeyAttributes [containsEvery DefinedAttributes]

    % Compute (defined attribute set) - (foreign key attribute set)
    construct ReducedAttributeDefinitions [repeat attributeDefinition]
        _ [. each AttributeDefinitions] 
          [removeAttributeDefinition each ForeignKeyAttributes]

    construct Predicates [repeat predicate]
        _ [ProcessMultiValuedAttribute_Atomic EntityName ReducedAttributeDefinitions]
            [ProcessMultiValuedAttribute_Composite AttributeName EntityName ReducedAttributeDefinitions]
    by
        Predicates
end rule


function addEntityAttributePredicate EntityName [id] 
                AttributeDefinition [attributeDefinition]

    deconstruct AttributeDefinition
        Attribute [attribute] Type [dataType] _ [opt notNull]

    construct EntityAttributePredicate [predicate]
        entityAttribute ( EntityName, Attribute, Type ) 

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. EntityAttributePredicate]
end function

function addPrimaryKeyPredicates_Atomic EntityName [id]
                PrimaryKey [attributelist]

    deconstruct PrimaryKey
        Attribute [attribute]

    construct KeyPredicate [predicate]
        key ( EntityName, Attribute ) 

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. KeyPredicate]
end function

function addPrimaryKeyPredicates_Composite EntityName [id]
                PrimaryKey_ [attributelist]

    deconstruct PrimaryKey_
        Attribute [attribute] , RestOfAttributes [list_1_attribute]

    construct KeyPredicate [predicate]
        key ( EntityName, 'PrimaryKey ) 

    construct EntityAttributePredicate [predicate]
        entityAttribute ( EntityName, 'PrimaryKey, 'COMPOSITE, Attribute, RestOfAttributes ) 
    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. KeyPredicate]
            [. EntityAttributePredicate]
end function

function addUniquePredicate_Atomic EntityName [id] 
        ForeignKeyAttributes [repeat attribute] UniqueStatement [uniqueConstraint]

    deconstruct UniqueStatement
        UNIQUE ( Attribute [attribute] ) 

    where not 
        Attribute [= each ForeignKeyAttributes]

    construct KeyPredicate [predicate]
        key ( EntityName, Attribute ) 

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. KeyPredicate]
end function

function addUniquePredicate_Composite EntityName [id] 
        ForeignKeyAttributes [repeat attribute] UniqueStatement [uniqueConstraint]

    deconstruct UniqueStatement
        UNIQUE ( UniqueAttributeList [list attribute] ) 

    deconstruct UniqueAttributeList
        Attribute1 [attribute] , RestOfAttributes [list_1_attribute]

    where not 
        Attribute1 [= each ForeignKeyAttributes]

    construct CandidateKeyId [id]
        'CandidateKey 

    construct CandidateKeyNew [id]
        CandidateKeyId [!]

    construct KeyPredicate [predicate]
        key ( EntityName, CandidateKeyNew ) 

    construct EntityAttributePredicate [predicate]
        entityAttribute ( EntityName, CandidateKeyNew, 'COMPOSITE, UniqueAttributeList ) 

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. KeyPredicate]
            [. EntityAttributePredicate]
end function

function checkNary ForeignKeyStatements [repeat foreignKeyDefinition]

    deconstruct ForeignKeyStatements
        % matches only if there are more than 2 ForeignKey statements
        ForeignKeyDefinition1 [foreignKeyDefinition]
        ForeignKeyDefinition2 [foreignKeyDefinition]
        ForeignKeyDefinition3 [foreignKeyDefinition]
        RestOfDefinitions [repeat foreignKeyDefinition]

    replace [arity]
        Binary
    by
        n_ary
end function

function addRelationshipAttributePredicate RelName [id] 
                AttributeDefinition [attributeDefinition]
    deconstruct AttributeDefinition
        % matches the attributes of the relationship only (i.e., without NOT NULL) 
        Attribute [attribute] Type [dataType]

    construct RelationshipAttributePredicate [predicate]
        relationshipAttribute ( RelName, Attribute, Type ) 

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. RelationshipAttributePredicate]
end function

function addEntityInRelationshipPredicateCommented RelName [id]
                ForeignKeyStatement [foreignKeyDefinition]

    deconstruct ForeignKeyStatement
        FOREIGN KEY ( ForeignKeyAttributesList [list attribute] ) 
            REFERENCES EntityName [id]
            --* ROLE : Role [role] Constraint [constraint]

    construct EntityInRelationshipPredicate [predicate]
        entityInRelationship ( RelName, EntityName, Constraint, Role ) 

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. EntityInRelationshipPredicate]
end function

function addEntityInRelationshipPredicate RelName [id]
                ForeignKeyStatement [foreignKeyDefinition]

    deconstruct ForeignKeyStatement
        FOREIGN KEY ( ForeignKeyAttributesList [list attribute] ) 
            REFERENCES EntityName [id]

    construct Role [role]
        % create a default role; it is the name of the entity
        EntityName 

    construct EntityInRelationshipPredicate [predicate]
        % (0,n) is a default value
        entityInRelationship ( RelName, EntityName, (0, n), Role ) 

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar [. EntityInRelationshipPredicate]
end function

% Process relations representing entities (here, ForeignKey statements
% represent binary relationships)

function addBinaryRelationPredicatesCommented EntityName [id]
                AttributeDefinitions [list attributeDefinition]
                ForeignKeyStatement [foreignKeyDefinition]

    deconstruct ForeignKeyStatement
        FOREIGN KEY ( ForeignKeyAttributesList [list attribute] ) 
            REFERENCES EntityName2 [id]
            --* RELATIONSHIP : RelName [id]
            --* ROLES : Role1 [role] Constraint1 [constraint] , 
                        Role2 [role] Constraint2 [constraint]

    construct RelationshipPredicate [predicate]
        relationship ( RelName, Binary ) 

    construct EntityInRelationshipPredicates [repeat predicate]
        % (0,n) is default value
        entityInRelationship ( RelName, EntityName1, Constraint1, Role1 ) 
        entityInRelationship ( RelName, EntityName2, Constraint2, Role2 ) 

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. RelationshipPredicate]
            [. EntityInRelationshipPredicates]
end function

function addBinaryRelationPredicates EntityName1 [id]
                AttributeDefinitions [list attributeDefinition]
                UniqueStatements [repeat uniqueConstraint]
                ForeignKeyStatement [foreignKeyDefinition]

    deconstruct ForeignKeyStatement
        FOREIGN KEY ( ForeignKeyAttributesList [list attribute] ) 
            REFERENCES EntityName2 [id]

    % construct default relationship name and roles 
    construct Role1 [role]
        EntityName1 

    construct Role2 [role]
        EntityName2

    construct RelName [id]
        EntityName1 [_ EntityName2] [_ 'Rel] [!]

    % construct constraints
    construct DefaultConstraint [constraint]
        (0, 1) 

    construct Constraint1 [constraint]
        DefaultConstraint 
            [checkNotNull ForeignKeyAttributesList AttributeDefinitions]

    construct DefaultConstraint2 [constraint]
        (0, n) 

    construct Constraint2 [constraint]
        DefaultConstraint2 
            [checkUnique ForeignKeyAttributesList UniqueStatements]

    construct RelationshipPredicate [predicate]
        relationship ( RelName, Binary ) 

    construct EntityInRelationshipPredicates [repeat predicate]
        entityInRelationship ( RelName, EntityName1, Constraint1, Role1 ) 
        entityInRelationship ( RelName, EntityName2, Constraint2, Role2 ) 

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. RelationshipPredicate]
            [. EntityInRelationshipPredicates]
end function

function checkNotNull ForeignKeyAttributesList [list attribute]
                AttributeDefinitions [list attributeDefinition]

    deconstruct ForeignKeyAttributesList
        Attribute [attribute] , Rest [list attribute]

    deconstruct * [attributeDefinition] AttributeDefinitions 
        Attribute _ [dataType] NOT NULL

    replace [constraint]
        (0, 1) 
    by
        (1, 1) 
end function

function checkUnique ForeignKeyAttributesList [list attribute]
                UniqueStatements [repeat uniqueConstraint]

    deconstruct ForeignKeyAttributesList
        Attribute [attribute] , Rest [list attribute]

    deconstruct * [uniqueConstraint] UniqueStatements
        UNIQUE ( Attribute ) 

    replace [constraint]
        (0, n) 
    by
        (0, 1) 
end function

function ProcessMultiValuedAttribute_Atomic EntityName [id]
                ReducedAttributeDefinitions [repeat attributeDefinition]

    deconstruct ReducedAttributeDefinitions
        % the multi-valued attribute is composed of one attribute
        Attribute [attribute] Type [dataType] _ [opt notNull]

    construct MultiValuedAttributePredicate [predicate]
        multivaluedAttribute ( EntityName, Attribute, Type ) 

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. MultiValuedAttributePredicate]
end function

function ProcessMultiValuedAttribute_Composite AttributeName [id]
                EntityName [id]
                ReducedAttributeDefinitions [repeat attributeDefinition]

    deconstruct ReducedAttributeDefinitions
        AttributeDefinition1 [attributeDefinition] 
        AttributeDefinition2 [attributeDefinition] 
        RestOfDefinitions [repeat attributeDefinition]

    construct MultiValuedAttributePredicate [predicate]
        multivaluedAttribute ( EntityName, AttributeName, COMPOSITE ) 

    construct MultiValuedAttributeComponentPredicates [repeat predicate]
        _ [addMultiValuedAttributeComponent EntityName AttributeName each ReducedAttributeDefinitions]

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. MultiValuedAttributePredicate]
            [. MultiValuedAttributeComponentPredicates]
end function

function addMultiValuedAttributeComponent EntityName [id]
                AttributeName [id]
                AttributeDefinition [attributeDefinition]

    deconstruct AttributeDefinition
        Attribute [attribute] Type [dataType] _ [opt notNull]

    construct MultiValuedAttributeComponentPredicate [predicate]
        multivaluedAttrComponent ( EntityName, MultiValuedAttribute, Attribute, Type ) 

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. MultiValuedAttributeComponentPredicate]
end function

function useIdentifyingRelNameAdvice RelComment [opt IdentifyingRelComment]
    deconstruct RelComment
        --* IDENTIFYING_REL : IdentifyingRelName [id]
        --* ROLE : Role [role] Constraint [constraint]
    replace [id]
        DefaultName [id]
    by
        IdentifyingRelName
end function

function useIdentifyingRelRoleAdvice RelComment [opt IdentifyingRelComment]
    deconstruct RelComment
        --* IDENTIFYING_REL : IdentifyingRelName [id]
        --* ROLE : Role [id] Constraint [constraint]
    replace [id]
        DefaultRole [id]
    by
        Role
end function

function useIdentifyingRelConstraintAdvice RelComment [opt IdentifyingRelComment]
    deconstruct RelComment
        --* IDENTIFYING_REL : IdentifyingRelName [id]
        --* ROLE : Role [role] Constraint [constraint]
    replace [constraint]
        DefaultConstraint [constraint]
    by
        Constraint
end function

function addPartialKeyPredicates_Atomic EntityName [id]
                PrimaryKeyAttributes [repeat attribute]

    deconstruct PrimaryKeyAttributes
        Attribute [attribute]

    construct KeyPredicate [predicate]
        partialKey ( EntityName, Attribute ) 

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. KeyPredicate]
end function

function addPartialKeyPredicates_Composite EntityName [id]
                PrimaryKeyAttributes [repeat attribute]

    deconstruct PrimaryKeyAttributes
        Attribute1 [attribute]  Attribute2 [attribute] RestOfAttributes [repeat attribute]

    construct PrimaryKey [list attribute]
        _ [, each PrimaryKeyAttributes]

    construct KeyPredicate [predicate]
        partialKey ( EntityName, 'PartialKey ) 

    construct EntityAttributePredicate [predicate]
        entityAttribute ( EntityName, 'PartialKey, 'COMPOSITE, PrimaryKey ) 

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. KeyPredicate]
            [. EntityAttributePredicate]
end function

function addIdentifyingRelationshipPredicates EntityName [id]
                IdentifyingRelName [id]
                Constraint [constraint]
                Role [role]
                ForeignKeyStatements [repeat foreignKeyDefinition]

    construct EntityInRelationshipPredicateForWeakEntity [predicate]
        entityInRelationship ( IdentifyingRelName, EntityName, Constraint, Role ) 

    construct NewPredicates [repeat predicate]
        _ [addIdentifyingRelationshipPredicate_Binary IdentifyingRelName ForeignKeyStatements]
            [addIdentifyingRelationshipPredicate_N_ary IdentifyingRelName ForeignKeyStatements]
            [. EntityInRelationshipPredicateForWeakEntity]
            [addEntityInRelationshipPredicateForOwnerEntities IdentifyingRelName each ForeignKeyStatements]

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. NewPredicates]
end function

function addIdentifyingRelationshipPredicate_Binary IdentifyingRelName [id]
                ForeignKeyStatements [repeat foreignKeyDefinition]

    deconstruct ForeignKeyStatements
        % matches only if there is exactly 1 ForeignKey statement
        _ [foreignKeyDefinition]

    construct IdentifyingRelationship [predicate]
        identifyingRelationship ( IdentifyingRelName, Binary ) 

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. IdentifyingRelationship]
end function

function addIdentifyingRelationshipPredicate_N_ary IdentifyingRelName [id]
                ForeignKeyStatements [repeat foreignKeyDefinition]

    deconstruct ForeignKeyStatements
        % matches only if there are more than 1 ForeignKey statements
        _ [foreignKeyDefinition]
        _ [foreignKeyDefinition]
        Rest [repeat foreignKeyDefinition]

    construct IdentifyingRelationship [predicate]
        relationship ( IdentifyingRelName, n_ary ) 

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. IdentifyingRelationship]
end function

function addEntityInRelationshipPredicateForOwnerEntities IdentifyingRelName [id]
                ForeignKeyStatement [foreignKeyDefinition]

    deconstruct ForeignKeyStatement
        _ [opt IdentifyingRelComment]
        FOREIGN KEY ( ForeignKeyAttributesList [list attribute] ) REFERENCES EntityName [id]
            RoleComment [opt SpecialComment]

    construct Role [role]
        EntityName [useRoleAdvice RoleComment]

    construct DefaultConstraint [constraint]
        (0, n)

    construct Constraint [constraint]
        DefaultConstraint [useConstraintAdvice RoleComment]

    construct EntityInRelationshipPredicate [predicate]
        entityInRelationship ( IdentifyingRelName, EntityName, Constraint, Role ) 

    replace [repeat predicate]
        PredicatesSoFar [repeat predicate]
    by
        PredicatesSoFar 
            [. EntityInRelationshipPredicate]
end function

function useRoleAdvice RoleComment [opt SpecialComment]
    deconstruct RoleComment
        --* ROLE : Role [id] Constraint [constraint]
    replace [id]
        DefaultRole [id]
    by
        Role
end function

function useConstraintAdvice RoleComment [opt SpecialComment]
    deconstruct RoleComment
        --* ROLE : Role [role] Constraint [constraint]
    replace [constraint]
        DefaultConstraint [constraint]
    by
        Constraint
end function


% Utilities

function removeAttributeDefinition Attribute [attribute]
    replace * [repeat attributeDefinition]
        Attribute _ [dataType] _ [opt notNull]
        Rest [repeat attributeDefinition]
    by
        Rest 
end function

function containsEvery Attributes2 [repeat attribute]
    match [repeat attribute]
        Attributes1 [repeat attribute]

    construct Attributes2Minus1 [repeat attribute]
        Attributes2 [remove each Attributes1]

    deconstruct Attributes2Minus1
        % empty
end function

function remove Attribute [attribute]
    replace * [repeat attribute]
        Attribute 
        Rest [repeat attribute]
    by
        Rest 
end function

function contains AttributeList2 [attributelist]
    match [attributelist]
        AttributeList1 [attributelist]
    construct Attributes1 [repeat attribute]
        _ [^ AttributeList1]
    construct Attributes2 [repeat attribute]
        _ [^ AttributeList2]
    deconstruct * Attributes2
        _ [attribute]
    where
        Attributes1 [containsEvery Attributes2]
end function
