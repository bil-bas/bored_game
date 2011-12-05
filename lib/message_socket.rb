# =============================================================================
# Bored Game
#
# By Bil Bas
#
# =============================================================================

require 'socket'

# =============================================================================
# Masks the regular TCP Socket so that we can pass Messages between clients
# via the server.
#
class TCPSocket
  MAX_MSG_LEN = 0xffff # No messages over 65k!

  # ------------------------
  #
  #
  public
  def readMsg
    # Get length of incoming message in 'header'.
    header = sysread 2

    len = ((header[0] << 8) + header[1]) # Extract as 16-bit integer

    if len > MAX_MSG_LEN
      raise MessageException, "Attempted to read #{message.length} byte message!"
    end

    # Read message itself and decode it to a Message object.
    data = sysread len

#     $stdout.puts "Reading: #{len} #{data.inspect}"
    message = Marshal.load(data)
  
    if message.kind_of? BasicMsg
      return message
    else
      raise MessageException, "Not a message."
    end
  end

  # ------------------------
  #
  #
  public
  def writeMsg(message)
    # Encode the Message object, and send it and its length.
    data = Marshal.dump(message)

    if data.length > MAX_MSG_LEN
      raise MessageException, "Attempted to write #{message.length} byte message!"
    end

    # Place length of message in 'header'
    header = ((data.length >> 8) & 0xff).chr + (data.length & 0xff).chr
#     $stdout.puts "Writing: #{len} #{data.inspect}"
#    p "bytes sent #{write header + data} out of #{(header + data).length}"
    syswrite header + data

    return message
  end
end

# =============================================================================
class MessageException < Exception
end