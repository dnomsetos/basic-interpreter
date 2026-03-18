#pragma once

#include <fstream>
#include <map>
#include <string>
#include <variant>

#include "parser.hh"
#include "scanner.hh"

class Driver {
public:
  Driver();
  std::map<std::string, std::variant<int, bool, std::string, std::nullptr_t>>
      variables;
  int result;
  int parse(const std::string &f);
  std::string file;

  void scan_begin();
  void scan_end();

  bool trace_parsing;
  bool trace_scanning;
  yy::location location;

  friend class Scanner;
  Scanner scanner;
  yy::parser parser;
  bool location_debug;

private:
  std::ifstream stream;
};
