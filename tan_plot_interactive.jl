using Plots
plotlyjs()

x = range(0, 2π, length=1000)
y = tan.(x)

p = plot(x, y, label="y = tan(x)", title="Tangent Function 0 to 2π", xlabel="x", ylabel="y", linewidth=2)

savefig(p, "tan_plot.html")
println("Interactive plot saved as tan_plot.html")
println("Open in browser: file:///$(pwd())/tan_plot.html")
gui()
