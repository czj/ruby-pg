# Compares PG::BinaryDecoder::TimestampLocal (and TIMESTAMP_DB_LOCAL alone) with
# PostgreSQL's `wall_clock::timestamp AT TIME ZONE zone`, every quarter hour of
# whole years, in several zones.
#
#   DATABASE_URL=postgres://... TZ=Europe/Paris ruby -I lib binary_local_timestamp_vs_postgresql.rb 1950 2024 2038 2100
require "pg"

zone = ENV.fetch("TZ")
years = ARGV.map(&:to_i)
connection = PG.connect(ENV.fetch("DATABASE_URL"))
encoder = PG::BinaryEncoder::TimestampUtc.new
local = PG::BinaryDecoder::TimestampLocal.new
db_local_only = PG::BinaryDecoder::Timestamp.new(flags: PG::Coder::TIMESTAMP_DB_LOCAL)

counts = Hash.new(0)
mismatches = []
years.each do |year|
  rows = connection.exec_params(<<~SQL, [zone, "#{year}-01-01", "#{year + 1}-01-01"]).values
    SELECT extract(epoch FROM wall_clock)::bigint, extract(epoch FROM wall_clock AT TIME ZONE $1)::bigint
    FROM generate_series($2::timestamp, $3::timestamp - interval '15 minutes', interval '15 minutes') AS wall_clock
  SQL
  rows.each do |wall_clock, expected|
    wire = encoder.encode(Time.at(wall_clock.to_i, in: "UTC"))
    decoded = local.decode(wire)
    counts[:values] += 1
    counts[:db_local_only_mismatches] += 1 unless db_local_only.decode(wire).then { it.to_i == expected.to_i && it.utc? }
    next if decoded.to_i == expected.to_i && decoded.utc_offset == Time.at(expected.to_i).utc_offset

    counts[:mismatches] += 1
    mismatches << [Time.at(wall_clock.to_i, in: "UTC").strftime("%F %R"), decoded, Time.at(expected.to_i).localtime] if mismatches.size < 5
  end
end
puts "#{zone.ljust(20)} #{PG::VERSION} #{years.join(",")}: #{counts[:values]} values, TimestampLocal #{counts[:mismatches]} mismatches, DB_LOCAL alone #{counts[:db_local_only_mismatches]}"
mismatches.each { puts "  #{it[0]} decoded=#{it[1]} postgresql=#{it[2]}" }
