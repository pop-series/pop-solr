#!/bin/bash


init() {
    VALIDATION_FAILURES=0
    TOP_LEVEL_DIR="$(git rev-parse --show-toplevel)"
    GRADLE_CMD="$TOP_LEVEL_DIR/gradlew"
}

validate() {
    ($GRADLE_CMD --project-dir $TOP_LEVEL_DIR check) || VALIDATION_FAILURES="$((VALIDATION_FAILURES+1))"
}


echo "executing pre-push checks"
init
validate
echo -e "\nTotal [$VALIDATION_FAILURES] validation failures were observed"
if [[ "$VALIDATION_FAILURES" -ne "0" ]]; then
  echo -e "❌ please rectify failures before proceeding ahead\n"
  exit 1
fi
echo -e "✅ all pre-push validations passed\n"
exit 0
