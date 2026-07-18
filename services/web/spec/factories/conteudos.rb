FactoryBot.define do
  factory :conteudo do
    user
    titulo { "Introdução ao #{Faker::Lorem.sentence(word_count: 2)}" }
    texto { "Neste artigo vamos explorar conceitos fundamentais sobre tecnologia e como aplicá-los em projetos reais de desenvolvimento de software. " * 3 }
    status { :processing }
  end
end
