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
using LaTeXStrings
using Colors

include("network_functions.jl")
using .NetworkFunctions
include("load_data.jl")
using .Load_Data
include("visualization.jl")
using .Visualization
include("power_flow_analysis.jl")
using .Power_Flow_Analysis

#Loading in the data 
good_buildings, load_profiles = extract_loading_usa!()

#Loading and transforming the network
eng = _PMD.parse_file("Master_oh.dss", data_model = _PMD.ENGINEERING, transformations=[_PMD.transform_loops!,_PMD.remove_all_bounds!])
rm_transformer!(eng)
reduce_lines_eng!(eng)
eng["settings"]["sbase_default"] = 10000
math = _PMD.transform_data_model(eng, kron_reduce=false, phase_project=false)
clean_4w_data!(math, load_profiles, eng=eng, good_buildings=good_buildings, merge_buses_diff_linecodes = false)
add_linecode_math!(math, eng)
topology_plot(math)

#Power flow analysis
max_idx, monthly_consumptions = calculating_month_with_highest_average_consumption_per_building(load_profiles, good_buildings)
Result_dict1 = initialize_empty_dict!()
season = "Summer"
rep_month_start, rep_month_end, rep_month = network_rep_month(season, load_profiles, good_buildings)
most_loaded_week = 2209:2880 #Selects the fourth week of August
EV_power_mult = 5.0
Z_mult = 1.5
load_mult = 3
Nr_EVs = 15

EV_load_list = select_EV_loads(math, Nr_EVs)

for Q_setpoint in [0, 1, 2]
        math2 = deepcopy(math)
        for (key, branch) in math2["branch"]
            br_r = branch["br_r"]
            br_x = branch["br_x"]
            math2["branch"][key]["br_r"] = br_r .*Z_mult.*sqrt(3)
            math2["branch"][key]["br_x"] = br_x .*Z_mult./sqrt(3)
        end
        hosting_capacity_analysis!(math2, load_profiles, load_mult, EV_load_list, rep_month_start, rep_month_end, most_loaded_week, Q_setpoint, season, "Z", Z_mult, EV_power_mult)
end

#Visualization of the results
slack_line, slack_bus = find_slack_line(math)
calculation_of_errors(Result_dict1, season, string(Z_mult))
visualization_effect_of_Q1(Result_dict1, season, string(Z_mult), 100, 3) # Area 1 = bus 66, Area 2 = bus 56, Area 3 = bus 100
visualization_of_load(Result_dict1, season, "0", 26, string(Z_mult), math)
visualization_of_line_loading(Result_dict1, season, string(slack_line), string(Z_mult))
min_max_differences(Result_dict1, season, 100, string(Z_mult), math, slack_bus)