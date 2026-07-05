using Plots
x = range(0, 2π, length=1000)
plot(x, tan.(x), label="tan(x)", title="0 to 2π")
gui()
