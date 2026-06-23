"""
    NetworkFunctions

This file contains functions related to the network and load processing and load modeling.

It includes functionality for:
- cleaning and reducing network data
- enriching network components with additional properties
- assigning load profiles to loads in the mathematical model

These functions are used in the hosting capacity analysis in
`Q_estimation_application.jl`.

"""
module NetworkFunctions

import DataFrames as _DF
using Random

export rm_transformer!, reduce_lines_eng!, add_length!, add_degree_to_bus!, remove_all_superfluous_buses!, find_voltage_source_branch_bus, clean_4w_data!, add_linecode_math!, assign_load_to_parquet_id!, select_EV_loads, insert_P_profiles!, insert_Q_profiles_usa!, add_initial_values!, pf_solution_to_line_loading!

"""
    rm_transformer!(data_eng)

Removes the transformer from the parsed PowerModelsDistribution 'ENGINEERING' data file.
"""

function rm_transformer!(data_eng)
    if haskey(data_eng, "transformer")
        trans = data_eng["transformer"]["tr1"]
        vprim_scale = trans["vm_nom"][2]/trans["vm_nom"][1]

        vsource = data_eng["voltage_source"]["source"]

        vsource["vm"] *= vprim_scale
        vsource["rs"] *= vprim_scale^2
        vsource["xs"] *= vprim_scale^2
        vsource["bus"] = "1"

        delete!(data_eng, "transformer")
        delete!(data_eng["bus"], "sourcebus")

        vbases_default = data_eng["settings"]["vbases_default"]
        vbases_default["1"] = vbases_default["sourcebus"]*vprim_scale
        delete!(vbases_default, "sourcebus")
    end
end

"""
    reduce_lines_eng!(data_eng)

Removes all trailing lines from a parsed PowerModelsDistribution 'ENGINEERING' data file, and joins lines that are connected in series and have the same linecode.
"""

function reduce_lines_eng!(data_eng)
    rm_trailing_lines_eng!(data_eng)
    join_lines_eng!(data_eng)
end

function rm_trailing_lines_eng!(data_eng)

    buses_exclude = []
    for comp_type in ["load", "shunt", "generator", "voltage_source"]
        if haskey(data_eng, comp_type)
            buses_exclude = union(buses_exclude, [comp["bus"] for (_, comp) in data_eng[comp_type]])
        end
    end
    if haskey(data_eng, "transformer")
        buses_exclude = union(buses_exclude, hcat([tr["bus"] for (_, tr) in data_eng["transformer"]]...))
    end

    line_has_shunt = Dict()
    bus_lines = Dict(k=>[] for k in keys(data_eng["bus"]))
    for (id, line) in data_eng["line"]
        lc = data_eng["linecode"][line["linecode"]]
        line_has_shunt[id] = !all(iszero(lc[k]) for k in ["b_fr", "b_to", "g_fr", "g_to"])
        push!(bus_lines[line["f_bus"]], id)
        push!(bus_lines[line["t_bus"]], id)
    end

    eligible_buses = [bus_id for (bus_id, line_ids) in bus_lines if length(line_ids)==1 && !(bus_id in buses_exclude) && !line_has_shunt[line_ids[1]]]

    while !isempty(eligible_buses)
        for bus_id in eligible_buses
            # this trailing bus has one associated line
            line_id = bus_lines[bus_id][1]
            line = data_eng["line"][line_id]

            delete!(data_eng["line"], line_id)
            delete!(data_eng["bus"],  bus_id)

            other_end_bus = line["f_bus"]==bus_id ? line["t_bus"] : line["f_bus"]
            bus_lines[other_end_bus] = setdiff(bus_lines[other_end_bus], [line_id])
            delete!(bus_lines,  bus_id)
        end

        eligible_buses = [bus_id for (bus_id, line_ids) in bus_lines if length(line_ids)==1 && !(bus_id in buses_exclude) && !line_has_shunt[line_ids[1]]]
    end
end

function _line_reverse_eng!(line)
    prop_pairs = [("f_bus", "t_bus")]

    for (x,y) in prop_pairs
        tmp = line[x]
        line[x] = line[y]
        line[y] = tmp
    end
end

function join_lines_eng!(data_eng::Dict)
    # a bus is eligible for reduction if it only appears in exactly two lines
    buses_all = collect(keys(data_eng["bus"]))
    buses_exclude = []

    # start by excluding all buses that appear in components other than lines
    for comp_type in ["load", "shunt", "generator", "voltage_source"]
        if haskey(data_eng, comp_type)
            buses_exclude = union(buses_exclude, [comp["bus"] for (_, comp) in data_eng[comp_type]])
        end
    end

    # per bus, list all inbound or outbound lines
    bus_lines = Dict(bus=>[] for bus in buses_all)
    for (id, line) in data_eng["line"]
        push!(bus_lines[line["f_bus"]], id)
        push!(bus_lines[line["t_bus"]], id)
    end

    # exclude all buses that do not have exactly two lines connected to it
    buses_exclude = union(buses_exclude, [bus for (bus, lines) in bus_lines if length(lines)!=2])

    # now loop over remaining buses
    candidates = setdiff(buses_all, buses_exclude)
    for bus in candidates
        line1_id, line2_id = bus_lines[bus]
        line1 = data_eng["line"][line1_id]
        line2 = data_eng["line"][line2_id]

        # reverse lines if needed to get the order
        # (x)--fr-line1-to--(bus)--to-line2-fr--(x)
        if line1["f_bus"]==bus
            _line_reverse_eng!(line1)
        end
        if line2["f_bus"]==bus
            _line_reverse_eng!(line2)
        end

        reducable = true
        reducable = reducable && line1["linecode"]==line2["linecode"]
        reducable = reducable && all(line1["t_connections"].==line2["t_connections"])
        if reducable

            line1["length"] += line2["length"]
            line1["t_bus"] = line2["f_bus"]
            line1["t_connections"] = line2["f_connections"]

            delete!(data_eng["line"], line2_id)
            delete!(data_eng["bus"], bus)
            for x in candidates
                if line2_id in bus_lines[x]
                    bus_lines[x] = [setdiff(bus_lines[x], [line2_id])..., line1_id]
                end
            end
        end
    end

    return data_eng
end

"""
    add_length!(ntw::Dict, eng::Dict)

Adds the length of the lines from the parsed PowerModelsDistribution 'ENGINEERING' data file to the mathematical dictionary.
"""

function add_length!(ntw::Dict, eng::Dict)
    for (_, br) in ntw["branch"]
        br["orig_length"] = eng["line"][br["name"]]["length"]
    end
    return ntw
end

"""
    add_degree_to_bus!(data)

Adds the degree (as defined in graph theory) of all nodes/buses in the feeder.
"""

function add_degree_to_bus!(data::Dict) # to see the number of connected ports
    for (b, bus) in data["bus"]
        bus["degree"] = 0
        for (br, branch) in data["branch"]
            if branch["t_bus"] == bus["index"] || branch["f_bus"] == bus["index"]
                bus["degree"] += 1
            end
        end
    end
end

"""
    remove_all_superfluous_buses!(data::Dict)

Removes all the buses that have degree 2 and are not connected to anything. The impedance of the resulting segment is the sum of the impedances of all removed segments.
"""

function remove_all_superfluous_buses!(data::Dict)
    @assert !haskey(data, "nw") "Please use `remove_all_intermediate_buses_mn` for multinetwork data dicts like this one"
    load_buses = ["$(load["load_bus"])" for (_, load) in data["load"]]
    gen_buses = ["$(gen["gen_bus"])" for (_, gen) in data["gen"]]
    add_degree_to_bus!(data)
    for lb in load_buses @assert data["bus"][lb]["degree"] == 1 "Load $lb is on the main cable, add a small connection cable with the appropriate util function!" end #Need to change this to 3
    to_delete = [b for (b, bus) in data["bus"] if (b ∉ union!(gen_buses, load_buses) && bus["degree"] <= 2)]
    for db in to_delete
        data["bus"][db]["adjacent_buses"] = []
        data["bus"][db]["inout_branches"] = []
        for (br, branch) in data["branch"]
            if branch["f_bus"] == parse(Int, db) || branch["t_bus"] == parse(Int, db)
                push!(data["bus"][db]["inout_branches"], br)
                if branch["f_bus"] != parse(Int, db)
                    push!(data["bus"][db]["adjacent_buses"], "$(branch["f_bus"])")
                else
                    push!(data["bus"][db]["adjacent_buses"], "$(branch["t_bus"])")
                end
            end
        end
    end
    while !isempty(to_delete)
        for db in to_delete
            if any([b ∈ to_delete for b in data["bus"][db]["adjacent_buses"]])
                deletable_adj_bus = [b for b in data["bus"][db]["adjacent_buses"] if b ∈ to_delete][1]
                other_adj_bus = [b for b in data["bus"][db]["adjacent_buses"] if b != deletable_adj_bus][1]
                deletable_adj_bus_branches = data["bus"][deletable_adj_bus]["inout_branches"]
                delete_branch = first(intersect(Set(data["bus"][db]["inout_branches"]), Set(deletable_adj_bus_branches)))
                preserve_branch = [br for br in data["bus"][db]["inout_branches"] if br != delete_branch][1]
                
                Req = (data["branch"][preserve_branch]["br_r"] .+ data["branch"][delete_branch]["br_r"])
                Xeq = (data["branch"][preserve_branch]["br_x"] .+ data["branch"][delete_branch]["br_x"]) 
                data["branch"][preserve_branch]["br_r"] = Req
                data["branch"][preserve_branch]["br_x"] = Xeq
                
                data["branch"][preserve_branch]["f_bus"] = parse(Int64, other_adj_bus)
                data["branch"][preserve_branch]["t_bus"] = parse(Int64, deletable_adj_bus)
                data["bus"][deletable_adj_bus]["adjacent_buses"] = filter(x->x!=db, data["bus"][deletable_adj_bus]["adjacent_buses"])
                push!(data["bus"][deletable_adj_bus]["adjacent_buses"], other_adj_bus)
                data["bus"][deletable_adj_bus]["inout_branches"] = filter(x->x!=delete_branch, data["bus"][deletable_adj_bus]["inout_branches"])
                push!(data["bus"][deletable_adj_bus]["inout_branches"], preserve_branch)
                delete!(data["branch"], delete_branch)
            else
                delete_branch = data["bus"][db]["inout_branches"][1]
                preserve_branch = [br for br in data["bus"][db]["inout_branches"] if br != delete_branch][1]
                Req = (data["branch"][preserve_branch]["br_r"] .+ data["branch"][delete_branch]["br_r"])
                Xeq = (data["branch"][preserve_branch]["br_x"] .+ data["branch"][delete_branch]["br_x"]) 
                data["branch"][preserve_branch]["br_r"] = Req
                data["branch"][preserve_branch]["br_x"] = Xeq
                
                delete!(data["branch"], delete_branch)
                data["branch"][data["bus"][db]["inout_branches"][2]]["f_bus"] = parse(Int64, data["bus"][db]["adjacent_buses"][1])
                data["branch"][data["bus"][db]["inout_branches"][2]]["t_bus"] = parse(Int64, data["bus"][db]["adjacent_buses"][2])
            end
            delete!(data["bus"], db)
            to_delete = filter(x->x!=db, to_delete)
        end
    end
    # the lines below make sure that the orientation of the branch at the slack bus is from slack_bus to --> rest of feeder
    ref_bus = [bus["index"] for (_,bus) in data["bus"] if bus["bus_type"] == 3][1]
    ref_branch_fr = [b for (b, br) in data["branch"] if br["f_bus"] == ref_bus]
    if isempty(ref_branch_fr) 
        ref_branch_to = [b for (b, br) in data["branch"] if br["t_bus"] == ref_bus][1]
        f_bus = data["branch"][ref_branch_to]["f_bus"]
        data["branch"][ref_branch_to]["f_bus"] = ref_bus
        data["branch"][ref_branch_to]["t_bus"] = f_bus
    end
    return data
end

function find_voltage_source_branch_bus(math)
    for (b, branch) in math["branch"]
        if branch["source_id"] == "voltage_source.source"
            return b, branch["f_bus"], branch["t_bus"]
        end
    end
    return error()
end

"""
    clean_4w_data!(ntw::Dict,  profiles_df::_DF.DataFrame;eng::Dict=Dict{String, Any}(), good_buildings, merge_buses_diff_linecodes::Bool = false)

# Arguments:
- `ntw`: the mathematical dictionary to which the profiles should be added
- `profiles_df`: the dataframe containing the load profiles
- `eng`: the parsed PowerModelsDistribution 'ENGINEERING' data file
- `good_buildings`: a list of the buildings to include
- `merge_buses_diff_linecodes`: whether to merge buses that are connected by lines with different linecodes (default is false)

Cleans a MATHEMATICAL data dictionary
"""

function clean_4w_data!(ntw::Dict, profiles_df::_DF.DataFrame;eng::Dict=Dict{String, Any}(), good_buildings, merge_buses_diff_linecodes::Bool = false)
    if merge_buses_diff_linecodes 
        remove_all_superfluous_buses!(ntw) 
        add_length!(ntw, eng)
        #TODO add function to add length even when we remove all superfluous buses
    end
    assign_load_to_parquet_id!(ntw, profiles_df, good_buildings)
    #### below removes virtual voltage source (but the transformer I removed in the eng model, thus beforehand)
    vsource_branch, vsource_bus, new_slackbus = find_voltage_source_branch_bus(ntw) 
    ntw["gen"]["1"]["gen_bus"] = new_slackbus
    ntw["bus"]["$new_slackbus"] = deepcopy(ntw["bus"]["$vsource_bus"])
    ntw["bus"]["$new_slackbus"]["bus_i"] = new_slackbus
    ntw["bus"]["$new_slackbus"]["index"] = new_slackbus
    delete!(ntw["branch"], vsource_branch)
    delete!(ntw["bus"], "$vsource_bus")
    return ntw
end

function add_linecode_math!(math::Dict, eng::Dict)
    for (id, branch) in math["branch"]
        name = branch["name"]  # This usually matches the line ID in eng["line"]
        if haskey(eng["line"], name) && haskey(eng["line"][name], "linecode")
            branch["linecode"] = eng["line"][name]["linecode"]
        end
    end
end

"""
    assign_load_to_parquet_id!(data::Dict, df::_DF.DataFrame, good_buildings)

Assigns the loads in the mathematical dictionary to some load profiles.
"""

function assign_load_to_parquet_id!(data::Dict, df::_DF.DataFrame, good_buildings)
    parquet_ids = names(df)
    count = 1
    for (_, load) in data["load"]
        if split(parquet_ids[count], "_")[1] == "PLoad"
            load["parquet_id"] = split(parquet_ids[count], "_")[end]
            load["original"] = good_buildings[count]
            load["phase_connections"] = load["connections"][1]
        end
        count+=1
    end
    return data
end

"""
    select_EV_loads(math, Nr_EVs)

Assigns a number of EV loads to the loads in the mathematical dictionary.
"""

function select_EV_loads(data::Dict, Nr_EVs::Int)
    rng = Random.seed!(1)                 
    numbers = randperm(rng, 55)[1:55]
    EV_load_list = []
    phase_1 = 0
    phase_2 = 0
    phase_3 = 0
    nr_EVs = 1
    if Nr_EVs > 0
        for n in numbers
            if data["load"]["$(n)"]["connections"][1] == 1 && ((phase_1 - 2 <  phase_2 && phase_1 - 2 < phase_3) || phase_1 < 3)
                phase_1 += 1
                push!(EV_load_list, "$(n)")
                nr_EVs += 1
            elseif data["load"]["$(n)"]["connections"][1] == 2 && (phase_2 - 2 < phase_1 && phase_2 - 2 < phase_3 || phase_2 < 3)
                phase_2 += 1
                push!(EV_load_list , "$(n)")
                nr_EVs += 1
            elseif data["load"]["$(n)"]["connections"][1] == 3 && (phase_3 - 2 < phase_1 && phase_3 - 2 < phase_2 || phase_3 < 3)
                phase_3 += 1
                push!(EV_load_list, "$(n)")
                nr_EVs += 1
            end
            if nr_EVs > Nr_EVs
                break
            end
        end
    end
    return EV_load_list
end

"""
    insert_P_profiles!(data, df, timestep, alpha, EV_load, power_mult::Float64=1.0)

# Arguments:
- `data`: the mathematical dictionary to which the profiles should be added
- `df`: the dataframe containing the load profiles
- `timestep`: the timestep for which the profiles should be added
- `alpha`: the scaling factor for the load profiles
- `EV_load_list`: the list of loads to which an EV load should be added
- `power_mult`: the multiplier for the EV load (default is 1.0, which corresponds to 3.5 kW)

Inserts the active power load profiles into the mathematical dictionary for a given timestep, and adds an EV load when relevant.
"""

function insert_P_profiles!(data::Dict, df::_DF.DataFrame, timestep::Int, alpha::Int64, EV_load_list::Vector{Any}, power_mult::Float64=1.0)
    power_unit = data["settings"]["sbase"]
    @assert power_unit == 1e4 "The profiles are in kW, but the power_unit seems different. Please fix."
    for (key, load) in data["load"]
        p_id = load["parquet_id"]
        load1 = df[timestep, "PLoad_"*p_id]*alpha
        if key in EV_load_list && (72 <= mod(timestep, 96) && mod(timestep, 96) <= 88) #between 6pm and 10pm
            EV_load_val = 3.5 + 0.6*power_mult  #kW
        else
            EV_load_val = 0.0
        end
        load["pd"][1] = (load1+EV_load_val)/power_unit
    end
end

"""
    insert_Q_profiles_usa!(data, df, timestep, Q_set, season, alpha, power_mult::Float64=1.0)

# Arguments:
- `data`: the mathematical dictionary to which the profiles should be added
- `df`: the dataframe containing the load profiles
- `timestep`: the timestep for which the profiles should be added
- `Q_set`: the method for determining the reactive power load (0 = 0.95 power factor, 1 = custom power factor based on season and building type, 2 = use measured reactive power load from profiles)
- `season`: the season for which the profiles should be added (used when `Q_set` = 1)
- `alpha`: the scaling factor for the load profiles

Inserts the reactive power load profiles into the mathematical dictionary for a given timestep, based on the specified method for determining the reactive power load.
"""

function insert_Q_profiles_usa!(data::Dict, df::_DF.DataFrame, timestep::Int, Q_set::Int, season::String, alpha::Int64)
    power_unit = data["settings"]["sbase"]
    @assert power_unit == 1e4 "The profiles are in kW, but the power_unit seems different. Please fix."
    for (_, load) in data["load"]
        p_id = load["parquet_id"]
        if Q_set == 2
            Q_load1 = df[timestep, "QLoad_"*p_id]
        elseif Q_set == 0
            Q_load1 = df[timestep, "PLoad_"*p_id].*tan(acos(0.95))
        elseif Q_set == 1
            if season == "Summer"
                if load["original"] in ["1", "2", "3", "4", "5", "6", "7", "9", "13", "26", "27", "28", "29", "30", "31", "32", "33",  "35", "39", "52", "53", "54", "55"]
                    PF = 0.98
                elseif load["original"] in ["8", "11", "12", "14", "16", "18", "24", "25", "34", "37", "38", "40", "42", "44", "50", "51"]
                    PF = 0.99
                elseif load["original"] in ["10", "15", "17", "19", "20", "21", "22", "23", "36", "41", "43", "45", "46", "47", "48", "49"]
                    PF = 1.0
                end
            elseif season == "Autumn"
                if load["original"] in ["6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "18", "19", "20", "21", "24", "25", "17", "22", "23", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51"]
                    PF = 1.0
                elseif load["original"] in ["1", "2", "3", "4", "5", "26", "27", "28", "29", "30", "31", "52", "53", "54", "55"]
                    PF = 0.99
                end
            elseif season == "Winter"
                if load["original"] in ["10", "11", "12", "14", "16", "17", "1", "2", "3", "4", "5", "13", "21", "6", "7", "8", "9", "15", "18", "19", "20", "24", "25", "22", "23", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "53", "54", "55"]
                    PF = 1.0
                elseif load["original"] in ["26", "52"]
                    PF = 0.99
                end
            elseif season == "Spring"
                if load["original"] in  ["6", "8", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "24", "25", "22", "23", "32", "34", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51"]
                    PF = 1.0
                elseif load["original"] in ["1", "2", "3", "4", "5", "7", "9", "26", "27", "28", "29", "30", "31", "33", "35", "52", "53", "54", "55"]
                    PF = 0.99
                end
            end
            Q_load1 = df[timestep, "PLoad_"*p_id].*tan(acos(PF))
        end
        load["qd"][1] = Q_load1*alpha/power_unit
    end
end

function add_initial_values!(math::Dict, result::Dict)
    for (key, bus) in math["bus"]
        vr = result["solution"]["bus"]["$key"]["vr"]
        vi = result["solution"]["bus"]["$key"]["vi"]
        bus["vr_start"] = vr
        bus["vi_start"] = vi
    end
end    

"""
    pf_solution_to_line_loading!(sol::Dict, math::Dict)

Calculates the line loading for each branch in the mathematical dictionary based on the power flow solution.
"""

function pf_solution_to_line_loading!(sol::Dict, math::Dict)
    slack_bus = 103
    for (key, bus) in math["bus"]
        if bus["bus_type"] == 3
            slack_bus = parse(Int64, key)
            break
        end
    end

    for (i, line) in sol["solution"]["branch"]
        bus = math["branch"]["$(i)"]["f_bus"]
        um = sqrt.(sol["solution"]["bus"]["$(bus)"]["vr"][1:4].^2 .+ sol["solution"]["bus"]["$(bus)"]["vi"][1:4].^2)
        ua = atan.(sol["solution"]["bus"]["$(bus)"]["vi"][1:4] ./ sol["solution"]["bus"]["$(bus)"]["vr"][1:4])
        uf = um .* exp.(1im .* ua)
        if haskey(line, "cr") && haskey(line, "ci")
            i_f = line["cr"][1:4] .+ 1im .* line["ci"][1:4]
            sf = uf.*conj(i_f)
            pf = real.(sf)
            qf = imag.(sf)
        else
            pf = line["pf"][1:4]
            qf = line["qf"][1:4] 
        end
        line_loading = sqrt.(pf.^2 .+ qf.^2).*math["settings"]["sbase"]./(abs.(uf).*math["settings"]["vbases_default"]["$(slack_bus)"])
        if math["branch"][i]["linecode"] == "pluto" || math["branch"][i]["linecode"] == "hydrogen"
            ampacity = 600 
        elseif math["branch"][i]["linecode"] == "ABC2x16"
            ampacity = 78.0
        elseif math["branch"][i]["linecode"] == "TW2X16"
            ampacity = 437.0
        else
            warning("Linecode $(math["branch"][i]["linecode"]) not recognized, assuming ampacity of 437 A") 
            ampacity = 437.0
        end
        sol["solution"]["branch"][i]["line_loading"] = line_loading./ampacity
    end
end

end #module NetworkFunctions