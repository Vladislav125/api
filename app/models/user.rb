class User < ApplicationRecord
    has_many_attached :files
end
