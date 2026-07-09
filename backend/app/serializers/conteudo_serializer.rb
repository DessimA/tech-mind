class ConteudoSerializer
  def initialize(conteudo)
    @c = conteudo
  end

  def as_json(*)
    {
      id: @c.id,
      titulo: @c.titulo,
      texto: @c.texto,
      categoria: @c.categoria,
      probabilidade: @c.probabilidade&.to_f,
      informacoes_adicionais: @c.informacoes_adicionais,
      status: @c.status,
      created_at: @c.created_at&.iso8601,
      updated_at: @c.updated_at&.iso8601
    }
  end
end
