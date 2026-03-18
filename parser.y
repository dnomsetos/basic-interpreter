%skeleton "lalr1.cc"
%require "3.5"
%defines
%define api.token.constructor
%define api.value.type variant
%define parse.assert
%code requires {
    #include "include/ast.hh"

    class Scanner;
    class Driver;
}
%define parse.trace
%define parse.error verbose
%lex-param { Scanner &scanner }
%parse-param { Scanner &scanner }
%parse-param { Driver &driver }
%locations
%define api.token.prefix {TOK_}
%code {
    #include "include/driver.hh"
    #include "location.hh"

    yy::parser::symbol_type yylex(Scanner &scanner) {
        return scanner.ScanToken();
    }
}
%token
    END 0 "end of file"
    START "HAI 1.3"
    STOP "KTHXBYE"
    LET "I HAS A"
    ASSIGN "R"
    PRINT "VISIBLE"
    DIFF "DIFF OF"
    SUM "SUM OF"
    MUL "PRODUKT OF"
    DIV "QUOSHUNT OF"
    MOD "MOD OF"
    MAX "BIGGR OF"
    MIN "SMALLR OF"
    EXP_SEP "AN"
    INIT_SEP "ITZ"
    FALSE "FAIL"
    TRUE "WIN"
    AND "BOTH OF"
    OR "EITHER OF"
    XOR "WON OF"
    NOT "NOT"
    IF_START ", O RLY?"
    IF "YA RLY"
    ELIF "MEBBE"
    ELSE "NO WAI"
    IF_END "OIC"
    EQ "BOTH SAEM"
    NOT_EQ "DIFFRINT"
    CONCAT_START "SMOOSH"
    CONCAT_END "MKAY"
    LOOP_START "IM IN YR"
    LOOP_END "IM OUTTA YR"
;
%token <bool> INCR
%token <bool> DECR
%token <bool> TIL
%token <bool> WILE
%token <std::string> IDENTIFIER
%token <int> INT_NUMBER
%token <std::string> STRING

%nterm <std::vector<StmtPtr>> commands
%nterm <StmtPtr> command
%nterm <StmtPtr> initialization
%nterm <StmtPtr> print
%nterm <StmtPtr> assignment
%nterm <StmtPtr> if_statement
%nterm <StmtPtr> for_cycle
%nterm <StmtPtr> while_cycle
%nterm <std::vector<ElifClause>> elif_clauses
%nterm <std::vector<ExprPtr>> concat_chain
%nterm <ExprPtr> exp

%%
%start unit;
unit:
    START commands STOP {
        for (auto& x : $2) {
            x->execute(driver);
        }
    };
commands:
    %empty { $$ = std::vector<StmtPtr>(); };
    | commands command { $$ = std::move($1); $$.emplace_back(std::move($2)); };
command:
    assignment { $$ = std::move($1); };
    | initialization { $$ = std::move($1); };
    | print { $$ = std::move($1); };
    | exp { $$ = std::make_unique<ExpressionStatement>(std::move($1)); };
    | if_statement { $$ = std::move($1); };
    | for_cycle { $$ = std::move($1); };
    | while_cycle { $$ = std::move($1); };
initialization:
    LET IDENTIFIER INIT_SEP exp {
        $$ = std::make_unique<AssignmentStatement>(std::move($2), std::move($4));
    };
print:
    PRINT exp {
        $$ = std::make_unique<PrintStatement>(std::move($2));
    };
assignment:
    IDENTIFIER ASSIGN exp {
        $$ = std::make_unique<AssignmentStatement>(std::move($1), std::move($3));
    };
exp:
    IDENTIFIER {
        $$ = std::make_unique<IdentifierExpr>($1);
    };
    | STRING {
        $$ = std::make_unique<LiteralString>($1);
    };
    | CONCAT_START concat_chain CONCAT_END {
        $$ = std::make_unique<ConcatExpression>(std::move($2));
    };
    | TRUE {
        $$ = std::make_unique<LiteralBool>(true);
    };
    | FALSE {
        $$ = std::make_unique<LiteralBool>(false);
    };
    | AND exp EXP_SEP exp {
        $$ = std::make_unique<BinaryExpression>(BinaryOpType::BOTH_OF, std::move($2), std::move($4));
    };
    | OR exp EXP_SEP exp {
        $$ = std::make_unique<BinaryExpression>(BinaryOpType::EITHER_OF, std::move($2), std::move($4));
    };
    | XOR exp EXP_SEP exp {
        $$ = std::make_unique<BinaryExpression>(BinaryOpType::WON_OF, std::move($2), std::move($4));
    };
    | NOT exp {
        $$ = std::make_unique<NotExpression>(std::move($2));
    };
    | INT_NUMBER {
        $$ = std::make_unique<LiteralInt>($1);
    };
    | SUM exp EXP_SEP exp {
        $$ = std::make_unique<BinaryExpression>(BinaryOpType::SUM_OF, std::move($2), std::move($4));
    };
    | DIFF exp EXP_SEP exp {
        $$ = std::make_unique<BinaryExpression>(BinaryOpType::DIFF_OF, std::move($2), std::move($4));
    };
    | MUL exp EXP_SEP exp {
        $$ = std::make_unique<BinaryExpression>(BinaryOpType::PRODUKT_OF, std::move($2), std::move($4));
    };
    | DIV exp EXP_SEP exp {
        $$ = std::make_unique<BinaryExpression>(BinaryOpType::QUOSHUNT_OF, std::move($2), std::move($4));
    };
    | MOD exp EXP_SEP exp {
        $$ = std::make_unique<BinaryExpression>(BinaryOpType::MOD_OF, std::move($2), std::move($4));
    };
    | MAX exp EXP_SEP exp {
        $$ = std::make_unique<BinaryExpression>(BinaryOpType::BIGGR_OF, std::move($2), std::move($4));
    };
    | MIN exp EXP_SEP exp {
        $$ = std::make_unique<BinaryExpression>(BinaryOpType::SMALLR_OF, std::move($2), std::move($4));
    };
    | EQ exp EXP_SEP exp {
        $$ = std::make_unique<BinaryExpression>(BinaryOpType::EQ, std::move($2), std::move($4));
    };
    | NOT_EQ exp EXP_SEP exp {
        $$ = std::make_unique<BinaryExpression>(BinaryOpType::DIFFRINT, std::move($2), std::move($4));
    };
concat_chain:
    exp {
        std::vector<ExprPtr> tmp;
        tmp.push_back(std::move($1));
        $$ = std::move(tmp);
    };
    | concat_chain EXP_SEP exp {
        $$ = std::move($1);
        $$.push_back(std::move($3));
    };
if_statement:
    exp IF_START IF commands elif_clauses ELSE commands IF_END {
        $$ = std::make_unique<IfStatement>(std::move($1), std::move($4), std::move($5), std::move($7));
    }
    | exp IF_START IF commands elif_clauses IF_END {
        $$ = std::make_unique<IfStatement>(std::move($1), std::move($4), std::move($5), std::vector<StmtPtr>{});
    };
elif_clauses:
    %empty { $$ = std::vector<ElifClause>{}; }
    | elif_clauses "MEBBE" exp commands {
        auto tmp = std::move($1);
        tmp.emplace_back(ElifClause{std::move($3), std::move($4)});
        $$ = std::move(tmp);
    };
for_cycle:
    LOOP_START IDENTIFIER INCR IDENTIFIER TIL exp commands LOOP_END IDENTIFIER {
        $$ = std::make_unique<ForStatement>($2, $9, $3, $4, $5, std::move($6), std::move($7));
    }
    | LOOP_START IDENTIFIER DECR IDENTIFIER TIL exp commands LOOP_END IDENTIFIER {
        $$ = std::make_unique<ForStatement>($2, $9, $3, $4, $5, std::move($6), std::move($7));
    }
    | LOOP_START IDENTIFIER INCR IDENTIFIER WILE exp commands LOOP_END IDENTIFIER {
        $$ = std::make_unique<ForStatement>($2, $9, $3, $4, $5, std::move($6), std::move($7));
    }
    | LOOP_START IDENTIFIER DECR IDENTIFIER WILE exp commands LOOP_END IDENTIFIER {
        $$ = std::make_unique<ForStatement>($2, $9, $3, $4, $5, std::move($6), std::move($7));
    };
while_cycle:
    LOOP_START IDENTIFIER TIL exp commands LOOP_END IDENTIFIER {
        $$ = std::make_unique<WhileStatement>($2, $7, $3, std::move($4), std::move($5));
    }
    | LOOP_START IDENTIFIER WILE exp commands LOOP_END IDENTIFIER {
        $$ = std::make_unique<WhileStatement>($2, $7, $3, std::move($4), std::move($5));
    };
%%
void
yy::parser::error(const location_type& l, const std::string& m)
{
  std::cerr << l << ": " << m << '\n';
}
