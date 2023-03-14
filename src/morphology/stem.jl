@system Stem begin

    "Initial stem drymass"
    iWS ~ preserve(parameter, u"kg/ha")

    growthStem(NPP, pS) => NPP * pS ~ track(u"kg/ha/hr") # stem

    deathStem(WS, mS, mortality, stemNo) => begin
        mS * mortality * (WS / stemNo)
    end ~ track(u"kg/ha/hr", when=flagMortal)

    dWS(growthStem, deathStem) => growthStem - deathStem ~ track(u"kg/ha/d")
    WS(dWS) ~ accumulate(u"kg/ha", init=iWS) # stem drymass
end