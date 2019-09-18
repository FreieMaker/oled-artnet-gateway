require 'pp'
require 'socket'

dmx_count = 512
oled_count = 1152

art_net_offset = 18

art_net_socket = UDPSocket.new
art_net_socket.bind('192.168.1.40', 6454)

wall_socket = UDPSocket.new
wall_socket.connect("192.168.1.50", 6038)


map = Array.new(oled_count) { 0 }

Kernel.loop do
  data = art_net_socket.recv(600) # Blocking - slows down the loop

  encoded_data = data.unpack('C*')
  # encoded_data[17] length
  next unless encoded_data.length > 100

  universe = encoded_data[14]
  dmx_count.times { |ix| map[ix + (dmx_count * universe)] = encoded_data[art_net_offset + ix] }

  #pp map
  pos = 0
  7.times do |row|
    payload = "0401dc4a0200080100000000ffffffff01000400f8010000"
    payload[33] = (row + 1).to_s

    count = row == 6 ? 144 : 168
    count.times do
      payload += Kernel.sprintf("%02x", map[pos])
      payload += '0000'
      pos += 1
    end

    wall_socket.send(payload.scan(/../).map { |x| x.hex.chr }.join, 0)
  end

end