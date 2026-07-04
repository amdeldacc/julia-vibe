using Plots

# Define domain and function
x = range(0, 2π, length=100)
y = tanh.(x)

# Plotting
p = plot(x, y, title="y = tanh(x)", xlabel="x", ylabel="tanh(x)", label="tanh(x)")
savefig(p, "plot_tanh.png")
println("Plot saved to plot_tanh.png")
