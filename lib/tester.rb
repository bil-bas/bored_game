require 'fox'
include Fox

# reg = FXRegistry.new("Game", "bil")
# reg.asciiMode = true

# reg.writeStringEntry("frog", "pee", "jolly")
# reg.writeStringEntry("frog", "knee", "jim")
# reg.writeStringEntry("kibble", "height", "jim")
# reg.write

# reg.read
# # reg.unparseFile "registry"

# # reg.parseFile "registry", 5000

# p reg.readStringEntry("frog", "pee", '')
# p reg.readStringEntry("frog", "knee", '')
# p reg.readStringEntry("kibble", "knee", '')
# p reg.readStringEntry("crap", "knee", '')


#   def [](section)
#     @section = section
#     self
#   
#   end

#   def [](value)
#     [self, self, self]
#   end

# p self[1][1]

# settings["frog"]["stencil"] = 

# set = FXSettings.new

# set.writeStringEntry "frog", "jim", "kill!"

# p set.readStringEntry("frog", "jim", 'fail')

# set.unparseFile "test.ini"

# set.parseFile "test.ini", 9999

# set.writeStringEntry "frog", "jim", "live!"

# p set.readStringEntry("frog", "jim", 'fail')


# class Fish

# end

# class Trout < Fish
#   attr_reader :frog
#   FROG = "fred"
# end

# class Minnow < Fish
#   attr_reader :frog
#   def initialize
#     @frog = "fred"
#   end
# end

# trout = Trout.new
# minnow = Minnow.new

# p trout.frog
# p minnow.frog

# p trout.FROG
# s = []
# puts "#{(s.inspect)}"

# arr = [0,1,2]

# p arr[1..-8]

# class Nob
#   def fish
#     "frog"
#   end
# end

# n = Nob.new

# p n.method(:fish)


#   ROTATION_0 = 0
#   ROTATION_90 = 1
#   ROTATION_180 = 2
#   ROTATION_270 = 3


# @rotation = ROTATION_0
# @tileSize = 10
# @numColumns = 4
# @numRows = 4
#   # ------------------------
#   #
#   public
#   def xy2Tile(x, y)
#     maxX, maxY = 40, 40
#     case @rotation
#       when ROTATION_0:
#         # No rotation

#       when ROTATION_90:
#         x, y = maxX - y, x

#       when ROTATION_180:
#         x, y = maxX - x, maxY - y

#       when ROTATION_270:
#         x, y = y, maxY - x

#     end
#    
#     column = [(x / @tileSize).floor, @numColumns - 1].min
#     row = [(y / @tileSize).floor, @numRows - 1].min

#     [ column, row ]
#   end

#   # ------------------------
#   #
#   public
#   def tile2xy(column, row)
#     maxCol, maxRow = 3, 3
#     case @rotation
#       when ROTATION_0:
#         # No rotation

#       when ROTATION_90:
#         column, row = row, maxCol - column

#       when ROTATION_180:
#         column, row = maxCol - column, maxRow - row

#       when ROTATION_270:
#         column, row = maxCol - row, column

#     end

#     x = column * @tileSize
#     y = row * @tileSize
#     [ x, y ]
#   end

# p tile2xy(0, 0)
# p tile2xy(3, 4)

# p xy2Tile(25, 35)
# p xy2Tile(0, 9)

# @rotation = ROTATION_90
# puts
# p tile2xy(0, 0)
# p tile2xy(3, 4)

# p xy2Tile(25, 35)
# p xy2Tile(0, 9)

# x, y = [1, 2]

# p x, y

# tr