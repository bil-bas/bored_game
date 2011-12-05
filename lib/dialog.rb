# =============================================================================
# Bored Game
#
# By Bil Bas
#
# =============================================================================
BUTTON_OPTS = BUTTON_NORMAL|LAYOUT_FIX_WIDTH
BUTTON_DIMS  = [0, 0, 80, 0, 5, 5, 3, 3]

HEADING_OPTS = JUSTIFY_CENTER_X|FRAME_RIDGE|LAYOUT_FILL_X

# # =============================================================================
# # Redefine it so that we always place dialogs in the centre of the parent wind.
# #
# class FXDialogBox
#   public
#   def execute(arg)
#     super PLACEMENT_OWNER
#   end
# end

# # =============================================================================
# #
# #
# class TextDialog < FXDialogBox

#   private
#   def initialize(app, title, label)
#     super(app, title, DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE)

#     FXLabel.new(self, label, nil, LAYOUT_TOP)

#     @buttonFrame = FXHorizontalFrame.new(self, LAYOUT_CENTER_X|LAYOUT_BOTTOM|FRAME_NONE)
#   end

#   private
#   def addButton(text, sel)
#     FXButton.new(@buttonFrame, text, nil, self, sel, BUTTON_DEFAULT|BUTTON_OPTS, *BUTTON_DIMS)
#   end
# end

# # =============================================================================
# #
# #
# class YesNoDialog < TextDialog

#   private
#   def initialize(app, title, label, yesText, noText)
#     super(app, title, label)

#     addButton(yesText, FXDialogBox::ID_ACCEPT)
#     addButton(noText, FXDialogBox::ID_CANCEL)
#   end

#   # --------------------------
#   # Runs the dialog. Returns true if 'yes', false if 'no'
#   #
#   public
#   def execute
#     super(PLACEMENT_OWNER) != 0
#   end
# end

# # =============================================================================
# # Returns the value of the input field IF *yes* pressed (else 'nil').
# #
# class InputDialog < YesNoDialog

#   private
#   def initialize(app, title, label, yesText, noText, input)
#     @input = input

#     super(app, title, label, yesText, noText)

#     @inputField = FXTextField.new(self, 25, nil, 0,
#                                   FRAME_SUNKEN|FRAME_THICK|LAYOUT_TOP|LAYOUT_FILL_X)
#     @inputField.text = @input
#     @inputField.focus
#   end

#   # --------------------------
#   # Runs the dialog. Returns true if 'yes', false if 'no'
#   #
#   public
#   def execute
#     if super(PLACEMENT_OWNER)
#       @inputField.text
#     else
#       nil
#     end
#   end
# end

# =============================================================================
# Returns the value of the input field IF *yes* pressed (else 'nil').
#
class ConnectDialog < FXDialogBox
  # --------------------------
  #
  private
  def initialize(master, name, address)
    super master, "Connect", DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE

    FXLabel.new self, "Name of Player", nil, LAYOUT_TOP
    @nameField = FXTextField.new(self, 25, nil, 0,
        TEXTFIELD_ENTER_ONLY|FRAME_SUNKEN|FRAME_THICK|LAYOUT_TOP|LAYOUT_FILL_X)
    @nameField.text = name
    @nameField.focus

    FXLabel.new self, "IP Address of Server", nil, LAYOUT_TOP

    @addrField = FXTextField.new self, 25, nil, 0,
        TEXTFIELD_ENTER_ONLY|FRAME_SUNKEN|FRAME_THICK|LAYOUT_TOP|LAYOUT_FILL_X
    @addrField.text = address
#     @addrField.connect(SEL_FOCUSIN) { @connButt.grab }

    @buttonFrame = FXHorizontalFrame.new self,
                     LAYOUT_CENTER_X|LAYOUT_BOTTOM|FRAME_NONE
    FXButton.new @buttonFrame, 'Cancel', nil, self, FXDialogBox::ID_CANCEL,
        BUTTON_DEFAULT|BUTTON_OPTS, *BUTTON_DIMS


    @connButt = FXButton.new @buttonFrame, 'Connect', nil, self,
        FXDialogBox::ID_ACCEPT,
        BUTTON_INITIAL|BUTTON_DEFAULT|BUTTON_OPTS, *BUTTON_DIMS

  end

  # --------------------------
  # Runs the dialog.
  #
  public
  def execute
    if super(PLACEMENT_OWNER) != 0
      [@nameField.text, @addrField.text]
    else
      nil
    end
  end
end

# =============================================================================
#
class GameDialog < FXDialogBox
  # --------------------------
  #
  private
  def initialize(master)
    @master = master

    super(@master, "Select New Game", DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE,
          0, 0, 640, 480)

    frame = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y)

    topFrame = FXHorizontalFrame.new(frame, LAYOUT_FILL_X|LAYOUT_FILL_Y)

    treeFrame = FXVerticalFrame.new(topFrame, FRAME_SUNKEN|LAYOUT_FILL_Y)

    tree = FXTreeList.new(treeFrame, self, 0, TREELIST_BROWSESELECT|LAYOUT_FIX_WIDTH, 0, 0, 140)
    tree.numVisible = 100
    tree.connect(SEL_CHANGED) { |sender, sel, data|
      changeGame tree.getItemData(data)
    }

    treeFrame.backColor = tree.backColor

    node = nil

    # All the games in the dir 'games'
    Dir.new(GAME_DIR).sort.each do |dir|
      unless dir =~ /\./ # Ignore . and ..
        ObjectSpace.each_object(Module) do |mod|
          if mod.name == "#{dir}"
            gameInfo = mod::GameInfo.instance
            node = tree.appendItem(nil, gameInfo.title)
            tree.setItemData(node, gameInfo)
          end
        end
      end
    end

    @tabBook = FXTabBook.new(topFrame, nil, 0,
                 LAYOUT_RIGHT|LAYOUT_FILL_X|LAYOUT_FILL_Y)

    # About
    aboutTab   = FXTabItem.new(@tabBook, "&About", nil)
    aboutFrame = FXVerticalFrame.new(@tabBook, FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

    @aboutTitle = FXLabel.new(aboutFrame, "About", nil,
                    LABEL_NORMAL|LAYOUT_FILL_X|JUSTIFY_CENTER_X)
    @aboutTitle.font = FXFont.new(app, 'arial', 16, FONTWEIGHT_BOLD)

    @aboutBody = FXText.new(aboutFrame, nil, 0,
                   LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|TEXT_READONLY|TEXT_WORDWRAP)
    @aboutBody.backColor = frame.backColor

    # Options
    optionsTab = FXTabItem.new(@tabBook, "&Options", nil)
    optionsFrame = FXVerticalFrame.new(@tabBook, FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

    # Sides
    playersTab = FXTabItem.new(@tabBook, "&Players", nil)
    @playersFrame = FXVerticalFrame.new(@tabBook, FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

    FXHorizontalSeparator.new(frame, SEPARATOR_GROOVE|LAYOUT_FILL_X)

    # Buttons
    @buttonFrame = FXHorizontalFrame.new(frame, LAYOUT_CENTER_X|LAYOUT_BOTTOM|FRAME_NONE)

    FXButton.new(@buttonFrame, "Cancel", nil, self,
                 FXDialogBox::ID_CANCEL, BUTTON_DEFAULT|BUTTON_OPTS, *BUTTON_DIMS)

    @startButton = FXButton.new(@buttonFrame, "Start Game", nil, self,
      FXDialogBox::ID_ACCEPT, BUTTON_INITIAL|BUTTON_DEFAULT|BUTTON_OPTS, *BUTTON_DIMS)

    @gameInfo = nil
    @playersGrid = nil

    @sideSelectButtons = Array.new
    @whoComboBoxes = Array.new

    playerTopFrame = FXHorizontalFrame.new(@playersFrame)
    FXLabel.new(playerTopFrame, 'First Player')

    @firstCombo = FXComboBox.new(playerTopFrame, 16, nil, 0,
              LAYOUT_CENTER_Y|COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP)

    create # Need to create before we can affect the tree.

    changeGame tree.getItemData(tree.firstItem) # Load up tabs for first item.
  end

  # --------------------------
  #
  private
  def changeGame(gameInfo)
    @gameInfo = gameInfo
    @aboutTitle.text = @gameInfo.title
    @aboutBody.text = @gameInfo.about

    if @playersGrid
      @playersGrid.parent.removeChild @playersGrid
    end
    @playersGrid = FXMatrix.new(@playersFrame, 3,
                     MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @playersGrid.create

    @sideSelectButtons.clear
    @whoComboBoxes.clear

    @firstCombo.clearItems
    @firstCombo.numVisible = @gameInfo.sides.size + 1
    @firstCombo.appendItem("Random", nil)
    
    minSides = @gameInfo.minSides
    maxSides = @gameInfo.sides.size

    # Headings.
    headingFont = FXFont.new(app, 'arial', 10, FONTWEIGHT_BOLD)
    [ "Side", "Selected", "Player" ].each do |title|
      heading = FXLabel.new(@playersGrid, title, nil, HEADING_OPTS)
      heading.font = headingFont
      heading.create
    end

    # Player/Side selection.
    for side in @gameInfo.sides
      # Side
      label = FXLabel.new(@playersGrid, side.name, side.icon, 
                          ICON_BEFORE_TEXT|LAYOUT_LEFT|LAYOUT_TOP)
      label.create

      @firstCombo.appendItem(side.name, side)

      # Selected to play?
      button = FXCheckButton.new(@playersGrid, '', nil, 0,
        LAYOUT_CENTER_Y|LAYOUT_CENTER_X)
      button.connect(SEL_COMMAND) { updateStartButton }
      button.create

      if minSides == maxSides
        # All sides must therefore be selected.
        button.disable
      end

      button.checkState = side.selected
      @sideSelectButtons.push button

      if @master.connected?
        # Who will play?
        players = @master.players.values
        combo = FXComboBox.new(@playersGrid, 16, (players.size + 1), nil, 0,
                  LAYOUT_CENTER_Y|COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP)

        combo.appendItem("Noone", nil)
        for player in players
          combo.appendItem(player.name, player)
        end
        combo.connect(SEL_COMMAND, method(:updateStartButton))
        combo.create

        @whoComboBoxes.push combo
      else
        combo = FXComboBox.new(@playersGrid, 16, nil, 0,
                  LAYOUT_CENTER_Y|COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP)

        combo.appendItem("Hotseat", nil)
        combo.disable
        combo.create
        @whoComboBoxes.push combo
      end

    end

    updateStartButton

    @playersFrame.recalc
  end

  # --------------------------
  #
  private
  def updateStartButton(*args)
    numSides = 0
    sides = @gameInfo.sides

    for i in 0...@sideSelectButtons.size
      if @sideSelectButtons[i].checked?
        numSides += 1
        sides[i].selected = true
      else
        sides[i].selected = false
      end
    end

    if numSides >= @gameInfo.minSides
      @startButton.enable
    else
      @startButton.disable
    end
  end

  # --------------------------
  #
  private
  def updateFirstPlayer(*args)
    old = @firstPlayer

    for i in 0...@firstPlayerButtons.size
      if @firstPlayerButtons[i].checked?
        if i == old
          @firstPlayerButtons[i].checkState = false
        else
          @firstPlayer = i
        end        
      end
    end
  end


  # --------------------------
  #
  public
  def execute
    if super(PLACEMENT_OWNER)!= 0
      return @gameInfo
    else
      return nil
    end
  end
end

# =============================================================================
#
class AboutDialog < FXDialogBox
  # --------------------------
  #
  private
  def initialize(master, icon)
    super(master, "About #{PROGRAM}", DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE,
      0, 0, 0, 0, 6, 6, 6, 6, 4, 4)

    frame = FXHorizontalFrame.new self, LAYOUT_TOP

    # Just an icon
    FXLabel.new frame, '', icon, LAYOUT_LEFT|LAYOUT_TOP

    # Frame contains textual details.
    frame2 = FXVerticalFrame.new frame, LAYOUT_RIGHT

    prog = FXLabel.new frame2, PROGRAM, nil, LAYOUT_TOP|JUSTIFY_LEFT
    prog.font = FXFont.new(app, "arial", 14, FONTWEIGHT_BOLD)

    details = FXLabel.new frame2,
        "A generic board game client\n\nby #{AUTHOR} @2003\n\n" +
        "Running under:\n    FXRuby #{Fox.fxrubyversion}\n" +
        "    FOX #{Fox.fxversion}",
        nil, JUSTIFY_LEFT

    FXButton.new self, 'OK', nil, self,
        FXDialogBox::ID_ACCEPT,
        LAYOUT_CENTER_X|BUTTON_INITIAL|BUTTON_DEFAULT|BUTTON_OPTS, *BUTTON_DIMS
  end

  # --------------------------
  #
  public
  def execute
    super PLACEMENT_OWNER
  end
end

# =============================================================================

#
class SurrenderDialog < FXDialogBox
  # --------------------------
  #
  private
  def initialize(master)
    super master, "Surrender", DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE

    FXLabel.new self, "Really surrender the game?", nil, LAYOUT_TOP

    @buttonFrame = FXHorizontalFrame.new self,
                     LAYOUT_CENTER_X|LAYOUT_BOTTOM|FRAME_NONE
    FXButton.new @buttonFrame, 'Cancel', nil, self, FXDialogBox::ID_CANCEL,
        BUTTON_DEFAULT|BUTTON_OPTS, *BUTTON_DIMS


    @connButt = FXButton.new @buttonFrame, 'Surrender', nil, self,
        FXDialogBox::ID_ACCEPT,
        BUTTON_INITIAL|BUTTON_DEFAULT|BUTTON_OPTS, *BUTTON_DIMS
  end

  # --------------------------
  #
  public
  def execute
    super PLACEMENT_OWNER
  end
end