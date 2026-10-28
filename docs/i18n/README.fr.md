# Random Cue Focus

[简体中文](README.zh-CN.md) · [English](../../README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · Français · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [繁體中文](README.zh-TW.md)

**Transformez « il faut étudier » en une prochaine étape concrète, avec un point de reprise après une distraction.**

Random Cue Focus est un compagnon d’étude Flutter privilégiant le stockage local, pour iOS et Windows. Définissez un objectif, écrivez une petite action de reprise et utilisez des vérifications facultatives sans arrêter le minuteur. L’historique local et l’évaluation facultative des progrès aident à réfléchir à la séance.

Utilisez-le avec vos livres, exercices ou notes : il soutient la planification et le suivi de l’apprentissage. La version `0.2.0` propose des vérifications espacées, ignorables, silencieuses et sans notification par défaut.

[Essayer une séance](#a-session-in-practice) · [Environnement de développement](#develop) · [Préparation de la version](#release-status) · [Questions fréquentes](#common-questions) · [Contribuer](#help-make-it-easier-to-use-and-verify)

<a id="learning-workflow"></a>

## L’utiliser pendant une séance d’étude

Remplacez « étudier la biologie » par « lire la division cellulaire et écrire trois différences entre mitose et méiose ». Ajoutez « si j’ouvre un onglet sans rapport, je reviens au paragraphe suivant et j’écris une comparaison ». Lors d’une vérification facultative, retrouvez l’objectif ou continuez à lire ; ensuite, notez ce que vous avez réalisé et la gêne occasionnée.

Pour les exercices, précisez les problèmes et l’étape de reprise ; pour réviser, choisissez les notions à rappeler et expliquer avec vos supports. Lire, résoudre, rappeler et vérifier vous revient. Le plan modifiable n’est pas un accompagnement automatique.

<a id="when-it-may-fit"></a>

## Dans quels cas l’utiliser

Utilisez-le si vous cherchez un moyen léger de revenir à votre propre tâche sans transformer chaque séance de concentration en une succession d’alertes.

- Définissez un objectif concret avant de commencer.
- Continuez à travailler pendant une vérification occasionnelle et facultative de l’objectif.
- Si vous remarquez une distraction, utilisez une action de reprise que vous avez vous-même écrite.
- Consultez l’historique local des séances sans créer de compte.

Vous pouvez ignorer une vérification ou désactiver celles qui ne sont pas essentielles pour une séance. Le but est de rendre l’auto-évaluation possible sans imposer d’interruption ; un minuteur ou un nombre de séances ne permet pas d’établir si cela vous aide.

<a id="a-session-in-practice"></a>

## Une séance en pratique

1. Définissez un objectif et une action simple de reprise : « si je me laisse distraire, alors… ».
2. Lancez une séance de concentration. Sur une nouvelle installation, les notifications et le son au premier plan sont désactivés.
3. Lorsqu’une vérification apparaît, choisissez « toujours sur mon objectif », « je viens d’être distrait » ou « ignorer ». Le temps de concentration continue de s’écouler.
4. Mettez en pause, reposez-vous ou arrêtez selon vos besoins, puis enregistrez éventuellement votre progression et la gêne occasionnée par les interruptions.
5. Consultez l’historique stocké sur votre appareil.

Les instructions de compilation et d’exécution figurent dans [Développement](#develop). Aucune vidéo sur appareil n’est encore fournie ici ; l’[état de la version](#release-status) distingue les vérifications automatisées du travail restant sur appareils physiques.

<a id="what-is-implemented"></a>

## Fonctionnalités implémentées

- Un package Dart partagé et testé pour les réglages, les modèles de séance, les migrations, la planification des signaux, la réduction adaptative de la gêne, l’affectation volontaire à un protocole croisé, les résumés locaux des résultats, le profilage de la disponibilité des données stratifié par condition, les contrôles de qualité des données et l’export de recherche respectueux de la vie privée.
- Des applications iOS et Windows avec les états concentration/pause/repos/arrêt, des vérifications d’objectif, un historique local et des adaptateurs de plateforme.
- Valeurs par défaut d’une nouvelle installation : 50 minutes de concentration, 10 minutes de repos, intervalle de vérification de 12 à 18 minutes, fenêtre de réponse de 20 secondes, notifications désactivées, son au premier plan désactivé.
- Réponses explicites : « toujours sur mon objectif », « je viens d’être distrait » ou « ignorer » ; le temps de concentration continue pendant la vérification.
- Les vérifications non essentielles peuvent être désactivées pour toute une séance ; un signalement de distraction n’amène jamais l’heuristique à augmenter la fréquence des interruptions.
- L’objectif, le déclencheur de distraction et l’action de reprise suivante sont modifiables par l’utilisateur, plutôt que traités comme un scénario universel.
- Stockage exclusivement local, sans compte, serveur, clé API, SDK publicitaire ni analyse à distance.
- Les réponses facultatives après séance sur la progression et la gêne liée aux interruptions sont enregistrées localement et restent manquantes si l’utilisateur ne répond pas.
- Un protocole croisé local expérimental n’est accessible qu’après consentement explicite. Il alterne les séances sans vérification et celles avec vérifications espacées, enregistre durablement l’affectation avant l’exposition, ne téléverse jamais automatiquement de données et peut être quitté à tout moment.
- Une CI pour les tests du cœur partagé, l’analyse et les tests des deux applications, la compilation de production Windows et la compilation pour simulateur iOS.

Les réglages et événements de séance existants de la version `0.1.x` sont migrés plutôt que supprimés silencieusement. La version `6` du schéma conserve toutes les migrations antérieures, l’inscription explicite à l’étude et l’affectation par séance, tout en ajoutant, pour les nouvelles séances d’étude, un instantané de l’activation réelle des vérifications, de leur intervalle et de la fenêtre de réponse. Le schéma v2 d’export de recherche supprime l’horodatage absolu d’affectation ainsi que les identifiants bruts de séance, les dates et le texte libre. La cadence adaptative est une heuristique déterministe et vérifiable, pas un modèle d’apprentissage automatique, et attend au moins trois séances et six réponses avant de modifier un intervalle.

<a id="evidence-boundary"></a>
<a id="limites-des-données-scientifiques"></a>

## Les recherches qui orientent le parcours

| Recherche et expérience | Résultat | Lien et limite |
| --- | --- | --- |
| [Gollwitzer & Sheeran (2006)](https://doi.org/10.1016/S0065-2601(06)38002-1) | La méta-analyse des plans si–alors observe un bénéfice moyen dans des contextes variés ; les estimations récentes robustes aux biais sont plus faibles. | Appuie un plan de reprise personnel ; ne prouve pas un bénéfice des rappels aléatoires pour apprendre. |
| [Harkin et al. (2016)](https://doi.org/10.1037/bul0000025) | 138 études randomisées, 19 951 participants : favoriser le suivi améliore en moyenne l’atteinte des objectifs. | Appuie les vérifications et la réflexion ; ne teste ni cette app ni les notes scolaires. |
| [Stothart et al. (2015)](https://doi.org/10.1037/xhp0000100) | Les notifications perturbent une tâche d’attention même sans utiliser le téléphone. | Oriente les vérifications silencieuses et facultatives ; ne valide pas l’intervalle de 12–18 minutes. |

**Ces expériences portent sur des méthodes et processus associés, pas sur des gains mesurés avec cette app.** Aucun essai du produit sur les apprentissages n’a été réalisé. L’intervalle est une heuristique réglable. Le croisement local compare conditions et expérience ; aucun résultat n’est rapporté. Historique et autoévaluations ne sont pas des scores d’apprentissage.

Le rappel et l’espacement sont étayés, mais l’app actuelle ne propose ni questions de rappel, ni correction, ni révision programmée du contenu. Le [mode d’apprentissage](../LEARNING_MODE_SPEC.md) reste une spécification. Une future évaluation pourrait comparer rétention différée, transfert et gêne ; elle n’a pas été menée.

Voir les [sources et limites](../EVIDENCE_BASE.md), le [plan de mesure](../MEASUREMENT_PLAN.md), le [dictionnaire de données](../DATA_DICTIONARY.md) et le [protocole croisé local](../LOCAL_CROSSOVER_PROTOCOL.md).

<a id="common-questions"></a>

## Questions fréquentes

**En quoi est-ce différent d’un minuteur de pauses obligatoires ?** Une vérification ne suspend pas le temps de concentration. Vous pouvez répondre, l’ignorer ou désactiver les vérifications non essentielles pour toute la séance. Le repos reste un état distinct.

**Serai-je davantage interrompu si je signale une distraction ?** L’heuristique documentée de réduction de la gêne n’augmente pas la fréquence des interruptions après des déclarations de distraction. Elle est déterministe et vérifiable, et non un modèle d’attention appris.

**Pourquoi n’entends-je aucun rappel ?** Les nouvelles installations désactivent le son au premier plan et les notifications externes. Vérifiez volontairement les réglages plutôt que de supposer qu’une séance silencieuse a échoué. Les autorisations du système et le comportement en arrière-plan demandent aussi une vérification propre à chaque plateforme.

**Puis-je installer l’application iPhone depuis Windows ?** Vous pouvez y modifier et tester le code Dart, mais la compilation et la signature réelles pour iPhone nécessitent Xcode sur macOS. Consultez le [guide iOS](../../apps/ios/README.md).

**L’historique prouve-t-il que j’ai mieux appris ?** Non. La durée du minuteur, la fin des séances et les auto-déclarations ne sont pas des résultats objectifs d’apprentissage ou de productivité. Les réponses facultatives sur les résultats restent manquantes lorsqu’aucune réponse n’est donnée.

**Dois-je participer à l’expérience ?** Non. Le protocole croisé local exige un consentement explicite, peut être quitté et ne téléverse pas automatiquement de données. Consultez le [protocole](../LOCAL_CROSSOVER_PROTOCOL.md) avant de l’utiliser.

<a id="repository-layout"></a>

## Organisation du dépôt

```text
packages/focus_core/  modèle métier partagé, migrations, planificateur, résultats, tests
apps/ios/             application Flutter iOS et adaptateur de notifications locales
apps/windows/         application Flutter Windows et adaptateur natif toast/zone de notification
docs/                 données scientifiques, architecture, confidentialité, acceptation de version
.github/               CI, mises à jour des dépendances et contrôles des contributions
```

<a id="develop"></a>

## Développement

Installez le SDK Flutter stable actuel et les outils de votre plateforme cible. Utilisez un poste Windows pour l’application Windows, ou macOS avec Xcode pour les compilations iOS. Les commandes ci-dessous partent de la racine du dépôt ; les guides de plateforme détaillent [Windows](../../apps/windows/README.md) et [iOS](../../apps/ios/README.md).

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

**Première action réussie :** exécutez une compilation locale de l’application, saisissez un objectif et une action de reprise, lancez une séance, puis mettez-la en pause et reprenez-la. Vérifiez que l’état affiché change. Il s’agit d’un parcours local élémentaire, pas d’une validation du comportement sur écran verrouillé, en veille/réveil ou des notifications natives.

Exécutez les commandes équivalentes d’analyse et de test dans `apps/ios`. La compilation iOS exige Xcode sur macOS ; la signature et la vérification des notifications sur appareil physique exigent un environnement de développement Apple.

<a id="release-status"></a>

## État de la version

| Critère | État |
|---|---|
| Tests du cœur partagé | Automatisés en CI |
| Analyse/tests iOS | Automatisés en CI |
| Compilation pour simulateur iOS | Automatisée en CI |
| Analyse/tests/compilation de production Windows | Automatisés en CI |
| Cycle de vie des notifications sur iPhone physique | **En attente** |
| Notifications toast, Assistant de concentration, veille/réveil et zone de notification sur Windows physique | **En attente** |
| Essai d’efficacité au niveau du produit | **Non réalisé** |

Il s’agit d’une amélioration technique candidate au niveau A+, et non d’une déclaration de version A+. L’acceptation de la version reste bloquée jusqu’à l’exécution des contrôles d’[Acceptation sur appareils](../DEVICE_ACCEPTANCE.md) sur du matériel identifié, avec pièces justificatives.

<a id="privacy-and-security"></a>

## Confidentialité et sécurité

Consultez [Confidentialité](../PRIVACY.md), [Politique de sécurité](../../SECURITY.md) et [Architecture](../ARCHITECTURE.md). Toutes les données actuelles du produit restent sur l’appareil et peuvent être supprimées en effaçant l’historique ou en désinstallant l’application.

<a id="help-make-it-easier-to-use-and-verify"></a>

## Aidez à simplifier l’utilisation et la vérification

Les contributions ciblées sont les bienvenues, notamment en matière d’accessibilité, de sécurité des migrations, de notifications des plateformes et d’interactions plus claires pour les vérifications d’objectif.

- Commencez par [CONTRIBUTING.md](../../CONTRIBUTING.md) et les tests du module à modifier.
- Conservez les comportements partagés dans `packages/focus_core` et les comportements propres à une plateforme dans l’adaptateur de son application.
- Pour les tests sur appareils, utilisez [DEVICE_ACCEPTANCE.md](../DEVICE_ACCEPTANCE.md) et indiquez le matériel, la version logicielle, le commit, les étapes et le résultat observé.
- Décrivez à la fois les vérifications exécutées et celles que vous n’avez pas pu effectuer.

| Travail à améliorer | Point d’entrée | Vérification à inclure |
| --- | --- | --- |
| Planification des signaux et migration des réglages | `packages/focus_core` | Tests métier, entrées de migration et maintien des contrats de confidentialité et de valeurs par défaut. |
| Interface de séance ou notifications iOS | `apps/ios/lib`, `apps/ios/test` | Analyse/tests de widgets ; précisez séparément les vérifications sur appareils réels. |
| Contrôle, persistance ou zone de notification Windows | `apps/windows/lib`, `apps/windows/test` | Tests pertinents des contrôleurs/dépôts et éléments probants explicites de plateforme. |
| Explications du produit | `docs/EVIDENCE_BASE.md`, `docs/PRIVACY.md` | Cohérence avec les valeurs par défaut réelles et les limites des preuves et des affirmations. |

Pour une modification d’interface, pensez aussi aux actions répétées, à la pause/reprise, à une vérification ignorée et aux séances interrompues. Ne marquez pas un critère d’appareil physique comme terminé sur la seule base d’un simulateur ou d’un adaptateur simulé.

Ouvrez une [issue](https://github.com/son-gladyso/random-cue-focus/issues) pour discuter d’une modification importante. Ne soumettez pas d’objectifs personnels, d’historique ou d’exports de recherche comme exemples publics. Les contributions doivent préserver le caractère facultatif des vérifications, la confidentialité et la distinction entre une heuristique implémentée et un bénéfice démontré.
