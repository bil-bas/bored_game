# =============================================================================
# Bored Game
#
# By Bil Bas
#
# =============================================================================

# =============================================================================
class Settings < FXSettings
  SETTINGS_FILE = 'bored.ini'

  # ------------------------
  # Initialize by reading in the settings file.
  # A bug means that any parse errors will CRASH the program. 
  #
  private
  def initialize
    super
    parseFile SETTINGS_FILE, 99999
  end

  # ------------------------
  #
  #
  public
  def getString(section, key, default = '')
    readStringEntry section, key, default
  end

  # ------------------------
  #
  #
  public
  def setString(section, key, value)
    deleteEntry section, key
    writeStringEntry section, key, value
  end

  # ------------------------
  #
  #
  public
  def getBool(section, key, default = false)
    readBoolEntry section, key, false
  end

  # ------------------------
  #
  #
  public
  def setBool(section, key, value)
    deleteEntry section, key
    writeBoolEntry section, key, value
  end

  # ------------------------
  #
  #
  public
  def save
    unparseFile SETTINGS_FILE
  end
end
