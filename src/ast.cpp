#include <algorithm>
#include <iostream>
#include <stdexcept>
#include <variant>

#include "include/ast.hh"
#include "include/driver.hh"

std::variant<int, bool, std::string, std::nullptr_t>
LiteralInt::evaluate(Driver &) const {
  return value;
}
std::variant<int, bool, std::string, std::nullptr_t>
LiteralString::evaluate(Driver &) const {
  return value;
}
std::variant<int, bool, std::string, std::nullptr_t>
LiteralBool::evaluate(Driver &) const {
  return value;
}

std::variant<int, bool, std::string, std::nullptr_t>
IdentifierExpr::evaluate(Driver &driver) const {
  if (driver.variables.find(name) == driver.variables.end()) {
    std::cerr << "Using undeclared variable: " << name << std::endl;
    throw std::runtime_error("Undeclared variable");
  }
  auto &val = driver.variables[name];
  if (std::holds_alternative<int>(val))
    return std::get<int>(val);
  if (std::holds_alternative<bool>(val))
    return std::get<bool>(val);
  if (std::holds_alternative<std::string>(val))
    return std::get<std::string>(val);
  return nullptr;
}

std::variant<int, bool, std::string, std::nullptr_t>
NotExpression::evaluate(Driver &driver) const {
  auto val = operand->evaluate(driver);
  if (std::holds_alternative<bool>(val))
    return !std::get<bool>(val);
  std::cerr << "Argument of NOT must be bool" << std::endl;
  throw std::invalid_argument("Argument of NOT must be bool");
}

std::variant<int, bool, std::string, std::nullptr_t>
ConcatExpression::evaluate(Driver &driver) const {
  std::string result;
  for (auto &part : parts) {
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

std::variant<int, bool, std::string, std::nullptr_t>
BinaryExpression::evaluate(Driver &driver) const {
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
    if (std::holds_alternative<bool>(val1) &&
        std::holds_alternative<bool>(val2))
      return std::get<bool>(val1) && std::get<bool>(val2);
    std::cerr << "Arguments of BOTH OF must be bool" << std::endl;
    throw std::invalid_argument("Arguments of BOTH OF must be bool");
  case BinaryOpType::EITHER_OF:
    if (std::holds_alternative<bool>(val1) &&
        std::holds_alternative<bool>(val2))
      return std::get<bool>(val1) || std::get<bool>(val2);
    std::cerr << "Arguments of EITHER OF must be bool" << std::endl;
    throw std::invalid_argument("Arguments of EITHER OF must be bool");
  case BinaryOpType::WON_OF:
    if (std::holds_alternative<bool>(val1) &&
        std::holds_alternative<bool>(val2))
      return std::get<bool>(val1) != std::get<bool>(val2);
    std::cerr << "Arguments of WON OF must be bool" << std::endl;
    throw std::invalid_argument("Arguments of WON OF must be bool");
  case BinaryOpType::EQ:
  case BinaryOpType::DIFFRINT:
    if ((std::holds_alternative<int>(val1) &&
         std::holds_alternative<int>(val2)) ||
        (std::holds_alternative<bool>(val1) &&
         std::holds_alternative<bool>(val2)) ||
        (std::holds_alternative<std::string>(val1) &&
         std::holds_alternative<std::string>(val2)) ||
        (std::holds_alternative<std::nullptr_t>(val1) &&
         std::holds_alternative<std::nullptr_t>(val2))) {
      return (op == BinaryOpType::EQ) ? (val1 == val2) : (val1 != val2);
    }
    std::cerr << "Arguments must have same type" << std::endl;
    throw std::invalid_argument("Arguments must have same type");
  }
  throw std::runtime_error("Unknown binary op");
}

void AssignmentStatement::execute(Driver &driver) const {
  driver.variables[name] = valueExpr->evaluate(driver);
  if (driver.location_debug) {
    std::cerr << driver.location << std::endl;
  }
}

void PrintStatement::execute(Driver &driver) const {
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

void ExpressionStatement::execute(Driver &driver) const {
  expr->evaluate(driver);
}

IfStatement::IfStatement(ExprPtr cond, std::vector<StmtPtr> thenB,
                         std::vector<ElifClause> elifs,
                         std::vector<StmtPtr> elseB)
    : condition(std::move(cond)), thenBody(std::move(thenB)),
      elifClauses(std::move(elifs)), elseBody(std::move(elseB)) {}

void IfStatement::execute(Driver &driver) const {
  auto val = condition->evaluate(driver);
  if (!std::holds_alternative<bool>(val)) {
    std::cerr << "Expression in if statement must be bool type" << std::endl;
    throw std::invalid_argument("Expression in if statement must be bool type");
  }
  if (std::get<bool>(val)) {
    for (auto &command : thenBody)
      command->execute(driver);
    return;
  }
  for (const auto &elif : elifClauses) {
    auto v = elif.condition->evaluate(driver);
    if (!std::holds_alternative<bool>(v)) {
      std::cerr << "Expression in if statement must be bool type" << std::endl;
      throw std::invalid_argument(
          "Expression in if statement must be bool type");
    }
    if (std::get<bool>(v)) {
      for (auto &command : elif.body)
        command->execute(driver);
      return;
    }
  }
  for (auto &command : elseBody)
    command->execute(driver);
}

ForStatement::ForStatement(std::string s, std::string e, bool incr,
                           std::string it, bool cm, ExprPtr cnd,
                           std::vector<StmtPtr> b)
    : startName(std::move(s)), endName(std::move(e)), isIncrement(incr),
      iterName(std::move(it)), condMode(cm), condition(std::move(cnd)),
      body(std::move(b)) {}

void ForStatement::execute(Driver &driver) const {
  bool created = false;
  if (driver.variables.find(iterName) == driver.variables.end()) {
    driver.variables.emplace(iterName, 0);
    created = true;
  }
  auto &it = driver.variables[iterName];
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
    if (cond != condMode)
      break;
    for (auto &cmd : body)
      cmd->execute(driver);
    std::get<int>(it) += step;
  }
  if (created)
    driver.variables.erase(iterName);
}

WhileStatement::WhileStatement(std::string s, std::string e, bool cm,
                               ExprPtr cnd, std::vector<StmtPtr> b)
    : startName(std::move(s)), endName(std::move(e)), condMode(cm),
      condition(std::move(cnd)), body(std::move(b)) {}

void WhileStatement::execute(Driver &driver) const {
  while (true) {
    auto cond_val = condition->evaluate(driver);
    if (!std::holds_alternative<bool>(cond_val)) {
      std::cerr << "While condition must be bool" << std::endl;
      throw std::invalid_argument("While condition must be bool");
    }
    bool cond = std::get<bool>(cond_val);
    if (cond != condMode)
      break;
    for (auto &cmd : body)
      cmd->execute(driver);
  }
}
