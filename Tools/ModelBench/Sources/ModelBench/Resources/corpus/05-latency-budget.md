---
uuid: a41f16e5-5621-45d4-b446-cbf87b62f33c
title: Ingest Pipeline Latency Budget
summary: Breakdown of the end-to-end latency budget for the document ingest pipeline, with per-stage measurements and the regression found in the parser.
---

The ingest pipeline has an end-to-end budget of 900 milliseconds at the ninety-fifth percentile, measured from file drop to search index commit. This budget was agreed when the pipeline was rebuilt and has not been revised since.

%%

Stage measurements at the ninety-fifth percentile are: extraction 140 milliseconds, chunking 55 milliseconds, embedding 610 milliseconds, and index commit 70 milliseconds. The total of 875 milliseconds leaves almost no headroom against the 900 millisecond budget.

%%

Embedding dominates the budget and is the only stage that scales with document length. A 40 page document pushes embedding past 2 seconds, which blows the budget outright. We currently accept this for the long tail rather than truncating input.

%%

A regression landed in the parser during the quarter and pushed extraction from 90 to 140 milliseconds. The cause was a redundant full-document scan added while fixing a table detection bug. Reverting the scan is tracked but not yet scheduled.
