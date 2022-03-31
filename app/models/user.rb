class User < ActiveRecord::Base
	enum role: [:normal_user, :admin]

	_arr_exp = ['expedicao.sp@datatransporte.com.br', 'gleison@transeconomica.com.br', 'ualerson@transeconomica.com.br', 'silgueiro.lima@gmail.com', 'expedicaofz@datatransporte.com.br', 'francisco@transeconomica.com.br', 'lindovanfernandes@hotmail.com']
	scope :expedicao, -> { where(email: _arr_exp) }

	# Include default devise modules. Others available are:
	# :confirmable, :lockable, :timeoutable and :omniauthable
	devise :database_authenticatable, :registerable,
	         :recoverable, :rememberable, :trackable, :validatable, :lockable

	has_many :usuario_empresas, :dependent => :destroy
	has_many :logs, :dependent => :destroy

	accepts_nested_attributes_for :usuario_empresas, :allow_destroy => true

	# after_create :lock_access!
end
