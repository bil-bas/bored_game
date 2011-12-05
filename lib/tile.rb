# =============================================================================
# Bored Game
#
# By Bil Bas
#
# =============================================================================

require 'pathfinding'

# =============================================================================
#
#
class Tile < Vertex

  attr_reader :column, :row

  # ------------------------
  #
  private
  def initialize(column, row, background = nil)
    @column, @row, @background = column, row, background

    @@board[column][row] = self

    super()
  end

  # ------------------------
  # Relocates the Class-wide reference for board.
  #
  public
  def Tile.relocate(board)
    @@board = board
  end

  # ------------------------
  #
  public
  def to_s
    "#{(?A + @column).chr}-#{@row + 1}"
  end

  # ------------------------
  #
  public
  def board
    @@board
  end

  # ------------------------
  #
  public
  def draw(dc, x, y)
    if @background
      dc.drawImage @background, x, y
    end
  end

  # ------------------------
  #
  public
  def Tile.dimension(tileSize, pieceSize, app)
    @@size = tileSize

    @@margin = (tileSize - pieceSize) / 2
    @@app = app
  end

  # ------------------------
  # Returns what is hit, either the tile or the piece on it.
  #
  public
  def hit(x, y)
    if piece
      hit = piece.hit(x - @@margin, y - @@margin)
      if hit
        return hit
      else
        return self
      end
    else
      return self
    end
  end
end

# =============================================================================
# A Tile which cannot hold a piece.
#
class ClosedTile < Tile
  # ------------------------
  #
  public
  def enterable?
    false
  end

  # ------------------------
  #
  public
  def piece
    nil
  end

  # ------------------------
  #
  public
  def edges
    return nil
  end
end

# =============================================================================
# A Tile which can hold a piece.
#
class OpenTile < Tile
  attr_reader :piece

  # ------------------------
  #
  private
  def initialize(column, row, background = nil)
    @piece, @edges = nil, Hash.new

    super column, row, background
  end

  # ------------------------
  # If piece changes, then we must update the entire tile.
  public
  def piece=(newPiece)
    @piece = newPiece
    @@board.updateTile column, row
  end
  # ------------------------
  #
  public
  def empty?
    @piece.nil?
  end

  # ------------------------
  #
  public
  def enterable?
    true
  end

  # ------------------------
  #
  public
  def draw(dc, x, y)
    super dc, x, y

    if @piece
      @piece.draw dc, x + @@margin, y + @@margin
    end
  end
end

# =============================================================================
# A Tile which is to be to be ignored. Fill in with background colour.
#
class VoidTile < ClosedTile
  # ------------------------
  #
  public
  def draw(dc, x, y)
    dc.foreground = @@board.backColor
    dc.fillRectangle x, y, @@size, @@size
  end
end