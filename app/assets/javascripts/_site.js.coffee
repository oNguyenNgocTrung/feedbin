window.feedbin ?= {}

$.extend feedbin,

  showNotification: (text, timeout = 3000, href = '', error = false) ->
    messages = $('[data-behavior~=messages]')
    if error == true
      messages.addClass('error')
    else
      messages.removeClass('error')

    if href == ''
      messages.removeAttr('href')
    else
      messages.attr('href', href)

    messages.text(text)
    messages.addClass('show')
    setTimeout ( ->
      messages.removeClass('show')
    ), timeout

  updateEntries: (entries, header) ->
    $('.entries ul').html(entries)
    $('.entries-header').html(header)

  appendEntries: (entries, header) ->
    $('.entries ul').append(entries)
    $('.entries-header').html(header)

  updatePager: (html) ->
    $('[data-behavior~=pagination]').html(html)

  updateEntryContent: (html) ->
    feedbin.closeEntryBasement(0)
    $('[data-behavior~=entry_content_target]').html(html)

  modalBox: (html) ->
    $('.modal-target').html(html)
    $('.modal').modal
      backdrop: false
    feedbin.modalShowing = true

  updateFeeds: (feeds) ->
    $('[data-behavior~=feeds_target]').html(feeds)

  clearEntries: ->
    $('[data-behavior~=entries_target]').html('')

  clearEntry: ->
    feedbin.updateEntryContent('')

  syntaxHighlight: ->
    $('[data-behavior~=entry_content_target] pre code').each (i, e) ->
      hljs.highlightBlock(e)

  footnotes: ->
    $.bigfoot
      scope: '[data-behavior~=entry_content_wrap]'
      actionOriginalFN: 'ignore'

  tableWrap: ->
    $('[data-behavior~=entry_content_wrap] table').wrap($('<div>', {class: 'table-wrap'}));

  hideTagsForm: (form) ->
    if not form
      form = $('.tags-form-wrap')
    form.animate
      height: 0

  blogContent: (content) ->
    content = $.parseJSON(content)
    $('.blog-post').text(content.title);
    $('.blog-post').attr('href', content.url);

  precacheImages: (data) ->
    if feedbin.data.precacheImages == true && feedbin.data.mobile == false
      entries = []
      $.each data, (index, entry) ->
        if entry.read == false
          entries.push(entry.content)
      $(entries.join())

  localizeTime: (container) ->
    $('time', container).each ->
      date = $(@).attr('datetime')
      format = $(@).data('format') || 'long'
      if date && format != 'none'
        date = new Date(date)
        if format == 'long'
          $(@).text(date.format("%B %e, %Y at %l:%M %p"))
        else if format == 'time'
          $(@).text(date.format("%l:%M %p"))
        else if format == 'day'
          $(@).text(date.format("%e %b"))
        else if format == 'day_year'
          $(@).text(date.format("%e %b %Y"))

  applyUserTitles: ->
    $('[data-behavior~=user_title]').each ->
      index = $(@).data('feed-id')
      newTitle = feedbin.data.userTitles[index]
      $(@).text(newTitle)

  queryString: (name) ->
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]")
    regexS = "[\\?&]" + name + "=([^&#]*)"
    regex = new RegExp(regexS)
    results = regex.exec(window.location.search)
    if results?
      decodeURIComponent results[1].replace(/\+/g, " ")
    else
      null

  openLinkInBackground: (href) ->
    anchor = document.createElement("a")
    anchor.href = href
    event = document.createEvent("MouseEvents")
    event.initMouseEvent "click", true, true, window, 0, 0, 0, 0, 0, true, false, false, true, 0, null
    anchor.dispatchEvent event

  updateTitle: (title) ->
    docTitle = $('title')
    docTitle.text(title) unless docTitle.text() is title

  autocomplete: (element) ->
    element.autocomplete
      serviceUrl: feedbin.data.tagsPath
      appendTo: $(element).closest(".tags-form").children("[data-behavior=tag_completions]")
      delimiter: /(,)\s*/

  autoHeight: ->
    windowHeight = $(window).height()
    controlsHeight = $('.collection-edit-controls').outerHeight()
    collectionOffset = $('.collection-edit-wrapper').offset().top
    collectionHeight = windowHeight - controlsHeight - collectionOffset
    $('.collection-edit-wrapper').css({'max-height': "#{collectionHeight}px"})

  entries: {}

  preloadEntries: (entry_ids) ->
    cachedIds = []
    for key of feedbin.entries
      cachedIds.push key * 1
    entry_ids = _.difference(entry_ids, cachedIds)
    if entry_ids.length > 0
      $.getJSON feedbin.data.preloadEntriesPath, {ids: entry_ids.join(',')}, (data) ->
        $.extend feedbin.entries, data
        feedbin.precacheImages(data)

  updateReadCount: (id, entry, target) ->
    if entry.read == false
      $.post $(target).data('mark-as-read-path')
      feedbin.recentlyReadTimer = setTimeout ( ->
        $.post $(target).data('recently-read-path')
      ), 10000
      feedbin.CountInstance.updateCount(entry.feed_id, entry.tags, 'decrement')
      $("[data-entry-id=#{id}]").addClass('read')
      feedbin.entries[id].read = true

      if feedbin.data.showUnreadCount
        count = $('[data-behavior~=all_unread]').find('.count').text() * 1
        if count == 0
          title = "Feedbin"
        else if count >= 1000
          title = "Feedbin (1,000+)"
        else
          title = "Feedbin (#{count})"

        feedbin.updateTitle(title)

  readability: (target) ->
    feedId = $('[data-feed-id]', target).data('feed-id')
    if feedbin.data.readabilitySettings[feedId] == true && feedbin.data.stickyReadability
      $('.button-toggle-content').find('span').addClass('active')
      $('[data-behavior~=entry_content_wrap]').html('Loading Readability&hellip;')
      $('[data-behavior~=toggle_content_view]').submit()

  formatEntryContent: (resetScroll = true, currentItem = null) ->
    if resetScroll
      $('.entry-content').prop('scrollTop', 0)
    $('[data-behavior~=entry_content_target]').fitVids({ customSelector: "iframe[src*='youtu.be'], iframe[src*='www.flickr.com'], iframe[src*='view.vzaar.com']"});
    feedbin.syntaxHighlight()
    feedbin.footnotes()
    feedbin.nextEntryPreview(currentItem)

  refresh: ->
    if feedbin.data
      $.get(feedbin.data.autoUpdatePath)

  shareOpen: ->
    $('[data-behavior~=toggle_share_menu]').parents('.dropdown-wrap').hasClass('open')

  updateFontSize: (direction) ->
    fontContainer = $("[data-font-size]")
    currentFontSize = fontContainer.data('font-size')
    if direction == 'increase'
      newFontSize = currentFontSize + 1
    else
      newFontSize = currentFontSize - 1
    if feedbin.data.fontSizes[newFontSize]
      fontContainer.removeClass("font-size-#{currentFontSize}")
      fontContainer.addClass("font-size-#{newFontSize}")
      fontContainer.data('font-size', newFontSize)

  matchHeights: (elements) ->
    height = 0
    $.each elements, (index, element) ->
      $(element).css({'height': ''})
      outerHeight = $(element).outerHeight()
      if outerHeight > height
        height = outerHeight

    elements.css
      height: height

  disableMarkRead: () ->
    feedbin.markReadData = {}
    $('[data-behavior~=mark_all_as_read]').attr('disabled', 'disabled')

  markRead: () ->
    $('.entries li').addClass('read')
    feedbin.markReadData.ids = $('.entries li').map(() ->
      $(@).data('entry-id')
    ).get().join()
    $.post feedbin.data.markAsReadPath, feedbin.markReadData

  checkPushPermission: (permissionData) ->
    if (permissionData.permission == 'default')
      $('body').removeClass('push-on')
      $('body').removeClass('push-disabled')
      $('body').addClass('push-off')
    else if (permissionData.permission == 'granted')
      $('body').removeClass('push-off')
      $('body').removeClass('push-disabled')
      $('body').addClass('push-on')
    else if (permissionData.permission == 'denied')
      $('body').removeClass('push-on')
      $('body').removeClass('push-off')
      $('body').addClass('push-disabled')

  toggleFullScreen: ->
    $('body').toggleClass('full-screen')

  isFullScreen: ->
    $('body').hasClass('full-screen')

  nextEntry: ->
    nextEntry = $('.entries').find('.selected').next()
    if nextEntry.length
      nextEntry
    else
      null

  nextEntryPreview: (current) ->
    next = $(current).parents('li').next()
    if next.length
      title = next.find('.title').text()
      feed = next.find('.feed-title').text()
      $('.next-entry-title').text(title)
      $('.next-entry-feed').text(feed)
      $('.next-entry-preview').removeClass('no-content')

  showSubscribe: ->
    $('.subscribe-wrap input').val('')
    $('.subscribe-wrap input').focus()
    $('.feeds-inner').addClass('show-subscribe')
    $('.subscribe-wrap').addClass('open')

  hideSubscribe: ->
    $('.feeds-inner').removeClass('show-subscribe')
    $('.subscribe-wrap').removeClass('open')

  getSelectedText: ->
    text = ""
    if (window.getSelection)
      text = window.getSelection().toString();
    else if (document.selection && document.selection.type != "Control")
      text = document.selection.createRange().text;
    text

  scrollTo: (item, container) ->
    item.offset().top - container.offset().top + container.scrollTop()

  sortByLastUpdated: (a, b) ->
    aTimestamp = $(a).data('sort-last-updated') * 1
    bTimestamp = $(b).data('sort-last-updated') * 1
    return bTimestamp - aTimestamp

  sortByName: (a, b) ->
    $(a).data('sort-name').localeCompare($(b).data('sort-name'))

  showSearchControls: (sort) ->
    $('.search-control').removeClass('hide');
    text = null
    if sort
      text = $("[data-sort-option=#{sort}]").text()
    if !text
      text = $("[data-sort-option=desc]").text()
    $('.sort-order').text(text)
    $('.entries').addClass('show-search-options')

  hideSearchControls: ->
    $('.search-control').addClass('hide');
    $('.entries').removeClass('show-search-options')
    $('.entries').removeClass('show-saved-search')
    $('.saved-search-wrap').removeClass('open')

  drawBarChart: (canvas, values) ->
    if values
      spaceWidth = 2
      numberOfSpaces = values.length - 1
      barWidth = (canvas.width - numberOfSpaces * spaceWidth) / values.length
      if canvas.getContext
        context = canvas.getContext("2d")
        context.fillStyle = "#DDDDDD"
        xPosition = 0
        for value in values
          height = Math.ceil(value * canvas.height)
          yPosition = canvas.height - height
          context.fillRect(xPosition, yPosition, barWidth, height)
          xPosition = xPosition + barWidth + spaceWidth

  readabilityActive: ->
    $('[data-behavior~=toggle_content_view]').find('.active').length > 0

  prepareShareForm: ->
    $('.field-cluster input, .field-cluster textarea').val('')
    $('.share-controls [type="checkbox"]').attr('checked', false);

    title = $('.entry-header h1').first().text()
    $('.share-form .title-placeholder').val(title)

    url = $('.entry-header a').first().attr('href')
    $('.share-form .url-placeholder').val(url)

    description = feedbin.getSelectedText()
    $('.share-form .description-placeholder').val(description)

    if feedbin.readabilityActive()
      $('.readability-placeholder').val('on')
    else
      $('.readability-placeholder').val('off')


  sharePopup: (url) ->
    windowOptions = 'scrollbars=yes,resizable=yes,toolbar=no,location=yes'
    width = 620
    height = 590
    winHeight = screen.height
    winWidth = screen.width
    left = Math.round((winWidth / 2) - (width / 2));
    top = 0;
    if (winHeight > height)
      top = Math.round((winHeight / 2) - (height / 2))
    window.open(url, 'intent', "#{windowOptions},width=#{width},height=#{height},left=#{left},top=#{top}")

  closeEntryBasement: (timeout = 200) ->
    feedbin.closeEntryBasementTimeount = setTimeout ( ->
      $('.basement-panel').addClass('hide')
      $('.field-cluster input').blur()
    ), timeout

    clearTimeout(feedbin.openEntryBasementTimeount)
    $('.entry-basement').removeClass('foreground')
    top = $('.entry-toolbar').outerHeight()
    $('.entry-basement').removeClass('open')
    $('.entry-content').css
      top: top

  openEntryBasement: (selectedPanel) ->
    feedbin.openEntryBasementTimeount = setTimeout ( ->
      $('.entry-basement').addClass('foreground')
      $('.field-cluster input', selectedPanel).first().select()
    ), 200

    clearTimeout(feedbin.closeEntryBasementTimeount)

    feedbin.prepareShareForm()

    $('.basement-panel').addClass('hide')
    selectedPanel.removeClass('hide')
    $('.entry-basement').addClass('open')
    newTop = $('.entry-toolbar').outerHeight() + selectedPanel.height()
    $('.entry-content').css
      top: newTop

  hideQueue: []

  feedCandidates: []

  modalShowing: false

  images: []

  feedXhr: null

  markReadData: {}

  closeSubcription: false

  player: null

  recentlyReadTimer: null

$.extend feedbin,
  init:
    setData: ->
      feedbin.data = $('#feedbin-data').data()

    hasTouch: ->
      if ('ontouchstart' in document)
        $('body').addClass('touch')

    changeSearchSort: (sort) ->
      $(document).on 'click', '[data-sort-option]', ->
        sortOption = $(@).data('sort-option')
        searchField = $('#query')
        query = searchField.val()
        query = query.replace(/\s*?(sort:\s*?asc|sort:\s*?desc|sort:\s*?relevance)\s*?/, '')
        query = "#{query} sort:#{sortOption}"
        searchField.val(query)
        searchField.parents('form').submit()

    markRead: ->
      $(document).on 'click', '[data-mark-read]', ->
        feedbin.markReadData = $(@).data('mark-read')
        $('[data-behavior~=mark_all_as_read]').removeAttr('disabled')
        return

      $(document).on 'click', '[data-behavior~=mark_all_as_read]', ->
        unless $(@).attr('disabled')
          $('.entries li').map ->
            entry_id = $(@).data('entry-id') * 1
            if entry_id of feedbin.entries
              feedbin.entries[entry_id].read = true

          if feedbin.data.markAsReadConfirmation
            result = confirm(feedbin.markReadData.message)
            if result
              feedbin.markRead()
          else
            feedbin.markRead()
        return

    selectable: ->
      $(document).on 'click', '[data-behavior~=selectable]', ->
        $(@).parents('ul').find('.selected').removeClass('selected')
        $(@).parent('li').addClass('selected')
        return

    choicesSubmit: ->
      $(document).on 'ajax:beforeSend', '[data-choice-form]', ->
        $('.modal').modal('hide')
        return

    openEntry: ->
      $(document).on 'ajax:complete', '[data-behavior~=reset_entry_content_position]', ->
        feedbin.formatEntryContent(true, @)
        return

    entryLinks: ->
      $(document).on 'click', '[data-behavior~=entry_content_wrap] a', ->
        $(this).attr('target', '_blank')
        return

    clearEntry: ->
      $(document).on 'ajax:beforeSend', '[data-behavior~=show_entries]', (event) ->
        unless $(event.target).is('.toggle-drawer')
          feedbin.clearEntry()
        return

    cancelFeedRequest: ->
      $(document).on 'ajax:beforeSend', '[data-behavior~=show_entries]', (event, xhr) ->
        if feedbin.feedXhr
          feedbin.feedXhr.abort()
        feedbin.feedXhr = xhr
        return

    tooltips: ->
      $(document).on 'mouseenter mouseleave', '[data-behavior~=tooltip]', (event) ->
        tooltip = $(this).tooltip
          delay: 0
          animation: false
        if 'mouseenter' == event.type
          tooltip.tooltip('show')
        else
          tooltip.tooltip('hide')
        return

    loadEntries: ->
      $('[data-behavior~=feeds_target] > li:first-child [data-behavior~=open_item]').click() unless $('body').hasClass('mobile')

    tagsForm: ->
      $(document).on 'click', (event) ->
        target = $(event.target)
        if not target.hasClass('toolbar-button')
          target = target.parents('.toolbar-button')
        wrap = target.find('.tags-form-wrap')
        feedbin.hideTagsForm($('.tags-form-wrap').not(wrap))
        return

      $(document).on 'click', '[data-behavior~=show_tags_form]', (event) ->
        target = $(event.target)
        if not target.hasClass('toolbar-button')
          target = target.parentsUntil('.toolbar-button')
        wrap = target.find('.tags-form-wrap')
        unless $(@).attr('disabled') == 'disabled'
          if '0px' == wrap.css('height')
            wrap.animate {
              height: '138px'
            }, 200
            field = wrap.find('.feed_tag_list')
            field.focus()
            value = field.val()
            field.val(value)
            feedbin.autocomplete(field)
        return

    resize: () ->
      defaults =
        handles: "e"
        minWidth: 200
        stop: (event, ui) ->
          form = $('[data-behavior~=resizable_form]')
          $('[name=column]', form).val($(ui.element).data('resizable-name'))
          $('[name=width]', form).val(ui.size.width)
          form.submit()
          return
      $('.feeds-column').resizable($.extend(defaults))
      $('.entries-column').resizable($.extend(defaults))

    processHideQueue: ->
      $(document).on 'click', '[data-behavior~=show_entries]', ->
        $.each feedbin.hideQueue, (i, feed_id) ->
          if feed_id != undefined && feed_id != "collection_all" && feed_id != "collection_unread"
            item = $("[data-feed-id=#{feed_id}]", '.feeds')
            $(item).hide 'fast', () ->
              $(item).remove()
              feedbin.hideQueue.remove(i)
        feedbin.hideQueue = []
        return

    feedCandidates: ->
      $(document).on 'click', '[data-behavior~=show_entries]', ->
        clickedItem = $(@).parents 'li'
        feedbin.feedCandidates = []
        feedbin.feedCandidates.push clickedItem.next().data('feed-id') if clickedItem.next().length
        feedbin.feedCandidates.push clickedItem.prev().data('feed-id') if clickedItem.prev().length
        return

    unauthorizedResponse: ->
      $(document).on 'ajax:complete', (event, response, status) ->
        if response.status == 401
          document.location = feedbin.data.loginUrl
        return

    screenshotTabs: ->
      $('[data-behavior~=screenshot_nav] li').first().addClass('active')
      $(document).on 'click', '[data-behavior~=screenshot_nav] a', (event) ->
        $('[data-behavior~=screenshot_nav] li').removeClass('active')
        $(@).parent('li').addClass('active')
        src = $(@).find('img').attr('src')
        $("[data-behavior~=screenshots] img").addClass('hide')
        $("[data-behavior~=screenshots] img[src='#{src}']").removeClass('hide')
        event.preventDefault()
        return

      $(document).on 'click', '[data-behavior~=screenshot_previous], [data-behavior~=screenshot_next]', (event) ->
        selectedScreenshot = $('[data-behavior~=screenshot_nav] li.active')
        button = $(event.target).data('behavior')
        if button.match(/screenshot_next/)
          nextScreenshot = selectedScreenshot.next()
          if nextScreenshot.length == 0
            nextScreenshot = $('li:first-child', $('[data-behavior~=screenshot_nav]'))
        else
          nextScreenshot = selectedScreenshot.prev()
          if nextScreenshot.length == 0
            nextScreenshot = $('li:last-child', $('[data-behavior~=screenshot_nav]'))

        nextScreenshot.find('a').click()
        event.preventDefault()
        return


    feedSelected: ->
      $(document).on 'click', '[data-behavior~=back_to_feeds]', ->
        $('body').addClass('nothing-selected').removeClass('feed-selected entry-selected')
        return

      $(document).on 'click', '[data-behavior~=show_entries]', (event) ->
        $('body').addClass('feed-selected').removeClass('nothing-selected entry-selected')
        return

      $(document).on 'click', '[data-behavior~=show_entry_content]', ->
        $('body').addClass('entry-selected').removeClass('nothing-selected feed-selected')
        return

    addFields: ->
      $(document).on 'click', '[data-behavior~=add_fields]', (event) ->
        time = new Date().getTime() + '_insert'
        regexp = new RegExp($(@).data('id'), 'g')
        $('[data-behavior~=add_fields_target]').find('tr:first').before($(@).data('fields').replace(regexp, time))
        event.preventDefault()
        return

    removeFields: ->
      $(document).on 'click', '[data-behavior~=remove_fields]', (event) ->
        $(@).prev('input[type=hidden]').val(1)
        $(@).closest('tr').addClass('hide')
        event.preventDefault()
        return

    dropdown: ->
      $(document).on 'click', (event) ->
        dropdown = $('.dropdown-wrap')
        unless $(event.target).is('[data-behavior~=toggle_dropdown]') || $(event.target).parents('[data-behavior~=toggle_dropdown]').length > 0
          dropdown.removeClass('open')
        return

      $(document).on 'click', '[data-behavior~=share_options] a', (event) ->
        $('.dropdown-wrap').removeClass('open')

      $(document).on 'click', '[data-behavior~=toggle_share_menu]', (event) ->
        $(".dropdown-wrap li").removeClass('selected')
        parent = $(@).closest('.dropdown-wrap')
        if parent.hasClass('open')
          parent.removeClass('open')
        else
          parent.addClass('open')
        event.preventDefault()
        return

      $(document).on 'mouseover', '.dropdown-wrap li', (event) ->
        $('.dropdown-wrap li').not(@).removeClass('selected')
        return

    drawer: ->
      $(document).on 'click', '[data-behavior~=toggle_drawer]', (event) =>
        button = $(event.currentTarget)
        drawer = button.parents('li').find('.drawer')

        if drawer.data('hidden') == true
          height = $('ul', drawer).height() + 2
          hidden = false
          text = 'hide'
        else
          height = 0
          hidden = true
          text = 'show'

        drawer.animate {
          height: height
        }, 200, ->
          if height > 0
            drawer.css
              height: 'auto'

        drawer.data('hidden', hidden)
        button.text(text)

        button.parent('form').submit()
        event.stopPropagation()
        event.preventDefault()
        return

    checkBoxToggle: ->
      $(document).on 'click', '[data-behavior~=check_all]', (event) =>
        $('[type="checkbox"]').prop('checked', true)
        event.preventDefault()
        return

      $(document).on 'click', '[data-behavior~=check_none]', (event) =>
        $('[type="checkbox"]').prop('checked', false)
        event.preventDefault()
        return

      $(document).on 'click', '[data-behavior~=check_feeds]', (event) ->
        cell = $(@).parents('[data-behavior~=associated_record]')
        feedIds = $('.feed-ids', cell)
        if $(@).is(':checked')
          $('[type="checkbox"]', feedIds ).prop('checked', true)
          $('[type="checkbox"]', feedIds ).attr('disabled', 'disabled')
        else
          $('[type="checkbox"]', feedIds ).prop('checked', false)
          $('[type="checkbox"]', feedIds ).removeAttr('disabled')
        return

    validateFile: ->
      form = $('.new_import_uploader')
      input = form.find("input:file")
      unless input.val()
        form.find('[type=submit]').attr('disabled','disabled')

      input.on 'change', ()->
        if $(this).val()
          form.find('[type=submit]').removeAttr('disabled')
        return

    autoHeight: ->
      if $('.collection-edit-wrapper').length
        feedbin.autoHeight()
        $(window).on 'resize', () ->
          feedbin.autoHeight()
          return

    usePreloadContent: ->
      $(document).on 'ajax:beforeSend', '[data-behavior~=open_item]', (event, xhr) ->
        clearTimeout feedbin.recentlyReadTimer
        id = $(@).parents('li').data('entry-id')
        entry = feedbin.entries[id]
        if entry
          xhr.abort()
          feedbin.updateEntryContent(entry.content)
          feedbin.formatEntryContent(true, @)
          feedbin.localizeTime($('[data-behavior~=entry_content_target]'))
          feedbin.applyUserTitles()
          feedbin.updateReadCount(id, entry, @)
          feedbin.readability(@)
        return

    timeago: ->
      strings =
        prefixAgo: null
        prefixFromNow: null
        suffixAgo: ""
        suffixFromNow: "from now"
        seconds: "less than 1 min"
        minute: "1m"
        minutes: "%dm"
        hour: "1h"
        hours: "%dh"
        day: "1d"
        days: "%dd"
        month: "a month"
        months: "%d months"
        year: "a year"
        years: "%d years"
        wordSeparator: " "
        numbers: []
      jQuery.timeago.settings.strings = strings
      jQuery.timeago.settings.allowFuture = true
      $("time.timeago").timeago()
      return

    updateReadability: ->
      $(document).on 'ajax:beforeSend', '[data-behavior~=toggle_content_view]', (event, xhr) ->
        feedId = $(event.currentTarget).data('feed-id')
        if feedbin.data.stickyReadability && feedbin.data.readabilitySettings[feedId] != "undefined"
          unless $("#content_view").val() == "true" && feedbin.data.readabilitySettings[feedId] == true
            feedbin.data.readabilitySettings[feedId] = !feedbin.data.readabilitySettings[feedId]
        return

    removePreload: ->
      # Just delete the preloaded entry when something gets starred
      $(document).on 'ajax:beforeSend', '[data-behavior~=toggle_starred]', (event, xhr) ->
        entryId = $(event.currentTarget).data('entry-id')
        delete feedbin.entries[entryId]
        return

    updateRead: ->
      $(document).on 'ajax:beforeSend', '[data-behavior~=toggle_read]', (event, xhr) ->
        entryId = $(event.currentTarget).data('entry-id')
        if feedbin.entries[entryId]
          feedbin.entries[entryId].read = !feedbin.entries[entryId].read
        return

    autoUpdate: ->
      setInterval ( ->
        feedbin.refresh()
      ), 300000

    entryBasement: ->

      $(document).on 'click', (event, xhr) ->
        if ($(event.target).hasClass('entry-basement') || $(event.target).parents('.entry-basement').length > 0)
          false

        if !$(event.target).is('[data-behavior~=show_entry_basement]') && $(event.target).parents('.entry-basement').length == 0
          feedbin.closeEntryBasement()
        return

      $(document).on 'click', '[data-behavior~=show_entry_basement]', (event, xhr) ->
        panelName = $(@).data('basement-panel')
        selectedPanel = $("[data-basement-panel-target=#{panelName}]")

        if $('.entry-basement').hasClass('open')
          if selectedPanel.hasClass('hide')
            # There is another panel open, transition to the clicked on panel
            feedbin.closeEntryBasement()
            feedbin.openEntryBasement(selectedPanel)
          else
            # The clicked on panel is alread open, close it
            feedbin.closeEntryBasement()
        else
          feedbin.openEntryBasement(selectedPanel)

        event.preventDefault()
        return

      $(document).on 'click', '[data-behavior~=close_entry_basement]', (event, xhr) ->
        feedbin.closeEntryBasement()
        event.preventDefault()
        return

      $(document).on 'submit', '.share-form form', (event, xhr) ->
        feedbin.closeEntryBasement()
        return

    supportedSharing: ->
      $(document).on 'click', '.button-toggle-share-menu [data-behavior~=show_entry_basement]', (event, xhr) ->
        panelName = $(@).data('basement-panel')
        selectedPanel = $("[data-basement-panel-target=#{panelName}]")
        $('form', selectedPanel).attr('action', $(@).attr('href'))

    formatToolbar: ->
      $('[data-behavior~=change_font]').val($("[data-font]").data('font'))
      $('[data-behavior~=change_font]').change ->
        fontContainer = $("[data-font]")
        currentFont = fontContainer.data('font')
        fontContainer.removeClass("font-#{currentFont}")
        fontContainer.addClass("font-#{$(@).val()}")
        fontContainer.data('font', $(@).val())
        $(@).parents('form').submit()

    feedSettings: ->
      $('[data-behavior~=sort_feeds]').change ->
        sortBy = $(@).val()
        if sortBy == "name"
          sortFunction = feedbin.sortByName
        else if sortBy == "last-updated"
          sortFunction = feedbin.sortByLastUpdated
        $('.sortable li').sort(sortFunction).appendTo('.sortable');
      return

    fontSize: ->
      $(document).on 'click', '[data-behavior~=increase_font]', (event) ->
        feedbin.updateFontSize('increase')
        return

      $(document).on 'click', '[data-behavior~=decrease_font]', (event) ->
        feedbin.updateFontSize('decrease')
        return

    entryWidth: ->
      $(document).on 'click', '[data-behavior~=entry_width]', (event) ->
        $('[data-behavior~=entry_content_target]').toggleClass('fluid')
        return

    fullscreen: ->
      $(document).on 'click', '[data-behavior~=full_screen]', (event) ->
        feedbin.toggleFullScreen()
        feedbin.closeEntryBasement()
        event.preventDefault()
        return

    theme: ->
      $(document).on 'click', '[data-behavior~=switch_theme]', (event) ->
        $('body').toggleClass('theme-night')
        event.preventDefault()
        return

    filterList: ->
      feedbin.matchHeights($('.app-detail'))
      $(window).on 'resize', () ->
        feedbin.matchHeights($('.app-detail'))
        return

      $(document).on 'click', '[data-filter]', (event) ->
        $('[data-filter]').removeClass('active')
        $(@).addClass('active')

        filter = $(@).data('filter')
        if filter == 'all'
          $("[data-platforms]").removeClass('hide')
        else
          $("[data-behavior~=filter_target]").addClass('hide')
          $("[data-platforms~=#{filter}]").removeClass('hide')
        return

    showEntryActions: ->
      $(document).on 'click', '[data-behavior~=show_entry_actions]', (event) ->
        parent = $(@).parents('li')
        if parent.hasClass('show-actions')
          $('.entries li').removeClass('show-actions')
        else
          $('.entries li').removeClass('show-actions')
          parent.addClass('show-actions')
        event.preventDefault()
        event.stopPropagation()
        return

      $(document).on 'click', (event) ->
        $('.entries li').removeClass('show-actions')
        return

      $(document).on 'click', '[data-behavior~=show_entry_content]', (event) ->
        unless $(event.target).is('[data-behavior~=show_entry_actions]')
          $('.entries li').removeClass('show-actions')
        return

    markDirectionAsRead: ->
      $(document).on 'click', '[data-behavior~=mark_below_read], [data-behavior~=mark_above_read]', (event) ->
        data = feedbin.markReadData
        if data
          data['ids'] = $(@).parents('li').prevAll().map(() ->
            $(@).data('entry-id')
          ).get().join()

          if $(@).is('[data-behavior~=mark_below_read]')
            $(@).parents('li').nextAll().addClass('read')
            data['direction'] = 'below'
          else
            $(@).parents('li').prevAll().addClass('read')
            data['direction'] = 'above'

        $.post feedbin.data.markDirectionAsReadEntries, data
        return

    formProcessing: ->
      $(document).on 'submit', '[data-behavior~=subscription_form], [data-behavior~=search_form]', ->
        $(@).find('input').addClass('processing')
        return

      $(document).on 'ajax:complete', '[data-behavior~=subscription_form], [data-behavior~=search_form]', ->
        $(@).find('input').removeClass('processing')
        if feedbin.closeSubcription
          setTimeout ( ->
            feedbin.hideSubscribe()
          ), 600
          feedbin.closeSubcription = false
        return

    subscribe: ->
      $(document).on 'click', '[data-behavior~=show_subscribe]', (event) ->
        feeds = $(".feeds-inner")
        if feeds.hasClass('show-subscribe')
          feedbin.hideSubscribe()
        else
          feedbin.showSubscribe()
        return

      $(document).on 'click', (event) ->
        unless $(event.target).is('[data-behavior~=show_subscribe]') || $(event.target).is('.subscribe-wrap') || $(event.target).parents('.subscribe-wrap').length > 0
          feedbin.hideSubscribe()

      subscription = feedbin.queryString('subscribe')
      if subscription?
        $('[data-behavior~=show_subscribe]').click()
        $('[data-behavior~=subscription_form] input').val(subscription)
        $('[data-behavior~=subscription_form]').submit()
        $('[data-behavior~=subscription_form] input').blur()
        feedbin.closeSubcription = true

    searchError: ->
      $(document).on 'ajax:error', '[data-behavior~=search_form]', (event, xhr) ->
        feedbin.showNotification('Search error.');
        return

    savedSearch: ->
      $(document).on 'click', '[data-behavior~=save_search_link]', ->
        query = $('#query').val()
        $('#saved_search_query').val(query)
        $('.entries').toggleClass('show-saved-search')
        $('.saved-search-wrap').toggleClass('open')
        $('#saved_search_name').focus()
        return

      $(document).on 'click', '[data-behavior~=feed_link]:not(.saved-search-link)', ->
        $('#query').val('')

    showPushOptions: ->
      if "safari" of window and "pushNotification" of window.safari
        $('body').addClass('supports-push')
        if $('#push-data').length > 0
          $('.push-options').removeClass('hide')
          data = $('#push-data').data()
          permissionData = window.safari.pushNotification.permission(data.websiteId)
          feedbin.checkPushPermission(permissionData )

    enablePush: ->
      $(document).on 'click', '[data-behavior~=enable_push]', (event) ->
        data = $('#push-data').data()
        window.safari.pushNotification.requestPermission(data.webServiceUrl, data.websiteId, {authentication_token: data.authenticationToken}, feedbin.checkPushPermission)
        event.preventDefault()
        return

    deleteAssociatedRecord: ->
      $(document).on 'click', '.remove_fields', (event) ->
        $(@).parents('[data-behavior~=associated_record]').hide(200)

    editAction: ->
      $(document).on 'click', '[data-behavior~=edit_action]', (event) ->
        actionForm = $(@).parents('.action-form')
        editForm = actionForm.find('.action-edit-form')
        actionDescription = $(@).parents('.action-form').find('.action-description')
        if editForm.hasClass('hide')
          editForm.removeClass('hide')
          actionForm.addClass('selected')
          actionDescription.addClass('hide')
        else
          editForm.addClass('hide')
          actionForm.removeClass('selected')
          actionDescription.removeClass('hide')
        event.stopPropagation()
        event.preventDefault()
        return

    nextEntry: ->
      $(document).on 'click', '.next-entry-preview', (event) ->
        next = feedbin.nextEntry()
        if next
          next.find('a').click()
        return

    viewLatest: ->
      $(document).on 'click', '.view-latest-link', ->
        $('.entries .selected a').click()
        return

    serviceOptions: ->
      $(document).on 'click', '[data-behavior~=show_service_options]', (event) ->
        $(@).parents('li').find('.service-options').removeClass('hide')
        $(@).parents('li').find('.show-service-options').addClass('hide')
        event.preventDefault()
        return

      $(document).on 'click', '[data-behavior~=hide_service_options]', (event) ->
        $(@).parents('li').find('.service-options').addClass('hide')
        $(@).parents('li').find('.show-service-options').removeClass('hide')
        event.preventDefault()
        return

    drawBarCharts: ->
      $('canvas').each ()->
        feedbin.drawBarChart(@, $(@).data('values'))
      return

    selectText: ->
      $(document).on 'mouseup', '[data-behavior~=select_text]', (event) ->
        $(@).select()
        event.preventDefault()
      return

    showSettingsModal: ->
      $(document).on 'mouseup', '[data-behavior~=show_settings_modal]', (event) ->
        content = $('[data-behavior~=settings_modal]').html()
        feedbin.modalBox(content);
        event.preventDefault()

    fuzzyFilter: ->
      feeds = $('.feed-form li')
      $(document).on 'keyup', '[data-behavior~=feed_search]', ->
        suggestions = []
        query = $(@).val()
        if query.length < 1
          suggestions = feeds
        else
          $.each feeds, (i, feed) ->
            feed.score = $(feed).data('sort-name').score(query);
            if feed.score > 0
              suggestions.push(feed);
          if suggestions.length > 0
            suggestions = _.sortBy suggestions, (suggestion) ->
              -(suggestion.score)
          else
            suggestions = ''
        $('.feed-form').html(suggestions)
      return

    generalAutocomplete: ->
      autocompleteFields = $('[data-behavior~=autocomplete_field]')
      $.each autocompleteFields, (i, field) ->
        field = $(field)
        field.autocomplete
          serviceUrl: field.data('autocompletePath')
          appendTo: field.parent("[data-behavior~=autocomplete_parent]").find("[data-behavior=autocomplete_target]")
          delimiter: /(,)\s*/
          deferRequestBy: 50
          autoSelectFirst: true
      return

jQuery ->
  $.each feedbin.init, (i, item) ->
    item()