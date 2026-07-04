using Plots

# Define domain and function
x = range(0, 2π, length=100)
y = cos.(x)

# Plotting
p = plot(x, y, title="y = cos(x)", xlabel="x", ylabel="cos(x)", label="cos(x)")
savefig(p, "plot_cos.png")
println("Plot saved to plot_cos.png")
