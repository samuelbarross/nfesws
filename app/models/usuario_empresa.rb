class UsuarioEmpresa < ActiveRecord::Base
  	belongs_to :user
  	belongs_to :empresa

	validates :user, presence: true
end
