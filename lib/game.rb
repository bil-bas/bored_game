# =============================================================================
# Bored Game
#
# By Bil Bas
# =============================================================================

require 'board'
require 'singleton'

# =============================================================================
#
#
class BasicGame
  attr_accessor :viewLastMove

  # ------------------------
  #
  #
  private
  def initialize(master, frame, infoFrame, sides, tileSize, pieceSize)

    @master, @infoFrame, @sides, @tileSize =
      master, infoFrame, sides, tileSize

    @currSide = @sides.last # It will move to the first one immediately
    @currSide.player = @currSide.player

    # Game is either run on one computer (hotseat) or over a network.
    @hotseat = (@currSide.player.instance_of? HotseatPlayer)

    @staleMate = false

    @board = Board.new(self, frame, tileSize, pieceSize, tileLayout, pieceLayout)
    @board.create
    @board.parent.recalc

    @winner = nil

    @viewLastMove = true

    @turnFrame = FXHorizontalFrame.new(@infoFrame, LAYOUT_FILL_X|LAYOUT_BOTTOM)
    @turnFrame.create

    @turnIconL = FXLabel.new(@turnFrame, '', nil, LAYOUT_LEFT)
    @turnIconL.create
    @turnInd = FXLabel.new(@turnFrame, 'Turn', nil,
                 LAYOUT_CENTER_X|LAYOUT_CENTER_Y)
    @turnInd.create
    @turnIconR = FXLabel.new(@turnFrame, '', nil, LAYOUT_RIGHT)
    @turnIconR.create

    @messageQueue = Array.new

    @busy = false

    startPhase
  end

  # ------------------------
  # Virtual functions
  #
  public;  def BasicGame.pieceLayout; raise; end # Must redefine.
  private; def staleMate?;            false; end # Default.
  public;  def press(at);                    end # Opt.
  public;  def canDrag?(at);                 end # Opt.
  public;  def initEdges(board);             end # Opt.

  # ------------------------
  # Start a phase within a side's turn.
  # Default is to start a turn for each phase.
  #
  private
  def startPhase
    nextTurn
    updateIndicators
  end

  private
  def nextTurn
    # Get next side...
    @currSide = @sides[((@sides.index @currSide) + 1).modulo(@sides.size)]
  end

  private
  def updateIndicators
    side = @currSide.name

    if @hotseat
      @turnInd.text = "#{side}'s turn"
    elsif @master.player == @currSide.player
      @turnInd.text = "Your turn (#{side})"
    else 
      @turnInd.text = "#{@currSide.player.name}'s turn (#{side})"
    end

    @turnIconL.icon = @turnIconR.icon = @currSide.icon
  end

  public
  def statusBar
    @master.statusBar
  end

  # ------------------------
  # currPiece?()
  # Does the piece belong to the current player?
  #
  private
  def currPiece?(piece)
    !piece.nil? && (piece.side == @currSide)
  end

  # ------------------------
  # enemyPiece?()
  # Does the piece belong anyone but the current player?
  #
  private
  def enemyPiece?(piece)
    !piece.nil? && (piece.side != @currSide)
  end

  # ------------------------
  #
  #
  public
  def endPhase
    @staleMate = staleMate?

    if @winner
      @turnIconL.icon = @turnIconR.icon = @winner.icon
      winSide = @winner.name
      if @hotseat
        @master.puts "#{winSide.upcase} WON THE GAME!"
        @turnInd.text = "#{winSide} won the game"
      elsif @winner == @master.player.side
        @master.puts "YOU WON THE GAME!"
        @turnInd.text = "You Won! (#{winSide} won)"
      else
        @master.puts "YOU LOST THE GAME!"
        @turnInd.text = "You Lost! (#{winSide} won)"
      end
      @master.gameEnded
    elsif @staleMate
      @turnIconL.icon = @turnIconR.icon = nil
      @master.puts "There is a stalemate!"
      @turnInd.text = "Stalemate!"
      @master.gameEnded
    else
      startPhase
    end
  end

  # ------------------------
  #
  #
  public
  def surrender
    @surrender = true

    if @hotseat
      @winner = opponent(@currSide.player)
      loser = @currSide.name
      @master.puts "#{loser} surrendered the game!"
      @turnInd.text = "#{loser} surrendered!"
    else
      @winner = opponent(@master.player)
      winSide = @winner.name
      @master.puts "You surrendered the game! (#{winSide} won)"
      @turnInd.text = "You surrendered! (#{winSide} won)"
    end
    @master.gameEnded
  end

  # ------------------------
  # Returns the opponent of whichever player is passed to it.
  #
  def opponent(player)
    @sides[0]
  end

  # ------------------------
  #
  #
  public
  def receive(message)
    # Store up messages if we are still animating last move.
    if @busy
#       @master.puts "queueing #{message}" # DEBUG
      @messageQueue.push message
    else
      processMessage message
    end
  end

  # ------------------------
  #
  #
  public
  def processMessage(message)
    source = @master.players[message.source]

    case message
      when MoveMsg
        fromTile = @board[message.from[0]][message.from[1]]
        toTile   = @board[message.to[0]][message.to[1]]
        path = findPath fromTile, toTile
  
        if path
          @board.animateMove fromTile, path
        else
          @master.puts "#{source.name} tried ILLEGAL MOVE from #{fromTile} to #{toTile}"
        end
  
      when PlaceMsg
        tile = @board[message.at[0]][message.at[1]]
        if legalPlace? tile
          placePiece tile
          endPhase
        else
          @master.puts "#{source.name} tried to PLACE a piece ILLEGALLY at #{tile}"
        end
  
      when SurrenderMsg
        @winner = @master.player.side
        @surrender = true
        @master.gameEnded
        @master.puts "#{source.name} surrendered the game! (#{@winner.name} won)"
    end

    return true # Stop processing (if taking messages off the queue).
  end

  # ------------------------
  #
  #
  public
  def startAnimatingAction
    @busy = true
  end

  # ------------------------
  #
  #
  public
  def endAnimatingAction
    # Remove and act on all the messages in the queue up until we
    # find one that prevents further action.
    stopProcessing = false
    while @messageQueue.size > 0 && !stopProcessing
      message = @messageQueue.shift
      stopProcessing = processMessage message
      @master.puts "Processing: #{message} (#{(stopProcessing)?"halting":"continuing"})" # DEBUG
    end

    updateIndicators

    @busy = false
  end

  # ------------------------
  #
  #  
  public
  def tick
    @board.animateMoveFrame unless @board.nil?
  end

  # ------------------------
  #
  # 
  public
  def cleanUp
    @board.cleanUp

    @board.parent.removeChild @board

    @turnFrame.parent.removeChild @turnFrame
 
    for side in @sides
      side.reset
    end
  end 
end

# =============================================================================
# Template for games where pieces initially on the board - moved by players
# E.g. Viking Game, Chess, etc.
#
class BasicMoveGame < BasicGame
  private; def findPath(from, to);      raise; end # Required
  private; def afterMove(from, to);        end # Opt

  # ------------------------
  # Called both by self and from opponent.
  #
  public
  def movePiece(from, to)
    fromTile = @board[from.column][from.row]
    piece = fromTile.piece

    toTile = @board[to.column][to.row]

    piece.moveTo(toTile)

    if @currSide.player == @master.player
      name = 'You'
    else
      name = @currSide.player.name
    end

    @master.puts "#{name} moved #{piece} from #{from} to #{to}."
  end

  # ------------------------
  # To check whether a given piece can be dragged.
  #
  public
  def canDrag?(piece)
    !@winner && !@staleMate && currPiece?(piece) &&
      (@hotseat || (@master.player == @currSide.player))
  end

  # ------------------------
  # dragDrop(Piece piece, Tile to)
  # Called when a dragged piece is released.
  #
  public
  def dragDrop(piece, to)
    from = piece.tile
    path = findPath(from, to)
    if path
      movePiece(from, to)
      @master.send MoveMsg.new(from, to)
      endPhase
    end
  end
end

# =============================================================================
# Template for games where pieces are played by each player.
# E.g. Go, Connect-4, 5-in-a-row games, O's & X's, etc
#
class BasicPlaceGame < BasicGame

  private; def legalPlace?(at); end
  private; def afterPlace(at);  end

  # ------------------------
  # placePiece()
  # Called both by self and from opponent.
  #
  public
  def placePiece(tile)
    # Create the first (and only) type of piece.
    piece = @board.createPiece(@currSide.defPiece, tile)

    # Check for change
    afterPlace(tile)

    if @currSide.player == @master.player
      name = 'You'
    else
      name = @currSide.player.name
    end

    @master.puts "#{name} placed #{piece} at #{tile}."
  end

  # ------------------------
  #
  public
  def press(at)
    return if @winner || @staleMate ||
      (!@hotseat && @master.player != @currSide.player)
    tile = @board[at.column][at.row]
    if legalPlace? tile
      placePiece tile
      @master.send PlaceMsg.new(tile)
      endPhase
    end
  end
end

# =============================================================================
# The icon is the one shown at the side when it is that player's turn.
# May have nothing to do with piece-icons.
#
class Side
  include Singleton

  attr_reader :name, :pieces, :defPiece, :icon, :defRotation
  attr_accessor :selected, :player

  private
  def initialize(name, defPiece, icon)
    @name, @defPiece, @icon = name, defPiece, icon

    @icon.create

    @player = nil
 
    @selected = false

    @defRotation = ROTATION_0

    @pieces = Array.new
  end

  public
  def Side.app=(app)
    @@app = app
  end

  public
  def addPiece(piece)
    @pieces.push piece
  end

  public
  def removePiece(piece)
    @pieces.delete piece
  end

  # ------------------------
  # Reset before an new game
  public
  def reset
    @pieces.clear
  end
end

# ---------------------------------------------------------------------------
#
class BasicGameInfo
  include Singleton

  attr_reader :sides

  # ------------------------
  #
  private
  def initialize(sides)
    @sides = sides

    for i in 0...minSides
      @sides[i].selected = true
    end
  end

  # ------------------------
  #
  public
  def selectedSides
    selected = Array.new
    for side in @sides
      selected.push side if side.selected
    end
    
    selected
  end
end