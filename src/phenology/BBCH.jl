@system BBCH begin

    #===================
    Biomass partitioning
    ====================#
    
    "Foliage:stem partitioning ratio at D=2cm"
    pFS2 => 1 ~ preserve(parameter)
    
    "Foliage:stem partitioning ratio at D=20cm"
    pFS20 => 0.15 ~ preserve(parameter)
    
    pfsPower(pFS2, pFS20) => log(pFS20 / pFS2) / log(20 / 2) ~ preserve
    
    pfsConst(pFS2, pfsPower) => pFS2 / 2 ^ pfsPower ~ preserve
      
    "Maximum fraction of NPP to roots"
    pRx => 0.8 ~ preserve(parameter)
    
    "Minimum fraction of NPP to roots"
    pRn => 0.25 ~ preserve(parameter)
    
    pFS(pfsConst, nounit(avDBH), pfsPower) => pfsConst * (avDBH ^ pfsPower) ~ track # foliage and stem partition
    pR30(pRx, pRn, fAge) => pRx * pRn / (pRn + ( pRx - pRn) * fAge) ~ track # root partition
    pS30(pR30, pFS) => (1 - pR30) / (1 + pFS) ~ track # stem partition
    pF30(pR30, pS30) => 1 - pR30 - pS30 ~ track # foliage partition

    pR90(pR30, pF30) => pR30 + pF30/2 ~ track
    pS90(pR90) => 1 - pR90 ~ track
    
    # Determine BBCH stage
    BBCH_stage(budburst, leafexpansion, senescent, dormant) => begin
        if dormant
            :BBCH00
        elseif budburst
            :BBCH10
        elseif leafexpansion
            :BBCH11
        elseif senescent
            :BBCH90
        else
            :BBCH30 # shoot development
        end
    end ~ track::Symbol

    # Carbon partitioning table corresponding to BBCH stages.
    BBCH_table(pF30, pS30, pR30, pR90, pS90) => [
      # leaf stem root
        0.00 0.00 0.00 # BBCH00
        0.90 0.05 0.05 # BBCH10
        0.90 0.05 0.05 # BBCH11
        pF30 pS30 pR30 # BBCH30
        0.00 pS90 pR90 # BBCH90
    ] ~ tabulate(
        rows=(:BBCH00, :BBCH10, :BBCH11, :BBCH30, :BBCH90),
        columns=(:leaf, :stem, :root),
        parameter
    )
end
