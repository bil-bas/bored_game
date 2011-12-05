# =============================================================================
# Bored Game
#
# By Bil Bas
#
# =============================================================================
module Hnefatafl

  IMAGE_DIR = "#{GAME_DIR}/Hnefatafl/images"
  COLOUR_TILE_BORDER = FXRGB(0, 0, 0)
  COLOUR_TILE        = FXRGB(0, 0xB0, 0)
  COLOUR_KINGS_TILE  = FXRGB(0xBB, 0, 0)

  # ---------------------------------------------------------------------------
  #
  class GameInfo < BasicGameInfo
    include Singleton

    attr_reader :moduleName, :name, :title, :subTitle, :about, :game, :minSides

    # ------------------------
    #
    private
    def initialize
      @moduleName = "Hnefatafl"
      @name = @title = "Hnefatafl"

      @subTitle = @title + " is a game for 2 players"

      @about =<<END_OF_TEXT
Hnefatafl (literally "King's Table", sometimes refered to as the Viking Game)
is a game of capture and escape.
END_OF_TEXT

      @game = Hnefatafl_11

      @minSides = 2 # Everyone must play!

      super [ Black.instance, White.instance ]
    end
  end
  # ---------------------------------------------------------------------------
  #
  class Black < Side
    private
    def initialize
      blackIcon = FXGIFIcon.new(@@app,
                    File.open("#{IMAGE_DIR}/black.gif", "rb").read)

      super 'Black', nil, blackIcon
    end
  end

  # ---------------------------------------------------------------------------
  #
  class White < Side
    private
    def initialize
      whiteIcon = FXGIFIcon.new(@@app,
                     File.open("#{IMAGE_DIR}/white.gif", "rb").read)

      super 'White', nil, whiteIcon
    end
  end

  # ---------------------------------------------------------------------------
  #
  class WhitePawn < Piece
    @@icon = nil

    private
    def initialize(tile, app)
      unless @@icon
        @@icon = FXGIFIcon.new(app,
                   File.open("#{IMAGE_DIR}/white.gif", "rb").read)
        @@icon.create
        @@name = "a pawn"
      end
      super tile, @@icon, @@name, White.instance
    end
  end

  # ---------------------------------------------------------------------------
  #
  class WhiteKing < Piece
    @@icon = nil

    private
    def initialize(tile, app)
      unless @@icon
        @@icon = FXGIFIcon.new(app,
                   File.open("#{IMAGE_DIR}/king.gif", "rb").read)
        @@icon.create
        @@name = "the king"
      end
     
      super tile, @@icon, @@name, White.instance
    end
  end
  
  # ---------------------------------------------------------------------------
  class BlackPawn < Piece
    @@icon = nil

    private
    def initialize(tile, app)
      unless @@icon
        @@icon = FXGIFIcon.new(app,
                   File.open("#{IMAGE_DIR}/black.gif", "rb").read)
        @@icon.create
        @@name = "a pawn"
      end

      super tile, @@icon, @@name, Black.instance
    end
  end

  # ---------------------------------------------------------------------------
  #
  class HnefataflTile < OpenTile
    private
    def colour
      COLOUR_TILE
    end

    public
    def draw(dc, x, y)
     # Outline
      dc.foreground = COLOUR_TILE_BORDER
      dc.fillRectangle x, y, @@size, @@size

      # Fill in with the colour.
      dc.foreground = colour
      dc.fillRectangle x + 1, y + 1, @@size - 2, @@size - 2

      super dc, x, y # Make sure any piece is drawn
    end
  end


  # ---------------------------------------------------------------------------
  # Abstract.
  #
  class KingsTile < HnefataflTile
    private
    def colour
      COLOUR_KINGS_TILE
    end
  end

  # ---------------------------------------------------------------------------
  #
  class ThroneTile < KingsTile

  end

  # ---------------------------------------------------------------------------
  #
  class CornerTile < KingsTile

  end

  # ---------------------------------------------------------------------------
  #
  class LightTile < HnefataflTile

  end

  # ---------------------------------------------------------------------------
  #
  class DarkTile < HnefataflTile

  end

  # ---------------------------------------------------------------------------
  #
  #
  class HnefataflGame < BasicMoveGame
  
    TILE_SIZE = 40
    PIECE_SIZE = 28

    # ------------------------
    #
    private
    def initialize(master, canvas, infoFrame, sides)
      layout = pieceLayout
      boardSize = layout.size
      @max = boardSize - 1

      super(master, canvas, infoFrame, sides, TILE_SIZE, PIECE_SIZE)
    end
  
    # ------------------------
    # movePiece()
    # Take any pieces based on the travel of the piece.
    # In this case we don't care where the piece came from.
    #
    public
    def movePiece(from, to)
      super from, to # Actually move piece.

      # Piece is now AT to.
      # Check whether white KING has escaped!
      if (to.piece.instance_of? WhiteKing) && (to.instance_of? CornerTile)
        @winner = @currSide
      end

      # Check to see if any of the adjacent pieces have been taken.
      takePiece(to.column, to.row + 1, true)  if to.row < @max
      takePiece(to.column, to.row - 1, true)  if to.row > 0
      takePiece(to.column + 1, to.row, false) if to.column < @max
      takePiece(to.column - 1, to.row, false) if to.column > 0
    end
  
    # ------------------------
    # takePiece()
    # Checks individual pieces to see if 'they' have been taken.
    # 'vertical' describes whether the moving piece is to the side
    # or above/below the piece to be checked.
    #
    private
    def takePiece(column, row, vertical) 
      check = nil
  
      tile = @board[column][row]
      piece = tile.piece

      # Ignore empty tile or friendly piece.
      return if piece.nil? || (currPiece? piece)

      if piece.instance_of? WhiteKing
        # The King must be surrounded on all four sides.
        check = [ [ column, row + 1 ], [column, row - 1],
                  [ column + 1, row ], [column - 1, row ] ]
      else
        if vertical
          # The piece must be taken from above and below...
          check = [ [ column, row + 1 ], [column, row - 1] ]
        else
          # ... or from both sides.
          check = [ [ column + 1, row ], [column - 1, row] ]
        end
      end
     
      if check
        # Examine all of the adjacent tiles and see how many can capture.
        numAdjacent = 0
        check.each do |checkColumn, checkRow|
          adjTile = @board[checkColumn][checkRow]
          if adjTile
            adjPiece = adjTile.piece
            # Check if piece is friendly or
            # Anyone can be captured by an EMPTY king's square.
            if currPiece?(adjPiece) ||
               (adjTile.kind_of?(KingsTile) && adjTile.empty?)
              numAdjacent += 1
            end
          else
            # King can be captured next to the edge (i.e. adjTile == nil)
            numAdjacent += 1 if piece.instance_of? WhiteKing
          end
        end
    
        # If a minimum number of sides are covered by enemies - take it.
        if numAdjacent >= check.size
          piece.remove
          @winner = @currSide if piece.instance_of? WhiteKing
        end
      end
    end
  
    # ------------------------
    #
    private
    def findPath(from, to)
      return nil if to == from

      piece = from.piece

      return nil unless piece

      kingMoving = piece.instance_of? WhiteKing
  
      # Disallow normal pieces from stopping at corner or center squares.
      return nil if (!kingMoving && (to.kind_of? KingsTile))
  
      # Institute simple 'rook' movement, checking for blocking pieces in way.
      if from.column == to.column
  
        if from.row > to.row
          start, finish = to.row, from.row - 1
        else
          start, finish = from.row + 1, to.row
        end
          
        for row in start..finish 
          # Fail if there is a piece in the way.
          # (Throne blocks non-Kings passage)
          if (@board[from.column][row].piece) ||
             (!kingMoving && (to.instance_of? ThroneTile))
  
            return nil
          end
        end
  
        return [ to ] # Horizontal movement not been blocked.
  
      elsif from.row == to.row
  
        if from.column > to.column
          start, finish = to.column, from.column - 1
        else
          start, finish = from.column + 1, to.column
        end
          
        for column in start..finish
          # Fail if there is a piece in the way.
          # (Throne blocks non-Kings passage)
          if (@board[column][from.row].piece) ||
             (!kingMoving && (to.instance_of? ThroneTile))
  
            return nil
          end
        end
  
        return [ to ] # Vertical movement not been blocked.
      end
  
      return nil # Movement must be diagonal.
    end
  end

  # ---------------------------------------------------------------------------
  #
  #
  class Hnefatafl_11 < HnefataflGame

    public
    def Hnefatafl_11.title
      "Hnefatafl (11x11 board)"
    end

    public
    def pieceLayout
      e = nil
      b = BlackPawn
      w = WhitePawn
      k = WhiteKing

      [
        [ e, e, e, b, b, b, b, b, e, e, e ],
        [ e, e, e, e, e, b, e, e, e, e, e ],
        [ e, e, e, e, e, e, e, e, e, e, e ],
        [ b, e, e, e, e, w, e, e, e, e, b ],
        [ b, e, e, e, w, w, w, e, e, e, b ],
        [ b, b, e, w, w, k, w, w, e, b, b ],
        [ b, e, e, e, w, w, w, e, e, e, b ],
        [ b, e, e, e, e, w, e, e, e, e, b ],
        [ e, e, e, e, e, e, e, e, e, e, e ],
        [ e, e, e, e, e, b, e, e, e, e, e ],
        [ e, e, e, b, b, b, b, b, e, e, e ]
      ]
    end

    public
    def tileLayout
      e = [ LightTile,  [] ]
      c = [ CornerTile, [] ]
      t = [ ThroneTile, [] ]

      size = 11

      layout = Array.new(size)
      # Create rows and fill with EMPTY tiles.
      for i in 0...size
        layout[i] = Array.new(size, e)
      end

      # Replace corners & centre with king-squares.
      last = (size - 1)
      layout[0][0]       = c
      layout[last][0]    = c
      layout[0][last]    = c
      layout[last][last] = c
      layout[last / 2][last / 2] = t

      return layout
    end

  end

  # ---------------------------------------------------------------------------
  #
  #
  class Hnefatafl_13 < HnefataflGame

    public
    def Hnefatafl_13.title
      "Hnefatafl (13x13 board)"
    end

    public
    def pieceLayout
      [
        [ E, E, E, E, B, B, B, B, B, E, E, E, E ],
        [ E, E, E, E, E, E, B, E, E, E, E, E, E ],
        [ E, E, E, E, E, E, E, E, E, E, E, E, E ],
        [ E, E, E, E, E, E, W, E, E, E, E, E, E ],
        [ B, E, E, E, E, E, W, E, E, E, E, E, B ],
        [ B, E, E, E, E, E, W, E, E, E, E, E, B ],
        [ B, B, E, W, W, W, K, W, W, W, E, B, B ],
        [ B, E, E, E, E, E, W, E, E, E, E, E, B ],
        [ B, E, E, E, E, E, W, E, E, E, E, E, B ],
        [ E, E, E, E, E, E, W, E, E, E, E, E, E ],
        [ E, E, E, E, E, E, E, E, E, E, E, E, E ],
        [ E, E, E, E, E, E, B, E, E, E, E, E, E ],
        [ E, E, E, E, B, B, B, B, B, E, E, E, E ]
      ]
    end

  end

  # ---------------------------------------------------------------------------
  #
  #
  class Tawlbyund_11A < HnefataflGame

    public
    def Tawlbyund_11A.title
     "Tawlbyund A (11x11 board)"
    end

    public
    def pieceLayout
      [
        [ E, E, E, B, B, B, B, B, E, E, E ],
        [ E, E, E, E, E, B, E, E, E, E, E ],
        [ E, E, E, E, E, W, E, E, E, E, E ],
        [ B, E, E, E, E, W, E, E, E, E, B ],
        [ B, E, E, E, E, W, E, E, E, E, B ],
        [ B, B, W, W, W, K, W, W, W, B, B ],
        [ B, E, E, E, E, W, E, E, E, E, B ],
        [ B, E, E, E, E, W, E, E, E, E, B ],
        [ E, E, E, E, E, W, E, E, E, E, E ],
        [ E, E, E, E, E, B, E, E, E, E, E ],
        [ E, E, E, B, B, B, B, B, E, E, E ]
      ]
    end

  end

  # ---------------------------------------------------------------------------
  #
  #
  class Tawlbyund_11B < HnefataflGame

    public
    def Tawlbyund_11B.title
     "Tawlbyund B (11x11 board)"
    end

    public
    def pieceLayout
      [
        [ E, E, E, E, B, B, B, E, E, E, E ],
        [ E, E, E, E, B, E, B, E, E, E, E ],
        [ E, E, E, E, E, B, E, E, E, E, E ],
        [ E, E, E, E, E, W, E, E, E, E, E ],
        [ B, B, E, E, W, W, W, E, E, B, B ],
        [ B, E, B, W, W, K, W, W, B, E, B ],
        [ B, B, E, E, W, W, W, E, E, B, B ],
        [ E, E, E, E, E, W, E, E, E, E, E ],
        [ E, E, E, E, E, B, E, E, E, E, E ],
        [ E, E, E, E, B, E, B, E, E, E, E ],
        [ E, E, E, E, B, B, B, E, E, E, E ]
      ]
    end
    
  end
end # module Hnefatafl