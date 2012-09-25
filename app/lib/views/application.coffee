require "ember-skeleton/core"

App.ButtonGroup = Ember.View.extend(
    className: 'control'
    data: null
    template: Ember.Handlebars.compile """
    <div class="btn-group">
        {{view view.Button value="Si" targetBinding="view.data.material"}}
        {{view view.Button value="GaAs" targetBinding="view.data.material"}}
        {{view view.Button value="Ge" targetBinding="view.data.material"}}
    </div>
    """
    
    Button: Ember.View.extend(
        tagName: 'a'
        classNames: ['btn']
        classNameBindings: ['isPrimary']
        value: 'Unassigned'
        target: null
        
        template: Ember.Handlebars.compile "{{view.value}}"
        
        click: ->
            @set 'target', @get('value')
        
        isPrimary: (->
            if @get('value') == @get('target')
                return 'btn-primary' 
            else
                return ''
        ).property('target')
    )
)

App.Slider = Ember.View.extend(
    min: 0
    max: 100
    value: 0
    rawValue: 0
    units: ''
    
    classNames: ['slider-wrapper', 'row', 'control']
    
    template: Ember.Handlebars.compile """
    <div class="row control">
        <div class="span2">{{view.label}}</div>
        <div class="span4">
            <div class="slider"></div>
        </div>
        <div class="span2">
            <span class="value help-inline">{{{view.valueString}}} {{{view.units}}}</span>
        </div>
    </div>
    """
    
    valueString: (->
        @get 'value'
    ).property('value')
    
    sliderChangedValue: (val) ->
        @set 'value', val
        
    didInsertElement: ->
        @set 'slider', @$().find('.slider').slider(
            min: @get('min')
            max: @get('max')
            step: (@get('max') - @get('min')) / 1000
            value: @get('value')
            slide: (event, ui) =>
                @set 'rawValue', ui.value
                @sliderChangedValue ui.value
        )
        
)

App.LogSlider = App.Slider.extend(
    sliderChangedValue: (val) ->
        @set 'value', Math.pow(10, val)
    
    valueString: (->
        exp = @get 'rawValue'
        "10<sup>#{exp}</sup>"
    ).property('value')
)

App.GraphView = Ember.View.extend(
    dataBinding: 'parentView.data'
    classNames: ['plot']
        
    yminBinding: 'parentView.ymin'
    ymaxBinding: 'parentView.ymax'
    
    showTooltip: (x, y, contents) ->
        @set 'tooltip', $('<div class="flot-tooltip">' + contents + '</div>').css( {
            position: 'absolute',
            display: 'none',
            top: y + 5,
            left: x + 5,
            border: '1px solid #fdd',
            padding: '2px',
            'background-color': '#fee',
            opacity: 0.80
        }).appendTo("body").fadeIn(200);
            
    didInsertElement: ->
        @plotRerender()
        @$().bind("plothover", (event, pos, item) =>
            try
                @get('tooltip').remove()
            catch e
                #
                
            if item
                x = item.datapoint[0].toExponential(2)
                y = item.datapoint[1].toExponential(2)
                    
                @showTooltip(item.pageX, item.pageY, x);
                                           
        )
)

App.ApplicationView = Ember.View.extend(
    dataBinding: "controller.content"
    templateName: "ember-skeleton/~templates/application"
        
    DebugView: Ember.View.extend(
        dataBinding: "parentView.data"
        template: Ember.Handlebars.compile """
            <strong>Input</strong>
            <ul>
            <li>Material: {{view.data.material}}
            <li>Temp: {{view.data.temp}}
            <li>Donor concentration: {{view.data.N_d}}
            <li>Acceptor concentration: {{view.data.N_a}}
            </ul>
            <strong>Derive:</strong>
            <ul>
            <li>N_c: {{view.data.N_c}}
            <li>N_v: {{view.data.N_v}}
            <li>kT: {{view.data.kT}}
            <li>n_i: {{view.data.n_i}}
            </ul>
            <strong>Electron and hole concentration</strong>
            <ul>
            <li>n0: {{view.data.n0}}
            <li>p0: {{view.data.p0}}
            </ul>
        """
    )
    
    ymin: -3
    ymax: 3
    
    DensityStateGraphView: App.GraphView.extend(        
        options: (->
            grid:
                hoverable: true
            yaxis:
                min: @get('ymin')
                max: @get('ymax')
            xaxis:
                tickFormatter: (val, axis) =>
                    return val.toExponential(0)
        ).property('ymin', 'ymax')
                
        gc_points: (->
            ([@get('data').g_c(E), E] for E in [@get('ymin')..@get('ymax')] by 0.001)
        ).property('data.g_c_changed')

        gv_points: (->
            ([@get('data').g_v(E), E] for E in [@get('ymin')..@get('ymax')] by 0.01)
        ).property('data.g_v_changed')
        
        plotRerender: (->
            $.plot(@$(), [@get('gc_points'), @get('gv_points')], @get('options'))
        ).observes('gc_points', 'gv_points')
        
    )
    
    DensityParticleGraphView: App.GraphView.extend(        
        options: (->
            grid:
                hoverable: true
            yaxis:
                min: @get('ymin')
                max: @get('ymax')
            xaxis:
                autoscaleMargin: 0.1
                tickFormatter: (val, axis) =>
                    return val.toExponential(0)
        ).property('ymin', 'ymax')
                
        n_points: (->
            ([@get('data').g_c(E) * @get('data').f_F(E), E] for E in [@get('ymin')..@get('ymax')] by 0.001)
        ).property('data.g_c_changed', 'data.f_F_changed')
        
        p_points: (->
            ([@get('data').g_v(E) * (1 - @get('data').f_F(E)), E] for E in [@get('ymin')..@get('ymax')] by 0.01)
        ).property('data.g_v_changed', 'data.f_F_changed')
        
        plotRerender: (->
            @set 'plot', $.plot(@$(), [{
                label: "Electrons"
                data: @get('n_points')
            }, {
                label: "Holes"
                data: @get('p_points')
            }], @get('options'))
        ).observes('n_points', 'p_points')
        
    )
    
    
    FermiDiracGraphView: App.GraphView.extend(
        options: (->
            grid:
                hoverable: true
            yaxis:
                min: @get('ymin')
                max: @get('ymax')
            xaxis:
                min: -0.5
                max: 1.5
        ).property('ymin', 'ymax')

        points: (->
            ( [@get('data').f_F(x), x] for x in [@get('ymin')..@get('ymax')] by 0.01)
        ).property('data.f_F_changed', 'ymin', 'ymax')
        
        plotRerender: (->
            $.plot(@$(), [{
                label: "Fermi-Driac Function"
                data: @get('points')
            }], @get('options'))
        ).observes('points')
    )
)