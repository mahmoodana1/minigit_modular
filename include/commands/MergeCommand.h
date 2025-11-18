#pragma once
#include "../core/CommandRegistry.h"
#include "../utils/GeneratorUtils.h"
#include "Command.h"
#include "CommitCommand.h"

class MergeCommand : public CommitCommand {
    void execute(const std::vector<std::string> &args) override;
    bool checkArgs(const std::vector<std::string> &args) override;
    void description() override;
    void fastForwardMerge(const std::string &mergedInto,
                          const std::string &mergedBranchName);
    std::string getName() override;
    void indirectMerge(const std::string &mergedIntoBranchName,
                       const std::string &mergedBranchName);
};
