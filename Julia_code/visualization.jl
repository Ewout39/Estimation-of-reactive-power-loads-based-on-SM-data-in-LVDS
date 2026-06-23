"""
    Visualization

This file contains all functions related to plotting and visualizing the results of the Power flow analysis.

It includes functionality for:
- Visualizing the effect of different reactive power (Q) setpoints on the voltage profiles and line loading.
- Calculating the false positive and false negative rates of the voltage violations for different Q setpoints.

These functions are used in the hosting capacity analysis in
`Q_estimation_application.jl`.
"""
module Visualization

using Plots
using LaTeXStrings
using Colors
using DataFrames

export find_slack_line, calculation_of_errors, visualization_effect_of_Q, visualization_of_load, visualization_of_line_loading, annual_consumption_per_building, Q_values_per_load!, Q_values_total!, min_max_differences, topology_plot

"""
    calculation_of_errors(Result_dict, season, Z_value)

Calculates the false positive and false negative rates of the voltage violations for all Q setpoints, as well as the number of correctly identified false positives and false negatives by the other methods.
"""

function calculation_of_errors(Result_dict, season, Z_value; range = 1:672)
    false_positive_industry_v1 = 0
    false_negative_industry_v1 = 0
    false_positive_industry_v2 = 0
    false_negative_industry_v2 = 0
    false_positive_industry_v3 = 0
    false_negative_industry_v3 = 0
    method_correctly_identified_false_positive_v1 = 0
    method_correctly_identified_false_negative_v1 = 0
    method_correctly_identified_false_positive_v2 = 0
    method_correctly_identified_false_negative_v2 = 0
    method_correctly_identified_false_positive_v3 = 0
    method_correctly_identified_false_negative_v3 = 0
    False_positive_method_v1 = 0
    False_positive_method_v2 = 0
    False_positive_method_v3 = 0
    false_negative_method_v1 = 0
    false_negative_method_v2 = 0
    false_negative_method_v3 = 0
    industry_correctly_identified_false_positive_v1 = 0
    industry_correctly_identified_false_negative_v1 = 0
    industry_correctly_identified_false_positive_v2 = 0
    industry_correctly_identified_false_negative_v2 = 0
    industry_correctly_identified_false_positive_v3 = 0
    industry_correctly_identified_false_negative_v3 = 0

    for bus in 1:110
        for timestep in range
            v1_industry = Result_dict["0"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V1"][timestep]
            v2_industry = Result_dict["0"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V2"][timestep]
            v3_industry = Result_dict["0"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V3"][timestep]
            v1_real = Result_dict["2"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V1"][timestep]
            v2_real = Result_dict["2"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V2"][timestep]
            v3_real = Result_dict["2"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V3"][timestep]
            v1_method = Result_dict["1"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V1"][timestep]
            v2_method = Result_dict["1"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V2"][timestep]
            v3_method = Result_dict["1"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V3"][timestep]

            # The lines below test false positives and negatives for each Q_setpoint
            if (v1_industry < 0.9 || v1_industry > 1.1) && (v1_real >= 0.9 && v1_real <= 1.1)
                false_positive_industry_v1 += 1
                if (v1_method > 0.9 && v1_method < 1.1)
                    method_correctly_identified_false_positive_v1 += 1
                end
            elseif (v1_industry >= 0.9 && v1_industry <= 1.1) && (v1_real < 0.9 || v1_real > 1.1)
                false_negative_industry_v1 += 1
                if (v1_method < 0.9 || v1_method > 1.1)
                    method_correctly_identified_false_negative_v1 += 1
                end
            elseif (v1_method < 0.9 || v1_method > 1.1) && (v1_real >= 0.9 && v1_real <= 1.1)
                False_positive_method_v1 += 1
                if (v1_industry >= 0.9 && v1_industry <= 1.1)
                    industry_correctly_identified_false_positive_v1 += 1
                end
            elseif (v1_method >= 0.9 && v1_method <= 1.1) && (v1_real < 0.9 || v1_real > 1.1)
                false_negative_method_v1 += 1
                if (v1_industry < 0.9 || v1_industry > 1.1)
                    industry_correctly_identified_false_negative_v1 += 1
                end
            end

            if (v2_industry < 0.9 || v2_industry > 1.1) && (v2_real >= 0.9 && v2_real <= 1.1)
                false_positive_industry_v2 += 1
                if (v2_method > 0.9 && v2_method < 1.1)
                    method_correctly_identified_false_positive_v2 += 1
                end
            elseif (v2_industry >= 0.9 && v2_industry <= 1.1) && (v2_real < 0.9 || v2_real > 1.1)
                false_negative_industry_v2 += 1
                if (v2_method < 0.9 || v2_method > 1.1)
                    method_correctly_identified_false_negative_v2 += 1
                end
            elseif (v2_method < 0.9 || v2_method > 1.1) && (v2_real >= 0.9 && v2_real <= 1.1)
                False_positive_method_v2 += 1
                if (v2_industry >= 0.9 && v2_industry <= 1.1)
                    industry_correctly_identified_false_positive_v2 += 1
                end
            elseif (v2_method >= 0.9 && v2_method <= 1.1) && (v2_real < 0.9 || v2_real > 1.1)
                false_negative_method_v2 += 1
                if (v2_industry < 0.9 || v2_industry > 1.1)
                    industry_correctly_identified_false_negative_v2 += 1
                end
            end

            if (v3_industry < 0.9 || v3_industry > 1.1) && (v3_real >= 0.9 && v3_real <= 1.1)
                false_positive_industry_v3 += 1
                if (v3_method > 0.9 && v3_method < 1.1)
                    method_correctly_identified_false_positive_v3 += 1
                end
            elseif (v3_industry >= 0.9 && v3_industry <= 1.1) && (v3_real < 0.9 || v3_real > 1.1)
                false_negative_industry_v3 += 1
                if (v3_method < 0.9 || v3_method > 1.1)
                    method_correctly_identified_false_negative_v3 += 1
                end
            elseif (v3_method < 0.9 || v3_method > 1.1) && (v3_real >= 0.9 && v3_real <= 1.1)
                False_positive_method_v3 += 1
                if (v3_industry >= 0.9 && v3_industry <= 1.1)
                    industry_correctly_identified_false_positive_v3 += 1
                end
            elseif (v3_method >= 0.9 && v3_method <= 1.1) && (v3_real < 0.9 || v3_real > 1.1)
                false_negative_method_v3 += 1
                if (v3_industry < 0.9 || v3_industry > 1.1)
                    industry_correctly_identified_false_negative_v3 += 1
                end
            end
        end
    end

    println("False Positives Industry Phase 1: $(false_positive_industry_v1), Correctly identified by method: $(method_correctly_identified_false_positive_v1)")
    println("False Negatives Industry Phase 1: $(false_negative_industry_v1), Correctly identified by method: $(method_correctly_identified_false_negative_v1)")
    println("False Positives Industry Phase 2: $(false_positive_industry_v2), Correctly identified by method: $(method_correctly_identified_false_positive_v2)")
    println("False Negatives Industry Phase 2: $(false_negative_industry_v2), Correctly identified by method: $(method_correctly_identified_false_negative_v2)")
    println("False Positives Industry Phase 3: $(false_positive_industry_v3), Correctly identified by method: $(method_correctly_identified_false_positive_v3)")
    println("False Negatives Industry Phase 3: $(false_negative_industry_v3), Correctly identified by method: $(method_correctly_identified_false_negative_v3)")
    println("False Positives Method Phase 1: $(False_positive_method_v1), Correctly identified by industry: $(industry_correctly_identified_false_positive_v1)")
    println("False Negatives Method Phase 1: $(false_negative_method_v1), Correctly identified by industry: $(industry_correctly_identified_false_negative_v1)")
    println("False Positives Method Phase 2: $(False_positive_method_v2), Correctly identified by industry: $(industry_correctly_identified_false_positive_v2)")
    println("False Negatives Method Phase 2: $(false_negative_method_v2), Correctly identified by industry: $(industry_correctly_identified_false_negative_v2)")
    println("False Positives Method Phase 3: $(False_positive_method_v3), Correctly identified by industry: $(industry_correctly_identified_false_positive_v3)")
    println("False Negatives Method Phase 3: $(false_negative_method_v3), Correctly identified by industry: $(industry_correctly_identified_false_negative_v3)")
end

"""
    find_slack_line(math)

Finds the bus and line connected to the LV/MV transformer (slack bus).
"""

function find_slack_line(math)
    slack_bus = 0
    slack_line = 0
    for (key, bus) in math["bus"]
        if bus["bus_type"] == 3
            println("Slack bus found: $(key)")
            slack_bus = parse(Int64, key)
            break
        end
    end
    for (key, line) in math["branch"]
        if line["f_bus"] == slack_bus || line["t_bus"] == slack_bus
            println("Line connected to slack bus: $(key)")
            slack_line = key
            break
        end
    end
    return slack_line, slack_bus
end

"""
    visualization_effect_of_Q(Result_dict, season, Z_value, bus, area; range = 1:672)

Visualizes the effect of different reactive power (Q) setpoints on the voltage profiles.
"""

function visualization_effect_of_Q(Result_dict, season, Z_value, bus, area; range = 1:672)
    Q_sets = ["0", "1", "2"] #(0 = 0.95 power factor, 1 = custom power factor based on season and building type, 2 = use measured reactive power load from profiles)
    c_light = RGB(0.80, 0.80, 0.80)   # light gray
    c_mid   = RGB(0.50, 0.50, 0.50)   # medium gray
    c_dark  = RGB(0.20, 0.20, 0.20)   # dark gray
    p1 = nothing
    p2 = nothing
    p3 = nothing
    p1_sub = nothing
    p2_sub = nothing
    p3_sub = nothing

    filepath = joinpath(@__DIR__, "result_figure")
    filename_phase_1 = "Undervoltage_Violations_Bus_$(bus)_Area_$(area)_Phase_1_Z_$(Z_value).pdf"
    filename_phase_2 = "Undervoltage_Violations_Bus_$(bus)_Area_$(area)_Phase_2_Z_$(Z_value).pdf"
    filename_phase_3 = "Undervoltage_Violations_Bus_$(bus)_Area_$(area)_Phase_3_Z_$(Z_value).pdf"

    for Q_set in Q_sets
        v1 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V1"][range]
        v2 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V2"][range]
        v3 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V3"][range]

        if Q_set == Q_sets[1]
            p1 = plot(v1, color =c_light, label=L"PF~=~0.95", linestyle = :dot, linewidth = 2.0, xlabel=L"Time~step", ylabel=L"Voltage~Magnitude~(p.u.)", legend=:topright, legend_background_color=RGBA(1,1,1,0.85), legendfontsize = 20, guidefontsize =20, tickfontsize = 15, titlefontsize=20, yticks = ([0.92, 0.94, 0.96, 0.98], [L"0.92", L"0.94", L"0.96", L"0.98"]), xticks = ([0, 96, 192, 288, 384, 480, 576], [L"0", L"24h", L"48h", L"72h", L"96h", L"120h", L"144h"]))
            p2 = plot(v2, color =c_light, label=L"PF~=~0.95", linestyle = :dot, linewidth = 2.0, xlabel=L"Time~step", ylabel=L"Voltage~Magnitude~(p.u.)", legend_background_color=RGBA(1,1,1,0.85), legend=:topright, legendfontsize = 20, guidefontsize =20, tickfontsize = 15, titlefontsize=20, yticks = ([0.9, 0.92, 0.94, 0.96, 0.98], [L"0.9", L"0.92", L"0.94", L"0.96", L"0.98"]), xticks = ([0, 96, 192, 288, 384, 480, 576], [L"0", L"24h", L"48h", L"72h", L"96h", L"120h", L"144h"]))
            p3 = plot(v3, color =c_light, label=L"PF~=~0.95", linestyle = :dot, linewidth = 2.0, xlabel=L"Time~step", ylabel=L"Voltage~Magnitude~(p.u.)", legend_background_color=RGBA(1,1,1,0.85), legend=:topright, legendfontsize = 20, guidefontsize =20, tickfontsize = 15, titlefontsize=20, yticks=([0.95, 0.96, 0.97, 0.98, 0.99], [L"0.95", L"0.96", L"0.97", L"0.98", L"0.99"]), xticks = ([0, 96, 192, 288, 384, 480, 576], [L"0", L"24h", L"48h", L"72h", L"96h", L"120h", L"144h"]))
            violation_indicator_1 = [v < 0.9 ? 1 : 0 for v in v1]
            violation_indicator_2 = [v < 0.9 ? 1 : 0 for v in v2]
            violation_indicator_3 = [v < 0.9 ? 1 : 0 for v in v3]
            p1_sub = plot(violation_indicator_1, color=:red, fillto=0, fillcolor=:red, alpha=0.7, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1, tickfontsize = 15, xticks = ([0, 96, 192, 288, 384, 480, 576], [L"0", L"24h", L"48h", L"72h", L"96h", L"120h", L"144h"]))
            p2_sub = plot(violation_indicator_2, color=:red, fillto=0, fillcolor=:red, alpha=0.7, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1, tickfontsize = 15, xticks = ([0, 96, 192, 288, 384, 480, 576], [L"0", L"24h", L"48h", L"72h", L"96h", L"120h", L"144h"]))
            p3_sub = plot(violation_indicator_3, color=:red, fillto=0, fillcolor=:red, alpha=0.7, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1, tickfontsize = 15, xticks = ([0, 96, 192, 288, 384, 480, 576], [L"0", L"24h", L"48h", L"72h", L"96h", L"120h", L"144h"]))
        elseif Q_set == Q_sets[3]
            act_vio_ind_1 = [v < 0.9 ? 1 : 0 for v in v1]
            act_vio_ind_2 = [v < 0.9 ? 1 : 0 for v in v2]
            act_vio_ind_3 = [v < 0.9 ? 1 : 0 for v in v3]
            plot!(p1_sub, act_vio_ind_1, color=:green, fillto=0, fillcolor=:green, alpha=0.7, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1, tickfontsize = 15)
            plot!(p2_sub, act_vio_ind_2, color=:green, fillto=0, fillcolor=:green, alpha=0.7, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1, tickfontsize = 15)
            plot!(p3_sub, act_vio_ind_3, color=:green, fillto=0, fillcolor=:green, alpha=0.7, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1, tickfontsize = 15)
            plot!(p1, v1, color =c_dark, linestyle = :dash,  label=L"Ground~truth", legendfontsize = 20, guidefontsize = 20, tickfontsize = 15)
            plot!(p2, v2, color =c_dark, linestyle = :dash,  label=L"Ground~truth", legendfontsize = 20, guidefontsize = 20, tickfontsize = 15)
            plot!(p3, v3, color =c_dark, linestyle = :dash,  label=L"Ground~truth", legendfontsize = 20, guidefontsize = 20, tickfontsize = 15)
        else
            plot!(p1, v1, color=c_mid, linestyle = :solid, linewidth=2, label=L"Best~method", legendfontsize = 20, guidefontsize = 20, tickfontsize = 15)
            plot!(p2, v2, color=c_mid, linestyle = :solid, linewidth=2, label=L"Best~method", legendfontsize = 20, guidefontsize = 20, tickfontsize = 15)
            plot!(p3, v3, color=c_mid, linestyle = :solid, linewidth=2, label=L"Best~method", legendfontsize = 20, guidefontsize = 20, tickfontsize = 15)
        end
    end

    # Add a red line at 0.9 p.u. if any of the methods show undervoltage violations, to make it easier to see where the violations are.
    for Q_set in Q_sets
        v1 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V1"][range]
        v2 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V2"][range]
        v3 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V3"][range]
        if !all(v1 .> 0.9)
            hline!(p1, [0.9], color=:red, label="")
        end
        if !all(v2 .> 0.9)
            hline!(p2, [0.9], color=:red, label="")
        end
        if !all(v3 .> 0.9)
            hline!(p3, [0.9], color=:red, label="")
        end
    end

    # Combine the main and subplots for each phase, and save the figures
    combined_plot_1 = plot(p1, p1_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    combined_plot_2 = plot(p2, p2_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    combined_plot_3 = plot(p3, p3_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    display(combined_plot_1)
    display(combined_plot_2)
    display(combined_plot_3)
    savefig(combined_plot_1, filepath * filename_phase_1)
    savefig(combined_plot_2, filepath * filename_phase_2)
    savefig(combined_plot_3, filepath * filename_phase_3)
end

"""
    visualization_of_load(Result_dict, season, Q_set, load, Z_value, math; range = 1:672)

Visualizes the active and reactive power at a specific load for a given Q setpoint.
"""

function visualization_of_load(Result_dict, season, Q_set, load, Z_value, math; range = 1:672)
    p1 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Loads"]["$(load)"]["Q$(math["load"]["$(load)"]["phase_connections"])"][range].*math["settings"]["sbase"]
    p2 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Loads"]["$(load)"]["P$(math["load"]["$(load)"]["phase_connections"])"][range].*math["settings"]["sbase"]
    pl1 = plot(p1, label="Phase $(math["load"]["$(load)"]["phase_connections"])", xlabel="Time step", ylabel="Reactive Power (kVAr)", title="Reactive Power at Load $(load)", legend=:topright)
    pl2 = plot(p2, label="Phase $(math["load"]["$(load)"]["phase_connections"])", xlabel="Time step", ylabel="Active Power (kW)", title="Active Power at Load $(load)", legend=:topright)
    display(pl1)
    display(pl2)
end

"""
    visualization_of_line_loading(Result_dict, season, line, Z_value; range= 1:672)

Visualizes the line loading for a specific line across different Q setpoints.
"""

function visualization_of_line_loading(Result_dict, season, line, Z_value; range= 1:672)
    Q_sets = ["0", "1", "2"]
    pl = nothing
    p2 = nothing
    p3 = nothing
    p1_sub = nothing
    c_light = RGB(0.80, 0.80, 0.80)   # light gray
    c_mid   = RGB(0.50, 0.50, 0.50)   # medium gray
    c_dark  = RGB(0.20, 0.20, 0.20)   # dark gray

    for Q_set in Q_sets
        loading_1 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Branches"]["$(line)"]["line_loading_P1"][range]
        loading_2 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Branches"]["$(line)"]["line_loading_P2"][range]
        loading_3 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Branches"]["$(line)"]["line_loading_P3"][range]
        if Q_set == Q_sets[1]
            pl = plot(loading_1, color=c_light, label=L"PF~=~0.95", linestyle = :dot, linewidth = 2.0, xlabel="Time step", ylabel="Line Loading (%)", title="Line Loading at Line $(line)", legendfontsize = 20, guidefontsize =20, tickfontsize = 15, titlefontsize=20, legend=:topright)
            p2 = plot(loading_2, color=c_light, label=L"PF~=~0.95", linestyle = :dot, linewidth = 2.0, xlabel="Time step", ylabel="Line Loading (%)", title="Line Loading at Line $(line)", legendfontsize = 20, guidefontsize =20, tickfontsize = 15, titlefontsize=20, legend=:topright)
            p3 = plot(loading_3, color=c_light, label=L"PF~=~0.95", linestyle = :dot, linewidth = 2.0, xlabel="Time step", ylabel="Line Loading (%)", title="Line Loading at Line $(line)", legendfontsize = 20, guidefontsize =20, tickfontsize = 15, titlefontsize=20, legend=:topright)
            violation_indicator_P1 = [ll > 1 ? 1 : 0 for ll in loading_1]
            violation_indicator_P2 = [ll > 1 ? 1 : 0 for ll in loading_2]
            violation_indicator_P3 = [ll > 1 ? 1 : 0 for ll in loading_3]
            p1_sub = plot(violation_indicator_P1, color=:red, fillto=0, fillcolor=:red, alpha=0.3, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1)
            p2_sub = plot(violation_indicator_P2, color=:red, fillto=0, fillcolor=:red, alpha=0.3, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1)
            p3_sub = plot(violation_indicator_P3, color=:red, fillto=0, fillcolor=:red, alpha=0.3, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1)
        elseif Q_set == Q_sets[3]
            plot!(pl, loading_1, linestyle = :dash,  label=L"Ground~truth", color=c_dark, legendfontsize = 20, guidefontsize = 20, tickfontsize = 15)
            plot!(p2, loading_2, linestyle = :dash,  label=L"Ground~truth", color=c_dark, legendfontsize = 20, guidefontsize = 20, tickfontsize = 15)
            plot!(p3, loading_3, linestyle = :dash,  label=L"Ground~truth", color=c_dark, legendfontsize = 20, guidefontsize = 20, tickfontsize = 15)
            violation_indicator_P1 = [ll > 1 ? 1 : 0 for ll in loading_1]
            violation_indicator_P2 = [ll > 1 ? 1 : 0 for ll in loading_2]
            violation_indicator_P3 = [ll > 1 ? 1 : 0 for ll in loading_3]
            p1_sub = plot(violation_indicator_P1, color=:green, fillto=0, fillcolor=:green, alpha=0.7, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1)
            p2_sub = plot(violation_indicator_P2, color=:green, fillto=0, fillcolor=:green, alpha=0.7, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1)
            p3_sub = plot(violation_indicator_P3, color=:green, fillto=0, fillcolor=:green, alpha=0.7, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1)
        else
            plot!(pl, loading_1, linestyle = :solid, linewidth=2, label=L"Best~method", color=c_mid, legendfontsize = 20, guidefontsize = 20, tickfontsize = 15)
            plot!(p2, loading_2, linestyle = :solid, linewidth=2, label=L"Best~method", color=c_mid, legendfontsize = 20, guidefontsize = 20, tickfontsize = 15)
            plot!(p3, loading_3, linestyle = :solid, linewidth=2, label=L"Best~method", color=c_mid, legendfontsize = 20, guidefontsize = 20, tickfontsize = 15)
        end
    end
    hline!(pl, [1], color=:red, label="")
    hline!(p2, [1], color=:red, label="")
    hline!(p3, [1], color=:red, label="")
    combined_plot_p1 = plot(pl, p1_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    combined_plot_p2 = plot(p2, p2_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    combined_plot_p3 = plot(p3, p3_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    display(combined_plot_p1)
    display(combined_plot_p2)
    display(combined_plot_p3)
end

"""
    min_max_differences2(Result_dict, season, bus, Z_value, math, slack_bus; range = 1:672)

Calculates the maximum and minimum differences between the voltage profiles obtained from the method, and industry standard with the ground truth.
"""

function min_max_differences(Result_dict, season, bus, Z_value, math, slack_bus; range = 1:672)
    V_base = math["settings"]["vbases_default"]["$(slack_bus)"] #given in kV
    voltage_scale_factor = math["settings"]["voltage_scale_factor"] #To convert the voltage from kV to V
    v1_truth = Result_dict["2"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V1"][range]
    v2_truth = Result_dict["2"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V2"][range]
    v3_truth = Result_dict["2"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V3"][range]
    v1_method = Result_dict["1"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V1"][range]
    v2_method = Result_dict["1"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V2"][range]
    v3_method = Result_dict["1"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V3"][range]
    v1_industry = Result_dict["0"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V1"][range]
    v2_industry = Result_dict["0"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V2"][range]
    v3_industry = Result_dict["0"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V3"][range]
    max_diff_method = maximum(abs.(v1_truth .- v1_method))*V_base*voltage_scale_factor
    min_diff_method = minimum(abs.(v1_truth .- v1_method))*V_base*voltage_scale_factor
    max_diff_industry = maximum(abs.(v1_truth .- v1_industry))*V_base*voltage_scale_factor
    min_diff_industry = minimum(abs.(v1_truth .- v1_industry))*V_base*voltage_scale_factor
    println("Max difference Phase 1 Method: $(max_diff_method), Min difference Phase 1 Method: $(min_diff_method)")
    println("Max difference Phase 1 Industry: $(max_diff_industry), Min difference Phase 1 Industry: $(min_diff_industry)")
    max_diff_method = maximum(abs.(v2_truth .- v2_method))*V_base*voltage_scale_factor
    min_diff_method = minimum(abs.(v2_truth .- v2_method))*V_base*voltage_scale_factor
    max_diff_industry = maximum(abs.(v2_truth .- v2_industry))*V_base*voltage_scale_factor
    min_diff_industry = minimum(abs.(v2_truth .- v2_industry))*V_base*voltage_scale_factor
    println("Max difference Phase 2 Method: $(max_diff_method), Min difference Phase 2 Method: $(min_diff_method)")
    println("Max difference Phase 2 Industry: $(max_diff_industry), Min difference Phase 2 Industry: $(min_diff_industry)")
    max_diff_method = maximum(abs.(v3_truth .- v3_method))*V_base*voltage_scale_factor
    min_diff_method = minimum(abs.(v3_truth .- v3_method))*V_base*voltage_scale_factor
    max_diff_industry = maximum(abs.(v3_truth .- v3_industry))*V_base*voltage_scale_factor
    min_diff_industry = minimum(abs.(v3_truth .- v3_industry))*V_base*voltage_scale_factor
    println("Max difference Phase 3 Method: $(max_diff_method), Min difference Phase 3 Method: $(min_diff_method)")
    println("Max difference Phase 3 Industry: $(max_diff_industry), Min difference Phase 3 Industry: $(min_diff_industry)")
end

function topology_plot(math)
    topology = powerplot(math, width=800, height = 600, bus=(:size=>100, :color=>:gray), load=(:size=>200, :color=>:black), branch=(:color=>:gray), gen=(:size=>300, :color=>:darkred))

    filepath =  @__DIR__
    save(joinpath(filepath, "network_topology.pdf"), topology)
end

end # module Visualization