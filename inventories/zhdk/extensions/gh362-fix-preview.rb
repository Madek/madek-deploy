mf = MediaFile.find('be629ecc-974f-430f-b347-e7c506d100d3')

puts "old previews:"
puts mf.previews.to_json

puts "recreating previews:"
mf.create_previews!

puts "OK"