module MiscTSV

using DelimitedFiles
using Interpolations

function load_data_0d(
    dirs::Vector{Tuple{String,String}};
    cols::Vector{Int} = Int[],
    parent_dir::String = expanduser("~/Data/Subcycling/"),
)::Tuple{Vector{Vector{Vector{Float64}}},Vector{String}}
    # Initialize containers for data and labels
    dats = Vector{Vector{Vector{Float64}}}()
    labs = [label for (_, label) in dirs]      # Extract labels

    for (subdir, _) in dirs
        fname = joinpath(parent_dir, subdir)

        # Load data from file
        dat = readdlm(fname, Float64, comments = true)

        # Select columns or use all columns if none are specified
        dat_list =
            isempty(cols) ? [dat[:, i] for i = 1:size(dat, 2)] : [dat[:, i] for i in cols]

        # Append data for this directory
        push!(dats, dat_list)
    end

    return (dats, labs)
end

function load_data_1d(
    dirs::Vector{Tuple{String,String}},
    time::Float64;
    ngh::Int = 0,
    cols::Tuple{Int,Int} = (8, 11),
    level::Int = 0,
    parent_dir::String = expanduser("~/Data/Subcycling/"),
    prefix::String = "z4cow-hc",
    suffix::String = ".x.tsv",
)::Tuple{Vector{Vector{Vector{Float64}}},Vector{String}}
    # Initialize empty array to hold data and extract labels
    dats = Vector{Vector{Vector{Float64}}}()
    labs = [label for (_, label) in dirs]      # Extract labels

    for (subdir, _) in dirs
        fulldir = joinpath(parent_dir, subdir)

        # Collect matching files in directory
        tsvs = [
            joinpath(root, file) for (root, _, files) in walkdir(fulldir) for
            file in files if startswith(file, prefix) && endswith(file, suffix)
        ]

        for fname in tsvs
            # Read data from file
            dat = readdlm(fname, Float64, comments = true)

            # Check if time matches the second element in the first row
            if isapprox(dat[1, 2], time; rtol = 1e-12)
                # Find indices where the 4th column matches the level
                idx = findall(x -> x == level, dat[:, 4])

                # Only proceed if indices are found
                if !isempty(idx)
                    # Extract specified columns at the found indices, handling ghost cells (ngh)
                    dat_list = [dat[idx, col][1+ngh:end-ngh] for col in cols]

                    # Append the data to the overall list
                    push!(dats, dat_list)
                end
            end
        end
    end

    return (dats, labs)
end

end
