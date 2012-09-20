require "ember-skeleton/core"

App.Data = Ember.Object.extend(
    ###
    User input
    ###
    temp: 300
    material: 'Si'
    N_d: 0 # Donor concentration
    N_a: 0 # Acceptor concentration
    
    ###
    Constants
    ###
    E_mid: 0
    m_0: 9.11e-31
    h: 6.625e-34
    N_c_0: {
        Si: 2.8e19
        GaAs: 4.7e17
        Ge: 1.04e19
    }
    my_N_c_0: (->
        @N_c_0[@get('material')]
    ).property('material')
    
    N_v_0: {
        Si: 1.04e19
        GaAs: 7e18
        Ge: 6e18
    }
    my_N_v_0: (->
        @N_v_0[@get('material')]
    ).property('material')
    
    m_n: {
        Si: 1.08
        GaAs: 0.067
        Ge: 0.55
    }
    my_m_n: (->
        @m_n[@get('material')] * @m_0
    ).property('material')
    
    m_p: {
        Si: 0.56
        GaAs: 0.48
        Ge: 0.37
    }
    my_m_p: (->
        @m_p[@get('material')] * @m_0
    ).property('material')
    
    Energy_gap: {
        Si: 1.12
        GaAs: 1.42
        Ge: 0.66
    }
    my_Energy_gap: (->
        @Energy_gap[@get('material')]
    ).property('material')
    
    ###
    After User Input
    ###
    E_c: (->
        @get('my_Energy_gap')/2 + @E_mid
    ).property('my_Energy_gap')
    
    E_v: (->
        -@get('my_Energy_gap')/2 + @E_mid
    ).property('my_Energy_gap')
    
    N_c: (->
        proportion = Math.pow(@get('temp') / 300, 1.5)
        
        @get('my_N_c_0') * proportion
    ).property('my_N_c_0', 'temp')
    
    N_v: (->
        proportion = Math.pow(@get('temp') / 300, 1.5)
        
        @get('my_N_v_0') * proportion
    ).property('my_N_v_0', 'temp')
    
    kT: (->
        0.0259 * @get('temp') / 300
    ).property('temp')
    
    n_i: (->
        Math.sqrt(@get('N_c') * @get('N_v') * Math.exp( -@get('my_Energy_gap')/@get('kT')))
    ).property('N_c', 'N_v', 'my_Energy_gap', 'kT')
    
    ###
    Electron & Hole concentration
    ###
    Nd_gt_Na: (->
        @get('N_d') > @get('N_a')
    ).property('N_d', 'N_a')
    
    n0: (->
        if @get('Nd_gt_Na')
            diff = @get('N_d') - @get('N_a')
            return (diff / 2) + Math.sqrt( Math.pow((diff / 2), 2) + Math.pow(@get('n_i'), 2) )
        else
            return Math.pow(@get('n_i'), 2) / @get('p0') || 0
    ).property('N_a', 'N_d', 'n_i', 'p0')
    
    p0: (->
        if @get('Nd_gt_Na')
            return Math.pow(@get('n_i'), 2) / @get('n0')
        else
            diff = @get('N_a') - @get('N_d')
            return (diff / 2) + Math.sqrt( Math.pow((diff / 2), 2) + Math.pow(@get('n_i'), 2) )
    ).property('N_a', 'N_d', 'n_i', 'n0')
    
    ###
    Equations
    ###
    E_fi: (->
        # E_f intrinsic
        @E_mid + 3*@get('kT')*Math.log(@get('my_m_p') / @get('my_m_n'))/4
    ).property('kT', 'my_m_p', 'my_m_n')
    
    E_f: ( ->
        ratio = @get('n0') / @get('n_i')        
        @get('E_fi') + @get('kT') * Math.log( ratio )
    ).property('E_fi', 'kT', 'n0', 'n_i')
    
    f_F: (E) ->
        # Fermi-Driac
        exp_term = (E - @get('E_f')) / @get('kT')
        # console.log @get('E_f'), @get('kT')
        1 / ( 1 + Math.exp(exp_term) )


    f_F_changed: (->
        true
    ).property('E_f', 'kT')
    
    g_c: (E) ->
        # Density of conduction band
        top = 4 * Math.PI * Math.pow(2*@get('my_m_n'), 1.5)
        bot = Math.pow(@h, 3)
        right = Math.sqrt(E - @get('E_c'))
        return top*right/bot
    
    g_v: (E) ->
        # Density of valence band
        top = 4 * Math.PI * Math.pow(2*@get('my_m_p'), 1.5)
        bot = Math.pow(@h, 3)
        right = Math.sqrt(@get('E_v') - E)
        return top*right/bot
    
    g_c_changed: (->
        true
    ).property('E_c', 'my_m_n')
    
    g_v_changed: (->
        true
    ).property('E_v', 'my_m_p')
)