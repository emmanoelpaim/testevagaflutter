# Answers

---

## Part 0 — Architecture Declaration

### 0.1 — Architecture choice

Eu seguiria uma arquitetura **em camadas**, parecida com o que o próprio Flutter documenta: em cima fica a interface (telas e widgets), no meio as regras e contratos do app, e embaixo tudo que fala com rede, banco ou arquivos. Isso significa que a tela não “enxerga” URL nem JSON direto — ela conversa com algo estável no meio.

Organizo também por **feature** (pastas ou módulos por funcionalidade), para o time conseguir evoluir uma parte do app sem abrir dezenas de pastas misturadas.

Para “ligar as peças” sem ficar passando dependência na mão em todo construtor, uso **GetIt** (ou algo equivalente): fica explícito quem depende de quem e fica mais fácil trocar implementação em teste.

### 0.2 — Layer mapping

| File | Layer / Component | Reason |
|------|-------------------|--------|
| `NotificationsCubit` | Apresentação (lógica de estado da tela) | É quem decide o que a tela mostra (carregando, lista, erro) e orquestra o polling. Não deveria saber detalhes de HTTP como montar URL ou parse de JSON. |
| `NotificationsApi` (interface) | Contrato entre “o que o app precisa” e “de onde vem” | É um contrato: “quero buscar notificações”. Quem implementa pode ser REST hoje e outra coisa amanhã; o resto do app não muda. |
| `NotificationsApiImpl` (hypothetical concrete) | Dados | É a peça que realmente chama o servidor, trata status code e transforma resposta em objetos. Vive na ponta “técnica”. |
| `NotificationsPage` | Apresentação (só interface) | Só desenha widgets e reage ao estado que o Cubit emite (por exemplo com `BlocBuilder`). |
| `OrganisationService` | Fica num meio-termo delicado | Ele junta chamada à API com atualização do `OrganisationsCubit`. Na Parte 1 isso vira problema porque mistura “serviço de dados” com “estado de tela” (detalho na pergunta 1.3). |

### 0.3 — Scalability justification

Essa divisão escala bem porque você consegue **mudar uma parte sem derrubar o resto**: trocar API, colocar cache ou mock para teste fica local. Também ajuda times diferentes a trabalharem em features sem pisar no mesmo arquivo gigante o tempo todo.

O “preço” é disciplina: se todo mundo começar a importar implementação concreta “porque é mais rápido”, as camadas viram teatro e o código volta a ser um bloco só. Revisão de código e regras simples de import ajudam a manter o desenho honesto.

---

## Part 1 — Diagnosis

### 1.1 — UserListCubit

1. **O `init` chama `getUsers()` mas emite uma lista vazia**  
   Na prática, a tela **nunca mostra os usuários** que vieram do servidor — parece bug óbvio, mas em produção o utilizador veria sempre lista vazia.  
   **Como corrigir:** depois do `getUsers()` terminar, emitir o estado carregado **com a lista retornada**; se der erro, ter um estado ou tratamento de erro em vez de fingir sucesso.

2. **Cada vez que a busca muda, abre um novo `listen` sem fechar o anterior**  
   Isto é como deixar várias torneiras abertas: **gasta memória**, e pior: uma resposta **antiga** da rede pode chegar depois de uma **nova** digitação e **atualizar a tela com resultado errado**.  
   **Como corrigir:** guardar a subscrição e cancelar antes de começar outra, ou concentrar a política de “só a última busca vale” num sítio (por exemplo no repositório com operadores de stream adequados) e cancelar tudo no `close()` do Cubit.

3. **Não há cuidado quando o Cubit é destruído**  
   Se o utilizador sair da tela enquanto um stream ainda emite, pode tentar-se **atualizar estado num Cubit já fechado** — erros estranhos ou estados fantasma.  
   **Como corrigir:** cancelar subscrições ao fechar o Cubit e não emitir depois disso.

4. **Não há estado de “a carregar” nem de erro**  
   Em rede lenta ou falha, a pessoa não sabe se está a espera ou se falhou. Também fica difícil de apoiar em produção.  
   **Como corrigir:** estados explícitos (por exemplo carregando / sucesso / erro) ou feedback equivalente.

### 1.2 — HttpErrorInterceptor

Imagina **várias chamadas ao mesmo tempo** e todas devolvem 401. O interceptor chama `onError` **uma vez por resposta**. Se o tratamento for “fazer logout e ir para o login”, podes acabar com **vários logouts e várias navegações em cima uma da outra**.

O tipo do callback é **síncrono** (`VoidCallback`), mas o exemplo comentado faz coisas **assíncronas** (logout, mudar de ecrã). Isso não “espera” de forma coordenada — não há um “já estou a tratar do 401, ignora os próximos até acabar”. O resultado pode ser **pilha de rotas estranha**, **logout repetido** ou **estado de sessão inconsistente**.

**Como melhorar:** garantir que só corre **um fluxo de recuperação** de cada vez (por exemplo um flag “logout em andamento”), ou fila única; se possível modelar o tratamento com `Future` e só permitir nova ação quando a anterior terminar; em cenários extremos, ignorar erros repetidos do mesmo tipo enquanto o primeiro fluxo não fechar.

### 1.3 — OrganisationService

O `OrganisationService` não só fala com a API como também **mexe diretamente no `OrganisationsCubit`** para atualizar a lista na memória. O problema é misturar **“buscar e gravar dados”** com **“estado que a interface usa”** no mesmo sítio.

Quando o projeto cresce, isto aperta: queres usar a mesma lógica **sem ecrã** (teste, script, background)? Tens de arrastar o Cubit. Queres mudar como a lista é mostrada? Acabas a mexer no “serviço de rede”. Testes também ficam mais pesados porque têm de simular Cubit, não só a API.

**Caminho mais saudável:** uma camada que devolve dados ou eventos (repositório / casos de uso) e a **UI** (ou um listener dedicado) atualiza o Cubit — ou o Cubit observa o fluxo de dados, em vez do serviço empurrar estado à força.

### 1.4 — Architecture Boundary Breaks

1. **`organisation_service.dart` — `OrganisationService` depende de `OrganisationsCubit`**  
   A ideia geral é: **dados e regras não deveriam depender de como a tela guarda estado**. Aqui o serviço aponta “para cima”, para um Cubit.  
   **Na prática:** testar o serviço vira teste de UI; reutilizar fora do Flutter fica estranho; mudanças de lista na interface arrastam código que deveria ser só “buscar organizações”.

2. **`user_list_viewmodel.dart` — `UserListCubit` mistura `Future` e `Stream` sem regra clara de cancelamento**  
   O Cubit deveria consumir um contrato estável; a política de “nova letra na pesquisa cancela a anterior” é regra de negócio/fluxo de dados, não algo espalhado sem controlo.  
   **Na prática:** aparecem **race conditions** na pesquisa e testes unitários do Cubit ficam frágeis porque o comportamento depende de timing de streams.

---

## Part 2 — Implementation

### 2.1 — Locator registration snippet

```dart
import 'package:get_it/get_it.dart';
import 'package:seu_app/notifications/notifications_api.dart';
import 'package:seu_app/notifications/notifications_cubit.dart';

void registerNotifications(GetIt getIt) {
  getIt.registerFactory<NotificationsCubit>(
    () => NotificationsCubit(getIt<NotificationsApi>()),
  );
}
```

Em palavras simples: o GetIt sabe criar um `NotificationsCubit` sempre que precisares, e injeta a implementação correta de `NotificationsApi`. A página em si não deve ir buscar o Cubit “escondido” dentro do widget — o normal é o **pai** (rota ou `BlocProvider`) criar o Cubit **uma vez** e a página só consumir.

---

## Part 3 — Written Questions

### 3.1 — Cubit vs BLoC vs Riverpod

**Cubit** é simples de ler: chamas métodos, o estado muda. Para fluxos como o polling da Parte 2, costuma ser suficiente e com menos código repetido.

O lado negativo é que, quando **entram muitas ações diferentes** (telemetria, undo, filas de comandos), sem eventos nomeados tudo vira “mais um método” e fica mais difícil testar e documentar o que aconteceu **porquê**.

**BLoC com eventos** faz mais sentido quando queres tratar cada intenção como um tipo (útil para testes de matriz “evento → estado” e para equipas maiores). **Não compensa** em ecrãs minúsculas onde o Cubit já é claro — aí é burocracia extra.

**Riverpod** é outro ecossistema (escopos, providers). Pode ser ótimo em projetos novos, mas **trocar só uma feature** de Cubit para Riverpod num app já em `flutter_bloc` é decisão de arquitetura, não um detalhe de uma tela.

### 3.2 — Centralised locator

Um ficheiro único onde **tudo** se regista vira um **ficheiro enorme**: conflitos em merge, mais difícil de navegar e maior risco de dependências circulares sem notar.

Um arranjo mais natural é **partir por áreas** (`registerAuth`, `registerNotificações`, etc.) e um ficheiro pequeno que só **chama essas funções** na arranque. Cada equipa/feature pode cuidar do seu registo sem mexer no resto.

### 3.3 — Offline operations queue

A ideia é: quando não há rede, **não perdes o trabalho** — guardas operações pendentes (criar, editar, apagar) num armazenamento **durável** (base local).

A camada de **dados** grava o quê falta sincronizar e o estado de cada item. A camada de **domínio** diz o que é válido e como resolver conflitos (por exemplo “último ganha” ou regras específicas). Um processo em **segundo plano** ou quando a app está ativa tenta enviar a fila para o servidor. A **UI** só mostra “pendente / a sincronizar / erro”, sem saber pormenores de HTTP.

Assim a fila **sobrevive** a fechar a app; a UI não fica cheia de detalhes técnicos.

### 3.4 — Previous user data bug

O sintoma — **dados do utilizador A a aparecer um instante para o B** — quase sempre aponta para **cache ou estado que não foi limpo no logout**.

Por exemplo: listas ainda na memória num Cubit singleton, repositório com dados antigos, ou interceptor a usar **token antigo** até a primeira chamada nova terminar.

**Como investigar:** seguir o fluxo de `logout()` e ver se limpa tokens, caches e **resets** de Cubits que são singleton; pôr logs na ordem logout → login → primeira API; simular rede lenta para ver a “janela” em que a UI pinta antes da resposta nova.

### 3.5 — SOLID principles in practice

**S — Single responsibility (`organisation_service.dart`):** o mesmo sítio **chama a API** e **atualiza o Cubit**. Se amanhã a lista for paginada ou vier de cache, acabas a mexer num sítio que mistura responsabilidades. **Refatorar:** separar “obter dados” de “atualizar estado da UI”, por exemplo com repositório + reação na camada de apresentação.

**D — Dependency inversion (`user_list_viewmodel.dart`):** ter interface `UserService` é bom, mas empurrar **como** subscrever o stream e sem cancelar política clara mete detalhe de infraestrutura no Cubit. **Refatorar:** a política de pesquisa (cancelar anterior, debounce) pode viver na implementação do serviço ou num caso de uso injetável, para o Cubit só pedir “resultado da pesquisa”.

### 3.6 — Dependency direction in this project

Em termos simples: a **página** fala com o **Cubit**, o Cubit fala com a **interface** `NotificationsApi`, e **só** a implementação (`NotificationsApiImpl`) sabe de HTTP. A página **não** devia importar a classe que monta `Dio` ou URLs.

Se o Cubit importasse `NotificationsApiImpl` **direto**, qualquer mudança no cliente HTTP ou no formato **quebrava** testes do Cubit e obrigava a mocks pesados. Com a interface, no teste usas um **fake** que devolve listas fixas.

**Como reforçar:** contratos num sítio comum; implementações na pasta de dados; no GetIt registar **interface → implementação**; regras de lint ou revisão para ninguém “saltar” a fronteira por hábito.

### 3.7 — Architecture under growth

**Notificações push (Firebase):** camada de **dados** lida com plugin e token; **domínio** traduz o payload em algo útil para o app; **UI** mostra banner ou navega. Se o domínio expuser um evento tipo “chegou notificação”, o resto não rebenta em cascata.

**Lista de organizações offline-first:** **dados** com armazenamento local e sincronização; **domínio** com regras de conflito; **apresentação** a ler modelos prontos. O exemplo da Parte 1 teria de **deixar de depender** só de lista vinda do ar sem cache.

**Tema global (claro/escuro):** sobretudo **apresentação** (tema na raiz) e, se quiseres lembrar a escolha, **dados** para gravar preferência. Pouco impacto nas APIs HTTP se for só preferência local.
