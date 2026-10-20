# Random Cue Focus

[简体中文](README.zh-CN.md) · [English](../../README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · Español · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [繁體中文](README.zh-TW.md)

**Vuelve a la tarea que elegiste, sin convertir cada sesión de concentración en una sucesión de alertas.**

Random Cue Focus es una aplicación complementaria Flutter que prioriza el almacenamiento local, para quienes quieren un recordatorio ocasional y opcional de su propio objetivo en iOS o Windows. La versión `0.2.0` sustituye el enfoque del prototipo basado en «micropausas» frecuentes y obligatorias por comprobaciones de objetivos espaciadas y omisibles, silenciosas y sin notificaciones de forma predeterminada.

El producto está **informado por la evidencia, pero no validado clínicamente**. Ayuda a definir un objetivo concreto, comprobar de vez en cuando si se sigue avanzando hacia él y utilizar un plan sencillo de recuperación «si… entonces…» después de una distracción. No pretende diagnosticar la atención, aumentar la productividad ni mejorar el aprendizaje por el mero uso de un temporizador.

[Prueba una sesión](#a-session-in-practice) · [Entorno de desarrollo](#develop) · [Preparación del lanzamiento](#release-status) · [Preguntas frecuentes](#common-questions) · [Colabora](#help-make-it-easier-to-use-and-verify)

<a id="when-it-may-fit"></a>

## Cuándo puede encajar

Úsalo cuando quieras retomar el contacto con tu propia tarea de forma ligera, sin convertir cada sesión de concentración en una sucesión de alertas.

- Define un objetivo concreto antes de empezar.
- Sigue trabajando durante una comprobación ocasional y opcional del objetivo.
- Si detectas una distracción, utiliza una acción de recuperación que hayas escrito tú.
- Consulta el historial local de sesiones sin crear una cuenta.

Puedes omitir una comprobación o desactivar las no esenciales durante una sesión. El objetivo es ofrecer la posibilidad de autoevaluarse sin imponer interrupciones; un temporizador o un recuento de sesiones no demuestra si te resulta útil.

<a id="a-session-in-practice"></a>

## Una sesión en la práctica

1. Establece un objetivo y una acción sencilla de recuperación: «si me distraigo, entonces…».
2. Inicia una sesión de concentración. En las instalaciones nuevas, las notificaciones y el sonido en primer plano están desactivados.
3. Cuando aparezca una comprobación, elige «sigo con el objetivo», «acabo de distraerme» u «omitir». El tiempo de concentración continúa.
4. Pausa, descansa o termina según lo necesites; después, registra opcionalmente el progreso y la carga de las interrupciones.
5. Consulta el historial guardado en tu dispositivo.

Las instrucciones de compilación y ejecución están en [Desarrollo](#develop). Todavía no hay una grabación en un dispositivo; el [estado del lanzamiento](#release-status) distingue las comprobaciones automatizadas del trabajo pendiente en dispositivos físicos.

<a id="what-is-implemented"></a>

## Qué está implementado

- Un paquete Dart compartido y probado para ajustes, modelos de sesión, migración, planificación de señales, reducción adaptativa de la carga, asignación cruzada voluntaria, resúmenes locales de resultados, perfiles de preparación de datos estratificados por condición, controles de calidad de datos y exportación de investigación que protege la privacidad.
- Aplicaciones iOS y Windows con estados de concentración/pausa/descanso/finalización, comprobaciones del objetivo, historial local y adaptadores de plataforma.
- Valores predeterminados de una instalación nueva: 50 minutos de concentración, 10 de descanso, intervalo de comprobación de 12–18 minutos, ventana de respuesta de 20 segundos, notificaciones desactivadas y sonido en primer plano desactivado.
- Respuestas explícitas: «sigo con el objetivo», «acabo de distraerme» u «omitir»; el tiempo de concentración sigue avanzando durante la comprobación.
- Las comprobaciones no esenciales pueden desactivarse para toda una sesión; los informes de distracción nunca hacen que la heurística aumente la frecuencia de las interrupciones.
- El objetivo, el desencadenante de la distracción y la siguiente acción de recuperación son editables por el usuario, no un guion universal.
- Almacenamiento exclusivamente local, sin cuenta, servidor, clave de API, SDK publicitario ni analítica remota.
- Las respuestas opcionales sobre progreso y carga de interrupciones después de una sesión se guardan localmente y quedan como datos ausentes si no se responde.
- Un estudio cruzado local experimental está disponible solo tras un consentimiento explícito. Alterna sesiones sin comprobaciones y con comprobaciones espaciadas, persiste la asignación antes de la exposición, nunca sube datos automáticamente y permite abandonarlo en cualquier momento.
- CI para pruebas del núcleo compartido, análisis/pruebas de ambas aplicaciones, compilación de lanzamiento de Windows y compilación del simulador de iOS.

Los ajustes y eventos de sesión existentes de la versión `0.1.x` se migran en lugar de descartarse silenciosamente. La versión de esquema `6` conserva todas las migraciones previas, la inscripción explícita en el estudio y la asignación por sesión, y añade una instantánea del estado real de activación de las comprobaciones, el intervalo y la ventana de respuesta para las nuevas sesiones de estudio. El esquema v2 de exportación de investigación elimina la marca temporal absoluta de asignación, además de los ID de sesión originales, las fechas y el texto libre. La cadencia adaptativa es una heurística determinista e inspeccionable, no un modelo de aprendizaje automático, y espera al menos tres sesiones y seis respuestas antes de cambiar un intervalo.

<a id="evidence-boundary"></a>

## Límites de la evidencia

El diseño da más peso a hallazgos directos y convergentes, y explicita las inferencias indirectas:

- Las alertas pueden interrumpir una tarea activa, por lo que las notificaciones externas y el sonido están desactivados de forma predeterminada.
- Las pausas breves muestran beneficios más consistentes para el vigor y la fatiga que para el rendimiento cognitivo; por eso las comprobaciones son opcionales y no se promete mejorar el rendimiento.
- Las intenciones de implementación escritas por el usuario y la automonitorización son apoyos plausibles para recuperarse de una distracción, pero las estimaciones modernas robustas frente a sesgos son menores que las de los primeros metaanálisis. Esta aplicación concreta y su intervalo predeterminado de 12–18 minutos no se han validado en un ensayo aleatorizado del producto.
- La práctica de recuperación y el aprendizaje espaciado tienen evidencia de aprendizaje más sólida, pero un temporizador por sí solo no es una intervención de práctica de recuperación.

Consulta la [Base de evidencia](../EVIDENCE_BASE.md), el [Plan de medición](../MEASUREMENT_PLAN.md), el [diccionario de datos](../DATA_DICTIONARY.md), el [protocolo de estudio cruzado local](../LOCAL_CROSSOVER_PROTOCOL.md) y la [especificación del modo experimental de aprendizaje](../LEARNING_MODE_SPEC.md) para ver la matriz entre afirmaciones y funciones, las limitaciones, el diseño de evaluación, el contrato del esquema y el ciclo mínimo de aprendizaje respaldado por evidencia.

<a id="common-questions"></a>

## Preguntas frecuentes

**¿En qué se diferencia de un temporizador de descansos obligatorios?** Una comprobación no detiene el tiempo de concentración. Puedes responder, omitirla o desactivar las comprobaciones no esenciales durante toda la sesión. El descanso sigue siendo un estado independiente.

**¿Me interrumpirá más si digo que me he distraído?** La heurística documentada de reducción de carga no aumenta la frecuencia de las interrupciones tras los autoinformes de distracción. Es determinista e inspeccionable, no un modelo de atención aprendido.

**¿Por qué no oigo recordatorios?** En las instalaciones nuevas, el sonido en primer plano y las notificaciones externas están desactivados. Revisa los ajustes de forma deliberada en lugar de asumir que una sesión silenciosa ha fallado. Los permisos del sistema operativo y el comportamiento en segundo plano también requieren verificación específica por plataforma.

**¿Puedo instalar la aplicación de iPhone desde Windows?** Allí puedes editar y probar código Dart, pero la compilación y firma reales para iPhone requieren Xcode en macOS. Consulta la [guía de iOS](../../apps/ios/README.md).

**¿El historial demuestra que he aprendido más?** No. La duración del temporizador, la finalización y los autoinformes no son resultados objetivos de aprendizaje ni de productividad. Las respuestas opcionales sobre resultados siguen ausentes si no se contestan.

**¿Tengo que participar en el experimento?** No. El estudio cruzado local requiere consentimiento explícito, se puede abandonar y no sube datos automáticamente. Consulta el [protocolo](../LOCAL_CROSSOVER_PROTOCOL.md) antes de utilizarlo.

<a id="repository-layout"></a>

## Estructura del repositorio

```text
packages/focus_core/  modelo de dominio compartido, migración, planificador, resultados, pruebas
apps/ios/             aplicación Flutter iOS y adaptador de notificaciones locales
apps/windows/         aplicación Flutter Windows y adaptador nativo de avisos toast/bandeja
docs/                 evidencia, arquitectura, privacidad y aceptación del lanzamiento
.github/               CI, actualizaciones de dependencias y controles de contribución
```

<a id="develop"></a>

## Desarrollo

Instala la versión estable actual del SDK de Flutter y las herramientas de la plataforma de destino. Utiliza un equipo de desarrollo Windows para la aplicación Windows, o macOS con Xcode para las compilaciones de iOS. Los comandos siguientes parten de la raíz del repositorio; las guías de plataforma cubren los detalles de [Windows](../../apps/windows/README.md) e [iOS](../../apps/ios/README.md).

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

**Primera acción satisfactoria:** ejecuta una compilación local de la aplicación, introduce un objetivo y una acción de recuperación, inicia una sesión y luego páusala y reanúdala. Confirma que cambia el estado mostrado. Es un recorrido local básico, no una aceptación del comportamiento de la pantalla bloqueada, la suspensión/reactivación o las notificaciones nativas.

Ejecuta los comandos equivalentes de análisis/pruebas dentro de `apps/ios`. Compilar iOS requiere Xcode en macOS; la firma y la verificación de notificaciones en dispositivos físicos requieren un entorno de desarrollo de Apple.

<a id="release-status"></a>

## Estado del lanzamiento

| Requisito | Estado |
|---|---|
| Pruebas del núcleo compartido | Automatizadas en CI |
| Análisis/pruebas de iOS | Automatizados en CI |
| Compilación del simulador de iOS | Automatizada en CI |
| Análisis/pruebas/compilación de lanzamiento de Windows | Automatizados en CI |
| Ciclo de vida de notificaciones en iPhone físico | **Pendiente** |
| Avisos toast, Asistente de concentración, suspensión/reactivación y bandeja en Windows físico | **Pendiente** |
| Ensayo de eficacia a nivel de producto | **No realizado** |

Se trata de una mejora de ingeniería candidata a A+, no de una declaración de lanzamiento A+. La aceptación del lanzamiento sigue bloqueada hasta ejecutar las comprobaciones de [Aceptación en dispositivos](../DEVICE_ACCEPTANCE.md) en hardware identificado y adjuntar la evidencia.

<a id="privacy-and-security"></a>

## Privacidad y seguridad

Consulta [Privacidad](../PRIVACY.md), [Política de seguridad](../../SECURITY.md) y [Arquitectura](../ARCHITECTURE.md). Todos los datos actuales del producto permanecen en el dispositivo y pueden eliminarse borrando el historial o desinstalando la aplicación.

<a id="help-make-it-easier-to-use-and-verify"></a>

## Ayuda a facilitar su uso y verificación

Son bienvenidas las contribuciones de alcance concreto, especialmente sobre accesibilidad, seguridad de las migraciones, comportamiento de las notificaciones de plataforma e interacciones de comprobación más claras.

- Empieza por [CONTRIBUTING.md](../../CONTRIBUTING.md) y las pruebas del módulo que quieras cambiar.
- Mantén el comportamiento compartido en `packages/focus_core` y el específico de cada plataforma en su adaptador de aplicación.
- Para las pruebas en dispositivos, utiliza [DEVICE_ACCEPTANCE.md](../DEVICE_ACCEPTANCE.md) y registra el hardware, la versión del software, el commit, los pasos y el resultado observado.
- Describe tanto las comprobaciones realizadas como las que no pudiste realizar.

| Trabajo que quieres mejorar | Punto de entrada | Verificación que debes incluir |
| --- | --- | --- |
| Planificación de señales y migración de ajustes | `packages/focus_core` | Pruebas de dominio, entradas de migración y conservación de los contratos de privacidad/valores predeterminados. |
| Interfaz de sesión o notificaciones de iOS | `apps/ios/lib`, `apps/ios/test` | Análisis/pruebas de widgets; identifica por separado cualquier comprobación en dispositivos reales. |
| Control, persistencia o bandeja de Windows | `apps/windows/lib`, `apps/windows/test` | Pruebas relevantes de controladores/repositorios y evidencia explícita de plataforma. |
| Explicaciones del producto | `docs/EVIDENCE_BASE.md`, `docs/PRIVACY.md` | Coherencia con los valores predeterminados reales y los límites entre evidencia y afirmaciones. |

Para un cambio de interfaz, considera también las acciones repetidas, la pausa/reanudación, una comprobación omitida y las sesiones interrumpidas. No marques como completado un requisito de dispositivo físico basándote solo en un simulador o un adaptador simulado.

Abre una [incidencia](https://github.com/son-gladyso/random-cue-focus/issues) para debatir un cambio importante. No envíes objetivos personales, historial ni exportaciones de investigación como ejemplos públicos. Las contribuciones deben preservar el carácter opcional de las comprobaciones, la privacidad y la diferencia entre una heurística implementada y un beneficio demostrado.
