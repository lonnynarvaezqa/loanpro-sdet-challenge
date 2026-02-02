#!/bin/bash

IMAGE="public.ecr.aws/l4q9w4c5/loanpro-calculator-cli:latest"
FAIL=0

run_test () {
  desc=$1
  cmd=$2
  expected=$3

  output=$(docker run --rm $IMAGE $cmd 2>&1)

  if [[ "$output" == *"$expected"* ]]; then
    echo "✅ $desc"
  else
    echo "❌ $desc"
    echo "Expected to contain: $expected"
    echo "Got: $output"
    FAIL=1
  fi
}

run_test "Add integers" "add 2 3" "5"
run_test "Multiply large numbers (precision risk)" "multiply 9999999999999999 2" "20000000000000000"
run_test "Invalid numeric format" "add --5 3" "Invalid argument"

exit $FAIL

