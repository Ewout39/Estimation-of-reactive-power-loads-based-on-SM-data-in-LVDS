import PowerModelsDistribution as _PMD
import DataFrames as _DF
using PowerPlots
using JuMP
using HDF5
using Plots
using Ipopt
using CSV
using Random
using Statistics
using LinearAlgebra
include("network_functions.jl")
include("load_data.jl")
include("Visualization.jl")

#Loading in the data 
good_buildings, load_profiles, PV_profile, PV_profile_Q = extract_loading_usa!()

#Loading and transforming the network
eng = _PMD.parse_file("Master_oh.dss", data_model = _PMD.ENGINEERING, transformations=[_PMD.transform_loops!,_PMD.remove_all_bounds!])
rm_transformer!(eng)
reduce_enwl_lines_eng!(eng)
eng["settings"]["sbase_default"] = 100000
math1 = _PMD.transform_data_model(eng, kron_reduce=false, phase_project=false)
math = remove_excess_loads(math1, good_buildings)
clean_4w_data!(math, load_profiles, eng=eng, good_buildings=good_buildings, merge_buses_diff_linecodes = false)
add_PV_index!(math)
add_linecode_math!(math, eng)
powerplot(math, width=1000, height = 1000, bus=(:size=>200))

#Hosting Capacity analysis (for different Q setpoints)
alpha_range = [1, 70, 72, 74, 76, 78]
season = "Winter"
rep_month_start, rep_month_end, rep_month = network_rep_month(season, load_profiles, good_buildings)
power_mult = 1.0
Result_dict = initialize_empty_dict!()
function hosting_capacity_analysis!(math, load_profiles, PV_profile, alpha_range,  rep_month_start::Int64, rep_month_end::Int64, Q_setpoint::Int64=2, season::String="Summer", Q_Z::String="Q", Z_value::Float64=1.0, power_mult::Float64=1.0)
    timesteps_range = rep_month_start:rep_month_end
    for alpha in alpha_range
        new_alpha_v = 1
        new_alpha_ll = 1
        println("Starting analysis for alpha = $alpha, Q_setpoint = $Q_setpoint and Z_value = $Z_value")
        _PMD.add_start_vrvi!(math)
        for timestep in timesteps_range
            insert_P_profiles!(math, load_profiles, PV_profile, timestep, alpha, power_mult)
            insert_Q_profiles_usa!(math, load_profiles, timestep, Q_setpoint, PV_profile_Q, PV_profile, season, alpha, power_mult)
            res = _PMD.solve_mc_opf(math, _PMD.IVRENPowerModel, optimizer_with_attributes(Ipopt.Optimizer, "max_iter" => 2000, "print_level" => 0))
            pf_solution_to_line_loading!(res, math)
            if res["termination_status"] == _PMD.OTHER_ERROR
                _PMD.add_start_vrvi!(math)
                res = _PMD.solve_mc_opf(math, _PMD.IVRENPowerModel, optimizer_with_attributes(Ipopt.Optimizer, "max_iter" => 2000, "print_level" => 0))
                pf_solution_to_line_loading!(res, math)
            end
            if res["termination_status"] != _PMD.LOCALLY_SOLVED && res["termination_status"] != _PMD.ALMOST_LOCALLY_SOLVED
                println(res["termination_status"])
                bus_numbers = [parse(Int, bus) for (bus, _) in res["solution"]["bus"]]
                vm1 = [sqrt(res["solution"]["bus"][string(bus)]["vr"][1]^2 + res["solution"]["bus"][string(bus)]["vi"][1]^2) for (bus, _) in res["solution"]["bus"]]
                vm2 = [sqrt(res["solution"]["bus"][string(bus)]["vr"][2]^2 + res["solution"]["bus"][string(bus)]["vi"][2]^2) for (bus, _) in res["solution"]["bus"]]
                vm3 = [sqrt(res["solution"]["bus"][string(bus)]["vr"][3]^2 + res["solution"]["bus"][string(bus)]["vi"][3]^2) for (bus, _) in res["solution"]["bus"]]
                p1 = scatter(bus_numbers, vm1,xlabel="Bus Number", ylabel="Voltage (pu)", title="Phase 1 voltage Profiles", legend=:topright, legend_background_color=RGBA(1,1,1,0.5))
                p2 = scatter(bus_numbers, vm2,xlabel="Bus Number", ylabel="Voltage (pu)", title="Phase 2 voltage Profiles", legend=:topright, legend_background_color=RGBA(1,1,1,0.5))
                p3 = scatter(bus_numbers, vm3,xlabel="Bus Number", ylabel="Voltage (pu)", title="Phase 3 voltage Profiles", legend=:topright, legend_background_color=RGBA(1,1,1,0.5))
                display(p1)
                display(p2)
                display(p3)
                @warn "Power flow did not converge at timestep $timestep for alpha = $alpha"
                #visualization_load_profiles(load_profiles, PV_profile, timestep, timesteps_range, good_buildings)
                return
            else
                if timestep != timesteps_range[1]
                    add_initial_values!(math, res)
                end
                if Q_Z == "Q"
                    add_to_dict!(Result_dict, res, Q_setpoint, alpha, Z_value, Q_Z, season, math)
                else
                    add_to_dict!(Result_dict1, res, Q_setpoint, alpha, Z_value, Q_Z, season, math)
                end
                if new_alpha_v == 1 
                    for (key, values) in res["solution"]["bus"]
                        vmag1 = sqrt(values["vr"][1]^2 + values["vi"][1]^2)
                        vmag2 = sqrt(values["vr"][2]^2 + values["vi"][2]^2)
                        vmag3 = sqrt(values["vr"][3]^2 + values["vi"][3]^2)
                        vmag4 = sqrt(values["vr"][4]^2 + values["vi"][4]^2)
                        if vmag1 > 1.1 || vmag1 < 0.90 || vmag2 > 1.1 || vmag2 < 0.9 || vmag3 > 1.1 || vmag3 < 0.9 || vmag4 > 0.1
                            println("Voltage limit violated at bus $(key) at timestep $timestep for alpha = $alpha: V1 = $(vmag1), V2 = $(vmag2), V3 = $(vmag3), V4 = $(vmag4)")
                            new_alpha_v = 0
                        end
                    end
                end
                if new_alpha_ll == 1
                    for (key, line_values) in res["solution"]["branch"]
                        lineloading = line_values["line_loading"]
                        if lineloading[1] > 1
                            println("Line loading limit violated at line $(key) for phase 1 at timestep $timestep for alpha = $alpha: Loading = $(lineloading[1])")
                            new_alpha_ll = 0
                        elseif lineloading[2] > 1
                            println("Line loading limit violated at line $(key) for phase 2 at timestep $timestep for alpha = $alpha: Loading = $(lineloading[2])")
                            new_alpha_ll = 0
                        elseif lineloading[3] > 1
                            println("Line loading limit violated at line $(key) for phase 3 at timestep $timestep for alpha = $alpha: Loading = $(lineloading[3])")
                            new_alpha_ll = 0
                        end
                    end
                end
            end
        end
    end
end

for Q_setpoint in [0, 1, 2]
    println("Starting analysis for Q_setpoint = $Q_setpoint")
    hosting_capacity_analysis!(math, load_profiles, PV_profile, alpha_range, rep_month_start, rep_month_end, Q_setpoint, season, "Q", 1.0, power_mult)
end

#Hosting capacity analysis for different Z values
Result_dict1 = initialize_empty_dict!()
Result_dict2 = initialize_empty_dict!()
season = "Autumn"
rep_month_start, rep_month_end, rep_month = network_rep_month(season, load_profiles, good_buildings)
power_mult = 1.0
Z_range = [1.4] #R = 1.4, X = 1 works, alpha = 50 for summer, 60 for winter, 60 for spring

for Q_setpoint in [0, 1, 2]
    for Z_value in Z_range
        math2 = deepcopy(math)
        for (key, branch) in math2["branch"]
            br_r = branch["br_r"]
            br_x = branch["br_x"]
            math2["branch"][key]["br_r"] = br_r .*Z_value
            math2["branch"][key]["br_x"] = br_x 
        end
        hosting_capacity_analysis!(math2, load_profiles, PV_profile, [60], rep_month_start, rep_month_end, Q_setpoint, season, "Z", Z_value, power_mult)
    end
end

#Temporary code for debugging
timestamp_test = 20499
_PMD.add_start_vrvi!(math)
insert_P_profiles!(math, load_profiles, PV_profile, timestamp_test, 77, power_mult)
insert_Q_profiles_usa!(math, load_profiles, timestamp_test, 1, PV_profile_Q, PV_profile, season, 77, power_mult)
res = _PMD.solve_mc_opf(math, _PMD.IVRENPowerModel, optimizer_with_attributes(Ipopt.Optimizer, "max_iter" => 800))

hosting_capacity_analysis!(math, load_profiles, PV_profile, [72], rep_month_start, rep_month_end, 2, season, "Q", 1.0, power_mult)

#Visualization of the results
visualization_same_bus_diff_alpha(Result_dict, season, "1", 11, alpha_range)
visualization_effect_of_Q_setpoint(Result_dict, season, 11, 78)
visualization_of_bus_voltages(Result_dict, season, 76, "1")
visualization_of_loads(Result_dict, season, "1", 18, 70, math)  #requires the load key from math (not the parquet_id or the original load index)
visualization_of_Q_loads(Result_dict, season, "1", 18, 70, math)
slack_line, slack_bus = find_slack_line(math)
visualization_of_line_loading(Result_dict, season, string(slack_line), 76)

Season = "Autumn"
visualization_effect_Z_line(Result_dict1, Season, string(slack_line), "2", Z_range)
visualization_effect_of_Z_voltage(Result_dict1, Season, 11, "0", Z_range)
visualization_effect_of_Q_Z(Result_dict1, Season, "1.4", 11, "60")
visualization_of_loads_Z(Result_dict1, Season, "1", 24, 54, 1.4, math)
visualization_of_Q_loads_Z(Result_dict1, Season, "0", 26, 54, 1.4, math)
visualization_of_line_loading_Z(Result_dict1, Season, string(slack_line), 60, 1.4)


PV_winter = PV_profile[2997:5665,:P_pv_3]
PV_summer = PV_profile[20353:23621,:P_pv_3]

plot(PV_winter, label="Winter PV Profile", xlabel="Time step", ylabel="PV Power (kW)", title="PV Power Profile Winter")
plot(PV_summer, label="Summer PV Profile", xlabel="Time step", ylabel="PV Power (kW)", title="PV Power Profile Summer")