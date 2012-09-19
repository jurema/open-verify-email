var s = $('#suggest');
$('#email').focus().on('blur', function() {
  $(this).mailcheck({
    suggested: function(element, suggestion) {
      s.html('Did you mean <em>' + suggestion.full + '</em>?');
      s.fadeIn('fast');
    },
    empty: function(element) {
      s.fadeOut('fast');
    }
  });
});
