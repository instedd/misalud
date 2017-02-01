class MessageResponder
  module Helper
    def reply_to(body)
      responder = MessageResponder.new
      yield responder
      responder.reply(body)
    end
  end

  def initialize
    @blocks = []
  end

  def yes(&block)
    @blocks << [/yes/i, block]
  end

  def no(&block)
    @blocks << [/no/i, block]
  end

  def digit(from, to, &block)
    (from..to).each do |num|
      @blocks << [Regexp.new("#{num}"), -> { block.call(num) } ]
    end
  end

  def otherwise(&block)
    @otherwise_block = block
  end

  def reply(body)
    @blocks.each do |regex, stmt|
      if body =~ regex
        stmt.call
        return
      end
    end

    @otherwise_block.call if @otherwise_block
  end
end

