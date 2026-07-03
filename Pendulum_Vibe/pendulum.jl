"""
Pendulum Equations of Motion Solver

Solves the equations of motion for a 1-meter length simple pendulum using OrdinaryDiffEq.jl
and displays the results graphically.
"""

using OrdinaryDiffEq
using Plots
using Statistics

# Set a reliable backend for headless environments
try
    # Try GR first (usually works well)
    gr()
catch e
    try
        # Fall back to plotlyjs for web-based plotting
        plotlyjs()
    catch e2
        # If all else fails, use the default backend
        @warn "Could not set GR or PlotlyJS backend: $e2. Using default backend."
    end
end

# Constants
const g = 9.81  # gravitational acceleration (m/s^2)
const L = 1.0   # pendulum length (m)

"""
    pendulum_ode!(du, u, p, t)

Define the system of ODEs for the simple pendulum.

# Arguments
- `du`: derivative vector (output)
- `u`: state vector [θ, ω] where θ is angle and ω is angular velocity
- `p`: parameters (unused)
- `t`: time

The equations are:
- dθ/dt = ω
- dω/dt = - (g/L) * sin(θ)
"""
function pendulum_ode!(du, u, p, t)
    θ = u[1]  # angular position
    ω = u[2]  # angular velocity
    
    du[1] = ω
    du[2] = - (g / L) * sin(θ)
end

"""
    solve_pendulum(θ₀, ω₀, tspan; saveat=0.01)

Solve the pendulum equations of motion with given initial conditions.

# Arguments
- `θ₀`: initial angle (radians)
- `ω₀`: initial angular velocity (rad/s)
- `tspan`: time span tuple (t_start, t_end)
- `saveat`: time step for saving solution (default: 0.01)

# Returns
- solution: ODE solution object containing time, angle, and angular velocity
"""
function solve_pendulum(θ₀::Float64, ω₀::Float64, tspan::Tuple{Float64,Float64}; saveat::Float64=0.01)
    # Initial state: [θ, ω]
    u₀ = [θ₀, ω₀]
    
    # Create ODE problem
    prob = ODEProblem(pendulum_ode!, u₀, tspan)
    
    # Solve using Tsitouras 5th order Runge-Kutta method
    sol = solve(prob, Tsit5(), saveat=saveat)
    
    return sol
end

"""
    plot_pendulum_solution(sol; show_energy=true)

Plot the pendulum solution showing angle, angular velocity, and optionally energy.

# Arguments
- `sol`: ODE solution from solve_pendulum
- `show_energy`: whether to display energy plot (default: true)
"""
function plot_pendulum_solution(sol; show_energy::Bool=true)
    t = sol.t
    θ = [u[1] for u in sol.u]  # extract angles
    ω = [u[2] for u in sol.u]  # extract angular velocities
    
    # Create a layout for the plots
    if show_energy
        energy = calculate_energy(sol)
        layout = @layout [a{0.4h}; b{0.4h}; c{0.2h}]
        p = plot(title="Pendulum Motion (L = $L m)", layout=layout, size=(800, 800))
        
        # Plot 1: Angle vs Time
        plot!(p[1], t, θ, 
              xlabel="Time (s)", ylabel="Angle (rad)", 
              title="Angular Position vs Time", 
              label="θ(t)", 
              color=:blue, linewidth=2)
        
        # Plot 2: Angular Velocity vs Time
        plot!(p[2], t, ω, 
              xlabel="Time (s)", ylabel="Angular Velocity (rad/s)", 
              title="Angular Velocity vs Time", 
              label="ω(t)", 
              color=:red, linewidth=2)
        
        # Plot 3: Energy
        plot!(p[3], t, energy, 
              xlabel="Time (s)", ylabel="Energy (J)", 
              title="Total Mechanical Energy", 
              label="E(t)", 
              color=:green, linewidth=2)
    else
        layout = @layout [a{0.5h}; b{0.5h}]
        p = plot(title="Pendulum Motion (L = $L m)", layout=layout, size=(800, 600))
        
        # Plot 1: Angle vs Time
        plot!(p[1], t, θ, 
              xlabel="Time (s)", ylabel="Angle (rad)", 
              title="Angular Position vs Time", 
              label="θ(t)", 
              color=:blue, linewidth=2)
        
        # Plot 2: Angular Velocity vs Time
        plot!(p[2], t, ω, 
              xlabel="Time (s)", ylabel="Angular Velocity (rad/s)", 
              title="Angular Velocity vs Time", 
              label="ω(t)", 
              color=:red, linewidth=2)
    end
    
    display(p)
    return p
end

"""
    calculate_energy(sol)

Calculate the total mechanical energy of the pendulum over time.

# Arguments
- `sol`: ODE solution from solve_pendulum

# Returns
- energy: vector of total energy values at each time point

The total mechanical energy is: E = (1/2) * m * v^2 + m * g * h
For a pendulum: v = L * ω, h = L * (1 - cos(θ))
Since m * g * L is constant, we can work with normalized energy.
"""
function calculate_energy(sol)
    m = 1.0  # mass (arbitrary, cancels out in normalized energy)
    
    energy = Vector{Float64}(undef, length(sol.t))
    for (i, u) in enumerate(sol.u)
        θ = u[1]
        ω = u[2]
        
        # Kinetic energy: (1/2) * m * v^2 = (1/2) * m * (L * ω)^2
        KE = 0.5 * m * (L * ω)^2
        
        # Potential energy: m * g * h = m * g * L * (1 - cos(θ))
        PE = m * g * L * (1 - cos(θ))
        
        energy[i] = KE + PE
    end
    
    return energy
end

"""
    phase_portrait(sol; title="Phase Portrait")

Plot the phase portrait (ω vs θ) of the pendulum motion.

# Arguments
- `sol`: ODE solution from solve_pendulum
- `title`: title for the plot
"""
function phase_portrait(sol; title::String="Phase Portrait")
    θ = [u[1] for u in sol.u]
    ω = [u[2] for u in sol.u]
    
    p = plot(θ, ω, 
             xlabel="Angle (rad)", ylabel="Angular Velocity (rad/s)", 
             title=title, 
             label="Trajectory", 
             color=:purple, linewidth=2, 
             xlims=(-π, π), ylims=(-10, 10),
             size=(600, 400))
    
    display(p)
    return p
end

# Main execution
println("Solving pendulum equations of motion for L = $L m")
println("Using OrdinaryDiffEq.jl package...")

# Initial conditions: start from rest at 45 degrees (π/4 radians)
θ₀ = π / 4  # 45 degrees in radians
ω₀ = 0.0    # initial angular velocity

# Time span: simulate for 10 seconds
tspan = (0.0, 10.0)

println("Initial angle: $(rad2deg(θ₀)) degrees")
println("Initial angular velocity: $ω₀ rad/s")
println("Simulating for $(tspan[2]) seconds...")

# Solve the pendulum equations
@time sol = solve_pendulum(θ₀, ω₀, tspan)

println("Solution computed successfully!")
println("Number of time points: $(length(sol.t))")

# Plot the results
println("\nDisplaying plots...")
plot_pendulum_solution(sol, show_energy=true)

# Save the plots
println("\nSaving plots to file...")
p_energy = plot_pendulum_solution(sol, show_energy=true)
savefig(p_energy, "Pendulum_Vibe/pendulum_motion.png")

p_phase = phase_portrait(sol, title="Pendulum Phase Portrait (L = $L m)")
savefig(p_phase, "Pendulum_Vibe/pendulum_phase_portrait.png")

println("Plots saved to Pendulum_Vibe/ directory")

# Display phase portrait
println("\nDisplaying phase portrait...")
phase_portrait(sol, title="Pendulum Phase Portrait (L = $L m)")

# Print some statistics about the solution
println("\n=== Solution Statistics ===")
final_angle = sol.u[end][1]
final_velocity = sol.u[end][2]
println("Final angle: $(rad2deg(final_angle)) degrees")
println("Final angular velocity: $final_velocity rad/s")

# Calculate period for small oscillations (approximate)
# For small angles: T ≈ 2π * sqrt(L/g)
expected_period = 2 * π * sqrt(L / g)
println("Expected period for small oscillations (T = 2π√(L/g)): $expected_period s")

# Note: For larger initial angles like 45°, the actual period is longer than the small-angle approximation
# due to nonlinear effects in the pendulum motion.

# Calculate actual period from the solution by finding time between successive maxima
θ_values = [u[1] for u in sol.u]
t_values = sol.t

# Find all local maxima (peaks) regardless of sign
peaks = Vector{Float64}()
for i in 2:length(θ_values)-1
    if θ_values[i] > θ_values[i-1] && θ_values[i] > θ_values[i+1]
        push!(peaks, t_values[i])
    end
end

# Calculate period as average time between consecutive peaks
if length(peaks) >= 2
    periods = diff(peaks)
    actual_period = mean(periods)
    println("Actual period from simulation (peak-to-peak): $actual_period s")
end

println("\nPendulum simulation complete!")