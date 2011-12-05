# =============================================================================
# Bopink Game
#
# By Bil Bas
#
# =============================================================================
module Shoggoth

  IMAGE_DIR = "#{GAME_DIR}/Shoggoth/images"
  COLOUR_TILE        = FXRGB(0x70, 0x70, 0x30)
  COLOUR_ROCK        = FXRGB(0x90, 0x90, 0x90)
  COLOUR_TILE_BORDER = FXRGB(0x68, 0x68, 0x28)

  # ---------------------------------------------------------------------------
  #
  class GameInfo < BasicGameInfo
    include Singleton

    attr_reader :moduleName, :name, :title, :subTitle, :about, :game, :minSides

    # ------------------------
    #
    private
    def initialize
      @moduleName = "Shoggoth"
      @name = @title = "Shoggoth!"

      @subTitle = @title + " is a game for 2 players"

      @about = "Schlopp!!! " * 200

      @game = ShoggothGame

      @minSides = 2 # Everyone must play!

      super [ Pink.instance, Green.instance ]
    end
  end

  # ---------------------------------------------------------------------------
  #
  class ShoggothSide < Side
  end

  # ---------------------------------------------------------------------------
  #
  class Pink < ShoggothSide
    private
    def initialize
      icon = FXGIFIcon.new(@@app,
                    File.open("#{IMAGE_DIR}/pink.gif", "rb").read)

      super 'Pink', nil, icon
    end

  end

  # ---------------------------------------------------------------------------
  #
  class Green < ShoggothSide
    private
    def initialize
      icon = FXGIFIcon.new(@@app,
                     File.open("#{IMAGE_DIR}/green.gif", "rb").read)

      super 'Green', nil, icon
    end
  end

  # ---------------------------------------------------------------------------
  #
  class ShoggothPiece < Piece
    FEATURE_OFFSET = 6
    public
    def draw(dc, x, y, unshaded = false)
      super # Draw body
      x1, y1 = x + FEATURE_OFFSET, y + FEATURE_OFFSET
      if @moving && !unshaded
        dc.drawIconShaded features[feature], x1, y1
      else
        dc.drawIcon features[feature], x1, y1
      end
    end
  end

  # ---------------------------------------------------------------------------
  #
  class PinkShoggoth < ShoggothPiece
    @@icon = nil

    private
    def initialize(tile, app)
      unless @@icon
        @@icon = FXGIFIcon.new(app,
                   File.open("#{IMAGE_DIR}/pink.gif", "rb").read)
        @@icon.create
        @@name = "a shoggoth"

        @@connectors = Array.new 4
        connTypes = ['Top', 'Right', 'Bottom', 'Left']
        for i in 0...connTypes.size
          @@connectors[i] = FXGIFIcon.new(app,
                   File.open("#{IMAGE_DIR}/pinkConn#{connTypes[i]}.gif", "rb").read)
          @@connectors[i].create
        end

        featureTypes = ['mouth', 'eye', 'pinkTentacle']
        @@features = Array.new featureTypes.size
        for i in 0...featureTypes.size
          @@features[i] = FXGIFIcon.new(app,
                   File.open("#{IMAGE_DIR}/#{featureTypes[i]}.gif", "rb").read)
          @@features[i].create
        end

      end

      @feature = rand @@features.size

      super tile, @@icon, @@name, Pink.instance
    end

    public
    def connectors
      @@connectors
    end

    public
    def features
      @@features
    end

    public
    def feature
      @feature
    end
  end
  
  # ---------------------------------------------------------------------------
  class GreenShoggoth < ShoggothPiece
    @@icon = nil

    private
    def initialize(tile, app)
      unless @@icon
        @@icon = FXGIFIcon.new(app,
                   File.open("#{IMAGE_DIR}/green.gif", "rb").read)
        @@icon.create
        @@name = "a shoggoth"

        @@connectors = Array.new 4
        connTypes = ['Top', 'Right', 'Bottom', 'Left']
        for i in 0...connTypes.size
          @@connectors[i] = FXGIFIcon.new(app,
                   File.open("#{IMAGE_DIR}/greenConn#{connTypes[i]}.gif", "rb").read)
          @@connectors[i].create
        end

        featureTypes = ['mouth', 'eye', 'greenTentacle']
        @@features = Array.new featureTypes.size
        for i in 0...featureTypes.size 
          @@features[i] = FXGIFIcon.new(app,
                   File.open("#{IMAGE_DIR}/#{featureTypes[i]}.gif", "rb").read)
          @@features[i].create
        end
      end

      @feature = rand @@features.size

      super tile, @@icon, @@name, Green.instance
    end

    public
    def connectors
      @@connectors
    end

    public
    def features
      @@features
    end

    public
    def feature
      @feature
    end
  end

  # ---------------------------------------------------------------------------
  #
  class Rock < Piece
    @@icon = nil

    private
    def initialize(tile, app)
      unless @@icon
        @@icon = FXGIFIcon.new(app,
                   File.open("#{IMAGE_DIR}/rock.gif", "rb").read)
        @@icon.create
        @@name = "a rock"
      end

      super tile, @@icon, @@name, nil
    end
  end

  # ---------------------------------------------------------------------------
  #
  class ShoggothTile < OpenTile
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

      # Draw hugging-Shoggoth behind Shoggoth in tile.
      # Ideally it should draw hugging-Shoggoth in all 8 directions.
      if @piece && @piece.side
        for adjPiece in adjacentPiecesVH
          if adjPiece.side == @piece.side
            xDiff = adjPiece.tile.column - @column
            yDiff = adjPiece.tile.row    - @row

            case [xDiff, yDiff]
              when [ 1,  0] # East
                connector = @piece.connectors[1]
                connX = x + @@size - connector.width
                connY = y + ((@@size - connector.height) / 2)
              when [-1,  0] # West
                connector = @piece.connectors[3]
                connX = x
                connY = y + ((@@size - connector.height) / 2)
              when [ 0,  1] # South
                connector = @piece.connectors[2]
                connX = x + ((@@size - connector.width) / 2)
                connY = y + @@size - connector.height
              when [ 0, -1] # North
                connector = @piece.connectors[0]
                connX = x + ((@@size - connector.width) / 2)
                connY = y
              else
                p "Disaster!"
                p "piece at #{@piece.tile.column}, #{@piece.tile.row}"
                p "adjpiece #{adjPiece.inspect}"
                p "...at #{adjPiece.tile.column}, #{adjPiece.tile.row}"
                p "diffs #{xDiff}, #{yDiff}"
            end

            dc.drawIcon connector, connX, connY
          end
        end
      end

      super dc, x, y # Make sure any piece is drawn
    end

    # ------------------------
    public
    def adjacentPieces
      pieces = Array.new

      maxColumn, maxRow = @@board.numColumns - 1, @@board.numRows - 1

      adjColumns = ([@column - 1, 0].max)..([@column + 1, maxColumn].min)
      adjRows    = ([@row    - 1, 0].max)..([@row    + 1, maxRow   ].min)

      # Check to see if any of the adjacent pieces have been taken.
      for adjColumn in adjColumns
        for adjRow in adjRows
          # Ignore the central tile!
          unless (adjColumn == @column) && (adjRow == @row)
            tile = @@board[adjColumn][adjRow]
            if tile
              piece = tile.piece
              pieces.push piece unless piece.nil?
            end
          end
        end
      end

      return pieces
    end

    # ------------------------
    public
    def adjacentPiecesVH
      pieces = Array.new

      adjTiles = [
        @@board[@column - 1][@row    ], @@board[@column + 1][@row    ],
        @@board[@column    ][@row - 1], @@board[@column    ][@row + 1]
      ]

      for adjTile in adjTiles
        if adjTile
          piece = adjTile.piece
          pieces.push piece unless piece.nil?
        end
      end

      return pieces
    end
  end

  # ---------------------------------------------------------------------------
  #
  #
  class ShoggothGame < BasicMoveGame
  
    TILE_SIZE = 40
    PIECE_SIZE = 36

    # ------------------------
    #
    private
    def initialize(master, canvas, infoFrame, sides)
      layout = pieceLayout
      boardSize = layout.size
      @max = boardSize - 1

      super(master, canvas, infoFrame, sides, TILE_SIZE, PIECE_SIZE)
  
      @countFrame = FXVerticalFrame.new infoFrame, FRAME_SUNKEN|LAYOUT_FILL_X

      @shoggInds = Hash.new
      for side in sides
        @shoggInds[side] = FXLabel.new(@countFrame, '0', side.icon, ICON_BEFORE_TEXT)
        @shoggInds[side].font = FXFont.new(@countFrame.app, 'arial', 16, FONTWEIGHT_BOLD)
      end

      @countFrame.create

      updateShoggInds
    end
  
    # ------------------------
    # movePiece()
    # 'Turn' any pieces based on where the piece lands.
    #
    public
    def movePiece(from, to)
      super from, to # Actually move piece.

      # A short move means we divide...
      if distance(from, to) == 1
        # Create a piece to fill the gap.
        @board.createPiece(to.piece.class, from)
 
        if @sides[0].pieces.size + @sides[1].pieces.size == @tilesLeft
          if @sides[0].pieces.size > @sides[1].pieces.size
            @winner = @sides[0]
          elsif @sides[0].pieces.size < @sides[1].pieces.size
            @winner = @sides[1]
          else
            @stalemate = true
          end
        end
      end

      tilesToUpdate = Array.new

      # Update all friendly pieces next to where we left * arrived.
      for adjPiece in (from.adjacentPieces | to.adjacentPieces)
        if adjPiece.side == @currSide
          tilesToUpdate.push adjPiece.tile
        end
      end

      for adjPiece in to.adjacentPieces
        # If the piece if of another flavour, turn it!
        if adjPiece.side && adjPiece.side != @currSide
          tile = adjPiece.tile
          adjPiece.remove
          @board.createPiece(to.piece.class, tile)
          tilesToUpdate.push tile

          # Update all pieces next to a 'turned' target.
          for adjAdjPiece in tile.adjacentPieces
            tilesToUpdate.push adjAdjPiece.tile
          end
        end
      end

      # Update each of the tiles we need to update once only.
      for tile in tilesToUpdate.uniq
        @board.updateTile(tile.column, tile.row)
      end

      updateShoggInds
    end

    # ------------------------
    # Update the shoggoth count indicators in the info panel.
    private
    def updateShoggInds
      for side in @sides
        @shoggInds[side].text = "#{side.pieces.size}"
      end
    end
  
    # ------------------------
    #
    private
    def findPath(from, to)
      return nil if (to == from) || to.piece 

      if distance(from, to) <= 2
        return [from, to]
      else
        return nil
      end
    end

    public
    def cleanUp
      super
      @countFrame.parent.removeChild @countFrame
    end

    # ------------------------
    # Distance assuming diagonal movement.
    #
    private
    def distance(from, to)
      hDistance = [from.column, to.column].max - [from.column, to.column].min
      vDistance = [from.row,    to.row].max    - [from.row,    to.row].min
      return [hDistance, vDistance].max
    end

    # ------------------------
    #
    public
    def pieceLayout
      e = nil
      b = PinkShoggoth
      g = GreenShoggoth
      r = Rock

      [
        [ g, e, e, e, e, e, e, b ],
        [ e, e, e, e, e, e, e, e ],
        [ e, e, e, e, e, e, e, e ],
        [ e, e, e, r, r, e, e, e ],
        [ e, e, e, r, r, e, e, e ],
        [ e, e, e, e, e, e, e, e ],
        [ e, e, e, e, e, e, e, e ],
        [ b, e, e, e, e, e, e, g ]
      ]
    end

    public
    def tileLayout
      e = [ ShoggothTile, [] ]
      v = [ VoidTile,     [] ]

      size = 8

      layout = Array.new(size)
      # Create rows and fill with EMPTY tiles.
      for i in 0...size
        layout[i] = Array.new(size, e)
      end

      @tilesLeft = size * size
      @tilesLeft -= 4 # Num rocks.

      return layout
    end

  end
end # module Shoggoth