class DominioPolicy < ApplicationPolicy

	def index?
		user.admin?
	end	

	def edit?
		user.admin?
	end	

	def create?
		user.admin?
	end		

  class Scope < Scope
    def resolve
      scope
    end
  end
end
