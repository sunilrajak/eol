// This handles all of the functionality of the mini-clade browser, which is used in several places.
if (!EOL) EOL = {};
// Set up some stupid defaults, just in case.  (All of these should be supplied before now, though.)
if (!EOL.clade_selector_input_name) { EOL.clade_selector_input_name = 'selected-clade-id'; }
if (!EOL.clade_selector_id) { EOL.clade_selector_id = 'selected-clade-id'; }
if (!EOL.clade_selector_id) { EOL.clade_selector_id = '<img src="/images/indicator_arrows_black.gif"/>'; }
if (!EOL.clade_behavior_needs_load) { EOL.clade_behavior_needs_load = 'yes'; } // Avoid boolean, makes defined test easier
if (!EOL.expand_clade_behavior) {
  EOL.expand_clade_behavior = function() {
    // Because things are sloppy, loading here sometimes happens twice.  This helps avoid that.  TODO - remove this when the
    // loading is cleaned up!  (I really hate this code as-is!)
    if(EOL.clade_behavior_needs_load == 'yes') {
      EOL.clade_behavior_needs_load = 'nope';
      if (!EOL.expanding_clade_spinner) { EOL.expanding_clade_spinner = $('#orig-clade-spinner').html(); }
      $('a.expand-clade').click(function() {
        $(this).append(EOL.expanding_clade_spinner);
        $('value_' + $(this).attr('clade_id')).html(EOL.indicator_arrows_html);
        // TODO - This is EXTREMELY inefficient in that it re-loads the current page with a given node expanded and then grabs
        // the entire tree from the resulting HTML and puts in place of the existing one.  This is really ugly.  Needs to be
        // fixed ASAP. Note that this special functionality of load() is ONLY available with load() (not with, say, $.ajax()).
        var tree_path = '#'+EOL.clade_selector_id+'-inner ul.tree';
        EOL.clade_behavior_needs_load = 'yes';
        $(tree_path).load($(this).attr('href') + ' ' + tree_path, // special syntax to grab *part* of a response.
          '', // data.  We don't want to send any.  Careful not to use an object {} here, the request w/ become a POST.
          function() { // this is called when the response is complete.
            EOL.expand_clade_behavior();
            $('.clade-spinner').remove();
          }
        );
        return false;
      });
    }
  };
}

// Alias to display a node when it's not for a selection:
function displayNode(id) {
  displayNode(id, false);
}

// call remote function to show the selected node in the text-based navigational tree view
function displayNode(id, for_selection, selected_hierarchy_entry_id) {
  url = '/navigation/show_tree_view';
  if(for_selection) {
    url = '/navigation/show_tree_view_for_selection';
  }
  $.ajax({
    url: url,
    type: 'POST',
    success: function(response){$('#classification_browser').html(response);},
    error: function(){ $('#classification_browser').html("<p>Sorry, there was an error.</p>"); },
    data: {id: id, selected_hierarchy_entry_id: selected_hierarchy_entry_id}
  });
}

// call remote function to show the selected node in the text-based navigational tree view
function update_browser(hierarchy_entry_id, expand) {
  $.ajax({
    url: '/navigation/browse',
    complete: function(){scroll(0,100);},
    success: function(response){$('#hierarchy_browser').html(response);},
    error: function(){ $('#classification_browser').html("<p>Sorry, there was an error.</p>"); },
    data: {id: hierarchy_entry_id, expand: expand }
  });
}

// call remote function to show the selected node in the text-based navigational tree view
function update_browser_stats(hierarchy_entry_id, expand) {
  $.ajax({
    url: '/navigation/browse_stats',
    complete: function(request){scroll(0,100);},
    success: function(response){$('#hierarchy_browser').html(response);},
    error: function(){ $('#classification_browser').html("<p>Sorry, there was an error.</p>"); },
    data: {id: hierarchy_entry_id, expand: expand }
  });
}

$(document).ready(function() {
  // Expand the mini-tree on the taxon overview:
  $('#classifications_summary a.show_tree').unbind('click').click(function() {
    var $update = $(this).closest('#classifications_summary > ul > li > ul');
    EOL.ajax_submit($(this), {update: $update, type: 'GET'});
    return(false);
  });
  // TODO: this is silly to repeat the method, but this whole file needs to be rewritten
  // so I'm just laying on the hacks for right now
  $('#classification_browser a.show_tree').unbind('click').click(function() {
    var $update = $(this).closest('#classification_browser > ul > li');
    EOL.ajax_submit($(this), {update: $update, type: 'GET'});
    return(false);
  });

  EOL.expand_clade_behavior();
});

if (!EOL.clade_selector_input_field) {
  EOL.clade_selector_input_field = function() {
    return $("#" + EOL.clade_selector_input_name.replace(/\]/, '').replace(/\[/, '_'));
  };
}

function select_clade_of_clade_selector( clade_id ) {
  EOL.clade_selector_input_field().val(clade_id);
  unselect_all_clades_of_clade_selector();
  $('li.value_' + clade_id).addClass('selected');
}

function clear_clade_of_clade_selector() {
  EOL.clade_selector_input_field().val('');
  unselect_all_clades_of_clade_selector();
}

function unselect_all_clades_of_clade_selector() {
  $('div#'+EOL.clade_selector_id+' ul.tree li.selected').removeClass('selected');
}
