using Plots

plotlyjs()

x = 0:0.01:10
y = tanh.(x)

plt = plot(x, y, label="tanh(x)", xlabel="x", ylabel="tanh(x)", title="tanh over 0 to 10")
png(plt, "tanh_plot.png")
display(plt)
