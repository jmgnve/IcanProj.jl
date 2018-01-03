using IcanProj
using NetCDF

# Settings

path = "/data02/Ican/vic_sim/past_1km_fsm"

time_start = DateTime(2002,1,1)


# Load soil parameters

soil_param = read_soil_params(path)


# Dimensions

dim_time = 365*4*8

dim_space = size(soil_param, 1)


# Auxiliary variables

time_str = Dates.format.([time_start + i*Dates.Hour(3) for i in 0:dim_time-1], "yyyy-mm-dd HH:MM:SS")
lon = soil_param[:lon]
lat = soil_param[:lat]
senorge_ind = soil_param[:gridcel]


# Create netcdf files

var = ["rainf",
       "snowf",
       "tair",
       "iswr",
       "ilwr",
       "pres",
       "rhum",
       "wind"]

var_atts = [Dict("units" => "mm/tstep"),
            Dict("units" => "mm/tstep"),
            Dict("units" => "C"),
            Dict("units" => "W/m2"),
            Dict("units" => "W/m2"),
            Dict("units" => "kPa"),
            Dict("units" => "%"),
            Dict("units" => "m/s")]

fn = joinpath.(path, "netcdf", var .* ".nc")

for i in 1:length(var)
    
    create_netcdf(fn[i], var[i], var_atts[i], dim_time, dim_space, time_str, lon, lat, senorge_ind)
    
end


# Loop over files

for i in 1:size(soil_param,1)
    
    #row = soil_param[i, :]

    lat_str = @sprintf("%0.5f", lat[i])
    lon_str = @sprintf("%0.5f", lon[i])

    file_src = joinpath(path, "results/metdata_$(lat_str)_$(lon_str)")

    rainf, snowf, tair, iswr, ilwr, pres, rhum, wind = read_mtclim_fsm(file_src)
    
    ncwrite(rainf[1:dim_time], fn[1], var[1], start=[1,i], count=[-1,1])
    ncwrite(snowf[1:dim_time], fn[2], var[2], start=[1,i], count=[-1,1])
    ncwrite(tair[1:dim_time],  fn[3], var[3], start=[1,i], count=[-1,1])
    ncwrite(iswr[1:dim_time],  fn[4], var[4], start=[1,i], count=[-1,1])
    ncwrite(ilwr[1:dim_time],  fn[5], var[5], start=[1,i], count=[-1,1])
    ncwrite(pres[1:dim_time],  fn[6], var[6], start=[1,i], count=[-1,1])
    ncwrite(rhum[1:dim_time],  fn[7], var[7], start=[1,i], count=[-1,1])
    ncwrite(wind[1:dim_time],  fn[8], var[8], start=[1,i], count=[-1,1])

    if mod(i, 1000) == 0
        print("Processed $i grids\n")
    end
    
    
end

ncclose()
