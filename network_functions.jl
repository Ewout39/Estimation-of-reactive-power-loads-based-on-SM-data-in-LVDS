"""
rm_enwl_transformer!(data_eng)

This function removes the transformer from a parsed ENWL `ENGINEERING` data file.
"""

function rm_transformer!(data_eng)
    if haskey(data_eng, "transformer")
        line1 = data_eng["line"]["line1"]
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

function reduce_enwl_lines_eng!(data_eng)
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
function join_lines_eng!(data_eng)
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

function add_length!(ntw::Dict, eng::Dict)
    for (_, br) in ntw["branch"]
        br["orig_length"] = eng["line"][br["name"]]["length"]
    end
    return ntw
end

function add_degree_to_bus!(data) # to see the number of connected ports
    for (b, bus) in data["bus"]
        bus["degree"] = 0
        for (br, branch) in data["branch"]
            if branch["t_bus"] == bus["index"] || branch["f_bus"] == bus["index"]
                bus["degree"] += 1
            end
        end
    end
end

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

function clean_4w_data!(ntw::Dict,  profiles_df::_DF.DataFrame;eng::Dict=Dict{String, Any}(), good_buildings, merge_buses_diff_linecodes::Bool = false)
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

function assign_load_to_parquet_id!(data::Dict, df::_DF.DataFrame, good_buildings)
    parquet_ids = names(df)
    count = 1
    for (_, load) in data["load"]
        if split(parquet_ids[count], "_")[1] == "PLoad"
            load["parquet_id"] = split(parquet_ids[count], "_")[end]
            load["original"] = good_buildings[count]
        end
        count+=1
    end
    return data
end

function insert_P_profiles!(data, df, df_PV, timestep, alpha) #data = math, df = load_profiles, timestep = j
    power_unit = data["settings"]["sbase"]
    @assert power_unit == 1e5 "The profiles are in kW, but the power_unit seems different. Please fix."
    for (_, load) in data["load"]
        load["connections"] = [1, 2, 3, 4]  # Ensure the load is connected to all phases
        load["pd"] = zeros(3)
        p_id = load["parquet_id"]
        tuple1 = df[timestep, "PLoad_"*p_id]
        load["pd"][1] = tuple1[1]/power_unit
        load["pd"][2] = tuple1[2]/power_unit
        if p_id == "25"
            load["pd"][3] = (tuple1[3] - df_PV[timestep, "P_pv_3"].*alpha)/power_unit
        else
            load["pd"][3] = tuple1[3]/power_unit
        end
        #load["qd"] = [df[timestep, "QLoad_"*p_id]/power_unit]
    end
end

function insert_Q_profiles!(data, df, timestep, Q_set, season) #data = math, df = load_profiles, timestep = j, Q_setpoint: 0 = 0.95, 1 = custom,  2 = measured
    power_unit = data["settings"]["sbase"]
    @assert power_unit == 1e5 "The profiles are in kW, but the power_unit seems different. Please fix."
    for (_, load) in data["load"]
        load["qd"] = zeros(3)
        p_id = load["parquet_id"]
        if Q_set == 2
            tuple1 = df[timestep, "QLoad_"*p_id]
        elseif Q_set == 0
            tuple1 = df[timestep, "PLoad_"*p_id].*tan(acos(0.95))
        elseif Q_set == 1
            if season == "Summer"
                if load["original"] in ["3", "5", "8", "9", "11", "12", "15", "16", "18", "21", "26", "27", "28", "33", "35", "38"]
                    tuple1 = df[timestep, "PLoad_"*p_id].*tan(acos(0.99))
                elseif load["original"] in ["4", "7", "10", "19", "20", "30", "32", "36", "39"]
                    tuple1 = df[timestep, "PLoad_"*p_id].*tan(acos(0.99))
                elseif load["original"] in ["14", "22", "23", "29", "34"]
                    tuple1 = df[timestep, "PLoad_"*p_id].*tan(acos(1))
                end
            elseif season == "Autumn"
                if load["original"] in ["5", "8", "20", "22", "34", "39"]
                    tuple1 = df[timestep, "PLoad_"*p_id].*tan(acos(1))
                elseif load["original"] in ["3", "7", "11", "12", "18", "19", "23", "28", "30", "32", "35", "36", "15", "33"]
                    tuple1 = df[timestep, "PLoad_"*p_id].*tan(acos(0.96))
                elseif load["original"] in ["4", "9", "10", "14", "16", "21", "26", "27", "29", "38"]
                    tuple1 = df[timestep, "PLoad_"*p_id].*tan(acos(0.9))
                end
            elseif season == "Winter"
                if load["original"] in ["5", "11", "15", "20", "30", "32", "34", "35", "36", "39", "14", "22", "28", "29", "33"]
                    tuple1 = df[timestep, "PLoad_"*p_id].*tan(acos(1))
                elseif load["original"] in ["4", "16", "21", "23", "26", "27"]
                    tuple1 = df[timestep, "PLoad_"*p_id].*tan(acos(0.98))
                elseif load["original"] in ["3", "12", "18", "19", "9", "10", "38"]
                    tuple1 = df[timestep, "PLoad_"*p_id].*tan(acos(0.88))
                elseif load["original"] in ["7", "8"]
                    tuple1 = df[timestep, "PLoad_"*p_id].*tan(acos(0.97))
                end
            elseif season == "Spring"
                if load["original"] in ["4", "14", "16", "18", "20", "22", "32", "33", "35", "39"]
                    tuple1 = df[timestep, "PLoad_"*p_id].*tan(acos(1))
                elseif load["original"] in ["3", "7", "8", "9", "11", "12", "19", "23", "26", "27", "28", "30", "36"]
                    tuple1 = df[timestep, "PLoad_"*p_id].*tan(acos(0.9))
                elseif load["original"] in ["10", "15", "21", "29", "38"]
                    tuple1 = df[timestep, "PLoad_"*p_id].*tan(acos(0.88))
                elseif load["original"] in ["5", "34"]
                    tuple1 = df[timestep, "PLoad_"*p_id].*tan(acos(0.99))
                end
            end 
        end
        if tuple1 === nothing
            error("No matching tuple assignment for load $(load["original"]) in season $season and Q_set $Q_set")
        end
        load["qd"][1] = tuple1[1]/power_unit
        load["qd"][2] = tuple1[2]/power_unit
        load["qd"][3] = tuple1[3]/power_unit
    end
end

function pf_solution_to_line_loading!(sol::Dict, math::Dict)
    I_base = math["settings"]["sbase"]/(math["settings"]["vbases_default"]["54"])  # in kA
    for (i, line) in sol["solution"]["branch"]
        line_from = sqrt.( (line["cr"][1:4]).^2 + (line["ci"][1:4]).^2 ).*I_base
        line_to = sqrt.( (line["cr"][5:8]).^2 + (line["ci"][5:8]).^2 ).*I_base
        #line_loading = maximum(vcat(line_from, line_to)) #This is wrong needs to be fixed
        line_loading = line_from
        if math["branch"][i]["linecode"] == "pluto" || math["branch"][i]["linecode"] == "hydrogen"
            ampacity = 437.0
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