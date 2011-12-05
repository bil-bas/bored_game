# =============================================================================
# Bored Game
#
# By Bil Bas
#
# =============================================================================
require 'game'
require 'singleton'

module NoughtsAndCrosses

  IMAGE_DIR = "#{GAME_DIR}/NoughtsAndCrosses/images"

  # ---------------------------------------------------------------------------
  #
  class GameInfo < BasicGameInfo
    include Singleton

    attr_reader :moduleName, :name, :title, :subTitle, :about, :game, :minSides

    # ------------------------
    #
    private
    def initialize
      @moduleName = "NoughtsAndCrosses"
      @name = @title = "Noughts and Crosses"

      @subTitle = @title + " is a quick game for 2 players"

      @about =<<END_OF_TEXT
It is noughts and crosses, OXO or Tick-Tack-Toe.
END_OF_TEXT

#       @about.gsub!(/\n\n/, "\n")

      @game = NandCsGame

      @minSides = 2 # Everyone must play!

      super [ Noughts.instance, Crosses.instance ]
    end
  end

  # ---------------------------------------------------------------------------
  #
  class NoughtPiece < Piece
    @@icon = nil

    private
    def initialize(tile, app)
      unless @@icon
        @@icon = FXGIFIcon.new(app,
                   File.open("#{IMAGE_DIR}/nought.gif", "rb").read)
        @@icon.create
        @@name = 'a nought'
      end

      super tile, @@icon, @@name, Noughts.instance
    end

  end

  # ---------------------------------------------------------------------------
  #
  class CrossPiece < Piece
    @@icon = nil
  
    private
    def initialize(tile, app)
      unless @@icon
        @@icon = FXGIFIcon.new(app,
                   File.open("#{IMAGE_DIR}/cross.gif", "rb").read)
        @@icon.create
        @@name = 'a cross'
      end

      super tile, @@icon, @@name, Crosses.instance
    end

  end

  # ---------------------------------------------------------------------------
  #
  class NandCsTile < OpenTile

    def draw(dc, x, y)
     # Outline
      dc.foreground = FXRGB(0, 0, 0)
      dc.fillRectangle x, y, @@size, @@size

      # Fill in with the colour.
      dc.foreground = FXRGB(0xFF, 0xFF, 0xFF)
      dc.fillRectangle x + 2, y + 2, @@size - 4, @@size - 4

      super dc, x, y # Make sure any piece is drawn
    end
  end

  # ---------------------------------------------------------------------------
  #
  class Crosses < Side
    private
    def initialize
      crossIcon = FXGIFIcon.new(@@app,
                    File.open("#{IMAGE_DIR}/cross.gif", "rb").read)

      super 'Crosses', CrossPiece, crossIcon
    end
  end

  # ---------------------------------------------------------------------------
  #
  class Noughts < Side
    private
    def initialize
      noughtIcon = FXGIFIcon.new(@@app,
                     File.open("#{IMAGE_DIR}/nought.gif", "rb").read)

      super 'Noughts', NoughtPiece, noughtIcon
    end
  end

  # ===========================================================================
  # There is only one game type.
  #
  class NandCsGame < BasicPlaceGame
    # width/height in pixels
    TILE_SIZE = 60
    PIECE_SIZE = 48

    # Lines are drawn when a row of 3 pieces has been created.
    LINE_COLOUR = FXRGB(0xFF, 0, 0)
    LINE_WIDTH = 16

    # ------------------------
    #  
    private
    def initialize(master, canvas, infoFrame, sides)
  
      @spacesLeft = 9 # grid is empty!

      super(master, canvas, infoFrame, sides, TILE_SIZE, PIECE_SIZE)

      @diagonals = [
      [ @board[0][0], @board[1][1], @board[2][2] ], # \
      [ @board[2][0], @board[1][1], @board[0][2] ]  # /
    ]
#       load "--O\n-X-\n--X\n"
    end

    # ------------------------
    # afterPlace()
    #
    private
    def afterPlace(tile)
      @spacesLeft -= 1 # One step closer to stalemate
  
      # Test for vertical line through new piece
      winLine = true
      for row in 0...@board.numRows
        winLine = false unless currPiece?(@board[tile.column][row].piece)
      end
      if winLine
        @winner = @currSide
        @board.drawLineGrid tile.column, 0,
                            tile.column, @board.numRows - 1,
                            LINE_COLOUR, LINE_WIDTH
      end
  
      # Test for horizontal line through new piece
      winLine = true
      for column in 0...@board.numColumns
        winLine = false unless currPiece?(@board[column][tile.row].piece)
      end
      if winLine
        @winner = @currSide
        @board.drawLineGrid 0, tile.row,
                            @board.numColumns - 1, tile.row,
                            LINE_COLOUR, LINE_WIDTH
      end
  
      @diagonals.each do |line|
        # Test for '\' and '/' lines
        winLine = true
        line.each do |tile|
          winLine = false unless currPiece?(tile.piece)
        end
        if winLine
          @winner = @currSide
          @board.drawLineGrid line[0].column, line[0].row,
                              line[2].column, line[2].row,
                              LINE_COLOUR, LINE_WIDTH
        end
      end
    end

    # ------------------------
    # Pieces can only be placed in empty squares.
    #
    private
    def legalPlace?(tile)
      tile.empty?
    end
  
    # ------------------------
    # A stalemate occurs when all the squares have been filled.
    #
    private
    def staleMate?
      @spacesLeft == 0 
    end

    # ------------------------
    # 3x3 Board is initalially empty.
    #
    public
    def tileLayout
      t = [ NandCsTile, [] ]
      [
        [ t, t, t ],
        [ t, t, t ],
        [ t, t, t ]
      ]
    end

    # ------------------------
    # 3x3 Board is initalially empty.
    #
    public
    def pieceLayout
      e = nil
      [
        [ e, e, e ],
        [ e, e, e ],
        [ e, e, e ]
      ]
    end

    # ------------------------
    #
    public
    def save
      data = ''

      for column in 0...@board.numColumns
        for row in 0...@board.numRows
          piece = @board[column][row].piece
          if piece
            if piece.instance_of? Nought
              data += 'O'
            else
              data += 'X'
            end
          else
            data += '-'
          end
        end

        data += "\n"
      end
             
      data 
    end

    # ------------------------
    #
    public
    def load(data)
      for column in 0...@board.numColumns
        for row in 0...@board.numRows
          tile = @board[column][row]
          case data[(row * 4) + column]
          when ?O:
            Nought.new(tile, @master.app)
          when ?X:
            Cross.new(tile, @master.app)
          when ?-:
             # Nothing
          end
          data += "\n"
        end
      end
    end
    
  end
end
