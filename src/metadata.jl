

"""
Struct with metadata for watersheds.
"""
struct WatershedData

    name::String
    regine_main::String
    dbk::Float64
    xrange::UnitRange{Int64}
    yrange::UnitRange{Int64}
    ind_senorge::Array{Int64,2}
    ind_1km::Array{Int64,2}
    ind_5km::Array{Int64,2}
    ind_10km::Array{Int64,2}
    ind_25km::Array{Int64,2}
    ind_50km::Array{Int64,2}
    elev::Array{Float64,2}

end


"""
Load metadata for selected stations.
"""
function load_metadata(stat_sel)

    file = joinpath(Pkg.dir("IcanProj", "data", "stations_metadata.xlsx"))

    df_all = readxlsheet(DataFrame ,file, "Ark1")

    df_all[:regine_main] = string.(convert.(Int, df_all[:regine_area])) .* "." .* string.(convert.(Int, df_all[:main_no]))

    df_sel = @from i in df_all begin
        @where i.regine_main in stat_sel
        @select i
        @collect DataFrame
    end

    return df_sel

end


"""
Print nice table with metadata.
"""
function clean_metadata(df_sel)

    df_nice = @from i in df_sel begin
        @select {i.regine_main, i.station_name, i.area_total, i.utm_east_z33, i.utm_north_z33, i.perc_agricul,
                 i.perc_bog, i.perc_forest, i.perc_glacier, i.perc_lake, i.perc_mountain, i.perc_urban,
                 i.height_minimum, i.height_maximum}
        @collect DataFrame
    end

    return df_nice

end


"""
Compute indicies for different resolutions.
"""
function resolution_ind(res)
    @assert 50%res == 0
    ind = zeros(Int, 50, 50)
    counter = 1
    for irow = 1:res:50, icol = 1:res:50
        ind[irow:irow+res-1, icol:icol+res-1] = counter
        counter += 1
    end
    return ind
end


"""
Collect metadata for selected watershed.
"""
function get_watershed_data(df_sel)

    # Grid cells with input data

    file = joinpath(Pkg.dir("NveData"), "raw/elevation.asc")
    
    dem = read_esri_raster(file)

    elev = dem["data"]
    
    valid_cells = similar(elev, Bool)
    valid_cells[dem["data"] .== -9999.0] = false
    valid_cells[dem["data"] .> 0.0] = true

    # Senorge information

    ind_senorge, xcoord, ycoord = senorge_info()

    # Catchment information
    
    dbk_ind = read_dbk_ind()

    # Loop over stations

    wsh_info = WatershedData[]
    
    for row in eachrow(df_sel)

        # Basic metadata

        name = row[:station_name]
        regine_main = row[:regine_main]
        dbk = row[:drainage_basin_key][1]

        # Find a grid box around the watershed with valid cells
    
        wsh_ind = dbk_ind[dbk]
    
        xcoord_center = mean(xcoord[findin(ind_senorge, wsh_ind)])
        ycoord_center = mean(ycoord[findin(ind_senorge, wsh_ind)])
    
        dist = sqrt.((xcoord - xcoord_center).^2 + (ycoord - ycoord_center).^2)
        
        xmin_ind, ymin_ind = findn(dist .== minimum(dist))
        
        xmin_ind, ymin_ind = xmin_ind[1], ymin_ind[1]
        
        shift_vec = [0 -1 1 -2 2 -3 3 -4 4 -5 5 -6 6 -7 7 -8 8 -9 9 -10 10 -11 11 -12 12 -13 13 -14 14]
    
        xrange, yrange = [], []
        
        for xshift = shift_vec, yshift = shift_vec
            
            xrange = (xmin_ind-25+xshift):(xmin_ind+24+xshift)
            yrange = (ymin_ind-25+yshift):(ymin_ind+24+yshift)
    
            if sum(valid_cells[xrange, yrange]) == 2500
                break
            end
    
        end
    
        println("Number valid cells for $(row[:regine_main]): $(sum(valid_cells[xrange, yrange]))")
        println("Percentage glacier for $(row[:regine_main]): $(round(row[:perc_glacier],2))")

        # Indices for different resolutions

        ind_1km  = resolution_ind(1)
        ind_5km  = resolution_ind(5)
        ind_10km = resolution_ind(10)
        ind_25km = resolution_ind(25)
        ind_50km = resolution_ind(50)
        
        # Save to struct

        wsh_tmp = WatershedData(
            name,
            regine_main,
            dbk,
            xrange,
            yrange,
            ind_senorge[xrange, yrange],
            ind_1km,
            ind_5km,
            ind_10km,
            ind_25km,
            ind_50km,
            elev[xrange, yrange]
        )

        push!(wsh_info, wsh_tmp)
        
    end

    return wsh_info

end








