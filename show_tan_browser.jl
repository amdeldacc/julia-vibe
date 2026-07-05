using Plots

# Use PlotlyJS backend - opens in default browser
plotlyjs()

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

# Save HTML and open in browser
html_file = "tan_plot.html"
savefig(p, html_file)

print("Plot saved to $html_file")
print("Opening in default browser...")

# Open in browser
run(`xdg-open $html_file`)

# Also save PNG
savefig(p, "tan_plot_browser.png")
print("Also saved as tan_plot_browser.png")
