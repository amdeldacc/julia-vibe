using Plots

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

println("Cosine plot displayed")
