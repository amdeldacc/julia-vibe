using Plots

gr()

x = range(0, 2*π, length=1000)
y = tan.(x)

p = plot(x, y,
     label="y = tan(x)",
     title="Tangent Function: 0 to 2π",
     xlabel="x",
     ylabel="y",
     linewidth=2)

savefig(p, "tan_plot.png")
display(p)
readline()
