using PowerModelsAnalytics
import PowerModelsDistribution as _PMD
import DataFrames as _DF
using JuMP
using HDF5
using Plots
include("network_functions.jl")
include("load_data.jl")
eng = _PMD.parse_file("Master_oh.dss", data_model = _PMD.ENGINEERING, transformations=[_PMD.transform_loops!,_PMD.remove_all_bounds!])
rm_transformer!(eng)
reduce_enwl_lines_eng!(eng)
eng["settings"]["sbase_default"] = 100000
math = _PMD.transform_data_model(eng, kron_reduce=false, phase_project=false)
good_buildings, load_profiles, PV_profile = extract_loading!()
#z_pu = (math["settings"]["voltage_scale_factor"]*math["settings"]["vbases_default"][collect(keys(math["settings"]["vbases_default"]))[1]])^2/(math["settings"]["power_scale_factor"])
clean_4w_data!(math, load_profiles, eng=eng, good_buildings=good_buildings, merge_buses_diff_linecodes = false)
_PMD.add_start_vrvi!(math) # adds start values for real (vr) and imaginary (vi) voltages
add_linecode_math!(math, eng)

alpha_range = [1, 10, 20, 29, 30, 31, 32, 33, 34, 35, 36, 40, 50, 81]
max_timesteps = 672
season = "Summer"
Result_dict = initialize_empty_dict!()
function hosting_capacity_analysis!(math, load_profiles, PV_profile, alpha_range, max_timesteps, Q_setpoint, season)
    if season == "Winter"
        timesteps_range = 577:(577+max_timesteps-1)
    elseif season == "Spring"
        timesteps_range = 9313:(9313+max_timesteps-1)
    elseif season == "Summer"
        timesteps_range = 21305:(21305+max_timesteps-1)
    elseif season == "Autumn"
        timesteps_range = 27361:(27361+max_timesteps-1)
    else
        error("Season must be one of: Winter, Spring, Summer, Autumn")
    end
    for alpha in alpha_range
        for timestep in timesteps_range
            insert_P_profiles!(math, load_profiles, PV_profile, timestep, alpha)
            insert_Q_profiles!(math, load_profiles, timestep, Q_setpoint, season)
            res = _PMD.solve_mc_pf(math, Ipopt.Optimizer)
            pf_solution_to_line_loading!(res, math)
            if res["termination_status"] != _PMD.PF_CONVERGED
                @warn "Power flow did not converge at timestep $timestep for alpha = $alpha"
                return
            else 
                add_to_dict!(Result_dict, res, Q_setpoint, alpha, season, math) 
                for (key, values) in res["solution"]["bus"]
                    vmag1 = values["vm"][1]
                    vmag2 = values["vm"][2]
                    vmag3 = values["vm"][3]  
                    vmag4 = values["vm"][4]
                    if vmag1 > 1.1 || vmag1 < 0.90 || vmag2 > 1.1 || vmag2 < 0.9 || vmag3 > 1.1 || vmag3 < 0.9
                        println("Voltage limit violated at bus $(key) at timestep $timestep for alpha = $alpha: V1 = $(vmag1), V2 = $(vmag2), V3 = $(vmag3)")
                    end
                end
                for (key, line_values) in res["solution"]["branch"]
                    lineloading = line_values["line_loading"]
                    if lineloading[1] > 1
                        println("Line loading limit violated at line $(key) for phase 1 at timestep $timestep for alpha = $alpha: Loading = $(lineloading[1])")
                    elseif lineloading[2] > 1
                        println("Line loading limit violated at line $(key) for phase 2 at timestep $timestep for alpha = $alpha: Loading = $(lineloading[2])")
                    elseif lineloading[3] > 1
                        println("Line loading limit violated at line $(key) for phase 3 at timestep $timestep for alpha = $alpha: Loading = $(lineloading[3])")
                    end
                end
            end
        end
    end
end

for Q_setpoint in [0, 1, 2]
    println("Starting analysis for Q_setpoint = $Q_setpoint")
    hosting_capacity_analysis!(math, load_profiles, PV_profile, alpha_range, max_timesteps, Q_setpoint, season)
end

hosting_capacity_analysis!(math, load_profiles, PV_profile, alpha_range, max_timesteps, 0, season)

visualization_same_bus_diff_alpha(Result_dict, season, "1", 32, [10.0, 20.0, 50.0, 55.0, 60.0, 80.0])
visualization_effect_of_Q_setpoint(Result_dict, season, 1, 60.0)
visualization_of_loads(Result_dict, season, "1", 10, 80.0)
visualization_of_Q_loads(Result_dict, season, "0", 10, 80.0)
visualization_of_line_loading(Result_dict, season, "53", 40)




function visualization_same_bus_diff_alpha(Result_dict, season, Q_set, bus, range)
    alphas = range
    p1 = nothing
    p2 = nothing
    p3 = nothing
    range = 300:400
    for alpha in alphas
        v1 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Busses"]["$(bus)"]["V1"][range]
        v2 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Busses"]["$(bus)"]["V2"][range]
        v3 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Busses"]["$(bus)"]["V3"][range]
        if alpha == alphas[1]
            p1 = plot(v1, label="Phase 1, Alpha=$(alpha)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Bus $(bus)", legend=:topright)
            p2 = plot(v2, label="Phase 2, Alpha=$(alpha)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Bus $(bus)", legend=:topright)
            p3 = plot(v3, label="Phase 3, Alpha=$(alpha)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Bus $(bus)", legend=:topright)
        else
            plot!(p1, v1, label="Phase 1, Alpha=$(alpha)")
            plot!(p2, v2, label="Phase 2, Alpha=$(alpha)")
            plot!(p3, v3, label="Phase 3, Alpha=$(alpha)")
        end
    end
    display(p1)
    display(p2)
    display(p3)
end

function visualization_effect_of_Q_setpoint(Result_dict, season, bus, alpha)
    Q_sets = ["0", "1", "2"]
    p1 = nothing
    p2 = nothing
    p3 = nothing
    range = 300:400
    for Q_set in Q_sets
        v1 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Busses"]["$(bus)"]["V1"][range]
        v2 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Busses"]["$(bus)"]["V2"][range]
        v3 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Busses"]["$(bus)"]["V3"][range]
        if Q_set == Q_sets[1]
            p1 = plot(v1, label="Phase 1, Q_set=$(Q_set)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Bus $(bus) for alpha $(alpha)", legend=:topright)
            p2 = plot(v2, label="Phase 2, Q_set=$(Q_set)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Bus $(bus) for alpha $(alpha)", legend=:topright)
            p3 = plot(v3, label="Phase 3, Q_set=$(Q_set)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Bus $(bus) for alpha $(alpha)", legend=:topright)
        else
            plot!(p1, v1, label="Phase 1, Q_set=$(Q_set)")
            plot!(p2, v2, label="Phase 2, Q_set=$(Q_set)")
            plot!(p3, v3, label="Phase 3, Q_set=$(Q_set)")
        end
    end
    display(p1)
    display(p2)
    display(p3)
end

function visualization_of_loads(Result_dict, season, Q_set, load, alpha)
    range = 300:400
    p1 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Loads"]["$(load)"]["P1"][range]
    p2 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Loads"]["$(load)"]["P2"][range]
    p3 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Loads"]["$(load)"]["P3"][range]
    pl1 = plot(p1, label="Phase 1", xlabel="Time step", ylabel="Active Power (pu)", title="Active Power at Load $(load) for alpha $(alpha)", legend=:topright)
    pl2 = plot(p2, label="Phase 2", xlabel="Time step", ylabel="Active Power (pu)", title="Active Power at Load $(load) for alpha $(alpha)", legend=:topright)
    pl3 = plot(p3, label="Phase 3", xlabel="Time step", ylabel="Active Power (pu)", title="Active Power at Load $(load) for alpha $(alpha)", legend=:topright)
    display(pl1)
    display(pl2)
    display(pl3)
end

function visualization_of_Q_loads(Result_dict, season, Q_set, load, alpha)
    range = 300:400
    p1 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Loads"]["$(load)"]["Q1"][range]
    p2 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Loads"]["$(load)"]["Q2"][range]
    p3 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Loads"]["$(load)"]["Q3"][range]
    pl1 = plot(p1, label="Phase 1", xlabel="Time step", ylabel="Reactive Power (pu)", title="Reactive Power at Load $(load) for alpha $(alpha)", legend=:topright)
    pl2 = plot(p2, label="Phase 2", xlabel="Time step", ylabel="Reactive Power (pu)", title="Reactive Power at Load $(load) for alpha $(alpha)", legend=:topright)
    pl3 = plot(p3, label="Phase 3", xlabel="Time step", ylabel="Reactive Power (pu)", title="Reactive Power at Load $(load) for alpha $(alpha)", legend=:topright)
    display(pl1)
    display(pl2)
    display(pl3)
end

function visualization_of_line_loading(Result_dict, season, line, alpha)
    pl = nothing
    p2 = nothing
    p3 = nothing
    range = 300:400
    for Q_set in ["0", "1", "2"]
        loading_1 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Branches"]["$(line)"]["line_loading_P1"][range]
        loading_2 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Branches"]["$(line)"]["line_loading_P2"][range]
        loading_3 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Branches"]["$(line)"]["line_loading_P3"][range]
        if Q_set == "0"
            pl = plot(loading_1, label="Line Loading P1, Q_set=$(Q_set)", xlabel="Time step", ylabel="Line Loading (%)", title="Line Loading at Line $(line) for alpha $(alpha)", legend=:topright)
            p2 = plot(loading_2, label="Line Loading P2, Q_set=$(Q_set)", xlabel="Time step", ylabel="Line Loading (%)", title="Line Loading at Line $(line) for alpha $(alpha)", legend=:topright)
            p3 = plot(loading_3, label="Line Loading P3, Q_set=$(Q_set)", xlabel="Time step", ylabel="Line Loading (%)", title="Line Loading at Line $(line) for alpha $(alpha)", legend=:topright)
        else
            plot!(pl, loading_1, label="Line Loading P1, Q_set=$(Q_set)")
            plot!(p2, loading_2, label="Line Loading P2, Q_set=$(Q_set)")
            plot!(p3, loading_3, label="Line Loading P3, Q_set=$(Q_set)")
        end
    end
    display(pl)
    display(p2)
    display(p3)
end



















#Extra: Visualization of a random PV and load profile
plot(PV_profile[21605:21705, "P_pv_3"], xlabel="15-min intervals in the day", ylabel="Active Power [kW]", title="PV production of house 33", legend=false)
plot(PV_profile[21605:21705, "P_pv_3"].*tan(acos(0.95)), xlabel="15-min intervals in the day", ylabel="Reactive Power [kVAr]", title="PV production of house 33", legend=false)
println("Max PV production of house 33: $(maximum(PV_profile[21605:21705, "P_pv_3"])) kW")
house = 25   #25 = house 33
tuples = load_profiles[21605:21705, "PLoad_$(house)"]
plot([t[1] for t in tuples], xlabel="15-min intervals in the day", ylabel="Active Power [kW]", title="Load profile of house $(good_buildings[house])", legend=false)
plot!([t[2] for t in tuples], xlabel="15-min intervals in the day", ylabel="Active Power [kW]", title="Load profile of house $(good_buildings[house])", legend=false)
plot!([t[3] for t in tuples], xlabel="15-min intervals in the day", ylabel="Active Power [kW]", title="Load profile of house $(good_buildings[house])", legend=false)

tuples_Q = load_profiles[21605:21705, "QLoad_$(house)"]
plot([t[1] for t in tuples_Q], xlabel="15-min intervals in the day", ylabel="Reactive Power [kVAr]", title="Load profile of house $(good_buildings[house])", legend=false)
plot!([t[2] for t in tuples_Q], xlabel="15-min intervals in the day", ylabel="Reactive Power [kVAr]", title="Load profile of house $(good_buildings[house])", legend=false)
plot!([t[3] for t in tuples_Q], xlabel="15-min intervals in the day", ylabel="Reactive Power [kVAr]", title="Load profile of house $(good_buildings[house])", legend=false)

println("Max Q load of house 33: $(maximum([t[3] for t in tuples_Q])) kVAr")