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

# empty commits
@test "log: failed empty commit before any commit leaves no history" {
  "$MINIGIT" commit -m "nothing staged" >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"Couldn't find log history"* ]]
}

@test "log: failed empty commit does not show in log" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "real commit" >/dev/null
  "$MINIGIT" commit -m "nothing staged" >/dev/null
  run "$MINIGIT" log
  [[ "$output" != *"nothing staged"* ]]
}

@test "log: empty message shows no message" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "" >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"(no message)"* ]]
}

@test "log: commit with only an empty directory shows in log" {
  mkdir -p emptydir
  "$MINIGIT" add . >/dev/null
  "$MINIGIT" commit -m "empty dir" >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"empty dir"* ]]
}

# weird commits
@test "log: special characters in message preserved" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m 'star * pipe | "quotes" $HOME' >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *'star * pipe | "quotes" $HOME'* ]]
}

@test "log: unicode in message preserved" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "héllo ünïcode" >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"héllo ünïcode"* ]]
}

@test "log: same message twice shows twice" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "same" >/dev/null
  echo "b" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  "$MINIGIT" commit -m "same" >/dev/null
  run "$MINIGIT" log
  [ "$(echo "$output" | grep -c "same")" -eq 2 ]
}

@test "log: many commits all show" {
  for i in 1 2 3 4 5; do
    echo "$i" >"f$i.txt"
    "$MINIGIT" add "f$i.txt" >/dev/null
    "$MINIGIT" commit -m "commit $i" >/dev/null
  done
  run "$MINIGIT" log
  [ "$(echo "$output" | grep -c "\* commit")" -eq 5 ]
}

@test "log: multi-line message keeps every line" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m $'line1\nAuthor: fake' >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"Author: fake"* ]]
}

# log with branches
@test "log: new branch inherits parent history" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "m1" >/dev/null
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"m1"* ]]
}

@test "log: main does not show dev commits" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "m1" >/dev/null
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  echo "d" >d.txt
  "$MINIGIT" add d.txt >/dev/null
  "$MINIGIT" commit -m "d1" >/dev/null
  echo y | "$MINIGIT" branch switch main >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"m1"* ]]
  [[ "$output" != *"d1"* ]]
}

@test "log: dev does not show later main commits" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "m1" >/dev/null
  "$MINIGIT" branch new dev >/dev/null
  echo "b" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  "$MINIGIT" commit -m "m2" >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"m1"* ]]
  [[ "$output" != *"m2"* ]]
}

@test "log: follows the current branch after switching" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "m1" >/dev/null
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  echo "d" >d.txt
  "$MINIGIT" add d.txt >/dev/null
  "$MINIGIT" commit -m "d1" >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"d1"* ]]
  echo y | "$MINIGIT" branch switch main >/dev/null
  run "$MINIGIT" log
  [[ "$output" != *"d1"* ]]
}

@test "log: branch history newest first" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "m1" >/dev/null
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  echo "d" >d.txt
  "$MINIGIT" add d.txt >/dev/null
  "$MINIGIT" commit -m "d1" >/dev/null
  run "$MINIGIT" log
  [[ "$output" == *"d1"*"m1"* ]]
}

@test "log all: shows commits from every branch" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "m1" >/dev/null
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  echo "d" >d.txt
  "$MINIGIT" add d.txt >/dev/null
  "$MINIGIT" commit -m "d1" >/dev/null
  run "$MINIGIT" log all
  [[ "$output" == *"m1"* ]]
  [[ "$output" == *"d1"* ]]
}

@test "log all: tags each commit with its branch" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "m1" >/dev/null
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  echo "d" >d.txt
  "$MINIGIT" add d.txt >/dev/null
  "$MINIGIT" commit -m "d1" >/dev/null
  run "$MINIGIT" log all
  [[ "$output" == *"(dev)"*"d1"* ]]
  [[ "$output" == *"(main)"*"m1"* ]]
}

@test "log all: newest first across branches" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "m1" >/dev/null
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  echo "d" >d.txt
  "$MINIGIT" add d.txt >/dev/null
  "$MINIGIT" commit -m "d1" >/dev/null
  echo y | "$MINIGIT" branch switch main >/dev/null
  echo "b" >b.txt
  "$MINIGIT" add b.txt >/dev/null
  "$MINIGIT" commit -m "m2" >/dev/null
  run "$MINIGIT" log all
  [[ "$output" == *"m2"*"d1"*"m1"* ]]
}

@test "log all: deleted branch commits still show" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "m1" >/dev/null
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  echo "d" >d.txt
  "$MINIGIT" add d.txt >/dev/null
  "$MINIGIT" commit -m "d1" >/dev/null
  echo y | "$MINIGIT" branch switch main >/dev/null
  "$MINIGIT" branch delete dev >/dev/null
  run "$MINIGIT" log all
  [[ "$output" == *"d1"* ]]
}

@test "log: recreated branch does not show old branch commits" {
  echo "a" >a.txt
  "$MINIGIT" add a.txt >/dev/null
  "$MINIGIT" commit -m "m1" >/dev/null
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  echo "d" >d.txt
  "$MINIGIT" add d.txt >/dev/null
  "$MINIGIT" commit -m "old dev" >/dev/null
  echo y | "$MINIGIT" branch switch main >/dev/null
  "$MINIGIT" branch delete dev >/dev/null
  "$MINIGIT" branch new dev >/dev/null
  echo y | "$MINIGIT" branch switch dev >/dev/null
  run "$MINIGIT" log
  [[ "$output" != *"old dev"* ]]
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
