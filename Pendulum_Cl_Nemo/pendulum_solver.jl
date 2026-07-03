using OrdinaryDiffEq
using Plots
plotlyjs()  # Use PlotlyJS backend for interactive plots

"""
    solve_pendulum(; L=1.0, g=9.81, θ0=π/4, ω0=0.0, tspan=(0.0, 10.0))

Solve the ODE for a simple pendulum.

# Arguments
- `L::Float64=1.0`: length of pendulum (m)
- `g::Float64=9.81`: gravitational acceleration (m/s²)
- `θ0::Float64=π/4`: initial angle (rad)
- `ω0::Float64=0.0`: initial angular velocity (rad/s)
- `tspan::Tuple{Float64,Float64}=(0.0, 10.0)`: time span for simulation

# Returns
- `sol`: the solution object from `OrdinaryDiffEq.solve`
"""
function solve_pendulum(; L=1.0, g=9.81, θ0=π/4, ω0=0.0, tspan=(0.0, 10.0))
    # Define the ODE for a simple pendulum: d²θ/dt² = -g/L * sin(θ)
    # Convert to system of first-order ODEs:
    # dθ/dt = ω
    # dω/dt = -g/L * sin(θ)
    function pendulum!(du, u, p, t)
        θ, ω = u
        du[1] = ω                    # dθ/dt
        du[2] = -g/L * sin(θ)        # dω/dt
    end

    # Initial conditions
    u0 = [θ0, ω0]

    # Create the ODE problem
    prob = ODEProblem(pendulum!, u0, tspan)

    # Solve the ODE
    sol = solve(prob, Tsit5(), reltol=1e-6, abstol=1e-8)
    return sol
end

"""
    plot_pendulum(sol; filename_html="pendulum_plot.html", filename_png="pendulum_plot.png")

Plot the pendulum solution and save to files.

# Arguments
- `sol`: the solution object from `solve_pendulum`
- `filename_html::String="pendulum_plot.html"`: output HTML file name
- `filename_png::String="pendulum_plot.png"`: output PNG file name
"""
function plot_pendulum(sol; filename_html="pendulum_plot.html", filename_png="pendulum_plot.png")
    # Extract solution components
    θ_sol = sol[1, :]  # angle over time
    ω_sol = sol[2, :]  # angular velocity over time
    t_sol = sol.t      # time points

    # Create plots
    plt1 = plot(t_sol, θ_sol,
               xlabel="Time (s)",
               ylabel="Angle (rad)",
               title="Pendulum Angle vs Time",
               label="θ(t)",
               linewidth=2,
               legend=:topright)

    plt2 = plot(t_sol, ω_sol,
               xlabel="Time (s)",
               ylabel="Angular Velocity (rad/s)",
               title="Pendulum Angular Velocity vs Time",
               label="ω(t)",
               linewidth=2,
               legend=:topright)

    # Combine plots
    plot(plt1, plt2, layout=(2,1), size=(800, 600))

    # Save the plot
    savefig(filename_html)
    println("Plot saved to $filename_html")

    # Also save as PNG for static viewing
    savefig(filename_png)
    println("Plot saved to $filename_png")
end

# If the script is run directly, solve and plot with default parameters
if abspath(PROGRAM_FILE) == @__FILE__
    sol = solve_pendulum()
    plot_pendulum(sol)

    # Print some basic information
    println("\nPendulum Simulation Results:")
    println("Length: 1.0 m")
    println("Gravity: 9.81 m/s²")
    println("Initial angle: $(π/4) rad ($(rad2deg(π/4))°)")
    println("Initial angular velocity: 0.0 rad/s")
    println("Time span: 0.0 to 10.0 s")
    println("\nSolution summary:")
    println("  Final angle: $(sol[1,end]) rad ($(rad2deg(sol[1,end]))°)")
    println("  Final angular velocity: $(sol[2,end]) rad/s")
end