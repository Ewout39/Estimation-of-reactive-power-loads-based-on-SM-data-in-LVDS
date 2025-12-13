function visualization_same_bus_diff_alpha(Result_dict, season, Q_set, bus, range)
    alphas = range
    p1 = nothing
    p2 = nothing
    p3 = nothing
    range = 100:772
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
            violation_indicator = [v < 0.9 ? 1 : 0 for v in v1]
            p1_sub = plot(violation_indicator, color=:red, fillto=0, fillcolor=:red, alpha=0.3, yticks=[0, 1], ylims=(-0.1, 1.1), legend=false, bar_width = 1)
        else
            plot!(p1, v1, label="Phase 1, Q_set=$(Q_set)")
            plot!(p2, v2, label="Phase 2, Q_set=$(Q_set)")
            plot!(p3, v3, label="Phase 3, Q_set=$(Q_set)")
        end
    end
    hline!(p1, [0.9], color=:red, label="")
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
    range = 1345:2016
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

function visualization_effect_of_Q_Z(Result_dict, season, Z_value, bus, area)
    Q_sets = ["0", "1", "2"]
    c_light = RGB(0.80, 0.80, 0.80)   # light gray
    c_mid   = RGB(0.50, 0.50, 0.50)   # medium gray
    c_dark  = RGB(0.20, 0.20, 0.20)   # dark gray
    p1 = nothing
    p2 = nothing
    p3 = nothing
    p1_sub = nothing
    p2_sub = nothing
    p3_sub = nothing
    #range = 673:1344
    range = 2017:2688
    for Q_set in Q_sets
        v1 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V1"][range]
        v2 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V2"][range]
        v3 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V3"][range]
        if Q_set == Q_sets[1]
            p1 = plot(v1, color =c_light, label=L"PF~=~0.95", linestyle = :dot, linewidth = 2.0, xlabel=L"Time~step", ylabel=L"Voltage~Magnitude~(p.u.)", legend=:topright, legend_background_color=RGBA(1,1,1,0.85), legendfontsize = 20, guidefontsize =20, tickfontsize = 15, titlefontsize=20, yscale=:log10, yticks = ([0.9, 0.92, 0.94, 0.96, 0.98], [L"0.9", L"0.92", L"0.94", L"0.96", L"0.98"]), xticks = ([0, 96, 192, 288, 384, 480, 576], [L"0", L"24h", L"48h", L"72h", L"96h", L"120h", L"144h"]))
            p2 = plot(v2, color =c_light, label=L"PF~=~0.95", linestyle = :dot, linewidth = 2.0, xlabel=L"Time~step", ylabel=L"Voltage~Magnitude~(p.u.)", legend_background_color=RGBA(1,1,1,0.85), legend=:topright, legendfontsize = 20, guidefontsize =20, tickfontsize = 15, titlefontsize=20, yscale=:log10, yticks = ([0.9, 0.92, 0.94, 0.96, 0.98], [L"0.9", L"0.92", L"0.94", L"0.96", L"0.98"]), xticks = ([0, 96, 192, 288, 384, 480, 576], [L"0", L"24h", L"48h", L"72h", L"96h", L"120h", L"144h"]))
            p3 = plot(v3, color =c_light, label=L"PF~=~0.95", linestyle = :dot, linewidth = 2.0, xlabel=L"Time~step", ylabel=L"Voltage~Magnitude~(p.u.)", legend_background_color=RGBA(1,1,1,0.85), legend=:topright, legendfontsize = 20, guidefontsize =20, tickfontsize = 15, titlefontsize=20, yscale=:log10, yticks=([0.96, 0.97, 0.98, 0.99], [L"0.96", L"0.97", L"0.98", L"0.99"]), xticks = ([0, 96, 192, 288, 384, 480, 576], [L"0", L"24h", L"48h", L"72h", L"96h", L"120h", L"144h"]))
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
    combined_plot_1 = plot(p1, p1_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    combined_plot_2 = plot(p2, p2_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    combined_plot_3 = plot(p3, p3_sub, layout=@layout([a{0.9h}; b{0.1h}]), size=(800, 600))
    display(combined_plot_1)
    display(combined_plot_2)
    display(combined_plot_3)
    savefig(combined_plot_1, "C:\\Users\\ewout\\OneDrive - KU Leuven\\PHD\\Papers\\paper_thesis\\result_figures\\Undervoltage_Violations_Bus_$(bus)_Area_$(area)_Phase_1_Z_$(Z_value).pdf")
    savefig(combined_plot_2, "C:\\Users\\ewout\\OneDrive - KU Leuven\\PHD\\Papers\\paper_thesis\\result_figures\\Undervoltage_Violations_Bus_$(bus)_Area_$(area)_Phase_2_Z_$(Z_value).pdf")
    savefig(combined_plot_3, "C:\\Users\\ewout\\OneDrive - KU Leuven\\PHD\\Papers\\paper_thesis\\result_figures\\Undervoltage_Violations_Bus_$(bus)_Area_$(area)_Phase_3_Z_$(Z_value).pdf")
    #savefig(combined_plot_1, "C:\\Users\\u0181580\\OneDrive - KU Leuven\\PHD\\Papers\\paper_thesis\\result_figures\\Undervoltage_Violations_Bus_$(bus)_Area_$(area)_Phase_1_Z_$(Z_value).pdf")
    #savefig(combined_plot_2, "C:\\Users\\u0181580\\OneDrive - KU Leuven\\PHD\\Papers\\paper_thesis\\result_figures\\Undervoltage_Violations_Bus_$(bus)_Area_$(area)_Phase_2_Z_$(Z_value).pdf")
    #savefig(combined_plot_3, "C:\\Users\\u0181580\\OneDrive - KU Leuven\\PHD\\Papers\\paper_thesis\\result_figures\\Undervoltage_Violations_Bus_$(bus)_Area_$(area)_Phase_3_Z_$(Z_value).pdf")
end

function visualization_effect_of_Q_Z_1(Result_dict, season, Z_value, bus, area)
    Q_sets = ["0", "1", "2"]
    c_light = RGB(0.80, 0.80, 0.80)   # light gray
    c_mid   = RGB(0.50, 0.50, 0.50)   # medium gray
    c_dark  = RGB(0.20, 0.20, 0.20)   # dark gray

    range = 2017:2688

    # Initialize plots
    p1_high = nothing; p2_high = nothing; p3_high = nothing
    p1_low  = nothing; p2_low  = nothing; p3_low  = nothing
    p1_sub  = nothing; p2_sub  = nothing; p3_sub  = nothing

    for Q_set in Q_sets
        v1 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V1"][range]
        v2 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V2"][range]
        v3 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V3"][range]

        # violation indicators
        vio1 = [v < 0.9 ? 1 : 0 for v in v1]
        vio2 = [v < 0.9 ? 1 : 0 for v in v2]
        vio3 = [v < 0.9 ? 1 : 0 for v in v3]

        if Q_set == Q_sets[1]
            # low and high y-axis plots
            p1_low  = plot(v1, color=c_light, linestyle=:dot, linewidth=2, label=L"PF≈0.95",
                           ylims=(0.85,0.94), xlabel=L"Time step", ylabel=L"Voltage (p.u.)",
                           xticks=0:96:576, legend=:topright)
            p1_high = plot(v1, color=c_light, linestyle=:dot, linewidth=2, label=L"PF≈0.95",
                           ylims=(0.94,1.0), xlabel=L"Time step", ylabel=L"", xticks=0:96:576)

            p2_low  = plot(v2, color=c_light, linestyle=:dot, linewidth=2, label=L"PF≈0.95",
                           ylims=(0.85,0.94), xlabel=L"Time step", ylabel=L"Voltage (p.u.)",
                           xticks=0:96:576, legend=:topright)
            p2_high = plot(v2, color=c_light, linestyle=:dot, linewidth=2, label=L"PF≈0.95",
                           ylims=(0.94,1.0), xlabel=L"Time step", ylabel=L"", xticks=0:96:576)

            p3_low  = plot(v3, color=c_light, linestyle=:dot, linewidth=2, label=L"PF≈0.95",
                           ylims=(0.85,0.94), xlabel=L"Time step", ylabel=L"Voltage (p.u.)",
                           xticks=0:96:576, legend=:topright)
            p3_high = plot(v3, color=c_light, linestyle=:dot, linewidth=2, label=L"PF≈0.95",
                           ylims=(0.94,1.0), xlabel=L"Time step", ylabel=L"", xticks=0:96:576)

            # violation bars remain the same
            p1_sub = plot(vio1, color=:red, fillto=0, fillcolor=:red, alpha=0.7,
                          yticks=[0,1], ylims=(-0.1,1.1), legend=false, bar_width=1)
            p2_sub = plot(vio2, color=:red, fillto=0, fillcolor=:red, alpha=0.7,
                          yticks=[0,1], ylims=(-0.1,1.1), legend=false, bar_width=1)
            p3_sub = plot(vio3, color=:red, fillto=0, fillcolor=:red, alpha=0.7,
                          yticks=[0,1], ylims=(-0.1,1.1), legend=false, bar_width=1)

        elseif Q_set == Q_sets[3]
            # Ground truth
            plot!(p1_low, v1, color=c_dark, linestyle=:dash, linewidth=3, label=L"Ground truth")
            plot!(p1_high, v1, color=c_dark, linestyle=:dash, linewidth=3, label=L"Ground truth")
            plot!(p2_low, v2, color=c_dark, linestyle=:dash, linewidth=3, label=L"Ground truth")
            plot!(p2_high, v2, color=c_dark, linestyle=:dash, linewidth=3, label=L"Ground truth")
            plot!(p3_low, v3, color=c_dark, linestyle=:dash, linewidth=3, label=L"Ground truth")
            plot!(p3_high, v3, color=c_dark, linestyle=:dash, linewidth=3, label=L"Ground truth")

            # Add violation corrections
            act_vio1 = [v < 0.9 ? 1 : 0 for v in v1]
            act_vio2 = [v < 0.9 ? 1 : 0 for v in v2]
            act_vio3 = [v < 0.9 ? 1 : 0 for v in v3]
            plot!(p1_sub, act_vio1, color=:green, fillto=0, fillcolor=:green, alpha=0.7)
            plot!(p2_sub, act_vio2, color=:green, fillto=0, fillcolor=:green, alpha=0.7)
            plot!(p3_sub, act_vio3, color=:green, fillto=0, fillcolor=:green, alpha=0.7)

        else
            # Best method
            plot!(p1_low, v1, color=c_mid, linestyle=:solid, markersize=1, markevery=100,
                  label=L"Best method")
            plot!(p1_high, v1, color=c_mid, linestyle=:solid, markersize=1, markevery=100,
                  label=L"Best method")
            plot!(p2_low, v2, color=c_mid, linestyle=:solid, markersize=1, markevery=100,
                  label=L"Best method")
            plot!(p2_high, v2, color=c_mid, linestyle=:solid, markersize=1, markevery=100,
                  label=L"Best method")
            plot!(p3_low, v3, color=c_mid, linestyle=:solid, markersize=1, markevery=100,
                  label=L"Best method")
            plot!(p3_high, v3, color=c_mid, linestyle=:solid, markersize=1, markevery=100,
                  label=L"Best method")
        end
    end

    # Add threshold lines if needed
    for Q_set in Q_sets
        v1 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V1"][range]
        v2 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V2"][range]
        v3 = Result_dict[Q_set][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V3"][range]

        if !all(v1 .> 0.9)
            hline!(p1_low, [0.9], color=:red, label="")
            hline!(p1_high, [0.9], color=:red, label="")
        end
        if !all(v2 .> 0.9)
            hline!(p2_low, [0.9], color=:red, label="")
            hline!(p2_high, [0.9], color=:red, label="")
        end
        if !all(v3 .> 0.9)
            hline!(p3_low, [0.9], color=:red, label="")
            hline!(p3_high, [0.9], color=:red, label="")
        end
    end

    # Combine low/high plots and violation bars
    combined_plot_1 = plot(p1_low, p1_high, p1_sub,
                           layout=@layout([a{0.45h}; b{0.45h}; c{0.1h}]), size=(900,600))
    combined_plot_2 = plot(p2_low, p2_high, p2_sub,
                           layout=@layout([a{0.45h}; b{0.45h}; c{0.1h}]), size=(900,600))
    combined_plot_3 = plot(p3_low, p3_high, p3_sub,
                           layout=@layout([a{0.45h}; b{0.45h}; c{0.1h}]), size=(900,600))

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

function min_max_differences(Result_dict, season, bus, Z_value)
    range = 2017:2688
    v1_truth = Result_dict["2"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V1"][range]
    v2_truth = Result_dict["2"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V2"][range]
    v3_truth = Result_dict["2"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V3"][range]
    v1_method = Result_dict["1"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V1"][range]
    v2_method = Result_dict["1"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V2"][range]
    v3_method = Result_dict["1"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V3"][range]
    v1_industry = Result_dict["0"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V1"][range]
    v2_industry = Result_dict["0"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V2"][range]
    v3_industry = Result_dict["0"][season]["Z=$(Z_value)"]["Busses"]["$(bus)"]["V3"][range]
    max_diff_method = maximum(abs.(v1_truth .- v1_method))*230
    min_diff_method = minimum(abs.(v1_truth .- v1_method))*230
    max_diff_industry = maximum(abs.(v1_truth .- v1_industry))*230
    min_diff_industry = minimum(abs.(v1_truth .- v1_industry))*230
    println("Max difference Phase 1 Method: $(max_diff_method), Min difference Phase 1 Method: $(min_diff_method)")
    println("Max difference Phase 1 Industry: $(max_diff_industry), Min difference Phase 1 Industry: $(min_diff_industry)")
    max_diff_method = maximum(abs.(v2_truth .- v2_method))*230
    min_diff_method = minimum(abs.(v2_truth .- v2_method))*230
    max_diff_industry = maximum(abs.(v2_truth .- v2_industry))*230
    min_diff_industry = minimum(abs.(v2_truth .- v2_industry))*230
    println("Max difference Phase 2 Method: $(max_diff_method), Min difference Phase 2 Method: $(min_diff_method)")
    println("Max difference Phase 2 Industry: $(max_diff_industry), Min difference Phase 2 Industry: $(min_diff_industry)")
    max_diff_method = maximum(abs.(v3_truth .- v3_method))*230
    min_diff_method = minimum(abs.(v3_truth .- v3_method))*230
    max_diff_industry = maximum(abs.(v3_truth .- v3_industry))*230
    min_diff_industry = minimum(abs.(v3_truth .- v3_industry))*230
    println("Max difference Phase 3 Method: $(max_diff_method), Min difference Phase 3 Method: $(min_diff_method)")
    println("Max difference Phase 3 Industry: $(max_diff_industry), Min difference Phase 3 Industry: $(min_diff_industry)")
end
