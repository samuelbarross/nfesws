class CronPolicy < ApplicationPolicy
	
	def index?
		user.normal_user?
	end	

	def show?
		user.normal_user?
	end	

  class Scope < Scope
    def resolve
      scope
    end
  end
end
