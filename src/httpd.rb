require 'socket'
require 'time'

def serve_kickstart_file(kickstart_filename)
    # Loop and serve the specified kickstart file until Anaconda
    # specifically requests it (so you can test it's working
    # elsewhere if needs be).

    recv_chunk = 256
    max_recv = 1024

    simple_http_server = setup_http_server()
    puts(simple_http_server.local_address.ip_port)

    anaconda = false
    loop do
        http_client = simple_http_server.accept()

        begin
            req = ""
            while buf = http_client.recv(recv_chunk)
                req = req + buf

                if req.end_with? "\r\n\r\n"
                    # Received end of request

                    anaconda = anaconda_asking?(req)
                    resp, headers = construct_file_send(kickstart_filename)
                    break
                end

                if req.length() > max_recv
                    # Don't receive forever

                    resp, headers = construct_413()
                    break
                end
            end

            http_client.puts(headers.join("\r\n") + "\r\n\r\n")
            http_client.puts(resp)
        rescue
            # Something went wrong. Try and recover...

            resp, headers = construct_500()

            http_client.puts(headers.join("\r\n") + "\r\n\r\n")
            http_client.puts(resp)
        ensure
            http_client.close()
        end

        break if anaconda
    end
end

def anaconda_asking?(headers="")
    headers.lines.map(&:chomp).each do |line|
        return true if line =~ /^User-Agent: .*anaconda.*/
    end

    return false
end

def setup_http_server
    begin
        tcp_server = TCPServer.new(0)
    rescue
        puts("Unable to find a port to listen to.")
        exit(2)
    end

    return tcp_server
end

def construct_500
    resp = "Server error."
    headers = ["HTTP/1.1 500 Server error",
                "Date: #{Time.now().rfc2822()}",
                "Content-Type: text/plain",
                "Content-Length: #{resp.length()}"]

    return resp, headers
end

def construct_413
    resp = "The request is too large."
    headers = ["HTTP/1.1 413 Request Entity Too Large",
               "Date: #{Time.now().rfc2822()}",
               "Content-Type: text/plain",
               "Content-Length: #{resp.length()}",
               "Connection: close"]

    return resp, headers
end

def construct_file_send(kickstart_filename)
    resp = File.read(kickstart_filename)
    headers = ["HTTP/1.1 200 OK",
               "Date: #{Time.now().rfc2822()}",
               "Content-Type: text/plain",
               "Content-Length: #{resp.length()}"]

    return resp, headers
end

if __FILE__ == $0
    kickstart_filename = ARGV[0]

    if kickstart_filename && File.file?(kickstart_filename)
        serve_kickstart_file(kickstart_filename)
    else
        puts("Cannot find kickstart file.")
        exit(1)
    end
end
