set -e
ruby -v
git -C patched log --oneline -1

echo "== Compile both from source with the same flags"
for dir in baseline patched; do
  mkdir -p $dir/build $dir/lib/4.0
  (cd $dir/build && ruby ../ext/extconf.rb > /dev/null && make -j4 > /dev/null && cp pg_ext.$(ruby -e "print RbConfig::CONFIG[%q(DLEXT)]") ../lib/4.0/)
  echo "$dir: $(grep -c HAVE_TIMEGM $dir/build/extconf.h || true) HAVE_TIMEGM in extconf.h"
done

echo "== Bench (alternating, 3 rounds)"
for round in 1 2 3; do
  for dir in baseline patched; do echo "-- $dir"; ruby -I $dir/lib bench/decoder_bench.rb; done
done

echo "== Equivalence"
if [ "$OS" = "Windows_NT" ]; then zones="default"; else zones="UTC Europe/Paris America/New_York"; fi
for zone in $zones; do
  for dir in baseline patched; do
    if [ "$zone" = "default" ]; then ruby -I $dir/lib bench/equivalence.rb $dir.txt; else TZ=$zone ruby -I $dir/lib bench/equivalence.rb $dir.txt; fi
  done
  echo "TZ=$zone: $(wc -l < baseline.txt) values, $(diff baseline.txt patched.txt | grep -c '^<' || true) differ"
done

echo "== Nanoseconds against Time.utc"
ruby -I patched/lib bench/nanoseconds.rb
