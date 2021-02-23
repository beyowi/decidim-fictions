$(() => {
  const $form = $(".fiction_form_admin");

  if ($form.length > 0) {
    const $fictionCreatedInMeeting = $form.find("#fiction_created_in_meeting");
    const $fictionMeeting = $form.find("#fiction_meeting");

    const toggleDisabledHiddenFields = () => {
      const enabledMeeting = $fictionCreatedInMeeting.prop("checked");
      $fictionMeeting.find("select").attr("disabled", "disabled");
      $fictionMeeting.hide();

      if (enabledMeeting) {
        $fictionMeeting.find("select").attr("disabled", !enabledMeeting);
        $fictionMeeting.show();
      }
    };

    $fictionCreatedInMeeting.on("change", toggleDisabledHiddenFields);
    toggleDisabledHiddenFields();

  }
});
