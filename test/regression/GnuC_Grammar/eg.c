#include <UNIX/cinterface>
extern TLstring	txl_library;
extern TLstring	txl_dirchar;
extern TLstring	defaultLibrary;
extern TLstring	directoryChar;
extern TLint4	txl_outputwidth;
extern TLint4	defaultOutputLineLength;
extern TLint4	txl_defaultsize;
extern TLint4	defaultTxlSize;
extern TLint4	txl_parsetimelimit;
extern TLint4	defaultTimeLimit;
extern TLint4	txl_clocks_per_second;
extern TLint4	clocksPerSecond;
extern TLaddressint	stackSize;
extern TLstring	txlSourceFileName;
extern TLstring	objectSourceFileName;

void error ();
extern TLaddressint	stackBase;
typedef	TLboolean	__x1737[256];
typedef	__x1737	propertyT;
extern propertyT	digitP;
extern propertyT	alphaP;
extern propertyT	alphaidP;
extern propertyT	idP;
extern propertyT	upperP;
extern propertyT	upperidP;
extern propertyT	lowerP;
extern propertyT	loweridP;
extern propertyT	specialP;
extern propertyT	repeaterP;
extern propertyT	optionalP;
extern propertyT	separatorP;
extern propertyT	spaceP;
extern propertyT	metaP;
extern propertyT	magicP;
extern propertyT	spaceBeforeP;
extern propertyT	spaceAfterP;
typedef	TLchar	__x1757[256];
extern __x1757	uppercase;
extern __x1757	lowercase;
extern TLchar	stringlitEscapeChar;
extern TLchar	charlitEscapeChar;

void putxmlencode ();
extern TLint4	TL_TLI_TLIARC;
extern TLnat4	TL_TLK_TLKTIME;
extern TLnat4	TL_TLK_TLKEPOCH;
extern TLboolean	TL_TLK_TLKCLKON;
extern TLnat4	TL_TLK_TLKHZ;
extern TLnat4	TL_TLK_TLKCRESO;
extern TLnat4	TL_TLK_TLKTIME;
extern TLnat4	TL_TLK_TLKEPOCH;
typedef	TLboolean	__x1765[37];
extern __x1765	options;
extern TLint4	maxOutputLineLength;
extern TLint4	indentIncrement;
extern TLstring	txlLibrary;
typedef	TLstring	__x1768[6];
extern __x1768	txlIncludes;
extern TLint4	nTxlIncludes;
extern TLstring	optionIdchars;
extern TLstring	optionSpchars;
extern TLboolean	updatedChars;
extern TLint4	txlSize;
extern TLint4	nprogArgs;
typedef	TLstring	__x1771[32];
extern __x1771	progArgs;
typedef	TLstring	__x1774[64];
extern __x1774	ifdefSymbols;
extern TLint4	nIfdefSymbols;
extern TLint4	exitcode;

void processOption ();

void processOptionsString ();
extern TLint4	maxIdents;
extern TLint4	maxIdentChars;
extern TLint4	maxTokens;
extern TLint4	maxLines;
extern TLint4	maxFiles;
extern TLint4	maxParseDepth;
extern TLint4	maxCallDepth;
extern TLint4	maxTrees;
extern TLint4	maxKids;
extern TLaddressint	maxStackUse;
typedef	TLnat4	tokenT;
typedef	TLint1	kindT;
typedef	TLint4	inputTokenHT;
extern tokenT	*inputTokens;
extern TLint4	inputTokensZ0;
extern tokenT	*inputTokenRaw;
extern TLint4	inputTokenRawZ0;
extern kindT	*inputTokenKind;
extern TLint4	inputTokenKindZ0;
extern TLint4	*inputTokenLineNum;
extern TLint4	inputTokenLineNumZ0;
extern inputTokenHT	tokenHandle;
extern inputTokenHT	lastTokenHandle;
extern inputTokenHT	failTokenHandle;
extern TLint4	nFiles;
extern TLstring	*fileNames;
extern TLint4	fileNamesZ0;
struct	compoundT {
    TLint4	length_;
    TLstring	literal;
};
typedef	struct compoundT	__x1872[129];
extern __x1872	compoundTokens;
extern TLint4	nCompounds;
typedef	TLint4	__x1873[256];
extern __x1873	compoundIndex;
typedef	tokenT	__x1876[16];
extern __x1876	commentStart;
extern __x1876	commentEnd;
extern TLint4	nComments;
typedef	TLchar	__x1877[256];
struct	patternT {
    kindT	kind;
    tokenT	name;
    __x1877	pattern;
    TLint4	length_;
    TLint4	next;
};
extern TLint4	nPatterns;
extern TLint4	nPredefinedPatterns;
extern TLint4	idPattern;
typedef	struct patternT	__x1878[64];
extern __x1878	tokenPatterns;
typedef	TLint4	__x1879[256];
extern __x1879	patternIndex;
extern TLint4	nPatternLinks;
typedef	TLint4	__x1882[1600];
extern __x1882	patternLink;
extern kindT	nextUserTokenKind;
typedef	TLchar	__x1885[13];
extern __x1885	patternChars;
typedef	TLchar	__x1889[13];
extern __x1889	patternCodes;
typedef	TLchar	__x1893[13];
extern __x1893	patternNotCodes;
typedef	tokenT	__x1897[768];
extern __x1897	keywordTokens;
extern TLint4	nKeys;
extern TLint4	nTxlKeys;
extern TLint4	lastKey;

TLboolean keyP ();

TLboolean uniformlyP ();
typedef	TLint4	kidPT;
typedef	TLint4	treePT;
typedef	treePT	consKidT;
typedef	TLint2	countT;
struct	patternAndParseTreeT {
    kindT	kind;
    countT	count;
    tokenT	name;
    tokenT	rawname;
    kidPT	kidsKP;
};
extern consKidT	*kids;
extern TLint4	kidsZ0;
extern struct patternAndParseTreeT	*trees;
extern TLint4	treesZ0;
extern TLint4	treeCount;
extern TLint4	kidCount;
extern TLint4	AVAILABLE;
extern TLint4	NILMARK;
extern TLint4	allocationStrategy;
typedef	treePT	__x1903[2048];
extern __x1903	inputTokenTP;
extern TLstring	outOfTreesMessage;

void newTree ();
extern TLstring	outOfKidsMessage;

void newKid ();

void newKids ();
extern TLchar	*identText;
extern TLint4	identTextZ0;
extern TLint4	identTextSize;
extern TLaddressint	*identTable;
extern TLint4	identTableZ0;
extern kindT	*identKind;
extern TLint4	identKindZ0;
extern TLint4	identTableSize;
extern treePT	*identTree;
extern TLint4	identTreeZ0;

extern tokenT ident_lookup ();

extern void ident_install ();

extern void ident_setkind ();
extern TLnat4	empty_T;
extern TLint4	emptyTP;
extern TLnat4	comma_T;
extern TLint4	commaTP;
extern TLnat4	anonymous_T;
extern TLnat4	NL_T;
extern TLnat4	FL_T;
extern TLnat4	IN_T;
extern TLnat4	EX_T;
extern TLnat4	SP_T;
extern TLnat4	TAB_T;
extern TLnat4	SPOFF_T;
extern TLnat4	SPON_T;
extern TLnat4	ATTR_T;
extern TLnat4	KEEP_T;
extern TLnat4	FENCE_T;
extern TLnat4	SEE_T;
extern TLnat4	NOT_T;
extern TLnat4	anyT;
extern TLnat4	quoteT;
extern TLnat4	underscoreT;
extern TLnat4	openbracketT;
extern TLnat4	includeT;
extern TLnat4	compoundsT;
extern TLnat4	commentsT;
extern TLnat4	keysT;
extern TLnat4	tokensT;
extern TLnat4	endT;
extern TLnat4	redefineT;
extern TLnat4	ENVIRONMENT_T;
extern TLnat4	dotT;
extern TLnat4	starT;
extern TLnat4	dollarT;
extern TLnat4	dotDotDotT;
extern TLnat4	barT;
extern TLnat4	TXL_optBar_T;
extern TLnat4	stringlit_T;
extern TLnat4	charlit_T;
extern TLnat4	token_T;
extern TLnat4	key_T;
extern TLnat4	number_T;
extern TLnat4	floatnumber_T;
extern TLnat4	decimalnumber_T;
extern TLnat4	integernumber_T;
extern TLnat4	id_T;
extern TLnat4	comment_T;
extern TLnat4	upperlowerid_T;
extern TLnat4	upperid_T;
extern TLnat4	lowerupperid_T;
extern TLnat4	lowerid_T;
extern TLnat4	srclinenumber_T;
extern TLnat4	srcfilename_T;
extern TLnat4	order_T;
extern TLnat4	choose_T;
extern TLnat4	literal_T;
extern TLnat4	firstTime_T;
extern TLnat4	subsequentUse_T;
extern TLnat4	expression_T;
extern TLnat4	lastExpression_T;
extern TLnat4	ruleCall_T;
extern TLnat4	leftchoose_T;
extern TLnat4	generaterepeat_T;
extern TLnat4	repeat_T;
extern TLnat4	generatelist_T;
extern TLnat4	list_T;
extern TLnat4	lookahead_T;
extern TLnat4	undefined_T;
extern TLnat4	usertoken1_T;
extern TLnat4	usertoken2_T;
extern TLnat4	usertoken3_T;
extern TLnat4	usertoken4_T;
extern TLnat4	usertoken5_T;
extern TLnat4	usertoken6_T;
extern TLnat4	usertoken7_T;
extern TLnat4	usertoken8_T;
extern TLnat4	usertoken9_T;
extern TLnat4	usertoken10_T;
extern TLnat4	usertoken11_T;
extern TLnat4	usertoken12_T;
extern TLnat4	usertoken13_T;
extern TLnat4	usertoken14_T;
extern TLnat4	usertoken15_T;
extern TLnat4	usertoken16_T;
extern TLnat4	usertoken17_T;
extern TLnat4	usertoken18_T;
extern TLnat4	usertoken19_T;
extern TLnat4	usertoken20_T;
extern TLnat4	usertoken21_T;
extern TLnat4	usertoken22_T;
extern TLnat4	usertoken23_T;
extern TLnat4	usertoken24_T;
extern TLnat4	usertoken25_T;
extern TLnat4	usertoken26_T;
extern TLnat4	usertoken27_T;
extern TLnat4	usertoken28_T;
extern TLnat4	usertoken29_T;
extern TLnat4	usertoken30_T;
extern TLnat4	newline_T;
extern TLnat4	space_T;
extern TLnat4	quit_T;
extern TLnat4	assert_T;
extern TLnat4	TXLargs_T;
extern TLnat4	TXLprogram_T;
extern TLnat4	TXLinput_T;
extern TLnat4	TXLexitcode_T;
extern TLnat4	ignore_T;
typedef	tokenT	__x1917[66];
extern __x1917	kindName;

kindT nameKind ();
struct	localInfoT {
    tokenT	name;
    tokenT	typename;
    tokenT	basetypename;
    TLnat2	partof;
    TLboolean	changed;
    TLboolean	global;
    TLnat2	refs;
    treePT	lastref;
};
typedef	struct localInfoT	__x1918[256];
struct	localsListT {
    __x1918	local;
    TLint4	nformals, nprelocals, nlocals;
};
typedef	TLint4	__x1919[256];
struct	callsListT {
    __x1919	call;
    TLint4	ncalls;
};
typedef	TLint1	partKind;
struct	partDescriptor {
    partKind	kind;
    tokenT	name;
    TLint4	nameRef;
    TLint4	globalRef;
    tokenT	target;
    tokenT	skipName;
    treePT	replacementTP;
    treePT	patternTP;
    TLboolean	isStarred;
    TLboolean	negated;
    TLboolean	anded;
    TLboolean	skipRepeat;
};
typedef	struct partDescriptor	__x1922[128];
typedef	__x1922	partList;
typedef	TLint4	ruleKind;
struct	ruleT {
    tokenT	name;
    struct localsListT	localVars;
    struct callsListT	calledRules;
    tokenT	target;
    tokenT	skipName;
    TLint4	prePatternCount;
    partList	prePattern;
    treePT	patternTP;
    TLint4	postPatternCount;
    partList	postPattern;
    treePT	replacementTP;
    ruleKind	kind;
    TLboolean	isStarred;
    TLboolean	isCondition;
    TLboolean	defined;
    TLboolean	called;
    TLboolean	skipRepeat;
};
typedef	struct ruleT	__x1923[4096];
extern __x1923	rules;
extern TLint4	ruleCount;
extern TLint4	mainRule;

void enterRuleName ();

void lookupLocalVar ();

void findLocalVar ();

void enterLocalVar ();

void enterRuleCall ();

void checkPredefinedFunctionScopeAndParameters ();
typedef	TLnat2	__x1971[1];
typedef	treePT	__x1970[256];
struct	ruleEnvironmentT {
    tokenT	name;
    treePT	scopeTP;
    __x1970	valueTP;
    treePT	resultTP;
    treePT	newscopeTP;
    __x1971	parentrefs;
    TLboolean	hasExported;
    TLint4	depth;
    TLaddressint	localsListAddr;
};

extern void tree_ops_makeOneKid ();

extern void tree_ops_makeTwoKids ();

extern void tree_ops_makeThreeKids ();

extern treePT tree_ops_kidTP ();

extern treePT tree_ops_kid1TP ();

extern treePT tree_ops_kid2TP ();

extern treePT tree_ops_kid3TP ();

extern treePT tree_ops_kid4TP ();

extern treePT tree_ops_kid5TP ();

extern treePT tree_ops_kid6TP ();

extern TLboolean tree_ops_plural_emptyP ();

extern treePT tree_ops_plural_firstTP ();

extern treePT tree_ops_plural_restTP ();

extern TLboolean tree_ops_isListOrRepeat ();

extern TLint4 tree_ops_lengthListOrRepeat ();

extern TLboolean tree_ops_isEmptyListOrRepeat ();

extern treePT tree_ops_listOrRepeatFirstTP ();

extern treePT tree_ops_listOrRepeatRestTP ();

extern TLboolean tree_ops_isListOrRepeatType ();

extern tokenT tree_ops_listOrRepeatBaseType ();

extern TLboolean tree_ops_treeIsTypeP ();

extern TLboolean tree_ops_treeMatchesTypeP ();

extern tokenT tree_ops_literalTypeName ();

extern TLboolean tree_ops_sameTrees ();

extern void tree_ops_copyTree ();

extern void tree_ops_extract ();

extern void tree_ops_substitute ();

extern void tree_ops_substituteLiteral ();

extern void tree_ops_findTreeType ();

extern treePT tree_ops_patternOrReplacement_litsAndVarsAndExpsTP ();

extern tokenT tree_ops_external_nameT ();

extern treePT tree_ops_external_formalsTP ();

extern tokenT tree_ops_rule_targetT ();

extern treePT tree_ops_rule_target_bracketedDescriptionTP ();

extern tokenT tree_ops_construct_varNameT ();

extern tokenT tree_ops_construct_targetT ();

extern treePT tree_ops_construct_replacementTP ();

extern treePT tree_ops_construct_bracketedDescriptionTP ();

extern TLboolean tree_ops_construct_isAnonymous ();

extern treePT tree_ops_construct_anonymousExpressionTP ();

extern tokenT tree_ops_deconstruct_varNameT ();

extern treePT tree_ops_deconstruct_patternTP ();

extern TLboolean tree_ops_deconstruct_isStarred ();

extern TLboolean tree_ops_deconstruct_negated ();

extern TLboolean tree_ops_deconstruct_isTyped ();

extern tokenT tree_ops_deconstruct_targetT ();

extern treePT tree_ops_deconstruct_optSkippingTP ();

extern tokenT tree_ops_import_export_targetT ();

extern treePT tree_ops_import_export_bracketedDescriptionTP ();

extern treePT tree_ops_import_patternTP ();

extern tokenT tree_ops_rule_nameT ();

extern treePT tree_ops_rule_prePatternTP ();

extern treePT tree_ops_rule_postPatternTP ();

extern treePT tree_ops_rule_patternTP ();

extern TLboolean tree_ops_rule_isStarred ();

extern TLboolean tree_ops_rule_isDollared ();

extern tokenT tree_ops_rule_replaceOrMatchT ();

extern treePT tree_ops_rule_optByReplacementTP ();

extern treePT tree_ops_optByReplacement_replacementTP ();

extern TLboolean tree_ops_optByReplacement_isAnonymous ();

extern treePT tree_ops_optByReplacement_anonymousExpressionTP ();

extern treePT tree_ops_rule_optSkippingTP ();

extern tokenT tree_ops_optSkipping_nameT ();

extern treePT tree_ops_rule_formalsTP ();

extern tokenT tree_ops_formal_nameT ();

extern tokenT tree_ops_formal_typeT ();

extern treePT tree_ops_formal_bracketedDescriptionTP ();

extern TLboolean tree_ops_isQuotedLiteral ();

extern tokenT tree_ops_literal_tokenT ();

extern tokenT tree_ops_literal_rawtokenT ();

extern kindT tree_ops_literal_kindT ();

extern tokenT tree_ops_ruleCall_nameT ();

extern treePT tree_ops_ruleCall_literalsTP ();

extern tokenT tree_ops_bracketedDescription_idT ();

extern treePT tree_ops_bracketedDescription_listRepeatOrOptTargetTP ();

extern tokenT tree_ops_firstTime_nameT ();

extern tokenT tree_ops_firstTime_typeT ();

extern tokenT tree_ops_expression_baseT ();

extern treePT tree_ops_expression_ruleCallsTP ();

extern treePT tree_ops_program_statementsTP ();

extern treePT tree_ops_keys_literalsTP ();

extern tokenT tree_ops_define_nameT ();

extern tokenT tree_ops_define_defineOrRedefineT ();

extern tokenT tree_ops_define_endDefineOrRedefineT ();

extern treePT tree_ops_define_optDotDotDotBarTP ();

extern treePT tree_ops_define_optBarDotDotDotTP ();

extern treePT tree_ops_define_literalsAndBracketedIdsTP ();

extern treePT tree_ops_define_barOrdersTP ();

extern treePT tree_ops_statement_keyDefRuleTP ();

extern TLboolean tree_ops_condition_is_assert ();

extern treePT tree_ops_condition_expressionTP ();

extern TLboolean tree_ops_condition_negated ();

extern TLboolean tree_ops_condition_anded ();

extern TLboolean tree_ops_literalOrBracketedIdP ();

extern TLboolean tree_ops_bracketedDescriptionP ();

extern TLboolean tree_ops_quotedLiteralP ();

extern TLboolean tree_ops_literalP ();

extern TLboolean tree_ops_listP ();

extern TLboolean tree_ops_repeatP ();

extern TLboolean tree_ops_list1P ();

extern TLboolean tree_ops_repeat1P ();

extern TLboolean tree_ops_optP ();

extern TLboolean tree_ops_attrP ();

extern TLboolean tree_ops_seeP ();

extern TLboolean tree_ops_notP ();

extern TLboolean tree_ops_fenceP ();

extern TLboolean tree_ops_pushP ();

extern TLboolean tree_ops_popP ();

void externalType ();

void predefinedParseError ();

void patternError ();

void parseInterruptError ();

void parseStackError ();
typedef	TLchar	__x2054[32768];

void printParse ();

void printPatternParse ();
typedef	treePT	__x2095[16384];

void printGrammar ();
typedef	TLchar	__x2110[33024];

void printLeaves ();

void printMatch ();
typedef	TLchar	__x2223[33024];

void quoteLeaves ();

void extractLeaves ();
typedef	treePT	__x2237[16384];
extern __x2237	symbolTable;
extern TLint4	symbolTableSize;

void enterSymbol ();

void lookupSymbol ();

void findSymbol ();

extern void bootstrap_makeGrammarTree ();

void scanner_tokenize ();
static TLint4	scanner_stdin;
static TLint4	scanner_inputStream;
struct	scanner___x2249 {
    TLint4	file;
    TLint4	filenum;
    TLint4	linenum;
};
typedef	struct scanner___x2249	scanner___x2248[8];
static scanner___x2248	scanner_includeStack;
static TLint4	scanner_includeDepth;
static TLstring	scanner_sourceFileDirectory;
typedef	TLchar	scanner___x2250[164096];
static scanner___x2250	scanner_inputline;
static TLstring	scanner_nextinputline;
static TLint4	scanner_nextlength;
static TLint4	scanner_inputchar;
static TLint4	scanner_filenum;
static TLint4	scanner_linenum;
static TLboolean	scanner_txlSource;
static TLboolean	scanner_fileInput;
typedef	TLchar	scanner___x2251[65792];
static scanner___x2251	scanner_sourceText;
static TLboolean	scanner_newlineComments;

static void scanner_installToken (kind, token, rawtoken)
kindT	kind;
tokenT	token;
tokenT	rawtoken;
{
    lastTokenHandle += 1;
    if (lastTokenHandle >= maxTokens) {
	{
	    TLstring	__x2255;
	    TL_TLS_TLSVIS((TLint4) maxTokens, (TLint4) 1, (TLint4) 10, __x2255);
	    {
		TLstring	__x2254;
		TL_TLS_TLSCAT("Input too large (total length > ", __x2255, __x2254);
		{
		    TLstring	__x2253;
		    TL_TLS_TLSCAT(__x2254, " tokens)", __x2253);
		    {
			TLstring	__x2252;
			TL_TLS_TLSCAT(__x2253, " (a larger size is required for this input)", __x2252);
			error("", __x2252, (TLint4) 21, (TLint4) 141);
		    };
		};
	    };
	};
    };
    inputTokens[lastTokenHandle - 1] = token;
    inputTokenRaw[lastTokenHandle - 1] = rawtoken;
    inputTokenKind[lastTokenHandle - 1] = kind;
    inputTokenLineNum[lastTokenHandle - 1] = (scanner_filenum * maxLines) + scanner_linenum;
    ident_setkind((tokenT) token, (kindT) kind);
    ident_setkind((tokenT) rawtoken, (kindT) kind);
    if ((options[19]) && (!scanner_txlSource)) {
	TL_TLI_TLISS ((TLint4) 0, (TLint2) 2);
	TL_TLI_TLIPS ((TLint4) 0, "<", (TLint2) 0);
	if (((* (TLchar *) (identTable[kindName[((TLnat4) kind)]]))) == '*') {
	    TL_TLI_TLISS ((TLint4) 0, (TLint2) 2);
	    TL_TLI_TLIPS ((TLint4) 0, ((* (TLstring *) ((unsigned long) (identTable[kindName[((TLnat4) kind)]]) + 1))), (TLint2) 0);
	} else {
	    TL_TLI_TLISS ((TLint4) 0, (TLint2) 2);
	    TL_TLI_TLIPS ((TLint4) 0, ((* (TLstring *) (identTable[kindName[((TLnat4) kind)]]))), (TLint2) 0);
	};
	TL_TLI_TLISS ((TLint4) 0, (TLint2) 2);
	TL_TLI_TLIPS ((TLint4) 0, " text=\"", (TLint2) 0);
	putxmlencode((TLint4) 0, (* (TLstring *) (identTable[rawtoken])));
	TL_TLI_TLISS ((TLint4) 0, (TLint2) 2);
	TL_TLI_TLIPS ((TLint4) 0, "\"/>", (TLint2) 0);
	TL_TLI_TLIPK ((TLint2) 0);
    };
}

static void scanner_getInputLine () {
    if (scanner_fileInput) {
	if ((options[36]) && (!scanner_txlSource)) {
	    if (((scanner_inputStream == scanner_stdin) && TL_TLI_TLIEOF((TLint4) -2)) || TL_TLI_TLIEOF((TLint4) scanner_inputStream)) {
		if (TL_TLS_TLSLEN(((* (TLstring *) scanner_inputline))) == 0) {
		    scanner_inputline[(0)] = (TLchar) '\376';
		};
	    } else {
		TLint4	lengthSoFar;
		lengthSoFar = TL_TLS_TLSLEN(((* (TLstring *) scanner_inputline)));
		for(;;) {
		    TLint4	bufferlength;
		    if (lengthSoFar >= (32768 * 4)) {
			break;
		    };
		    if (scanner_inputStream == scanner_stdin) {
			TL_TLI_TLISSI ();
			TL_TLI_TLIGSS((TLint4) 255, (* (TLstring *) &scanner_inputline[((lengthSoFar + 1) - 1)]), (TLint2) -2);
		    } else {
			TL_TLI_TLISS ((TLint4) scanner_inputStream, (TLint2) 1);
			TL_TLI_TLIGSS((TLint4) 255, (* (TLstring *) &scanner_inputline[((lengthSoFar + 1) - 1)]), (TLint2) scanner_inputStream);
		    };
		    bufferlength = TL_TLS_TLSLEN(((* (TLstring *) &scanner_inputline[((lengthSoFar + 1) - 1)])));
		    if (bufferlength == 255) {
			TLint4	nextIndex;
			nextIndex = lengthSoFar + bufferlength;
			for(;;) {
			    TLstring	buffer;
			    if (scanner_inputStream == scanner_stdin) {
				TL_TLI_TLISSI ();
				TL_TLI_TLIGSS((TLint4) 255, buffer, (TLint2) -2);
			    } else {
				TL_TLI_TLISS ((TLint4) scanner_inputStream, (TLint2) 1);
				TL_TLI_TLIGSS((TLint4) 255, buffer, (TLint2) scanner_inputStream);
			    };
			    bufferlength = TL_TLS_TLSLEN(buffer);
			    if ((((nextIndex - 1) + bufferlength) - lengthSoFar) > 32768) {
				{
				    TLstring	__x2267;
				    TL_TLS_TLSVIS((TLint4) 32768, (TLint4) 1, (TLint4) 10, __x2267);
				    {
					TLstring	__x2266;
					TL_TLS_TLSCAT("Input line too long (> ", __x2267, __x2266);
					{
					    TLstring	__x2265;
					    TL_TLS_TLSCAT(__x2266, " characters)", __x2265);
					    error("", __x2265, (TLint4) 21, (TLint4) 144);
					};
				    };
				};
			    };
			    TLSTRASS(255, (* (TLstring *) &scanner_inputline[((nextIndex + 1) - 1)]), buffer);
			    nextIndex += bufferlength;
			    if (bufferlength != 255) {
				break;
			    };
			};
			lengthSoFar = nextIndex;
		    } else {
			lengthSoFar += bufferlength;
		    };
		    TLSTRASS(255, (* (TLstring *) &scanner_inputline[((lengthSoFar + 1) - 1)]), "\n");
		    lengthSoFar += 1;
		    if (((scanner_inputStream == scanner_stdin) && TL_TLI_TLIEOF((TLint4) -2)) || TL_TLI_TLIEOF((TLint4) scanner_inputStream)) {
			break;
		    };
		};
	    };
	} else {
	    if (((scanner_inputStream == scanner_stdin) && TL_TLI_TLIEOF((TLint4) -2)) || TL_TLI_TLIEOF((TLint4) scanner_inputStream)) {
		scanner_inputline[(0)] = (TLchar) '\376';
	    } else {
		if (scanner_inputStream == scanner_stdin) {
		    TL_TLI_TLISSI ();
		    TL_TLI_TLIGSS((TLint4) 255, (* (TLstring *) scanner_inputline), (TLint2) -2);
		} else {
		    TL_TLI_TLISS ((TLint4) scanner_inputStream, (TLint2) 1);
		    TL_TLI_TLIGSS((TLint4) 255, (* (TLstring *) scanner_inputline), (TLint2) scanner_inputStream);
		};
		if (TL_TLS_TLSLEN(((* (TLstring *) scanner_inputline))) == 255) {
		    if (!scanner_txlSource) {
			TLint4	nextIndex;
			nextIndex = 256;
			for(;;) {
			    TLstring	buffer;
			    TLint4	bufferlength;
			    if (scanner_inputStream == scanner_stdin) {
				TL_TLI_TLISSI ();
				TL_TLI_TLIGSS((TLint4) 255, buffer, (TLint2) -2);
			    } else {
				TL_TLI_TLISS ((TLint4) scanner_inputStream, (TLint2) 1);
				TL_TLI_TLIGSS((TLint4) 255, buffer, (TLint2) scanner_inputStream);
			    };
			    bufferlength = TL_TLS_TLSLEN(buffer);
			    if (((nextIndex - 1) + bufferlength) > 32768) {
				{
				    TLstring	__x2275;
				    TL_TLS_TLSVIS((TLint4) 32768, (TLint4) 1, (TLint4) 10, __x2275);
				    {
					TLstring	__x2274;
					TL_TLS_TLSCAT("Input line too long (> ", __x2275, __x2274);
					{
					    TLstring	__x2273;
					    TL_TLS_TLSCAT(__x2274, " characters)", __x2273);
					    error("", __x2273, (TLint4) 21, (TLint4) 144);
					};
				    };
				};
			    };
			    TLSTRASS(255, (* (TLstring *) &scanner_inputline[(nextIndex - 1)]), buffer);
			    if (bufferlength != 255) {
				break;
			    };
			    nextIndex += 255;
			};
		    } else {
			{
			    TLstring	__x2279;
			    TL_TLS_TLSVIS((TLint4) 254, (TLint4) 1, (TLint4) 10, __x2279);
			    {
				TLstring	__x2278;
				TL_TLS_TLSCAT("TXL program line too long (> ", __x2279, __x2278);
				{
				    TLstring	__x2277;
				    TL_TLS_TLSCAT(__x2278, " characters)", __x2277);
				    error("", __x2277, (TLint4) 21, (TLint4) 145);
				};
			    };
			};
		    };
		};
		TLSTRCATASS((* (TLstring *) scanner_inputline), "\n", 255);
	    };
	};
    } else {
	if (((scanner_sourceText[(0)]) != (TLchar) '\376') || ((scanner_sourceText[(1)]) != '\0')) {
	    TLSTRASS(255, (* (TLstring *) scanner_inputline), (* (TLstring *) scanner_sourceText));
	    TLSTRCATASS((* (TLstring *) scanner_inputline), "\n", 255);
	    scanner_sourceText[(0)] = (TLchar) '\376';
	    scanner_sourceText[(1)] = '\0';
	} else {
	    scanner_inputline[(0)] = (TLchar) '\376';
	};
    };
    scanner_inputchar = 1;
}

static void scanner_PushInclude () {
    TLstring	newFileName;
    TLstring	oldNewFileName;
    TLint4	newInputStream;
    TLBIND((*is), struct scanner___x2249);
    TLSTRASS(255, newFileName, (* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)]));
    if (TL_TLS_TLSIND(newFileName, "\"") != 0) {
	{
	    TLstring	__x2285;
	    TL_TLS_TLSBXS(__x2285, (TLint4) 0, (TLint4) (TL_TLS_TLSIND(newFileName, "\"") + 1), newFileName);
	    TLSTRASS(255, newFileName, __x2285);
	};
    };
    if (TL_TLS_TLSIND(newFileName, "\"") != 0) {
	{
	    TLstring	__x2286;
	    TL_TLS_TLSBXX(__x2286, (TLint4) (TL_TLS_TLSIND(newFileName, "\"") - 1), (TLint4) 1, newFileName);
	    TLSTRASS(255, newFileName, __x2286);
	};
    };
    TLSTRASS(255, oldNewFileName, newFileName);
    {
	TLstring	__x2287;
	TL_TLS_TLSCAT(scanner_sourceFileDirectory, newFileName, __x2287);
	TLSTRASS(255, newFileName, __x2287);
    };
    if (nFiles == maxFiles) {
	{
	    TLstring	__x2290;
	    TL_TLS_TLSVIS((TLint4) maxFiles, (TLint4) 1, (TLint4) 10, __x2290);
	    {
		TLstring	__x2289;
		TL_TLS_TLSCAT("Too many source include files (>", __x2290, __x2289);
		{
		    TLstring	__x2288;
		    TL_TLS_TLSCAT(__x2289, ")", __x2288);
		    error("", __x2288, (TLint4) 21, (TLint4) 149);
		};
	    };
	};
    };
    TL_TLI_TLIOF ((TLnat2) 2, newFileName, &newInputStream);
    {
	register TLint4	i;
	TLint4	__x2291;
	__x2291 = nTxlIncludes;
	i = 1;
	if (i <= __x2291) {
	    for(;;) {
		if (newInputStream != 0) {
		    break;
		};
		{
		    TLstring	__x2293;
		    TL_TLS_TLSCAT(txlIncludes[i - 1], directoryChar, __x2293);
		    {
			TLstring	__x2292;
			TL_TLS_TLSCAT(__x2293, oldNewFileName, __x2292);
			TLSTRASS(255, newFileName, __x2292);
		    };
		};
		TL_TLI_TLIOF ((TLnat2) 2, newFileName, &newInputStream);
		if (i == __x2291) break;
		i++;
	    }
	};
    };
    if (newInputStream == 0) {
	{
	    TLstring	__x2295;
	    TL_TLS_TLSCAT("Unable to find include file \'", oldNewFileName, __x2295);
	    {
		TLstring	__x2294;
		TL_TLS_TLSCAT(__x2295, "\'", __x2294);
		error("", __x2294, (TLint4) 20, (TLint4) 150);
	    };
	};
    };
    if (scanner_includeDepth == 8) {
	{
	    TLstring	__x2298;
	    TL_TLS_TLSVIS((TLint4) 8, (TLint4) 1, (TLint4) 10, __x2298);
	    {
		TLstring	__x2297;
		TL_TLS_TLSCAT("Include file nesting too deep (>", __x2298, __x2297);
		{
		    TLstring	__x2296;
		    TL_TLS_TLSCAT(__x2297, ")", __x2296);
		    error("", __x2296, (TLint4) 21, (TLint4) 151);
		};
	    };
	};
    };
    scanner_includeDepth += 1;
    is = &(scanner_includeStack[scanner_includeDepth - 1]);
    (*is).file = scanner_inputStream;
    (*is).filenum = scanner_filenum;
    (*is).linenum = scanner_linenum;
    nFiles += 1;
    TLSTRASS(255, fileNames[nFiles - 1], newFileName);
    scanner_filenum = nFiles;
    scanner_inputStream = newInputStream;
    scanner_linenum = 0;
    scanner_getInputLine();
}

static void scanner_PopInclude () {
    TLBIND((*is), struct scanner___x2249);
    TL_TLI_TLICL ((TLint4) scanner_inputStream);
    is = &(scanner_includeStack[scanner_includeDepth - 1]);
    scanner_inputStream = (*is).file;
    scanner_filenum = (*is).filenum;
    scanner_linenum = (*is).linenum;
    scanner_includeDepth -= 1;
    scanner_inputline[(0)] = '\0';
    scanner_inputchar = 1;
}

static void scanner_openFile (fileNameOrText)
TLstring	fileNameOrText;
{
    nFiles = 1;
    if (scanner_fileInput) {
	TLSTRASS(255, fileNames[0], fileNameOrText);
	if (((strcmp(fileNameOrText, "") == 0) || (strcmp(fileNameOrText, "stdin") == 0)) || (strcmp(fileNameOrText, "STDIN") == 0)) {
	    scanner_inputStream = scanner_stdin;
	} else {
	    TL_TLI_TLIOF ((TLnat2) 2, fileNameOrText, &scanner_inputStream);
	};
	if (scanner_inputStream == 0) {
	    {
		TLstring	__x2300;
		TL_TLS_TLSCAT("Unable to open source file \'", fileNameOrText, __x2300);
		{
		    TLstring	__x2299;
		    TL_TLS_TLSCAT(__x2300, "\'", __x2299);
		    error("", __x2299, (TLint4) 20, (TLint4) 152);
		};
	    };
	};
	if ((TL_TLS_TLSIND(fileNameOrText, "/") != 0) || (TL_TLS_TLSIND(fileNameOrText, "\\") != 0)) {
	    TLSTRASS(255, scanner_sourceFileDirectory, fileNameOrText);
	    for(;;) {
		{
		    TLchar	__x2302[2];
		    {
			TLchar	__x2301[2];
			TL_TLS_TLSBS(__x2301, (TLint4) 0, scanner_sourceFileDirectory);
			if ((strcmp(__x2301, "/") == 0) || ((TL_TLS_TLSBS(__x2302, (TLint4) 0, scanner_sourceFileDirectory), strcmp(__x2302, "\\") == 0))) {
			    break;
			};
		    };
		};
		{
		    TLstring	__x2303;
		    TL_TLS_TLSBXS(__x2303, (TLint4) -1, (TLint4) 1, scanner_sourceFileDirectory);
		    TLSTRASS(255, scanner_sourceFileDirectory, __x2303);
		};
	    };
	};
    } else {
	TLSTRASS(255, fileNames[0], "(no file)");
	TLSTRASS(255, (* (TLstring *) scanner_sourceText), fileNameOrText);
    };
    if ((options[36]) && (!scanner_txlSource)) {
	if ((scanner_newlineComments && (options[34])) && (!(options[31]))) {
	    TLSTRASS(255, (* (TLstring *) scanner_inputline), "\n");
	} else {
	    scanner_inputline[(0)] = '\0';
	};
    };
    scanner_filenum = 1;
    scanner_linenum = 0;
    scanner_getInputLine();
    if ((options[36]) && (!scanner_txlSource)) {
	if ((scanner_newlineComments && (options[34])) && (!(options[31]))) {
	    scanner_linenum = 0;
	} else {
	    scanner_linenum = 1;
	};
    } else {
	scanner_linenum = 1;
    };
}

static void scanner_closeFile () {
    if (scanner_fileInput && (scanner_inputStream != scanner_stdin)) {
	TL_TLI_TLICL ((TLint4) scanner_inputStream);
	scanner_inputStream = 0;
    };
}
typedef	TLboolean	scanner___x2306[32];
static scanner___x2306	scanner_ifdefStack;
typedef	TLint4	scanner___x2309[32];
static scanner___x2309	scanner_ifdefFile;
static TLint4	scanner_ifdefTop;

static void scanner_synchronizePreprocessor () {
    if ((scanner_ifdefTop > 0) && ((scanner_ifdefFile[scanner_ifdefTop - 1]) == scanner_filenum)) {
	{
	    TLstring	__x2315;
	    TL_TLS_TLSVIS((TLint4) (scanner_linenum + 1), (TLint4) 1, (TLint4) 10, __x2315);
	    {
		TLstring	__x2314;
		TL_TLS_TLSCAT("line ", __x2315, __x2314);
		{
		    TLstring	__x2313;
		    TL_TLS_TLSCAT(__x2314, " of ", __x2313);
		    {
			TLstring	__x2312;
			TL_TLS_TLSCAT(__x2313, fileNames[scanner_filenum - 1], __x2312);
			error(__x2312, "Preprocessor syntax error: missing #endif directive", (TLint4) 20, (TLint4) 153);
		    };
		};
	    };
	};
	scanner_ifdefTop = 0;
    };
}

static void scanner_defineIfdefSymbol (symbol)
TLstring	symbol;
{
    if (nIfdefSymbols < 64) {
	nIfdefSymbols += 1;
	TLSTRASS(255, ifdefSymbols[nIfdefSymbols - 1], symbol);
    } else {
	{
	    TLstring	__x2318;
	    TL_TLS_TLSVIS((TLint4) 64, (TLint4) 0, (TLint4) 10, __x2318);
	    {
		TLstring	__x2317;
		TL_TLS_TLSCAT("Too many preprocessor symbols (> ", __x2318, __x2317);
		{
		    TLstring	__x2316;
		    TL_TLS_TLSCAT(__x2317, ")", __x2316);
		    error("", __x2316, (TLint4) 21, (TLint4) 154);
		};
	    };
	};
    };
}

static TLint4 scanner_lookupIfdefSymbol (symbol)
TLstring	symbol;
{
    {
	register TLint4	i;
	TLint4	__x2319;
	__x2319 = nIfdefSymbols;
	i = 1;
	if (i <= __x2319) {
	    for(;;) {
		if (strcmp(ifdefSymbols[i - 1], symbol) == 0) {
		    return (i);
		};
		if (i == __x2319) break;
		i++;
	    }
	};
    };
    return (0);
    /* NOTREACHED */
}

static void scanner_undefineIfdefSymbol (symbol)
TLstring	symbol;
{
    TLint4	symbolIndex;
    symbolIndex = scanner_lookupIfdefSymbol(symbol);
    if (symbolIndex != 0) {
	TLSTRASS(255, ifdefSymbols[symbolIndex - 1], "");
    } else {
    };
}

static void scanner_pushIfdef (symbol, negated)
TLstring	symbol;
TLboolean	negated;
{
    TLint4	symbolIndex;
    symbolIndex = scanner_lookupIfdefSymbol(symbol);
    if (scanner_ifdefTop < 32) {
	scanner_ifdefTop += 1;
	scanner_ifdefFile[scanner_ifdefTop - 1] = scanner_filenum;
	if (negated) {
	    scanner_ifdefStack[scanner_ifdefTop - 1] = symbolIndex == 0;
	} else {
	    scanner_ifdefStack[scanner_ifdefTop - 1] = symbolIndex != 0;
	};
    } else {
	{
	    TLstring	__x2322;
	    TL_TLS_TLSVIS((TLint4) 32, (TLint4) 0, (TLint4) 10, __x2322);
	    {
		TLstring	__x2321;
		TL_TLS_TLSCAT("#ifdef nesting too deep (>", __x2322, __x2321);
		{
		    TLstring	__x2320;
		    TL_TLS_TLSCAT(__x2321, " levels deep)", __x2320);
		    error("", __x2320, (TLint4) 21, (TLint4) 155);
		};
	    };
	};
    };
}

static void scanner_popIfdef () {
    if (scanner_ifdefTop > 0) {
	scanner_ifdefTop -= 1;
    } else {
	{
	    TLstring	__x2326;
	    TL_TLS_TLSVIS((TLint4) (scanner_linenum + 1), (TLint4) 1, (TLint4) 10, __x2326);
	    {
		TLstring	__x2325;
		TL_TLS_TLSCAT("line ", __x2326, __x2325);
		{
		    TLstring	__x2324;
		    TL_TLS_TLSCAT(__x2325, " of ", __x2324);
		    {
			TLstring	__x2323;
			TL_TLS_TLSCAT(__x2324, fileNames[scanner_filenum - 1], __x2323);
			error(__x2323, "Preprocessor syntax error: too many #endif directives (no matching #if)", (TLint4) 20, (TLint4) 156);
		    };
		};
	    };
	};
    };
}

static TLboolean scanner_trueIfdef () {
    return (scanner_ifdefStack[scanner_ifdefTop - 1]);
    /* NOTREACHED */
}

static void scanner_flushLinesUntilPreprocessorDirective (whichDirective)
TLint4	whichDirective;
{
    for(;;) {
	scanner_getInputLine();
	if ((scanner_inputline[(scanner_inputchar - 1)]) == (TLchar) '\376') {
	    break;
	};
	if (TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), "#") != 0) {
	    TLint4	startchar;
	    startchar = scanner_inputchar;
	    for(;;) {
		if (!(spaceP[scanner_inputline[(scanner_inputchar - 1)]])) {
		    break;
		};
		scanner_inputchar += 1;
	    };
	    if ((scanner_inputline[(scanner_inputchar - 1)]) == '#') {
		scanner_inputchar += 1;
		for(;;) {
		    if (!(spaceP[scanner_inputline[(scanner_inputchar - 1)]])) {
			break;
		    };
		    scanner_inputchar += 1;
		};
		if ((TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), "end") == 1) || ((whichDirective == 1) && (((TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), "elsif") == 1) || (TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), "elif") == 1)) || (TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), "else") == 1)))) {
		    scanner_inputchar = startchar;
		    break;
		} else {
		    if (TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), "if") == 1) {
			scanner_flushLinesUntilPreprocessorDirective((TLint4) 2);
		    };
		};
	    };
	};
    };
    if ((scanner_inputline[(scanner_inputchar - 1)]) == (TLchar) '\376') {
	{
	    TLstring	__x2336;
	    TL_TLS_TLSVIS((TLint4) (scanner_linenum + 1), (TLint4) 1, (TLint4) 10, __x2336);
	    {
		TLstring	__x2335;
		TL_TLS_TLSCAT("line ", __x2336, __x2335);
		{
		    TLstring	__x2334;
		    TL_TLS_TLSCAT(__x2335, " of ", __x2334);
		    {
			TLstring	__x2333;
			TL_TLS_TLSCAT(__x2334, fileNames[scanner_filenum - 1], __x2333);
			error(__x2333, "Preprocessor syntax error: missing #endif directive", (TLint4) 20, (TLint4) 157);
		    };
		};
	    };
	};
    };
}

static void scanner_sortTokenPatterns ();

static void scanner_handlePreprocessorDirective () {
    scanner_inputchar += 1;
    for(;;) {
	if (!(spaceP[scanner_inputline[(scanner_inputchar - 1)]])) {
	    break;
	};
	scanner_inputchar += 1;
    };
    if ((TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), "def") == 1) || (TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), "undef") == 1)) {
	TLboolean	define;
	TLint4	startchar;
	TLstring	symbol;
	define = (scanner_inputline[(scanner_inputchar - 1)]) == 'd';
	for(;;) {
	    if (((scanner_inputline[(scanner_inputchar - 1)]) == '\0') || (spaceP[scanner_inputline[(scanner_inputchar - 1)]])) {
		break;
	    };
	    scanner_inputchar += 1;
	};
	for(;;) {
	    if (!(spaceP[scanner_inputline[(scanner_inputchar - 1)]])) {
		break;
	    };
	    scanner_inputchar += 1;
	};
	startchar = scanner_inputchar;
	for(;;) {
	    if (!(idP[scanner_inputline[(scanner_inputchar - 1)]])) {
		break;
	    };
	    scanner_inputchar += 1;
	};
	{
	    TLstring	__x2339;
	    TL_TLS_TLSBXX(__x2339, (TLint4) (scanner_inputchar - 1), (TLint4) startchar, ((* (TLstring *) scanner_inputline)));
	    TLSTRASS(255, symbol, __x2339);
	};
	if (strcmp(symbol, "") == 0) {
	    {
		TLstring	__x2344;
		TL_TLS_TLSVIS((TLint4) (scanner_linenum + 1), (TLint4) 1, (TLint4) 10, __x2344);
		{
		    TLstring	__x2343;
		    TL_TLS_TLSCAT("line ", __x2344, __x2343);
		    {
			TLstring	__x2342;
			TL_TLS_TLSCAT(__x2343, " of ", __x2342);
			{
			    TLstring	__x2341;
			    TL_TLS_TLSCAT(__x2342, fileNames[scanner_filenum - 1], __x2341);
			    error(__x2341, "Preprocessor syntax error: missing symbol in #define or #undefine directive", (TLint4) 20, (TLint4) 158);
			};
		    };
		};
	    };
	};
	if (define) {
	    scanner_defineIfdefSymbol(symbol);
	} else {
	    scanner_undefineIfdefSymbol(symbol);
	};
	scanner_getInputLine();
    } else {
	if ((((TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), "if") == 1) || (TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), "elsif") == 1)) || (TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), "elif") == 1)) || (TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), "elseif") == 1)) {
	    TLboolean	firstif;
	    TLint4	ifindex;
	    TLboolean	negated;
	    TLint4	startchar;
	    TLstring	symbol;
	    firstif = (scanner_inputline[(scanner_inputchar - 1)]) == 'i';
	    ifindex = TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), "if");
	    negated = (scanner_inputline[((((scanner_inputchar - 1) + ifindex) + 2) - 1)]) == 'n';
	    for(;;) {
		if (((scanner_inputline[(scanner_inputchar - 1)]) == '\0') || (spaceP[scanner_inputline[(scanner_inputchar - 1)]])) {
		    break;
		};
		scanner_inputchar += 1;
	    };
	    for(;;) {
		if (!(spaceP[scanner_inputline[(scanner_inputchar - 1)]])) {
		    break;
		};
		scanner_inputchar += 1;
	    };
	    startchar = scanner_inputchar;
	    for(;;) {
		if (!(idP[scanner_inputline[(scanner_inputchar - 1)]])) {
		    break;
		};
		scanner_inputchar += 1;
	    };
	    {
		TLstring	__x2350;
		TL_TLS_TLSBXX(__x2350, (TLint4) (scanner_inputchar - 1), (TLint4) startchar, ((* (TLstring *) scanner_inputline)));
		TLSTRASS(255, symbol, __x2350);
	    };
	    if (strcmp(symbol, "") == 0) {
		{
		    TLstring	__x2355;
		    TL_TLS_TLSVIS((TLint4) (scanner_linenum + 1), (TLint4) 1, (TLint4) 10, __x2355);
		    {
			TLstring	__x2354;
			TL_TLS_TLSCAT("line ", __x2355, __x2354);
			{
			    TLstring	__x2353;
			    TL_TLS_TLSCAT(__x2354, " of ", __x2353);
			    {
				TLstring	__x2352;
				TL_TLS_TLSCAT(__x2353, fileNames[scanner_filenum - 1], __x2352);
				error(__x2352, "Preprocessor syntax error: missing symbol in #if or #elsif directive", (TLint4) 20, (TLint4) 159);
			    };
			};
		    };
		};
	    };
	    if (strcmp(symbol, "not") == 0) {
		negated = !negated;
		for(;;) {
		    if (!(spaceP[scanner_inputline[(scanner_inputchar - 1)]])) {
			break;
		    };
		    scanner_inputchar += 1;
		};
		startchar = scanner_inputchar;
		for(;;) {
		    if (!(idP[scanner_inputline[(scanner_inputchar - 1)]])) {
			break;
		    };
		    scanner_inputchar += 1;
		};
		{
		    TLstring	__x2356;
		    TL_TLS_TLSBXX(__x2356, (TLint4) (scanner_inputchar - 1), (TLint4) startchar, ((* (TLstring *) scanner_inputline)));
		    TLSTRASS(255, symbol, __x2356);
		};
		if (strcmp(symbol, "") == 0) {
		    {
			TLstring	__x2361;
			TL_TLS_TLSVIS((TLint4) (scanner_linenum + 1), (TLint4) 1, (TLint4) 10, __x2361);
			{
			    TLstring	__x2360;
			    TL_TLS_TLSCAT("line ", __x2361, __x2360);
			    {
				TLstring	__x2359;
				TL_TLS_TLSCAT(__x2360, " of ", __x2359);
				{
				    TLstring	__x2358;
				    TL_TLS_TLSCAT(__x2359, fileNames[scanner_filenum - 1], __x2358);
				    error(__x2358, "Preprocessor syntax error: missing symbol in #if or #elsif directive", (TLint4) 20, (TLint4) 160);
				};
			    };
			};
		    };
		};
	    };
	    if (firstif) {
		scanner_pushIfdef(symbol, (TLboolean) negated);
		if (!scanner_trueIfdef()) {
		    scanner_flushLinesUntilPreprocessorDirective((TLint4) 1);
		} else {
		    scanner_getInputLine();
		};
	    } else {
		if (scanner_ifdefTop == 0) {
		    {
			TLstring	__x2365;
			TL_TLS_TLSVIS((TLint4) (scanner_linenum + 1), (TLint4) 1, (TLint4) 10, __x2365);
			{
			    TLstring	__x2364;
			    TL_TLS_TLSCAT("line ", __x2365, __x2364);
			    {
				TLstring	__x2363;
				TL_TLS_TLSCAT(__x2364, " of ", __x2363);
				{
				    TLstring	__x2362;
				    TL_TLS_TLSCAT(__x2363, fileNames[scanner_filenum - 1], __x2362);
				    error(__x2362, "Preprocessor syntax error: #elsif not nested inside #if", (TLint4) 20, (TLint4) 161);
				};
			    };
			};
		    };
		};
		if (scanner_trueIfdef()) {
		    scanner_flushLinesUntilPreprocessorDirective((TLint4) 2);
		} else {
		    scanner_popIfdef();
		    scanner_pushIfdef(symbol, (TLboolean) negated);
		    if (!scanner_trueIfdef()) {
			scanner_flushLinesUntilPreprocessorDirective((TLint4) 1);
		    } else {
			scanner_getInputLine();
		    };
		};
	    };
	} else {
	    if (TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), "else") == 1) {
		if (scanner_ifdefTop == 0) {
		    {
			TLstring	__x2370;
			TL_TLS_TLSVIS((TLint4) (scanner_linenum + 1), (TLint4) 1, (TLint4) 10, __x2370);
			{
			    TLstring	__x2369;
			    TL_TLS_TLSCAT("line ", __x2370, __x2369);
			    {
				TLstring	__x2368;
				TL_TLS_TLSCAT(__x2369, " of ", __x2368);
				{
				    TLstring	__x2367;
				    TL_TLS_TLSCAT(__x2368, fileNames[scanner_filenum - 1], __x2367);
				    error(__x2367, "Preprocessor syntax error: #else not nested inside #if", (TLint4) 20, (TLint4) 162);
				};
			    };
			};
		    };
		};
		if (scanner_trueIfdef()) {
		    scanner_flushLinesUntilPreprocessorDirective((TLint4) 2);
		} else {
		    scanner_getInputLine();
		};
	    } else {
		if (TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), "end") == 1) {
		    scanner_popIfdef();
		    scanner_getInputLine();
		} else {
		    if (TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), "pragma") == 1) {
			processOptionsString((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)]));
			scanner_getInputLine();
			if (updatedChars) {
			    scanner_sortTokenPatterns();
			};
		    } else {
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '!') {
			    scanner_getInputLine();
			} else {
			    {
				TLstring	__x2378;
				TL_TLS_TLSCAT("Preprocessor directive syntax error at or near:\n    ", (* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)]), __x2378);
				{
				    TLstring	__x2377;
				    TL_TLS_TLSVIS((TLint4) (scanner_linenum + 1), (TLint4) 1, (TLint4) 10, __x2377);
				    {
					TLstring	__x2376;
					TL_TLS_TLSCAT("line ", __x2377, __x2376);
					{
					    TLstring	__x2375;
					    TL_TLS_TLSCAT(__x2376, " of ", __x2375);
					    {
						TLstring	__x2374;
						TL_TLS_TLSCAT(__x2375, fileNames[scanner_filenum - 1], __x2374);
						error(__x2374, __x2378, (TLint4) 20, (TLint4) 163);
					    };
					};
				    };
				};
			    };
			};
		    };
		};
	    };
	};
    };
}

static void scanner_skipTxlComment () {
    if (((scanner_inputline[((scanner_inputchar + 1) - 1)]) == '(') || ((scanner_inputline[((scanner_inputchar + 1) - 1)]) == '{')) {
	TLstring	comend;
	TLint4	comindex;
	TLSTRASS(255, comend, ")%");
	if ((scanner_inputline[((scanner_inputchar + 1) - 1)]) == '{') {
	    TLSTRASS(255, comend, "}%");
	};
	for(;;) {
	    comindex = TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)])), comend);
	    if (comindex != 0) {
		break;
	    };
	    scanner_getInputLine();
	    scanner_linenum += 1;
	    if ((scanner_inputline[(scanner_inputchar - 1)]) == (TLchar) '\376') {
		break;
	    };
	};
	if ((scanner_inputline[(scanner_inputchar - 1)]) == (TLchar) '\376') {
	    {
		TLstring	__x2381;
		TL_TLS_TLSCAT("at end of ", fileNames[scanner_filenum - 1], __x2381);
		error(__x2381, "Syntax error - comment ends at end of file", (TLint4) 20, (TLint4) 164);
	    };
	};
    };
    scanner_getInputLine();
    scanner_linenum += 1;
}

static void scanner_skipSeparators () {
    if ((options[36]) && (!scanner_txlSource)) {
	for(;;) {
	    if (!(options[31])) {
		for(;;) {
		    if (!(spaceP[scanner_inputline[(scanner_inputchar - 1)]])) {
			break;
		    };
		    if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			scanner_linenum += 1;
		    };
		    scanner_inputchar += 1;
		};
	    };
	    if (scanner_fileInput && (scanner_inputchar > (32768 * (3)))) {
		TLSTRASS(255, (* (TLstring *) scanner_inputline), (* (TLstring *) &scanner_inputline[(scanner_inputchar - 1)]));
		scanner_getInputLine();
		if ((!(spaceP[scanner_inputline[(scanner_inputchar - 1)]])) || (options[31])) {
		    return;
		};
	    } else {
		if ((scanner_inputline[(scanner_inputchar - 1)]) == '\0') {
		    scanner_inputline[(0)] = '\0';
		    scanner_getInputLine();
		    if ((!(spaceP[scanner_inputline[(scanner_inputchar - 1)]])) || (options[31])) {
			return;
		    };
		} else {
		    return;
		};
	    };
	};
    } else {
	for(;;) {
	    TLboolean	beginningOfLine;
	    beginningOfLine = scanner_inputchar == 1;
	    if (scanner_txlSource || (!(options[31]))) {
		for(;;) {
		    if (!(spaceP[scanner_inputline[(scanner_inputchar - 1)]])) {
			break;
		    };
		    if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			scanner_linenum += 1;
		    };
		    scanner_inputchar += 1;
		};
	    };
	    if ((scanner_inputline[(scanner_inputchar - 1)]) == '\0') {
		scanner_getInputLine();
		if ((scanner_inputline[(scanner_inputchar - 1)]) == (TLchar) '\376') {
		    break;
		};
	    } else {
		if (scanner_txlSource) {
		    if ((scanner_inputline[(scanner_inputchar - 1)]) == '%') {
			scanner_skipTxlComment();
		    } else {
			if (beginningOfLine && ((scanner_inputline[(scanner_inputchar - 1)]) == '#')) {
			    scanner_handlePreprocessorDirective();
			} else {
			    return;
			};
		    };
		} else {
		    return;
		};
	    };
	};
    };
}
typedef	TLchar	scanner___x2384[256];

static TLboolean scanner_scanToken (pattern, startpos, endpos, test)
scanner___x2384	pattern;
TLint4	startpos;
TLint4	endpos;
TLboolean	test;
{
    TLint4	pos;
    TLint4	startchar;
    TLint4	startline;
    pos = startpos;
    startchar = scanner_inputchar;
    startline = scanner_linenum;
    for(;;) {
	TLchar	pat;
	TLboolean	fail;
	pat = pattern[(pos - 1)];
	fail = 1;
	switch (pat) {
	    case (TLchar) '\254':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if (!(digitP[scanner_inputline[(scanner_inputchar - 1)]])) {
			    break;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\255':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if (!(alphaP[scanner_inputline[(scanner_inputchar - 1)]])) {
			    break;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\265':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if (!(alphaidP[scanner_inputline[(scanner_inputchar - 1)]])) {
			    break;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\256':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if (!(idP[scanner_inputline[(scanner_inputchar - 1)]])) {
			    break;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\257':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if (!(upperP[scanner_inputline[(scanner_inputchar - 1)]])) {
			    break;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\260':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if (!(upperidP[scanner_inputline[(scanner_inputchar - 1)]])) {
			    break;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\261':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if (!(lowerP[scanner_inputline[(scanner_inputchar - 1)]])) {
			    break;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\262':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if (!(loweridP[scanner_inputline[(scanner_inputchar - 1)]])) {
			    break;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\263':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if (!(specialP[scanner_inputline[(scanner_inputchar - 1)]])) {
			    break;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\264':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\0') {
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			    scanner_linenum += 1;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\253':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if ((scanner_inputline[(scanner_inputchar - 1)]) != '\n') {
			    break;
			};
			scanner_inputchar += 1;
			scanner_linenum += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\266':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if ((scanner_inputline[(scanner_inputchar - 1)]) != '\r') {
			    break;
			};
			scanner_inputchar += 1;
			scanner_linenum += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\252':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if ((scanner_inputline[(scanner_inputchar - 1)]) != '\t') {
			    break;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\267':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if ((digitP[scanner_inputline[(scanner_inputchar - 1)]]) || ((scanner_inputline[(scanner_inputchar - 1)]) == '\0')) {
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			    scanner_linenum += 1;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\270':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if ((alphaP[scanner_inputline[(scanner_inputchar - 1)]]) || ((scanner_inputline[(scanner_inputchar - 1)]) == '\0')) {
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			    scanner_linenum += 1;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\314':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if ((alphaidP[scanner_inputline[(scanner_inputchar - 1)]]) || ((scanner_inputline[(scanner_inputchar - 1)]) == '\0')) {
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			    scanner_linenum += 1;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\274':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if ((idP[scanner_inputline[(scanner_inputchar - 1)]]) || ((scanner_inputline[(scanner_inputchar - 1)]) == '\0')) {
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			    scanner_linenum += 1;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\275':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if ((upperP[scanner_inputline[(scanner_inputchar - 1)]]) || ((scanner_inputline[(scanner_inputchar - 1)]) == '\0')) {
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			    scanner_linenum += 1;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\276':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if ((upperidP[scanner_inputline[(scanner_inputchar - 1)]]) || ((scanner_inputline[(scanner_inputchar - 1)]) == '\0')) {
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			    scanner_linenum += 1;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\277':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if ((lowerP[scanner_inputline[(scanner_inputchar - 1)]]) || ((scanner_inputline[(scanner_inputchar - 1)]) == '\0')) {
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			    scanner_linenum += 1;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\300':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if ((loweridP[scanner_inputline[(scanner_inputchar - 1)]]) || ((scanner_inputline[(scanner_inputchar - 1)]) == '\0')) {
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			    scanner_linenum += 1;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\312':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if ((specialP[scanner_inputline[(scanner_inputchar - 1)]]) || ((scanner_inputline[(scanner_inputchar - 1)]) == '\0')) {
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			    scanner_linenum += 1;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\315':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if (((scanner_inputline[(scanner_inputchar - 1)]) == '\n') || ((scanner_inputline[(scanner_inputchar - 1)]) == '\0')) {
			    break;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\317':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if (((scanner_inputline[(scanner_inputchar - 1)]) == '\r') || ((scanner_inputline[(scanner_inputchar - 1)]) == '\0')) {
			    break;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\316':
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if (((scanner_inputline[(scanner_inputchar - 1)]) == '\t') || ((scanner_inputline[(scanner_inputchar - 1)]) == '\0')) {
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			    scanner_linenum += 1;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case '[':
		{
		    TLint4	len;
		    TLint4	altsubsstartpos;
		    TLint4	altsubsendpos;
		    TLboolean	repeated;
		    pos += 1;
		    len = ((TLnat4) (pattern[(pos - 1)]));
		    altsubsstartpos = pos + 1;
		    altsubsendpos = pos + len;
		    pos += len + 2;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			TLint4	substartpos;
			TLboolean	subfail;
			TLint4	startinputchar;
			substartpos = altsubsstartpos;
			subfail = 1;
			startinputchar = scanner_inputchar;
			for(;;) {
			    TLchar	spat;
			    TLint4	subendpos;
			    if (substartpos > altsubsendpos) {
				break;
			    };
			    spat = pattern[(substartpos - 1)];
			    subendpos = substartpos;
			    switch (spat) {
				case '[':
				case (TLchar) '\332':
				case '(':
				case (TLchar) '\333':
				    {
					subendpos = (substartpos + ((TLnat4) (pattern[((substartpos + 1) - 1)]))) + 2;
				    }
				    break;
				case '\\':
				case '#':
				    {
					subendpos += 1;
				    }
				    break;
				default :
				    break;
			    };
			    if (repeaterP[pattern[((subendpos + 1) - 1)]]) {
				subendpos += 1;
			    };
			    if (scanner_scanToken(pattern, (TLint4) substartpos, (TLint4) subendpos, (TLboolean) test)) {
				subfail = 0;
				break;
			    };
			    substartpos = subendpos + 1;
			};
			if (subfail) {
			    break;
			};
			fail = 0;
			if (!repeated) {
			    break;
			};
			if (scanner_inputchar == startinputchar) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\332':
		{
		    TLint4	len;
		    TLint4	altsubsstartpos;
		    TLint4	altsubsendpos;
		    TLboolean	repeated;
		    pos += 1;
		    len = ((TLnat4) (pattern[(pos - 1)]));
		    altsubsstartpos = pos + 1;
		    altsubsendpos = pos + len;
		    pos += len + 2;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			TLint4	substartpos;
			TLboolean	subfail;
			TLint4	startinputchar;
			substartpos = altsubsstartpos;
			subfail = 1;
			startinputchar = scanner_inputchar;
			for(;;) {
			    TLchar	spat;
			    TLint4	subendpos;
			    if (substartpos > altsubsendpos) {
				break;
			    };
			    spat = pattern[(substartpos - 1)];
			    subendpos = substartpos;
			    switch (spat) {
				case '[':
				case (TLchar) '\332':
				case '(':
				case (TLchar) '\333':
				    {
					subendpos = (substartpos + ((TLnat4) (pattern[((substartpos + 1) - 1)]))) + 2;
				    }
				    break;
				case '\\':
				case '#':
				    {
					subendpos += 1;
				    }
				    break;
				default :
				    break;
			    };
			    if (repeaterP[pattern[((subendpos + 1) - 1)]]) {
				subendpos += 1;
			    };
			    if (scanner_scanToken(pattern, (TLint4) substartpos, (TLint4) subendpos, (TLboolean) test)) {
				subfail = 0;
				break;
			    };
			    substartpos = subendpos + 1;
			};
			if (!subfail) {
			    scanner_inputchar = startinputchar;
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\0') {
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			    scanner_linenum += 1;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case '(':
		{
		    TLint4	len;
		    TLint4	substartpos;
		    TLint4	subendpos;
		    TLboolean	repeated;
		    pos += 1;
		    len = ((TLnat4) (pattern[(pos - 1)]));
		    substartpos = pos + 1;
		    subendpos = pos + len;
		    pos += len + 2;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if (!scanner_scanToken(pattern, (TLint4) substartpos, (TLint4) subendpos, (TLboolean) test)) {
			    break;
			};
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\333':
		{
		    TLint4	len;
		    TLint4	substartpos;
		    TLint4	subendpos;
		    TLboolean	repeated;
		    pos += 1;
		    len = ((TLnat4) (pattern[(pos - 1)]));
		    substartpos = pos + 1;
		    subendpos = pos + len;
		    pos += len + 2;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			TLboolean	subfail;
			TLint4	startinputchar;
			subfail = 1;
			startinputchar = scanner_inputchar;
			if (scanner_scanToken(pattern, (TLint4) substartpos, (TLint4) subendpos, (TLboolean) test)) {
			    subfail = 0;
			};
			if (!subfail) {
			    scanner_inputchar = startinputchar;
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\0') {
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			    scanner_linenum += 1;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case (TLchar) '\334':
		{
		    TLint4	substartpos;
		    TLint4	subendpos;
		    TLboolean	subfail;
		    TLint4	startinputchar;
		    substartpos = pos + 1;
		    subendpos = endpos;
		    pos = endpos + 1;
		    subfail = 1;
		    startinputchar = scanner_inputchar;
		    if (scanner_scanToken(pattern, (TLint4) substartpos, (TLint4) subendpos, (TLboolean) test)) {
			subfail = 0;
		    };
		    scanner_inputchar = startinputchar;
		    if (!subfail) {
			goto __x2524;
		    } else {
		    };
		}
		break;
	    case (TLchar) '\335':
		{
		    TLint4	substartpos;
		    TLint4	subendpos;
		    TLboolean	subfail;
		    TLint4	startinputchar;
		    substartpos = pos + 1;
		    subendpos = endpos;
		    pos = endpos + 1;
		    subfail = 1;
		    startinputchar = scanner_inputchar;
		    if (scanner_scanToken(pattern, (TLint4) substartpos, (TLint4) subendpos, (TLboolean) test)) {
			subfail = 0;
		    };
		    scanner_inputchar = startinputchar;
		    if (subfail) {
			goto __x2524;
		    } else {
		    };
		}
		break;
	    case '\\':
		{
		    TLboolean	repeated;
		    pat = pattern[((pos + 1) - 1)];
		    pos += 2;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if ((scanner_inputline[(scanner_inputchar - 1)]) != pat) {
			    break;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    case '#':
		{
		    TLboolean	repeated;
		    pat = pattern[((pos + 1) - 1)];
		    pos += 2;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if (((scanner_inputline[(scanner_inputchar - 1)]) == pat) || ((scanner_inputline[(scanner_inputchar - 1)]) == '\0')) {
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			    scanner_linenum += 1;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	    default :
		{
		    TLboolean	repeated;
		    pos += 1;
		    repeated = repeaterP[pattern[(pos - 1)]];
		    for(;;) {
			if ((scanner_inputline[(scanner_inputchar - 1)]) != pat) {
			    break;
			};
			if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
			    scanner_linenum += 1;
			};
			scanner_inputchar += 1;
			fail = 0;
			if (!repeated) {
			    break;
			};
		    };
		}
		break;
	};
	if (optionalP[pattern[(pos - 1)]]) {
	    pos += 1;
	} else {
	    if ((pattern[(pos - 1)]) == '+') {
		pos += 1;
	    };
	    if (fail) {
		if (!test) {
		    scanner_inputchar = startchar;
		};
		scanner_linenum = startline;
		return (0);
	    };
	};
	if (pos > endpos) {
	    break;
	};
    }
    __x2524:;
    return (1);
    /* NOTREACHED */
}

static TLboolean scanner_scanCompoundLiteral (litindex)
TLint4	litindex;
{
    TLint4	i;
    TLBIND((*inp), TLstring);
    i = litindex;
    inp = &(scanner_inputline[(scanner_inputchar - 1)]);
    for(;;) {
	{
	    TLBIND((*lit), struct compoundT);
	    lit = &(compoundTokens[i - 1]);
	    {
		TLstring	__x2386;
		TL_TLS_TLSBXX(__x2386, (TLint4) ((*lit).length_), (TLint4) 1, (*inp));
		if (strcmp(__x2386, (*lit).literal) == 0) {
		    scanner_inputchar += (*lit).length_;
		    return (1);
		};
	    };
	};
	i += 1;
	{
	    TLchar	__x2388[2];
	    {
		TLchar	__x2387[2];
		if ((i > nCompounds) || ((TL_TLS_TLSBX(__x2388, (TLint4) 1, (*inp)), TL_TLS_TLSBX(__x2387, (TLint4) 1, (compoundTokens[i - 1].literal)), strcmp(__x2387, __x2388) != 0))) {
		    break;
		};
	    };
	};
    };
    return (0);
    /* NOTREACHED */
}

static TLint4 scanner_commentindex (commentstarttoken)
tokenT	commentstarttoken;
{
    {
	register TLint4	c;
	TLint4	__x2389;
	__x2389 = nComments;
	c = 1;
	if (c <= __x2389) {
	    for(;;) {
		if (commentstarttoken == (commentStart[c - 1])) {
		    return (c);
		};
		if (c == __x2389) break;
		c++;
	    }
	};
    };
    return (0);
    /* NOTREACHED */
}

static void scanner_scanComment (startchararg, comindex)
TLint4	startchararg;
TLint4	comindex;
{
    TLint4	startchar;
    tokenT	comtoken;
    TLstring	indent;
    TLstring	comend;
    TLboolean	firstline;
    TLint4	comstartlength;
    startchar = startchararg;
    TLSTRASS(255, indent, "");
    TLSTRASS(255, comend, (* (TLstring *) (identTable[commentEnd[comindex - 1]])));
    if ((commentEnd[comindex - 1]) == 0) {
	TLSTRASS(255, comend, "\n");
    };
    firstline = 1;
    comstartlength = TL_TLS_TLSLEN(((* (TLstring *) (identTable[commentStart[comindex - 1]]))));
    for(;;) {
	TLint4	comendindex;
	TLint4	newlineindex;
	if (startchar > (32768 * (3))) {
	    TLSTRASS(255, (* (TLstring *) scanner_inputline), (* (TLstring *) &scanner_inputline[(startchar - 1)]));
	    scanner_getInputLine();
	    startchar = scanner_inputchar;
	} else {
	    if ((scanner_inputline[(scanner_inputchar - 1)]) == '\0') {
		scanner_inputline[(0)] = '\0';
		scanner_getInputLine();
		startchar = scanner_inputchar;
	    };
	};
	comendindex = TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(startchar - 1)])), comend);
	if ((firstline && (comendindex != 0)) && (comendindex <= comstartlength)) {
	    comendindex = TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[((startchar + comstartlength) - 1)])), comend);
	    if (comendindex != 0) {
		comendindex += comstartlength;
	    };
	};
	newlineindex = TL_TLS_TLSIND(((* (TLstring *) &scanner_inputline[(startchar - 1)])), "\n");
	if ((((scanner_inputline[(startchar - 1)]) != (TLchar) '\376') && (newlineindex != 0)) && ((!(comendindex != 0)) || (newlineindex < comendindex))) {
	    if (options[16]) {
		TLchar	savedchar;
		savedchar = scanner_inputline[((startchar + newlineindex) - 1)];
		scanner_inputline[((startchar + newlineindex) - 1)] = '\0';
		if (TL_TLS_TLSLEN(((* (TLstring *) &scanner_inputline[(startchar - 1)]))) > (255 - TL_TLS_TLSLEN(indent))) {
		    ident_install((* (TLstring *) &scanner_inputline[(startchar - 1)]), (kindT) 24, &(comtoken));
		} else {
		    {
			TLstring	__x2399;
			TL_TLS_TLSCAT(indent, (* (TLstring *) &scanner_inputline[(startchar - 1)]), __x2399);
			ident_install(__x2399, (kindT) 24, &(comtoken));
		    };
		};
		scanner_installToken((kindT) 24, (tokenT) comtoken, (tokenT) comtoken);
		scanner_inputline[((startchar + newlineindex) - 1)] = savedchar;
	    };
	    scanner_linenum += 1;
	    scanner_inputchar = startchar + newlineindex;
	    if ((commentEnd[comindex - 1]) == 0) {
		break;
	    };
	    if ((options[16]) && (!(options[31]))) {
		for(;;) {
		    if ((!(spaceP[scanner_inputline[(scanner_inputchar - 1)]])) || ((scanner_inputline[(scanner_inputchar - 1)]) == '\n')) {
			break;
		    };
		    scanner_inputchar += 1;
		};
		TLSTRASS(255, indent, "   ");
	    };
	} else {
	    if (comendindex != 0) {
		if (options[16]) {
		    TLint4	lencomend;
		    TLchar	savedchar;
		    lencomend = TL_TLS_TLSLEN(comend);
		    if (strcmp(comend, "\n") == 0) {
			scanner_linenum += 1;
			lencomend = 0;
		    };
		    savedchar = scanner_inputline[((((startchar + comendindex) + lencomend) - 1) - 1)];
		    scanner_inputline[((((startchar + comendindex) + lencomend) - 1) - 1)] = '\0';
		    if (TL_TLS_TLSLEN(((* (TLstring *) &scanner_inputline[(startchar - 1)]))) > (255 - TL_TLS_TLSLEN(indent))) {
			ident_install((* (TLstring *) &scanner_inputline[(startchar - 1)]), (kindT) 24, &(comtoken));
		    } else {
			{
			    TLstring	__x2403;
			    TL_TLS_TLSCAT(indent, (* (TLstring *) &scanner_inputline[(startchar - 1)]), __x2403);
			    ident_install(__x2403, (kindT) 24, &(comtoken));
			};
		    };
		    scanner_installToken((kindT) 24, (tokenT) comtoken, (tokenT) comtoken);
		    scanner_inputline[((((startchar + comendindex) + lencomend) - 1) - 1)] = savedchar;
		};
		scanner_inputchar = ((startchar + comendindex) + TL_TLS_TLSLEN(comend)) - 1;
		if (strcmp(comend, "\n") == 0) {
		    if (options[16]) {
			scanner_linenum -= 1;
		    };
		    scanner_inputchar -= 1;
		};
		break;
	    } else {
		if ((scanner_inputline[(startchar - 1)]) == (TLchar) '\376') {
		    {
			TLstring	__x2405;
			TL_TLS_TLSCAT("at end of ", fileNames[scanner_filenum - 1], __x2405);
			error(__x2405, "Syntax error - comment ends at end of file", (TLint4) 20, (TLint4) 164);
		    };
		} else {
		    {
			TLstring	__x2408;
			TL_TLS_TLSVIS((TLint4) 32768, (TLint4) 1, (TLint4) 10, __x2408);
			{
			    TLstring	__x2407;
			    TL_TLS_TLSCAT("Input line too long (> ", __x2408, __x2407);
			    {
				TLstring	__x2406;
				TL_TLS_TLSCAT(__x2407, " characters)", __x2406);
				error("", __x2406, (TLint4) 21, (TLint4) 144);
			    };
			};
		    };
		};
	    };
	};
	startchar = scanner_inputchar;
	firstline = 0;
    };
}

static void scanner_sortCompoundTokens () {
    TLint4	k;
    {
	register TLint4	k;
	for (k = nCompounds; k >= 2; k--) {
	    TLboolean	swap;
	    swap = 0;
	    {
		register TLint4	j;
		TLint4	__x2409;
		__x2409 = k;
		j = 2;
		if (j <= __x2409) {
		    for(;;) {
			{
			    TLchar	__x2411[2];
			    TL_TLS_TLSBX(__x2411, (TLint4) 1, (compoundTokens[j - 1].literal));
			    {
				TLchar	__x2410[2];
				TL_TLS_TLSBX(__x2410, (TLint4) 1, (compoundTokens[(j - 1) - 1].literal));
				if (strcmp(__x2410, __x2411) > 0) {
				    struct compoundT	temp;
				    TLSTRCTASS(temp, compoundTokens[(j - 1) - 1], struct compoundT);
				    TLSTRCTASS(compoundTokens[(j - 1) - 1], compoundTokens[j - 1], struct compoundT);
				    TLSTRCTASS(compoundTokens[j - 1], temp, struct compoundT);
				    swap = 1;
				};
			    };
			};
			if (j == __x2409) break;
			j++;
		    }
		};
	    };
	    if (!swap) {
		break;
	    };
	};
    };
    for(;;) {
	TLboolean	swap;
	swap = 0;
	{
	    register TLint4	k;
	    TLint4	__x2412;
	    __x2412 = nCompounds - 1;
	    k = 1;
	    if (k <= __x2412) {
		for(;;) {
		    {
			TLchar	__x2414[2];
			TL_TLS_TLSBX(__x2414, (TLint4) 1, (compoundTokens[(k + 1) - 1].literal));
			{
			    TLchar	__x2413[2];
			    TL_TLS_TLSBX(__x2413, (TLint4) 1, (compoundTokens[k - 1].literal));
			    if (strcmp(__x2413, __x2414) == 0) {
				if ((compoundTokens[k - 1].length_) < (compoundTokens[(k + 1) - 1].length_)) {
				    struct compoundT	temp;
				    TLSTRCTASS(temp, compoundTokens[(k + 1) - 1], struct compoundT);
				    TLSTRCTASS(compoundTokens[(k + 1) - 1], compoundTokens[k - 1], struct compoundT);
				    TLSTRCTASS(compoundTokens[k - 1], temp, struct compoundT);
				    swap = 1;
				};
			    };
			};
		    };
		    if (k == __x2412) break;
		    k++;
		}
	    };
	};
	if (!swap) {
	    break;
	};
    };
    TLSTRASS(255, compoundTokens[(nCompounds + 1) - 1].literal, "\377");
    compoundTokens[(nCompounds + 1) - 1].length_ = 1;
    k = 1;
    {
	register TLchar	c;
	c = '\0';
	if (c <= (TLchar) '\377') {
	    for(;;) {
		{
		    TLchar	__x2416[2];
		    {
			TLchar	__x2415[2];
			if ((k <= nCompounds) && ((TLCHRTOSTR(c, __x2416), TL_TLS_TLSBX(__x2415, (TLint4) 1, (compoundTokens[k - 1].literal)), strcmp(__x2415, __x2416) == 0))) {
			    compoundIndex[c] = k;
			    for(;;) {
				k += 1;
				{
				    TLchar	__x2418[2];
				    {
					TLchar	__x2417[2];
					if ((k > nCompounds) || ((TLCHRTOSTR(c, __x2418), TL_TLS_TLSBX(__x2417, (TLint4) 1, (compoundTokens[k - 1].literal)), strcmp(__x2417, __x2418) > 0))) {
					    break;
					};
				    };
				};
			    };
			} else {
			    compoundIndex[c] = 0;
			};
		    };
		};
		if (c == (TLchar) '\377') break;
		c++;
	    }
	};
    };
}

static void scanner_sortKeywords (firstkey)
TLint4	firstkey;
{
    if (firstkey > 1) {
	TLint4	kk;
	kk = 0;
	{
	    register TLint4	k;
	    TLint4	__x2419;
	    __x2419 = lastKey;
	    k = firstkey;
	    if (k <= __x2419) {
		for(;;) {
		    kk += 1;
		    keywordTokens[kk - 1] = keywordTokens[k - 1];
		    if (k == __x2419) break;
		    k++;
		}
	    };
	};
	nKeys = kk;
    };
    {
	register TLint4	k;
	for (k = nKeys; k >= 2; k--) {
	    TLboolean	swap;
	    swap = 0;
	    {
		register TLint4	j;
		TLint4	__x2420;
		__x2420 = k;
		j = 2;
		if (j <= __x2420) {
		    for(;;) {
			if ((keywordTokens[(j - 1) - 1]) > (keywordTokens[j - 1])) {
			    TLnat4	temp;
			    temp = keywordTokens[(j - 1) - 1];
			    keywordTokens[(j - 1) - 1] = keywordTokens[j - 1];
			    keywordTokens[j - 1] = temp;
			    swap = 1;
			};
			if (j == __x2420) break;
			j++;
		    }
		};
	    };
	    if (!swap) {
		break;
	    };
	};
    };
}

static void scanner_linkpattern (c, p)
TLchar	c;
TLint4	p;
{
    scanner_inputline[(0)] = c;
    scanner_inputline[(1)] = '\0';
    scanner_inputchar = 1;
    if (scanner_scanToken(tokenPatterns[p - 1].pattern, (TLint4) 1, (TLint4) (tokenPatterns[p - 1].length_), (TLboolean) 1)) {
    };
    if (scanner_inputchar != 1) {
	nPatternLinks += 1;
	if (nPatternLinks >= 1600) {
	    {
		TLstring	__x2423;
		TL_TLS_TLSVIS((TLint4) 1600, (TLint4) 1, (TLint4) 10, __x2423);
		{
		    TLstring	__x2422;
		    TL_TLS_TLSCAT("Too many token patterns (links) (>", __x2423, __x2422);
		    {
			TLstring	__x2421;
			TL_TLS_TLSCAT(__x2422, ")", __x2421);
			error("", __x2421, (TLint4) 21, (TLint4) 166);
		    };
		};
	    };
	};
	if ((patternIndex[c]) == 0) {
	    patternIndex[c] = nPatternLinks;
	};
	patternLink[nPatternLinks - 1] = p;
    };
}

static void scanner_sortTokenPatterns () {
    typedef	TLchar	__x2424[164096];
    __x2424	saveinputline;
    TLint4	saveinputchar;
    TLNONSCLASS(saveinputline, scanner_inputline, __x2424);
    saveinputchar = scanner_inputchar;
    {
	register TLint4	p;
	TLint4	__x2425;
	__x2425 = nPatterns;
	p = 1;
	if (p <= __x2425) {
	    for(;;) {
		scanner_inputline[(0)] = '\0';
		scanner_inputchar = 1;
		if (scanner_scanToken(tokenPatterns[p - 1].pattern, (TLint4) 1, (TLint4) (tokenPatterns[p - 1].length_), (TLboolean) 1)) {
		    {
			TLstring	__x2427;
			TL_TLS_TLSCAT("Token pattern for \'", (* (TLstring *) (identTable[tokenPatterns[p - 1].name])), __x2427);
			{
			    TLstring	__x2426;
			    TL_TLS_TLSCAT(__x2427, "\' accepts the null string", __x2426);
			    error("", __x2426, (TLint4) 1, (TLint4) 165);
			};
		    };
		};
		if (p == __x2425) break;
		p++;
	    }
	};
    };
    nPatternLinks = 0;
    {
	register TLchar	c;
	c = '\0';
	if (c <= (TLchar) '\377') {
	    for(;;) {
		patternIndex[c] = 0;
		{
		    register TLint4	p;
		    TLint4	__x2429;
		    __x2429 = nPatterns;
		    p = nPredefinedPatterns + 1;
		    if (p <= __x2429) {
			for(;;) {
			    scanner_linkpattern((TLchar) c, (TLint4) p);
			    if (p == __x2429) break;
			    p++;
			}
		    };
		};
		{
		    register TLint4	p;
		    TLint4	__x2430;
		    __x2430 = nPredefinedPatterns;
		    p = 1;
		    if (p <= __x2430) {
			for(;;) {
			    scanner_linkpattern((TLchar) c, (TLint4) p);
			    if (p == __x2430) break;
			    p++;
			}
		    };
		};
		if ((patternIndex[c]) != 0) {
		    nPatternLinks += 1;
		    patternLink[nPatternLinks - 1] = 0;
		    if ((c > '\0') && ((patternIndex[((TLchar) (((TLnat4) c) - 1))]) != 0)) {
			TLint4	l1;
			TLint4	l2;
			TLboolean	same;
			l1 = patternIndex[((TLchar) (((TLnat4) c) - 1))];
			l2 = patternIndex[c];
			same = 1;
			for(;;) {
			    if ((patternLink[l1 - 1]) != (patternLink[l2 - 1])) {
				same = 0;
				break;
			    };
			    if ((patternLink[l1 - 1]) == 0) {
				break;
			    };
			    l1 += 1;
			    l2 += 1;
			};
			if (same) {
			    nPatternLinks = (patternIndex[c]) - 1;
			    patternIndex[c] = patternIndex[((TLchar) (((TLnat4) c) - 1))];
			};
		    };
		};
		if (c == (TLchar) '\377') break;
		c++;
	    }
	};
    };
    TLNONSCLASS(scanner_inputline, saveinputline, scanner___x2250);
    scanner_inputchar = saveinputchar;
}

static void scanner_setTokenPattern (p, kind, name, pattern)
TLint4	p;
kindT	kind;
TLstring	name;
TLstring	pattern;
{
    TLint4	patternlength;
    typedef	TLchar	__x2431[256];
    __x2431	compressedpattern;
    struct	__x2433 {
    TLchar	ket;
    TLint4	inx;
};
    typedef	struct __x2433	__x2432[256];
    __x2432	bstack;
    TLint4	bstop;
    TLint4	i;
    TLint4	j;
    TLBIND((*pp), struct patternT);
    patternlength = TL_TLS_TLSLEN(pattern);
    bstop = 0;
    i = 1;
    j = i;
    for(;;) {
	TLchar	pi;
	if (i > patternlength) {
	    break;
	};
	{
	    TLchar	__x2434[2];
	    TL_TLS_TLSBX(__x2434, (TLint4) i, pattern);
	    pi = TLCVTTOCHR(__x2434);
	};
	{
	    TLchar	__x2436[2];
	    {
		TLchar	__x2435[2];
		if ((pi == '\\') || ((pi == '#') && ((!(patternlength > i)) || ((TL_TLS_TLSBX(__x2435, (TLint4) (i + 1), pattern), (strcmp(__x2435, "[") != 0) && ((TL_TLS_TLSBX(__x2436, (TLint4) (i + 1), pattern), strcmp(__x2436, "(") != 0))))))) {
		    if (i == patternlength) {
			{
			    TLstring	__x2438;
			    TL_TLS_TLSCAT("Syntax error in token pattern for \'", name, __x2438);
			    {
				TLstring	__x2437;
				TL_TLS_TLSCAT(__x2438, "\' (\\ or # at end of pattern)", __x2437);
				error("", __x2437, (TLint4) 20, (TLint4) 167);
			    };
			};
		    };
		    if (pi == '\\') {
			TLchar	code;
			i += 1;
			{
			    TLchar	__x2439[2];
			    TL_TLS_TLSBX(__x2439, (TLint4) i, pattern);
			    pi = TLCVTTOCHR(__x2439);
			};
			code = '\0';
			{
			    register TLint4	c;
			    for (c = 1; c <= 13; c++) {
				if ((patternChars[c - 1]) == pi) {
				    code = patternCodes[c - 1];
				    break;
				};
			    };
			};
			if (code == '\0') {
			    if (((!(metaP[pi])) && (pi != '"')) && (pi != ':')) {
				{
				    TLstring	__x2443;
				    {
					TLchar	__x2444[2];
					TLCHRTOSTR(pi, __x2444);
					TL_TLS_TLSCAT("Escaped character \\", __x2444, __x2443);
				    };
				    {
					TLstring	__x2442;
					TL_TLS_TLSCAT(__x2443, " in token pattern for \'", __x2442);
					{
					    TLstring	__x2441;
					    TL_TLS_TLSCAT(__x2442, name, __x2441);
					    {
						TLstring	__x2440;
						TL_TLS_TLSCAT(__x2441, "\' is not a valid token pattern meta-character", __x2440);
						error("", __x2440, (TLint4) 1, (TLint4) 169);
					    };
					};
				    };
				};
			    };
			    if (pi == ':') {
				if (bstop > 0) {
				    {
					TLstring	__x2446;
					TL_TLS_TLSCAT("Syntax error in token pattern for \'", name, __x2446);
					{
					    TLstring	__x2445;
					    TL_TLS_TLSCAT(__x2446, "\' (lookahead test \\: must be a trailing pattern)", __x2445);
					    error("", __x2445, (TLint4) 20, (TLint4) 181);
					};
				    };
				};
				pi = (TLchar) '\334';
			    } else {
				compressedpattern[(j - 1)] = '\\';
				j += 1;
			    };
			} else {
			    pi = code;
			};
		    } else {
			TLchar	code;
			i += 1;
			{
			    TLchar	__x2447[2];
			    TL_TLS_TLSBX(__x2447, (TLint4) i, pattern);
			    pi = TLCVTTOCHR(__x2447);
			};
			code = '\0';
			{
			    register TLint4	c;
			    for (c = 1; c <= 13; c++) {
				if ((patternChars[c - 1]) == pi) {
				    code = patternNotCodes[c - 1];
				    break;
				};
			    };
			};
			if (code == '\0') {
			    {
				TLchar	__x2448[2];
				if ((pi == '\\') && ((!(patternlength > i)) || ((TL_TLS_TLSBX(__x2448, (TLint4) (i + 1), pattern), strcmp(__x2448, ":") == 0)))) {
				    i += 1;
				    if (bstop > 0) {
					{
					    TLstring	__x2450;
					    TL_TLS_TLSCAT("Syntax error in token pattern for \'", name, __x2450);
					    {
						TLstring	__x2449;
						TL_TLS_TLSCAT(__x2450, "\' (lookahead test \\: must be a trailing pattern)", __x2449);
						error("", __x2449, (TLint4) 20, (TLint4) 181);
					    };
					};
				    };
				    pi = (TLchar) '\335';
				} else {
				    compressedpattern[(j - 1)] = '#';
				    j += 1;
				    if ((pi == '\\') && (i < patternlength)) {
					i += 1;
					{
					    TLchar	__x2451[2];
					    TL_TLS_TLSBX(__x2451, (TLint4) i, pattern);
					    pi = TLCVTTOCHR(__x2451);
					};
				    };
				};
			    };
			} else {
			    pi = code;
			};
		    };
		} else {
		    {
			TLchar	__x2452[2];
			if ((pi == '[') || (((pi == '#') && (patternlength > i)) && ((TL_TLS_TLSBX(__x2452, (TLint4) (i + 1), pattern), strcmp(__x2452, "[") == 0)))) {
			    if (pi == '#') {
				i += 1;
				compressedpattern[(j - 1)] = (TLchar) '\332';
			    } else {
				compressedpattern[(j - 1)] = '[';
			    };
			    j += 1;
			    bstop += 1;
			    bstack[bstop - 1].ket = ']';
			    bstack[bstop - 1].inx = j;
			    pi = '\0';
			} else {
			    {
				TLchar	__x2453[2];
				if ((pi == '(') || (((pi == '#') && (patternlength > i)) && ((TL_TLS_TLSBX(__x2453, (TLint4) (i + 1), pattern), strcmp(__x2453, "(") == 0)))) {
				    if (pi == '#') {
					i += 1;
					compressedpattern[(j - 1)] = (TLchar) '\333';
				    } else {
					compressedpattern[(j - 1)] = '(';
				    };
				    j += 1;
				    bstop += 1;
				    bstack[bstop - 1].ket = ')';
				    bstack[bstop - 1].inx = j;
				    pi = '\0';
				} else {
				    if ((pi == ']') || (pi == ')')) {
					if ((bstop > 0) && ((bstack[bstop - 1].ket) == pi)) {
					    TLint4	len;
					    len = (j - (bstack[bstop - 1].inx)) - 1;
					    compressedpattern[((bstack[bstop - 1].inx) - 1)] = ((TLchar) len);
					    bstop -= 1;
					} else {
					    {
						TLstring	__x2455;
						TL_TLS_TLSCAT("Syntax error in token pattern for \'", name, __x2455);
						{
						    TLstring	__x2454;
						    TL_TLS_TLSCAT(__x2455, "\' (unbalanced () or [])", __x2454);
						    error("", __x2454, (TLint4) 20, (TLint4) 170);
						};
					    };
					};
				    } else {
					if (magicP[pi]) {
					    compressedpattern[(j - 1)] = '\\';
					    j += 1;
					};
				    };
				};
			    };
			};
		    };
		};
	    };
	};
	compressedpattern[(j - 1)] = pi;
	j += 1;
	i += 1;
    };
    if (bstop > 0) {
	{
	    TLstring	__x2457;
	    TL_TLS_TLSCAT("Syntax error in token pattern for \'", name, __x2457);
	    {
		TLstring	__x2456;
		TL_TLS_TLSCAT(__x2457, "\' (unbalanced () or [])", __x2456);
		error("", __x2456, (TLint4) 20, (TLint4) 171);
	    };
	};
    };
    compressedpattern[(j - 1)] = '\0';
    if ((strcmp(name, "comment") == 0) && ((compressedpattern[(0)]) == (TLchar) '\253')) {
	scanner_newlineComments = 1;
    };
    pp = &(tokenPatterns[p - 1]);
    (*pp).kind = kind;
    ident_install(name, (kindT) 15, &((*pp).name));
    if ((kind >= 30) && (kind <= 59)) {
	kindName[((TLnat4) kind)] = (*pp).name;
    };
    TLSTRASS(255, (* (TLstring *) (*pp).pattern), (* (TLstring *) compressedpattern));
    (*pp).length_ = j - 1;
    (*pp).next = 0;
}

static void scanner_defaultTokenPatterns () {
    scanner_setTokenPattern((TLint4) 1, (kindT) 15, "id", "\\u\\i*");
    scanner_setTokenPattern((TLint4) 2, (kindT) 20, "number", "\\d+(.\\d+)?([eE][+-]?\\d+)?");
    scanner_setTokenPattern((TLint4) 3, (kindT) 12, "stringlit", "\"[(\\\\\\c)#\"]*\"");
    scanner_setTokenPattern((TLint4) 4, (kindT) 13, "charlit", "\'[(\\\\\\c)#\']*\'");
    scanner_setTokenPattern((TLint4) 5, (kindT) 26, "space", "[ \t]+");
    scanner_setTokenPattern((TLint4) 6, (kindT) 27, "newline", "\n");
    scanner_setTokenPattern((TLint4) 7, (kindT) 10, "ignore", "\"$%&*/ UNDEFINED /*&%$\"");
    idPattern = 1;
    nPatterns = 7;
    nPredefinedPatterns = nPatterns;
    scanner_sortTokenPatterns();
    ident_install("[", (kindT) 11, &(keywordTokens[0]));
    ident_install("]", (kindT) 11, &(keywordTokens[1]));
    ident_install("|", (kindT) 11, &(keywordTokens[2]));
    ident_install("end", (kindT) 15, &(keywordTokens[3]));
    ident_install("keys", (kindT) 15, &(keywordTokens[4]));
    ident_install("define", (kindT) 15, &(keywordTokens[5]));
    ident_install("repeat", (kindT) 15, &(keywordTokens[6]));
    ident_install("list", (kindT) 15, &(keywordTokens[7]));
    ident_install("opt", (kindT) 15, &(keywordTokens[8]));
    ident_install("rule", (kindT) 15, &(keywordTokens[9]));
    ident_install("function", (kindT) 15, &(keywordTokens[10]));
    ident_install("external", (kindT) 15, &(keywordTokens[11]));
    ident_install("replace", (kindT) 15, &(keywordTokens[12]));
    ident_install("by", (kindT) 15, &(keywordTokens[13]));
    ident_install("match", (kindT) 15, &(keywordTokens[14]));
    ident_install("skipping", (kindT) 15, &(keywordTokens[15]));
    ident_install("construct", (kindT) 15, &(keywordTokens[16]));
    ident_install("deconstruct", (kindT) 15, &(keywordTokens[17]));
    ident_install("where", (kindT) 15, &(keywordTokens[18]));
    ident_install("not", (kindT) 15, &(keywordTokens[19]));
    ident_install("include", (kindT) 15, &(keywordTokens[20]));
    ident_install("comments", (kindT) 15, &(keywordTokens[21]));
    ident_install("compounds", (kindT) 15, &(keywordTokens[22]));
    ident_install("tokens", (kindT) 15, &(keywordTokens[23]));
    ident_install("all", (kindT) 15, &(keywordTokens[24]));
    ident_install("import", (kindT) 15, &(keywordTokens[25]));
    ident_install("export", (kindT) 15, &(keywordTokens[26]));
    ident_install("assert", (kindT) 15, &(keywordTokens[27]));
    ident_install("...", (kindT) 11, &(keywordTokens[28]));
    nKeys = 29;
    nTxlKeys = 29;
    lastKey = 29;
    scanner_sortKeywords((TLint4) 1);
}

static void scanner_expectend (expectedword)
TLstring	expectedword;
{
    TLint4	startchar;
    TLstring	gotword;
    scanner_skipSeparators();
    startchar = scanner_inputchar;
    for(;;) {
	if (!(idP[scanner_inputline[(scanner_inputchar - 1)]])) {
	    break;
	};
	scanner_inputchar += 1;
    };
    {
	TLstring	__x2460;
	TL_TLS_TLSBXX(__x2460, (TLint4) (scanner_inputchar - 1), (TLint4) startchar, ((* (TLstring *) scanner_inputline)));
	TLSTRASS(255, gotword, __x2460);
    };
    if (strcmp(gotword, expectedword) != 0) {
	{
	    TLstring	__x2469;
	    TL_TLS_TLSCAT("Syntax error - expected \'end ", expectedword, __x2469);
	    {
		TLstring	__x2468;
		TL_TLS_TLSCAT(__x2469, "\', got \'end ", __x2468);
		{
		    TLstring	__x2467;
		    TL_TLS_TLSCAT(__x2468, gotword, __x2467);
		    {
			TLstring	__x2466;
			TL_TLS_TLSCAT(__x2467, "\'", __x2466);
			{
			    TLstring	__x2465;
			    TL_TLS_TLSVIS((TLint4) scanner_linenum, (TLint4) 1, (TLint4) 10, __x2465);
			    {
				TLstring	__x2464;
				TL_TLS_TLSCAT("line ", __x2465, __x2464);
				{
				    TLstring	__x2463;
				    TL_TLS_TLSCAT(__x2464, " of ", __x2463);
				    {
					TLstring	__x2462;
					TL_TLS_TLSCAT(__x2463, fileNames[scanner_filenum - 1], __x2462);
					error(__x2462, __x2466, (TLint4) 20, (TLint4) 172);
				    };
				};
			    };
			};
		    };
		};
	    };
	};
    };
}

static TLboolean scanner_isId (id)
TLstring	id;
{
    {
	register TLint4	i;
	TLint4	__x2470;
	__x2470 = TL_TLS_TLSLEN(id);
	i = 1;
	if (i <= __x2470) {
	    for(;;) {
		TLchar	idi;
		{
		    TLchar	__x2471[2];
		    TL_TLS_TLSBX(__x2471, (TLint4) i, id);
		    idi = TLCVTTOCHR(__x2471);
		};
		if (!(idP[idi])) {
		    return (0);
		};
		if (i == __x2470) break;
		i++;
	    }
	};
    };
    return (1);
    /* NOTREACHED */
}

static void scanner_setCompoundToken (literal)
TLstring	literal;
{
    if (TL_TLS_TLSLEN(literal) == 1) {
	return;
    };
    if (nCompounds == 128) {
	{
	    TLstring	__x2474;
	    TL_TLS_TLSVIS((TLint4) 128, (TLint4) 1, (TLint4) 10, __x2474);
	    {
		TLstring	__x2473;
		TL_TLS_TLSCAT("Too many compound literals (>", __x2474, __x2473);
		{
		    TLstring	__x2472;
		    TL_TLS_TLSCAT(__x2473, ")", __x2472);
		    error("", __x2472, (TLint4) 21, (TLint4) 173);
		};
	    };
	};
    };
    nCompounds += 1;
    TLSTRASS(255, compoundTokens[nCompounds - 1].literal, literal);
    compoundTokens[nCompounds - 1].length_ = TL_TLS_TLSLEN(literal);
}

static void scanner_setKeyword (keyword)
TLstring	keyword;
{
    if (lastKey == 768) {
	{
	    TLstring	__x2477;
	    TL_TLS_TLSVIS((TLint4) 768, (TLint4) 1, (TLint4) 10, __x2477);
	    {
		TLstring	__x2476;
		TL_TLS_TLSCAT("Too many keywords (>", __x2477, __x2476);
		{
		    TLstring	__x2475;
		    TL_TLS_TLSCAT(__x2476, ")", __x2475);
		    error("", __x2475, (TLint4) 21, (TLint4) 174);
		};
	    };
	};
    };
    lastKey += 1;
    ident_install(keyword, (kindT) 15, &(keywordTokens[lastKey - 1]));
}

static void scanner_processCompoundTokens () {
    for(;;) {
	TLint4	startchar;
	TLstring	literal;
	scanner_skipSeparators();
	if ((scanner_inputline[(scanner_inputchar - 1)]) == '\'') {
	    scanner_inputchar += 1;
	};
	if ((scanner_inputline[(scanner_inputchar - 1)]) == (TLchar) '\376') {
	    break;
	};
	startchar = scanner_inputchar;
	for(;;) {
	    if (separatorP[scanner_inputline[(scanner_inputchar - 1)]]) {
		break;
	    };
	    scanner_inputchar += 1;
	};
	{
	    TLstring	__x2478;
	    TL_TLS_TLSBXX(__x2478, (TLint4) (scanner_inputchar - 1), (TLint4) startchar, ((* (TLstring *) scanner_inputline)));
	    TLSTRASS(255, literal, __x2478);
	};
	if (strcmp(literal, "end") == 0) {
	    break;
	};
	scanner_setCompoundToken(literal);
    };
    scanner_expectend("compounds");
    scanner_sortCompoundTokens();
}

static void scanner_processCommentBrackets () {
    for(;;) {
	TLint4	startchar;
	TLstring	commentbracket;
	scanner_skipSeparators();
	if ((scanner_inputline[(scanner_inputchar - 1)]) == '\'') {
	    scanner_inputchar += 1;
	};
	if ((scanner_inputline[(scanner_inputchar - 1)]) == (TLchar) '\376') {
	    break;
	};
	startchar = scanner_inputchar;
	for(;;) {
	    if (separatorP[scanner_inputline[(scanner_inputchar - 1)]]) {
		break;
	    };
	    scanner_inputchar += 1;
	};
	{
	    TLstring	__x2480;
	    TL_TLS_TLSBXX(__x2480, (TLint4) (scanner_inputchar - 1), (TLint4) startchar, ((* (TLstring *) scanner_inputline)));
	    TLSTRASS(255, commentbracket, __x2480);
	};
	if (strcmp(commentbracket, "end") == 0) {
	    break;
	};
	if (scanner_isId(commentbracket)) {
	    scanner_setKeyword(commentbracket);
	} else {
	    if (TL_TLS_TLSLEN(commentbracket) > 1) {
		scanner_setCompoundToken(commentbracket);
	    };
	};
	if (nComments == 16) {
	    {
		TLstring	__x2484;
		TL_TLS_TLSVIS((TLint4) 16, (TLint4) 1, (TLint4) 10, __x2484);
		{
		    TLstring	__x2483;
		    TL_TLS_TLSCAT("Too many comment conventions (>", __x2484, __x2483);
		    {
			TLstring	__x2482;
			TL_TLS_TLSCAT(__x2483, ")", __x2482);
			error("", __x2482, (TLint4) 21, (TLint4) 175);
		    };
		};
	    };
	};
	nComments += 1;
	ident_install(commentbracket, (kindT) 11, &(commentStart[nComments - 1]));
	for(;;) {
	    if (!(spaceP[scanner_inputline[(scanner_inputchar - 1)]])) {
		break;
	    };
	    scanner_inputchar += 1;
	};
	if (((scanner_inputline[(scanner_inputchar - 1)]) != '\0') && ((scanner_inputline[(scanner_inputchar - 1)]) != '%')) {
	    if ((scanner_inputline[(scanner_inputchar - 1)]) == '\'') {
		scanner_inputchar += 1;
	    };
	    if (((scanner_inputline[(scanner_inputchar - 1)]) != (TLchar) '\376') && ((scanner_inputline[(scanner_inputchar - 1)]) != '\0')) {
		startchar = scanner_inputchar;
		for(;;) {
		    if (separatorP[scanner_inputline[(scanner_inputchar - 1)]]) {
			break;
		    };
		    scanner_inputchar += 1;
		};
		{
		    TLstring	__x2485;
		    TL_TLS_TLSBXX(__x2485, (TLint4) (scanner_inputchar - 1), (TLint4) startchar, ((* (TLstring *) scanner_inputline)));
		    TLSTRASS(255, commentbracket, __x2485);
		};
		if (scanner_isId(commentbracket)) {
		    scanner_setKeyword(commentbracket);
		} else {
		    if (TL_TLS_TLSLEN(commentbracket) > 1) {
			scanner_setCompoundToken(commentbracket);
		    };
		};
		ident_install(commentbracket, (kindT) 11, &(commentEnd[nComments - 1]));
	    } else {
		commentEnd[nComments - 1] = 0;
	    };
	} else {
	    commentEnd[nComments - 1] = 0;
	};
    };
    scanner_expectend("comments");
    scanner_sortCompoundTokens();
}

static void scanner_processKeywordTokens () {
    for(;;) {
	TLboolean	quoted;
	TLint4	startchar;
	TLstring	key;
	scanner_skipSeparators();
	quoted = 0;
	if ((scanner_inputline[(scanner_inputchar - 1)]) == '\'') {
	    scanner_inputchar += 1;
	    quoted = 1;
	};
	if ((scanner_inputline[(scanner_inputchar - 1)]) == (TLchar) '\376') {
	    break;
	};
	startchar = scanner_inputchar;
	for(;;) {
	    if (separatorP[scanner_inputline[(scanner_inputchar - 1)]]) {
		break;
	    };
	    scanner_inputchar += 1;
	};
	{
	    TLstring	__x2487;
	    TL_TLS_TLSBXX(__x2487, (TLint4) (scanner_inputchar - 1), (TLint4) startchar, ((* (TLstring *) scanner_inputline)));
	    TLSTRASS(255, key, __x2487);
	};
	if ((strcmp(key, "end") == 0) && (!quoted)) {
	    break;
	};
	scanner_setKeyword(key);
    };
    scanner_expectend("keys");
}

static void scanner_processTokenPatterns () {
    TLstring	name;
    TLSTRASS(255, name, "");
    for(;;) {
	TLboolean	extension;
	TLint4	startchar;
	TLstring	pattern;
	TLint4	newp;
	TLnat4	kind;
	scanner_skipSeparators();
	if ((scanner_inputline[(scanner_inputchar - 1)]) == (TLchar) '\376') {
	    break;
	};
	if ((((scanner_inputline[(scanner_inputchar - 1)]) == '|') || ((scanner_inputline[(scanner_inputchar - 1)]) == '+')) && (strcmp(name, "") != 0)) {
	} else {
	    TLint4	startchar;
	    startchar = scanner_inputchar;
	    for(;;) {
		if (!(idP[scanner_inputline[(scanner_inputchar - 1)]])) {
		    break;
		};
		scanner_inputchar += 1;
	    };
	    {
		TLstring	__x2489;
		TL_TLS_TLSBXX(__x2489, (TLint4) (scanner_inputchar - 1), (TLint4) startchar, ((* (TLstring *) scanner_inputline)));
		TLSTRASS(255, name, __x2489);
	    };
	    if (strcmp(name, "") == 0) {
		{
		    TLstring	__x2493;
		    TL_TLS_TLSBXS(__x2493, (TLint4) 0, (TLint4) startchar, ((* (TLstring *) scanner_inputline)));
		    {
			TLstring	__x2492;
			TL_TLS_TLSCAT("Syntax error in token pattern definition (expected token name, got \'", __x2493, __x2492);
			{
			    TLstring	__x2491;
			    TL_TLS_TLSCAT(__x2492, "\')", __x2491);
			    error("", __x2491, (TLint4) 20, (TLint4) 176);
			};
		    };
		};
	    };
	};
	if (strcmp(name, "end") == 0) {
	    break;
	};
	scanner_skipSeparators();
	if ((scanner_inputline[(scanner_inputchar - 1)]) == (TLchar) '\376') {
	    break;
	};
	extension = 0;
	if ((((scanner_inputline[(scanner_inputchar - 1)]) == '.') && ((scanner_inputline[((scanner_inputchar + 1) - 1)]) == '.')) && ((scanner_inputline[((scanner_inputchar + 2) - 1)]) == '.')) {
	    scanner_inputchar += 3;
	    scanner_skipSeparators();
	};
	if (((scanner_inputline[(scanner_inputchar - 1)]) == '|') || ((scanner_inputline[(scanner_inputchar - 1)]) == '+')) {
	    extension = 1;
	    scanner_inputchar += 1;
	    scanner_skipSeparators();
	    if ((scanner_inputline[(scanner_inputchar - 1)]) == (TLchar) '\376') {
		break;
	    };
	};
	startchar = scanner_inputchar;
	if ((scanner_inputline[(scanner_inputchar - 1)]) == '"') {
	    TLchar	lastchar;
	    lastchar = '"';
	    scanner_inputchar += 1;
	    for(;;) {
		if ((scanner_inputline[(scanner_inputchar - 1)]) == '"') {
		    break;
		};
		if ((scanner_inputline[(scanner_inputchar - 1)]) == '\0') {
		    break;
		};
		scanner_inputchar += 1;
		if (((scanner_inputline[((scanner_inputchar - 1) - 1)]) == '\\') && ((scanner_inputline[(scanner_inputchar - 1)]) != '\0')) {
		    scanner_inputchar += 1;
		};
	    };
	    if ((scanner_inputline[(scanner_inputchar - 1)]) == '"') {
		scanner_inputchar += 1;
	    };
	};
	{
	    TLstring	__x2495;
	    TL_TLS_TLSBXX(__x2495, (TLint4) (scanner_inputchar - 1), (TLint4) startchar, ((* (TLstring *) scanner_inputline)));
	    TLSTRASS(255, pattern, __x2495);
	};
	if (strcmp(pattern, "\"\"") == 0) {
	    TLSTRASS(255, pattern, "\"$%&*/ UNDEFINED /*&%$\"");
	};
	{
	    TLchar	__x2498[2];
	    {
		TLchar	__x2497[2];
		if (((TL_TLS_TLSLEN(pattern) < 3) || ((TL_TLS_TLSBX(__x2497, (TLint4) 1, pattern), strcmp(__x2497, "\"") != 0))) || ((TL_TLS_TLSBS(__x2498, (TLint4) 0, pattern), strcmp(__x2498, "\"") != 0))) {
		    {
			TLstring	__x2501;
			TL_TLS_TLSBXS(__x2501, (TLint4) 0, (TLint4) startchar, ((* (TLstring *) scanner_inputline)));
			{
			    TLstring	__x2500;
			    TL_TLS_TLSCAT("Syntax error in token pattern definition (expected pattern string, got \'", __x2501, __x2500);
			    {
				TLstring	__x2499;
				TL_TLS_TLSCAT(__x2500, "\')", __x2499);
				error("", __x2499, (TLint4) 20, (TLint4) 177);
			    };
			};
		    };
		};
	    };
	};
	{
	    TLstring	__x2503;
	    TL_TLS_TLSBXS(__x2503, (TLint4) -1, (TLint4) 2, pattern);
	    TLSTRASS(255, pattern, __x2503);
	};
	newp = 0;
	kind = 65;
	{
	    register TLint4	p;
	    TLint4	__x2504;
	    __x2504 = nPatterns;
	    p = 1;
	    if (p <= __x2504) {
		for(;;) {
		    if (strcmp((* (TLstring *) (identTable[tokenPatterns[p - 1].name])), name) == 0) {
			if (!extension) {
			    newp = p;
			};
			kind = tokenPatterns[p - 1].kind;
			break;
		    };
		    if (p == __x2504) break;
		    p++;
		}
	    };
	};
	if (strcmp(name, "comment") == 0) {
	    kind = 24;
	};
	if (newp == 0) {
	    if (nPatterns == 64) {
		{
		    TLstring	__x2508;
		    TL_TLS_TLSVIS((TLint4) 64, (TLint4) 1, (TLint4) 10, __x2508);
		    {
			TLstring	__x2507;
			TL_TLS_TLSCAT("Too many user-defined token patterns (>", __x2508, __x2507);
			{
			    TLstring	__x2506;
			    TL_TLS_TLSCAT(__x2507, ")", __x2506);
			    error("", __x2506, (TLint4) 21, (TLint4) 178);
			};
		    };
		};
	    };
	    nPatterns += 1;
	    newp = nPatterns;
	};
	if (kind == 65) {
	    if (nextUserTokenKind == 59) {
		error("", "Too many user-defined token kinds (>10)", (TLint4) 21, (TLint4) 179);
	    };
	    kind = nextUserTokenKind;
	    nextUserTokenKind = TLSUCC((TLint4) nextUserTokenKind, (TLint4) 65);
	};
	scanner_setTokenPattern((TLint4) newp, (kindT) kind, name, pattern);
	if ((newp == idPattern) && (!extension)) {
	    TLboolean	idscan;
	    TLSTRASS(255, (* (TLstring *) scanner_inputline), "function ");
	    scanner_inputchar = 1;
	    idscan = scanner_scanToken(tokenPatterns[idPattern - 1].pattern, (TLint4) 1, (TLint4) (tokenPatterns[idPattern - 1].length_), (TLboolean) 0);
	    if (!(idscan && (scanner_inputchar == (TL_TLS_TLSLEN("function") + 1)))) {
		error("", "Token pattern for [id] does not allow TXL keywords", (TLint4) 20, (TLint4) 180);
	    };
	};
    };
    scanner_expectend("tokens");
    scanner_sortTokenPatterns();
}

void scanner_tokenize (fileNameOrText, isFile, isTxlSource)
TLstring	fileNameOrText;
TLboolean	isFile;
TLboolean	isTxlSource;
{
    TLboolean	processingTxl;
    tokenT	token;
    tokenT	previoustoken;
    tokenT	rawtoken;
    scanner_fileInput = isFile;
    scanner_txlSource = isTxlSource;
    if (scanner_txlSource) {
	scanner_defaultTokenPatterns();
    };
    if (updatedChars) {
	scanner_sortTokenPatterns();
    };
    if ((options[34]) && (!scanner_txlSource)) {
	spaceP['\n'] = 0;
	spaceP['\r'] = 0;
    } else {
	spaceP['\n'] = 1;
	spaceP['\r'] = 1;
    };
    scanner_openFile(fileNameOrText);
    lastTokenHandle = 0;
    processingTxl = scanner_txlSource || (options[14]);
    token = 0;
    previoustoken = token;
    rawtoken = token;
    for(;;) {
	TLnat4	kind;
	TLint4	startchar;
	TLint4	litindex;
	for(;;) {
	    scanner_skipSeparators();
	    if ((scanner_inputline[(0)]) != (TLchar) '\376') {
		break;
	    };
	    scanner_synchronizePreprocessor();
	    if (scanner_includeDepth == 0) {
		break;
	    };
	    scanner_PopInclude();
	};
	if ((scanner_inputline[(0)]) == (TLchar) '\376') {
	    break;
	};
	kind = 65;
	startchar = scanner_inputchar;
	if (previoustoken == quoteT) {
	    previoustoken = 0;
	} else {
	    previoustoken = token;
	};
	token = 0;
	rawtoken = token;
	litindex = compoundIndex[scanner_inputline[(scanner_inputchar - 1)]];
	if ((litindex != 0) && ((!processingTxl) || (((((scanner_inputline[(scanner_inputchar - 1)]) != '.') || ((scanner_inputline[((scanner_inputchar + 1) - 1)]) != '.')) || ((scanner_inputline[((scanner_inputchar + 2) - 1)]) != '.')) || (previoustoken == quoteT)))) {
	    if (scanner_scanCompoundLiteral((TLint4) litindex)) {
		kind = 11;
		{
		    TLstring	__x2510;
		    TL_TLS_TLSBXX(__x2510, (TLint4) (scanner_inputchar - 1), (TLint4) startchar, ((* (TLstring *) scanner_inputline)));
		    ident_install(__x2510, (kindT) 11, &(token));
		};
		rawtoken = token;
	    };
	};
	if (kind == 65) {
	    if ((processingTxl && ((scanner_inputline[(scanner_inputchar - 1)]) == '\'')) && (previoustoken != quoteT)) {
	    } else {
		TLint4	patindex;
		patindex = patternIndex[scanner_inputline[(scanner_inputchar - 1)]];
		if (patindex != 0) {
		    for(;;) {
			TLBIND((*pp), struct patternT);
			pp = &(tokenPatterns[(patternLink[patindex - 1]) - 1]);
			if (scanner_scanToken((*pp).pattern, (TLint4) 1, (TLint4) ((*pp).length_), (TLboolean) 0)) {
			    kind = (*pp).kind;
			    if (scanner_txlSource && (!((kind < 30) || (previoustoken == quoteT)))) {
				kind = 65;
				scanner_inputchar = startchar;
			    } else {
				TLint4	endchar;
				TLchar	oldchar;
				endchar = scanner_inputchar - 1;
				oldchar = scanner_inputline[((endchar + 1) - 1)];
				scanner_inputline[((endchar + 1) - 1)] = '\0';
				if (options[35]) {
				    ident_install((* (TLstring *) &scanner_inputline[(startchar - 1)]), (kindT) 15, &(rawtoken));
				};
				if (((((options[29]) || (options[30])) || (options[35])) && ((kind != 13) && (kind != 12))) && (!(scanner_txlSource && (previoustoken != quoteT)))) {
				    if (options[29]) {
					{
					    register TLint4	i;
					    TLint4	__x2513;
					    __x2513 = endchar;
					    i = startchar;
					    if (i <= __x2513) {
						for(;;) {
						    scanner_inputline[(i - 1)] = uppercase[scanner_inputline[(i - 1)]];
						    if (i == __x2513) break;
						    i++;
						}
					    };
					};
				    } else {
					{
					    register TLint4	i;
					    TLint4	__x2514;
					    __x2514 = endchar;
					    i = startchar;
					    if (i <= __x2514) {
						for(;;) {
						    scanner_inputline[(i - 1)] = lowercase[scanner_inputline[(i - 1)]];
						    if (i == __x2514) break;
						    i++;
						}
					    };
					};
				    };
				};
				ident_install((* (TLstring *) &scanner_inputline[(startchar - 1)]), (kindT) 15, &(token));
				if (!(options[35])) {
				    rawtoken = token;
				};
				scanner_inputline[((endchar + 1) - 1)] = oldchar;
				if ((!processingTxl) || (previoustoken != quoteT)) {
				    if (keyP((tokenT) token)) {
					kind = 25;
				    };
				};
				break;
			    };
			};
			patindex += 1;
			if ((patternLink[patindex - 1]) == 0) {
			    break;
			};
		    };
		};
	    };
	};
	if (kind == 65) {
	    kind = 11;
	    {
		TLchar	__x2516[2];
		TL_TLS_TLSBX(__x2516, (TLint4) scanner_inputchar, ((* (TLstring *) scanner_inputline)));
		ident_install(__x2516, (kindT) 11, &(token));
	    };
	    rawtoken = token;
	    if ((scanner_inputline[(scanner_inputchar - 1)]) == '\n') {
		scanner_linenum += 1;
	    };
	    scanner_inputchar += 1;
	    if (((scanner_inputline[(startchar - 1)]) == '"') || (((scanner_inputline[(startchar - 1)]) == '\'') && (!processingTxl))) {
		if ((options[7]) && ((((scanner_inputline[(startchar - 1)]) == '"') && ((tokenPatterns[2].pattern[(0)]) == '"')) || (((scanner_inputline[(startchar - 1)]) == '\'') && ((tokenPatterns[3].pattern[(0)]) == '\'')))) {
		    error("", "Unmatched opening quote accepted as literal token", (TLint4) 1, (TLint4) 168);
		};
	    };
	    if (keyP((tokenT) token)) {
		kind = 25;
	    };
	    if (processingTxl) {
		if (keyP((tokenT) token)) {
		    kind = 25;
		} else {
		    if ((token == quoteT) && ((scanner_inputline[(scanner_inputchar - 1)]) == '%')) {
			TLint4	pcindex;
			TLint4	pcchar;
			pcindex = compoundIndex['%'];
			pcchar = scanner_inputchar;
			if ((pcindex != 0) && scanner_scanCompoundLiteral((TLint4) pcindex)) {
			    kind = 11;
			    {
				TLstring	__x2518;
				TL_TLS_TLSBXX(__x2518, (TLint4) (scanner_inputchar - 1), (TLint4) pcchar, ((* (TLstring *) scanner_inputline)));
				ident_install(__x2518, (kindT) 11, &(token));
			    };
			    rawtoken = token;
			} else {
			    previoustoken = quoteT;
			    ident_install("%", (kindT) 11, &(token));
			    rawtoken = token;
			    startchar = scanner_inputchar;
			    scanner_inputchar += 1;
			};
		    } else {
			if (token == underscoreT) {
			    kind = 15;
			} else {
			    if ((((token == dotT) && (previoustoken != quoteT)) && ((scanner_inputline[(scanner_inputchar - 1)]) == '.')) && ((scanner_inputline[((scanner_inputchar + 1) - 1)]) == '.')) {
				token = dotDotDotT;
				rawtoken = token;
				kind = 25;
				scanner_inputchar += 2;
			    };
			};
		    };
		};
		if (scanner_txlSource && (previoustoken == openbracketT)) {
		    TLchar	tokenchar;
		    tokenchar = scanner_inputline[(startchar - 1)];
		    if (((scanner_inputline[(scanner_inputchar - 1)]) == '=') && (((tokenchar == '~') || (tokenchar == '<')) || (tokenchar == '>'))) {
			scanner_inputchar += 1;
			{
			    TLstring	__x2520;
			    TL_TLS_TLSBXX(__x2520, (TLint4) (scanner_inputchar - 1), (TLint4) startchar, ((* (TLstring *) scanner_inputline)));
			    ident_install(__x2520, (kindT) 11, &(token));
			};
			rawtoken = token;
		    } else {
			if (tokenchar == '?') {
			    scanner_skipSeparators();
			    startchar = scanner_inputchar - 1;
			    scanner_inputline[(startchar - 1)] = '?';
			    if (alphaidP[scanner_inputline[(scanner_inputchar - 1)]]) {
				for(;;) {
				    if (!(idP[scanner_inputline[(scanner_inputchar - 1)]])) {
					break;
				    };
				    scanner_inputchar += 1;
				};
				{
				    TLstring	__x2522;
				    TL_TLS_TLSBXX(__x2522, (TLint4) (scanner_inputchar - 1), (TLint4) startchar, ((* (TLstring *) scanner_inputline)));
				    ident_install(__x2522, (kindT) 15, &(token));
				};
				rawtoken = token;
				kind = 15;
			    };
			};
		    };
		};
	    };
	};
	if (scanner_txlSource) {
	    if ((kind == 25) && (previoustoken != quoteT)) {
		if (token == keysT) {
		    scanner_processKeywordTokens();
		    kind = 65;
		} else {
		    if (token == compoundsT) {
			scanner_processCompoundTokens();
			kind = 65;
		    } else {
			if (token == commentsT) {
			    scanner_processCommentBrackets();
			    kind = 65;
			} else {
			    if (token == tokensT) {
				scanner_processTokenPatterns();
				kind = 65;
			    } else {
				if (token == includeT) {
				    scanner_PushInclude();
				    kind = 65;
				};
			    };
			};
		    };
		};
	    } else {
		if ((previoustoken == quoteT) && ((kind == 11) || (kind == 25))) {
		    TLint4	comindex;
		    comindex = scanner_commentindex((tokenT) token);
		    if (comindex != 0) {
			scanner_scanComment((TLint4) startchar, (TLint4) comindex);
			kind = 65;
		    };
		};
	    };
	} else {
	    if (((kind == 11) || (kind == 25)) && (!((previoustoken == quoteT) && processingTxl))) {
		TLint4	comindex;
		comindex = scanner_commentindex((tokenT) token);
		if (comindex != 0) {
		    scanner_scanComment((TLint4) startchar, (TLint4) comindex);
		    kind = 65;
		};
	    } else {
		if (kind == 24) {
		    if (!(options[16])) {
			kind = 65;
		    };
		};
	    };
	};
	if ((kind != 65) && (kind != 10)) {
	    scanner_installToken((kindT) kind, (tokenT) token, (tokenT) rawtoken);
	};
    };
    if (scanner_txlSource) {
	scanner_sortKeywords((TLint4) (nTxlKeys + 1));
    };
    lastTokenHandle += 1;
    inputTokens[lastTokenHandle - 1] = empty_T;
    inputTokenRaw[lastTokenHandle - 1] = empty_T;
    inputTokenKind[lastTokenHandle - 1] = 10;
    inputTokenLineNum[lastTokenHandle - 1] = (scanner_filenum * maxLines) + scanner_linenum;
    scanner_closeFile();
}

void scanner () {
    scanner_stdin = -2;
    scanner_inputStream = 0;
    scanner_includeDepth = 0;
    TLSTRASS(255, scanner_sourceFileDirectory, "");
    TLSTRASS(255, scanner_nextinputline, "");
    scanner_nextlength = 0;
    scanner_inputline[(0)] = '\0';
    scanner_newlineComments = 0;
    scanner_ifdefTop = 0;
}
