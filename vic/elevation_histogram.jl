
using IcanProj
using PyPlot

opt = get_options()

wsh_info = get_wsh_info()

# for i in 1:length(wsh_info)

i = 1

fig = figure("pyplot_histogram",figsize=(7,5))

h = plt[:hist](wsh_info[i].elev[:], 20, alpha = 0.3)

xlabel("Elevation (m)")
ylabel("Number of gridcells")

# end
