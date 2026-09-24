CXX = g++
FLAGS = -std=c++17 -Iinclude
LIBS = -lstdc++fs
SRC = $(shell find src -name '*.cpp')
BIN = build/minigit

build:
	mkdir -p build
	$(CXX) $(FLAGS) $(SRC) $(LIBS) -o $(BIN)

test:
	@rm -f /tmp/minigit-test.log; \
	for t in init add commit branch log status; do \
		$(MAKE) --no-print-directory test-$$t | tee -a /tmp/minigit-test.log; \
	done; \
	echo ""; \
	if grep -q "✗" /tmp/minigit-test.log; then \
		grep "✗" /tmp/minigit-test.log | awk '{gsub(/\033\[[0-9;]*[mK]/,""); sub(/.*✗ /,""); printf "[%d] failure in \"%s\"\n", NR, $$0}'; \
	else \
		echo "ALL PASSED"; \
	fi


test-init:
	bats -p tests/init.bats

test-add:
	bats -p tests/add.bats

test-commit:
	bats -p tests/commit.bats

test-branch:
	bats -p tests/branch.bats

test-log:
	bats -p tests/log.bats

test-status:
	bats -p tests/status.bats

clean:
	rm -rf build

run: build
	./$(BIN) $(ARGS)
