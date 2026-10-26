require "pg"

random = Random.new(7)
decoder = PG::TextDecoder::TimestampUtc.new
mismatches = 0
100_000.times do
  year, month, day = random.rand(1..294275), random.rand(1..12), random.rand(1..28)
  hour, min, sec, nsec = random.rand(24), random.rand(60), random.rand(60), random.rand(1_000_000_000)
  bc = random.rand(10).zero?
  text = format("%04d-%02d-%02d %02d:%02d:%02d.%09d%s", year, month, day, hour, min, sec, nsec, bc ? " BC" : "")
  expected = Time.utc(bc ? 1 - year : year, month, day, hour, min, sec + Rational(nsec, 1_000_000_000))
  mismatches += 1 unless decoder.decode(text) == expected
end
puts "100000 values with 9 fractional digits, #{mismatches} differ from Time.utc"
