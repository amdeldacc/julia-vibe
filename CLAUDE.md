# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose and Scope

**vibe-julia** is a Julia visualization package that generates mathematical function plots and pendulum simulations using multiple output formats: PlotlyJS HTML, PNG images, GR plots, Qt GUIs, and browser-based JavaScript displays. The project includes supporting MCP server utilities for Julia execution (see [julia-mcp-analysis.md](julia-mcp-analysis.md)).

### Core Components
- **Function plotting**: `plot_tan.jl`, `plot_sin.jl`, `plot_cos.jl`, `plot_tanh.jl` — generate PNG images and HTML previews of trigonometric functions.
- **Display utilities**: `show_tan_browser.jl`, `display_tan.jl`, `tan_plot.html` — provide various ways to view rendered plots in browsers or as static files.
- **Pendulum simulations**: Subdirectories `Pendulum_Vibe/` and `Pendulum_Cl_Nemo/` contain pendulum motion visualizations with phase portraits and animations (PNG outputs).
- **Qt integration**: `qt_tan.jl`, `show_qt_tan.sh`, `run_tan.sh` — Qt-based GUI wrappers for interactive viewing.

### Repository Structure
```
/home/piou/vibe-julia/
├── .gitignore                  # Ignores node_modules, generated PNGs, etc.
├── Manifest.toml              # Julia dependency resolution output
└── Pendulum_*/*               # Two pendulum simulation subdirectories with tests and outputs
```

## Julia Development Workflow

### Project Environment Management
- This repo uses Julia project environments (Manifest.toml). When invoking the MCP server `julia_eval`, always provide an absolute `env_path` pointing to this repository root so dependencies are resolved from the correct environment.
- Prefer using the MCP tools (`mcp__julia__julia_eval`) over direct subprocess calls — they handle persistent REPL sessions, state preservation, and hot-reloading via Revise.jl automatically.

### Package Management
- The project depends on **Revise.jl** (auto-loaded by the MCP server for in-project code) and standard packages used in plotting code (e.g., PlotlyJS, GR).
- Never attempt to run `Pkg.add` or modify Manifest.toml directly without confirmation — these are managed automatically through the Julia-MCP infrastructure.

### Code Style Guidelines
- Follow Julia 1.x idioms: use `end` for scoping blocks rather than `else end`, prefer explicit type annotations in function signatures when helpful, and maintain consistent spacing around binary operators.
- For plotting code, always specify reasonable axis limits and labels — the generated PNGs should be self-documenting at minimum 800×600 resolution.

## Generated Output Policy

All `.png` files under this repository are **generated artifacts** from Julia plotting scripts:
- `plot_tan.png`, `tan_plot.png`, etc. come from `plot_tan.jl` and related scripts
- These PNGs should never be edited manually — they represent rendered mathematical visualizations with precise axis scales, legends, and color maps baked into them

## Test Suite Information

The project includes Julia test files:
- In root: implicit inline tests within plotting scripts (the MCP server can run these via `julia_eval("using Test; @testset ...")`)
- In subdirectories (`Pendulum_Vibe/test_pendulum.jl`, `Pendulum_Cl_Nemo/test_pendulum.jl`): standalone test suites using Julia's built-in `Test` framework

When running tests, prefer calling the MCP server with code that invokes these test modules — they'll automatically benefit from Revise.jl hot-reloading and proper environment scoping.
