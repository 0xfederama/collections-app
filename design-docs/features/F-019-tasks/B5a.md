# F019-B5a task specs: generated contract, legacy server removed (PR 11)

Branch `refactor/F019-B5a-spec`, worktree `/Users/federico/Developer/collections-app/backend-F019-B5a`. Everything is on Huma except `/healthz`, `/readyz` and the router scaffolding. Goal: `api/openapi.yaml` is GENERATED from the handlers and is the contract for `api-v1.0.0`; the hand-written spec, `oapi-codegen`, the request guard and the old problem mapper are deleted.
Rule for tests: keep every test whose subject survives; a test whose subject was deleted code (guard internals, `toProblem`, the generated strict server) is deleted ONLY if an equivalent exists elsewhere (`platform/problem`, `platform/httpserver` tests) or is re-pointed at a Huma route; list each deleted/re-pointed test in FLAGS.

## T1a · health ops on Huma, delete the legacy server
- `internal/httpapi/router.go`: split `NewRouter` into `register(api huma.API, d Deps)` (all `Register` calls, health/readiness included) and the chi/Wrap assembly; export `func API(d Deps) huma.API` that builds a chi router + `httpserver.NewAPI` + `register` and returns the API (used by specgen with a zero `Deps{}`; nothing may dereference a nil dependency at registration time). `NotFound`/`MethodNotAllowed`/`Wrap` stay.
- New `internal/httpapi/health.go` (or `internal/platform/httpserver/health.go`): Huma ops `checkHealth` (GET /healthz => 200 text/plain body `ok\n`) and `checkReadiness` (GET /readyz => 200 `ready\n` / 503 `database unavailable\n` or `storage unavailable\n`, 2 s timeout, writable probe file as today) with exactly the current bodies, content types and logging. Tag `health`. These are NOT behind the workspace scope.
- Delete `internal/httpapi/{server.go,guard.go,problem.go,paramerr.go}`, the whole `internal/httpapi/oapi/` package, `oapi-codegen.yaml`, the `go tool` directive for oapi-codegen and the `generate` step for it in the Makefile (`generate` = sqlc only; `check-generate` paths adjusted), `github.com/oapi-codegen/*` dependencies that become unused (`go mod tidy`; `oapi-codegen/nullable` too if nothing imports it). `api/openapi.yaml` is left untouched in this task (it is replaced in T1b).
- Tests: adapt `internal/httpapi/{api,internal,router}_test.go` per the rule above; the 428/400/413/404/405/headers/request-id/health tests stay (they run over HTTP on the real router). 
Must pass: `go build ./... && go vet ./... && make fmt-check && make lint && go test -count=1 ./...`.

## T1b · spec generation
- `cmd/specgen/main.go`: prints `httpapi.API(httpapi.Deps{}).OpenAPI().YAML()` (3.1) deterministically. Makefile: `spec` writes `api/openapi.yaml`; `check-spec` regenerates to a temp file and fails on diff (`diff`), added to `make check` (replace the old `lint-api` input: `lint-api` lints the generated file). `redocly.yaml`: adapt rules so the generated 3.1 file passes (document any rule turned off and why).
- Every operation needs `operationId` (the contract's current ids), `summary`, `tags` and its `Errors` statuses; add a `description` for operations whose old spec had one (take the wording from `git show origin/main:api/openapi.yaml`). Components: stable schema names (collisions like `Page`/`PathSegment`: one shared type each, in `platform/httpserver` or the owning feature).
- `Problem` schema description lists every `code` the API can return (one table in `internal/platform/problem` as the single source, also used by a test that fails when `From()` produces a code missing from it).
- Constraints the services enforce (lengths, enums, ranges) that are not Huma tags: add the documentation-only tags where they do not change runtime behaviour (min/max/enum on request fields) OR record each omission in `docs/api-notes.md` (list). Do not change runtime error shapes.
- `Optional[T].Schema` for `$ref` types must be valid 3.1 (`oneOf [ref, {type: null}]`); fix in `platform/httpserver/optional.go` with a test.
- Verify the web can consume it: `cd ../frontend-web && node_modules/.bin/openapi-typescript <spec> -o <scratchpad>/schema.d.ts` succeeds (report-only, do not touch the web repo).
Must pass: `make spec && make check-spec && make lint-api && go test ./...`.

## T2 · contract report
`docs`: `design-docs/features/F-019-contract-report.md` (written by the orchestrator, with the diff of `origin/main:api/openapi.yaml` vs the generated one via `oasdiff` in Docker: paths, operation ids, schema names, required/nullable changes, removed fields, error status changes). The worker only produces the machine diff files in the scratchpad.
