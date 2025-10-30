function extract_loading_german!()
    filepath = "C:\\Users\\ewout\\OneDrive - KU Leuven\\2e_master\\thesis\\datasets\\dataset German household\\repository\\2019_data_15min.hdf5"
    loaded_data = h5open(filepath, "r") do file
    read(file)
    end
    PV_building = "33"
    good_buildings = ["3", "4", "5", "7", "8", "9", "10", "11", "12", "14", "15", "16", "18", "19", "20", "21", "22", "23", "26", "27", "28", "29", "30", "32", "33", "34", "35", "36", "38", "39"]
    column_names_P = ["PLoad_$(i)" for i in 1:length(good_buildings)]
    column_names_Q = ["QLoad_$(i)" for i in 1:length(good_buildings)]
    column_names = vcat(column_names_P, column_names_Q)
    load_data = _DF.DataFrame((column_name => [(0.0, 0.0, 0.0) for _ in 1:35040] for column_name in column_names)...)
    PV_prod = _DF.DataFrame("P_pv_3" => zeros(35040))
    PV_prod_Q = _DF.DataFrame("Q_pv_3" => zeros(35040))
    i=1
    for building in good_buildings
        if haskey(loaded_data["NO_PV"], "SFH$(building)")
            for j in 1:35040
                if haskey(loaded_data["NO_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j], :P_1) == true || haskey(loaded_data["NO_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j], :P_) == true || haskey(loaded_data["NO_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j], :P_3) == true
                    load_data[j, "PLoad_$(i)"] = (loaded_data["NO_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_1]/1000 + loaded_data["NO_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:P_1]/1000, loaded_data["NO_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_2]/1000 + loaded_data["NO_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:P_2]/1000, loaded_data["NO_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_3]/1000 + loaded_data["NO_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:P_3]/1000)
                    load_data[j, "QLoad_$(i)"] = (loaded_data["NO_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:Q_1]/1000 + loaded_data["NO_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:Q_1]/1000,loaded_data["NO_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:Q_2]/1000 + loaded_data["NO_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:Q_2]/1000, loaded_data["NO_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:Q_3]/1000 + loaded_data["NO_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:Q_3]/1000)
                else
                    load_data[j, "PLoad_$(i)"] = (loaded_data["NO_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_1]/1000 + loaded_data["NO_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:P_TOT]/3000, loaded_data["NO_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_2]/1000 + loaded_data["NO_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:P_TOT]/3000, loaded_data["NO_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_3]/1000 + loaded_data["NO_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:P_TOT]/3000)
                    load_data[j, "QLoad_$(i)"] = (loaded_data["NO_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:Q_1]/1000 + loaded_data["NO_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:Q_TOT]/3000, loaded_data["NO_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:Q_2]/1000 + loaded_data["NO_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:Q_TOT]/3000, loaded_data["NO_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:Q_3]/1000 + loaded_data["NO_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:Q_TOT]/3000)
                end
            end 
        elseif haskey(loaded_data["WITH_PV"], "SFH$(building)")
            for j in 1:35040
                if building == "33"
                    load_data[j, "PLoad_$(i)"] = (loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_1]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:P_1]/1000,loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_2]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:P_2]/1000, loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_3]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:P_3]/1000 + (loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_TOT]/1000 - loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_TOT_WITH_PV]/1000))
                    load_data[j, "QLoad_$(i)"] = (loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:Q_1]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:Q_1]/1000, loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:Q_2]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:Q_2]/1000, loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:Q_3]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:Q_3]/1000)
                elseif haskey(loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j], :P_1) == true || haskey(loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j], :P_2) == true || haskey(loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j], :P_3) == true
                    load_data[j, "PLoad_$(i)"] = (loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_1]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:P_1]/1000,loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_2]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:P_2]/1000, loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_3]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:P_3]/1000)
                    load_data[j, "QLoad_$(i)"] = (loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:Q_1]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:Q_1]/1000, loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:Q_2]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:Q_2]/1000, loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:Q_3]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:Q_3]/1000)
                else
                    load_data[j, "PLoad_$(i)"] = (loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_1]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:P_TOT]/3000, loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_2]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:P_TOT]/3000, loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_3]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:P_TOT]/3000)
                    load_data[j, "QLoad_$(i)"] = (loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:Q_1]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:Q_TOT]/3000, loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:Q_2]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:Q_TOT]/3000, loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:Q_3]/1000 + loaded_data["WITH_PV"]["SFH$(building)"]["HEATPUMP"]["table"][j][:Q_TOT]/3000)
                end
            end
        else
            error("Building $(building) not found in either NO_PV or PV datasets")
        end
        if building == PV_building
            for j in 1:35040
                PV_prod[j, "P_pv_3"] = loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_TOT]/1000 - loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_TOT_WITH_PV]/1000
                PV_prod_Q[j, "Q_pv_3"] = PV_prod[j, "P_pv_3"] * tan(deg2rad(acos(0.95)))
            end
        end
        i += 1
    end
    return good_buildings, load_data, PV_prod, PV_prod_Q
end

function extract_loading_usa!()
    loaded_data = Dict{Int, Any}()
    filepath1 = "C:\\Users\\ewout\\OneDrive - KU Leuven\\2e_master\\thesis\\datasets\\dataset German household\\repository\\2019_data_15min.hdf5"
    loaded_data_PV = h5open(filepath1, "r") do file
    read(file)
    end
    PV_prod = _DF.DataFrame("P_pv_3" => zeros(35040))
    PV_prod_Q = _DF.DataFrame("Q_pv_3" => zeros(35040))
    for j in 1:35040
                PV_prod[j, "P_pv_3"] = (loaded_data_PV["WITH_PV"]["SFH33"]["HOUSEHOLD"]["table"][j][:P_TOT]/1000 - loaded_data_PV["WITH_PV"]["SFH33"]["HOUSEHOLD"]["table"][j][:P_TOT_WITH_PV]/1000)/2
                PV_prod_Q[j, "Q_pv_3"] = PV_prod[j, "P_pv_3"] .* tan(acos(0.97)) #Strong effect on results
    end
    good_buildings = ["$(i)" for i in 1:26]
    column_names_P = ["PLoad_$(i)" for i in 1:length(good_buildings)]
    column_names_Q = ["QLoad_$(i)" for i in 1:length(good_buildings)]
    column_names = vcat(column_names_P, column_names_Q)
    load_data = _DF.DataFrame((column_name => [0.0 for _ in 1:35040] for column_name in column_names)...)
    for i in 1:26
        filepath = "C:\\Users\\ewout\\OneDrive - KU Leuven\\2e_master\\thesis\\datasets\\MFRED USA dataset\\Code_data\\powerdf_clean_test\\$(i).csv"
        data = CSV.read(filepath, _DF.DataFrame, delim=',')
        loaded_data[i] = data
        for j in 1:35040
            load_data[j, "PLoad_$(i)"] = loaded_data[i][j, :P]
            load_data[j, "QLoad_$(i)"] = loaded_data[i][j, :Q]
        end
    end
    return good_buildings, load_data, PV_prod, PV_prod_Q
end

function initialize_empty_dict!()
    Result_dict = Dict{String, Dict{String, Any}}()
    Result_dict["0"] = Dict("Winter" => Dict{String, Any}(Dict{String, Any}()), "Spring" => Dict{String, Any}(Dict{String, Any}()), "Summer" => Dict{String, Any}(Dict{String, Any}()), "Autumn" => Dict{String, Any}(Dict{String, Any}()))
    Result_dict["1"] = Dict("Winter" => Dict{String, Any}(Dict{String, Any}()), "Spring" => Dict{String, Any}(Dict{String, Any}()), "Summer" => Dict{String, Any}(Dict{String, Any}()), "Autumn" => Dict{String, Any}(Dict{String, Any}()))
    Result_dict["2"] = Dict("Winter" => Dict{String, Any}(Dict{String, Any}()), "Spring" => Dict{String, Any}(Dict{String, Any}()), "Summer" => Dict{String, Any}(Dict{String, Any}()), "Autumn" => Dict{String, Any}(Dict{String, Any}()))
    return Result_dict
end

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
                "V1" => Float64[sqrt(values["vr"][1]^2 + values["vi"][1]^2)],
                "V2" => Float64[sqrt(values["vr"][2]^2 + values["vi"][2]^2)],
                "V3" => Float64[sqrt(values["vr"][3]^2 + values["vi"][3]^2)],
                "V4" => Float64[sqrt(values["vr"][4]^2 + values["vi"][4]^2)],
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
            Dict("line_loading_P1" => Float64[values["line_loading"][1]],
                 "line_loading_P2" => Float64[values["line_loading"][2]],
                 "line_loading_P3" => Float64[values["line_loading"][3]])
        end
        push!(branch_dict["line_loading_P1"], values["line_loading"][1])
        push!(branch_dict["line_loading_P2"], values["line_loading"][2])
        push!(branch_dict["line_loading_P3"], values["line_loading"][3])
    end
    for (key, values) in math["load"]
        load_key = string(key)
        load_dict = get!(alpha_dict["Loads"], load_key) do
            Dict(
                "P$(values["phase_connections"])" => Float64[values["pd"][1]],
                "Q$(values["phase_connections"])" => Float64[values["qd"][1]]
            )
        end
        push!(load_dict["P$(values["phase_connections"])"], values["pd"][1])
        push!(load_dict["Q$(values["phase_connections"])"], values["qd"][1])
    end
    for (key, values) in res["solution"]["gen"]
        gen_key = string(key)
        gen_dict = get!(alpha_dict["Gen"], gen_key) do
            Dict(
                "P1" => Float64[values["pg"][1]],
                "P2" => Float64[values["pg"][2]],
                "P3" => Float64[values["pg"][3]],
                "Q1" => Float64[values["qg"][1]],
                "Q2" => Float64[values["qg"][2]],
                "Q3" => Float64[values["qg"][3]],
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

function finding_most_representative_month_2021(season::String, data, i::Int)
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

function network_rep_month(season::String, data, good_buildings)
    n_loads = length(good_buildings)
    rep_months = Int[]
    for l in 1:n_loads
        month_l = finding_most_representative_month_2021(season, data, l)
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