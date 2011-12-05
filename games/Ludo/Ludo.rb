# =============================================================================
# Bored Game
#
# By Bil Bas
#
# =============================================================================
require 'game'
require 'dice'
require 'fox16'
require 'singleton'

module Ludo

  IMAGE_DIR = "#{GAME_DIR}/Ludo/images"

  COLOUR_GREEN  = Fox::FXRGB(0x00, 0xFF, 0x00)
  COLOUR_RED    = Fox::FXRGB(0xFF, 0x00, 0x00)
  COLOUR_YELLOW = Fox::FXRGB(0xF0, 0xF0, 0x00)
  COLOUR_BLUE   = Fox::FXRGB(0x20, 0x20, 0xFF)


  COLOUR_BORDER    = Fox::FXRGB(0x00, 0x00, 0x00)
  COLOUR_PATH      = Fox::FXRGB(0xE0, 0xE0, 0xE0)
  COLOUR_OPEN_BASE = Fox::FXRGB(0xC0, 0xC0, 0xC0)
  # ---------------------------------------------------------------------------
  #
  class GameInfo < BasicGameInfo


    attr_reader :moduleName, :name, :title, :subTitle, :about, :game, :minSides

    # ------------------------
    #
    private
    def initialize
      @moduleName = "Ludo"
      @name = @title = "Ludo"

      @subTitle = "Ludo is a family game for 2-4 players"

      @about =<<END_OF_TEXT
What more is there to say? It _nearly_ rocks! I can't help myself.

That's all folks.
END_OF_TEXT

#       @about.gsub!(/\n\n/, "\n")

      @game = LudoGame

      sides = [
        GreenSide.instance,
        RedSide.instance,
        YellowSide.instance,
        BlueSide.instance
      ]
      @minSides = 2

      super sides
    end

  end

  # ===========================================================================
  class PathTile < OpenTile
    def draw(dc, x, y)
       # Outline
      dc.foreground = COLOUR_BORDER
      dc.fillRectangle x, y, @@size, @@size

      # Fill in with the colour of the OpenTile.
      dc.foreground = COLOUR_PATH
      dc.fillRectangle x + 1, y + 1, @@size - 2, @@size - 2

      super dc, x, y # Make sure any piece is drawn
    end
  end

  # ---------------------------------------------------------------------------
  class OpenBaseTile < OpenTile
    public
    def draw(dc, x, y)
      # Fill in
      dc.foreground = COLOUR_OPEN_BASE
      dc.fillRectangle x, y, @@size, @@size

      super dc, x, y # Make sure any piece is drawn
    end
  end

  # ---------------------------------------------------------------------------
  class ClosedBaseTile < ClosedTile
    attr_reader :side

    private
    def initialize(column, row, side)
      super column, row
      @side = side
    end

    public
    def draw(dc, x, y)
      # Fill in with the colour of the OpenTile.
      dc.foreground = side.colour
      dc.fillRectangle x, y, @@size, @@size
    end
  end


  # ===========================================================================
  #
  class HomeTile < OpenTile
  end
  # ---------------------------------------------------------------------------
  class CentreHomeTile < HomeTile
    # ------------------------
    #
    private
    def initialize(column, row)
      background = FXGIFImage.new(@@app,
                     File.open("#{IMAGE_DIR}/home.gif", "rb").read)
      background.create
  
      super column, row, background
    end
  end
  # ---------------------------------------------------------------------------
  class SideHomeTile < HomeTile

    attr_reader :side

    private
    def initialize(column, row, side)
      background = FXGIFImage.new(@@app,
                     File.open("#{IMAGE_DIR}/#{side.name}_home.gif", "rb").read)
      background.create

      @side = side
      super column, row, background
    end
  end

  # ===========================================================================
  # Counters may move here from the base with a 6.
  #
  class StartTile < OpenTile
    MARGIN = 15

    attr_reader :side

    private
    def initialize(column, row, side)
      @side = side

      super column, row

      side.startTile = self
    end

    public
    def draw(dc, x, y)
      # Outline
      dc.foreground = COLOUR_BORDER
      dc.fillRectangle x, y, @@size, @@size

      # Fill in with the colour of the OpenTile.
      dc.foreground = COLOUR_PATH
      dc.fillRectangle x + 1, y + 1, @@size - 2, @@size - 2

      # Draw A Mini icon.
      width = @@size - (MARGIN * 2)
      dc.foreground = COLOUR_BORDER
      dc.drawRectangle x + MARGIN, y + MARGIN, width, width

      # Fill in with the colour of the OpenTile.
      dc.foreground = side.colour
      dc.fillRectangle x + MARGIN + 1, y + MARGIN + 1,
                       width - 1, width - 1

      super dc, x, y # Make sure any piece is drawn over it.
    end
  end

  # ===========================================================================
  #
  class LudoPiece < Piece
    attr_reader :origin

    # ------------------------
    # 
    private
    def initialize(tile, icon, name, side)
      # Remember initial position, in case we get taken.
      @origin = tile

      @stack = nil

      super tile, icon, name, side

      side.addPiece self
    end

    # ------------------------
    # 
    public
    def capture
      moveTo @origin
    end

    # ------------------------
    # Arrive at central home tile. Removed from board.
    #
    public
    def home
      @tile.piece = nil
      @tile = nil
    end

    # ------------------------
    # 
    public
    def stack(piece)
      # Link to a piece that is 'on top of' this one.
      @stack = piece  
    end

    # ------------------------
    # 
    public
    def unstack(oldTile)
      if @stack
        # Put the stacked piece into the square, after we move on.
        oldTile.piece = @stack

        @stack = nil
      end
    end

    # ------------------------
    #
    STACK_OFFSET = 2
    public
    def draw(dc, x, y, isMoving = false)
      if @stack
        if isMoving
          super
        else
          @stack.draw dc, x - STACK_OFFSET, y - STACK_OFFSET
          super dc, x + STACK_OFFSET, y + STACK_OFFSET, isMoving
        end
      else
        super
      end
    end

    # ------------------------
    # 
    public
    def stacked?
      !@stack.nil?
    end
  end

  # ---------------------------------------------------------------------------
  #
  class GreenPiece < LudoPiece
    @@icon = nil

    private
    def initialize(tile, app)
      unless @@icon
        @@icon = FXGIFIcon.new(app,
          File.open("#{IMAGE_DIR}/green.gif", "rb").read)
        @@icon.create
        @@name = "a green counter"
      end

      super tile, @@icon, @@name, GreenSide.instance
    end
  end

  # ---------------------------------------------------------------------------
  #
  class RedPiece < LudoPiece
    @@icon = nil

    private
    def initialize(tile, app)
      unless @@icon
        @@icon = FXGIFIcon.new(app,
          File.open("#{IMAGE_DIR}/red.gif", "rb").read)
        @@icon.create
        @@name = "a red counter"
      end
      super tile, @@icon, @@name, RedSide.instance
    end
  end

  # ---------------------------------------------------------------------------
  #
  class YellowPiece < LudoPiece
    @@icon = nil

    private
    def initialize(tile, app)
      unless @@icon
        @@icon = FXGIFIcon.new(app,
                   File.open("#{IMAGE_DIR}/yellow.gif", "rb").read)
        @@icon.create
        @@name = "a yellow counter"
      end
      super tile, @@icon, @@name, YellowSide.instance
    end
  end

  # ---------------------------------------------------------------------------
  #
  class BluePiece < LudoPiece
    @@icon = nil

    private
    def initialize(tile, app)
      unless @@icon
        @@icon = FXGIFIcon.new(app,
                   File.open("#{IMAGE_DIR}/blue.gif", "rb").read)
        @@icon.create
        @@name = "a blue counter"
      end
      super tile, @@icon, @@name, BlueSide.instance
    end
  end

  # ===========================================================================
  #
  class LudoSide < Side
    attr_reader :colour
    attr_accessor :activePieces, :startTile

    INIT_COUNTERS = 4

    # ------------------------
    #
    private
    def initialize(name, defPiece, sideIcon, colour)
      @colour = colour

      @activePieces = Array.new

      super name, defPiece, sideIcon
    end

    public
    def addPiece(piece)
      @activePieces.push piece
    end
  end

  # ---------------------------------------------------------------------------
  #
  class GreenSide < LudoSide
    private
    def initialize
      greenIcon = FXGIFIcon.new(@@app,
        File.open("#{IMAGE_DIR}/green.gif", "rb").read)

      super 'Green', nil, greenIcon, COLOUR_GREEN
    end
  end
  # ---------------------------------------------------------------------------
  #
  class RedSide < LudoSide
    private
    def initialize
      redIcon = FXGIFIcon.new(@@app,
        File.open("#{IMAGE_DIR}/red.gif", "rb").read)

      super 'Red', nil, redIcon, COLOUR_RED
    end
  end
  # ---------------------------------------------------------------------------
  #
  class YellowSide < LudoSide
    private
    def initialize
      yellowIcon = FXGIFIcon.new(@@app,
         File.open("#{IMAGE_DIR}/yellow.gif", "rb").read)

      super 'Yellow', nil, yellowIcon, COLOUR_YELLOW
    end
  end
  # ---------------------------------------------------------------------------
  #
  class BlueSide < LudoSide
    private
    def initialize
      blueIcon = FXGIFIcon.new(@@app,
                   File.open("#{IMAGE_DIR}/blue.gif", "rb").read)

      super 'Blue', nil, blueIcon, COLOUR_BLUE
    end
  end

  # ===========================================================================
  #
  class LudoGame < BasicMoveGame
    # width/height in pixels
    TILE_SIZE = 40
    PIECE_SIZE = 28

    attr_reader :name

    # ------------------------
    #  
    private
    def initialize(master, canvas, infoFrame, sides)
      @name = "Ludo"

      @titleLabel = FXLabel.new(infoFrame, @name, nil,
                      LAYOUT_TOP|LAYOUT_FILL_X|FRAME_RAISED|FRAME_THICK)
      @titleLabel.font = FXFont.new(infoFrame.app, 'arial', 22, FONTWEIGHT_BOLD)
      @titleLabel.create

      @homeDisplay = HomeDisplay.new(infoFrame, LAYOUT_FILL_X|FRAME_SUNKEN)

      # A dice box to hold a maximum of 4 dice.
      @dice = DiceBox.new(infoFrame,
                LAYOUT_CENTER_X|LAYOUT_BOTTOM|FRAME_SUNKEN, 4)

      @passButton = FXButton.new(infoFrame, "Pass\tPass\tPass your turn",
        nil, nil, 0, BUTTON_OPTS|LAYOUT_BOTTOM|LAYOUT_CENTER_X, *BUTTON_DIMS)
      @passButton.connect(SEL_COMMAND, method(:onPassButton))
      @passButton.create

      app = canvas.app

      super master, canvas, infoFrame, sides, TILE_SIZE, PIECE_SIZE
    end

    # ------------------------
    #
    private
    def startPhase(forceTurn = false)
      # Don't move to next player if a six was the last die thrown.
      if @dice.last != 6 || forceTurn
        nextTurn
        @dice.clear
      end

      updateIndicators

      if @hotseat || (@currSide.player.instance_of? LocalPlayer)
        @dice.push rand(6) + 1
        @master.send DiceMsg.new(@dice.last) unless @hotseat

        pieces = @currSide.activePieces

        # Try to discover if there are any possible moves for any pieces.
        for piece in pieces
          tile = piece.tile
          if tile # On the board.
            if tile.instance_of? OpenBaseTile
              # Check if the piece can be moved onto the start pos.
              if @dice.last == 6
                pieceOnStart = piece.side.startTile.piece
                if pieceOnStart.nil? || !pieceOnStart.stacked?
                  @passButton.disable
                  return
                end
              end
            else
              # Check all the available paths to see if they can be used.
              paths = tile.paths @dice.last
              for path in paths
                if validMove? path
                  @passButton.disable
                  return
                end
              end
            end
          end
        end

        # Enable only if there are no moves to be made.
        @passButton.enable
      else
        # Not my go!
        @passButton.disable
      end


    end

    # ------------------------
    #
    public
    def canDrag?(piece)
      super # &&
#        ((@dice.last == 6 && @currSide.inactivePieces.include?(piece)) ||
#         (@currSide.activePieces.include?(piece)))
    end

    # ------------------------
    #
    public
    def onPassButton(*args)
      startPhase true
      @master.send PassMsg.new unless @hotseat
    end

    # ------------------------
    # Returns either the path of tiles which must be traversed to get to
    # 'to' - else nil if it cannot get through for some reason.
    # 
    private
    def findPath(from, to)
      return nil if to == from

      from = @board[from.column][from.row]
      to = @board[to.column][to.row]

      # Grab the path, if there is one (ignoring long paths).
      path = from.pathTo to, @dice.last

      # Deal with startup. Can move from base to start.
      if path.nil?
        if (from.instance_of? OpenBaseTile) &&
            ((to.instance_of? StartTile) && (to.side == @currSide))
          path = Path.new([ from, to ], 6) # Need a six to start.
        else
          return nil
        end
      end

      if path && (validMove? path)
        return path
      else
        return nil
      end
    end

    # ------------------------
    #
    #
    public
    def validMove?(path)
      to = path.last

      # Check that the counter can move exactly the right distance.
      return false unless path.distance == @dice.last

      # To home if own side's HomeTile or if it is the central home tile.
      if to.kind_of? HomeTile
        if to.instance_of? CentreHomeTile
          # If center - fail if the penultimate tile is in another side's home.
          return false unless path[-2].side == @currSide
        else
          return false unless to.side == @currSide
        end
      end

      # Check for stacked pieces blocking the path.
      for tile in path[1..-1] # Ignore start tile
        piece = tile.piece
        # Can never land on a stack!
        if piece && piece.stacked?
          return false
        end
      end

      return true
    end

    # ------------------------
    #
    #
    public
    def processMessage(message)
#       @master.puts "R: #{message.inspect}" # DEBUG

      case message
        when DiceMsg
          if @master.players[message.source] == @currSide.player
            # If we are waiting for a die then set it, otherwise store it.
#             if @expectDie
              if @dice.last != 6
                @dice.clear
              end
              @dice.push message.number
              @master.puts "#{@currSide.name} rolled a #{message.number}."
#             end
          end
          return false # Keep on processing messages from queue.

        when PassMsg
          if @master.players[message.source] == @currSide.player
            @master.puts "#{@currSide.name} passed."
            startPhase true # Always ends the turn.
          end
          return true # Stop processing messages from queue.

        else
          super

      end

    end

    # ------------------------
    # 
    public
    def movePiece(from, to)
      actor = from.piece
      target = to.piece

      if enemyPiece? target
        # A boney fido enemy piece!
        target.capture
      end

      super from, to

      actor.unstack @board[from.column][from.row] if actor.stacked?

      if currPiece? target
        # One of our own pieces - form a stack!
        actor.stack target
      elsif to.instance_of? CentreHomeTile
        actor.home
        num = @homeDisplay.addPiece actor.side
        @winner = @currSide if num == 4
      end
    end

    # ------------------------
    # get rid of the
    # 
    public
    def cleanUp
      super

      @titleLabel.parent.removeChild @titleLabel

      @homeDisplay.parent.removeChild @homeDisplay

      @passButton.parent.removeChild @passButton

      @dice.parent.removeChild @dice
    end

    # ------------------------
    #
    public
    def pieceLayout
      e = nil
      r = RedPiece
      y = YellowPiece
      g = GreenPiece
      b = BluePiece
      [
        [ e, e, e, e, e, e, e, e, e, e, e ],
        [ e, r, r, e, e, e, e, e, y, y, e ],
        [ e, r, r, e, e, e, e, e, y, y, e ],
        [ e, e, e, e, e, e, e, e, e, e, e ],
        [ e, e, e, e, e, e, e, e, e, e, e ],
        [ e, e, e, e, e, e, e, e, e, e, e ],
        [ e, e, e, e, e, e, e, e, e, e, e ],
        [ e, e, e, e, e, e, e, e, e, e, e ],
        [ e, g, g, e, e, e, e, e, b, b, e ],
        [ e, g, g, e, e, e, e, e, b, b, e ],
        [ e, e, e, e, e, e, e, e, e, e, e ]
      ]

#       size = 13
#       layout = Array.new(size)
#       for i in 0...size
#         layout.push Array.new(size, e)
#       end
#       layout
    end

    # ------------------------
    #
    public
    def tileLayout
      pa = [ PathTile, [] ]
      
      ob = [ OpenBaseTile, [] ]
      rb = [ ClosedBaseTile,  [ RedSide.instance    ] ]
      yb = [ ClosedBaseTile,  [ YellowSide.instance ] ]
      bb = [ ClosedBaseTile,  [ BlueSide.instance   ] ]
      gb = [ ClosedBaseTile,  [ GreenSide.instance  ] ]

      ch = [ CentreHomeTile, [] ]

      rh = [ SideHomeTile, [ RedSide.instance    ] ]
      yh = [ SideHomeTile, [ YellowSide.instance ] ]
      bh = [ SideHomeTile, [ BlueSide.instance   ] ]
      gh = [ SideHomeTile, [ GreenSide.instance  ] ]

      rs = [ StartTile, [ RedSide.instance    ] ]
      ys = [ StartTile, [ YellowSide.instance ] ]
      bs = [ StartTile, [ BlueSide.instance   ] ]
      gs = [ StartTile, [ GreenSide.instance  ] ]

      [
        [ rb, rb, rb, rb, pa, pa, pa, yb, yb, yb, yb ],
        [ rb, ob, ob, rb, pa, yh, ys, ob, ob, ob, yb ],
        [ rb, ob, ob, rb, pa, yh, pa, yb, ob, ob, yb ],
        [ rb, ob, rb, rb, pa, yh, pa, yb, yb, yb, yb ],
        [ pa, rs, pa, pa, pa, yh, pa, pa, pa, pa, pa ],
        [ pa, rh, rh, rh, rh, ch, bh, bh, bh, bh, pa ],
        [ pa, pa, pa, pa, pa, gh, pa, pa, pa, bs, pa ],
        [ gb, gb, gb, gb, pa, gh, pa, bb, bb, ob, bb ],
        [ gb, ob, ob, gb, pa, gh, pa, bb, ob, ob, bb ],
        [ gb, ob, ob, ob, gs, gh, pa, bb, ob, ob, bb ],
        [ gb, gb, gb, gb, pa, pa, pa, bb, bb, bb, bb ]
      ]

#       [
#         [ rb, rb, rb, rb, rb, pa, pa, pa, yb, yb, yb, yb, yb ],
#         [ rb, ob, ob, ob, rb, pa, yh, ys, ob, ob, ob, ob, yb ],
#         [ rb, ob, ob, ob, rb, pa, yh, pa, yb, ob, ob, ob, yb ],
#         [ rb, ob, ob, ob, rb, pa, yh, pa, yb, ob, ob, ob, yb ],
#         [ rb, ob, rb, rb, rb, pa, yh, pa, yb, yb, yb, yb, yb ],
#         [ pa, rs, pa, pa, pa, pa, yh, pa, pa, pa, pa, pa, pa ],
#         [ pa, rh, rh, rh, rh, rh, ch, bh, bh, bh, bh, bh, pa ],
#         [ pa, pa, pa, pa, pa, pa, gh, pa, pa, pa, pa, bs, pa ],
#         [ gb, gb, gb, gb, gb, pa, gh, pa, bb, bb, bb, ob, bb ],
#         [ gb, ob, ob, ob, gb, pa, gh, pa, bb, ob, ob, ob, bb ],
#         [ gb, ob, ob, ob, gb, pa, gh, pa, bb, ob, ob, ob, bb ],
#         [ gb, ob, ob, ob, ob, gs, gh, pa, bb, ob, ob, ob, bb ],
#         [ gb, gb, gb, gb, gb, pa, pa, pa, bb, bb, bb, bb, bb ]
#       ]
    end

    # ------------------------
    # Convert the board into a digraph. Each tile may have exits to other tiles.
    #
    public
    def initEdges(board)
      xx = [ ]

      ri = [[ 1,  0]]
      le = [[-1,  0]]
      up = [[ 0, -1]]
      dn = [[ 0,  1]]

      ur = up + ri
      ul = up + le
      dr = dn + ri
      dl = dn + le
      
      graph = [
        [ xx, xx, xx, xx, ri, dr, dn, xx, xx, xx, xx ],
        [ xx, xx, xx, xx, up, dn, dn, xx, xx, xx, xx ],
        [ xx, xx, xx, xx, up, dn, dn, xx, xx, xx, xx ],
        [ xx, xx, xx, xx, up, dn, dn, xx, xx, xx, xx ],
        [ ri, ri, ri, ri, up, dn, ri, ri, ri, ri, dn ],
        [ ur, ri, ri, ri, ri, xx, le, le, le, le, dl ],
        [ up, le, le, le, le, up, dn, le, le, le, le ],
        [ xx, xx, xx, xx, up, up, dn, xx, xx, xx, xx ],
        [ xx, xx, xx, xx, up, up, dn, xx, xx, xx, xx ],
        [ xx, xx, xx, xx, up, up, dn, xx, xx, xx, xx ],
        [ xx, xx, xx, xx, up, ul, le, xx, xx, xx, xx ]
      ]

      for column in 0...graph.size
        for row in 0...graph.size
          tile = board[column][row]
          edges = graph[row][column] # reverse!

          for exitCol, exitRow in edges
            target = board[column + exitCol][row + exitRow]
            tile.exits.push target
          end
        end
      end
    end
  end
  
  #
  # Display of pieces that have got home and left the board.
  class HomeDisplay < FXVerticalFrame
    BACKGROUND = FXRGB(0x99, 0x99, 0x99)

    private
    def initialize(*args)
      super(*args)

      clear

      @labels = Hash.new

      matrix = FXMatrix.new(self, 2,
                     MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)

      title = "HOME"
      font = FXFont.new(app, 'arial', 16, FONTWEIGHT_BOLD)

      sides = GameInfo.instance.sides
      for side in sides
        options = TEXT_BEFORE_ICON|LAYOUT_RIGHT|LAYOUT_CENTER_Y|
                    LAYOUT_FIX_HEIGHT|LAYOUT_FIX_WIDTH
        label = FXLabel.new(matrix, title[0].chr, side.icon, options,
                            0, 0, 50, 30)
        label.font = font
        title = title[1..4]
        
        @labels[side] = Array.new

        pieceFrame = FXHorizontalFrame.new(matrix, FRAME_SUNKEN)
        pieceFrame.backColor = BACKGROUND
        for i in 0..3
          label = FXLabel.new(pieceFrame, '', nil,
                    LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT, 0, 0, 32, 32)
          label.backColor = BACKGROUND
          @labels[side].push label
        end
      end

      create
    end

    # Returns the number of pieces of that colour.
    public
    def addPiece(side)
      @numPieces[side] += 1
      @labels[side][@numPieces[side] - 1].icon = side.icon

      return @numPieces[side]
    end

    # Returns the number of pieces of that colour.
    public
    def numPieces(side)
      return @numPieces[side]
    end

    public
    def clear
      @numPieces = Hash.new(0)
    end
  end


end

