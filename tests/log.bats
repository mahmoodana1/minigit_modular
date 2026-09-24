#!/bin/bash

MINIGIT="$BATS_TEST_DIRNAME/../build/minigit"

setup() {
  cd /tmp
  rm -rf minigit-tests && mkdir minigit-tests && cd minigit-tests
  "$MINIGIT" init >/dev/null
}

# log
@test "log: no commits prints no history" {
  run "$MINIGIT" log
  [[ "$output" == *"Couldn't find log history"* ]]
}

@test "log: shows the commit message" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "first commit" >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"first commit"* ]]
}

@test "log: shows every commit" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "first commit" >/dev/null
  echo "b" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  "$MINIGIT" commit -m "second commit" >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"first commit"* ]]
  [[ "$output" == *"second commit"* ]]
}

@test "log: shows newest commit first" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "first commit" >/dev/null
  echo "b" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  "$MINIGIT" commit -m "second commit" >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"second commit"*"first commit"* ]]
}

# log all
@test "log all: no commits prints no history" {
  run "$MINIGIT" log all
  [[ "$output" == *"Couldn't find log history"* ]]
}

@test "log all: shows the commit message" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "first commit" >/dev/null
  run "$MINIGIT" log all
  [[ "$output" == *"first commit"* ]]
}

@test "log all: shows the branch name" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "first commit" >/dev/null
  run "$MINIGIT" log all
  [[ "$output" == *"(main)"* ]]
}

# error handling
@test "log: unknown option prints usage" {
  run "$MINIGIT" log foo
  [[ "$output" == *"Usage: minigit log"* ]]
}

@test "log: too many args prints usage" {
  run "$MINIGIT" log all extra
  [[ "$output" == *"Usage: minigit log"* ]]
}
