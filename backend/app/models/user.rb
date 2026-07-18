class User < ApplicationRecord
  has_secure_password

  has_many :conteudos, dependent: :destroy

  validates :nome,  presence: true, length: { maximum: 100 }
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    length: { maximum: 255 }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
end
