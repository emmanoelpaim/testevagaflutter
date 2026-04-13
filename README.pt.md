# Avaliação técnica para desenvolvedor Flutter

**Stack**: Flutter · Dart · Cubit · flutter_bloc · GetIt · HTTP + interceptors · Auto Route  
**Tempo estimado**: 3h30 a 4h  
**Entrega**: pull request ou zip com o código + arquivo `ANSWERS.md` preenchido

---

## Estrutura

```
challenge/
├── README.md                          ← este arquivo
├── ANSWERS.md                         ← preencha suas respostas escritas
├── pubspec.yaml
├── lib/
│   ├── main.dart                      ← entrada do app (GetIt + BlocProvider)
│   ├── fake_notifications_api.dart    ← API fake para rodar localmente
│   └── part2_implementation/
│       ├── notifications/
│       │   ├── notifications_api.dart       ← interface da API (não alterar)
│       │   ├── notification.dart            ← modelo (não alterar)
│       │   ├── notifications_view_model.dart ← IMPLEMENTAR AQUI (estados)
│       │   ├── notifications_cubit.dart     ← IMPLEMENTAR AQUI (cubit)
│       │   └── notifications_page.dart      ← IMPLEMENTAR AQUI (tela)
│       └── rate_limit/
│           ├── interceptor_contract.dart  ← interface base (não alterar)
│           └── http_rate_limit_interceptor.dart  ← IMPLEMENTAR AQUI
└── part1_diagnosis/
    ├── user_list_viewmodel.dart       ← 1.1
    ├── http_error_interceptor.dart    ← 1.2
    └── organisation_service.dart     ← 1.3
```

---

## Parte 0 — Declaração de arquitetura

> Preencha esta seção em `ANSWERS.md` **antes de começar qualquer outra parte.**  
> Não existe uma única resposta certa — o que importa é que sua escolha seja deliberada, escalável e que você entenda as consequências.

Declare a arquitetura que você seguirá nesta avaliação e no dia a dia.

**0.1 — Escolha de arquitetura**

Indique qual arquitetura ou estilo arquitetural você usará (exemplos: arquitetura em camadas recomendada pelo Flutter, Clean Architecture, MVVM + Repository, modular por feature, etc.).

> A documentação do Flutter recomenda uma **arquitetura em camadas** composta por três camadas — UI, Domínio e Dados — onde as dependências sempre apontam para dentro (UI → Domínio → Dados). Esse é o ponto de partida sugerido, mas você pode usar outra abordagem desde que seja escalável e você consiga justificá-la.  
> Referência: [flutter.dev/app-architecture](https://docs.flutter.dev/app-architecture/guide)

**0.2 — Mapeamento de camadas**

Para cada arquivo abaixo, diga a qual camada ou componente da sua arquitetura ele pertence e por quê:

- `NotificationsCubit`
- `NotificationsApi` (a interface abstrata)
- Um hipotético `NotificationsApiImpl` (implementação HTTP concreta)
- `NotificationsPage`
- `OrganisationService` (da Parte 1)

**0.3 — Justificativa de escalabilidade**

Em duas a quatro frases, explique o que torna sua arquitetura escalável e qual é o principal trade-off ou custo de adotá-la.

---

## Parte 1 — Diagnóstico de código

> Leia os arquivos em `part1_diagnosis/`. **Todas as respostas vão em `ANSWERS.md` — não modifique os arquivos `.dart`.**  
> Nenhum código precisa ser escrito nesta parte. Apenas explicações escritas.

### 1.1 — `user_list_viewmodel.dart`

Identifique **todos** os problemas neste código. Para cada um:

- O que está errado
- Qual o impacto em produção
- Como você corrigiría (em palavras, sem código)

### 1.2 — `http_error_interceptor.dart`

Há um problema sutil de **concorrência / comportamento inesperado** neste interceptor e na forma como ele é registrado.

- Qual o cenário exato em que o bug se manifesta
- Por que acontece
- Como você corrigiría (em palavras, sem código)

### 1.3 — `organisation_service.dart`

Este código funciona corretamente, mas tem um **problema de design** que vai causar dor conforme o projeto cresce.

- Qual é o problema
- Por que é problemático
- Como você refatoraria (em palavras, sem código)

### 1.4 — Quebras de fronteira arquitetural

Usando os três arquivos da Parte 1, aponte onde as fronteiras arquiteturais pretendidas estão sendo violadas.

- Nomeie pelo menos **2 quebras concretas** (arquivo + classe/método ou bloco de código)
- Para cada quebra, diga qual direção de dependência deveria existir
- Explique uma consequência prática em uma base de código em crescimento (testabilidade, acoplamento, deploy ou velocidade do time)

---

## Parte 2 — Implementação

> Implemente nos arquivos indicados. Siga os padrões dos arquivos de apoio fornecidos.

### 2.1 — Notificações

Implemente nos três arquivos em `lib/part2_implementation/notifications/`:

- **`notifications_view_model.dart`** — hierarquia de estados selada (`NotificationsState` e subclasses)
- **`notifications_cubit.dart`** — lógica do `NotificationsCubit`
- **`notifications_page.dart`** — tela usando `BlocBuilder`

Requisitos do `NotificationsCubit`:

- Fazer polling a cada **30 segundos** enquanto o app estiver em primeiro plano
- Em falha: **tentar de novo com backoff exponencial** (1s → 2s → 4s, máximo de 3 tentativas por ciclo)
- Se um ciclo ainda falhar após todas as tentativas, contar **1 ciclo falho**
- Após **3 ciclos falhos consecutivos**: parar o polling e emitir um estado de erro para a UI mostrar um banner
- **Retomar o polling automaticamente** quando o app voltar ao primeiro plano
- Os estados do Cubit devem cobrir: carregamento inicial, dados carregados e erro

A tela não precisa ser elaborada — uma `Column` com lista e banner de erro basta.  
Registre o Cubit no locator (adicione o trecho em `ANSWERS.md`; se seu pacote não tiver `locator.dart`, forneça um trecho hipotético coerente com sua arquitetura).

### 2.2 — `lib/part2_implementation/rate_limit/http_rate_limit_interceptor.dart`

Implemente `HttpRateLimitInterceptor` com os seguintes requisitos:

- Detectar respostas **429 Too Many Requests**
- Ler o header **`Retry-After`** (valor em segundos) e aguardar o tempo indicado
- **Reenviar automaticamente a requisição original** após a espera
- Limitar a no máximo **2 reenvios** por requisição — depois disso, lançar exceção

---

## Parte 3 — Perguntas escritas

Responda em `ANSWERS.md`. Não há uma única resposta certa — o objetivo é entender seu raciocínio.  
Baseie cada resposta em evidências concretas deste desafio (arquivo, classe, dependência, cenário de execução). Não entregue só definições de livro.

**3.1** — O projeto usa `Cubit` em vez de BLoC completo ou Riverpod. Quais são as vantagens e desvantagens dessa escolha? Em que ponto de escala você sugeriria migrar para BLoC com eventos explícitos, e quando isso seria exagero?

**3.2** — `locator.dart` registra todos os Cubits, Services e APIs em um único arquivo. Que problemas isso cria em projetos maiores? Como você organizaria de outra forma?

**3.3** — Dado que o projeto tem suporte offline parcial, como você implementaria uma **fila de operações pendentes** (ex.: edições sem internet que precisam ser sincronizadas depois)? Descreva a arquitetura, não o código.

**3.4** — Você encontrou um bug em produção: após logout, **dados de um usuário anterior aparecem brevemente** para o próximo usuário que faz login no mesmo dispositivo. Com base na arquitetura deste projeto, qual seria sua hipótese de causa raiz e como você investigaria?

**3.5** — Princípios SOLID na prática  
Escolha **dois** princípios SOLID quaisquer. Para cada um, aponte uma violação concreta nos arquivos da Parte 1 (nome do arquivo + qual é a violação), explique a consequência no mundo real de não corrigir em um time em crescimento e descreva como você refatoraria.

**3.6** — Direção de dependência neste projeto  
Usando `NotificationsApi` e a arquitetura declarada na Parte 0:

- Descreva a direção de dependência esperada entre `NotificationsPage`, `NotificationsCubit`, `NotificationsApi` e `NotificationsApiImpl`
- Aponte uma quebra concreta que ocorreria se `NotificationsCubit` importasse `NotificationsApiImpl` diretamente
- Descreva como você refatoraria ou reforçaria fronteiras (imports, interfaces, registro em DI)
- Explique um efeito prático em testabilidade ou custo de mudança

**3.7** — Arquitetura sob crescimento  
Imagine que o app ganhe três novos recursos no próximo trimestre: notificações push Firebase, lista de organizações offline-first e um seletor global de tema. Usando a arquitetura que você declarou na Parte 0, descreva — para cada recurso — quais camada(s) são afetadas e se alguma camada existente precisa mudar. O objetivo é mostrar que sua arquitetura absorve novos requisitos sem mudanças em cascata por todo o código.
