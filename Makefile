CXX = g++
FLAGS = -std=c++17 -Iinclude
LIBS = -lstdc++fs
SRC = $(shell find src -name '*.cpp')
BIN = build/minigit

build:
	mkdir -p build
	$(CXX) $(FLAGS) $(SRC) $(LIBS) -o $(BIN)

test: test-init test-add test-commit test-branch

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
