#!/bin/bash
set -e

echo "=== Aguardando PostgreSQL ==="
until bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" 2>/dev/null; do
  echo "PostgreSQL não está pronto ainda..."
  sleep 2
done
echo "PostgreSQL está pronto!"

echo "=== Executando migrations ==="
bundle exec rails db:migrate 2>&1 || echo "Nenhuma migration pendente"

echo "=== Iniciando servidor ==="
exec "$@"
