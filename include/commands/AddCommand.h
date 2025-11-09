#include "../core/CommandRegistry.h"
#include "Command.h"
#include <memory>

class AddCommand : public Command {
    void execute(const std::vector<std::string> &args) override;
    bool checkArgs(const std::vector<std::string> &args) override;
    std::string getName() override;
};
