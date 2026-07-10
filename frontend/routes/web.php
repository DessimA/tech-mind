<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ConteudoController;

Route::get('/', fn () => redirect()->route('conteudos.index'));

Route::get('/health', fn () => response()->json(['status' => 'ok']));

Route::controller(ConteudoController::class)->prefix('conteudos')->name('conteudos.')->group(function () {
    Route::get('/', 'index')->name('index');
    Route::get('/criar', 'create')->name('create');
    Route::post('/', 'store')->name('store');
    Route::get('/{id}', 'show')->name('show');
});
