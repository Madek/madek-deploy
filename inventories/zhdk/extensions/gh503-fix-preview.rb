mf = MediaFile.find('6e7124d2-7f20-4933-a964-1fecdb0dbcb3')

puts "old previews:"
puts mf.previews.to_json

puts "recreating previews:"
mf.create_previews!

puts "OK"
