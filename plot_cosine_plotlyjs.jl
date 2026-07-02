using Plots

# Use PlotlyJS backend for headless environments
plotlyjs()

# Generate x values from 0 to 2π with 1000 points
x = range(0, 2π, length=1000)

# Compute y = cos(x)
y = cos.(x)

# Create and display the plot
plot(x, y,
     title="y = cos(x) over [0, 2π]",
     xlabel="x",
     ylabel="y = cos(x)",
     label="cos(x)",
     linewidth=2,
     color=:red,
     size=(800, 400))

# Save as HTML for interactive viewing
Plots.savefig("cosine_plot_plotlyjs.html")

println("Cosine plot created with PlotlyJS backend")
println("Interactive HTML saved to cosine_plot_plotlyjs.html")
