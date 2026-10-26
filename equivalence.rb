require "pg"

random = Random.new(42)
days_in_month = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
offsets = ["", "+05", "-03", "+05:30", "-09:30", "+00:19:32", "-11:11:11", "+14", "-12"]

texts = Array.new(200_000) do
  year = case random.rand(4)
         when 0, 1 then random.rand(1900..2100)
         when 2 then random.rand(1..9999)
         else random.rand(1..294275)
         end
  month = random.rand(1..12)
  day = random.rand(1..days_in_month[month - 1])
  day = 28 if month == 2 && day == 29 && !(year % 4 == 0 && (year % 100 != 0 || year % 400 == 0))
  fraction = (digits = random.rand(0..6)).zero? ? "" : ".#{random.rand(10**digits).to_s.rjust(digits, "0")}"
  text = format("%04d-%02d-%02d %02d:%02d:%02d%s%s", year, month, day, random.rand(24), random.rand(60), random.rand(60), fraction, offsets.sample(random: random))
  text << " BC" if random.rand(10).zero? && year <= 4713 && !(month == 2 && day == 29)
  text
end

decoders = PG::TextDecoder.constants.grep(/Timestamp/).map { PG::TextDecoder.const_get(it) }.uniq.sort_by(&:name).map(&:new)
File.open(ARGV.fetch(0), "w") do |file|
  decoders.each do |decoder|
    texts.each do |text|
      time = decoder.decode(text)
      file.puts(time.is_a?(Time) ? "#{decoder.class} #{text} #{time.to_r} #{time.utc_offset} #{time.utc?}" : "#{decoder.class} #{text} #{time.inspect}")
    end
  end
end
