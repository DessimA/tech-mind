module Cacheable
  extend ActiveSupport::Concern

  private

  # Tenta ler do cache. Se acertar, retorna o valor e marca @from_cache.
  # Se errar, executa o bloco, persiste o resultado no cache e retorna.
  def cached_conteudos(key)
    cached = Rails.cache.read(key)
    if cached
      @from_cache = true
      return cached
    end

    result = yield
    result = result.to_a if defined?(ActiveRecord::Relation) && result.is_a?(ActiveRecord::Relation)
    Rails.cache.write(key, result, expires_in: cache_ttl)
    result
  end

  # Invalida todos os caches de conteúdo do usuário atual.
  def invalidate_cache
    Rails.cache.delete_matched("#{cache_namespace}:*")
  rescue StandardError
    nil
  end

  def cache_user
    raise NotImplementedError, "implement #cache_user no controller"
  end

  def cache_namespace
    "conteudos:#{cache_user.id}"
  end

  def cache_ttl
    ENV.fetch("CACHE_TTL", 300).to_i
  end
end
