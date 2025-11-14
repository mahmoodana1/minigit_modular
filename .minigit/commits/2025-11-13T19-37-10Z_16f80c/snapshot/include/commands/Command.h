#pragma once
#include "../../include/utils/utils.h"
#include <iostream>
#include <string>
#include <vector>

class Command {
  public:
    virtual ~Command() = default;
    virtual bool checkArgs(const std::vector<std::string> &args) = 0;
    virtual std::string getName() = 0;
    virtual void description() = 0;
    virtual void execute(const std::vector<std::string> &args) = 0;
};
