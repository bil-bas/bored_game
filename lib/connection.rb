# =============================================================================
# Bored Game
#
# By Bil Bas
# =============================================================================

require 'message_socket'
require 'messages'
require 'thread'

# =============================================================================
# 
#
class Connection
  PORT = 6061

  # ------------------------
  #
  #
  public
  def initialize(master)
    @master = master

    @sock = nil
    @connected = nil

    @messageQueue = []
    @queueMutex = Mutex.new
  end


  # ------------------------
  #
  #
  public
  def connect(host)
    @sock.close if @sock && !@sock.closed?

    @master.puts "Connecting to server at #{host}:#{PORT}."

    begin
      @sock = TCPSocket.new(host, PORT)
#       @master.app.addInput @sock, INPUT_READ|INPUT_WRITE|INPUT_EXCEPT, method(:sockActivity)

      send LoginMsg.new(@master.player.name)
      @connected = true
      receiveSocket
    rescue Exception => ex
      @master.puts "Connection to #{host}:#{PORT} failed."
    end
  end

  # ------------------------
  #
  #
  private
  def receiveSocket
    Thread.new do
      begin
        loop do
          # Queues up messages until they can be handled by client
          message = @sock.readMsg
          @queueMutex.synchronize {
            @messageQueue.push message
            # @master.puts "ConnRec: #{message.inspect}" # DEBUG
          }
        end

      rescue MessageException
        @master.puts "Error: Bad data received!"
      rescue IOError => ex
        @sock.close unless (@sock.nil? || @sock.closed?)
        @master.puts "Error: Failure while reading socket.#{ex.inspect}"
        break
      end
    end
  end

#   # ------------------------
#   #
#   #
#   def sockActivity(sender, sel, data)
#     case SELTYPE(sel)
#       when SEL_IO_READ
#         begin
# p "READ"
#           @master.processMsg @sock.readMsg
# p "finished read"
#         rescue MessageException
#           @master.puts "Error: Bad data received & ignored!"
#         rescue IOError => ex
#           @sock.close unless (@sock.nil? || @sock.closed?)
#           @master.puts "Error: Failure while reading socket. #{ex.inspect}"
#         rescue Exception => ex
#           p "Unknown error #{ex.inspect}"
#         end

#         return 0

#       when SEL_IO_EXCEPT
#         p ["EXCEPT", sender, sel, data]
#         @master.puts "Exception in socket!!"
#         return 0

#       when SEL_IO_WRITE
# #         while c = @sock.read(1)
#            p "WRITING"
# #         end
#         return 0
#     end
#   end

  # ------------------------
  #
  #
  public
  def send(message)
# p "sending #{message.inspect}"
    begin
      @sock.writeMsg message
    rescue MessageException => ex
      @master.puts ex
    rescue Exception # If @sock is already closed.
      @master.puts "Error: No connection open to accept data."
      @connected = false
    end
# p "sent"
  end

  # ------------------------
  # 
  #
  public
  def connected?
    @connected
  end

  # ------------------------
  #
  #
  public
  def nextMessage
    # Pull off the first message (if there is one)
    if @queueMutex.try_lock
      message = @messageQueue.shift
      @queueMutex.unlock
    else
      message = nil
    end

    return message
  end

end
