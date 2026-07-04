using Plots

# Define domain and function y = tanh(x)
x = range(0, 2π, length=100)
y = tanh.(x)

# Plotting with PlotlyJS backend (same as plot_cos)
p = plot(x, y, title="y = tanh(x)", xlabel="x", ylabel="tanh(x)", label="tanh(x)", legend=:topright, linewidth=2, backend=:plotlyjs)
savefig(p, "plot_tanh.png")
println("Plot saved to plot_tanh.png")
