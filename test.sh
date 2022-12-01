#!/usr/bin/env bash
shopt -s nullglob

lake build autograder AutograderTests

exitval=0

for cat in Pass Fail TodoPass TodoFail; do
  echo === $cat ===
  for t in AutograderTests/$cat/*.lean; do
    modname=${t//.lean/}
    modname=${modname//\//.}
    output=$(env AUTOGRADER_IN_EXERCISE=1 lake exe autograder $modname $t)

    pass=$?
    if [ $pass -eq 0 ]; then
      echo PASS $t
    else
      echo FAIL $t
    fi

    case $cat-$pass in
      Pass-1)
        echo $output
        echo '*****' $t failed, but should have passed
        exitval=1;;
      Fail-0)
        echo $output
        echo '*****' $t passed, but should have failed
        exitval=1;;
    esac
  done
  echo
done

exit $exitval
