module Math
  # ------------------------
  # Convert degrees into radians
  #
  public
  def Math.deg2rad(degrees)
    degrees * PI / 180.0
  end

  # ------------------------
  # Convert radians into degrees.
  #
  public
  def Math.rad2deg(radians)
    radians * 180 / PI
  end

  # ------------------------
  # Rotate a set of coordinates, clockwise or anti-clockwise.
  # [rotation] should be given in radians.
  #
  public
  def Math.rotate(x, y, rotation)
    # Convert to a vector.
    theta = Math.atan2(x, y)
    magnitude = Math.hypot(x, y)

    # Rotate.
    theta += rotation

    # Convert back into coordinate system.
    x = magnitude * Math.sin(theta)
    y = magnitude * Math.cos(theta)

    return [ x.round, y.round ]

  end
end

# -----------------------------------------------------------------------------
# TEST
if __FILE__ == $0
  
  coords = [
    [0, 0],
    [0, 5], [5, 5], [5, 0], [5, -5],     # Around the clock
    [0, -5], [-5, -5], [-5, 0], [-5, 5], # Around the clock
    [5, 1000], [9999, 1], [9999, 9999],  # Big numbers
  ]
  
  for x, y in coords
    # Clockwise rotation.
    p [x, y,    0] unless Math.rotate(x, y, Math.deg2rad(0))   == [ x,  y]
  
    p [x, y,   90] unless Math.rotate(x, y, Math.deg2rad(90))  == [ y, -x]
    p [x, y,  180] unless Math.rotate(x, y, Math.deg2rad(180)) == [-x, -y]
    p [x, y,  270] unless Math.rotate(x, y, Math.deg2rad(270)) == [-y,  x]
  
    p [x, y,  360] unless Math.rotate(x, y, Math.deg2rad(360)) == [ x,  y]
  
    # Anti-clockwise rotation.
    p [x, y,   -0] unless Math.rotate(x, y, Math.deg2rad(-0))   == [ x,  y]
  
    p [x, y,  -90] unless Math.rotate(x, y, Math.deg2rad(-90))  == [-y,  x]
    p [x, y, -180] unless Math.rotate(x, y, Math.deg2rad(-180)) == [-x, -y]
    p [x, y, -270] unless Math.rotate(x, y, Math.deg2rad(-270)) == [ y, -x]
  
    p [x, y, -360] unless Math.rotate(x, y, Math.deg2rad(-360)) == [ x,  y]
  

    # Rotate clockwise by each possible degree.
    error = 1 # We don't mind being a couple of pixels out.

    for degrees in 0..360
      rads = Math.deg2rad degrees
      a, b = Math.rotate(x, y, rads)  # Rotate clockwise
      p, q = Math.rotate(a, b, -rads) # Rotate anti-clockwise the same amount
      if (p < x - error) || (p > x + error) || (q < y - error) || (q > y + error)  
        p "#{x}, #{y}, #{degrees}, #{p}, #{q}"
      end
    end
  end
end