#include "../../include/utils/utils.h"
#include <filesystem>
#include <iostream>

namespace Utils {

void copyDirRecursive(const fs::path &src, const fs::path &dest,
                      bool skipMeta) {
    if (!fs::exists(src)) {
        std::cout << "Source directory does not exist: " << src << "\n";
        return;
    }

    for (const auto &entry : fs::recursive_directory_iterator(src)) {
        const auto &path = entry.path();
        auto relativePath = fs::relative(path, src);
        fs::path targetPath = dest / relativePath;

        // Skip .git and .minigit directories if requested
        if (skipMeta) {
            if (path.string().find(".git") != std::string::npos ||
                path.string().find(".minigit") != std::string::npos) {
                continue;
            }
        }

        if (fs::is_directory(path)) {
            fs::create_directories(targetPath);
        } else if (fs::is_regular_file(path)) {
            copyFileSafe(path, targetPath);
        }
    }
}

void copyFileSafe(const fs::path &src, const fs::path &destRoot) {
    try {
        if (!fs::exists(src) || !fs::is_regular_file(src)) {
            std::cerr << "Source file not found or not a regular file: " << src
                      << "\n";
            return;
        }

        fs::path targetPath = destRoot / fs::relative(src);

        std::cout << targetPath.string() << '\n';

        fs::create_directories(targetPath.parent_path());

        if (fs::exists(targetPath) && fs::is_directory(targetPath)) {
            fs::remove_all(targetPath);
        }

        fs::copy_file(src, targetPath, fs::copy_options::overwrite_existing);

        std::cout << "Copied " << src << " → " << targetPath << "\n";
    } catch (const std::exception &e) {
        std::cerr << "Failed to copy file: " << src << " → " << destRoot
                  << "\nReason: " << e.what() << "\n";
    }
}

void removeDir(const fs::path &path) {
    try {
        if (fs::exists(path)) {
            fs::remove_all(path);
        }
    } catch (const std::exception &e) {
        std::cerr << "Failed to remove directory: " << path
                  << "\nReason: " << e.what() << "\n";
    }
}

void ensureDir(const fs::path &path) {
    try {
        fs::create_directories(path);
    } catch (const std::exception &e) {
        std::cerr << "Failed to create directory: " << path
                  << "\nReason: " << e.what() << "\n";
    }
}

bool exists(const fs::path &path) { return fs::exists(path); }

} // namespace Utils
