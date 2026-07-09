@extends('layouts.app')

@section('title', $conteudo['titulo'])

@section('content')
    <div class="mb-6">
        <a href="{{ route('conteudos.index') }}" class="text-sm text-indigo-600 hover:text-indigo-800">&larr; Voltar</a>
    </div>

    <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <div class="p-6">
            <div class="flex items-start justify-between mb-4">
                <h1 class="text-2xl font-bold text-gray-900">{{ $conteudo['titulo'] }}</h1>
                <span class="px-3 py-1 rounded-full text-sm font-medium
                    @if ($conteudo['status'] === 'done') bg-green-50 text-green-700
                    @elseif ($conteudo['status'] === 'pending') bg-yellow-50 text-yellow-700
                    @elseif ($conteudo['status'] === 'processing') bg-blue-50 text-blue-700
                    @else bg-red-50 text-red-700 @endif">
                    {{ $conteudo['status'] }}
                </span>
            </div>

            <div class="prose prose-sm max-w-none text-gray-700 whitespace-pre-wrap mb-6">
                {{ $conteudo['texto'] ?? '' }}
            </div>

            @if ($conteudo['status'] === 'done')
                <div class="border-t border-gray-200 pt-6">
                    <h2 class="text-lg font-semibold text-gray-900 mb-4">Classificação</h2>

                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div class="bg-gray-50 rounded-lg p-4">
                            <p class="text-sm text-gray-500 mb-1">Categoria</p>
                            <p class="text-lg font-semibold text-indigo-600">{{ $conteudo['categoria'] }}</p>
                        </div>
                        <div class="bg-gray-50 rounded-lg p-4">
                            <p class="text-sm text-gray-500 mb-1">Probabilidade</p>
                            <p class="text-lg font-semibold text-gray-900">{{ number_format($conteudo['probabilidade'] * 100, 1) }}%</p>
                        </div>
                    </div>

                    @if (!empty($conteudo['informacoes_adicionais']))
                        <div class="mt-4">
                            <p class="text-sm text-gray-500 mb-2">Palavras-chave</p>
                            <div class="flex flex-wrap gap-2">
                                @foreach ($conteudo['informacoes_adicionais'] as $kw)
                                    <span class="px-2 py-1 bg-gray-100 text-gray-700 rounded text-xs font-medium">{{ $kw }}</span>
                                @endforeach
                            </div>
                        </div>
                    @endif
                </div>
            @elseif ($conteudo['status'] === 'pending')
                <div class="border-t border-gray-200 pt-6">
                    <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4 text-sm text-yellow-700">
                        Aguardando processamento. A classificação será feita em instantes.
                    </div>
                </div>
            @endif
        </div>

        <div class="bg-gray-50 px-6 py-3 border-t border-gray-200">
            <p class="text-xs text-gray-400">
                Criado em {{ \Carbon\Carbon::parse($conteudo['created_at'])->format('d/m/Y \à\s H:i') }}
                @if (!empty($conteudo['updated_at']) && $conteudo['updated_at'] !== $conteudo['created_at'])
                    &middot; Atualizado em {{ \Carbon\Carbon::parse($conteudo['updated_at'])->format('d/m/Y \à\s H:i') }}
                @endif
            </p>
        </div>
    </div>
@endsection
