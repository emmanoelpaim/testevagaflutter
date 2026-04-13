# Respostas

---

## Parte 0 — Declaração de arquitetura

### 0.1 — Escolha de arquitetura

<!-- Indique a arquitetura ou estilo arquitetural que você seguirá. -->

### 0.2 — Mapeamento de camadas

| Arquivo | Camada / componente | Motivo |
|---------|---------------------|--------|
| `NotificationsCubit` | | |
| `NotificationsApi` (interface) | | |
| `NotificationsApiImpl` (concreto hipotético) | | |
| `NotificationsPage` | | |
| `OrganisationService` | | |

### 0.3 — Justificativa de escalabilidade

<!-- Em 2–4 frases: o que torna esta arquitetura escalável e qual é seu principal custo? -->

---

## Parte 1 — Diagnóstico

### 1.1 — UserListCubit

<!-- Descreva os problemas encontrados, o impacto de cada um e como você corrigiría -->

### 1.2 — HttpErrorInterceptor

<!-- Descreva o cenário do bug, por que acontece e como você corrigiría -->

### 1.3 — OrganisationService

<!-- Identifique o problema de design, explique o impacto e descreva a refatoração -->

### 1.4 — Quebras de fronteira arquitetural

<!-- Aponte pelo menos 2 quebras concretas de fronteira (arquivo + símbolo/bloco), direção de dependência esperada e impacto prático -->

---

## Parte 2 — Implementação

### 2.1 — Trecho de registro no locator

```dart

```

---

## Parte 3 — Perguntas escritas

### 3.1 — Cubit vs BLoC vs Riverpod

### 3.2 — Locator centralizado

### 3.3 — Fila de operações offline

### 3.4 — Bug de dados do usuário anterior

### 3.5 — Princípios SOLID na prática

<!-- Princípio 1: nome, arquivo, violação, consequência, refatoração -->

<!-- Princípio 2: nome, arquivo, violação, consequência, refatoração -->

### 3.6 — Direção de dependência neste projeto

<!-- Descreva a direção de dependência esperada, um cenário concreto de quebra e como reforçar fronteiras -->

### 3.7 — Arquitetura sob crescimento

<!-- Notificações push Firebase — camadas afetadas: -->

<!-- Lista de organizações offline-first — camadas afetadas: -->

<!-- Seletor global de tema — camadas afetadas: -->
