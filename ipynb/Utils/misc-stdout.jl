#
# CHECKOUT https://github.com/lwJi/ETK-Scaling-Tests/tree/main/Utils for updated version
#
module MiscStdout

using DelimitedFiles
using Plots

function load_data(filenames, directory, pattern)
    results = []
    # Pre-compiled regex patterns for efficiency
    time_pattern =
        r"\(CarpetX\): Simulation time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"
    step_pattern =
        r"\(CarpetX\):   total iterations:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"

    for filename in filenames
        file_path = joinpath(directory, filename)
        data = readlines(file_path)

        # Store parsed values
        steps = Float64[]
        times = Float64[]
        matches = Float64[]

        for row in data
            # Matching time, steps, and custom pattern
            time_match = match(time_pattern, row)
            step_match = match(step_pattern, row)
            pattern_match = match(pattern, row)

            if time_match !== nothing
                push!(times, parse(Float64, time_match.captures[1]))
            end
            if step_match !== nothing
                push!(steps, parse(Int64, step_match.captures[1]))
            end
            if pattern_match !== nothing
                push!(matches, parse(Float64, pattern_match.captures[1]))
            end
        end

        # Take the minimum length to avoid mismatches
        common_length = minimum([length(steps), length(times), length(matches)])

        # Store the extracted data
        push!(
            results,
            (steps[1:common_length], times[1:common_length], matches[1:common_length]),
        )
    end

    return results
end

function calc_avgs(datas; range = :)
    avgs = Float64[]  # Preallocate an array for averages

    for i = 1:length(datas)
        time_data = datas[i][2][range]  # time values
        value_data = datas[i][3][range]  # target values

        # Ensure time_data and value_data have enough elements
        if length(time_data) < 2 || length(value_data) < 2
            println(
                "Warning: Not enough data points for node $i in the selected range. Skipping.",
            )
            continue
        end

        # Calculate the average
        delta_time = time_data[end] - time_data[1]
        delta_value = value_data[end] - value_data[1]
        average = 3600 * (delta_time / delta_value)  # Convert to M/h

        push!(avgs, average)
    end

    return avgs
end

function plot_speed(
    plt,
    nodes,
    directory;
    prefix = "N",
    range = :,
    pattern = r"total evolution compute time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)",
    verbose = false,
    seriestype = :line,
    marker = :circle,
)
    # Generate file paths for each node
    file_paths = [joinpath(prefix * string(node), "stdout.txt") for node in nodes]

    # Load data based on the file paths and pattern
    datas = load_data(file_paths, directory, pattern)
    avgs = calc_avgs(datas; range = range)

    # Optionally print averages for debugging
    if verbose
        println("Averages speeds (M/h): ", avgs)
        println("Num of points: ", [length(data[1]) for data in datas])
    end

    # Iterate over the loaded data to plot
    for i = 1:length(datas)
        label_i = string(basename(directory), "-", prefix, nodes[i])
        steps = datas[i][1][range]  # x-values: steps
        values = datas[i][3][range]  # y-values: matched values

        # Ensure data is not empty or mismatched in length
        if isempty(steps) || isempty(values)
            println("Warning: No data found for node $nodes[i]. Skipping.")
            continue
        end

        # Plot the data
        plt =
            plot!(steps, values, seriestype = seriestype, marker = marker, label = label_i)
    end

    # return plt
end

function plot_scaling(
    plt,
    nodes,
    directories;  # (directory, label) tuples
    prefix = "N",
    range = :,
    pattern = r"total evolution compute time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)",
    verbose = false,
    with_ideal = false,
    seriestype = :line,
    marker = :circle,
)
    # Generate file paths for each node
    file_paths = [joinpath(prefix * string(node), "stdout.txt") for node in nodes]

    # Loop over directories
    (directory, label) = directories

    # Load data for each directory
    datas = load_data(file_paths, directory, pattern)
    avgs = calc_avgs(datas; range = range)

    # Optionally print averages for debugging
    if verbose
        println("Averages speeds (M/h) for $label: ", avgs)
    end

    # Check if `avgs` is not empty before plotting
    if !isempty(avgs)
        # Plot the computed averages
        plt = plot!(nodes, avgs, seriestype = seriestype, marker = marker, label = label)

        # Optionally plot the ideal scaling line
        if with_ideal
            ideal_avgs = [avgs[1] / nodes[1] * node for node in nodes]
            plt = plot!(
                nodes,
                ideal_avgs,
                seriestype = seriestype,
                marker = marker,
                label = "",
            )
        end
    else
        println("Warning: No data to plot for directory $directory.")
    end

    # return plt
end

function plot_efficiency(
    plt,
    nodes,
    directories;  # List of (directory, label) tuples
    prefix = "N",
    range = :,
    with_ideal = false,
    pattern = r"total evolution compute time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)",
)
    # Generate file paths for each node
    file_paths = [joinpath(prefix * string(node), "stdout.txt") for node in nodes]

    # Loop over directories
    for (directory, label) in directories
        # Load data for each directory
        datas = load_data(file_paths, directory, pattern)
        avgs = calc_avgs(datas, range)

        # Ensure avgs is not empty and has the expected length
        if isempty(avgs) || length(avgs) != length(nodes)
            println("Warning: Insufficient data for directory $directory. Skipping.")
            continue
        end

        # Compute ideal efficiency
        ideal_avgs = [avgs[1] / nodes[1] * n for n in nodes]

        # Compute efficiency
        efficiency = [avgs[i] / ideal_avgs[i] for i = 1:length(nodes)]

        # Plot efficiency
        plt = plot!(nodes, efficiency, seriestype = :line, marker = :circle, label = label)

        # Optionally plot the ideal efficiency line
        if with_ideal
            plt = plot!(
                nodes,
                [1.0 for _ in nodes],
                seriestype = :line,
                marker = :circle,
                label = "Ideal",
            )
        end
    end

    # return plt
end

end
