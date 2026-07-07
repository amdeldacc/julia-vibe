# vibe-julia

Exploratory Julia project: pendulum ODE solvers + trig function plotting.

## Structure

- `Pendulum_Cl_Nemo/` — Own `Project.toml` + `Manifest.toml`. ODE solver with `OrdinaryDiffEq`, plots via `plotlyjs()`.
- `Pendulum_Vibe/` — Own `Project.toml` (OrdinaryDiffEq, Plots, Statistics). ODE solver with `OrdinaryDiffEq`, plots via `gr()`.
- Root `*.jl` — Standalone trig plotting scripts (tan, sin, cos, tanh). Most use `gr()` backend.

## Commands

```bash
# Run a pendulum solver (activate env first)
julia --project=Pendulum_Cl_Nemo Pendulum_Cl_Nemo/pendulum_solver.jl

# Run tests in a sub-project
julia --project=Pendulum_Cl_Nemo Pendulum_Cl_Nemo/test_pendulum.jl
julia -e 'include("Pendulum_Vibe/test_pendulum.jl")'

# Run root-level plot scripts (no Project.toml — uses default env)
julia plot_sin.jl
# Or via shell wrapper (sets DISPLAY + GKSwstype for GR/Qt):
./run_tan.sh
```

No root `Project.toml`. Pendulum_Vibe has own `Project.toml` — use `--project` or `Pkg.activate` for it. Add `--project` or `Pkg.activate` if deps are missing.

## Plotting Backends

Scripts switch backends inline with `gr()` or `plotlyjs()`. Headless PNG export needs `GKSwstype=100`. Qt interactive mode uses `GKSwstype=qt`. `show_qt_tan.sh` already sets it; `run_tan.sh` still uses `GKSwstype=100` (for headless). `plotlyjs()` saves interactive HTML and opens browser via `xdg-open`.

**Qt test note**: Qt display requires a running X server. The headless CI/container environment hangs on GKS socket connection without `GKSwstype=100`. Use `GKSwstype=100 julia script.jl` for headless verification.

## Julia Version

`julia_version = "1.12.6"` (from `Manifest.toml`).

## MCP

This repo is used with a Julia MCP server (`julia_eval` tool). Persistent REPL sessions avoid startup cost. State carries across calls within same session. Has `Revise.jl` for hot-reloading.

OpenCode is configured with `rtk` for token-efficient tool use.

## Caveats

- No CI, formatter, linter, or pre-commit hooks.
- Tests run via `julia` directly, no `runtests.jl` convention.
- Duplicated code across similar scripts — no shared library pattern.
- HEAD commit (`cb3d312`) already includes a `CLAUDE.md` with generic Julia workflow guidance.
