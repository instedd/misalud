class Integer
  def later
    Timecop.freeze(Time.now + self.seconds)
  end
end
