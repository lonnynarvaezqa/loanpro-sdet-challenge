#!/bin/bash


IMAGE="public.ecr.aws/l4q9w4c5/loanpro-calculator-cli:latest"
FAIL=0


run_test () {
desc=$1
cmd=$2
expected=$3
reason=$4


output=$(docker run --rm $IMAGE $cmd 2>&1)


if [[ "$output" == *"$expected"* ]]; then
echo "✅ $desc"
else
echo "❌ $desc"
echo " Why this matters: $reason"
echo " Expected to contain: $expected"
echo " Actual output: $output"
FAIL=1
fi
}


echo "Running LoanPro Calculator CLI tests"
echo "------------------------------------"


run_test "Add integers" "add 2 3" "5" "Basic functionality should work for valid integer inputs"
run_test "Subtract integers" "subtract 5 3" "2" "Subtraction should return the correct result"
run_test "Multiply integers" "multiply 4 5" "20" "Multiplication is a core supported operation"
run_test "Divide integers" "divide 10 2" "5" "Division with valid inputs should succeed"


run_test "Multiply large numbers (precision risk)" "multiply 9999999999999999 2" "19999999999999998" "Large numbers can introduce silent precision errors"


run_test "Invalid numeric format (--5)" "add --5 3" "15" "Ambiguous numeric formats should be rejected clearly"
run_test "Invalid numeric format (+-5)" "add +-5 3" "-15" "Ambiguous numeric formats should be rejected clearly"


run_test "Scientific notation" "add 1e2 5" "105" "Scientific notation is commonly accepted by numeric parsers"
run_test "Negative numbers" "subtract -5 -3" "-2" "Operations with negative numbers should behave consistently"
run_test "Division by zero" "divide 1 0" "Error" "Division by zero should fail with a clear error message"


echo "------------------------------------"


if [ $FAIL -eq 0 ]; then
echo "All tests completed successfully"
else
echo "Some tests failed. Review messages above for details"
fi


exit $FAIL