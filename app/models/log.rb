class Log < ActiveRecord::Base
  belongs_to :user
  belongs_to :nota_fiscal
end
