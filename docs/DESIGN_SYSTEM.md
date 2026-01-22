# 🎨 Sistema de Design - Trashtalk Records

## Visão Geral

O Trashtalk Records utiliza um sistema de design moderno inspirado em estúdios de gravação profissionais, com foco em:

- **Dark Mode**: Conforto visual para sessões longas de trabalho
- **Acentos Ciano/Turquesa**: Remetendo a VU meters e displays LED de estúdio
- **Gradientes Sutis**: Representando ondas sonoras
- **Tipografia Moderna**: Legível e distinta

## Paleta de Cores

### Cores Primárias
| Nome | Hex | Uso |
|------|-----|-----|
| Primary | `#00E5CC` | Destaques principais, botões, links |
| Primary Dark | `#00B8A3` | Estados hover/pressed |
| Primary Light | `#5EFFF2` | Glow effects |

### Cores Secundárias
| Nome | Hex | Uso |
|------|-----|-----|
| Secondary | `#FF006E` | Acentos complementares |
| Secondary Dark | `#CC0058` | Estados alternativos |
| Secondary Light | `#FF4D94` | Destaques secundários |

### Superfícies
| Nome | Hex | Uso |
|------|-----|-----|
| Surface | `#0D0D12` | Background principal |
| Surface Variant | `#16161D` | Cards, containers |
| Surface Elevated | `#1E1E28` | Modais, menus |
| Surface Highlight | `#2A2A38` | Bordas, divisores |

### Texto
| Nome | Hex | Uso |
|------|-----|-----|
| Text Primary | `#F5F5F7` | Títulos, texto principal |
| Text Secondary | `#B8B8C0` | Subtítulos, descrições |
| Text Tertiary | `#6E6E7A` | Hints, labels secundários |

### Estados
| Nome | Hex | Uso |
|------|-----|-----|
| Success | `#00E676` | Sucesso, confirmações |
| Warning | `#FFD600` | Alertas |
| Error | `#FF5252` | Erros |
| Info | `#448AFF` | Informações |
| Gold | `#FFD700` | Master tracks |

## Tipografia

### Font Families
- **Display/Headlines**: Space Grotesk (bold, impactante)
- **Body/Labels**: Inter (legível, neutro)

### Escala Tipográfica
| Estilo | Tamanho | Peso | Uso |
|--------|---------|------|-----|
| Display Large | 57px | 700 | Títulos de página |
| Display Medium | 45px | 600 | Subtítulos grandes |
| Display Small | 36px | 600 | Títulos de seção |
| Headline Large | 32px | 600 | Cabeçalhos |
| Title Large | 22px | 600 | Títulos de cards |
| Body Large | 16px | 400 | Texto principal |
| Body Small | 12px | 400 | Detalhes |
| Label Medium | 12px | 500 | Botões, labels |

## Espaçamentos

| Token | Valor | Uso |
|-------|-------|-----|
| spacing-xs | 4px | Espaços mínimos |
| spacing-sm | 8px | Entre elementos relacionados |
| spacing-md | 16px | Entre grupos |
| spacing-lg | 24px | Entre seções |
| spacing-xl | 32px | Margens de página |
| spacing-2xl | 48px | Separações grandes |

## Raios de Borda

| Token | Valor | Uso |
|-------|-------|-----|
| radius-sm | 8px | Chips, tags |
| radius-md | 12px | Cards, inputs |
| radius-lg | 16px | Modais, containers grandes |
| radius-xl | 24px | Bottom sheets |
| radius-full | 999px | Avatars, botões circulares |

## Componentes

### Botões

**Primary**: Fundo gradiente, texto escuro
- Estados: Default → Hover (brilho) → Pressed (escala 0.95)

**Secondary**: Fundo transparente com borda colorida
- Estados: Default → Hover (fundo sutil) → Pressed

**Ghost**: Apenas texto/ícone
- Estados: Default → Hover (fundo sutil)

### Cards

**Glass Card**: Efeito glassmorphism com blur
- Blur: 10-15px
- Opacidade: 10-15%
- Borda: 1px surfaceHighlight

**Project Card**: Card com ícone colorido e gradiente sutil
- Hover: Escala 0.98 + sombra

**Audio Track Card**: Card com botão play integrado
- Estados: Normal → Playing (glow primário)

### Inputs

**Text Input**: Fundo surfaceVariant, borda sutil
- Focus: Borda primária + glow
- Error: Borda vermelha

**Search Input**: Pill-shape com ícone de busca

### Player

**Mini Player**: Barra inferior com thumbnail, info e controles
**Full Player**: Tela cheia com artwork rotativo (vinil), controles centralizados

## Animações

### Durações
| Token | Valor | Uso |
|-------|-------|-----|
| instant | 100ms | Feedback imediato |
| fast | 200ms | Transições rápidas |
| normal | 300ms | Transições padrão |
| slow | 500ms | Animações de entrada |
| slower | 800ms | Animações dramáticas |

### Curvas
- **smooth**: easeOutCubic - Entrada suave
- **snappy**: easeOutExpo - Resposta rápida
- **bounce**: elasticOut - Efeito elástico
- **dramatic**: easeInOutCubic - Transições longas

### Animações Padrão
- **FadeSlideIn**: Entrada com fade + slide vertical
- **ScaleOnTap**: Escala ao pressionar (0.95)
- **PulseAnimation**: Pulsação contínua
- **SpinAnimation**: Rotação contínua (loading)
- **ShimmerEffect**: Skeleton loading

## Backgrounds

### Gradient Background
- Gradiente radial sutil
- Padrão de grid com opacidade baixa
- Glow effects nos cantos

### Particle Background
- Partículas flutuantes (login screen)
- Cores primárias/secundárias
- Movimento vertical lento

## Uso

### Importação
```dart
import 'package:trashtalk_records/core/theme/app_theme.dart';
import 'package:trashtalk_records/core/theme/app_animations.dart';
```

### Acessar Cores
```dart
Container(color: AppTheme.primary)
Container(color: AppTheme.surfaceVariant)
```

### Acessar Espaçamentos
```dart
Padding(padding: EdgeInsets.all(AppTheme.spacingMd))
SizedBox(height: AppTheme.spacingLg)
```

### Usar Animações
```dart
FadeSlideIn(
  delay: Duration(milliseconds: 100),
  child: MyWidget(),
)

ScaleOnTap(
  onTap: () {},
  child: MyCard(),
)
```

### Usar Componentes
```dart
CustomButton(
  label: 'Criar Projeto',
  onPressed: () {},
  variant: ButtonVariant.primary,
  icon: Icons.add,
)

GlassCard(
  padding: EdgeInsets.all(AppTheme.spacingMd),
  child: Text('Conteúdo'),
)
```

## Screenshots (Conceito)

### Login Screen
- Background com partículas animadas
- Logo com gradiente e glow
- Form com glass card

### Projects Screen
- Header com saudação baseada na hora
- Cards de projeto coloridos
- FAB com gradiente

### Project Detail Screen
- SliverAppBar com artwork
- Lista de tracks com botões play
- Mini player fixo

### Full Player
- Artwork rotativo (estilo vinil)
- Progress bar customizado com glow
- Controles circulares com gradiente
