<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class ConteudoController extends Controller
{
    protected string $apiUrl;

    public function __construct()
    {
        $this->apiUrl = env('RAILS_API_URL', 'http://backend:3000');
    }

    public function index(Request $request)
    {
        $page = $request->get('page', 1);
        $response = Http::withHeaders([
            'X-Forwarded-For' => $request->ip(),
        ])->get("{$this->apiUrl}/v1/conteudos", [
            'page' => $page,
            'per_page' => 20,
            'q' => $request->get('q'),
            'sort' => $request->get('sort', 'created_at_desc'),
        ]);

        if ($response->failed()) {
            return view('conteudos.index', [
                'conteudos' => [], 'meta' => [],
                'error' => 'Erro ao carregar conteúdos do servidor.'
            ]);
        }

        $body = $response->json();
        $conteudos = $body['data'] ?? [];
        $meta = $body['meta'] ?? [];

        return view('conteudos.index', compact('conteudos', 'meta'));
    }

    public function create()
    {
        return view('conteudos.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'titulo' => 'required|string|min:3|max:200',
            'texto' => 'required|string|min:10|max:5000',
        ]);

        $response = Http::withHeaders([
            'X-Forwarded-For' => $request->ip(),
        ])->post("{$this->apiUrl}/v1/conteudos", $validated);

        if ($response->failed()) {
            return back()
                ->withInput()
                ->with('error', 'Erro ao cadastrar conteúdo. Tente novamente.');
        }

        $conteudo = $response->json();

        return redirect()
            ->route('conteudos.show', $conteudo['id'])
            ->with('success', 'Conteúdo cadastrado! A classificação está sendo processada.');
    }

    public function show(int $id, Request $request)
    {
        $response = Http::withHeaders([
            'X-Forwarded-For' => $request->ip(),
        ])->get("{$this->apiUrl}/v1/conteudos/{$id}");

        if ($response->failed()) {
            return redirect()
                ->route('conteudos.index')
                ->with('error', 'Conteúdo não encontrado.');
        }

        $conteudo = $response->json();

        return view('conteudos.show', compact('conteudo'));
    }
}
