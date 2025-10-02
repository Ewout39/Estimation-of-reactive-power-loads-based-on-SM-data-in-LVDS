function extract_loading!()
    filepath = "C:\\Users\\ewout\\OneDrive - KU Leuven\\2e_master\\thesis\\datasets\\dataset German household\\repository\\2019_data_15min.hdf5"
    loaded_data = h5open(filepath, "r") do file
    read(file)
    end
    good_buildings = ["3", "4", "5", "7", "8", "9", "10", "11", "12", "14", "15", "16", "18", "19", "20", "21", "22", "23", "26", "27", "28", "29", "30", "32", "33", "34", "35", "36", "38", "39"]

    column_names_P = ["PLoad_$(i)" for i in 1:30]
    column_names_Q = ["QLoad_$(i)" for i in 1:30]
    column_names = vcat(column_names_P, column_names_Q)
    load_data = _DF.DataFrame((column_name => [(0.0, 0.0, 0.0) for _ in 1:35040] for column_name in column_names)...)
    PV_prod = _DF.DataFrame("P_pv_3" => zeros(35040))

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
        if building == "33"
            for j in 1:35040
                PV_prod[j, "P_pv_3"] = loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_TOT]/1000 - loaded_data["WITH_PV"]["SFH$(building)"]["HOUSEHOLD"]["table"][j][:P_TOT_WITH_PV]/1000
            end
        end
        i += 1
    end
    return good_buildings, load_data, PV_prod
end

function initialize_empty_dict!()
    Result_dict = Dict{String, Dict{String, Any}}()
    Result_dict["0"] = Dict("Winter" => Dict{String, Any}(Dict{String, Any}()), "Spring" => Dict{String, Any}(Dict{String, Any}()), "Summer" => Dict{String, Any}(Dict{String, Any}()), "Autumn" => Dict{String, Any}(Dict{String, Any}()))
    Result_dict["1"] = Dict("Winter" => Dict{String, Any}(Dict{String, Any}()), "Spring" => Dict{String, Any}(Dict{String, Any}()), "Summer" => Dict{String, Any}(Dict{String, Any}()), "Autumn" => Dict{String, Any}(Dict{String, Any}()))
    Result_dict["2"] = Dict("Winter" => Dict{String, Any}(Dict{String, Any}()), "Spring" => Dict{String, Any}(Dict{String, Any}()), "Summer" => Dict{String, Any}(Dict{String, Any}()), "Autumn" => Dict{String, Any}(Dict{String, Any}()))
    return Result_dict
end

function add_to_dict!(Result_dict, res,  Q_set, alpha, season, math)
    q_key = string(Q_set)
    s_key = string(season)
    a_key = "Alpha=$(alpha)"
    alpha_dict = get!(get!(get!(Result_dict, q_key, Dict{String,Any}()),
                           s_key, Dict{String,Any}()),
                      a_key, Dict("Busses"=>Dict(), "Branches"=>Dict(), "Loads"=>Dict()))
    for (key, values) in res["solution"]["bus"]
        bus_key = string(key)
        bus_dict = get!(alpha_dict["Busses"], bus_key) do
            Dict(
                "V1" => Float64[values["vm"][1]],
                "V2" => Float64[values["vm"][2]],
                "V3" => Float64[values["vm"][3]],
                "V4" => Float64[values["vm"][4]],
            )
        end
        push!(bus_dict["V1"], values["vm"][1])
        push!(bus_dict["V2"], values["vm"][2])
        push!(bus_dict["V3"], values["vm"][3])
        push!(bus_dict["V4"], values["vm"][4])
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
                "P1" => Float64[values["pd"][1]],
                "P2" => Float64[values["pd"][2]],
                "P3" => Float64[values["pd"][3]],
                "Q1" => Float64[values["qd"][1]],
                "Q2" => Float64[values["qd"][2]],
                "Q3" => Float64[values["qd"][3]],
            )
        end
        push!(load_dict["P1"], values["pd"][1])
        push!(load_dict["P2"], values["pd"][2])
        push!(load_dict["P3"], values["pd"][3])
        push!(load_dict["Q1"], values["qd"][1])
        push!(load_dict["Q2"], values["qd"][2])
        push!(load_dict["Q3"], values["qd"][3]) 
    end
end



#function add_to_dict!(Result_dict, res,  Q_set, alpha, season, math) #Summer = 8832, Fall = 8740, Winter = 8640, Spring = 8828 
#       if !haskey(Result_dict["$(Q_set)"]["$(season)"], "Alpha=$(alpha)")
#            Result_dict["$(Q_set)"]["$(season)"]["Alpha=$(alpha)"] = Dict{String, Any}("Busses" => Dict(), "Branches" => Dict(), "Loads" => Dict())
#        end
#        for (key, values) in res["solution"]["bus"]
#            if !haskey(Result_dict["$(Q_set)"]["$(season)"]["Alpha=$(alpha)"]["Busses"], "$(key)")
#                Result_dict["$(Q_set)"]["$(season)"]["Alpha=$(alpha)"]["Busses"]["$(key)"] = Dict("V1" => [values["vm"][1]], "V2" => [values["vm"][2]], "V3" => [values["vm"][3]], "V4" => [values["vm"][4]])
#            else
#                bus_dict = Result_dict["$(Q_set)"]["$(season)"]["Alpha=$(alpha)"]["Busses"]["$(key)"]
#                push!(bus_dict["V1"], values["vm"][1])
#                push!(bus_dict["V2"], values["vm"][2])
#                push!(bus_dict["V3"], values["vm"][3])
#                push!(bus_dict["V4"], values["vm"][4])
#            end
#        end
#        for (key, values) in res["solution"]["branch"]
#            if !haskey(Result_dict["$(Q_set)"]["$(season)"]["Alpha=$(alpha)"]["Branches"], "$(key)")
#                Result_dict["$(Q_set)"]["$(season)"]["Alpha=$(alpha)"]["Branches"]["$(key)"] = Dict("line_loading" => [values["line_loading"]])
#            else
#                branch_dict = Result_dict["$(Q_set)"]["$(season)"]["Alpha=$(alpha)"]["Branches"]["$(key)"]
#                push!(branch_dict["line_loading"], values["line_loading"])
#            end
#        end
#        for (key, values) in math["load"]
#            if !haskey(Result_dict["$(Q_set)"]["$(season)"]["Alpha=$(alpha)"]["Loads"], "$(key)")
#                Result_dict["$(Q_set)"]["$(season)"]["Alpha=$(alpha)"]["Loads"]["$(key)"] = Dict("P1" => [values["pd"][1]], "P2" => [values["pd"][2]], "P3" => [values["pd"][3]], "Q1" => [values["qd"][1]], "Q2" => [values["qd"][2]], "Q3" => [values["qd"][3]])
#            else
#                load_dict = Result_dict["$(Q_set)"]["$(season)"]["Alpha=$(alpha)"]["Loads"]["$(key)"]
#                push!(load_dict["P1"], values["pd"][1])
#                push!(load_dict["P2"], values["pd"][2])
#                push!(load_dict["P3"], values["pd"][3])
#                push!(load_dict["Q1"], values["qd"][1])
#                push!(load_dict["Q2"], values["qd"][2])
#                push!(load_dict["Q3"], values["qd"][3])
#            end
#        end
#end