# =============================================================================
# Bored Game
#
# By Bil Bas
#
# =============================================================================

# =============================================================================
# Abstract class for any piece that might be placed on the board.
#
class Piece
  attr_reader :icon, :tile, :side
  attr_accessor :moving

  private
  def initialize(tile, icon, name, side)

    @tile, @icon, @name, @side = tile, icon, name, side
    
    # Place the piece on the board.
    @tile.piece = self

    @moving = false

    @side.addPiece self if @side
  end

  # ------------------------
  #
  public
  def to_s
    @name
  end

  # ------------------------
  # Moves the piece to another location, remembering to clear up the old one.
  #
  public
  def moveTo(tile)
    @tile.piece = nil

    @tile = tile

    @tile.piece = self
  end

  # ------------------------
  # Removes the piece from the board, temporarily.
  #
  public
  def remove
    @tile.piece = nil
    @tile = nil
    @side.removePiece self
  end

  # ------------------------
  #
  public
  def draw(dc, x, y, unshaded = false)
    if @moving && !unshaded
      dc.drawIconShaded @icon, x, y
    else
      dc.drawIcon @icon, x, y
    end
  end

  # ------------------------
  # Returns what is hit.
  # BUG: getPixel crashes???
  public
  def hit(x, y)
#  p [x, y, @icon.width, @icon.height]

    if (x >= 0 && x < @icon.width) && (y >= 0 && y < @icon.height)# &&
       #(@icon.getPixel(x, y) == @icon.transparentColor)
#  p @icon.transparentColor
#  p @icon.getPixel(0, 0) # WHAT IS WRONG HERE? WHY DIE???
      return self
    end

    return nil
  end
end