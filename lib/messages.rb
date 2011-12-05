# =============================================================================
# Bored Game
#
# By Bil Bas
#
# =============================================================================

# =============================================================================
#
#
SERVER_ADDR = 0
BROADCAST_ADDR = 0xff # 255

class BasicMsg
  attr_accessor :source, :dest
end

class BasicTextMsg < BasicMsg
  attr_reader :text

  private
  def initialize(text)
    @text = text
  end
end

# =============================================================================
#
#
class ChangeNameMsg < BasicMsg
  attr_reader :name

  private
  def initialize(name)
    @name = name
  end
end

# =============================================================================
#
#

class DiedMsg < BasicMsg
  private
  def initialize(source)
    @source = source
  end
end
# =============================================================================
#
#
class EmoteMsg < BasicTextMsg
end

# =============================================================================
#
#
class LoginMsg < BasicMsg
  attr_reader :name

  private
  def initialize(name)
    @name = name 
  end
end

# =============================================================================
# Telling about the throw of the die (or dice).
#
class DiceMsg < BasicMsg
  attr_reader :number

  private
  def initialize(number)
    @number = number 
  end
end

# =============================================================================
#
#
class LoginOkMsg < BasicMsg
  attr_reader :num, :players

  private
  def initialize(num, players)
    @num, @players = num, players 
  end
end

# =============================================================================
#
#
class MoveMsg < BasicMsg
  attr_reader :from, :to

  private
  def initialize(from, to)
    @from, @to = [from.column, from.row], [to.column, to.row]
  end
end

# =============================================================================
#
#
class NewPlayerMsg < BasicMsg
end

# =============================================================================
#
#
class NewGameMsg < BasicMsg
  attr_reader :game, :options

  private
  def initialize(game, options = nil)
    @game = game.moduleName
    @options = options
  end
end

# =============================================================================
#
#
class PassMsg < BasicMsg
end

# =============================================================================
#
#
class PingMsg < BasicMsg
  attr_reader :time
  attr_accessor :bounced

  private
  def initialize(dest)
    @bounced = nil
    @dest = dest
    @time = Time.new
  end
end

# =============================================================================
#
#
class PlaceMsg < BasicMsg
  attr_reader :at

  private
  def initialize(at)
    @at = [at.column, at.row]
  end
end

# =============================================================================
#
#
class SayMsg < BasicTextMsg
end

# =============================================================================
#
#
class SurrenderMsg < BasicMsg
end

# =============================================================================
#
#
class QuitMsg < BasicMsg
end