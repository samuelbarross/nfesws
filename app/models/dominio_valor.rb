class DominioValor < ActiveRecord::Base
  belongs_to :dominio

  validates :codigo, presence: true
  validates :descricao, presence: true
end
