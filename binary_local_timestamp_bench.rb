require "pg"
puts "#{RUBY_DESCRIPTION}, pg #{PG::VERSION} (#{$LOADED_FEATURES.grep(/pg_ext/).first}), TZ=#{ENV["TZ"]}"
values = Array.new(10_000) { |i| [((Time.utc(2024, 1, 1) + i * 3137 - Time.utc(2000)) * 1_000_000).round].pack("q>") }
{ "TimestampLocal" => PG::BinaryDecoder::TimestampLocal.new, "DB_LOCAL alone" => PG::BinaryDecoder::Timestamp.new(flags: PG::Coder::TIMESTAMP_DB_LOCAL), "TimestampUtc" => PG::BinaryDecoder::TimestampUtc.new }.each do |name, decoder|
  values.each { decoder.decode(it) }
  timings = Array.new(7) { t = Process.clock_gettime(Process::CLOCK_MONOTONIC); values.each { decoder.decode(it) }; (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t) / values.size * 1e9 }
  GC.start; b = GC.stat(:total_allocated_objects); values.each { decoder.decode(it) }
  printf "%-15s %6.0f ns per value (median of 7), %.1f objects\n", name, timings.sort[3], (GC.stat(:total_allocated_objects) - b).to_f / values.size
end
