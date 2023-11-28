$logger = Logger.new(File.join('/tmp', 'leihs-script.log'))
$logger.level = Logger::INFO

def log(message = '', log_level = 'info', stdout = false)
  $logger.send(log_level, message)
  puts message if stdout == true
end
