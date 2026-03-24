@system Budburst begin

    #=========
    Parameters
    =========#

    "Minimum temperature for budburst"
    T_bud_min => 5 ~ preserve(parameter, u"°C")

    "Optimal temperature for budburst"
    T_bud_opt => 20 ~ preserve(parameter, u"°C")

    "Maximum temperature for budburst"
    T_bud_max => 40 ~ preserve(parameter, u"°C")

    "Yearly target bud growth as constant"
    bud_max_const => 1e3 ~ preserve(parameter, u"kg/ha")
    "Yearly target bud growth as fraction of dormant biomass"
    bud_max_factor => 0.02 ~ preserve(parameter)    

    # bud growth per degree hours
    bud_rate => 1 ~ preserve(parameter, u"kg/ha/hr/K")  

    #=========
    =========#

    # Budburst only when forcing requirement met. No budburst when coppiced i.e. WS == 0. Budburst halts when target bud_max is met.
    budburst(F, Rf, bud_max, WF) => begin
        (F >= Rf) && (bud_max >= WF)
    end ~ flag

    # Degree units for budburst. Actual
    BD(T=T_air, Tb=T_bud_min, To=T_bud_opt, Tx=T_bud_max): budburst_degrees => begin
        T = !isnothing(To) ? min(T, To) : T
        T = !isnothing(Tx) && T >= Tx ? Tb : T
        T - Tb
        # min(T_air, T_bud_opt) - T_bud 
    end ~ track(when=budburst, min=0, u"K")

    BDD(BD): budburst_degree_days ~ accumulate(u"K*hr")

    # set bud_max_factor = 0 for constant bud_max = bud_max_const
    # yearly amount of stem mass allocated to buds
    bud_max(bud_max_factor, WD, bud_max_const) => begin
        bud_max_factor == 0 ? bud_max_const : bud_max_factor * WD 
    end ~ track(u"kg/ha")

    # mass of buds remaining
    bud_mass(bud_max, bud) => bud_max - bud ~ track(u"kg/ha")

    dBud_max(bud_mass, step) => bud_mass / step ~ track(u"kg/ha/hr")

    # bud growth per hour (WIP).
    dBud(bud_rate, BD) => bud_rate * BD ~ track(max=dBud_max, u"kg/ha/hr")

    # Accumulated bud growth for the year. Resets to 0 every year. 
    bud(dBud) ~ accumulate(reset=senescent, u"kg/ha")
end
