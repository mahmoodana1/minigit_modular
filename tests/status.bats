#!/bin/bash

MINIGIT="$BATS_TEST_DIRNAME/../build/minigit"

setup() {
    cd /tmp
    rm -rf minigit-tests && mkdir minigit-tests && cd minigit-tests
    "$MINIGIT" init >/dev/null
    export TERM=dumb
}

commit_base() {
    echo "base" >base.txt
    "$MINIGIT" add base.txt >/dev/null
    "$MINIGIT" commit -m "base" >/dev/null
}

# before any commit
@test "status: no commits asks for a commit first" {
    run "$MINIGIT" status
    [[ "$output" == *"Please make a commit before checking the status"* ]]
}

# file states
@test "status: committed file shows clean" {
    commit_base
    run "$MINIGIT" status
    echo "$output" | grep "base.txt" | grep -q "clean"
}

@test "status: new file shows untracked" {
    commit_base
    echo "new" >new.txt
    run "$MINIGIT" status
    echo "$output" | grep "new.txt" | grep -q "untracked"
}

@test "status: new file added shows new file staged" {
    commit_base
    echo "new" >new.txt
    "$MINIGIT" add new.txt >/dev/null
    run "$MINIGIT" status
    echo "$output" | grep "new.txt" | grep -q "new file staged"
}

@test "status: committed file changed shows modified" {
    commit_base
    echo "changed" >base.txt
    run "$MINIGIT" status
    echo "$output" | grep "base.txt" | grep -q "modified"
}

@test "status: committed file changed and added shows staged" {
    commit_base
    echo "changed" >base.txt
    "$MINIGIT" add base.txt >/dev/null
    run "$MINIGIT" status
    echo "$output" | grep "base.txt" | grep -q "staged"
}

@test "status: committed file deleted shows deleted" {
    commit_base
    rm base.txt
    run "$MINIGIT" status
    echo "$output" | grep "base.txt" | grep -q "deleted"
}

@test "status: nested file shows with its path" {
    commit_base
    mkdir -p sub
    echo "x" >sub/nested.txt
    run "$MINIGIT" status
    echo "$output" | grep "sub/nested.txt" | grep -q "untracked"
}

# deeper file states
@test "status: file removed before a commit is no longer listed" {
    commit_base
    echo "x" >x.txt
    "$MINIGIT" add x.txt >/dev/null
    "$MINIGIT" commit -m "x" >/dev/null
    rm x.txt
    echo "y" >y.txt
    "$MINIGIT" add y.txt >/dev/null
    "$MINIGIT" commit -m "y" >/dev/null
    run "$MINIGIT" status
    [[ "$output" != *"x.txt"* ]]
}

@test "status: modified file is clean again after commit" {
    commit_base
    echo "changed" >base.txt
    "$MINIGIT" add base.txt >/dev/null
    "$MINIGIT" commit -m "change" >/dev/null
    run "$MINIGIT" status
    echo "$output" | grep "base.txt" | grep -q "clean"
}

@test "status: deleted committed directory shows deleted" {
    mkdir -p sub
    echo "a" >sub/a.txt
    "$MINIGIT" add . >/dev/null
    "$MINIGIT" commit -m "sub" >/dev/null
    rm -rf sub
    run "$MINIGIT" status
    echo "$output" | grep "sub/a.txt" | grep -q "deleted"
}

@test "status: dev-only file is clean on dev" {
    commit_base
    "$MINIGIT" branch new dev >/dev/null
    echo y | "$MINIGIT" branch switch dev >/dev/null
    echo "d" >dev.txt
    "$MINIGIT" add dev.txt >/dev/null
    "$MINIGIT" commit -m "dev" >/dev/null
    run "$MINIGIT" status
    echo "$output" | grep "dev.txt" | grep -q "clean"
}

@test "status: dev-only file not listed on main" {
    commit_base
    "$MINIGIT" branch new dev >/dev/null
    echo y | "$MINIGIT" branch switch dev >/dev/null
    echo "d" >dev.txt
    "$MINIGIT" add dev.txt >/dev/null
    "$MINIGIT" commit -m "dev" >/dev/null
    echo y | "$MINIGIT" branch switch main >/dev/null
    run "$MINIGIT" status
    [[ "$output" != *"dev.txt"* ]]
}

# status after branch failures
@test "status: committed file stays clean after deleting another branch" {
    commit_base
    "$MINIGIT" branch new dev >/dev/null
    "$MINIGIT" branch delete dev >/dev/null
    run "$MINIGIT" status
    echo "$output" | grep "base.txt" | grep -q "clean"
}

@test "status: committed file stays clean after cancelled switch" {
    commit_base
    "$MINIGIT" branch new dev >/dev/null
    echo "m" >main2.txt
    "$MINIGIT" add main2.txt >/dev/null
    "$MINIGIT" commit -m "m2" >/dev/null
    echo n | "$MINIGIT" branch switch dev >/dev/null
    run "$MINIGIT" status
    echo "$output" | grep "main2.txt" | grep -q "clean"
}

@test "status: staged file still shows after switch round trip" {
    commit_base
    "$MINIGIT" branch new dev >/dev/null
    echo "s" >s.txt
    "$MINIGIT" add s.txt >/dev/null
    echo y | "$MINIGIT" branch switch dev >/dev/null
    echo y | "$MINIGIT" branch switch main >/dev/null
    run "$MINIGIT" status
    echo "$output" | grep "s.txt" | grep -q "new file staged"
}

@test "status: untracked file still shows after switch round trip" {
    commit_base
    "$MINIGIT" branch new dev >/dev/null
    echo "u" >u.txt
    echo y | "$MINIGIT" branch switch dev >/dev/null
    echo y | "$MINIGIT" branch switch main >/dev/null
    run "$MINIGIT" status
    echo "$output" | grep "u.txt" | grep -q "untracked"
}

@test "status: still works after failed branch with slash" {
    commit_base
    "$MINIGIT" branch new feature/login >/dev/null 2>&1 || true
    run "$MINIGIT" status
    echo "$output" | grep "base.txt" | grep -q "clean"
}

@test "status: failed branch new before any commit still asks for a commit" {
    "$MINIGIT" branch new dev >/dev/null 2>&1 || true
    run "$MINIGIT" status
    [[ "$output" == *"Please make a commit before checking the status"* ]]
}

@test "status: shows mixed states in one run" {
    commit_base
    echo "c" >clean.txt
    "$MINIGIT" add clean.txt >/dev/null
    "$MINIGIT" commit -m "clean" >/dev/null
    echo "changed" >base.txt
    echo "u" >u.txt
    run "$MINIGIT" status
    echo "$output" | grep "clean.txt" | grep -q "clean"
    echo "$output" | grep "base.txt" | grep -q "modified"
    echo "$output" | grep "u.txt" | grep -q "untracked"
}

@test "status: modified then reverted file shows clean" {
    commit_base
    echo "changed" >base.txt
    echo "base" >base.txt
    run "$MINIGIT" status
    echo "$output" | grep "base.txt" | grep -q "clean"
}

@test "status: filename with spaces shows" {
    commit_base
    echo "s" >"my file.txt"
    run "$MINIGIT" status
    echo "$output" | grep "my file.txt" | grep -q "untracked"
}

@test "status: running status does not change the index" {
    commit_base
    echo "new" >new.txt
    "$MINIGIT" add new.txt >/dev/null
    "$MINIGIT" status >/dev/null
    [ "$(ls .minigit/index)" = "new.txt" ]
}

# output
@test "status: prints table header" {
    commit_base
    run "$MINIGIT" status
    [[ "$output" == *"File Path"* ]]
    [[ "$output" == *"Status"* ]]
}

@test "status: does not list .minigit files" {
    commit_base
    run "$MINIGIT" status
    [[ "$output" != *".minigit"* ]]
}

# error handling
@test "status: extra args prints usage" {
    commit_base
    run "$MINIGIT" status foo
    [[ "$output" == *"Usage: minigit status"* ]]
}
