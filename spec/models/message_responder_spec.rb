require 'rails_helper'

include MessageResponder::Helper

def is_a_yes?(content)
  is_a_yes = false
  reply_to(content) do |r|
    r.yes { is_a_yes = true }
  end
  is_a_yes
end

def is_a_no?(content)
  is_a_no = false
  reply_to(content) do |r|
    r.no { is_a_no = true }
  end
  is_a_no
end

def is_digit?(from, to, content)
  digit = nil
  reply_to(content) do |r|
    r.digit(from, to) { |d| digit = d }
  end
  digit
end

def is_otherwise?(content)
  otherwise = false
  reply_to(content) do |r|
    r.yes { }
    r.no { }
    r.digit(0, 9) { }
    r.otherwise { otherwise = true }
  end
  otherwise
end

RSpec.describe MessageResponder, type: :model do
  it { expect(is_a_yes?("yes")).to eq(true) }
  it { expect(is_a_yes?("Yes")).to eq(true) }
  it { expect(is_a_yes?("   YES   ")).to eq(true) }
  it { expect(is_a_yes?("   no   ")).to eq(false) }

  it { expect(is_a_no?("no")).to eq(true) }
  it { expect(is_a_no?("No")).to eq(true) }
  it { expect(is_a_no?("   NO   ")).to eq(true) }
  it { expect(is_a_no?("   yes   ")).to eq(false) }

  it { expect(is_digit?(1, 5, "1")).to eq(1) }
  it { expect(is_digit?(1, 5, "3")).to eq(3) }
  it { expect(is_digit?(1, 5, "5")).to eq(5) }
  it { expect(is_digit?(1, 5, "6")).to eq(nil) }
  it { expect(is_digit?(1, 5, "0")).to eq(nil) }
  it { expect(is_digit?(1, 5, "a")).to eq(nil) }

  it { expect(is_otherwise?("foo")).to eq(true) }
  it { expect(is_otherwise?("yes")).to eq(false) }
  it { expect(is_otherwise?("no")).to eq(false) }
  it { expect(is_otherwise?("4")).to eq(false) }
end


