using Plots

# Generate x values from 0 to 2π with 1000 points
x = range(0, 2π, length=1000)

# Compute y = sin(x)
y = sin.(x)

# Create the plot
plot(x, y,
     title="y = sin(x) over [0, 2π]",
     xlabel="x",
     ylabel="y = sin(x)",
     label="sin(x)",
     linewidth=2,
     color=:blue,
     size=(800, 400))

# Save the plot to a file
savefig("sine_plot.png")

println("Plot saved to sine_plot.png")
