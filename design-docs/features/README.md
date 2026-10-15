# Feature briefs

One file per feature: `F-NNN-<slug>.md`. The **top-level orchestrator** writes it with the user (AGENT_WORKFLOW §1b);
each **repo orchestrator** fills in its "Repo breakdown" and works through its stories with `worker` agents.
The roadmap ([`ROADMAP.md`](../../ROADMAP.md)) lists every feature with its horizon and status.

States: `draft` (being discussed) → `approved` (user OK, repo orchestrators may start) → `in progress` → `done` (all PRs merged).

## Starting the repo orchestrators for a feature

Start a session in `backend/` or `frontend-web/` with **Opus 5.5, medium effort**, then send:

```text
You are the <backend|web> orchestrator. Follow /Users/federico/Developer/collections-app/design-docs/AGENT_WORKFLOW.md (v2, §1b). Implement the <backend|web> stories of /Users/federico/Developer/collections-app/design-docs/features/<F-NNN-file>.md: fill in its Repo breakdown, dispatch `worker` agents, review only their FLAGS, run the gate, open one PR per story, keep STATUS.md current.
```

A repo orchestrator can stay alive across features. Start a fresh one when its context gets large.

## Template

```markdown
# F-NNN — <title>

Status: draft | approved | in progress | done    Release: <1.x / 2.0>    Roadmap: ROADMAP.md §<n>
Repos: backend | web | parent    Approved by the user: <date>

## Why
<problem and the outcome for the user, 2–4 sentences>

## User stories
### Backend
- **F<NNN>-B1**: As <who>, I want <what>, so that <why>.
  Acceptance: <observable checks; AT ids if any>
### Web
- **F<NNN>-W1**: As <who>, I want <what>, so that <why>.
  Acceptance: <...>
### Parent / ops (top-level orchestrator)
- ...

## Contract impact
<new/changed endpoints, additive or breaking, tag to cut (api-v0.N.0), order: backend story X before web story Y. "None" if none>

## Constraints and decisions already made
<D-entries, design-doc sections, things that must not change>

## Out of scope
- ...

## Open questions
| ID | Question | Default |

## Repo breakdown (filled by the repo orchestrators)
### Backend
| Task | Story | Branch | Worker result | Flags reviewed | PR |
### Web
| Task | Story | Branch | Worker result | Flags reviewed | PR |

## Log
- <date>: <one line>
```
