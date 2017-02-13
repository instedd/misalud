class Borough < Struct.new(:code, :name, :label)

  ALL = [
    [1, "manhattan", "Manhattan"],
    [2, "brooklyn", "Brooklyn"],
    [3, "queens", "Queens"],
    [4, "bronx", "The Bronx"],
    [5, "staten_island", "Staten Island"]
  ].map { |args| Borough.new(*args) }

  def self.all
    ALL
  end

  def self.[](index)
    if index.kind_of?(Numeric) || index =~ /\d+/
      all.find { |b| b.code == index.to_i }
    else
      all.find { |b| b.name == index }
    end
  end
end
