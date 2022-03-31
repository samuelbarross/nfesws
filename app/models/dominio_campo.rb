class DominioCampo < ActiveRecord::Base
  belongs_to :dominio

  validates :descricao, presence: true

end
