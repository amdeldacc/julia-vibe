"""
Test suite for pendulum.jl

Comprehensive tests for the pendulum ODE solver and related functions.
"""

using Test
using OrdinaryDiffEq
using Statistics
using Plots: Plot  # Import Plot type

# Include the main pendulum module
include("pendulum.jl")

@testset "Pendulum ODE Solver Tests" begin

    # Constants for testing (already defined in pendulum.jl when included)
    # g = 9.81
    # L = 1.0
    
    @testset "ODE Function Tests" begin
        
        @testset "pendulum_ode! function" begin
            # Test at θ = 0, ω = 0 (equilibrium position at rest)
            du = zeros(2)
            u = [0.0, 0.0]  # [θ, ω]
            p = nothing
            t = 0.0
            
            pendulum_ode!(du, u, p, t)
            
            # At θ=0, ω=0: dθ/dt = ω = 0, dω/dt = -g/L * sin(0) = 0
            @test du[1] == 0.0  # dθ/dt = ω = 0
            @test du[2] == 0.0  # dω/dt = -g/L * sin(0) = 0
            
            # Test at θ = π/2, ω = 0 (pendulum at horizontal position)
            du = zeros(2)
            u = [π/2, 0.0]
            pendulum_ode!(du, u, p, t)
            
            @test du[1] == 0.0  # dθ/dt = ω = 0
            @test isapprox(du[2], -g/L, rtol=1e-10)  # dω/dt = -g/L * sin(π/2) = -g/L
            
            # Test at θ = π/4, ω = 1.0
            du = zeros(2)
            u = [π/4, 1.0]
            pendulum_ode!(du, u, p, t)
            
            @test du[1] == 1.0  # dθ/dt = ω = 1.0
            @test isapprox(du[2], -g/L * sin(π/4), rtol=1e-10)  # dω/dt = -g/L * sin(π/4)
        end
        
        @testset "Dimensional consistency" begin
            # Test that the units work out dimensionally
            du = zeros(2)
            u = [1.0, 2.0]  # [rad, rad/s]
            p = nothing
            t = 0.0
            
            pendulum_ode!(du, u, p, t)
            
            # du[1] should have units of rad/s (same as ω)
            # du[2] should have units of rad/s^2
            @test du[1] == u[2]  # rad/s = rad/s ✓
            @test isapprox(du[2], - (g / L) * sin(u[1]), rtol=1e-10)  # rad/s^2 = (m/s^2)/m * dimensionless ✓
        end
    end
    
    @testset "Solution Function Tests" begin
        
        @testset "Basic solution properties" begin
            # Test basic solution with small angle
            θ₀ = deg2rad(5.0)  # 5 degrees
            ω₀ = 0.0
            tspan = (0.0, 10.0)
            
            sol = solve_pendulum(θ₀, ω₀, tspan, saveat=0.01)
            
            # Test solution structure
            @test typeof(sol) <: Any  # Solution object from OrdinaryDiffEq
            @test length(sol.t) > 0
            @test length(sol.u) == length(sol.t)
            
            # Test initial conditions
            @test isapprox(sol.u[1][1], θ₀, rtol=1e-10)
            @test isapprox(sol.u[1][2], ω₀, rtol=1e-10)
            
            # Test time span
            @test isapprox(sol.t[1], tspan[1], rtol=1e-10)
            @test isapprox(sol.t[end], tspan[2], rtol=1e-10)
        end
        
        @testset "Energy conservation" begin
            # Test that total mechanical energy is approximately conserved
            θ₀ = deg2rad(10.0)  # 10 degrees
            ω₀ = 0.0
            tspan = (0.0, 5.0)
            
            sol = solve_pendulum(θ₀, ω₀, tspan, saveat=0.001)
            energy = calculate_energy(sol)
            
            # Energy should be conserved (constant)
            initial_energy = energy[1]
            final_energy = energy[end]
            
            # Allow for small numerical errors
            energy_tolerance = 0.01  # 1% tolerance
            energy_error = abs(final_energy - initial_energy) / initial_energy
            
            @test energy_error < energy_tolerance
            
            # Test that energy doesn't drift significantly over time
            energy_std = std(energy)
            energy_mean = mean(energy)
            @test energy_std / energy_mean < 0.01  # Less than 1% variation
        end
        
        @testset "Period accuracy for small angles" begin
            # Test that the period matches the theoretical value for small angles
            θ₀ = deg2rad(2.0)  # 2 degrees (small angle)
            ω₀ = 0.0
            tspan = (0.0, 15.0)  # Simulate long enough for multiple periods
            
            sol = solve_pendulum(θ₀, ω₀, tspan, saveat=0.001)
            
            # Calculate period from solution
            θ_values = [u[1] for u in sol.u]
            t_values = sol.t
            
            peaks = Vector{Float64}()
            for i in 2:length(θ_values)-1
                if θ_values[i] > θ_values[i-1] && θ_values[i] > θ_values[i+1]
                    push!(peaks, t_values[i])
                end
            end
            
            @test length(peaks) >= 2  # Should have at least 2 peaks
            
            if length(peaks) >= 2
                periods = diff(peaks)
                actual_period = mean(periods)
                
                # Theoretical period: T = 2π√(L/g)
                expected_period = 2 * π * sqrt(L / g)
                
                # For small angles, the actual period should be very close to theoretical
                period_error = abs(actual_period - expected_period) / expected_period
                
                @test period_error < 0.01  # Less than 1% error for small angles
            end
        end
    end
    
    @testset "Energy Calculation Tests" begin
        
        @testset "Energy calculation function" begin
            # Create a simple solution for testing
            θ₀ = deg2rad(30.0)
            ω₀ = 1.0
            tspan = (0.0, 1.0)
            
            sol = solve_pendulum(θ₀, ω₀, tspan, saveat=0.1)
            energy = calculate_energy(sol)
            
            # Test that energy has the right length
            @test length(energy) == length(sol.t)
            
            # Test that energy values are positive (for reasonable initial conditions)
            @test all(e -> e >= 0, energy)  # Energy should be non-negative
            
            # Test energy at rest position with some velocity
            θ_rest = 0.0
            ω_rest = 2.0
            u_rest = [θ_rest, ω_rest]
            
            # Manually calculate expected energy
            m = 1.0  # mass used in calculate_energy
            KE_expected = 0.5 * m * (L * ω_rest)^2
            PE_expected = m * g * L * (1 - cos(θ_rest))
            E_expected = KE_expected + PE_expected
            
            # Create a solution with just this state
            prob_rest = ODEProblem(pendulum_ode!, u_rest, (0.0, 0.1))
            sol_rest = solve(prob_rest, Tsit5(), saveat=0.1)
            energy_rest = calculate_energy(sol_rest)
            
            @test isapprox(energy_rest[1], E_expected, rtol=1e-10)
        end
        
        @testset "Energy at maximum height" begin
            # At maximum height (θ = π), ω = 0
            θ_max = π
            ω_max = 0.0
            u_max = [θ_max, ω_max]
            
            m = 1.0
            KE_expected = 0.5 * m * (L * ω_max)^2  # = 0
            PE_expected = m * g * L * (1 - cos(θ_max))  # = 2*m*g*L
            E_expected = KE_expected + PE_expected
            
            prob_max = ODEProblem(pendulum_ode!, u_max, (0.0, 0.1))
            sol_max = solve(prob_max, Tsit5(), saveat=0.1)
            energy_max = calculate_energy(sol_max)
            
            @test isapprox(energy_max[1], E_expected, rtol=1e-10)
        end
    end
    
    @testset "Edge Case Tests" begin
        
        @testset "Zero initial conditions" begin
            # Pendulum starting at rest from equilibrium position
            θ₀ = 0.0
            ω₀ = 0.0
            tspan = (0.0, 5.0)
            
            sol = solve_pendulum(θ₀, ω₀, tspan, saveat=0.01)
            
            # Should stay at rest (within numerical precision)
            for u in sol.u
                @test abs(u[1]) < 1e-6  # θ should stay near 0
                @test abs(u[2]) < 1e-6  # ω should stay near 0
            end
        end
        
        @testset "Large initial angle" begin
            # Test with initial angle near π (almost upside down)
            θ₀ = π - 0.1  # 10 degrees from upside down
            ω₀ = 0.0
            tspan = (0.0, 2.0)
            
            sol = solve_pendulum(θ₀, ω₀, tspan, saveat=0.01)
            
            # Should work without errors
            @test length(sol.t) > 0
            
            # Energy should still be conserved
            energy = calculate_energy(sol)
            initial_energy = energy[1]
            final_energy = energy[end]
            energy_error = abs(final_energy - initial_energy) / initial_energy
            
            @test energy_error < 0.05  # Allow 5% tolerance for large angles
        end
        
        @testset "Different pendulum lengths" begin
            # Test with different lengths by modifying the global constant
            # Note: We'll create a local version for testing
            local L_test = 2.0  # 2m pendulum
            
            function pendulum_ode_test!(du, u, p, t)
                θ = u[1]
                ω = u[2]
                du[1] = ω
                du[2] = - (g / L_test) * sin(θ)
            end
            
            u₀ = [deg2rad(5.0), 0.0]
            tspan = (0.0, 10.0)
            prob = ODEProblem(pendulum_ode_test!, u₀, tspan)
            sol = solve(prob, Tsit5(), saveat=0.01)
            
            # Theoretical period for 2m pendulum
            expected_period = 2 * π * sqrt(L_test / g)
            
            θ_values = [u[1] for u in sol.u]
            t_values = sol.t
            
            peaks = Vector{Float64}()
            for i in 2:length(θ_values)-1
                if θ_values[i] > θ_values[i-1] && θ_values[i] > θ_values[i+1]
                    push!(peaks, t_values[i])
                end
            end
            
            if length(peaks) >= 2
                periods = diff(peaks)
                actual_period = mean(periods)
                period_error = abs(actual_period - expected_period) / expected_period
                
                @test period_error < 0.01  # Should match theoretical period
            end
        end
        
        @testset "Non-zero initial velocity" begin
            θ₀ = 0.0
            ω₀ = 1.0  # 1 rad/s initial velocity
            tspan = (0.0, 5.0)
            
            sol = solve_pendulum(θ₀, ω₀, tspan, saveat=0.01)
            
            # Should work without errors
            @test length(sol.t) > 0
            
            # Should have non-zero motion
            @test any(abs(u[1]) > 0.1 for u in sol.u)  # Should reach non-zero angles
            
            # Energy should be conserved
            energy = calculate_energy(sol)
            initial_energy = energy[1]
            final_energy = energy[end]
            energy_error = abs(final_energy - initial_energy) / initial_energy
            
            @test energy_error < 0.01
        end
    end
    
    @testset "Plotting Function Tests" begin
        
        @testset "plot_pendulum_solution function" begin
            θ₀ = deg2rad(10.0)
            ω₀ = 0.0
            tspan = (0.0, 5.0)
            
            sol = solve_pendulum(θ₀, ω₀, tspan, saveat=0.01)
            
            # Test that plotting functions don't throw errors
            # Note: We can't test the actual plot display in tests, but we can test
            # that the functions run without errors
            
            # Test without energy
            p1 = plot_pendulum_solution(sol, show_energy=false)
            @test p1 isa Plot
            
            # Test with energy
            p2 = plot_pendulum_solution(sol, show_energy=true)
            @test p2 isa Plot
        end
        
        @testset "phase_portrait function" begin
            θ₀ = deg2rad(20.0)
            ω₀ = 0.0
            tspan = (0.0, 10.0)
            
            sol = solve_pendulum(θ₀, ω₀, tspan, saveat=0.01)
            
            p = phase_portrait(sol, title="Test Phase Portrait")
            @test p isa Plot
        end
    end
end

# Print test summary
println("\n" * "="^50)
println("Pendulum ODE Solver Test Suite")
println("="^50)
println("All tests completed!")
println("="^50)