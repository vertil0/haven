class Message < ApplicationRecord
  belongs_to :author, class_name: 'User'
  belongs_to :reciever, class_name: 'User'
end
