// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require_tree .
//= require jquery

$(document).on('turbolinks:load', function() {
  setTimeout(function() { $('.alert').fadeOut('slow') }, 2000);

  $('#opponent').on('click', '.del-comp', function(e) {
    e.preventDefault();
    e.stopPropagation();
    var neg = Math.round(Number($(this).data('week')));
    var tot = Number($('#opp-total').data('total'));
    var now = tot - neg
    now = now < 0 ? 0 : now;

    $(this).parents('.one-opp').remove();

    now = $('.del-comp').length === 1 ? Math.round(Number($('.del-comp').first().data('week'))) : now;

    $('#opp-total').text(String(now) + " points this week");
    $('#opp-total').data('total', now);
  });

  var result = ''

  $('#searchbar').on("keyup", function(e) {
    result = $(this).val().toLowerCase();

    var notIncluded = $(':checkbox').filter(function() {
          return !$(this).val().toLowerCase().includes(result);
        });

    var included = $(':checkbox').filter(function() {
          return $(this).val().toLowerCase().includes(result);
        });

    if (notIncluded.length) {
      notIncluded.parents('.playcheck').hide();
      included.parents('.playcheck').show();
    } else {
      $('.playcheck').show();
    }
  });

  $(':checkbox').change(function() {
    result = '';
    $('#searchbar').val('');
    $('.playcheck').show();
  });

  $('#positions :radio').click(function(e) {
      var url = location.href;
      var $val = $(this).val();
      $val = 'pos=' + $val;
      var parts = location.search.split(/[?&]/g);

      var pos = parts.find(function(str) { return str.includes('pos') });

      if (url.includes('#')) {
          url = url.split('#')
          url.pop();
          url = url.join('');
        }

      if (pos) {
        url = url.replace(pos, $val);
      } else { 
        if (location.search) {
          url = url + '&' + $val;
        } else {
          url = url + '?' + $val;
        }
      }

      location.replace(url);

    });

});
