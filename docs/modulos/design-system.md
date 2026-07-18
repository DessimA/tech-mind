# Módulo: Design System — TechMind

> Sistema de design visual inspirado na estética Gorillaz: caos controlado, colagem urbana, neon sobre escuro, traço grosso de quadrinho.

## Propósito

Este documento define a linguagem visual do TechMind: paleta, tipografia, texturas, componentes e a lógica de intensidade por seção. O objetivo é manter consistência visual sem engessar a criatividade — o "caos controlado".

## Princípios

| Princípio | Descrição |
|---|---|
| Caos controlado | Visual ousado nos pontos de impacto (hero, CTAs, badges), limpo nos pontos de leitura (formulários, corpo de texto) |
| Urbano/tecnológico | Texturas de rua (grafite, halftone, grão) combinadas com elementos digitais (glitch, tracking aberto) |
| Contraste como regra | Fundo escuro vs neon limpo; traço vetorial grosso vs textura granulada |

## Paleta de cores

| Token | Hex | Uso |
|---|---|---|
| `bg-base` | `#0B0E14` | Fundo principal da página |
| `bg-surface` | `#151A24` | Cards, painéis, elementos elevados |
| `bg-surface-alt` | `#1E2530` | Seções alternadas |
| `ink` | `#0A0A0A` | Contornos grossos estilo quadrinho |
| `text-primary` | `#F4F1E8` | Texto principal, off-white (textura papel) |
| `text-secondary` | `#A9AFBC` | Texto de apoio, legendas |
| `accent-green` | `#C6FF3D` | Cor de identidade principal, CTAs |
| `accent-cyan` | `#29E7CD` | Links, elementos tecnológicos, hover |
| `accent-magenta` | `#FF4FA3` | Badges, alertas, destaque secundário |
| `accent-mustard` | `#F2C230` | Ícones, contraponto quente |
| `state-error` | `#FF3B3B` | Erros de formulário |

**Regra de uso:** uma cor accent dominante por seção. As demais aparecem apenas em pontos isolados (badges, hover, ícones).

## Tipografia

| Papel | Fonte | Uso |
|---|---|---|
| Display | Anton (Google Fonts) | Títulos H1/H2, caixa alta, tracking apertado |
| Corpo | Inter (Google Fonts) | Parágrafos, formulários, navegação |
| Dados/técnico | Space Mono (Google Fonts) | Tags, timestamps, badges, números |

## Texturas e elementos gráficos

| Efeito | Implementação |
|---|---|
| Grão/noise | Overlay `body::before` com SVG `feTurbulence`, opacidade 3% |
| Ink outline | `border: 2px solid #0A0A0A` em cards e botões |
| Sticker shadow | `box-shadow: 4px 4px 0 #0A0A0A` em botões e cards |
| Halftone | `radial-gradient` repetido em fundos de seção |
| Glitch hover | `text-shadow` duplo em cyan e magenta no hover |
| Input underline | `border-bottom: 2px` que muda de cor no foco |

## Componentes

| Componente | Especificação |
|---|---|
| Botão primário | `bg-accent-green`, texto `ink`, borda 2px `ink`, sombra dura, hover sobe -0.5px |
| Botão secundário | Fundo transparente, borda 2px na accent da seção |
| Card | Fundo `bg-surface`, borda 2px `ink`, sombra dura |
| Badge | `font-mono` uppercase, fundo accent, texto `ink`, borda 2px `ink` |
| Input | Fundo `bg-surface-alt`, borda inferior 2px, foco muda para accent |
| Flash notice | Fundo verde/10, borda verde, texto verde |
| Flash alert | Fundo magenta/10, borda magenta, texto magenta |

## Acessibilidade

1. Cores accent (green, mustard) funcionam como texto sobre fundo escuro — usam texto `ink` (escuro) quando são fundo de botão
2. Cyan e magenta têm contraste ajustado — usar apenas em elementos grandes
3. `prefers-reduced-motion`: glitch hover desativado
4. Grão/noise em opacidade 3% — imperceptível para a maioria, mantém textura

## Extensão do Tailwind

```javascript
tailwind.config = {
  theme: {
    extend: {
      colors: {
        base: '#0B0E14',
        surface: '#151A24',
        'surface-alt': '#1E2530',
        ink: '#0A0A0A',
        accent: {
          green: '#C6FF3D',
          cyan: '#29E7CD',
          magenta: '#FF4FA3',
          mustard: '#F2C230',
        },
      },
      fontFamily: {
        display: ['Anton', 'sans-serif'],
        body: ['Inter', 'sans-serif'],
        mono: ['Space Mono', 'monospace'],
      },
      boxShadow: {
        hard: '4px 4px 0 #0A0A0A',
      },
    },
  },
}
```
