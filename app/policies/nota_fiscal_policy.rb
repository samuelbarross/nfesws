class NotaFiscalPolicy < ApplicationPolicy

	def index?
		!User.expedicao.include? user
	end

	def show?
		!User.expedicao.include? user
	end

	def citacoes?
		User.expedicao.include? user or user.admin?
	end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
