mf = MediaEntry.find('eb8e685e-3095-405b-ab9b-7d85107f0925').media_file

puts "old previews:"
puts mf.previews.to_json

puts "recreating previews:"
mf.create_previews!

mf = MediaEntry.find('e51b620f-3869-411c-8fb3-efb9f33c72f4').media_file

puts "old previews:"
puts mf.previews.to_json

puts "recreating previews:"
mf.create_previews!

puts "OK"
