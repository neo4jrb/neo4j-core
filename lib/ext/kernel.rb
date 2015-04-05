module Kernel
  def ergo(&b)
    if block_given?
      b.arity == 1 ? yield(self) : instance_eval(&b)
    else
      self
    end
  end
end
