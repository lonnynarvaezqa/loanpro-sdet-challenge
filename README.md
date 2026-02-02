# LoanPro Calculator – SDET Challenge

This repository shows how I approached a quality and testing challenge for an arithmetic calculator CLI distributed as a Docker image. I intentionally treated this exercise as I would in a real work environment, not as an academic assignment.

The goal was not to force bugs or look for artificial failures, but to understand how the product behaves in realistic scenarios, identify risks that could easily go unnoticed, and design tests that help prevent future issues.

---

## 1. Summary

After running functional tests and several edge-case scenarios:

- The system behaves correctly in most expected cases.
- **Two real issues were identified**:
  - A silent precision error when working with very large numbers.
  - Ambiguity around which numeric input formats are considered valid.
- No additional critical bugs were found without forcing unrealistic scenarios.

Based on these results, the focus shifted to understanding quality risks and adding simple automation to help catch regressions.

---

## 2. Findings

### Bug 1 – Silent overflow in multiplication

**Command**

```bash
docker run --rm public.ecr.aws/l4q9w4c5/loanpro-calculator-cli multiply 9999999999999999 2
```

**Observed result**

```
Result: 20000000000000000
```

**Expected behavior**  
An explicit error or at least a warning indicating a loss of precision.

**Impact**

- The output looks valid but is mathematically incorrect.
- This type of issue can easily go unnoticed in production.

**Severity**: High

---

### Bug 2 – Ambiguous numeric input formats

**Commands**

```bash
add --5 3
add +-5 3
```

**Observed result**

```
Error: Invalid argument. Must be a numeric value.
```

**Analysis**  
The system correctly rejects these values, but it does not clearly document which numeric formats are supported. This can lead to confusion for users or automated integrations.

**Severity**: Medium

---

## 3. Risks and improvement areas

These points are not current bugs, but they represent real quality risks:

- The output format (`Result: X`) is not defined as a stable contract.
- There is no machine-readable output option.
- Exit codes are not documented.

---

## 4. Explored test cases (including non-bug scenarios)

In addition to the issues found, multiple scenarios were tested to better understand the system’s overall behavior and ensure there were no hidden failures. While many of these cases did not reveal bugs, they help increase confidence in the product and document what was evaluated.

Examples of explored tests include:

- Basic arithmetic operations (add, subtract, multiply, divide)
- Negative numbers
- Mixed integers and decimals
- Very small and very large values
- Invalid inputs (strings, ambiguous formats)
- Known scenarios described in the challenge (to confirm expected behavior)

Below is the full test matrix of executed cases.

| ID    | Category    | Case                        | Result              |
|-------|-------------|-----------------------------|---------------------|
| TC-01 | Functional  | add 2 3                     | OK                  |
| TC-02 | Functional  | subtract 5 3                | OK                  |
| TC-03 | Functional  | multiply 4 5                | OK                  |
| TC-04 | Functional  | divide 10 2                 | OK                  |
| TC-05 | Edge        | multiply 9999999999999999 2 | FAIL                |
| TC-06 | Input       | add a b                     | OK                  |
| TC-07 | Input       | add --5 3                   | FAIL                |
| TC-08 | Input       | add +-5 3                   | FAIL                |
| TC-09 | Negative    | divide -10 -2               | OK                  |
| TC-10 | Precision   | add 0.1 0.2                 | OK                  |
| TC-11 | Exploratory | add 1e2 5                   | OK                  |
| TC-12 | Exploratory | subtract -5 -3              | OK                  |
| TC-13 | Exploratory | divide 1 0                  | OK (expected error) |

---

## 5. Automation

The goal of automation here is not only to detect current bugs, but to provide a baseline test suite that can catch regressions if the CLI behavior changes in the future.

Since the product is delivered as a Docker image and the source code is not available, automation was implemented at the CLI level using Bash, testing the system exactly as a user or CI pipeline would.

### Structure

```text
loanpro-sdet-challenge/
├── README.md
├── tests/
│   └── cli-tests.sh
```

### Test script

The automation is implemented as a simple Bash script that executes the Docker image directly, validating the CLI behavior exactly as a user or CI pipeline would.

The script includes:
- Core functional scenarios
- Edge cases and risky inputs
- Clear output explaining why each test exists and what risk it covers

You can find the full script here:

👉 **[`tests/cli-tests.sh`](tests/cli-tests.sh)**

### How to run the tests

```bash
chmod +x tests/cli-tests.sh
./tests/cli-tests.sh
---

## 6. Repository setup and commits

```bash
git init
git add README.md
git commit -m "Initial findings and quality assessment"

git add tests/cli-tests.sh
git commit -m "Add basic CLI automation tests"
```

Small, descriptive commits make the work easier to review and discuss.

---

## 7. Closing thoughts

This exercise reflects a practical testing approach:

- Real bugs were found without forcing unrealistic scenarios.
- Quality risks affecting maintainability and automation were identified.
- Simple but effective automation was implemented.

This is the type of work I would expect to complete before releasing a component to production.
