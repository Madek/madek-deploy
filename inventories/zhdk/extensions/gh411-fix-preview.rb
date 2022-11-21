mf = MediaFile.find('ea343d6f-87af-4a1c-aa40-f6614234c3ce')

puts "old previews:"
puts mf.previews.to_json

puts "recreating previews:"
mf.create_previews!

puts "OK"