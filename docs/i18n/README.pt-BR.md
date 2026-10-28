# Random Cue Focus

[简体中文](README.zh-CN.md) · [English](../../README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · Português (Brasil) · [Русский](README.ru.md) · [繁體中文](README.zh-TW.md)

**Transforme “preciso estudar” em um próximo passo concreto e saiba onde retomar após se distrair.**

Random Cue Focus é um companheiro de estudo Flutter com armazenamento local para iOS e Windows. Defina o que aprender, escreva uma pequena ação de retomada e use verificações opcionais sem parar o temporizador. O histórico local e a avaliação opcional do progresso ajudam a refletir sobre a sessão.

Use com livros, exercícios ou anotações: ele apoia o planejamento e o acompanhamento da aprendizagem. A versão `0.2.0` usa verificações espaçadas, que podem ser puladas, silenciosas e sem notificações por padrão.

[Experimente uma sessão](#a-session-in-practice) · [Ambiente de desenvolvimento](#develop) · [Preparação para lançamento](#release-status) · [Perguntas frequentes](#common-questions) · [Contribua](#help-make-it-easier-to-use-and-verify)

<a id="learning-workflow"></a>

## Como usar em uma sessão de estudo

Troque “estudar biologia” por “ler a seção de divisão celular e escrever três diferenças entre mitose e meiose”. Acrescente “se eu abrir uma aba sem relação, volto ao próximo parágrafo e escrevo uma comparação”. Na verificação opcional, retome o objetivo ou continue lendo; depois, registre o que concluiu e o incômodo das interrupções.

Para resolver problemas, defina os exercícios e o passo de retomada; para revisar, escolha os conceitos que vai recordar e explicar com seus materiais. Ler, resolver, recordar e conferir cabe a você. O plano editável não é uma intervenção automática de orientação.

<a id="when-it-may-fit"></a>

## Quando pode ser útil

Use quando quiser uma forma leve de se reconectar à sua própria tarefa, sem transformar cada sessão de foco em uma sequência de alertas.

- Defina um objetivo concreto antes de começar.
- Continue trabalhando durante uma verificação ocasional e opcional do objetivo.
- Se perceber uma distração, use uma ação de retomada escrita por você.
- Consulte o histórico local de sessões sem criar uma conta.

Você pode pular uma verificação ou desativar as não essenciais durante uma sessão. A intenção é disponibilizar a autoavaliação sem tornar a interrupção obrigatória; um temporizador ou a contagem de sessões não comprova se isso ajuda você.

<a id="a-session-in-practice"></a>

## Uma sessão na prática

1. Defina um objetivo e uma ação simples de retomada: “se eu me distrair, então…”.
2. Inicie uma sessão de foco. Em novas instalações, as notificações e o som em primeiro plano ficam desativados.
3. Quando uma verificação aparecer, escolha “continuo no objetivo”, “acabei de me distrair” ou “pular”. O tempo de foco continua.
4. Pause, descanse ou encerre conforme precisar; depois, registre opcionalmente o progresso e o incômodo causado pelas interrupções.
5. Consulte o histórico armazenado no seu dispositivo.

As instruções de compilação e execução estão em [Desenvolvimento](#develop). Ainda não há uma gravação em dispositivo nesta página; o [status do lançamento](#release-status) distingue as verificações automatizadas do trabalho pendente em dispositivos físicos.

<a id="what-is-implemented"></a>

## O que está implementado

- Um pacote Dart compartilhado e testado para configurações, modelos de sessão, migração, planejamento de sinais, redução adaptativa do incômodo, atribuição cruzada voluntária, resumos locais de resultados, perfis de prontidão de dados estratificados por condição, verificações de qualidade de dados e exportação de pesquisa que preserva a privacidade.
- Aplicativos iOS e Windows com estados de foco/pausa/descanso/parada, verificações de objetivo, histórico local e adaptadores de plataforma.
- Padrões de uma nova instalação: 50 minutos de foco, 10 de descanso, intervalo de verificação de 12–18 minutos, janela de resposta de 20 segundos, notificações desativadas e som em primeiro plano desativado.
- Respostas explícitas: “continuo no objetivo”, “acabei de me distrair” ou “pular”; o tempo de foco continua durante a verificação.
- Verificações não essenciais podem ser desativadas para toda uma sessão; relatos de desvio da tarefa nunca fazem a heurística aumentar a frequência das interrupções.
- O objetivo, o gatilho de distração e a próxima ação de retomada são editáveis pelo usuário, em vez de serem tratados como um roteiro universal.
- Armazenamento exclusivamente local, sem conta, servidor, chave de API, SDK de publicidade ou análise remota.
- As respostas opcionais após a sessão sobre progresso e incômodo das interrupções são armazenadas localmente e permanecem ausentes quando o usuário não responde.
- Um experimento cruzado local está disponível somente após consentimento explícito. Ele alterna sessões sem verificações e com verificações espaçadas, persiste a atribuição antes da exposição, nunca faz upload automaticamente e pode ser abandonado a qualquer momento.
- CI para testes do núcleo compartilhado, análise/testes dos dois aplicativos, compilação de lançamento do Windows e compilação do simulador iOS.

As configurações e os eventos de sessão existentes da versão `0.1.x` são migrados, e não descartados silenciosamente. A versão `6` do esquema mantém todas as migrações anteriores, a inscrição explícita no estudo e a atribuição por sessão, acrescentando, para novas sessões de estudo, um retrato do estado real de ativação das verificações, do intervalo e da janela de resposta. O esquema v2 de exportação de pesquisa remove o timestamp absoluto da atribuição, além dos IDs brutos de sessão, datas e texto livre. A cadência adaptativa é uma heurística determinística e inspecionável, não um modelo de aprendizado de máquina, e aguarda pelo menos três sessões e seis respostas antes de alterar um intervalo.

<a id="evidence-boundary"></a>
<a id="limites-das-evidências"></a>

## Pesquisa por trás do fluxo

| Estudo e experimento | Resultado | Relação e limite |
| --- | --- | --- |
| [Gollwitzer & Sheeran (2006)](https://doi.org/10.1016/S0065-2601(06)38002-1) | A metanálise de planos se–então encontrou benefícios médios em contextos variados; estimativas modernas robustas a vieses são menores. | Apoia escrever um plano de retomada; não comprova benefício de lembretes aleatórios para aprender. |
| [Harkin et al. (2016)](https://doi.org/10.1037/bul0000025) | 138 estudos randomizados, 19.951 participantes: promover o monitoramento melhorou em média o alcance de objetivos. | Apoia verificações e reflexão; não avaliou este app nem seu efeito nas notas. |
| [Stothart et al. (2015)](https://doi.org/10.1037/xhp0000100) | Notificações prejudicaram uma tarefa de atenção mesmo sem manusear o telefone. | Orienta verificações silenciosas e opcionais; não valida o intervalo de 12–18 minutos. |

**São evidências de métodos e processos relacionados, não ganhos de aprendizagem medidos neste app.** Não foi realizado ensaio educacional do produto. O intervalo é uma heurística ajustável. O cruzamento local compara condições e experiência; não há resultados relatados. Histórico e autoavaliações não são notas de aprendizagem.

Recordação e espaçamento têm respaldo, mas o app atual não oferece perguntas de recuperação, correção de respostas ou revisão agendada de conteúdos. O [modo de aprendizagem](../LEARNING_MODE_SPEC.md) continua sendo uma especificação. Uma avaliação futura poderia comparar retenção tardia, transferência e incômodo; ela ainda não foi realizada.

Veja [fontes e limites](../EVIDENCE_BASE.md), [plano de medição](../MEASUREMENT_PLAN.md), [dicionário de dados](../DATA_DICTIONARY.md) e [protocolo de cruzamento local](../LOCAL_CROSSOVER_PROTOCOL.md).

<a id="common-questions"></a>

## Perguntas frequentes

**Qual é a diferença em relação a um temporizador de pausas obrigatórias?** Uma verificação não interrompe o tempo de foco. Você pode responder, pular ou desativar as verificações não essenciais durante toda a sessão. O descanso continua sendo um estado separado.

**Vou receber mais interrupções se relatar uma distração?** A heurística documentada de redução do incômodo não aumenta a frequência das interrupções após autorrelatos de desvio da tarefa. Ela é determinística e inspecionável, não um modelo de atenção aprendido.

**Por que não ouço lembretes?** Novas instalações mantêm o som em primeiro plano e as notificações externas desativados. Confira deliberadamente as configurações em vez de presumir que uma sessão silenciosa falhou. Permissões do sistema operacional e comportamento em segundo plano também precisam de verificação específica por plataforma.

**Posso instalar o aplicativo de iPhone pelo Windows?** Você pode editar e testar código Dart nele, mas a etapa real de compilação/assinatura para iPhone exige Xcode no macOS. Veja o [guia de iOS](../../apps/ios/README.md).

**O histórico comprova que aprendi mais?** Não. Duração do temporizador, conclusão e autorrelatos não são resultados objetivos de aprendizagem nem de produtividade. Respostas opcionais sobre resultados continuam ausentes quando não são respondidas.

**Preciso participar do experimento?** Não. O experimento cruzado local exige consentimento explícito, pode ser abandonado e não faz upload automaticamente. Leia o [protocolo](../LOCAL_CROSSOVER_PROTOCOL.md) antes de usá-lo.

<a id="repository-layout"></a>

## Estrutura do repositório

```text
packages/focus_core/  modelo de domínio compartilhado, migração, planejador, resultados, testes
apps/ios/             aplicativo Flutter iOS e adaptador de notificações locais
apps/windows/         aplicativo Flutter Windows e adaptador nativo de toast/bandeja
docs/                 evidências, arquitetura, privacidade e aceitação de lançamento
.github/               CI, atualizações de dependências e controles de contribuição
```

<a id="develop"></a>

## Desenvolvimento

Instale o SDK Flutter estável atual e as ferramentas da plataforma de destino. Use uma máquina de desenvolvimento Windows para o aplicativo Windows, ou macOS com Xcode para compilações iOS. Os comandos abaixo começam na raiz do repositório; os guias de plataforma detalham [Windows](../../apps/windows/README.md) e [iOS](../../apps/ios/README.md).

```powershell
cd packages\focus_core
dart pub get
dart analyze --fatal-infos
dart test

cd ..\..\apps\windows
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run -d windows
```

**Primeira ação bem-sucedida:** execute uma compilação local do aplicativo, informe um objetivo e uma ação de retomada, inicie uma sessão e depois pause e retome. Confirme que o estado exibido da sessão muda. Este é um roteiro local básico, não uma aceitação do comportamento na tela bloqueada, em suspensão/retomada ou das notificações nativas.

Execute os comandos equivalentes de análise/testes dentro de `apps/ios`. Compilar para iOS exige Xcode no macOS; assinatura e verificação de notificações em dispositivos físicos exigem um ambiente de desenvolvimento Apple.

<a id="release-status"></a>

## Status do lançamento

| Critério | Status |
|---|---|
| Testes do núcleo compartilhado | Automatizados no CI |
| Análise/testes iOS | Automatizados no CI |
| Compilação do simulador iOS | Automatizada no CI |
| Análise/testes/compilação de lançamento Windows | Automatizados no CI |
| Ciclo de vida de notificações no iPhone físico | **Pendente** |
| Toasts, Assistente de foco, suspensão/retomada e bandeja no Windows físico | **Pendente** |
| Ensaio de eficácia no nível do produto | **Não realizado** |

Esta é uma melhoria de engenharia candidata a A+, não uma declaração de lançamento A+. A aceitação do lançamento continua bloqueada até que as verificações de [Aceitação em dispositivos](../DEVICE_ACCEPTANCE.md) sejam executadas em hardware identificado e as evidências sejam anexadas.

<a id="privacy-and-security"></a>

## Privacidade e segurança

Veja [Privacidade](../PRIVACY.md), [Política de segurança](../../SECURITY.md) e [Arquitetura](../ARCHITECTURE.md). Todos os dados atuais do produto permanecem no dispositivo e podem ser removidos limpando o histórico ou desinstalando o aplicativo.

<a id="help-make-it-easier-to-use-and-verify"></a>

## Ajude a facilitar o uso e a verificação

Contribuições com escopo definido são bem-vindas, especialmente em acessibilidade, segurança das migrações, comportamento das notificações de plataforma e interações mais claras nas verificações de objetivo.

- Comece por [CONTRIBUTING.md](../../CONTRIBUTING.md) e pelos testes do módulo que você deseja alterar.
- Mantenha o comportamento compartilhado em `packages/focus_core` e o específico de cada plataforma no adaptador do aplicativo.
- Para testes em dispositivos, use [DEVICE_ACCEPTANCE.md](../DEVICE_ACCEPTANCE.md) e registre hardware, versão do software, commit, etapas e resultado observado.
- Descreva tanto as verificações que executou quanto aquelas que não pôde executar.

| Trabalho que você quer melhorar | Ponto de entrada | Verificação a incluir |
| --- | --- | --- |
| Planejamento de sinais e migração de configurações | `packages/focus_core` | Testes de domínio, entradas de migração e contratos de privacidade/valores padrão inalterados. |
| Interface da sessão ou notificações iOS | `apps/ios/lib`, `apps/ios/test` | Análise/testes de widgets; identifique separadamente qualquer verificação em dispositivo real. |
| Controle, persistência ou bandeja do Windows | `apps/windows/lib`, `apps/windows/test` | Testes relevantes de controladores/repositórios e evidências explícitas da plataforma. |
| Explicações do produto | `docs/EVIDENCE_BASE.md`, `docs/PRIVACY.md` | Consistência com os padrões reais e os limites entre evidências e afirmações. |

Para mudanças na interface, considere também ações repetidas, pausa/retomada, uma verificação pulada e sessões interrompidas. Não marque um critério de dispositivo físico como concluído apenas com base em um simulador ou adaptador simulado.

Abra uma [issue](https://github.com/son-gladyso/random-cue-focus/issues) para discutir uma mudança maior. Não envie objetivos pessoais, histórico nem exportações de pesquisa como exemplos públicos. As contribuições devem preservar as verificações opcionais, a privacidade e a distinção entre uma heurística implementada e um benefício demonstrado.
