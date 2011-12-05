# =============================================================================
# Bored Game
#
# By Bil Bas
#
# =============================================================================

require 'fox16'
include Fox

$:.push '../lib' # Add library to search path.

require 'player'
require 'connection'
require 'dialog'
require 'game'
require 'settings'
# require 'utility'

PROGRAM = 'Bored Game'
AUTHOR  = 'Bil Bas'

TIMEOUT_MS = 50 # means 20 ticks per second.
GAME_DIR  = '../games'
MAIN_IMAGE_DIR = '../images'

# Settings
SECT_PLAYER = 'player'
KEY_NAME = 'name'

SECT_INTERNET = 'internet'
KEY_ADDRESS = 'address'


# =============================================================================
# The controlling class of the program. It is mainly having to deal with dialog
# boxes and menus. Actual game stuff is completely held elsewhere.
#
class GameClientWindow < FXMainWindow
  attr_reader :root, :player, :players, :settings, :statusBar

  private
  def initialize(app)

    # Iconified icon (Mac only)
    @bigIcon = FXPNGIcon.new(app, File.open("#{MAIN_IMAGE_DIR}/icon.png", "rb").read)

    # Mini icon for top left corner of window.
    smallIcon = FXPNGIcon.new(app, File.open("#{MAIN_IMAGE_DIR}/mini_icon.png", "rb").read)

    super(app, PROGRAM, @bigIcon, smallIcon,
        DECOR_ALL|LAYOUT_MIN_WIDTH|LAYOUT_MIN_HEIGHT, 0, 0, 800, 550)

    connect(SEL_CLOSE) { # top right X pressed
      @settings.save if @settings.modified?
      0 # Allow game to end gracefully.
    }

    @connection = Connection.new(self)

    @settings = Settings.new

    @address = @settings.getString SECT_INTERNET, KEY_ADDRESS, "localhost"

    initMenus

    # Frames for layout
    fFlags = LAYOUT_FILL_X|LAYOUT_TOP
    fDimensions = [ 0, 0, 0, 0, 5, 5, 5, 5 ]

    @layoutFrame = FXVerticalFrame.new(self, fFlags|LAYOUT_FILL_Y|FRAME_NONE,
                     0, 0, 0, 0, 0, 0, 0, 0)

    # Status bar at the bottom.
    @statusBar = FXStatusBar.new(@layoutFrame,
                   LAYOUT_FILL_X|LAYOUT_BOTTOM|STATUSBAR_WITH_DRAGCORNER)

    # This frame is given to the Game to do stuff in.
    mainFrame = FXHorizontalFrame.new(@layoutFrame,
                   LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE, 200, 0)

    sideFrame = FXVerticalFrame.new(mainFrame,
                   LAYOUT_FILL_Y|LAYOUT_FIX_WIDTH,
                   0, 0, 250, 0, 0, 0, 0, 0)

    boardFrame = FXHorizontalFrame.new(mainFrame,
        fFlags|LAYOUT_FILL_Y|LAYOUT_RIGHT|FRAME_SUNKEN|FRAME_THICK,
        0, 0, 0, 0, 0, 0, 0, 0)

    @scrollWindow = FXScrollWindow.new boardFrame, 0,
        LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT

    # Make it fill up the space in its frame each time we resize.
    @scrollWindow.connect(SEL_CONFIGURE) {
      frameThickness = 4 # Otherwise scrollbars cover frame.
      @scrollWindow.resize @scrollWindow.parent.width - frameThickness,
                           @scrollWindow.parent.height - frameThickness
    }

    ioFrame = FXVerticalFrame.new(sideFrame,
                    FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_BOTTOM)

    # Type stuff in!!!
    @input = FXTextField.new(ioFrame, 50, nil, 0,
                      LAYOUT_BOTTOM|FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X)
    @input.disable

    # Textual frame for textual output.
    outputFrame = FXVerticalFrame.new(ioFrame,
        FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_BOTTOM,
        0, 0, 0, 0, 0, 0, 0, 0)
    @output = FXText.new(outputFrame, nil, 0,
        fFlags|TEXT_READONLY|TEXT_WORDWRAP|VSCROLLER_ALWAYS)
    @output.marginTop = @output.marginBottom = 2
    @output.marginLeft = @output.marginRight = 4
    @output.cursorColor = @output.backColor
    @output.visibleRows = 5
    outputFrame.backColor = @output.backColor
    

    @infoFrame = FXVerticalFrame.new(sideFrame, FRAME_NONE|LAYOUT_BOTTOM|LAYOUT_FILL_X)

    @player = DummyPlayer.new(@settings.getString(SECT_PLAYER, KEY_NAME, "Freddy"))

    @players = Hash.new # id => Player

    @output.appendText "Welcome to #{PROGRAM}.\nDo you want to play a game?"

    @game = nil

    # Require all the games in the dir 'games'
    begin
      Dir.new(GAME_DIR).each do |dir|
        unless dir =~ /\./ # Ignore . and ..
          require "#{GAME_DIR}/#{dir}/#{dir}.rb"
        end
      end
    end

    FXToolTip.new(app)

    Side.app = app

    # Start up the timer and chores.
    tick()
    processMsg nil, nil, nil
  end

  private
  def onQueryHelp(sender, sel, event)
    p sender, sel, event
    return 0
  end
 
  # ------------------------
  #
  private
  def initMenus()
    menuBar = FXMenuBar.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    initFileMenu    menuBar
    initGameMenu    menuBar
    initViewMenu    menuBar
    initOptionsMenu menuBar
    initHelpMenu    menuBar
  end      

  # ------------------------
  #
  private
  def initFileMenu(menuBar)
    # File Menu
    fileMenu = FXMenuPane.new(self)
    FXMenuTitle.new(menuBar, "&File", nil, fileMenu)

    text = "&Connect...\t\tConnect to a network game server"
    menu = FXMenuCommand.new(fileMenu, text)
    menu.connect(SEL_COMMAND, method(:connectDialog))

    text = "Start Game Server\t\tStart a network game server"
    menu = FXMenuCommand.new(fileMenu, text)
    #menu.connect(SEL_COMMAND, method(:startServer))
    menu.disable

    FXMenuSeparator.new(fileMenu)

    text = "&Load Game...\t\tLoad a previously saved game"
    menu = FXMenuCommand.new(fileMenu, text)
    #menu.connect(SEL_COMMAND, method(:loadGame))
    menu.disable

    text = "&Save Game\tCtrl-S\tSave the current game"
    menu = FXMenuCommand.new(fileMenu, text)
    #menu.connect(SEL_COMMAND, method(:saveGame))
    menu.disable

    text = "Save Game &As...\tAlt-Shift-S\tSave the current game with a different name"
    menu = FXMenuCommand.new(fileMenu, text)
    #menu.connect(SEL_COMMAND, method(:saveGameAs))
    menu.disable

    FXMenuSeparator.new(fileMenu)

    text = "&Quit\tCtrl-Q\tQuit the application"
    FXMenuCommand.new(fileMenu, text, nil, app, FXApp::ID_QUIT)

#     FXMenuSeparator.new(fileMenu)

#     text = "&Debug\t\t"
#     menu = FXMenuCommand.new(fileMenu, text, nil, app)
#     menu.connect(SEL_COMMAND) { p app.dumpWidgets }
  end

  # ------------------------
  #
  private
  def initGameMenu(menuBar)
    gameMenu = FXMenuPane.new(self)
    FXMenuTitle.new(menuBar, "&Game", nil, gameMenu)

    text = "&New Game...\t\tStart a new game"
    menu = FXMenuCommand.new(gameMenu, text)
    menu.connect(SEL_COMMAND, method(:newGameDialog))

    text = "&Restart Game\t\tRestart the game"
    menu = FXMenuCommand.new(gameMenu, text)
    menu.disable
#     menu.connect(SEL_COMMAND, method(:restartGame))

    FXMenuSeparator.new(gameMenu)

    text = "&Surrender...\t\tSurrender the current game"
    @surrenderMenu = FXMenuCommand.new(gameMenu, text)
    @surrenderMenu.connect(SEL_COMMAND, method(:surrenderDialog))
    @surrenderMenu.disable # We can't surrender unless we have a game running.
  end

  # ------------------------
  #
  private
  def initViewMenu(menuBar)
    viewMenu = FXMenuPane.new(self)
    FXMenuTitle.new(menuBar, "&View", nil, viewMenu)

    text = "&Status Bar\t\tToggle whether the status bar is visible"
    @statusTog = FXMenuCheck.new(viewMenu, text)
    @statusTog.connect(SEL_COMMAND, method(:statusToggle))
    @statusTog.check = true

    text = "&Board Coordinates\t\tToggle whether coordinates are seen on the board"
    @seeCoordsTog = FXMenuCheck.new(viewMenu, text)
    @seeCoordsTog.connect(SEL_COMMAND, method(:seeCoordsToggle))
    @seeCoordsTog.check = true
    @seeCoordsTog.disable

    text = "&Last Move\t\tToggle whether last move is shown"
    @lastMoveTog = FXMenuCheck.new(viewMenu, text)
    @lastMoveTog.connect(SEL_COMMAND, method(:lastMoveToggle))
    @lastMoveTog.check = true
    @lastMoveTog.disable
  end

  # ------------------------
  #
  private
  def initOptionsMenu(menuBar)
    optionMenu = FXMenuPane.new(self)
    FXMenuTitle.new(menuBar, "&Tools", nil, optionMenu)

    text = "&Preferences...\t\tSet personal preferences"
    menu = FXMenuCommand.new(optionMenu, text)
    #menu.connect(SEL_COMMAND, method(:preferences))
    menu.disable
  end

  # ------------------------
  #
  private
  def initHelpMenu(menuBar)
    helpMenu = FXMenuPane.new(self)
    FXMenuTitle.new(menuBar, "&Help", nil, helpMenu)

    menu = FXMenuCommand.new(helpMenu, "&Help...\t\tGeneral help topics")
    #menu.connect(SEL_COMMAND, method(:help))
    menu.disable

    FXMenuSeparator.new(helpMenu)

    text = "&About #{PROGRAM}...\t\tInformation about this program"
    menu = FXMenuCommand.new(helpMenu, text)
    menu.connect(SEL_COMMAND) {
      about = AboutDialog.new self, @bigIcon
      about.create
      about.execute
    }
  end

  # ------------------------
  # Create required resources.
  #
  public
  def create
    super  
    show(PLACEMENT_SCREEN) # Make us seen!
  end

  # ------------------------
  # Sends a Message to opponent.
  #
  public
  def send(message)
#      puts "S: #{message.inspect}" # DEBUG
    if @connection.connected?
      @connection.send message
    end
  end

  # ------------------------
  #
  private
  def tick(*args)
    @timeout = app.addTimeout TIMEOUT_MS, method(:tick)
    @game.tick unless @game.nil?
  end

  # ------------------------
  # Processes a message from opponent.
  # Registers a chore so that it will be called during GUI idle moments.
  #
  public
  def processMsg(sender, sel, event)

    # Register a new chore to call us when GUI is idle.
    app.addChore(method(:processMsg))

    # Interpret messages only if there are any in the queue.
    while message = @connection.nextMessage
  
      case message
        when SayMsg
          puts "<#{@players[message.source].name}> #{message.text}"
    
        when EmoteMsg
          puts ":#{@players[message.source].name} #{message.text}"
    
        when ChangeNameMsg
          puts "#{@players[message.source].name} has changed name to #{message.name}."
          @players[message.source].name = message.name
    
        when PingMsg
          if message.bounced
            took = ((Time.new - message.time).to_f * 1000).ceil
            from = (message.source == SERVER_ADDR) ? "server" : @players[message.source].name
            puts "Ping returned from #{from} after #{took} ms."
          else
            # Bounce it back.
            message.bounced = true
            message.source, message.dest = message.dest, message.source
            send message
          end
    
        when LoginMsg
          puts "#{message.name} has connected."
          @players[message.source] = RemotePlayer.new(message.name, message.source)
    
         when QuitMsg
            puts "#{@players[message.source].name} has quit."
            @players.delete message.source
      
         when DiedMsg
            puts "#{@players[message.source].name} has disconnected."
            @players.delete message.source
    
        when NewGameMsg
          ObjectSpace.each_object(Class) do |aClass|
            if aClass.to_s == (message.game + "::GameInfo")
              newGame aClass.instance, @players[message.source]
            end
          end
    
        when MoveMsg, PassMsg, PlaceMsg, SurrenderMsg, DiceMsg
          @game.receive message if @game
    
        when LoginOkMsg
          if @player.instance_of? LocalPlayer
            @player.id = message.num
          else
            @player = LocalPlayer.new(self, @input, @player.name, message.num)
          end
    
          @players.clear
    
          @players[message.num] = @player
    
          message.players.each_pair do |num, name|
            @players[num] = RemotePlayer.new(name, num)
          end
    
          puts "Logged in as player #{message.num} (#{@players.size - 1} " +
               "other player#{@players.size == 2 ? '':'s'})."
    
      end
    end
# p "processed!"
  end

  # ------------------------
  #
  #
  private
  def newGame(gameInfo, remoteCreator = nil)
    sides = gameInfo.selectedSides

    if remoteCreator.nil?
      puts "You started a game of #{gameInfo.name}."

      if @connection.connected?
        if players.size != sides.size
          puts "Wrong number of players! (#{sides.size} requested)."
          return
        end
        # Create an online game
        players = @players.values
        for i in 0...sides.size
          players[i].side = sides[i]
          sides[i].player = players[i]
        end
        send NewGameMsg.new(gameInfo)

     else
        # Get rid of the input line if we have disconnected.
        @player.cleanUp if @player.instance_of? LocalPlayer

        # Start up a local, Round-robin game.
        @players.clear
        for i in 0...sides.size
          @players[i] = HotseatPlayer.new(sides[i].name, i, sides[i])
        end
      end
    else
      players = @players.values
      for i in 0...sides.size
        players[i].side = sides[i]
        sides[i].player = players[i]
      end
      puts "Game of #{gameInfo.name} started remotely by #{remoteCreator.name}."
    end

    @game.cleanUp if @game

    # Remove the board from the @scrollWindow
    if content = @scrollWindow.contentWindow
      @scrollWindow.removeChild content
    end

    @game = gameInfo.game.new(self, @scrollWindow, @infoFrame, sides)

    @surrenderMenu.enable

    self.title = "#{PROGRAM} - #{gameInfo.name}"
  end

  # ------------------------
  # Forwards any textual output to the player's output.
  
  public
  def puts(*args)
    @output.appendText "\n" + args.join('\n'), false
    @output.makePositionVisible @output.getLength
  end

  # ------------------------
  public
  def connected?
    @connection.connected?
  end

  # ------------------------
  # Toggle the status bar visibility.
  #
  private
  def statusToggle(sender, sel, event)
    if @statusBar.shown?
      @statusTog.check = false
      @statusBar.hide
    else
      @statusTog.check = true
      @statusBar.show
    end

    # Make sure our change is updated.
    @layoutFrame.recalc
  end

  # ------------------------
  # Toggle the visibility of the board coordinates.
  #
  private
  def seeCoordsToggle(sender, sel, event)
    if @seeCoordsTog.checked?
      @seeCoordsTog.check = false
    else
      @seeCoordsTog.check = true
    end
  end

  # ------------------------
  # Toggle the last move indicator.
  #
  private
  def lastMoveToggle(sender, sel, event)
    if @lastMoveTog.checked?
      @lastMoveTog.check = false
      @game.viewLastMove = true
    else
      @lastMoveTog.check = true
      @game.viewLastMove = false
    end
  end
 
  # ------------------------
  # Open the options dialog.
  # Needs actually writing
  private
  def optionsDialog(sender, sel, event)
#     OptionsDialog.new(self, @player.name)
#     if (name.length > 1) && (name != @name)
#       if validName? name
#         puts "You have changed your name from #{@player.name} to #{name}."
#         @player.name = name
#         @settings.setString SECT_PLAYER, KEY_NAME, name
#         send ChangeNameMsg.new(name)
#       else
#         puts 'Bad choice of name, it may only contain letters, ' \
#                   ' numbers and the underscore character (_).'
#       end
#     end
  end

  # ------------------------
  # Name must start with a letter and contain letters, numbers and _
  #
  private
  def validName?(name)
    name =~ /^[a-zдец]\w+$/i
  end

  # ------------------------
  #
  private
  def connectDialog(sender, sel, event) 
    dialog = ConnectDialog.new(self, @player.name, @address) 

    result = dialog.execute

    if result
      if validName? result[0]
        if result[0] != @player.name
          @player.name = result[0]
          @settings.setString SECT_PLAYER, KEY_NAME, @player.name
        end
        if result[1] != @address
          @address = result[1]
          @settings.setString SECT_INTERNET, KEY_ADDRESS, @address
        end

        @connection.connect @address
      else
        puts "Invalid name."
      end
    end
  end

  # ------------------------
  #
  #
  private
  def surrenderDialog(sender, sel, event)
    dialog = SurrenderDialog.new self

    if dialog.execute != 0
      @game.surrender
      send SurrenderMsg.new
    end
  end

  # ------------------------
  # Game has ended, so update menus.
  #
  public
  def gameEnded()
    @surrenderMenu.disable
  end

  # ------------------------
  #
  #
  private
  def newGameDialog(sender, sel, event)
    dialog = GameDialog.new self

    gameInfo = dialog.execute

    if gameInfo
      newGame gameInfo
    end
  end
end

# =============================================================================
if __FILE__ == $0
  app = FXApp.new(PROGRAM, AUTHOR)

  app.disableThreads

  GameClientWindow.new(app)

  app.create
  
  app.run
end