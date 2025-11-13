#include "../../include/commands/LogCommand.h"

std::string LogCommand::getName() { return "add"; }

bool LogCommand::checkArgs(const std::vector<std::string> &args) {
    return (args.size() != 2);
}
