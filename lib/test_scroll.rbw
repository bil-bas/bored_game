# =============================================================================
# Bored Game
#
# By Bil Bas
#
# =============================================================================

TYGER = <<END_OF_POEM
The Tyger

Tyger! Tyger! burning bright
In the forests of the night
What immortal hand or eye
Could frame thy fearful symmetry?

In what distant deeps or skies
Burnt the fire of thine eyes?
On what wings dare he aspire?
What the hand dare seize the fire?

And what shoulder, and what art,
Could twist the sinews of thy heart,
And when thy heart began to beat,
What dread hand? and what dread feet?

What the hammer? what the chain?
In what furnace was thy brain?
What the anvil? what dread grasp
Dare its deadly terrors clasp?

When the stars threw down their spears,
And water'd heaven with their tears,
Did he smile his work to see?
Did he who made the Lamb make thee?

Tyger! Tyger! burning bright
In the forests of the night,
What immortal hand or eye,
Dare frame thy fearful symmetry?



               - William Blake
END_OF_POEM

require 'fox'
include Fox

class ClientWindow < FXMainWindow

  attr_reader :root, :player, :players, :settings, :statusBar

  private
  def initialize(app)

    super(app, "Test Prog", nil, nil, DECOR_ALL, 0, 0, 300, 300)

    win = FXHorizontalFrame.new(self, FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

    scrollwindow = FXScrollWindow.new(win, 0)
    btn = FXButton.new(scrollwindow, TYGER, nil, nil, 0,
      LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT, 0, 0, 600, 1000)
    btn.backColor = FXRGB(255,255,255)

#     connect(SEL_UPDATE) {
#       recalc
#       p [@frame.width, @frame.height, @scroll.width, @scroll.height]
#       p [@scroll.viewportWidth, @scroll.viewportHeight, @scroll.contentWidth, @scroll.contentHeight]
#       p [@scroll.contentWindow.width, @scroll.contentWindow.height]
#       p [@scroll, @scroll.contentWindow, @frame]
#     }

  end

  # ------------------------
  # Create required resources.
  #
  public
  def create
    super  
    show(PLACEMENT_SCREEN) # Make us seen!
  end
end

# =============================================================================
if __FILE__ == $0
  app = FXApp.new("PROG", "BIL")

  ClientWindow.new(app)

  app.create
  
  app.run
end