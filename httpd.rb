require 'socket'

server = TCPServer.open 8081
puts "Listening on port 8081"

client = server.accept()

while line = client.gets
    break if line =~ /^\s*$/
end

resp = File.read('ks.cfg')
headers = ["HTTP/1.1 200 OK",
           "Content-Type: text/plain",
           "Content-Length: #{resp.length}\r\n\r\n"].join("\r\n")
client.puts headers
client.puts resp
client.close
