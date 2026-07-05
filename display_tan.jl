using Plots

# Force GR backend and Qt terminal
ENV["GKS_ENCODING"] = "utf8"
ENV["GKSwstype"] = "100"
ENV["GKS_QT"] = "true"
gr()

# Create plot
x = range(0, 2π, length=1000)
y = tan.(x)

p = plot(x, y, 
     label="y = tan(x)", 
     title="Tangent Function: 0 to 2π",
     xlabel="x", 
     ylabel="y",
     linewidth=2,
     size=(800, 600))

# Save PNG first
savefig(p, "tan_plot_display.png")
println("PNG saved. Qt window opening...")

# Display and keep open
display(p)
print("Press Enter to close window and exit...")
readline()

println("Done.")
