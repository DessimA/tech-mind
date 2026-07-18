FactoryBot.define do
  factory :user do
    nome { Faker::Name.name }
    sequence(:email) { |n| "usuario#{n}@exemplo.com" }
    password { "senha-segura-123" }
  end
end
