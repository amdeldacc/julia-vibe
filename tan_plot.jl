using Plots

x = range(0, 2π, length=1000)
y = tan.(x)

plot(x, y, label="y = tan(x)", xlabel="x", ylabel="y", title="Tangent Function", linewidth=2)

savefig("tan_plot.png")
println("Plot saved as tan_plot.png")