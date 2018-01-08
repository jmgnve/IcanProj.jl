
using DataFrames
using NetCDF
using IcanProj
using ProgressMeter


function aggregate_forcings(path, var, res)

    # Symbol for resolution

    ind_res = Symbol("ind_$(res)")
    
    # Metadata from table

    file = Pkg.dir("IcanProj", "data", "df_links.csv")

    df_meta = readtable(file)
    
    # Metadata from input netcdfs

    file_in = joinpath(path, "$(var)_1km.nc")

    nc_in = Dict("ind_senorge" => ncread(file_in, "ind_senorge"),
                 "time_str" => ncread(file_in, "time_str"),
                 "var_atts" => ncgetatt(file_in, var, "units"))

    # Create netcdfs

    file_out = joinpath(path, "$(var)_$(res).nc")

    var_atts = Dict("units" => nc_in["var_atts"])

    dim_time = length(nc_in["time_str"])

    dim_space = length(unique(df_meta[ind_res]))

    time_str = nc_in["time_str"]

    id = convert(Array{Int64}, unique(df_meta[ind_res]))

    id_desc = String(ind_res)
    
    create_netcdf(file_out, var, var_atts, dim_time, dim_space, time_str, id, id_desc)

    # Aggregate forcings

    icol_out = 1

    @showprogress 1 "Running..." for ind_unique in unique(df_meta[ind_res])

        itarget = find(df_meta[ind_res] .== ind_unique)

        data_agg = fill(0.0, dim_time)

        tmp = fill(0.0, dim_time)
        
        for ind_senorge in df_meta[:ind_senorge][itarget]

            icol_in = find(nc_in["ind_senorge"] .== ind_senorge)[1]

            ncread!(file_in, var, tmp, start=[1,icol_in], count=[-1,1])

            data_agg = data_agg + tmp / length(itarget)
            
        end
        
        ncwrite(data_agg, file_out, var, start=[1,icol_out], count=[-1,1])

        icol_out += 1
        
    end

    ncclose()

    return nothing

end



# Settings

path = "/data02/Ican/vic_sim/fsm_past_1km/netcdf"

var_all = ["ilwr", "iswr", "pres", "rainf", "snowf", "wind", "rhum", "tair"]

res_all = ["50km", "25km", "10km", "5km"]

# Loop over all variables and resolutions

for var in var_all, res in res_all

    aggregate_forcings(path, var, res)

    print("Finished $(var) for $(res)\n")

end











#=

# Settings

path = "/data02/Ican/vic_sim/fsm_past_1km/netcdf"

# Metadata from input netcdfs

file_in = joinpath(path, "tair_1km.nc")

nc_in = Dict("lon" => ncread(file_in, "lon"),
             "lat" => ncread(file_in, "lat"),
             "ind_senorge" => ncread(file_in, "ind_senorge"),
             "time_str" => ncread(file_in, "time_str"))

# Metadata from table

file = Pkg.dir("IcanProj", "data", "df_links.csv")

df_meta = readtable(file)

# Create netcdfs

file_out = joinpath(path, "tair_50km.nc")

var = "tair"

var_atts = Dict("units" => "C")

dim_time = length(nc_in["time_str"])

dim_space = length(unique(df_meta[:ind_50km]))

time_str = nc_in["time_str"]

lon = collect(1:length(dim_space))

lat = collect(1:length(dim_space))

id = convert(Array{Int64}, unique(df_meta[:ind_50km]))

id_desc = "ind_50km"



create_netcdf(file_out, var, var_atts, dim_time, dim_space, time_str, lon, lat, id, id_desc)




# Aggregate forcings

icol_out = 1

for ind_unique in unique(df_meta[:ind_50km])

    itarget = find(df_meta[:ind_50km] .== ind_unique)

    data_agg = fill(0.0, dim_time)

    tmp = fill(0.0, dim_time)
    
    for ind_senorge in df_meta[:ind_senorge][itarget]

        # Find column in input netcdf

        icol_in = find(nc_in["ind_senorge"] .== ind_senorge)[1]

        # Read data from netcdf

        ncread!(file_in, "tair", tmp, start=[1,icol_in], count=[-1,1])
        
        # Compute average

        data_agg = data_agg + tmp / length(itarget)
        
    end

    # Write data to output netcdf
    
    ncwrite(data_agg, file_out, "tair", start=[1,icol_out], count=[-1,1])

    icol_out += 1

    print("Processed $(icol_out) grids\n")
    
end

=#