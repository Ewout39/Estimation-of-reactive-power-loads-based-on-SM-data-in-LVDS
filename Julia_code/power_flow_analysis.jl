module Power_Flow_Analysis


using JuMP
using Ipopt
using Plots
using Colors
using LinearAlgebra
import PowerModelsDistribution as _PMD
using ..Load_Data
using ..NetworkFunctions

export hosting_capacity_analysis!

"""
    function hosting_capacity_analysis!(math, load_profiles, alpha, EV_load, rep_month_start::Int64, rep_month_end::Int64, most_loaded_week::UnitRange{Int64}, Q_setpoint::Int64=2, season::String="Summer", Q_Z::String="Q", Z_value::Float64=1.0, power_mult::Float64=1.0)

#Arguments:
- `math`: The power model data structure.
- `load_profiles`: The load profiles for the buildings.
- `alpha`: The scaling factor for the load profiles.
- `EV_load`: The list of loads to which an EV load should be added.
- `rep_month_start`: The starting timestep of the representative month.
- `rep_month_end`: The ending timestep of the representative month.
- `most_loaded_week`: The range of timesteps corresponding to the most loaded week.
- `Q_setpoint`: The setpoint for reactive power.
- `season`: The season for which the analysis is being performed.
- `Q_Z`: A string indicating whether to use reactive power ("Q") or impedance ("Z") for the analysis.
- `Z_value`: The value of impedance to be used if `Q_Z` is set to "Z".
- `power_mult`: A multiplier for the power of the EV load.

Performs a power flow analysis over a timestep range, checking for voltage and line loading violations and storing the results.
"""

function hosting_capacity_analysis!(math, load_profiles, alpha, EV_load, rep_month_start::Int64, rep_month_end::Int64, most_loaded_week::UnitRange{Int64}, Q_setpoint::Int64=2, season::String="Summer", Q_Z::String="Q", Z_value::Float64=1.0, power_mult::Float64=1.0)
    timesteps_range = rep_month_start:rep_month_end
    new_alpha_v = 1
    new_alpha_ll = 1
    println("Starting analysis for Q_setpoint = $Q_setpoint")
    _PMD.add_start_vrvi!(math)
    for timestep in timesteps_range[most_loaded_week]
        insert_P_profiles!(math, load_profiles, timestep, alpha, EV_load, power_mult)
        insert_Q_profiles_usa!(math, load_profiles, timestep, Q_setpoint, season, alpha)
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
            return
        else
            if timestep != timesteps_range[1]
                add_initial_values!(math, res)
            end
            add_to_dict!(Result_dict1, res, Q_setpoint, alpha, Z_value, Q_Z, season, math)
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

end # module Power_Flow_Analysis