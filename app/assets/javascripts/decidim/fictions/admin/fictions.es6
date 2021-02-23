// = require_self
$(document).ready(function () {
  let selectedFictionsCount = function() {
    return $('.table-list .js-check-all-fiction:checked').length
  }

  let selectedFictionsNotPublishedAnswerCount = function() {
    return $('.table-list [data-published-state=false] .js-check-all-fiction:checked').length
  }

  window.selectedFictionsCountUpdate = function() {
    const selectedFictions = selectedFictionsCount();
    const selectedFictionsNotPublishedAnswer = selectedFictionsNotPublishedAnswerCount();
    if(selectedFictions == 0){
      $("#js-selected-fictions-count").text("")
    } else {
      $("#js-selected-fictions-count").text(selectedFictions);
    }

    if(selectedFictions >= 2) {
      $('button[data-action="merge-fictions"]').parent().show();
    } else {
      $('button[data-action="merge-fictions"]').parent().hide();
    }

    if(selectedFictionsNotPublishedAnswer > 0) {
      $('button[data-action="publish-answers"]').parent().show();
      $('#js-form-publish-answers-number').text(selectedFictionsNotPublishedAnswer);
    } else {
      $('button[data-action="publish-answers"]').parent().hide();
    }
  }

  let showBulkActionsButton = function() {
    if(selectedFictionsCount() > 0){
      $("#js-bulk-actions-button").removeClass('hide');
    }
  }

  window.hideBulkActionsButton = function(force = false) {
    if(selectedFictionsCount() == 0 || force == true){
      $("#js-bulk-actions-button").addClass('hide');
      $("#js-bulk-actions-dropdown").removeClass('is-open');
    }
  }

  window.showOtherActionsButtons = function() {
    $("#js-other-actions-wrapper").removeClass('hide');
  }

  window.hideOtherActionsButtons = function() {
    $("#js-other-actions-wrapper").addClass('hide');
  }

  window.hideBulkActionForms = function() {
    $(".js-bulk-action-form").addClass('hide');
  }

  if ($('.js-bulk-action-form').length) {
    window.hideBulkActionForms();
    $("#js-bulk-actions-button").addClass('hide');

    $("#js-bulk-actions-dropdown ul li button").click(function(e){
      e.preventDefault();
      let action = $(e.target).data("action");

      if(action) {
        $(`#js-form-${action}`).submit(function(){
          $('.layout-content > .callout-wrapper').html("");
        })

        $(`#js-${action}-actions`).removeClass('hide');
        window.hideBulkActionsButton(true);
        window.hideOtherActionsButtons();
      }
    })

    // select all checkboxes
    $(".js-check-all").change(function() {
      $(".js-check-all-fiction").prop('checked', $(this).prop("checked"));

      if ($(this).prop("checked")) {
        $(".js-check-all-fiction").closest('tr').addClass('selected');
        showBulkActionsButton();
      } else {
        $(".js-check-all-fiction").closest('tr').removeClass('selected');
        window.hideBulkActionsButton();
      }

      selectedFictionsCountUpdate();
    });

    // fiction checkbox change
    $('.table-list').on('change', '.js-check-all-fiction', function (e) {
      let fiction_id = $(this).val()
      let checked = $(this).prop("checked")

      // uncheck "select all", if one of the listed checkbox item is unchecked
      if ($(this).prop("checked") === false) {
        $(".js-check-all").prop('checked', false);
      }
      // check "select all" if all checkbox fictions are checked
      if ($('.js-check-all-fiction:checked').length === $('.js-check-all-fiction').length) {
        $(".js-check-all").prop('checked', true);
        showBulkActionsButton();
      }

      if ($(this).prop("checked")) {
        showBulkActionsButton();
        $(this).closest('tr').addClass('selected');
      } else {
        window.hideBulkActionsButton();
        $(this).closest('tr').removeClass('selected');
      }

      if ($('.js-check-all-fiction:checked').length === 0) {
        window.hideBulkActionsButton();
      }

      $('.js-bulk-action-form').find(".js-fiction-id-"+fiction_id).prop('checked', checked);
      selectedFictionsCountUpdate();
    });

    $('.js-cancel-bulk-action').on('click', function (e) {
      window.hideBulkActionForms()
      showBulkActionsButton();
      showOtherActionsButtons();
    });
  }
});
