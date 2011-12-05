# =============================================================================
# Bored Game
#
# By Bil Bas
#
# =============================================================================

# =============================================================================
#
#
class MovingIcon
  attr_reader :piece, :from
  attr_accessor :pos
  attr :canvas

  private
  def initialize(canvas, piece, from, pos)
    @canvas, @piece, @from, @pos = canvas, piece, from, pos

    # Create a blank icon which will be used to store the image covered by the
    # dragged piece.

    @buffer = FXImage.new(@canvas.app, nil, 0, @piece.icon.width, @piece.icon.height)
    @buffer.create
  end

  # ------------------------
  #
  public
  def saveBuffer
    FXDCWindow.new(@buffer) do |dc|
      dc.drawArea @canvas, pos.x, pos.y, @buffer.width, @buffer.height, 0, 0
    end
  end

  # ------------------------
  #
  public
  def restoreBuffer
    FXDCWindow.new(@canvas) do |dc|
      dc.drawImage @buffer, pos.x, pos.y
    end
  end
end

# -----------------------------------------------------------------------------
#
#
class Move < MovingIcon

  PIECE_SPEED = 5 # Pixels per tick

  attr_reader :to, :endPos

  private
  def initialize(canvas, piece, from, to, pos, endPos)
    @to, @endPos = to, endPos

    piece.moving = true

    super canvas, piece, from, pos
  end

  public
  def animate
    restoreBuffer

    x, y = @pos.x, @pos.y

    nextPos = @endPos[0]

    xDistance = nextPos.x - x
    x += if xDistance > 0
           PIECE_SPEED
         elsif xDistance < 0
           - PIECE_SPEED
         else
           0
         end
    if xDistance > 0
      x = [x, nextPos.x].min
    else
      x = [x, nextPos.x].max
    end

    yDistance = nextPos.y - y
    y += if yDistance > 0
           PIECE_SPEED
         elsif yDistance < 0
           - PIECE_SPEED
         else
           0
         end
    if yDistance > 0
      y = [y, nextPos.y].min
    else
      y = [y, nextPos.y].max
    end

# puts "#{pos.x},#{pos.y} & #{x},#{y} & #{nextPos.x},#{nextPos.y}"

    @pos = FXPoint.new(x, y)

# puts "#{pos.x},#{pos.y}"
    saveBuffer

    FXDCWindow.new(@canvas) do |dc|
      piece.draw dc, x, y, true # Force it to be drawn unshaded.
    end

    if (@pos == nextPos)
      if @endPos.size > 1
        # Get rid of that move. We've completed it.
        @endPos.shift
      else
        # No more moves required.
        piece.moving = false
        return false
      end
    end

    true
  end
end

# -----------------------------------------------------------------------------
#
#
class Drag < MovingIcon
  private
  def initialize(canvas, piece, from, pos)
    piece.moving = true

    super canvas, piece, from, pos
  end
end
