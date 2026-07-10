@extends('layouts.app')

@section('title', 'Conteúdos')

@section('content')
    <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold text-gray-900">Conteúdos</h1>
        <a href="{{ route('conteudos.create') }}" class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 text-sm font-medium">
            + Novo Conteúdo
        </a>
    </div>

    <form method="GET" action="{{ route('conteudos.index') }}" class="mb-6 flex gap-2">
        <input type="text" name="q" value="{{ request('q') }}" placeholder="Buscar por título ou palavra-chave..."
               class="flex-1 px-4 py-2 border border-gray-300 rounded-lg text-sm focus:ring-indigo-500 focus:border-indigo-500">
        <select name="sort" class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-indigo-500 focus:border-indigo-500">
            <option value="created_at_desc" @selected(request('sort') === 'created_at_desc')>Mais recentes</option>
            <option value="created_at_asc" @selected(request('sort') === 'created_at_asc')>Mais antigos</option>
            <option value="titulo_asc" @selected(request('sort') === 'titulo_asc')>Título A-Z</option>
        </select>
        <button type="submit" class="px-4 py-2 bg-gray-100 border border-gray-300 rounded-lg text-sm text-gray-700 hover:bg-gray-200">
            Buscar
        </button>
    </form>

    @if (!empty($error))
        <div class="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
            {{ $error }}
        </div>
    @endif

    @if (empty($conteudos))
        <div class="text-center py-12 bg-white rounded-lg border border-gray-200">
            <p class="text-gray-500">Nenhum conteúdo cadastrado ainda.</p>
            <a href="{{ route('conteudos.create') }}" class="mt-2 inline-block text-indigo-600 hover:text-indigo-700">
                Cadastre o primeiro conteúdo
            </a>
        </div>
    @else
        <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Título</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Categoria</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Data</th>
                        <th class="px-6 py-3"></th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                    @foreach ($conteudos as $c)
                        <tr class="hover:bg-gray-50">
                            <td class="px-6 py-4 text-sm font-medium text-gray-900">{{ $c['titulo'] }}</td>
                            <td class="px-6 py-4 text-sm text-gray-500">
                                @if ($c['status'] === 'done')
                                    <span class="px-2 py-1 bg-indigo-50 text-indigo-700 rounded-full text-xs font-medium">
                                        {{ $c['categoria'] }}
                                    </span>
                                @else
                                    <span class="text-gray-400">—</span>
                                @endif
                            </td>
                            <td class="px-6 py-4">
                                @if ($c['status'] === 'pending')
                                    <span class="px-2 py-1 bg-yellow-50 text-yellow-700 rounded-full text-xs font-medium">Pendente</span>
                                @elseif ($c['status'] === 'processing')
                                    <span class="px-2 py-1 bg-blue-50 text-blue-700 rounded-full text-xs font-medium">Processando</span>
                                @elseif ($c['status'] === 'done')
                                    <span class="px-2 py-1 bg-green-50 text-green-700 rounded-full text-xs font-medium">Concluído</span>
                                @else
                                    <span class="px-2 py-1 bg-red-50 text-red-700 rounded-full text-xs font-medium">Falhou</span>
                                @endif
                            </td>
                            <td class="px-6 py-4 text-sm text-gray-500">
                                {{ \Carbon\Carbon::parse($c['created_at'])->format('d/m/Y H:i') }}
                            </td>
                            <td class="px-6 py-4 text-right">
                                <a href="{{ route('conteudos.show', $c['id']) }}" class="text-indigo-600 hover:text-indigo-800 text-sm font-medium">
                                    Detalhes
                                </a>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>

        @if (($meta['total_pages'] ?? 1) > 1)
            <div class="mt-6 flex justify-center space-x-2">
                @for ($i = 1; $i <= $meta['total_pages']; $i++)
                    <a href="{{ route('conteudos.index', ['page' => $i]) }}"
                       class="px-3 py-2 rounded-md text-sm {{ $i == ($meta['current_page'] ?? 1) ? 'bg-indigo-600 text-white' : 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50' }}">
                        {{ $i }}
                    </a>
                @endfor
            </div>
        @endif
    @endif
@endsection
