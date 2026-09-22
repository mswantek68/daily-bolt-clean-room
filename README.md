---
title: Daily Bolt Clean Room
description: Clean-room repository for testing the portability of the Daily Bolt engineering operating model
author: Mike Swantek
ms.date: 2026-09-22
ms.topic: concept
---

## Daily Bolt Clean Room

This repository is an isolated portability experiment for the Daily Bolt
engineering operating model.

The repository begins without history, implementation, architecture, product
code, prior Bolt records, or artifacts from the original Agentic Daily Bolt
repository. Its foundation exists only to establish independent source
control, validation, and pull-request governance.

## Experiment boundary

The initial foundation contains:

* Repository documentation and ignore rules
* Markdown and repository validation
* GitHub Actions automation for pull requests and merge groups
* A durable clean-room evidence record

The initial foundation does not contain:

* The Daily Bolt operating model
* A sample Bolt or numbered Bolt record
* Product implementation
* Copied files or inherited Git history from another repository

See [the clean-room experiment record](./docs/clean-room-experiment.md) for
bootstrap evidence and readiness status.
