$(() => {
  const $content = $(".picker-content"),
      pickerMore = $content.data("picker-more"),
      pickerPath = $content.data("picker-path"),
      toggleNoFictions = () => {
        const showNoFictions = $("#fictions_list li:visible").length === 0
        $("#no_fictions").toggle(showNoFictions)
      }

  let jqxhr = null

  toggleNoFictions()

  $(".data_picker-modal-content").on("change keyup", "#fictions_filter", (event) => {
    const filter = event.target.value.toLowerCase()

    if (pickerMore) {
      if (jqxhr !== null) {
        jqxhr.abort()
      }

      $content.html("<div class='loading-spinner'></div>")
      jqxhr = $.get(`${pickerPath}?q=${filter}`, (data) => {
        $content.html(data)
        jqxhr = null
        toggleNoFictions()
      })
    } else {
      $("#fictions_list li").each((index, li) => {
        $(li).toggle(li.textContent.toLowerCase().indexOf(filter) > -1)
      })
      toggleNoFictions()
    }
  })
})
