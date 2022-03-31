class Dominio < ActiveRecord::Base
  # has_many :dominio_valores
  has_many :dominio_valores, foreign_key: :dominio_id, class_name: DominioValor, :dependent => :destroy
  has_many :dominio_campos, foreign_key: :dominio_id, class_name: DominioCampo, :dependent => :destroy
  accepts_nested_attributes_for :dominio_valores, :dominio_campos, :allow_destroy => true

  validates :descricao, presence: true

  UNRANSACKABLE_ATTRIBUTES = ["created_at","updated_at"]

  def self.ransackable_attributes auth_object = nil
    (column_names - UNRANSACKABLE_ATTRIBUTES) + _ransackers.keys
  end

end
