module Pig
  class RedactorImageUpload < ActiveRecord::Base

    dragonfly_accessor :file
    validates_property :format, of: :file, in: ['jpeg', 'png', 'gif']
    validates :file, presence: true

    def image
      file_type == 'image' ? file : nil
    end
  end
end
