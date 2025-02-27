module MiscTool

using DSP  # for fftw window functions
using FFTW

function derivs_1st(x, f)
    n = length(x)
    df_dx = similar(f)  # Create a similar array for derivative values

    # Central difference for interior points
    @inbounds df_dx[2:n-1] .= (f[3:n] - f[1:n-2]) ./ (x[3:n] - x[1:n-2])

    # Forward difference for the first point
    @inbounds df_dx[1] = (f[2] - f[1]) / (x[2] - x[1])

    # Backward difference for the last point
    @inbounds df_dx[n] = (f[n] - f[n-1]) / (x[n] - x[n-1])

    return df_dx
end

function derivs(x, f; n = 1)
    if n == 0
        return f
    elseif n == 1
        return derivs_1st(x, f)
    else
        return derivs(x, derivs_1st(x, f); n = n - 1)
    end
end

function fft_transform(time, signal; fwindow = hanning)
    # Ensure time and signal have the same length
    N = length(time)
    if length(signal) != N
        error("Time and signal must have the same length.")
    end

    # Calculate sample rate (1 / delta_t)
    sample_rate = 1 / (time[2] - time[1])  # Assuming uniform sampling

    # Compute the frequency bins (centered with fftshift)
    freqs = fftshift(fftfreq(length(time), sample_rate))

    # Apply the window function if provided, or no window if `fwindow` is `nothing`
    windowed_signal = fwindow === nothing ? signal : signal .* fwindow(N)

    # Perform FFT and shift the result (to center zero frequency)
    fft_result = fftshift(fft(windowed_signal))

    return freqs, fft_result
end

end
