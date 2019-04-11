$(document).ready(function() {
  $("input[name='reason_id']").live('click', function() {
    if ($(this).val() == 'false')
     $('input.hide').addClass('show').removeClass('hide');
    else
     $('input.show').addClass('hide').removeClass('show');
  });
});
