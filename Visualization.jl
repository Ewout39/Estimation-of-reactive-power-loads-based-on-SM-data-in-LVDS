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
    p1_sub = nothing
    range = 480:580
    for Q_set in Q_sets
        v1 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Busses"]["$(bus)"]["V1"][range]
        v2 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Busses"]["$(bus)"]["V2"][range]
        v3 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Busses"]["$(bus)"]["V3"][range]
        if Q_set == Q_sets[1]
            p1 = plot(v1, label="Phase 1, Q_set=$(Q_set)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Bus $(bus) for alpha $(alpha)", legend=:topright)
            p2 = plot(v2, label="Phase 2, Q_set=$(Q_set)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Bus $(bus) for alpha $(alpha)", legend=:topright)
            p3 = plot(v3, label="Phase 3, Q_set=$(Q_set)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Bus $(bus) for alpha $(alpha)", legend=:topright)
            violation_indicator = [v > 1.1 ? 1 : 0 for v in v1]
            p1_sub = plot(violation_indicator, color=:red, fillto=0, fillcolor=:red, alpha=0.3, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1)
        else
            plot!(p1, v1, label="Phase 1, Q_set=$(Q_set)")
            plot!(p2, v2, label="Phase 2, Q_set=$(Q_set)")
            plot!(p3, v3, label="Phase 3, Q_set=$(Q_set)")
        end
    end
    hline!(p1, [1.1], color=:red, label="")
    combined_plot = plot(p1, p1_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    display(combined_plot)
    display(p2)
    display(p3)
end

function visualization_of_bus_voltages(Result_dict, season, alpha, Q_set)
    p1 = nothing
    p2 = nothing
    p3 = nothing
    p4 = nothing
    range = 1:length(Result_dict[Q_set][season]["Alpha=$(alpha)"]["Busses"]["1"]["V1"])
    for bus in keys(Result_dict[Q_set][season]["Alpha=$(alpha)"]["Busses"])
        color = bus == "54" ? :black : :auto
        v1 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Busses"]["$(bus)"]["V1"][range]
        v2 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Busses"]["$(bus)"]["V2"][range]
        v3 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Busses"]["$(bus)"]["V3"][range]
        v4 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Busses"]["$(bus)"]["V4"][range]
        if bus == collect(keys(Result_dict[Q_set][season]["Alpha=$(alpha)"]["Busses"]))[1]
            p1 = plot(v1, label="Bus=$(bus)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Buses for alpha $(alpha) and Q_set=$(Q_set) on phase 1", legend=:topright, legend_background_color=RGBA(1,1,1,0.5), color=color)
            p2 = plot(v2, label="Bus=$(bus)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Buses for alpha $(alpha) and Q_set=$(Q_set) on phase 2", legend=:topright, legend_background_color=RGBA(1,1,1,0.5), color=color)
            p3 = plot(v3, label="Bus=$(bus)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Buses for alpha $(alpha) and Q_set=$(Q_set) on phase 3", legend=:topright, legend_background_color=RGBA(1,1,1,0.5), color=color)
            p4 = plot(v4, label="Bus=$(bus)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Buses for alpha $(alpha) and Q_set=$(Q_set) on phase 4", legend=:topright, legend_background_color=RGBA(1,1,1,0.5), color=color)
        else
            plot!(p1, v1, label="Bus=$(bus)", legend_background_color=RGBA(1,1,1,0.5), color=color)
            plot!(p2, v2, label="Bus=$(bus)", legend_background_color=RGBA(1,1,1,0.5), color=color)
            plot!(p3, v3, label="Bus=$(bus)", legend_background_color=RGBA(1,1,1,0.5), color=color)
            plot!(p4, v4, label="Bus=$(bus)", legend_background_color=RGBA(1,1,1,0.5), color=color)
        end
    end
    display(p1)
    display(p2)
    display(p3)
    display(p4)
end

function visualization_of_loads(Result_dict, season, Q_set, load, alpha, math)
    #range = 1:length(Result_dict[Q_set][season]["Alpha=$(alpha)"]["Loads"]["$(load)"]["P1"])
    range = 1:672
    p1 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Loads"]["$(load)"]["P$(math["load"]["$(load)"]["phase_connections"])"][range].*math["settings"]["sbase"]
    pl1 = plot(p1, label="Phase $(math["load"]["$(load)"]["phase_connections"])", xlabel="Time step", ylabel="Active Power (kW)", title="Active Power at Load $(load) for alpha $(alpha)", legend=:topright)
    display(pl1)
end

function visualization_of_Q_loads(Result_dict, season, Q_set, load, alpha, math)
    range = 1:672
    p1 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Loads"]["$(load)"]["Q$(math["load"]["$(load)"]["phase_connections"])"][range].*math["settings"]["sbase"]
    pl1 = plot(p1, label="Phase $(math["load"]["$(load)"]["phase_connections"])", xlabel="Time step", ylabel="Reactive Power (kVAr)", title="Reactive Power at Load $(load) for alpha $(alpha)", legend=:topright)
    display(pl1)
end

function visualization_of_line_loading(Result_dict, season, line, alpha)
    pl = nothing
    p2 = nothing
    p3 = nothing
    p1_sub = nothing
    range = 300:400
    for Q_set in ["0", "1", "2"]
        loading_1 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Branches"]["$(line)"]["line_loading_P1"][range]
        loading_2 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Branches"]["$(line)"]["line_loading_P2"][range]
        loading_3 = Result_dict[Q_set][season]["Alpha=$(alpha)"]["Branches"]["$(line)"]["line_loading_P3"][range]
        if Q_set == "0"
            pl = plot(loading_1, label="Line Loading P1, Q_set=$(Q_set)", xlabel="Time step", ylabel="Line Loading (%)", title="Line Loading at Line $(line) for alpha $(alpha)", legend=:topright)
            p2 = plot(loading_2, label="Line Loading P2, Q_set=$(Q_set)", xlabel="Time step", ylabel="Line Loading (%)", title="Line Loading at Line $(line) for alpha $(alpha)", legend=:topright)
            p3 = plot(loading_3, label="Line Loading P3, Q_set=$(Q_set)", xlabel="Time step", ylabel="Line Loading (%)", title="Line Loading at Line $(line) for alpha $(alpha)", legend=:topright)
            violation_indicator = [v > 1 ? 1 : 0 for v in loading_1]
            p1_sub = plot(violation_indicator, color=:red, fillto=0, fillcolor=:red, alpha=0.3, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1)
        else
            plot!(pl, loading_1, label="Line Loading P1, Q_set=$(Q_set)")
            plot!(p2, loading_2, label="Line Loading P2, Q_set=$(Q_set)")
            plot!(p3, loading_3, label="Line Loading P3, Q_set=$(Q_set)")
        end
    end
    hline!(pl, [1], color=:red, label="")
    combined_plot = plot(pl, p1_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    display(combined_plot)
    display(p2)
    display(p3)
end

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

function visualization_load_profiles(load_profiles, PV_profile, timestamp, timestep_range, good_buildings)
    total_P = [0.0, 0.0, 0.0]
    total_Q = [0.0, 0.0, 0.0]
    timestamp_range = timestep_range[1]:timestamp
    total_PV = PV_profile[timestamp, "P_pv_3"]
    for i in 1:length(good_buildings)
        tuple_P = load_profiles[timestamp, "PLoad_$(i)"]
        tuple_Q = load_profiles[timestamp, "QLoad_$(i)"]
        total_P[1] += tuple_P[1]
        total_P[2] += tuple_P[2]
        total_P[3] += tuple_P[3]
        total_Q[1] += tuple_Q[1]
        total_Q[2] += tuple_Q[2]
        total_Q[3] += tuple_Q[3]
    end
    total_P_load = [total_P[1], total_P[2], total_P[3] - total_PV]
    println("Total active power load at timestamp $(timestamp): $(total_P_load) kW")
    println("Total reactive power load at timestamp $(timestamp): $(total_Q) kVAr")
    println("Total PV production at timestamp $(timestamp): $(total_PV) kW")
    p1 = plot(xlabel="15-min intervals", ylabel="Active Power [kW]", 
              title="Phase 1 Active Power Load Profiles", legend=:topright, 
              legend_background_color=RGBA(1,1,1,0.5))
    p2 = plot(xlabel="15-min intervals", ylabel="Active Power [kW]", 
              title="Phase 2 Active Power Load Profiles", legend=:topright, 
              legend_background_color=RGBA(1,1,1,0.5))
    p3 = plot(xlabel="15-min intervals", ylabel="Active Power [kW]", 
              title="Phase 3 Active Power Load Profiles", legend=:topright, 
              legend_background_color=RGBA(1,1,1,0.5))
    
    q1 = plot(xlabel="15-min intervals", ylabel="Reactive Power [kVAr]", 
              title="Phase 1 Reactive Power Load Profiles", legend=:topright, 
              legend_background_color=RGBA(1,1,1,0.5))
    q2 = plot(xlabel="15-min intervals", ylabel="Reactive Power [kVAr]", 
              title="Phase 2 Reactive Power Load Profiles", legend=:topright, 
              legend_background_color=RGBA(1,1,1,0.5))
    q3 = plot(xlabel="15-min intervals", ylabel="Reactive Power [kVAr]", 
              title="Phase 3 Reactive Power Load Profiles", legend=:topright, 
              legend_background_color=RGBA(1,1,1,0.5))
    Random.seed!(1)
    random_list = rand(1:3, length(good_buildings))
    for i in 1:length(good_buildings)
        tuple_P = load_profiles[timestamp_range, "PLoad_$(i)"]
        tuple_Q = load_profiles[timestamp_range, "QLoad_$(i)"]
        if i == 25
            plot!(p3, [t[3] for t in tuple_P], label="Phase 3, Load $(i)", legend_background_color=RGBA(1,1,1,0.5))
            plot!(q3, [t[3] for t in tuple_Q], label="Phase 3, Load $(i)", legend_background_color=RGBA(1,1,1,0.5))
        elseif random_list[i] == 1
            plot!(p1, [t[1] for t in tuple_P], label="Phase 1, Load $(i)", legend_background_color=RGBA(1,1,1,0.5))
            plot!(q1, [t[1] for t in tuple_Q], label="Phase 1, Load $(i)", legend_background_color=RGBA(1,1,1,0.5))
        elseif random_list[i] == 2
            plot!(p2, [t[2] for t in tuple_P], label="Phase 2, Load $(i)", legend_background_color=RGBA(1,1,1,0.5))
            plot!(q2, [t[2] for t in tuple_Q], label="Phase 2, Load $(i)", legend_background_color=RGBA(1,1,1,0.5))
        elseif random_list[i] == 3
            plot!(p3, [t[3] for t in tuple_P], label="Phase 3, Load $(i)", legend_background_color=RGBA(1,1,1,0.5))
            plot!(q3, [t[3] for t in tuple_Q], label="Phase 3, Load $(i)", legend_background_color=RGBA(1,1,1,0.5))
        end

    end
    pv1 = plot(PV_profile[timestamp_range, "P_pv_3"], xlabel="15-min intervals in the day", ylabel="Active Power [kW]", title="PV production of house 33", legend=false)
    plot!(pv1, PV_profile_Q[timestamp_range, "Q_pv_3"], xlabel="15-min intervals in the day", ylabel="Reactive Power [kVAr]", title="PV production of house 33", legend=false)
    display(p1)
    display(p2)
    display(p3)
    display(q1)
    display(q2)
    display(q3)
    display(pv1)
end

function visualization_effect_Z_line(Result_dict1, season, line, Q_set, Z_range)
    pl = nothing
    p2 = nothing
    p3 = nothing
    p1_sub = nothing
    for Z_value in Z_range
        loading_1 = Result_dict1[Q_set][season]["Z=$(Z_value)"]["Branches"]["$(line)"]["line_loading_P1"][100:300]
        loading_2 = Result_dict1[Q_set][season]["Z=$(Z_value)"]["Branches"]["$(line)"]["line_loading_P2"][100:300]
        loading_3 = Result_dict1[Q_set][season]["Z=$(Z_value)"]["Branches"]["$(line)"]["line_loading_P3"][100:300]
        if Z_value == Z_range[1]
            pl = plot(loading_1, label="Line Loading P1, R=$(Z_value)", xlabel="Time step", ylabel="Line Loading (%)", title="Line Loading at Line $(line) for Q $(Q_set)", legend=:topright)
            p2 = plot(loading_2, label="Line Loading P2, R=$(Z_value)", xlabel="Time step", ylabel="Line Loading (%)", title="Line Loading at Line $(line) for Q $(Q_set)", legend=:topright)
            p3 = plot(loading_3, label="Line Loading P3, R=$(Z_value)", xlabel="Time step", ylabel="Line Loading (%)", title="Line Loading at Line $(line) for Q $(Q_set)", legend=:topright)
            violation_indicator = [v > 1 ? 1 : 0 for v in loading_1]
            p1_sub = plot(violation_indicator, color=:red, fillto=0, fillcolor=:red, alpha=0.3, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1)
        else
            plot!(pl, loading_1, label="Line Loading P1, R=$(Z_value)")
            plot!(p2, loading_2, label="Line Loading P2, R=$(Z_value)")
            plot!(p3, loading_3, label="Line Loading P3, R=$(Z_value)")
        end
    end
    hline!(pl, [1], color=:red, label="")
    combined_plot = plot(pl, p1_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    display(combined_plot)
    display(p2)
    display(p3)
end

function visualization_effect_of_Z_voltage(Result_dict, season, bus, Q_set, Z_range)
    p1 = nothing
    p2 = nothing
    p3 = nothing
    p1_sub = nothing
    for Z_value in Z_range
        v1 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V1"][100:300]
        v2 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V2"][100:300]
        v3 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V3"][100:300]
        if Z_value == Z_range[1]
            p1 = plot(v1, label="Phase 1, R=$(Z_value)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Bus $(bus) for Q =  $(Q_set)", legend=:topright)
            p2 = plot(v2, label="Phase 2, R=$(Z_value)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Bus $(bus) for Q =  $(Q_set)", legend=:topright)
            p3 = plot(v3, label="Phase 3, R=$(Z_value)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Bus $(bus) for Q =  $(Q_set)", legend=:topright)
            violation_indicator = [v > 1.1 ? 1 : 0 for v in v1]
            p1_sub = plot(violation_indicator, color=:red, fillto=0, fillcolor=:red, alpha=0.3, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1)
        else
            plot!(p1, v1, label="Phase 1, R=$(Z_value)")
            plot!(p2, v2, label="Phase 2, R=$(Z_value)")
            plot!(p3, v3, label="Phase 3, R=$(Z_value)")
        end
    end
    hline!(p1, [1.1], color=:red, label="")
    combined_plot = plot(p1, p1_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    display(combined_plot)
    display(p2)
    display(p3)
end

function visualization_effect_of_Q_Z(Result_dict, season, Z_value, bus, alpha)
    Q_sets = ["0", "1", "2"]
    p1 = nothing
    p2 = nothing
    p3 = nothing
    p1_sub = nothing
    p2_sub = nothing
    p3_sub = nothing
    range = 100:772
    for Q_set in Q_sets
        v1 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V1"][range]
        v2 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V2"][range]
        v3 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V3"][range]
        if Q_set == Q_sets[1]
            p1 = plot(v1, label="Phase 1, Q_set=$(Q_set)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Bus $(bus) for alpha $(alpha) in $(season)", legend=:topright)
            p2 = plot(v2, label="Phase 2, Q_set=$(Q_set)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Bus $(bus) for alpha $(alpha) in $(season)", legend=:topright)
            p3 = plot(v3, label="Phase 3, Q_set=$(Q_set)", xlabel="Time step", ylabel="Voltage Magnitude (p.u.)", title="Voltage Magnitude at Bus $(bus) for alpha $(alpha) in $(season)", legend=:topright)
        elseif Q_set == Q_sets[3]
            violation_indicator_1 = [v > 1.1 ? 1 : 0 for v in v1]
            violation_indicator_2 = [v > 1.1 ? 1 : 0 for v in v2]
            violation_indicator_3 = [v > 1.1 ? 1 : 0 for v in v3]
            p1_sub = plot(violation_indicator_1, color=:red, fillto=0, fillcolor=:red, alpha=0.3, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1)
            p2_sub = plot(violation_indicator_2, color=:red, fillto=0, fillcolor=:red, alpha=0.3, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1)
            p3_sub = plot(violation_indicator_3, color=:red, fillto=0, fillcolor=:red, alpha=0.3, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1)
            plot!(p1, v1, label="Phase 1, Q_set=$(Q_set)")
            plot!(p2, v2, label="Phase 2, Q_set=$(Q_set)")
            plot!(p3, v3, label="Phase 3, Q_set=$(Q_set)")
        else
            plot!(p1, v1, label="Phase 1, Q_set=$(Q_set)")
            plot!(p2, v2, label="Phase 2, Q_set=$(Q_set)")
            plot!(p3, v3, label="Phase 3, Q_set=$(Q_set)")
        end
    end
    hline!(p1, [1.1], color=:red, label="")
    hline!(p2, [1.1], color=:red, label="")
    hline!(p3, [1.1], color=:red, label="")
    combined_plot_1 = plot(p1, p1_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    combined_plot_2 = plot(p2, p2_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    combined_plot_3 = plot(p3, p3_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    display(combined_plot_1)
    display(combined_plot_2)
    display(combined_plot_3)
end

function visualization_of_loads_Z(Result_dict, season, Q_set, load, alpha, Z_value, math)
    #range = 1:length(Result_dict[Q_set][season]["Alpha=$(alpha)"]["Loads"]["$(load)"]["P1"])
    range = 300:400
    p1 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Loads"]["$(load)"]["P$(math["load"]["$(load)"]["phase_connections"])"][range].*math["settings"]["sbase"]
    pl1 = plot(p1, label="Phase $(math["load"]["$(load)"]["phase_connections"])", xlabel="Time step", ylabel="Active Power (kW)", title="Active Power at Load $(load) for alpha $(alpha)", legend=:topright)
    display(pl1)
end

function visualization_of_Q_loads_Z(Result_dict, season, Q_set, load, alpha, Z_value, math)
    range = 300:400
    p1 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Loads"]["$(load)"]["Q$(math["load"]["$(load)"]["phase_connections"])"][range].*math["settings"]["sbase"]
    pl1 = plot(p1, label="Phase $(math["load"]["$(load)"]["phase_connections"])", xlabel="Time step", ylabel="Reactive Power (kVAr)", title="Reactive Power at Load $(load) for alpha $(alpha)", legend=:topright)
    display(pl1)
end

function visualization_of_line_loading_Z(Result_dict, season, line, alpha, Z_value)
    pl = nothing
    p2 = nothing
    p3 = nothing
    p1_sub = nothing
    range = 100:772
    for Q_set in ["0", "1", "2"]
        loading_1 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Branches"]["$(line)"]["line_loading_P1"][range]
        loading_2 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Branches"]["$(line)"]["line_loading_P2"][range]
        loading_3 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Branches"]["$(line)"]["line_loading_P3"][range]
        if Q_set == "0"
            pl = plot(loading_1, label="Line Loading P1, Q_set=$(Q_set)", xlabel="Time step", ylabel="Line Loading (%)", title="Line Loading at Line $(line) for alpha $(alpha) in $(season)", legend=:topright)
            p2 = plot(loading_2, label="Line Loading P2, Q_set=$(Q_set)", xlabel="Time step", ylabel="Line Loading (%)", title="Line Loading at Line $(line) for alpha $(alpha) in $(season)", legend=:topright)
            p3 = plot(loading_3, label="Line Loading P3, Q_set=$(Q_set)", xlabel="Time step", ylabel="Line Loading (%)", title="Line Loading at Line $(line) for alpha $(alpha) in $(season)", legend=:topright)
            violation_indicator = [v > 1 ? 1 : 0 for v in loading_1]
            p1_sub = plot(violation_indicator, color=:red, fillto=0, fillcolor=:red, alpha=0.3, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1)
        else
            plot!(pl, loading_1, label="Line Loading P1, Q_set=$(Q_set)")
            plot!(p2, loading_2, label="Line Loading P2, Q_set=$(Q_set)")
            plot!(p3, loading_3, label="Line Loading P3, Q_set=$(Q_set)")
        end
    end
    hline!(pl, [1], color=:red, label="")
    combined_plot = plot(pl, p1_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    display(combined_plot)
    display(p2)
    display(p3)
end

#Extra: Visualization of a random PV and load profile
function single_plots()
    range = 21352:21363
    plot(PV_profile[range, "P_pv_3"], xlabel="15-min intervals in the day", ylabel="Active Power [kW]", title="PV production of house 33", legend=false)
    plot!(PV_profile[range, "P_pv_3"].*tan(acos(0.95)), xlabel="15-min intervals in the day", ylabel="Reactive Power [kVAr]", title="PV production of house 33", legend=false)
    println("Max PV production of house 33: $(maximum(PV_profile[range, "P_pv_3"])) kW")
    house = 25   #25 = house 33
    tuples = load_profiles[range, "PLoad_$(house)"]
    P1 = plot([t[1] for t in tuples], xlabel="15-min intervals in the day", ylabel="Active Power [kW]", title="Load profile of house $(good_buildings[house])", legend=false)
    plot!(P1, [t[2] for t in tuples], xlabel="15-min intervals in the day", ylabel="Active Power [kW]", title="Load profile of house $(good_buildings[house])", legend=false)
    plot!(P1, [t[3] for t in tuples], xlabel="15-min intervals in the day", ylabel="Active Power [kW]", title="Load profile of house $(good_buildings[house])", legend=false)
    display(P1)

    tuples_Q = load_profiles[range, "QLoad_$(house)"]
    Q1 = plot([t[1] for t in tuples_Q], xlabel="15-min intervals in the day", ylabel="Reactive Power [kVAr]", title="Load profile of house $(good_buildings[house])", legend=false)
    plot!(Q1, [t[2] for t in tuples_Q], xlabel="15-min intervals in the day", ylabel="Reactive Power [kVAr]", title="Load profile of house $(good_buildings[house])", legend=false)
    plot!(Q1, [t[3] for t in tuples_Q], xlabel="15-min intervals in the day", ylabel="Reactive Power [kVAr]", title="Load profile of house $(good_buildings[house])", legend=false)
    display(Q1)

    println("Max Q load of house 33: $(maximum([t[3] for t in tuples_Q])) kVAr")
end
