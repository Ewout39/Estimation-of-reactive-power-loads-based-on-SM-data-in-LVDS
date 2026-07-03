"""
    Load_Data

Loads and stores the data from/to external files.
"""
module Load_Data

using HDF5
import DataFrames as _DF
using CSV
using LinearAlgebra
using Statistics
using ZipFile

export extract_loading_usa!, initialize_empty_dict!, add_to_dict!, finding_most_representative_month, network_rep_month, calculating_month_with_highest_average_consumption_per_building

"""
    extract_loading_usa!()

Extracts the load data from the MFRED dataset.
"""
function extract_loading_usa!()
    loaded_data = Dict{Int, Any}()
    data = _DF.DataFrame()
    good_buildings = ["$(i)" for i in 1:55]
    column_names_P = ["PLoad_$(i)" for i in 1:length(good_buildings)]
    column_names_Q = ["QLoad_$(i)" for i in 1:length(good_buildings)]
    column_names = vcat(column_names_P, column_names_Q)
    load_data = _DF.DataFrame((column_name => [0.0 for _ in 1:35040] for column_name in column_names)...)
    for i in 1:55
        if i >= 27 && i <= 52
            k = i - 26
        elseif i >= 53
            k = i -52
        else
            k = i
        end
        filepath = joinpath(dirname(@__DIR__),"clustering","data","repository","USA","power_dict_test.zip")
        z = ZipFile.Reader(filepath)
        for f in z.files
            if f.name == "$(k).csv"
                bytes = read(f)
                data = CSV.read(IOBuffer(bytes), _DF.DataFrame, delim=',')
                break
            end
        end
        close(z)
        loaded_data[i] = data
        for j in 1:35040
            load_data[j, "PLoad_$(i)"] = loaded_data[i][j, :P]
            load_data[j, "QLoad_$(i)"] = loaded_data[i][j, :Q]
        end
    end
    return good_buildings, load_data
end

"""    initialize_empty_dict!()

Initializes an empty dictionary to store the results of the power flow analysis.
"""

function initialize_empty_dict!()
    Result_dict = Dict{String, Dict{String, Any}}()
    Result_dict["0"] = Dict("Winter" => Dict{String, Any}(Dict{String, Any}()), "Spring" => Dict{String, Any}(Dict{String, Any}()), "Summer" => Dict{String, Any}(Dict{String, Any}()), "Autumn" => Dict{String, Any}(Dict{String, Any}()))
    Result_dict["1"] = Dict("Winter" => Dict{String, Any}(Dict{String, Any}()), "Spring" => Dict{String, Any}(Dict{String, Any}()), "Summer" => Dict{String, Any}(Dict{String, Any}()), "Autumn" => Dict{String, Any}(Dict{String, Any}()))
    Result_dict["2"] = Dict("Winter" => Dict{String, Any}(Dict{String, Any}()), "Spring" => Dict{String, Any}(Dict{String, Any}()), "Summer" => Dict{String, Any}(Dict{String, Any}()), "Autumn" => Dict{String, Any}(Dict{String, Any}()))
    return Result_dict
end

"""
    add_to_dict!(Result_dict, res,  Q_set, alpha, Z_value, Q_Z, season, math)

Adds the results of the power flow analysis to the Result_dict.
"""

function add_to_dict!(Result_dict, res,  Q_set, alpha, Z_value, Q_Z, season, math)
    q_key = string(Q_set)
    s_key = string(season)
    if Q_Z == "Z"
        a_key = "Z=$(Z_value)"
    else
        a_key = "Alpha=$(alpha)"
    end
    alpha_dict = get!(get!(get!(Result_dict, q_key, Dict{String,Any}()),
                           s_key, Dict{String,Any}()),
                      a_key, Dict("Busses"=>Dict(), "Branches"=>Dict(), "Loads"=>Dict(), "Gen"=>Dict()))
    for (key, values) in res["solution"]["bus"]
        bus_key = string(key)
        bus_dict = get!(alpha_dict["Busses"], bus_key) do
            Dict(
                "V1" => Float64[],
                "V2" => Float64[],
                "V3" => Float64[],
                "V4" => Float64[],
            )
        end
        push!(bus_dict["V1"], sqrt(values["vr"][1]^2 + values["vi"][1]^2))
        push!(bus_dict["V2"], sqrt(values["vr"][2]^2 + values["vi"][2]^2))
        push!(bus_dict["V3"], sqrt(values["vr"][3]^2 + values["vi"][3]^2))
        push!(bus_dict["V4"], sqrt(values["vr"][4]^2 + values["vi"][4]^2))
    end
    for (key, values) in res["solution"]["branch"]
        branch_key = string(key)
        branch_dict = get!(alpha_dict["Branches"], branch_key) do
            Dict("line_loading_P1" => Float64[],
                 "line_loading_P2" => Float64[],
                 "line_loading_P3" => Float64[])
        end
        push!(branch_dict["line_loading_P1"], values["line_loading"][1])
        push!(branch_dict["line_loading_P2"], values["line_loading"][2])
        push!(branch_dict["line_loading_P3"], values["line_loading"][3])
    end
    for (key, values) in math["load"]
        load_key = string(key)
        load_dict = get!(alpha_dict["Loads"], load_key) do
            Dict(
                "P$(values["phase_connections"])" => Float64[],
                "Q$(values["phase_connections"])" => Float64[]
            )
        end
        push!(load_dict["P$(values["phase_connections"])"], values["pd"][1])
        push!(load_dict["Q$(values["phase_connections"])"], values["qd"][1])
    end
    for (key, values) in res["solution"]["gen"]
        gen_key = string(key)
        gen_dict = get!(alpha_dict["Gen"], gen_key) do
            Dict(
                "P1" => Float64[],
                "P2" => Float64[],
                "P3" => Float64[],
                "Q1" => Float64[],
                "Q2" => Float64[],
                "Q3" => Float64[],
            )
        end
        push!(gen_dict["P1"], values["pg"][1])
        push!(gen_dict["P2"], values["pg"][2])
        push!(gen_dict["P3"], values["pg"][3])
        push!(gen_dict["Q1"], values["qg"][1])
        push!(gen_dict["Q2"], values["qg"][2])
        push!(gen_dict["Q3"], values["qg"][3]) 
    end
end

"""
    finding_most_representative_month(season::String, data, i::Int)

Calculates the most representative month for a given season based on the load profiles.
"""

function finding_most_representative_month(season::String, data, i::Int)
    days_in_month = [31,28,31,30,31,30,31,31,30,31,30,31]
    month_starts = cumsum([1; 96 .* days_in_month[1:end-1]])
    month_ends   = cumsum(96 .* days_in_month)

    if season == "Winter"
        months_in_season = [12, 1, 2]
    elseif season == "Spring"
        months_in_season = [3, 4, 5]
    elseif season == "Summer"
        months_in_season = [6, 7, 8]
    elseif season == "Autumn"
        months_in_season = [9, 10, 11]
    else
        error("Invalid season")
    end

    month_pf_list = []
    for m in months_in_season
        start_idx, end_idx = month_starts[m], month_ends[m]
        P_block, Q_block = data[start_idx:end_idx, "PLoad_$(i)"], data[start_idx:end_idx, "QLoad_$(i)"]
        n_days = days_in_month[m]
        day_matrix = zeros(Float64, n_days, 96)
        for d in 1:n_days
            idx_day = ((d-1)*96 + 1):(d*96)
            PF_day = P_block[idx_day] ./ sqrt.(P_block[idx_day].^2 + Q_block[idx_day].^2)
            day_matrix[d,:] = PF_day
        end
        push!(month_pf_list, day_matrix)
    end

    n_months = 3
    total_dists = zeros(Float64, n_months)

    for i in 1:n_months
        dist_sum = 0.0
        for j in 1:n_months
            if i == j
                continue
            end
            A, B = month_pf_list[i], month_pf_list[j]
            n_days_i, n_days_j = size(A,1), size(B,1)
            dist_matrix = zeros(Float64, n_days_i, n_days_j)

            for p in 1:n_days_i
                a = A[p,:]
                for q in 1:n_days_j
                    b = B[q,:]
                    cosine_sim = dot(a,b) / (norm(a) * norm(b))  # cosine similarity
                    dist_matrix[p,q] = 1.0 - cosine_sim          
                end
            end
            dist_sum += mean(dist_matrix)  #using mean corrects for difference in number of days between months
        end
        total_dists[i] = dist_sum
    end

    idx = argmin(total_dists)
    return months_in_season[idx]
end

"""
    network_rep_month(season::String, data, good_buildings)

Calculates the most representative month for a given season based on the load profiles of the buildings.
"""
function network_rep_month(season::String, data, good_buildings)
    n_loads = length(good_buildings)
    rep_months = Int[]
    for l in 1:n_loads
        month_l = finding_most_representative_month(season, data, l)
        push!(rep_months, month_l)
    end
    month_counts = Dict{Int,Int}()
    for m in rep_months
        month_counts[m] = get(month_counts, m, 0) + 1
    end
    sorted_counts = sort(collect(month_counts), by=x->x[2], rev=true)
    days_in_month = [31,28,31,30,31,30,31,31,30,31,30,31]
    month_starts = cumsum([1; 96 .* days_in_month[1:end-1]])
    rep_month_start = month_starts[sorted_counts[1][1]] 
    rep_month_end = rep_month_start + 96 * days_in_month[sorted_counts[1][1]]
    return rep_month_start, rep_month_end, sorted_counts[1][1]
end

"""
    calculating_month_with_highest_average_consumption_per_building(data, good_buildings)
Calculates the month with the highest average consumption per building.
"""
function calculating_month_with_highest_average_consumption_per_building(data, good_buildings)
    days_in_month = [31,28,31,30,31,30,31,31,30,31,30,31]
    month_starts = cumsum([1; 96 .* days_in_month[1:end-1]])
    month_ends   = cumsum(96 .* days_in_month)
    avg_consumptions = zeros(Float64, 12)
    for i in 1:length(good_buildings)
        for m in 1:12
            start_idx, end_idx = month_starts[m], month_ends[m]
            P_block = data[start_idx:end_idx, "PLoad_$(i)"]
            avg_consumptions[m] += mean(P_block)
        end
    end
    avg_consumptions ./= length(good_buildings)
    idx_max = argmax(avg_consumptions)
    return idx_max, avg_consumptions
end

end #module Load_Data