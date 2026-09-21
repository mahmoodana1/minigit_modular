CXX = g++
FLAGS = -std=c++17 -Iinclude
LIBS = -lstdc++fs
SRC = $(shell find src -name '*.cpp')
BIN = build/minigit

build:
	mkdir -p build
	$(CXX) $(FLAGS) $(SRC) $(LIBS) -o $(BIN)

test: 
	-$(MAKE) test-init --no-print-directory test-init || true
	-$(MAKE) test-add --no-print-directory test-init || true
	-$(MAKE) test-commit --no-print-directory test-init || true
	-$(MAKE) test-branch --no-print-directory test-init || true


test-init:
	bats -p tests/init.bats

test-add:
	bats -p tests/add.bats

test-commit:
	bats -p tests/commit.bats

test-branch:
	bats -p tests/branch.bats

clean:
	rm -rf build

run: build
	./$(BIN) $(ARGS)
