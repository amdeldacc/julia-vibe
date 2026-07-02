using Printf

# Simple ASCII plot of y = cos(x) - works in headless environments

# Generate data
x = range(0, 2π, length=60)
y = cos.(x)

# ASCII plot parameters
height = 15
width = 60

# Scale y values to fit in terminal
y_min, y_max = minimum(y), maximum(y)
y_range = y_max - y_min

# Create ASCII plot grid
grid = fill(' ', height, width)

# Map y values to row indices
for (i, y_val) in enumerate(y)
    row = round(Int, (y_val - y_min) / y_range * (height - 1)) + 1
    row = clamp(row, 1, height)
    col = round(Int, (i - 1) / (length(x) - 1) * (width - 1)) + 1
    col = clamp(col, 1, width)
    grid[row, col] = '•'
end

# Add x-axis (middle row)
axis_row = round(Int, height / 2)
for col in 1:width
    if grid[axis_row, col] == ' '
        grid[axis_row, col] = '-'
    end
end

# Print the plot
println("ASCII Plot of y = cos(x) over [0, 2π]:")
println()
for row in 1:height
    println(join(grid[row, :], ""))
end
println()
@printf("x: %.2f to %.2f  |  y: %.2f to %.2f\n", 0, 2π, y_min, y_max)
