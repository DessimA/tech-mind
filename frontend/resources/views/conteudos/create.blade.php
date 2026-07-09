@extends('layouts.app')

@section('title', 'Novo Conteúdo')

@section('content')
    <div class="max-w-2xl">
        <h1 class="text-2xl font-bold text-gray-900 mb-6">Cadastrar Conteúdo</h1>

        <form action="{{ route('conteudos.store') }}" method="POST" class="bg-white rounded-lg border border-gray-200 p-6 space-y-6">
            @csrf

            <div>
                <label for="titulo" class="block text-sm font-medium text-gray-700 mb-1">Título</label>
                <input type="text" name="titulo" id="titulo" value="{{ old('titulo') }}" required
                       class="w-full px-3 py-2 border border-gray-300 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm"
                       placeholder="Ex: Introdução ao Docker">
                @error('titulo')
                    <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                @enderror
            </div>

            <div>
                <label for="texto" class="block text-sm font-medium text-gray-700 mb-1">Texto</label>
                <textarea name="texto" id="texto" rows="10" required
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm resize-y"
                          placeholder="Cole ou digite o conteúdo técnico aqui...">{{ old('texto') }}</textarea>
                @error('texto')
                    <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                @enderror
            </div>

            <div class="flex items-center justify-end space-x-3">
                <a href="{{ route('conteudos.index') }}" class="px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-900">Cancelar</a>
                <button type="submit" class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 text-sm font-medium">
                    Cadastrar
                </button>
            </div>
        </form>
    </div>
@endsection
