#!/bin/bash

PASS=0
FAIL=0

cleanup() {
  rm -rf tmp_out_wc tmp_out_grep tmp_out_conc1 tmp_out_conc2
  rm -f /tmp/tmp_mr_out.txt /tmp/tmp_mr_truth.txt /tmp/tmp_mr_conc1.txt /tmp/tmp_mr_conc2.txt
}

run_test() {
  local name=$1
  local app=$2
  local outdir=$3
  local n=$4
  local args=$5
  shift 5
  local files=$@

  echo "=============================="
  echo "TEST: $name"
  echo "=============================="

  rm -rf $outdir

  if [ -n "$args" ]; then
    ./bin/mr-client submit -a $app -o $outdir -w -n $n -x "$args" $files
  else
    ./bin/mr-client submit -a $app -o $outdir -w -n $n $files
  fi

  ./bin/mr-client process -a $app -o $outdir -n $n | sort > /tmp/tmp_mr_out.txt

  if [ "$app" == "wc" ]; then
    cat $files | tr -s '[:space:]' '\n' | sort | uniq -c | awk '{print $1"\t"$2}' | sort > /tmp/tmp_mr_truth.txt
  elif [ "$app" == "grep" ]; then
    grep "$args" $files | awk -F: '{print $2}' | sort > /tmp/tmp_mr_truth.txt
  fi

  if diff -q /tmp/tmp_mr_out.txt /tmp/tmp_mr_truth.txt > /dev/null 2>&1; then
    echo "PASS: $name"
    PASS=$((PASS+1))
  else
    echo "FAIL: $name"
    diff /tmp/tmp_mr_out.txt /tmp/tmp_mr_truth.txt | head -20
    FAIL=$((FAIL+1))
  fi
  echo ""
}

# Test 1: word count
run_test "wc_basic" wc tmp_out_wc 10 "" data/gutenberg/*

# Test 2: grep
run_test "grep_basic" grep tmp_out_grep 10 "the" data/gutenberg/*

# Test 3: concurrent jobs
echo "=============================="
echo "TEST: concurrent_wc"
echo "=============================="
rm -rf tmp_out_conc1 tmp_out_conc2
./bin/mr-client submit -a wc -o tmp_out_conc1 -w -n 5 data/gutenberg/* &
./bin/mr-client submit -a wc -o tmp_out_conc2 -w -n 5 data/gutenberg/* &
wait

./bin/mr-client process -a wc -o tmp_out_conc1 -n 5 | sort > /tmp/tmp_mr_conc1.txt
./bin/mr-client process -a wc -o tmp_out_conc2 -n 5 | sort > /tmp/tmp_mr_conc2.txt
cat data/gutenberg/* | tr -s '[:space:]' '\n' | sort | uniq -c | awk '{print $1"\t"$2}' | sort > /tmp/tmp_mr_truth.txt

if diff -q /tmp/tmp_mr_conc1.txt /tmp/tmp_mr_truth.txt > /dev/null 2>&1 && \
   diff -q /tmp/tmp_mr_conc2.txt /tmp/tmp_mr_truth.txt > /dev/null 2>&1; then
  echo "PASS: concurrent_wc"
  PASS=$((PASS+1))
else
  echo "FAIL: concurrent_wc"
  FAIL=$((FAIL+1))
fi

echo ""
echo "=============================="
echo "RESULTS: $PASS passed, $FAIL failed"
echo "=============================="

cleanup