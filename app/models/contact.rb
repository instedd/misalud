class Contact < ApplicationRecord
  serialize :survey_data, JSON
end
