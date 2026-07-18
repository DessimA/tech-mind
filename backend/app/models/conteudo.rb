class Conteudo < ApplicationRecord
  belongs_to :user

  enum :status, { pending: "pending", processing: "processing", done: "done", failed: "failed" }

  validates :titulo, presence: true, length: { minimum: 3, maximum: 200 }
  validates :texto, presence: true, length: { minimum: 10, maximum: 5000 }
end
