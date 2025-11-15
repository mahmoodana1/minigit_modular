#pragma once
#include "../core/CommandRegistry.h"
#include "Command.h"
#include <filesystem>

class StatusCommand : public Command {
    void execute(const std::vector<std::string> &args) override;
    bool checkArgs(const std::vector<std::string> &args) override;
    void description() override;
    bool checkFilesEqual(const fs::path &path1, const fs::path &path2);
    std::vector<std::pair<fs::path, std::string>> compareFiles();
    std::string getName() override;
};
