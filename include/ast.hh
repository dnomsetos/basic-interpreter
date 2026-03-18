#pragma once
#include <memory>
#include <string>
#include <variant>
#include <vector>

class Driver;

class Expression {
public:
  virtual ~Expression() = default;
  virtual std::variant<int, bool, std::string, std::nullptr_t>
  evaluate(Driver &driver) const = 0;
};

class Statement {
public:
  virtual ~Statement() = default;
  virtual void execute(Driver &driver) const = 0;
};

using ExprPtr = std::unique_ptr<Expression>;
using StmtPtr = std::unique_ptr<Statement>;

struct ElifClause {
  ExprPtr condition;
  std::vector<StmtPtr> body;
};

enum class BinaryOpType {
  SUM_OF,
  DIFF_OF,
  PRODUKT_OF,
  QUOSHUNT_OF,
  MOD_OF,
  BIGGR_OF,
  SMALLR_OF,
  BOTH_OF,
  EITHER_OF,
  WON_OF,
  EQ,
  DIFFRINT
};

class LiteralInt : public Expression {
  int value;

public:
  explicit LiteralInt(int v) : value(v) {}
  std::variant<int, bool, std::string, std::nullptr_t>
  evaluate(Driver &driver) const override;
};

class LiteralString : public Expression {
  std::string value;

public:
  explicit LiteralString(std::string v) : value(std::move(v)) {}
  std::variant<int, bool, std::string, std::nullptr_t>
  evaluate(Driver &driver) const override;
};

class LiteralBool : public Expression {
  bool value;

public:
  explicit LiteralBool(bool v) : value(v) {}
  std::variant<int, bool, std::string, std::nullptr_t>
  evaluate(Driver &driver) const override;
};

class IdentifierExpr : public Expression {
  std::string name;

public:
  explicit IdentifierExpr(std::string n) : name(std::move(n)) {}
  std::variant<int, bool, std::string, std::nullptr_t>
  evaluate(Driver &driver) const override;
};

class NotExpression : public Expression {
  ExprPtr operand;

public:
  explicit NotExpression(ExprPtr op) : operand(std::move(op)) {}
  std::variant<int, bool, std::string, std::nullptr_t>
  evaluate(Driver &driver) const override;
};

class ConcatExpression : public Expression {
  std::vector<ExprPtr> parts;

public:
  explicit ConcatExpression(std::vector<ExprPtr> p) : parts(std::move(p)) {}
  std::variant<int, bool, std::string, std::nullptr_t>
  evaluate(Driver &driver) const override;
};

class BinaryExpression : public Expression {
  BinaryOpType op;
  ExprPtr left;
  ExprPtr right;

public:
  BinaryExpression(BinaryOpType o, ExprPtr l, ExprPtr r)
      : op(o), left(std::move(l)), right(std::move(r)) {}
  std::variant<int, bool, std::string, std::nullptr_t>
  evaluate(Driver &driver) const override;
};

class AssignmentStatement : public Statement {
  std::string name;
  ExprPtr valueExpr;

public:
  AssignmentStatement(std::string n, ExprPtr v)
      : name(std::move(n)), valueExpr(std::move(v)) {}
  void execute(Driver &driver) const override;
};

class PrintStatement : public Statement {
  ExprPtr expr;

public:
  explicit PrintStatement(ExprPtr e) : expr(std::move(e)) {}
  void execute(Driver &driver) const override;
};

class ExpressionStatement : public Statement {
  ExprPtr expr;

public:
  explicit ExpressionStatement(ExprPtr e) : expr(std::move(e)) {}
  void execute(Driver &driver) const override;
};

class IfStatement : public Statement {
  ExprPtr condition;
  std::vector<StmtPtr> thenBody;
  std::vector<ElifClause> elifClauses;
  std::vector<StmtPtr> elseBody;

public:
  IfStatement(ExprPtr cond, std::vector<StmtPtr> thenB,
              std::vector<ElifClause> elifs, std::vector<StmtPtr> elseB);
  void execute(Driver &driver) const override;
};

class ForStatement : public Statement {
  std::string startName, endName;
  bool isIncrement;
  std::string iterName;
  bool condMode;
  ExprPtr condition;
  std::vector<StmtPtr> body;

public:
  ForStatement(std::string s, std::string e, bool incr, std::string it, bool cm,
               ExprPtr cnd, std::vector<StmtPtr> b);
  void execute(Driver &driver) const override;
};

class WhileStatement : public Statement {
  std::string startName, endName;
  bool condMode;
  ExprPtr condition;
  std::vector<StmtPtr> body;

public:
  WhileStatement(std::string s, std::string e, bool cm, ExprPtr cnd,
                 std::vector<StmtPtr> b);
  void execute(Driver &driver) const override;
};
