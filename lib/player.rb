# =============================================================================
# Bored Game
#
# By Bil Bas
#
# =============================================================================

# =============================================================================
# An abstract player who may be RemotePlayer or LocalPlayer.
#
class BasicPlayer
  attr_accessor :name, :id, :side, :pieces, :data

  # ------------------------
  #
  private
  def initialize(name, id, side)
    @name, @id = name, id
    @side = side
    @side.player = self if @side
    @pieces = Array.new
    @data = Hash.new
  end
end

# =============================================================================
# Dummy player exists until a game is started. Only there to remember name!
# 
class DummyPlayer < BasicPlayer
  # ------------------------
  #
  private
  def initialize(name)
    super name, -1, nil
  end
end

# =============================================================================
# The game is being played in hotseat mode (all around one computer).
#
class HotseatPlayer < BasicPlayer
end

# =============================================================================
# A player on another machine, playing over a network.
#
class RemotePlayer < BasicPlayer
  # ------------------------
  #
  private
  def initialize(name, id)
    super name, id, nil
  end
end

# =============================================================================
# A player running on this machine - playing a network game.
# Controls command input and holds state information.
#
class LocalPlayer < BasicPlayer
  MESSAGE_WIDTH = 80
  MESSAGE_HEIGHT = 6
  MAX_MSGS = 50 # id of messages to remember in the text area.

  attr_accessor :id

  # ------------------------
  #
  private
  def initialize(master, input, name, id)
    super name, id, nil
 
    @master, @input = master, input

    @history = History.new

    @input.connect SEL_COMMAND, method(:parse)

    @input.connect SEL_KEYPRESS, method(:onKeyPress)

    @input.enable
    @input.setFocus
  end

  # ------------------------
  # Cleanup
  #
  private
  def cleanup
    @input.disable
  end

  # ------------------------
  # Interprets up and down arrows in order to view command history.
  #
  private
  def onKeyPress(sender, sel, event)
    case event.code
      when KEY_UP
        @input.text = @history.previous
        @input.cursorPos = @input.text.length
        return 1
      
      when KEY_DOWN
        if @history.started?
          @input.text = @history.next
          @input.cursorPos = @input.text.length
        end
        return 1
      else
        return 0
    end
  end

  # ------------------------
  # puts()
  # Write line(s) of text to the output window.
  #
  public
  def puts(*args)
    @master.puts(*args)
  end

  # ------------------------
  #
  private
  def parse(sender, sel, input)
    input.strip!

    if input.length > 0
      # System commands start with a '/'
      if input =~ /^\/(.*)/
        commandLine = $1

        if commandLine.length == 0 || commandLine =~ /^\s/
          @master.puts "No '/' command used."
        else
          # Extract the command itself and the arguements.
          commandLine =~ /^(\S+)\s*(.*)/
          cmd, arg = $1, $2.chomp
  
          case cmd
            when /ping/i
              if arg.length >= 1
                to = nil
                @master.players.each_value do |player|
                  if player.name =~ /^#{arg}$/i
                    to = player.id
                    break
                  end
                end
              else
                to = SERVER_ADDR
              end
    
              if to.nil?
                puts "#{arg} not recognised as a player."
              else
                puts 'Ping.......................!'
                @master.send PingMsg.new(to)
              end
      
            when /quit/i
              @master.send QuitMsg.new
    
            when /me/i
              if arg && arg.length >= 1
                @master.puts ":#{@name} #{arg}"
                @master.send EmoteMsg.new(arg)
              else
                puts "/me requires an arguement!"
              end
  
            else
              @master.puts "Command /#{cmd} not recognised."
          end
        end
      else
        @master.puts "<#{@name}> #{input}"
        @master.send SayMsg.new(input)
      end

      @history.push input if input != @history.last

      @input.text = ''
    end
  end
end

# =============================================================================
# History
# Records history of previous (typed) messages sent by this player.
# Stores an array of text lines which can be retrieved (with 'up' and 'down').
# Also stores the *current* history line being viewed.
#
class History < Array
  MAX_HISTORY = 10   # id of lines to keep in memory.

  private
  def initialize
    super(0, '') # Default return is ''
    @index = size
  end

  # ------------------------
  # Have we started to view the history?
  public
  def started?
    @index < size
  end

  # ------------------------
  #
  public
  def push(command)
    shift if size >= MAX_HISTORY   # Remove excess
    super(command)
    @index = size # Reset to after the last item in history. 
  end

  # ------------------------
  #
  public
  def previous
    @index -= 1
    @index = [@index, 0].max
    return self[@index]
  end
 
  # ------------------------
  #
  public
  def next
    @index += 1
    @index = [@index, size - 1].min
    return self[@index]
  end
end


# =============================================================================
# OptionsDialog
#
class OptionsDialog

  private
  def initialize(master, name)

#     dialog = TkToplevel.new { title 'Options'}
#    
#     first = TkFrame.new(dialog) { pack }
#     second = TkFrame.new(dialog) { pack }
#     # Name
#     entryLabel = TkLabel.new(first) {
#       text 'Name'; pack('side' => 'left')
#     }

#     name = TkVariable.new(name)
#     entry = TkEntry.new(first, 'textvariable' => name) {
#       pack('side' => 'right', 'padx' => '5', 'pady' => '5')
#     }
    
#     # Does the User require separate game windows?
#     TkLabel.new(second) {
#       text 'Separate Game Window'; pack('side' => 'left')
#     }

#     sep = TkVariable.new()
#     entry = TkEntry.new(second, 'textvariable' => sep) {
#       pack('side' => 'right', 'padx' => '5', 'pady' => '5')
#     }
    
    # Cancel button
#     TkButton.new(dialog) {
#       text 'Cancel'; command { dialog.destroy };
#       pack('side' => 'right', 'padx' => '5', 'pady' => '2')
#     }

#     # Done button
#     TkButton.new(dialog, 'command' => proc { master.optionsDialogOK(name.value); dialog.destroy } ) {
#       text 'OK';
#       pack('side' => 'right', 'padx' => '5', 'pady' => '2')
#     }

#     dialog.focus
#     dialog.grab
  end

end