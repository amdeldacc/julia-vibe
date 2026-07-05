using GR

# Set up Qt terminal
ENV["GKS_ENCODING"] = "utf8"
ENV["GKSwstype"] = "100"

# Create data
x = range(0, 2π, length=1000)
y = tan.(x)

# Plot
plot(x, y)
title("Tangent Function: 0 to 2π")
xlabel("x")
ylabel("y")

# Keep window open
print("Qt window open. Close window to continue.")
update()
readline()
