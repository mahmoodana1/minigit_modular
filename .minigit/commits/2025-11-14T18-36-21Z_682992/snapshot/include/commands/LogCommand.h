#pragma once
#include "../core/CommandRegistry.h"
#include "Command.h"
#include <vector>

class LogCommand : public Command {
    void execute(const std::vector<std::string> &args) override;
    bool checkArgs(const std::vector<std::string> &args) override;
    void description() override;
    void printLogs(const std::vector<std::string> &parts, bool printBranch);
    std::string getName() override;
};
