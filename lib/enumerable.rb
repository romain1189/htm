module Enumerable
  def pmap(&block)
    futures = map { |elem| Celluloid::Future.new(elem, &block) }
    futures.map { |future| future.value }
  end
  alias_method :pcollect, :pmap

  def peach(&block)
    futures = map { |elem| Celluloid::Future.new(elem, &block) }
    futures.map { |future| future.value }
    self
  end
end
