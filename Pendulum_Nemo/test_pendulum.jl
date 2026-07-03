using Test
using DiffEqBase

# Include the pendulum solver functions
include("pendulum_solver.jl")

@testset "Pendulum Solver Tests" begin
    # Test 1: Default parameters
    sol = solve_pendulum()
    @test typeof(sol) <: DiffEqBase.AbstractODESolution
    @test size(sol, 1) == 2  # Two components (angle and angular velocity)
    @test length(sol.t) > 0

    # Test 2: Initial conditions
    θ0 = π/4
    ω0 = 0.0
    sol_ic = solve_pendulum(θ0=θ0, ω0=ω0)
    @test sol_ic.t[1] ≈ 0.0
    @test sol_ic[1,1] ≈ θ0 atol=1e-6
    @test sol_ic[2,1] ≈ ω0 atol=1e-6

    # Test 3: Different length
    L = 2.0
    sol_L = solve_pendulum(L=L)
    @test all(isfinite, sol_L[1, :])  # Angle should be finite
    @test all(isfinite, sol_L[2, :])  # Angular velocity should be finite

    # Test 4: Different initial angle
    θ0_large = π/2  # 90 degrees
    sol_large = solve_pendulum(θ0=θ0_large)
    @test sol_large[1,1] ≈ θ0_large atol=1e-6

    # Test 5: Zero initial angle and zero initial velocity should stay at zero (equilibrium)
    sol_eq = solve_pendulum(θ0=0.0, ω0=0.0)
    @test all(abs.(sol_eq[1, :]) .< 1e-6)  # Angle should remain near zero
    @test all(abs.(sol_eq[2, :]) .< 1e-6)  # Angular velocity should remain near zero

    # Test 6: Check that the plotting function doesn't throw (we'll just call it and check it returns nothing)
    # We'll use a temporary file for the plot
    @test_nowarn plot_pendulum(sol; filename_html="test_plot.html", filename_png="test_plot.png")
    # Clean up the test files
    rm("test_plot.html"; force=true)
    rm("test_plot.png"; force=true)
end

println("All tests passed!")