# =============================================================================
# Bored Game
#
# By Bil Bas
#
# =============================================================================

require 'piece'
require 'tile'
require 'animate'

ROTATION_0 = 0
ROTATION_90 = 1
ROTATION_180 = 2
ROTATION_270 = 3
ROTATION_360 = 4

KEY_LEFT  = 65361
KEY_UP    = 65362
KEY_RIGHT = 65363
KEY_DOWN  = 65364

# =============================================================================
#
#
class Line
  attr_reader :x1, :y1, :x2, :y2, :colour, :width, :cap

  private
  def initialize(x1, y1, x2, y2, colour, width, cap)
    @x1, @y1, @x2, @y2, @colour, @numColumns, @cap = 
       x1, y1, x2, y2, colour, width, cap
  end

  public
  def draw(dc)
    dc.foreground = @colour
    dc.lineWidth = @numColumns
    dc.lineCap = @cap
    dc.drawLine x1, y1, x2, y2
  end

end

# =============================================================================
# An array which returns nil for negative indexes.
# Used to hold inner arrays in the tiles 2D array.
#
class ArrayNotNeg < Array
  public
  def [](index)
    if index < 0
      nil
    else
      super
    end
  end
end

# =============================================================================
#
#
class Board < FXHorizontalFrame

  SELECT_COLOUR = '#f00'

  GRID_LINE_WIDTH = 2

  attr_reader :numRows, :numColumns, :tileSize, :rotation

  private
  def initialize(game, frame, tileSize, pieceSize, tileLayout, pieceLayout)
    @game = game
    @tileSize = tileSize
    @pieceSize = pieceSize

    @rotation = ROTATION_0

    pad = 10 # Margin outside the board. May contain the coords one day?
    super frame, 0, 0, 0, 0, 0, pad, pad, pad, pad
    @pieceMargin = (@tileSize - @pieceSize) / 2

    Tile.relocate(self) # Make sure that new items point at this board.

    Tile.dimension(tileSize, pieceSize, frame.app)

    self.backColor = FXRGB(0, 0, 0)

    # The dimensions let us know just how many tiles to ask for.
    @numRows = tileLayout.size
    @numColumns = tileLayout[0].size

    @canvas = FXCanvas.new(self, self, 0, LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT, 
      0, 0, @numColumns * tileSize, @numRows * tileSize)

    @canvas.connect(SEL_PAINT,             method(:onPaint))
    @canvas.connect(SEL_LEFTBUTTONPRESS,   method(:onMouseDown))
    @canvas.connect(SEL_MOTION,            method(:onMouseMove))
    @canvas.connect(SEL_LEFTBUTTONRELEASE, method(:onMouseUp))

    # Scroll the board within the frame.
    @canvas.connect(SEL_KEYPRESS, method(:onKeyPress))

    @game.statusBar.statusLine.connect(SEL_UPDATE, method(:onQueryHelp))

    # Create tiles and pieces.
    @tiles = Array.new(@numColumns) # Create columns

    for column in 0...@numColumns
      @tiles[column] = ArrayNotNeg.new(@numRows) # Create rows
      for row in 0...@numRows
        tileType, args = tileLayout[row][column] # Reverse!
          tileType.new column, row, *args

        pieceType = pieceLayout[row][column] # Reverse!

        unless pieceType.nil?
          pieceType.new self[column][row], frame.app
        end
      end
    end

    @game.initEdges self

    @drag = nil

    @move = nil

    @lines = Array.new
  end

  # ------------------------
  # 
  #
  public
  def onPaint(sender, sel, event)
# p [sender, sel, event]
    x, y, width, height = event.rect.x, event.rect.y, event.rect.w, event.rect.h

    colA, rowA = xy2coord(x, y)
    colB, rowB = xy2coord(x + width, y + height)

    # Rectangle has been rotated - so make sure we are top-R to bottom-L corners.
    minCol, maxCol = [colA, colB].min, [[colA, colB].max, @numColumns - 1].min
    minRow, maxRow = [rowA, rowB].min, [[rowA, rowB].max, @numRows - 1].min

    FXDCWindow.new(@canvas, event) do |dc|
      # Redraw tiles and pieces.
      for column in minCol..maxCol
        for row in minRow..maxRow
# p ["painting x, y = ", column * @tileSize, row * @tileSize].join(",")
#           rotX, rotY = rotate(column * @tileSize, row * @tileSize, maxCol * @tileSize, maxRow * @tileSize, true)
          rotX, rotY = coord2xy(column, row)
# p "painting tile coord #{column}, #{row} / xy #{rotX}, #{rotY}"
          self[column][row].draw dc, rotX, rotY
        end
      end

      for line in @lines
        line.draw dc
      end
# p "done painting"
    end
  end

  # ------------------------
  # Create a new piece of class 'klass' on this board.
  #
  public
  def createPiece(klass, tile)
# p "created at tile #{tile.column}, #{tile.row}"
    klass.new(tile, @canvas.app)
  end

  # ------------------------
  # Allow access to internal array of pieces. If the index is out of bounds
  # we must return an empty array (rather than nil) so that board[999][1]
  # will OVERALL return a nil.
  #
  public
  def [](index)
    if index < 0 || index >= @tiles.size
      []
    else
      @tiles[index]
    end
  end

  # ------------------------
  # Start dragging a piece.
  #
  def onMouseDown(sender, sel, event)

    half = @pieceSize / 2

    x, y = event.win_x, event.win_y
    column, row = xy2coord(x, y)

    target = self[column][row].hit(x % @tileSize, y % @tileSize)

    case target
      when Piece
        if @game.canDrag? target
          @drag = Drag.new @canvas, target, target.tile,
                  FXPoint.new(x - half, y - half)
    
          updateTile column, row # delete old version.
          repaintTile column, row # and force redraw now.
    
          @drag.saveBuffer # Save what where we will draw

          FXDCWindow.new(@canvas) do |dc|
            @drag.piece.draw dc, @drag.pos.x, @drag.pos.y, true # Draw over.
          end
        end
      when Tile
        @game.press target
    end

    return 1
  end

  # ------------------------
  # During a drag.
  #
  def onMouseMove(sender, sel, event)
    if @drag
      # Erase the old icon.
      @drag.restoreBuffer

      half = @pieceSize / 2
  
      # x and y are the top left hand corner of the dragged icon.
      x, y = event.win_x - half, event.win_y - half
  
      # Limit pieces to canvas.
      x = [ [ x, 0 ].max, ((@numColumns - 1) * @tileSize + @pieceMargin * 2) ].min
  
      y = [ [ y, 0 ].max, ((@numRows - 1) * @tileSize + @pieceMargin * 2) ].min

      @drag.pos.x, @drag.pos.y = x, y

      # Save the graphics at new position, then draw over it.
      @drag.saveBuffer

      FXDCWindow.new(@canvas) do |dc|
        @drag.piece.draw dc, x, y, true
      end

      # Cursor in middle of icon.
      @canvas.setCursorPosition(x + half, y + half)
    end

    return 1
  end

  # ------------------------
  # A dragged icon has been released
  #
  public
  def onMouseUp(sender, sel, event)
    if @drag
      @canvas.ungrab

      @drag.restoreBuffer

      @drag.piece.moving = false

      column, row = xy2coord(event.win_x, event.win_y)

      @game.dragDrop @drag.piece, self[column][row]

      updateTile @drag.from.column, @drag.from.row # Remove the shaded icon.

      @drag = nil
    end

    return 1
  end

  # ------------------------
  # Update the status line based on the mouse position within the board.
  #
  public
  def onQueryHelp(sender, sel, event) 
    x, y, button = @canvas.cursorPosition
    if x >= 0 && y >= 0 # && x < parent.width && y < parent.height
      column, row = xy2coord(x, y)
      if tile = self[column][row]
        str = "Board position #{tile}"
        if piece = tile.piece
          str += " contains #{piece}"
        end
        sender.text = str
        return 1
      end
    end

    return 0
  end

    private
    def onKeyPress(sender, sel, event)
      x, y = parent.xPosition, parent.yPosition
      scrollBy = parent.horizontalScrollbar.line * 2

      case event.code
        when KEY_UP
          y += scrollBy
        
        when KEY_DOWN
          y -= scrollBy

        when KEY_LEFT
          x += scrollBy

        when KEY_RIGHT
          x -= scrollBy

      end

      parent.setPosition x, y

      return 1 # OK!
    end
  # ------------------------
  #
  public
  def updateTile(column, row)
    x, y = coord2xy(column, row)
    @canvas.update x, y, @tileSize, @tileSize
  end

  # ------------------------
  #
  public
  def repaintTile(column, row)
    x, y = coord2xy(column, row)
    @canvas.repaint x, y, @tileSize, @tileSize
  end

  # ------------------------
  #
  private
  def drawIcon(icon, x, y)
    FXDCWindow.new(@canvas) do |dc|

# #       poly = [FXPoint.new(0, 0), FXPoint.new(200,200), FXPoint.new(200,0), FXPoint.new(100,50)]
# #       dc.foreground = FXRGB(0,255,0)
# #       dc.background = FXRGB(255,0,0)
# #       dc.fillStyle = FILL_SOLID

# #       dc.fillPolygon(poly)
# # #       dc.fillConcavePolygon(poly)
# # #       dc.fillComplexPolygon(poly)

#       dc.drawLines(poly)

      dc.drawIcon(icon, x, y)
    end
  end

  # ------------------------
  #
  public
  def drawPiece(piece)
    x, y = coord2xy(piece.tile.column * @tileSize + @pieceMargin,
                    piece.tile.row * @tileSize + @pieceMargin)
    drawIcon(piece.icon, x, y)
  end

  # ------------------------
  #
  public
  def animateMove(from, to)
    initPos = FXPoint.new((from.column * @tileSize) + @pieceMargin,
                          (from.row    * @tileSize) + @pieceMargin)

    endPos = Array.new(to.size)

    for i in 0...to.size
      endPos[i] = FXPoint.new((to[i].column * tileSize) + @pieceMargin,
                              (to[i].row    * tileSize) + @pieceMargin)
    end
    @move = Move.new(@canvas, self[from.column][from.row].piece,
                     from, to.last, initPos, endPos)

    # Delete old version before we save the background.
    @canvas.update  initPos.x, initPos.y, @tileSize, @tileSize
    @canvas.repaint initPos.x, initPos.y, @tileSize, @tileSize

    @move.saveBuffer

    @game.startAnimatingAction
  end

  # ------------------------
  #
  def animateMoveFrame
    if @move
      moveContinuing = @move.animate
      unless moveContinuing
        @game.movePiece @move.from, @move.to
        @game.endPhase

        if @game.viewLastMove
  #         drawLineGrid @move.from, @move.to, FXRGB(0, 0, 0xFF), 6
        end
  
        @move = nil

        @game.endAnimatingAction
      end
    end
  end


  # ------------------------
  #
  public
  def drawLineGrid(column1, row1, column2, row2, colour, width)
    halfTile = @tileSize / 2

    x1, y1 = coord2xy(column1, row1)
    x2, y2 = coord2xy(column2, row2)

    x1 += halfTile
    y1 += halfTile
    x2 += halfTile
    y2 += halfTile

    line = Line.new(x1, y1, x2, y2, colour, width, CAP_ROUND)

    @lines.push line
    @canvas.update
  end

  # ------------------------
  # Convert screen coordinates into board coordinates, through rotation.
  #
  public
  def xy2coord(x, y)
    maxX, maxY = (@numColumns * @tileSize), (@numRows  * @tileSize) - 1

    if @rotation != ROTATION_0
      # Anti-clockwise rotation
      x, y = rotate(x, y, maxX, maxY, false)
    end
   
    # Divide screen coordinates to get board coords.
    column = (x / @tileSize).floor
    row    = (y / @tileSize).floor

    [ column, row ]
  end

  # ------------------------
  # Convert board coordinates into screen coordinates, through rotation.
  #
  public
  def coord2xy(column, row)
    maxCols, maxRows = @numColumns - 1, @numRows - 1

    if @rotation != ROTATION_0
      # Clockwise rotation
      column, row = rotate(column, row, maxCols, maxRows, true)
    end

    # Multiply them up to real screen coords.
    x = column * @tileSize
    y = row * @tileSize

    [ x, y ]
  end

  # ------------------------
  # Rotate a set of coordinates, clockwise or anti-clockwise.
  #
  private
  def rotate(x, y, maxX, maxY, clockwise)
    if clockwise
      rot = @rotation
    else
      rot = ROTATION_360 - @rotation
    end

    case rot
      when ROTATION_0:
        # No rotation

      when ROTATION_90:
        x, y = maxX - y, x

      when ROTATION_180:
        x, y = maxX - x, maxY - y

      when ROTATION_270:
        x, y = y, maxY - x

    end

    [ x, y ]
  end

  # ------------------------
  #
  # 
  public
  def cleanUp
    @canvas.parent.removeChild @canvas
  end 

end