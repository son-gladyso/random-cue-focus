# Experimental learning-mode specification

## Status

This is a product/research specification, not a shipped or validated effectiveness claim. The current timer does not become a learning intervention merely because a session was labeled “study,” lasted a certain number of minutes, or ended on schedule.

## Evidence-valid minimum loop

An experimental learning mode may ship only when it supports this complete local loop:

1. The learner identifies the material and supplies a recall prompt plus a trustworthy answer/source.
2. The learner attempts recall without viewing that source.
3. The source is revealed for verification; the learner records `correct`, `partial`, `incorrect`, or `unknown` and may save a correction.
4. A transparent, adjustable follow-up is scheduled by retention interval (for example next day, three days, seven days), without calling one schedule scientifically optimal.
5. At least one delayed retention attempt is stored separately from initial practice; an optional differently worded item may measure near transfer.

Without source verification, any accuracy value must be labeled self-report. Skipped, unknown, and missing attempts remain distinct from incorrect answers.

## Minimum local schema

- `materialId` and optional local material label
- `studyEndedAt`, `attemptAt`, and `intervalHours`
- `attemptType`: `initialPractice`, `delayedRetention`, or `nearTransfer`
- `firstAttemptCorrect`: `correct`, `partial`, `incorrect`, or `unknown`
- `responseMode`, `feedbackViewed`, `sourceVerified`, and `correctionRecorded`
- optional confidence and response latency
- optional skipped reason, distinct from an incorrect response
- schema version

Only report retention/correction/near-transfer rates when a valid denominator exists, grouped by material and retention interval. Never turn timer minutes, check responses, confidence, or immediate fluency into a memory score.

## Product constraints

- Prompts, material, and answer source are user-owned; do not generate unverified distractors or answers and present them as truth.
- Feedback must contain corrective information, not only praise, rewards, or “right/wrong.”
- Difficulty must allow successful retrieval or corrective feedback; repeated impossible retrieval without feedback is not an evidence-based dose.
- Provide an editable schedule and explain that optimal spacing depends on material and desired retention interval.
- Treat implementation intentions as optional user-authored recovery support. Do not imply that they work without motivation or prevent distraction.
- Do not infer far transfer, general intelligence, attention, “brain function,” productivity, or health.

## Release evidence gate

Before marketing a learning benefit, run a preregistered comparison with actual delayed retention, a no-retrieval or suitable active comparison, declared exclusions/missing-data handling, and accuracy by material and retention interval. Immediate performance can be a process measure, not the primary learning outcome.

## Key sources and limits

- Yang et al. (2021), classroom quizzing meta-analysis: 222 independent studies, 48,478 students, mean effect about `g = .50`, with meaningful moderators and some negative effects. [PubMed](https://pubmed.ncbi.nlm.nih.gov/33683913/)
- Rowland (2014), testing-versus-restudy meta-analysis: successful retrieval and feedback matter, especially when initial retrieval is difficult. [PubMed](https://pubmed.ncbi.nlm.nih.gov/25150680/)
- Roediger and Karpicke (2006): restudy can improve immediate performance while retrieval improves delayed retention, illustrating that performance is not learning. [PubMed](https://pubmed.ncbi.nlm.nih.gov/16507066/)
- Pan and Rickard (2018), transfer meta-analysis: transfer is stronger for near/format changes than unpracticed material or far transfer, and bias adjustment reduces estimates. [DOI](https://doi.org/10.1037/bul0000151)
- Cepeda et al. (2006), distributed-practice review: spacing benefits are broad, but useful intervals depend on the desired retention interval. [DOI](https://doi.org/10.1037/0033-2909.132.3.354)
- Wisniewski, Zierer, and Hattie (2020), feedback meta-analysis: average benefits coexist with high heterogeneity and negative effects, especially for low-information motivational feedback. [Full text](https://pmc.ncbi.nlm.nih.gov/articles/PMC6987456/)
- Theobald (2021), university self-regulated-learning training meta-analysis: small-to-moderate effects came from extended programs, not a bare timer. [DOI](https://doi.org/10.1016/j.cedpsych.2021.101976)
