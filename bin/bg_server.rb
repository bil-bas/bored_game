# =============================================================================
# Bored Game
#
# By Bil Bas
#
# =============================================================================

require 'thread'

$:.push '../lib' # Add library to search path.

require 'message_socket'
require 'messages'

# =============================================================================
# User Structure
#
User = Struct.new('User', :socket, :name, :address)

# =============================================================================
#
#
class BGServer

  PORT = 6061

  private
  def initialize
    @playerNum = 0 # Tally of total players that have ever connected.

    @users = { }   # Players currently connected playerNum => User
    @ids = { } # Players currently connected sock => playerId

    srand

    @mutex = Mutex.new

    Thread.abort_on_exception = true
  end

  # ------------------------
  #
  #
  public
  def start
    thread = listen(PORT)
    thread.join if thread
  end

  # ------------------------
  #
  #
  private
  def listen(port)
    # Create server
    begin
      servSock = TCPServer.new('localhost', port)
    rescue Exception => ex
      puts "TCPServer failed! #{ex}"
      return nil
    end

    puts "Waiting for a connection on port #{PORT}."

    return Thread.new do
      begin
        while sock = servSock.accept 
          addPlayer sock
        end
      rescue Exception => ex
        puts "TCPServer failed!", ex.class, ex
        servSock.close
        @ids.each_key do |sock|
          kill sock
        end
      end
    end
  end

  # ------------------------
  #
  #
  private
  def addPlayer(sock)
    Thread.new do
      begin

        loop do
          message = sock.readMsg
          # Make sure only one message is processed at a time.
          @mutex.synchronize do
            processMsg message, sock
          end
        end

      rescue IOError, NoMethodError => ex
        puts "Socket died: " + ex.inspect
      ensure
        kill sock
      end
    end
  end

  # ------------------------
  #
  #
  private
  def processMsg(message, sock)
    message.source = @ids[sock]

    if message.source.nil?
      # The user has not logged in yet.
      if message.instance_of? LoginMsg # Perform login.
        @playerNum += 1

        playList = { }
        @users.each do |key, value|
           playList[key] = value.name
        end

        sock.writeMsg LoginOkMsg.new(@playerNum, playList)
        puts "#{sock.peeraddr[2..3].inspect} #{message.name} logged in as player #{@playerNum}."

        @users[@playerNum] = User.new(sock, message.name, "0.0.0.0")
        @ids[sock] = @playerNum

        # Give it a valid source and pass it on.
        message.source = @playerNum
        broadcast message
      else
        p "Not logged in! #{message}"
      end
      return # ignore it.
    end

    case message
    when SayMsg, EmoteMsg, MoveMsg, PlaceMsg, PassMsg, NewGameMsg,
         SurrenderMsg, DiceMsg
      broadcast message

    when PingMsg
      # Bounce it back.
      if message.dest == SERVER_ADDR
        puts "Bounced ping from #{message.source}"
        message.bounced = true
        message.source, message.dest = message.dest, message.source
      else
        puts "Forwarded ping from #{message.source} to #{message.dest}"
      end

      @users[message.dest].socket.writeMsg message if @users.has_key? message.dest

    when ChangeNameMsg
      puts "#{@users[message.source].name} has changed name to #{message.name}."
      @users[message.source].name = message.name
      broadcast message

    when QuitMsg
      kill sock
      puts "Player #{message.source} quit..."
      broadcast message

    else
      # Forward the specific message!
      @users[message.dest].socket.writeMsg message if @users.has_key? message.dest

    end

  end

  # ------------------------
  #
  #
  private
  def broadcast(message)
    # Broadcast appropriate messages.
    @ids.each do |sock, num|
      begin
        if num != message.source
          sock.writeMsg message 
        end
      rescue Exception
        kill sock
      end
    end
  end

  # ------------------------
  #
  #
  private
  def kill(sock)
    
    num = @ids[sock]
    user = @users[num]

    @users.delete num
    @ids.delete sock

    begin
      sock.close
      puts "User #{user.name} disconnected."
    rescue Exception
    end

    broadcast DiedMsg.new(num)
  end
end


# =============================================================================
if __FILE__ == $0
  server = BGServer.new

  server.start
end