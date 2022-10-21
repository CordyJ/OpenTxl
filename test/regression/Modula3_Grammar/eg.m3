MODULE Bootstrap;

(***************************************************************************)
(** Created by:  Peter Klein						   *)
(** (c) 1997 Lehrstuhl fuer Informatik III, RWTH Aachen, Germany.          *)
(** Adapted with permission from:                                          *)
(** TXL v7.4 (c) 1988-1993, Queen's University at Kingston                 *)
(** J.R. Cordy, C.D. Halpern, E.M. Promislow, and I.H. Carmichael          *)
(** June 1993                                                              *)

(** $Author: txl $
    $Revision: 1.1 $
    $Date: 1997/06/17 19:00:37 $
    $Log: Bootstrap.m3,v $
    Revision 1.1  1997/06/17 19:00:37  txl
    *** empty log message ***

*)
(***************************************************************************)

IMPORT Specification, TokenPatterns, Tree, TreeStorage, Token;

IMPORT Bundle, BootBundle, Text, TextSet, TextSetDef, TextSeq, ASCII;


PROCEDURE F (): Specification.T RAISES {SyntaxError} =
  VAR
    spec       : Specification.T;
    symbolTable: TreeStorage.T;

  BEGIN
    symbolTable := NEW(TreeStorage.T).init();
    SetUpBuiltins(symbolTable);
    spec.grammar := GetTree("program", Token.Type.Undefined, symbolTable);
    spec.keywords := GetKeys();
    spec.patterns := GetTokens();
    GetDefines(symbolTable);
    CheckTrees(symbolTable);
    RETURN spec;
  END F;


(* Install the builtin nonterminals in the symbol table. *)
PROCEDURE SetUpBuiltins (symbolTable: TreeStorage.T) =
  BEGIN
    EVAL GetTree("empty", Token.Type.Empty, symbolTable);
    EVAL GetTree("stringlit", Token.Type.ClassLit, symbolTable,
                 Token.StringLitClass);
    EVAL GetTree(
           "number", Token.Type.ClassLit, symbolTable, Token.NumberClass);
    EVAL GetTree("id", Token.Type.ClassLit, symbolTable, Token.IdClass);
    EVAL GetTree("token", Token.Type.Token, symbolTable);
    EVAL GetTree("key", Token.Type.Key, symbolTable);
    EVAL GetTree("NL", Token.Type.Empty, symbolTable);
    EVAL GetTree("IN", Token.Type.Empty, symbolTable);
    EVAL GetTree("EX", Token.Type.Empty, symbolTable);
    EVAL GetTree("SP", Token.Type.Empty, symbolTable);
    EVAL GetTree("NOSP", Token.Type.Empty, symbolTable);
    EVAL GetTree("SPOFF", Token.Type.Empty, symbolTable);
    EVAL GetTree("SPON", Token.Type.Empty, symbolTable);
    EVAL GetTree("KEEP", Token.Type.Empty, symbolTable);
  END SetUpBuiltins;


(* Collect the tokens from the keys section of the specification. *)
PROCEDURE GetKeys (): TextSet.T RAISES {SyntaxError} =
  VAR
    token     : TEXT;
    keywordSet: TextSet.T;

  BEGIN
    Match("keys");
    keywordSet := NEW(TextSetDef.T).init();
    LOOP
      token := GetNextToken();
      IF (Text.Equal(token, "end")) THEN EXIT; END;
      IF (Text.GetChar(token, 0) = '\'') THEN
        token := Text.Sub(token, 1);
      END;
      EVAL keywordSet.insert(token);
    END;
    Match("keys");
    RETURN keywordSet;
  END GetKeys;


(* Collect the names and patterns from the tokens section of the
   specification. *)
PROCEDURE GetTokens (): TokenPatterns.T RAISES {SyntaxError} =
  VAR
    patterns: TokenPatterns.T;
    token   : TEXT;
    pattern : TEXT;

  BEGIN
    patterns := NEW(TokenPatterns.T).init();
    Match("tokens");
    LOOP
      token := GetNextToken();
      IF (Text.Equal(token, "end")) THEN EXIT; END;
      pattern := GetNextToken();
      IF ((Text.Length(pattern) < 2) OR (Text.GetChar(pattern, 0) # '"')
            OR (Text.GetChar(pattern, Text.Length(pattern) - 1) # '"')) THEN
        RAISE
          SyntaxError(
            "error in token statement: missing string quote in pattern");
      END;
      pattern := Text.Sub(pattern, 1, Text.Length(pattern) - 2);
      TRY
        patterns.store(token, pattern);
      EXCEPT
      | TokenPatterns.Error (m) =>
          RAISE SyntaxError("error in token statement: " & m);
      END;
    END;
    Match("tokens");
    RETURN patterns;
  END GetTokens;


(* Process the define statements in the specification. *)
PROCEDURE GetDefines (symbolTable: TreeStorage.T) RAISES {SyntaxError} =
  VAR
    token     : TEXT;
    found     : BOOLEAN;
    defineTree: Tree.T;

  BEGIN
    LOOP
      token := TryNextToken(found);
      IF (NOT found) THEN EXIT; END;
      IF (NOT Text.Equal(token, "define")) THEN
        Mismatch(expected := "define", got := token);
      END;
      token := GetNextToken();
      defineTree := GetTree(token, Token.Type.Undefined, symbolTable);
      GetDefineBody(defineTree, symbolTable);
      Match("define");
    END;
  END GetDefines;


(* Process the body of a define statement. *)
PROCEDURE GetDefineBody (parent: Tree.T; symbolTable: TreeStorage.T)
  RAISES {SyntaxError} =
  VAR
    token    : TEXT;
    childTree: Tree.T;

  BEGIN
    token := GetNextToken();
    (* by default, we think it's an order construct *)
    parent.changeType(Token.Type.Order);
    LOOP
      IF (Text.Equal(token, "end")) THEN EXIT; END;
      childTree := GetChildTree(token, symbolTable);
      parent.appendChild(childTree);
      token := GetNextToken();
      IF (parent.getType() = Token.Type.Choose) THEN
        IF (Text.Equal(token, "end")) THEN EXIT; END;
        IF (NOT Text.Equal(token, "|")) THEN
          Mismatch(expected := "|", got := token);
        END;
        token := GetNextToken();
      ELSE
        IF (Text.Equal(token, "|")) THEN
          IF (parent.noOfChildren() > 1) THEN
            (* this is not allowed in the bootstrap specification *)
            RAISE SyntaxError("multiple tokens in choice alternative");
          END;
          (* it's a choose construct, then *)
          parent.changeType(Token.Type.Choose);
          token := GetNextToken();
        END;
      END;
    END;
  END GetDefineBody;


(* Returns a tree for a child token. *)
PROCEDURE GetChildTree (token: TEXT; symbolTable: TreeStorage.T): Tree.T =
  VAR
    firstChar: CHAR;
    name     : TEXT;

  BEGIN
    firstChar := Text.GetChar(token, 0);
    IF (firstChar = '[') THEN
      (* its a reference to a tree we already have *)
      name := Text.Sub(token, 1, Text.Length(token) - 2);
      RETURN GetTree(name, Token.Type.Undefined, symbolTable);
    END;
    IF (firstChar = '\'') THEN name := Text.Sub(token, 1); END;

    (* a new tree *)
    RETURN
      NEW(Tree.T).init(rootType := Token.Type.Literal, rootName := name);
  END GetChildTree;


(* Check that there is a definition for all nonterminals we have found. *)
PROCEDURE CheckTrees (symbolTable: TreeStorage.T) RAISES {SyntaxError} =
  VAR
    error    : BOOLEAN;
    tree     : Tree.T;
    errorText: TEXT;
    iterator : TreeStorage.Iterator;

  BEGIN
    error := FALSE;
    errorText := "undefined symbol(s): ";
    iterator := symbolTable.iterate();
    WHILE (iterator.next(tree)) DO
      IF (tree.getType() = Token.Type.Undefined) THEN
        IF (error) THEN errorText := errorText & ", "; END;
        errorText := errorText & "<" & tree.getName() & ">";
        error := TRUE;
      END;
    END;
    IF (error) THEN RAISE SyntaxError(errorText); END;
  END CheckTrees;


(* Returns a tree for a token.  Creates one if there is none. *)
PROCEDURE GetTree (name       : TEXT;
                   type       : Token.Type;
                   symbolTable: TreeStorage.T;
                   class      : TEXT            := NIL): Tree.T =
  VAR
    tree : Tree.T;
    found: BOOLEAN;

  <* FATAL TreeStorage.Redefined *>

  BEGIN
    tree := symbolTable.get(name, found);
    IF (found) THEN RETURN tree; END;
    tree := NEW(Tree.T).init(
              rootType := type, rootName := name, rootClass := class);
    symbolTable.insert(tree);
    RETURN tree;
  END GetTree;


(* Raises SyntaxError if the current token is not expectedToken. *)
PROCEDURE Match (expectedToken: TEXT) RAISES {SyntaxError} =
  VAR token: TEXT;

  BEGIN
    token := GetNextToken();
    IF (NOT Text.Equal(token, expectedToken)) THEN
      Mismatch(expectedToken, token);
    END;
  END Match;


(* Raises SyntaxError with a formated error message. *)
PROCEDURE Mismatch (expected: TEXT; got: TEXT) RAISES {SyntaxError} =
  BEGIN
    RAISE SyntaxError("expected " & expected & ", got " & got);
  END Mismatch;


(* Returns the next token in the input stream. *)
PROCEDURE GetNextToken (): TEXT RAISES {SyntaxError} =
  VAR
    token: TEXT;
    found: BOOLEAN;

  BEGIN
    token := TryNextToken(found);
    IF (NOT found) THEN RAISE SyntaxError("unexpected end of file"); END;
    RETURN token;
  END GetNextToken;


VAR
  tokenSeq  : TextSeq.T;
  tokenIndex: CARDINAL;


(* Returns the next token if there is one. *)
PROCEDURE TryNextToken (VAR found: BOOLEAN): TEXT =
  VAR token: TEXT;

  BEGIN
    IF (tokenIndex >= tokenSeq.size()) THEN
      found := FALSE;
      RETURN NIL;
    END;
    found := TRUE;
    token := tokenSeq.get(tokenIndex);
    INC(tokenIndex);
    RETURN token;
  END TryNextToken;


VAR
  grammar   : TEXT;
  first     : INTEGER;
  token     : TEXT;
  spaces    : BOOLEAN;
  specTokens: BOOLEAN;

BEGIN
  (* the bootstrap grammar is expected to be bundled into the
     application *)
  grammar := Bundle.Get(BootBundle.Get(), "BootstrapGrammar");

  (* read the grammar into a token sequence *)
  tokenSeq := NEW(TextSeq.T).init();
  spaces := (Text.GetChar(grammar, 0) IN ASCII.Spaces);
  first := 0;
  specTokens := FALSE;
  FOR i := 0 TO Text.Length(grammar) - 1 DO
    IF (Text.GetChar(grammar, i) IN ASCII.Spaces) THEN
      IF (NOT spaces) THEN
        token := Text.Sub(grammar, first, i - first);
        IF (Text.Equal(token, "keys")) THEN specTokens := TRUE; END;
        IF (specTokens) THEN tokenSeq.addhi(token); END;
        spaces := TRUE;
      END;
    ELSE
      IF (spaces) THEN first := i; spaces := FALSE; END;
    END;
  END;
  tokenIndex := 0;
END Bootstrap.
