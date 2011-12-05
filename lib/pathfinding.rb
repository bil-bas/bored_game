#-- ===========================================================================
#++
# == Pathfinding
# Discovers shortest paths.
# Utilises Dijkstra's algorithm which is an algorithm to find a shortest path.
#
# Author:: Bil Bas
# Date:: 14/09/03
#-- ===========================================================================

#-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#++ Stores an inclusive path of vertices and records the travel distance.
#
class Path < Array
  attr_reader :distance

  #
  #
  private
  def initialize(vertices, distance)
    super vertices
    @distance = distance
  end
end

#-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
class Vertex
  attr_accessor :exits

  private
  def initialize(entryCost = 1, exitCost = 0)
    @entryCost, @exitCost = entryCost, exitCost
    @exits = Array.new
  end

  # ------------------------
  # A shortest path from self to destination, limited only by maxDistance.
  #
  public
  def pathTo(destination, maxDistance = nil)
    paths = findPaths(destination, maxDistance)

    paths[destination]
  end

  # ------------------------
  # List of paths of a given length.
  #
  public
  def absolutePaths(distance)
    paths = findPaths(nil, distance)

    # Remove all those paths which are shorter than the absolute distance.
    paths.delete_if { |vertex, path| path.distance != distance }

    paths.values
  end

  # ------------------------
  # All paths from self, limited only by maxDistance.
  #
  public
  def paths(maxDistance = nil)
    findPaths(nil, maxDistance).values
  end

  # ------------------------
  #
  private
  def findPaths(destination, maxDistance)
    paths = Hash.new
    
    possiblePaths = Array.new

    paths[self] = Path.new([ self ], 0)

    vertices = [ self ]

    while vertices.size > 0
      # Stop if we have found dest. Clear us out so we only contain one path.
      destPath = paths[destination]
      break if destPath

#-- puts "Self: #{collect { |k,v| k + " => " + v.collect { |z| z}.join('-') + " (#{v.distance})"}.join(', ')}"

      vertices = addPaths vertices, paths, possiblePaths, maxDistance
    end

    if destination
      # Forget everything except the destination.
      paths.delete_if { |vertex, path| vertex != destination }
    end

    paths.delete self unless destination == self # Get rid of this, not relavent any more.

    return paths
  end

  # ------------------------
  # Adds all edges leaving vertex. Returns a list of the last vertex of
  # each added path.
  #
  private
  def addPaths(vertices, paths, possiblePaths, maxDistance)
    added = Array.new

    for vertex in vertices
      oldPath = paths[vertex]
      exitCost = vertex.exitCost
      if exitCost
        for target in vertex.exits
          # Only add if there isn't already a shortest path registered.
          if paths[target].nil?
            entryCost = target.entryCost
            if entryCost
              newPath = Path.new(oldPath + [ target ], oldPath.distance + exitCost + entryCost)
              possiblePaths.push newPath
            end
          end
        end
      end
    end

#-- puts "Possible before: #{@possible.collect { |path| path.collect { |f| f }.join('-') + " (#{path.distance})"}.join(', ')}"

    if possiblePaths.size > 0
      # Make sure shortest paths are at the front.
      possiblePaths.sort! { |a, b| a.distance <=> b.distance }

      # Remove all the edges which have the minimum path, returning the paths.
      distance = possiblePaths.first.distance

      # If we have over-reached the distance-horizon then that is that.
      if maxDistance && distance > maxDistance
        added.clear
      else
        # Put all of the minimum length paths into self & into added.
        while possiblePaths.size > 0 && possiblePaths.first.distance == distance
          addedPath = possiblePaths.shift
          addedVertex = addedPath.last

          added.push addedVertex
          paths[addedVertex] = addedPath
  
          # Remove all the other possible paths to the selected vertex
          possiblePaths.delete_if { |path| path.last == addedVertex }
        end
      end

#-- puts "Possible after: #{@possible.collect { |path| path.collect { |f| f }.join('-') + " (#{path.distance})"}.join(', ')}"

    end

#-- puts "Added: #{added.collect { |v| v }.join(', ')}"

    return added
  end

  public
  def entryCost(from = nil)
    @entryCost
  end

  def exitCost(to = nil)
    @exitCost
  end

end

# TESTING
if __FILE__ == $0
  class TestVertex < Vertex
    private
    def initialize(name, entryCost)
      @name = name
      super entryCost
    end

    private
    def to_s
      @name
    end
  end
    
  a = TestVertex.new('a', 5)
  b = TestVertex.new('b', 9)
  c = TestVertex.new('c', 7)
  d = TestVertex.new('d', 3)
  e = TestVertex.new('e', 12)

  a.exits = [ b, c, d ]
  b.exits = [ a, c, e ]
  c.exits = [ a, b, d, e ]
  d.exits = [ a, c, e ]
  e.exits = [ b, c, d ]

  start, finish = a, e

  puts
  puts "Pathfinding from #{start} with unlimited distance"
  start.paths.each { |path|
    puts "#{path.distance} to #{path.last} via " +
    "[ #{path.collect {|v| v}.join(', ')} ]"
  }

  puts
  puts '=' * 50

  for max in 0..20
    puts
    puts "Pathfinding from #{start} with max distance #{max}"
    start.paths(max).each { |path| 
      puts "#{path.distance} to #{path.last} via " + 
           "[ #{path.collect {|v| v}.join(', ')} ]"
    }
  end

  puts
  puts '=' * 50

  for target in [ a, b, c, d, e, TestVertex.new('f', 1) ]
    puts
    puts "Pathfinding from #{start} to #{target} with unlimited distance"
    path = start.pathTo(target)
    if path
      puts "#{path.distance} to #{target} via [ #{path.join(', ')} ]"
    else
      puts "Failed to find path"
    end
  end

  puts
  puts '=' * 50

  for max in 0..20
    puts
    puts "Pathfinding from #{start} to #{finish} with max distance #{max}"
    path = start.pathTo(finish, max)
    if path
      puts "#{path.distance} to #{finish} via [ #{path.join(', ')} ]"
    else
      puts "Failed to find path"
    end
  end

  puts
  puts '=' * 50

  for distance in 0..20
    puts
    puts "Pathfinding from #{start} with absolute distance #{distance}"
    start.absolutePaths(distance).each { |path| 
      puts "#{path.distance} to #{path.last} via " + 
           "[ #{path.collect {|v| v}.join(', ')} ]"
    }
  end

end