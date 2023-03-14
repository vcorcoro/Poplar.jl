include("radiation.jl")

@system Foliage(Radiation) begin
    "Initial foliage drymass"
    iWF ~ preserve(parameter, u"kg/ha")

    # Specific leaf area
    "Specific leaf area at age 0"
    SLA0 ~ preserve(parameter, u"m^2/kg")
    
    "Specfic leaf area for mature leaves"
    SLA1 ~ preserve(parameter, u"m^2/kg")
    
    "Age at which specific leaf area = (SLA0 + SLA1)/2"
    tSLA ~ preserve(parameter)

    growthFoliage(NPP, pF) => NPP * pF ~ track(u"kg/ha/hr") # foliage

    deathFoliage(WF, mF, mortality, stemNo) => begin
        mF * mortality * (WF / stemNo)
    end ~ track(u"kg/ha/hr", when=flagMortal)

    "Maximum litterfall rate"
    gammaF1 ~ preserve(parameter)

    "Literfall rate at t = 0"
    gammaF0 ~ preserve(parameter)

    "Age at which litterfall rate has median value"
    tgammaF ~ preserve(parameter)

    # Monthly litterfall rate
    gammaF(gammaF1, gammaF0, standAge, tgammaF) => begin
        if tgammaF * gammaF1 == 0
            gammaF1
        else
            kgammaF = 12 * log(1 + gammaF1 / gammaF0) / tgammaF
            gammaF1 * gammaF0 / (gammaF0 + (gammaF1 - gammaF0) * exp(-kgammaF * standAge))
        end
    end ~ track
    
    # Hourly litterfall rate
    gammaFhour(calendar, gammaF) => begin
        (1 - (1 - gammaF)^(1 / daysinmonth(calendar.date') / 24)) / u"hr"
    end ~ track(u"hr^-1")

    litterfall(gammaFhour, WF) => gammaFhour * WF ~ track(u"kg/ha/hr")

    dWF(growthFoliage, litterfall, deathFoliage) => growthFoliage - litterfall - deathFoliage ~ track(u"kg/ha/hr")
    WF(dWF) ~ accumulate(u"kg/ha", init=iWF) # foliage drymass

    # Specific leaf area based on stand age (years)
    SLA(standAge, SLA0, SLA1, tSLA) => begin
        SLA1 + (SLA0 - SLA1) * exp(-log(2) * (standAge / tSLA) ^ 2)
    end ~ track(u"m^2/kg")

    # Leaf Area Index
    LAI(WF, SLA) => WF * SLA ~ track
end