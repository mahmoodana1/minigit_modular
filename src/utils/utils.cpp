#include "../../include/utils/utils.h"
#include <filesystem>
#include <fstream>
#include <iostream>

namespace Utils {

void copyDirRecursive(const fs::path &src, const fs::path &dest,
                      bool skipMeta) {
    fs::path absSrc = fs::absolute(src);
    fs::path absDest = fs::absolute(dest);

    if (!fs::exists(absSrc) || !fs::is_directory(absSrc)) {
        std::cerr << "Source path invalid: " << absSrc << "\n";
        return;
    }

    for (const auto &entry : fs::recursive_directory_iterator(absSrc)) {
        fs::path path = entry.path();
        fs::path relativePath = fs::relative(path, absSrc);
        fs::path target = absDest / relativePath;

        // FIXED skipMeta (checks only folder names, not full absolute path)
        std::string name = path.filename().string();
        if (skipMeta && (name == ".git" || name == ".minigit"))
            continue;

        if (fs::is_directory(path)) {
            fs::create_directories(target);
        } else if (fs::is_regular_file(path)) {
            fs::create_directories(target.parent_path());
            fs::copy_file(path, target, fs::copy_options::overwrite_existing);
        }
    }
}

void deleteDirRecursive(const fs::path &src, bool skipMeta) {
    if (!fs::exists(src))
        return;

    for (const auto &entry : fs::directory_iterator(src)) {
        fs::path p = entry.path();
        std::string name = p.filename().string();

        // Skip .git and .minigit
        if (skipMeta && (name == ".git" || name == ".minigit"))
            continue;

        if (fs::is_directory(p)) {
            deleteDirRecursive(p, skipMeta); // delete inside first
            fs::remove(p);                   // then delete folder
        } else {
            fs::remove(p); // delete file
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

std::string getLine(const fs::path &path) {
    std::ifstream file(path);
    std::string firstLine;

    if (file.is_open()) {
        std::getline(file, firstLine);
        file.close();
    } else {
        std::cout << "Failed to open file:" << path.string() << '\n';
    }

    return firstLine;
}

void clearAndPushLine(const fs::path &path, std::string line) {
    std::ofstream file(path);

    if (file.is_open()) {
        file << line;
        file.close();
    } else {
        std::cout << "Failed to open file.\n";
        return;
    }
}

bool fileNameExists(const fs::path &path, std::string name) {
    for (const fs::directory_entry &entry : fs::directory_iterator(path)) {
        if (entry.path().filename() == name) {
            return true;
        }
    }

    return false;
}

void printFilesInDirectory(const fs::path &path, bool branches) {
    std::ifstream file(path);

    if (file.is_open()) {
        for (const fs::directory_entry &entry : fs::directory_iterator(path)) {
            char prefix = ' ';
            if (branches) {
                std::string currentBranchName =
                    Utils::getLine(".minigit/currentBranch");
                if (currentBranchName == entry.path().filename()) {
                    prefix = '*';
                }
            }
            std::cout << prefix << entry.path().filename().string() << '\n';
        }
        file.close();
    } else {
        std::cout << "Failed to open file:" << path.string() << '\n';
    }

    return;
}

std::vector<std::string> readLines(const fs::path &path) {
    std::ifstream file(path);
    std::vector<std::string> parts;

    if (!file.is_open()) {
        std::cout << "Failed to open file: " << path.string() << '\n';
        return parts;
    }

    std::string line;
    while (std::getline(file, line)) {
        std::stringstream ss(line);
        std::string word;

        while (ss >> word) {
            parts.push_back(word);
        }
    }

    return parts;
}

bool exists(const fs::path &path) { return fs::exists(path); }

} // namespace Utils
