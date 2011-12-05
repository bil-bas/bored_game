# =============================================================================
# Bored Game
#
# By Bil Bas
#
# =============================================================================

# ---------------------------------------------------------------------------
# Standard (six-sided) dice may be used in any game. Joy!
#
class DiceBox < FXPacker
  PADDING = 4
  CONTAINS = 4 # Maximum number of dice that can be held.
  COLOUR_BACKGROUND = FXRGB(0x99, 0x99, 0x99)

  private
  def initialize(parent, options, numDice)
    @icons = Array.new(6)
    for i in 0..5
      @icons[i] = FXGIFIcon.new(parent.app,
                    File.open("#{MAIN_IMAGE_DIR}/die_#{i + 1}.gif", "rb").read)
      @icons[i].create
    end

    @dice = Array.new # List of numbers on the dice.

    @iconSize = @icons[0].width

    super parent, options, 0, 0, 0, 0,
          PADDING, PADDING, PADDING, PADDING

    self.backColor = COLOUR_BACKGROUND

    @canvas = FXCanvas.new(self, self, 0, LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT,
                0, 0, ((numDice * (@iconSize + PADDING)) - PADDING), @iconSize)
    @canvas.connect(SEL_PAINT, method(:selPaint)) 

    create
  end

  # ------------------------
  # Repaint the dice we have.
  public
  def selPaint(sender, sel, event)
    FXDCWindow.new(@canvas, event) do |dc|
      dc.foreground = COLOUR_BACKGROUND
      dc.fillRectangle 0, 0, @canvas.width, @canvas.height
      for i in 0...@dice.size
        if i == (@dice.size - 1)
          dc.drawIcon @icons[@dice[i] - 1], i * (@iconSize + PADDING), 0
        else
         dc.drawIconShaded @icons[@dice[i] - 1], i * (@iconSize + PADDING), 0
        end
      end
    end
  end

  # ------------------------
  # Remove all displayed dice.
  public
  def clear
    @dice.clear
    @canvas.update
  end

  # ------------------------
  # Add another die (or several dice).
  public
  def push(*numbers)
    @dice.push(*numbers)
    @canvas.update
  end

  # ------------------------
  # Sum of all the dice in the box.
  #
  public
  def sum
    total = 0
    for i in @dice
      total += i
    end

    total
  end

  # ------------------------
  # Last die added.
  #
  public
  def last
    @dice.last
  end
end