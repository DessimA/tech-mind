<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class ConteudoControllerTest extends TestCase
{
    protected string $apiUrl = 'http://backend:3000';

    public function test_index_returns_view_with_conteudos(): void
    {
        Http::fake([
            "{$this->apiUrl}/v1/conteudos*" => Http::response([
                'data' => [
                    ['id' => 1, 'titulo' => 'Ruby on Rails', 'categoria' => 'Backend',
                     'probabilidade' => 0.95, 'status' => 'done',
                     'created_at' => '2026-07-09T20:00:00Z'],
                ],
                'meta' => ['current_page' => 1, 'total_pages' => 1, 'total_count' => 1, 'per_page' => 20],
            ]),
        ]);

        $response = $this->get(route('conteudos.index'));
        $response->assertStatus(200);
        $response->assertSee('Ruby on Rails');
    }

    public function test_index_shows_empty_state(): void
    {
        Http::fake([
            "{$this->apiUrl}/v1/conteudos*" => Http::response([
                'data' => [],
                'meta' => ['current_page' => 1, 'total_pages' => 1, 'total_count' => 0, 'per_page' => 20],
            ]),
        ]);

        $response = $this->get(route('conteudos.index'));
        $response->assertStatus(200);
        $response->assertSee('Nenhum conteúdo cadastrado ainda.');
    }

    public function test_create_returns_form(): void
    {
        $response = $this->get(route('conteudos.create'));
        $response->assertStatus(200);
        $response->assertSee('Cadastrar Conteúdo');
        $response->assertSee('Título');
        $response->assertSee('Texto');
    }

    public function test_store_creates_and_redirects(): void
    {
        Http::fake([
            "{$this->apiUrl}/v1/conteudos" => Http::response([
                'id' => 1, 'titulo' => 'Docker', 'status' => 'pending',
                'created_at' => '2026-07-09T20:00:00Z',
            ], 201),
        ]);

        $response = $this->post(route('conteudos.store'), [
            'titulo' => 'Docker',
            'texto' => 'Guia completo sobre containers Docker e orquestracao com Kubernetes',
        ]);

        $response->assertRedirect(route('conteudos.show', 1));
        $response->assertSessionHas('success');
    }

    public function test_store_validates_required_fields(): void
    {
        $response = $this->post(route('conteudos.store'), [
            'titulo' => '',
            'texto' => '',
        ]);

        $response->assertSessionHasErrors(['titulo', 'texto']);
    }

    public function test_show_displays_conteudo(): void
    {
        Http::fake([
            "{$this->apiUrl}/v1/conteudos/1" => Http::response([
                'id' => 1, 'titulo' => 'Docker',
                'texto' => 'Guia sobre containers',
                'categoria' => 'DevOps & Infraestrutura',
                'probabilidade' => 0.89,
                'informacoes_adicionais' => ['Docker', 'containers'],
                'status' => 'done',
                'created_at' => '2026-07-09T20:00:00Z',
                'updated_at' => '2026-07-09T20:01:00Z',
            ]),
        ]);

        $response = $this->get(route('conteudos.show', 1));
        $response->assertStatus(200);
        $response->assertSee('Docker');
        $response->assertSee('DevOps & Infraestrutura');
    }

    public function test_show_returns_redirect_for_missing(): void
    {
        Http::fake([
            "{$this->apiUrl}/v1/conteudos/999" => Http::response([], 404),
        ]);

        $response = $this->get(route('conteudos.show', 999));
        $response->assertRedirect(route('conteudos.index'));
    }

    public function test_store_handles_api_error(): void
    {
        Http::fake([
            "{$this->apiUrl}/v1/conteudos" => Http::response([], 500),
        ]);

        $response = $this->post(route('conteudos.store'), [
            'titulo' => 'Docker',
            'texto' => 'Guia completo sobre containers Docker',
        ]);

        $response->assertSessionHas('error');
    }

    public function test_index_handles_api_failure(): void
    {
        Http::fake([
            "{$this->apiUrl}/v1/conteudos*" => Http::response([], 500),
        ]);

        $response = $this->get(route('conteudos.index'));
        $response->assertSessionHas('error');
    }
}
