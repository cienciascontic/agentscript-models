window.WaterControls =
  modelReady: false
  drawStyle: "draw"  # draw or fill
  wellType: "irrigation" # removal or irrigation
  patchType: "rock1"
  removeType: "layer"
  countOptions:
    x: 0
    y: 0
    dx: 50
    dy: 50
    debug: true
  graphOptions:
    xMin: 0
    xMax: 40
    yMin: 0
    yMax: 600
    initialValues: [0]
  localStoragePrefix: "water"
  setup: ->
    if ABM.model?
      $(".icon-pause").hide()
      $(".icon-play").show()
      if @modelReady
        $("#controls").show()
      else
        $("#controls").hide()
      # $("#draw-button").button()
      # .click =>
      #   $("#fill-button").click() if $("#fill-button")[0].checked
      #   if `this.checked`
      #     @drawStyle = "draw"
      #     @draw()
      #   else
      #     @stopDraw()
      $("#play-pause-button").button()
      .click =>
        @stopDraw(null, false)
        @startStopModel()
      $("#reset-button").button()
      .click =>
        @stopDraw()
        @resetModel()
      $("#playback").buttonset()
      $("#erase-button").button()
      .click =>
        @stopDraw("#erase-button")
        @erase()
      $("#fill-button").button()
      .click =>
        if `this.checked`
          @stopDraw("#fill-button")
          @drawStyle = "fill"
          @draw()
      $("#draw-button-set").buttonset()
      $("#draw-button-type-options").hide().menu
        select: (evt, ui)=>
          layerOption = ui.item.find(".layer-option")
          $("label[for='fill-button'] .layer-option").attr("class", layerOption.attr("class"))
          @setDrawType layerOption.prop('className').split(/\s+/)
          # automatically put us into fill mode when we select a layer type
          $("#fill-button").click() unless $("#fill-button")[0].checked
      $("#remove-button").button()
      .click =>
        if `this.checked`
          @stopDraw("#remove-button")
          switch @removeType
            when "layer" then @erase()
            when "water" then @removeWater()
            when "well" then @removeWell()
            else console.log("Invalid remove type: " + @removeType)
      $("#remove-button-set").buttonset()
      $("#remove-button-type-options").hide().menu
        select: (evt, ui)=>
          layerOption = ui.item.find(".remove-option")
          $("label[for='remove-button'] .remove-option").attr("class", layerOption.attr("class"))
          $("label[for='remove-button'] .remove-option img").replaceWith(layerOption.find("img").clone())
          @setRemoveType layerOption.prop('className').split(/\s+/)
          # automatically put us into fill mode when we select a layer type
          @stopDraw()
          $("#remove-button").click()
      $("#add-wells-button").button()
      .click =>
        if `this.checked`
          @stopDraw("#add-wells-button")
          @drill(@wellType)
      $("#add-wells-button-set").buttonset()
      $("#add-wells-button-type-options").hide().menu
        select: (evt, ui)=>
          wellOption = ui.item.find(".well-option")
          $("label[for='add-wells-button'] .well-option").attr("class", wellOption.attr("class"))
          $("label[for='add-wells-button'] .well-option img").replaceWith(wellOption.find("img").clone())
          @setWellType wellOption.prop('className').split(/\s+/)
          @stopDraw()
          $("#add-wells-button").click()

      $("#draw-button-type, #remove-button-type, #add-wells-button-type").button
        text: false
        icons:
          primary: "ui-icon-triangle-1-s"
      .click ->
        id = $(this).attr("id")
        menu = $("#" + id + "-options")
        if menu.is(":visible")
          menu.hide()
          return
        menu.show().position
          my: "left bottom"
          at: "right bottom"
          of: this
        # Set timeout is necessary, so we don't catch the same event and hide menu immediately.
        setTimeout(->
          $(document).off '.' + id
          $(document).one 'click.' + id, ->
            menu.hide()
        , 1)

      $('#follow-water-button').button(
        label: "Follow Water Droplet"
      ).click ->
        $span = $('#follow-water-button').find('span')
        if $span.text() is "Follow Water Droplet"
          ABM.model.addRainSpotlight()
          $span.text "Stop following"
        else
          ABM.model.removeSpotlight()
          $span.text "Follow Water Droplet"
      exportDataField = $("#exported-data")
      $("#export-button").button().click ->
        state = ImportExport.export(ABM.model)
        stateStr = JSON.stringify(state, null, 2)
        exportDataField.val(stateStr)
      $("#import-button").button().click ->
        if exportDataField.val()? and exportDataField.val().length > 0
          state = JSON.parse(exportDataField.val())
          ImportExport.import(ABM.model, state)
      $("#rain-slider").slider
        orientation: 'horizontal'
        min: 0
        max: 1
        step: 0.05
        value: 0.35
        slide: (evt, ui)->
          ABM.model.rainProbability = ui.value
        ABM.model.rainProbability = 0.35
      templateOptions = $('#template-options')
      templateOptions.change (evt)=>
        # FIXME There's got to be a better way to handle this
        switch templateOptions.val()
          when "state/hi-res/WaterModel-Gaining-Losing-Stream-StreamA.json"  then @graphOptions.initialValues = [28]
          when "state/low-res/WaterModel-Gaining-Losing-Stream-StreamA.json" then @graphOptions.initialValues = [28]
          when "state/hi-res/WaterModel-Gaining-Losing-Stream-StreamB.json"  then @graphOptions.initialValues = [5333]
          when "state/low-res/WaterModel-Gaining-Losing-Stream-StreamB.json" then @graphOptions.initialValues = [1120]
        ABM.model.setTemplate templateOptions.val()
        window.localStorage.setItem @localStoragePrefix + "-template", templateOptions.val()
        @resetModel(false)
      staticOptions = $('#static-options')
      staticOptions.change (evt)=>
        if WaterModelStaticLayers?
          WaterModelStaticLayers.background = staticOptions.val()
          window.localStorage.setItem @localStoragePrefix + "-background", staticOptions.val()
          ABM.model._setupPatches()
      irrigationWellButton = $("#irrigation-well-button")
      irrigationWellButton.button().click =>
        if irrigationWellButton[0]?.checked
          @stopDraw("#irrigation-well-button")
          @drill('irrigation')
      removalWellButton = $("#removal-well-button")
      removalWellButton.button().click =>
        if removalWellButton[0]?.checked
          @stopDraw("#removal-well-button")
          @drill('removal')
      removeWellButton = $("#remove-well")
      removeWellButton.button().click =>
        if removeWellButton[0]?.checked
          @stopDraw("#remove-well")
          @removeWell()
      addWaterButton = $("#water-button")
      addWaterButton.button().click =>
        if addWaterButton[0]?.checked
          @stopDraw("#water-button")
          @addWater()
      removeWaterButton = $("#remove-water-button")
      removeWaterButton.button().click =>
        if removeWaterButton[0]?.checked
          @stopDraw("#remove-water-button")
          @removeWater()

      if $('#output-graph').length > 0
        @setupGraph()

    else
      console.log("delaying...")
      setTimeout =>
        @setup()
      , 500

  outputGraph: null
  center: null
  setupGraph: ->
    outputOptions =
      title:  "Water Level"
      xlabel: "Time (years)"
      ylabel: "Water Level"
      xmax:   @graphOptions.xMax
      xmin:   @graphOptions.xMin
      ymax:   @graphOptions.yMax
      ymin:   @graphOptions.yMin
      xTickCount: 4
      yTickCount: 5
      xFormatter: "3.3r"
      realTime: false
      fontScaleRelativeToParent: true
      sampleInterval: 1/12
      dataColors: [
        [160,   0,   0],
        [ 44, 160,   0],
        [ 44,   0, 160],
        [  0,   0,   0],
        [255, 127,   0],
        [255,   0, 255]]

    @outputGraph = LabGrapher '#output-graph', outputOptions

    # start the graph with one line at 0,0
    @outputGraph.addSamples @graphOptions.initialValues

    @center = ABM.model.patches.patchXY @countOptions.x, @countOptions.y

    $(document).on WaterModel.MONTH_ELAPSED, =>
      count = ABM.model.rainCount @center, @countOptions.dx, @countOptions.dy, true, @countOptions.debug

      @outputGraph.addSamples [count]


  logAction: (action, data) ->
    # noop by default.
    # This function can be replaced by client code by something meaningful
    # (e.g. logging to the parent window).

  setDrawType: (colors = [])->
    if $.inArray("rock1", colors) > -1
      @patchType = "rock1"
    else if $.inArray("rock2", colors) > -1
      @patchType = "rock2"
    else if $.inArray("rock3", colors) > -1
      @patchType = "rock3"
    else if $.inArray("rock4", colors) > -1
      @patchType = "rock4"
    else if $.inArray("soil", colors) > -1
      @patchType = "soil"
    else
      console.log "Invalid layer option!", colors

  setRemoveType: (types = [])->
    if $.inArray("layer", types) > -1
      @removeType = "layer"
    else if $.inArray("water", types) > -1
      @removeType = "water"
    else if $.inArray("well", types) > -1
      @removeType = "well"
    else
      console.log "Invalid remove option!", types

  setWellType: (types = [])->
    if $.inArray("irrigation", types) > -1
      @wellType = "irrigation"
    else if $.inArray("removal", types) > -1
      @wellType = "removal"
    else
      console.log "Invalid well option!", types

  startType: null
  fillBelow: (x,y,points)->
    # also include all the points below this one, up to the first patch that is not the same type as the current patch
    @startType ||= ABM.model.patches.patchXY(x, y)?.type
    done = false
    for dy in [(y)..(ABM.model.patches.minY)]
      continue if done
      p = ABM.model.patches.patchXY x, dy
      if p.type is @startType
        points.push {x: x, y: dy}
      else
        done = true

  draw: ->
    target = $("#mouse-catcher")
    mouseDown = false
    cStart = null
    touchStart = null
    changedCount = 0
    actionStart = null
    drawEvt = (evt)=>
      if evt? and evt.preventDefault?
        evt.preventDefault()
      else
        window.event.returnValue = false
      return false unless mouseDown
      cEnd = ABM.model.patches.patchAtPixel @offsetX(evt, target), @offsetY(evt, target)
      points = []
      if cStart? and (cStart.x != cEnd.x or cStart.y != cEnd.y)
        # Paint all the patches in a line between this and the last patch red
        if cEnd.x != cStart.x
          m = (cEnd.y - cStart.y)/(cEnd.x - cStart.x)
        else
          m = 100000000 # something large enough that it will always round down
        for x in [(cStart.x)..(cEnd.x)]
          continue if x > ABM.model.patches.maxX or x < ABM.model.patches.minX
          pt = {x: x}
          pt.y = Math.round(m * (x - cEnd.x) + cEnd.y)  # point-slope form, solve for y
          continue if pt.y > ABM.model.patches.maxY or pt.y < ABM.model.patches.minY
          if @drawStyle is "fill"
            @fillBelow pt.x, pt.y, points
          else
            points.push pt
        if @drawStyle is "draw" and m != 0
          for y in [(cStart.y)..(cEnd.y)]
            continue if y > ABM.model.patches.maxY or y < ABM.model.patches.minY
            pt = {y: y}
            pt.x = Math.round((y - cEnd.y)/m + cEnd.x)  # point-slope form, solve for x
            continue if pt.x > ABM.model.patches.maxX or pt.x < ABM.model.patches.minX
            points.push pt
      else
        if @drawStyle is "fill"
          @fillBelow cEnd.x, cEnd.y, points
        else
          points.push cEnd
      wellsToRevalidate = []
      for c in points
        p = ABM.model.patches.patchXY c.x, c.y
        if p?
          if p.type != @patchType
            changedCount += 1
          p.type = @patchType
          if p.isWell
            wellsToRevalidate.push p.well
          ABM.model.patchChanged p # handles resetting the patch color
        else
          console.log("Failed to find patch for: (" + c.x + ", " + c.y + ")")
      @revalidateWells wellsToRevalidate
      ABM.model.refreshPatches = true
      ABM.model.draw()
      ABM.model.refreshPatches = false
      cStart = cEnd
      return false
    log = () =>
      @logAction('LayerAdded', {
        type: @patchType,
        points: changedCount,
        area: changedCount / ABM.model.getArea(),
        time: (Date.now() - actionStart) / 1000
      })
    target.show()
    target.css('cursor', 'url("img/cursor_add.cur"), default')
    target.bind 'mousedown touchstart', (evt)->
      mouseDown = true
      changedCount = 0
      if evt.originalEvent.touches?
        t = evt.originalEvent.touches[0]
        touchStart = document.elementFromPoint(t.pageX,t.pageY)
      drawEvt(evt)
      actionStart = Date.now()
    target.bind 'mouseup touchend', =>
      mouseDown = false
      cStart = null
      touchStart = null
      @startType = null
      if changedCount
        log()
        changedCount = 0
    target.bind 'mouseleave', (evt)=>
      drawEvt(evt)
      mouseDown = false
      cStart = null
      touchStart = null
      @startType = null
      if changedCount
        log()
        changedCount = 0
    target.bind 'mousemove', drawEvt
    target.bind 'touchmove', (evt)=>
      if touchStart?
        t = evt.originalEvent.touches[0]
        currTouch = document.elementFromPoint(t.pageX,t.pageY)
        drawEvt(evt)
        if touchStart isnt currTouch
          mouseDown = false
          cStart = null
          touchStart = null
          @startType = null


  erase: ->
    target = $("#mouse-catcher")
    target.show()
    target.css('cursor', 'url("img/new-cursors/remove.cur"), default')
    target.bind 'mousedown touchstart', (evt)=>
      # get the patch under the cursor,
      # find all the contiguous patches of the same type,
      # set them to the type of the first non-similar patch above them
      originalPatch = ABM.model.patches.patchAtPixel @offsetX(evt, target), @offsetY(evt, target)
      return unless originalPatch?
      originalPatchType = originalPatch.type
      return if originalPatchType is "sky"
      patches = [originalPatch]
      wellsToRevalidate = []
      fillTypes = {}
      findFillType = (p)->
        x = p.x
        return fillTypes[x] if fillTypes[x]
        for y in [(p.y)..(ABM.model.patches.maxY)]
          nextP = ABM.model.patches.patchXY(x,y)
          if nextP? and p.type isnt nextP.type
            fillTypes[x] = nextP.type
            return fillTypes[x]
        fillTypes[x] = "sky"
        return fillTypes[x]
      changedCount = 0
      while patches.length > 0
        patch = patches.shift()
        continue if patch.type isnt originalPatchType
        changedCount += 1
        fType = findFillType(patch)
        patch.type = fType
        if patch.isWell
          # add it to the list to revalidate
          wellsToRevalidate.push patch.well if wellsToRevalidate.indexOf(patch.well) == -1
        ABM.model.patchChanged patch # handles resetting the patch color
        for n in patch.n4
          if n? and n.type is originalPatchType
            patches.push n
      @revalidateWells wellsToRevalidate
      ABM.model.refreshPatches = true
      ABM.model.draw()
      ABM.model.refreshPatches = false
      @logAction("LayerRemoved", {type: originalPatchType, patches: changedCount, area: changedCount / ABM.model.getArea()})

  stopDraw: (source, alsoStopModel=true)->
    $("#fill-button").click() if source isnt "#fill-button" and $("#fill-button")[0]?.checked
    $("#add-wells-button").click() if source isnt "#add-wells-button" and $("#add-wells-button")[0]?.checked
    $("#remove-button").click() if source isnt "#remove-button" and $("#remove-button")[0]?.checked
    $("#erase-button").click() if source isnt "#erase-button" and $("#erase-button")[0]?.checked
    $("#irrigation-well-button").click() if source isnt "#irrigation-well-button" and $("#irrigation-well-button")[0]?.checked
    $("#removal-well-button").click() if source isnt "#removal-well-button" and $("#removal-well-button")[0]?.checked
    $("#remove-well").click() if source isnt "#remove-well" and $("#remove-well")[0]?.checked
    $("#water-button").click() if source isnt "#water-button" and $("#water-button")[0]?.checked
    $("#remove-water-button").click() if source isnt "#remove-water-button" and $("#remove-water-button")[0]?.checked
    @startStopModel() if alsoStopModel and not ABM.model.anim.animStop
    $("#mouse-catcher").hide()
    $("#mouse-catcher").css('cursor', '')
    $("#mouse-catcher").unbind('mouseup')
    $("#mouse-catcher").unbind('mousedown')
    $("#mouse-catcher").unbind('mousemove')
    $("#mouse-catcher").unbind('mouseleave')
    $("#mouse-catcher").unbind('touchend')
    $("#mouse-catcher").unbind('touchstart')
    $("#mouse-catcher").unbind('touchmove')
    clearInterval @timerId if @timerId?
    @timerId = null

  revalidateWells: (wellsToRevalidate)->
    for well in wellsToRevalidate
      well.remove() unless well.isValid()

  timerId: null
  drill: (type='irrigation')->
    target = $("#mouse-catcher")
    target.show()
    target.css('cursor', 'url("img/new-cursors/' + type + '.cur"), default')
    # Keep patch (coords in fact) in the outer scope so they can be reused by logging code.
    patch = null
    wellWasPresent = null
    shouldLog = false
    target.bind 'mousedown touchstart', (evt)=>
      return if @timerId?
      if evt? and evt.preventDefault?
        evt.preventDefault()
      else
        window.event.returnValue = false
      ABM.model.newWellType = switch type
        when "irrigation" then IrrigationWell
        else WaterRemovalWell
      wellWasPresent = null
      shouldLog = true
      @timerId = setInterval =>
        patch = ABM.model.patches.patchAtPixel(@offsetX(evt, target), @offsetY(evt, target))
        # Check whether well is present just once, at the beginning of drilling. Check explicitly if wellWasPresent
        # equals to null and make sure that null is not assigned to it (but true / false instead).
        wellWasPresent = ABM.model.findNearbyWell(patch) != null if wellWasPresent == null
        ABM.model.drill patch
      , 100
    .bind 'mouseup mouseleave touchend', =>
      clearInterval @timerId if @timerId?
      @timerId = null
      if shouldLog && patch?
        well = ABM.model.findNearbyWell(patch)
        if well
          actionName = if wellWasPresent then "#{well.type}WellModified" else "#{well.type}WellAdded"
          @logAction(actionName, {id: well.id, x: well.x, y: well.depth})
        # It's quite important, as this handler is also called on mouse leave => can be called multiple times.
        shouldLog = false


  removeWell: ->
    target = $("#mouse-catcher")
    target.show()
    target.css('cursor', 'url("img/new-cursors/remove-well.cur"), default')
    target.bind 'mousedown touchstart', (evt)=>
      # get the patch under the cursor,
      # check if there's a nearby well. If so, remove it.
      originalPatch = ABM.model.patches.patchAtPixel @offsetX(evt, target), @offsetY(evt, target)
      return unless originalPatch?
      well = ABM.model.findNearbyWell originalPatch
      if well?
        @logAction("#{well.type}WellRemoved", {id: well.id})
        well.remove()

  addWater: ->
    target = $("#mouse-catcher")
    lastWaterEvt = null
    mouseDown = false
    touchStart = null
    waterAdded = 0
    actionStart = null
    target.show()
    target.css('cursor', 'url("img/new-cursors/water.cur"), default')
    target.bind 'mousedown touchstart', (evt)=>
      return if @timerId?
      if evt? and evt.preventDefault?
        evt.preventDefault()
      else
        window.event.returnValue = false
      lastWaterEvt = evt
      mouseDown = true
      if evt.originalEvent.touches?
        t = evt.originalEvent.touches[0]
        touchStart = document.elementFromPoint(t.pageX,t.pageY)
      waterAdded = @_placeWater(evt, target)
      actionStart = Date.now()
      @timerId = setInterval =>
        waterAdded += @_placeWater(lastWaterEvt, target)
      , 10
    .bind 'mousemove touchmove', (evt)=>
      lastWaterEvt = evt if mouseDown
      if evt? and evt.preventDefault?
        evt.preventDefault()
      else
        window.event.returnValue = false
      if touchStart?
        t = evt.originalEvent.touches[0]
        currTouch = document.elementFromPoint(t.pageX,t.pageY)
        if currTouch isnt touchStart
          mouseDown = false
          clearInterval @timeId if @timeId?
          @timerId = null
          touchStart = null
      return false
    .bind 'mouseup mouseleave touchend', =>
      mouseDown = false
      clearInterval @timerId if @timerId?
      @timerId = null
      touchStart = null
      if waterAdded
        @logAction("WaterAdded", {patches: waterAdded, time: (Date.now() - actionStart) / 1000})
        waterAdded = 0

  removeWater: ->
    target = $("#mouse-catcher")
    lastWaterEvt = null
    mouseDown = false
    touchStart = null
    waterRemoved = 0
    actionStart = null
    target.show()
    target.css('cursor', 'url("img/new-cursors/remove-water.cur"), default')
    target.bind 'mousedown touchstart', (evt)=>
      return if @timerId?
      if evt? and evt.preventDefault?
        evt.preventDefault()
      else
        window.event.returnValue = false
      lastWaterEvt = evt
      mouseDown = true
      if evt.originalEvent.touches?
        t = evt.originalEvent.touches[0]
        touchStart = document.elementFromPoint(t.pageX,t.pageY)
      waterRemoved = @_removeWater(evt, target)
      actionStart = Date.now()
      @timerId = setInterval =>
        waterRemoved += @_removeWater(lastWaterEvt, target)
      , 10
    .bind 'mousemove touchmove', (evt)=>
      lastWaterEvt = evt if mouseDown
      if evt? and evt.preventDefault?
        evt.preventDefault()
      else
        window.event.returnValue = false
      if touchStart?
        t = evt.originalEvent.touches[0]
        currTouch = document.elementFromPoint(t.pageX,t.pageY)
        if currTouch isnt touchStart
          mouseDown = false
          clearInterval @timeId if @timeId?
          @timerId = null
          touchStart = null
      return false
    .bind 'mouseup mouseleave touchend', =>
      mouseDown = false
      clearInterval @timerId if @timerId?
      @timerId = null
      touchStart = null
      if waterRemoved
        @logAction("WaterRemoved", {patches: waterRemoved, time: (Date.now() - actionStart) / 1000})
        waterRemoved = 0

  _placeWater: (evt, target) ->
    p = ABM.model.patches.patchAtPixel(@offsetX(evt, target), @offsetY(evt, target))
    rect = ABM.model.patches.patchRect p, 5, 5, true
    for pa in ABM.util.shuffle(rect)
      if pa? and pa.agentsHere().length == 0
        ABM.model.rain.create 1, (drop) ->
          drop.moveTo pa
          ABM.model.draw()
        return 1
    return 0

  _removeWater: (evt, target)->
    p = ABM.model.patches.patchAtPixel(@offsetX(evt, target), @offsetY(evt, target))
    rect = ABM.model.patches.patchRect p, 5, 5, true
    removedWater = 0
    for pa in ABM.util.shuffle(rect)
      if pa? and (agents = pa.agentsHere()).length != 0
        for a in agents
          if a.breed is ABM.model.rain
            a.die()
            removedWater += 1
        ABM.model.draw()
        return removedWater
    return removedWater

  startStopModel: ->
    if ABM.model.anim.animStop
      ABM.model.start()
      $(".icon-pause").show()
      $(".icon-play").hide()
    else
      ABM.model.stop()
      $(".icon-pause").hide()
      $(".icon-play").show()

  resetModel: (passToModel=true)->
    ABM.model.reset() if passToModel
    $(".icon-pause").hide()
    $(".icon-play").show()

    if @outputGraph?
      @outputGraph.reset()
      @outputGraph.addSamples @graphOptions.initialValues

  getCanvasScaleX: ->
    $canvas = $("#layers canvas")
    $canvas.attr("width") / $canvas.width()

  getCanvasScaleY: ->
    $canvas = $("#layers canvas")
    $canvas.attr("height") / $canvas.height()

  offsetX: (evt, target)->
    scale = @getCanvasScaleX()
    if evt.originalEvent.touches?
      evt = evt.originalEvent.touches[0]
    val = if evt.offsetX? then evt.offsetX else (evt.pageX - target.offset().left)
    val * scale

  offsetY: (evt, target)->
    scale = @getCanvasScaleY()
    if evt.originalEvent.touches?
      evt = evt.originalEvent.touches[0]
    val = if evt.offsetY? then evt.offsetY else (evt.pageY - target.offset().top)
    val * scale

$(document).one 'model-ready', ->
  WaterControls.modelReady = true
  $("#controls").show()
$(document).trigger('controls-ready')
