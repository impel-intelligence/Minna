---
uuid: 5df70c12-fcf5-44ed-a888-2b5d64f264de
title: Storage Engine Migration Postmortem
summary: Postmortem of the storage engine migration, covering the rollback trigger, the duration of degraded service, and the follow-up actions.
---

The migration moved the primary document store from the legacy engine to the new one over a planned four hour window. Traffic was shifted in three stages, at ten percent, fifty percent, and one hundred percent.

%%

Rollback was triggered 26 minutes after the fifty percent stage began, when write latency at the ninety-ninth percentile crossed 4 seconds. The agreed rollback trigger was 3 seconds sustained for five minutes, so the call was made slightly late.

%%

Service was degraded for 51 minutes in total. No data was lost, because the dual-write path remained active throughout, but 1,840 write operations were retried after the rollback completed.

%%

The root cause was an unindexed foreign key in the new schema that only became expensive above roughly thirty percent of production write volume. Our staging environment runs at five percent of production volume and could not have surfaced it.

%%

Follow-up actions agreed: add a load stage at forty percent of production volume before any future migration, and automate the rollback trigger rather than relying on a human call.
