CXX = g++
FLAGS = -std=c++17 -Iinclude
LIBS = -lstdc++fs
SRC = $(shell find src -name '*.cpp')
BIN = build/minigit

build:
	mkdir -p build
	$(CXX) $(FLAGS) $(SRC) $(LIBS) -o $(BIN)

test:
	bats -p tests/

clean:
	rm -rf build

run: build
	./$(BIN) $(ARGS)
