%skeleton "lalr1.cc"
%require "3.5"
%defines
%define api.token.constructor
%define api.value.type variant
%define parse.assert
%code requires {
    #include <functional>
    #include <list>
    #include <string>
    #include <variant>
    #include <memory>
    #include <vector>
    #include <iostream>
    #include <stdexcept>

    class Scanner;
    class Driver;

    class Expression;
    class Statement;

    using ExprPtr = std::unique_ptr<Expression>;
    using StmtPtr = std::unique_ptr<Statement>;

    class Expression {
    public:
        virtual ~Expression() = default;
        virtual std::variant<int, bool, std::string, std::nullptr_t> evaluate(Driver& driver) const = 0;
    };

    class Statement {
    public:
        virtual ~Statement() = default;
        virtual void execute(Driver& driver) const = 0;
    };

    struct ElifClause {
        ExprPtr condition;
        std::vector<StmtPtr> body;
    };

    enum class BinaryOpType {
        SUM_OF, DIFF_OF, PRODUKT_OF, QUOSHUNT_OF, MOD_OF,
        BIGGR_OF, SMALLR_OF,
        BOTH_OF, EITHER_OF, WON_OF,
        EQ, DIFFRINT
    };

    class LiteralInt : public Expression {
        int value;
    public:
        explicit LiteralInt(int v) : value(v) {}
        std::variant<int, bool, std::string, std::nullptr_t> evaluate(Driver& driver) const override;
    };

    class LiteralString : public Expression {
        std::string value;
    public:
        explicit LiteralString(std::string v) : value(std::move(v)) {}
        std::variant<int, bool, std::string, std::nullptr_t> evaluate(Driver& driver) const override;
    };

    class LiteralBool : public Expression {
        bool value;
    public:
        explicit LiteralBool(bool v) : value(v) {}
        std::variant<int, bool, std::string, std::nullptr_t> evaluate(Driver& driver) const override;
    };

    class IdentifierExpr : public Expression {
        std::string name;
    public:
        explicit IdentifierExpr(std::string n) : name(std::move(n)) {}
        std::variant<int, bool, std::string, std::nullptr_t> evaluate(Driver& driver) const override;
    };

    class NotExpression : public Expression {
        ExprPtr operand;
    public:
        explicit NotExpression(ExprPtr op) : operand(std::move(op)) {}
        std::variant<int, bool, std::string, std::nullptr_t> evaluate(Driver& driver) const override;
    };

    class ConcatExpression : public Expression {
        std::vector<ExprPtr> parts;
    public:
        explicit ConcatExpression(std::vector<ExprPtr> p) : parts(std::move(p)) {}
        std::variant<int, bool, std::string, std::nullptr_t> evaluate(Driver& driver) const override;
    };

    class BinaryExpression : public Expression {
        BinaryOpType op;
        ExprPtr left;
        ExprPtr right;
    public:
        BinaryExpression(BinaryOpType o, ExprPtr l, ExprPtr r) : op(o), left(std::move(l)), right(std::move(r)) {}
        std::variant<int, bool, std::string, std::nullptr_t> evaluate(Driver& driver) const override;
    };

    class AssignmentStatement : public Statement {
        std::string name;
        ExprPtr valueExpr;
    public:
        AssignmentStatement(std::string n, ExprPtr v) : name(std::move(n)), valueExpr(std::move(v)) {}
        void execute(Driver& driver) const override;
    };

    class PrintStatement : public Statement {
        ExprPtr expr;
    public:
        explicit PrintStatement(ExprPtr e) : expr(std::move(e)) {}
        void execute(Driver& driver) const override;
    };

    class ExpressionStatement : public Statement {
        ExprPtr expr;
    public:
        explicit ExpressionStatement(ExprPtr e) : expr(std::move(e)) {}
        void execute(Driver& driver) const override;
    };

    class IfStatement : public Statement {
        ExprPtr condition;
        std::vector<StmtPtr> thenBody;
        std::vector<ElifClause> elifClauses;
        std::vector<StmtPtr> elseBody;
    public:
        IfStatement(ExprPtr cond, std::vector<StmtPtr> thenB, std::vector<ElifClause> elifs, std::vector<StmtPtr> elseB)
            : condition(std::move(cond)), thenBody(std::move(thenB)), elifClauses(std::move(elifs)), elseBody(std::move(elseB)) {}
        void execute(Driver& driver) const override;
    };

    class ForStatement : public Statement {
        std::string startName, endName;
        bool isIncrement;
        std::string iterName;
        bool condMode;
        ExprPtr condition;
        std::vector<StmtPtr> body;
    public:
        ForStatement(std::string s, std::string e, bool incr, std::string it, bool cm, ExprPtr cnd, std::vector<StmtPtr> b)
            : startName(std::move(s)), endName(std::move(e)), isIncrement(incr), iterName(std::move(it)), condMode(cm), condition(std::move(cnd)), body(std::move(b)) {}
        void execute(Driver& driver) const override;
    };

    class WhileStatement : public Statement {
        std::string startName, endName;
        bool condMode;
        ExprPtr condition;
        std::vector<StmtPtr> body;
    public:
        WhileStatement(std::string s, std::string e, bool cm, ExprPtr cnd, std::vector<StmtPtr> b)
            : startName(std::move(s)), endName(std::move(e)), condMode(cm), condition(std::move(cnd)), body(std::move(b)) {}
        void execute(Driver& driver) const override;
    };
}
%define parse.trace
%define parse.error verbose
%code {
    #include "driver.hh"
    #include "location.hh"

    static yy::parser::symbol_type yylex(Scanner &scanner) {
        return scanner.ScanToken();
    }

    std::variant<int, bool, std::string, std::nullptr_t> LiteralInt::evaluate(Driver&) const { return value; }
    std::variant<int, bool, std::string, std::nullptr_t> LiteralString::evaluate(Driver&) const { return value; }
    std::variant<int, bool, std::string, std::nullptr_t> LiteralBool::evaluate(Driver&) const { return value; }

    std::variant<int, bool, std::string, std::nullptr_t> IdentifierExpr::evaluate(Driver& driver) const {
        if (driver.variables.find(name) == driver.variables.end()) {
            std::cerr << "Using undeclared variable: " << name << std::endl;
            throw std::runtime_error("Undeclared variable");
        }
        auto& val = driver.variables[name];
        if (std::holds_alternative<int>(val)) return std::get<int>(val);
        if (std::holds_alternative<bool>(val)) return std::get<bool>(val);
        if (std::holds_alternative<std::string>(val)) return std::get<std::string>(val);
        return nullptr;
    }

    std::variant<int, bool, std::string, std::nullptr_t> NotExpression::evaluate(Driver& driver) const {
        auto val = operand->evaluate(driver);
        if (std::holds_alternative<bool>(val)) return !std::get<bool>(val);
        std::cerr << "Argument of NOT must be bool" << std::endl;
        throw std::invalid_argument("Argument of NOT must be bool");
    }

    std::variant<int, bool, std::string, std::nullptr_t> ConcatExpression::evaluate(Driver& driver) const {
        std::string result;
        for (auto& part : parts) {
            auto val = part->evaluate(driver);
            if (std::holds_alternative<std::nullptr_t>(val)) {
                std::cerr << "Cannot concat NOOB type";
                throw std::runtime_error("Cannot concat NOOB type");
            } else if (std::holds_alternative<int>(val)) {
                result += std::to_string(std::get<int>(val));
            } else if (std::holds_alternative<bool>(val)) {
                result += std::get<bool>(val) ? "WIN" : "FAIL";
            } else {
                result += std::get<std::string>(val);
            }
        }
        return result;
    }

    std::variant<int, bool, std::string, std::nullptr_t> BinaryExpression::evaluate(Driver& driver) const {
        auto val1 = left->evaluate(driver);
        auto val2 = right->evaluate(driver);
        switch (op) {
            case BinaryOpType::SUM_OF:
                if (std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2))
                    return std::get<int>(val1) + std::get<int>(val2);
                std::cerr << "Arguments of SUM OF must be integer" << std::endl;
                throw std::invalid_argument("Arguments of SUM OF must be integer");
            case BinaryOpType::DIFF_OF:
                if (std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2))
                    return std::get<int>(val1) - std::get<int>(val2);
                std::cerr << "Arguments of DIFF OF must be integer" << std::endl;
                throw std::invalid_argument("Arguments of DIFF OF must be integer");
            case BinaryOpType::PRODUKT_OF:
                if (std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2))
                    return std::get<int>(val1) * std::get<int>(val2);
                std::cerr << "Arguments of PRODUKT OF must be integer" << std::endl;
                throw std::invalid_argument("Arguments of PRODUKT OF must be integer");
            case BinaryOpType::QUOSHUNT_OF:
                if (std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2))
                    return std::get<int>(val1) / std::get<int>(val2);
                std::cerr << "Arguments of QUOSHUNT OF must be integer" << std::endl;
                throw std::invalid_argument("Arguments of QUOSHUNT OF must be integer");
            case BinaryOpType::MOD_OF:
                if (std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2))
                    return std::get<int>(val1) % std::get<int>(val2);
                std::cerr << "Arguments of MOD OF must be integer" << std::endl;
                throw std::invalid_argument("Arguments of MOD OF must be integer");
            case BinaryOpType::BIGGR_OF:
                if (std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2))
                    return std::max(std::get<int>(val1), std::get<int>(val2));
                std::cerr << "Arguments of BIGGR OF must be integer" << std::endl;
                throw std::invalid_argument("Arguments of BIGGR OF must be integer");
            case BinaryOpType::SMALLR_OF:
                if (std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2))
                    return std::min(std::get<int>(val1), std::get<int>(val2));
                std::cerr << "Arguments of SMALLR OF must be integer" << std::endl;
                throw std::invalid_argument("Arguments of SMALLR OF must be integer");
            case BinaryOpType::BOTH_OF:
                if (std::holds_alternative<bool>(val1) && std::holds_alternative<bool>(val2))
                    return std::get<bool>(val1) && std::get<bool>(val2);
                std::cerr << "Arguments of BOTH OF must be bool" << std::endl;
                throw std::invalid_argument("Arguments of BOTH OF must be bool");
            case BinaryOpType::EITHER_OF:
                if (std::holds_alternative<bool>(val1) && std::holds_alternative<bool>(val2))
                    return std::get<bool>(val1) || std::get<bool>(val2);
                std::cerr << "Arguments of EITHER OF must be bool" << std::endl;
                throw std::invalid_argument("Arguments of EITHER OF must be bool");
            case BinaryOpType::WON_OF:
                if (std::holds_alternative<bool>(val1) && std::holds_alternative<bool>(val2))
                    return std::get<bool>(val1) != std::get<bool>(val2);
                std::cerr << "Arguments of WON OF must be bool" << std::endl;
                throw std::invalid_argument("Arguments of WON OF must be bool");
            case BinaryOpType::EQ:
            case BinaryOpType::DIFFRINT:
                if ((std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2)) ||
                    (std::holds_alternative<bool>(val1) && std::holds_alternative<bool>(val2)) ||
                    (std::holds_alternative<std::string>(val1) && std::holds_alternative<std::string>(val2)) ||
                    (std::holds_alternative<std::nullptr_t>(val1) && std::holds_alternative<std::nullptr_t>(val2))) {
                    return (op == BinaryOpType::EQ) ? (val1 == val2) : (val1 != val2);
                }
                std::cerr << "Arguments must have same type" << std::endl;
                throw std::invalid_argument("Arguments must have same type");
        }
        throw std::runtime_error("Unknown binary op");
    }

    void AssignmentStatement::execute(Driver& driver) const {
        driver.variables[name] = valueExpr->evaluate(driver);
        if (driver.location_debug) {
            std::cerr << driver.location << std::endl;
        }
    }

    void PrintStatement::execute(Driver& driver) const {
        auto val = expr->evaluate(driver);
        if (std::holds_alternative<int>(val)) {
            std::cout << std::get<int>(val) << std::endl;
        } else if (std::holds_alternative<bool>(val)) {
            std::cout << (std::get<bool>(val) ? "WIN" : "FAIL") << std::endl;
        } else if (std::holds_alternative<std::string>(val)) {
            std::cout << std::get<std::string>(val) << std::endl;
        } else {
            std::cerr << "Cannot implicitly cast nil" << std::endl;
            throw std::runtime_error("Cannot print NOOB type");
        }
    }

    void ExpressionStatement::execute(Driver& driver) const {
        expr->evaluate(driver);
    }

    void IfStatement::execute(Driver& driver) const {
        auto val = condition->evaluate(driver);
        if (!std::holds_alternative<bool>(val)) {
            std::cerr << "Expression in if statement must be bool type" << std::endl;
            throw std::invalid_argument("Expression in if statement must be bool type");
        }
        if (std::get<bool>(val)) {
            for (auto& command : thenBody) command->execute(driver);
            return;
        }
        for (const auto& elif : elifClauses) {
            auto v = elif.condition->evaluate(driver);
            if (!std::holds_alternative<bool>(v)) {
                std::cerr << "Expression in if statement must be bool type" << std::endl;
                throw std::invalid_argument("Expression in if statement must be bool type");
            }
            if (std::get<bool>(v)) {
                for (auto& command : elif.body) command->execute(driver);
                return;
            }
        }
        for (auto& command : elseBody) command->execute(driver);
    }

    void ForStatement::execute(Driver& driver) const {
        bool created = false;
        if (driver.variables.find(iterName) == driver.variables.end()) {
            driver.variables.emplace(iterName, 0);
            created = true;
        }
        auto& it = driver.variables[iterName];
        if (!std::holds_alternative<int>(it)) {
            std::cerr << "Iterator must be integer" << std::endl;
            throw std::invalid_argument("Iterator must be integer");
        }
        it = 0;
        int step = isIncrement ? 1 : -1;
        while (true) {
            auto cond_val = condition->evaluate(driver);
            if (!std::holds_alternative<bool>(cond_val)) {
                std::cerr << "For condition must be bool" << std::endl;
                throw std::invalid_argument("For condition must be bool");
            }
            bool cond = std::get<bool>(cond_val);
            if (cond != condMode) break;
            for (auto& cmd : body) cmd->execute(driver);
            std::get<int>(it) += step;
        }
        if (created) driver.variables.erase(iterName);
    }

    void WhileStatement::execute(Driver& driver) const {
        while (true) {
            auto cond_val = condition->evaluate(driver);
            if (!std::holds_alternative<bool>(cond_val)) {
                std::cerr << "While condition must be bool" << std::endl;
                throw std::invalid_argument("While condition must be bool");
            }
            bool cond = std::get<bool>(cond_val);
            if (cond != condMode) break;
            for (auto& cmd : body) cmd->execute(driver);
        }
    }
}
%lex-param { Scanner &scanner }
%parse-param { Scanner &scanner }
%parse-param { Driver &driver }
%locations
%define api.token.prefix {TOK_}
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
