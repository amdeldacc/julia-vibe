using Plots

# Define the function y = sin(x)
f(x) = sin(x)

# Generate x values from 0 to 2*pi
x = range(0, stop=2*pi, length=100)
y = f.(x)

# Create the plot
p = plot(x, y,
         title="Plot of y = sin(x)",
         xlabel="x",
         ylabel="sin(x)",
         label="sin(x)",
         linewidth=2,
         legend=:topright)

# Save the plot as a PNG file
savefig(p, "plot_sin.png")
println("Plot saved to plot_sin.png")
