module HTM
  module Geometry
    class Point < Struct.new(:x, :y)

      # Iterates over self coordinates up to given point coordinates yielding
      # new coordinates
      #
      # @param [Point] point the other point object
      # @yieldparam [Integer] i the x coordinate yielded
      # @yieldparam [Integer] j the y coordinate yielded
      def through(point)
        x.upto(point.x) { |i| y.upto(point.y) { |j| yield(i, j) }}
      end
      alias_method :upto, :through

      # Compute the distance between self and given point
      #
      # @param [Point] point the other point
      # @return [Float] the distance
      def distance_from(point)
        width = point.x - x
        height = point.y - y

        Math.sqrt(width ** 2 + height ** 2)
      end
      alias_method :distance_to, :distance_from
    end
  end
end
