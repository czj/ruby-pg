require "pg"
puts "pg_ext: #{$LOADED_FEATURES.grep(/pg_ext/).join(", ")}"
inputs = Array.new(10_000) { |i| format("2025-%02d-%02d %02d:%02d:%02d.%06d", 1 + i % 12, 1 + i % 28, i % 24, i % 60, i % 60, i * 37 % 1_000_000) }
{ "timestamp (TimestampUtc)" => [PG::TextDecoder::TimestampUtc.new, inputs],
  "timestamptz" => [PG::TextDecoder::TimestampWithTimeZone.new, inputs.map { "#{it}+02" }] }.each do |name, (decoder, values)|
  values.each { decoder.decode(it) }
  timings = Array.new(7) do
    t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    values.each { decoder.decode(it) }
    (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t) / values.size * 1e9
  end
  GC.start; before = GC.stat(:total_allocated_objects); values.each { decoder.decode(it) }
  printf "%-26s médiane %7.1f ns/valeur, %.1f objets/valeur\n", name, timings.sort[3], (GC.stat(:total_allocated_objects) - before).to_f / values.size
end
