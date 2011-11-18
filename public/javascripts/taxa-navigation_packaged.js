if(!EOL)EOL={};if(!EOL.clade_selector_input_name){EOL.clade_selector_input_name='selected-clade-id';}
if(!EOL.clade_selector_id){EOL.clade_selector_id='selected-clade-id';}
if(!EOL.clade_selector_id){EOL.clade_selector_id='<img src="/images/indicator_arrows_black.gif"/>';}
if(!EOL.clade_behavior_needs_load){EOL.clade_behavior_needs_load='yes';}
if(!EOL.expand_clade_behavior){EOL.expand_clade_behavior=function(){if(EOL.clade_behavior_needs_load=='yes'){EOL.clade_behavior_needs_load='nope';if(!EOL.expanding_clade_spinner){EOL.expanding_clade_spinner=$('#orig-clade-spinner').html();}
$('a.expand-clade').click(function(){$(this).append(EOL.expanding_clade_spinner);$('value_'+$(this).attr('clade_id')).html(EOL.indicator_arrows_html);var tree_path='#'+EOL.clade_selector_id+'-inner ul.tree';EOL.clade_behavior_needs_load='yes';$(tree_path).load($(this).attr('href')+' '+tree_path,'',function(){EOL.expand_clade_behavior();$('.clade-spinner').remove();});return false;});}};}
function displayNode(id){displayNode(id,false);}
function displayNode(id,for_selection,selected_hierarchy_entry_id){url='/navigation/show_tree_view';if(for_selection){url='/navigation/show_tree_view_for_selection';}
$.ajax({url:url,type:'POST',success:function(response){$('#classification_browser').html(response);},error:function(){$('#classification_browser').html("<p>Sorry, there was an error.</p>");},data:{id:id,selected_hierarchy_entry_id:selected_hierarchy_entry_id}});}
function update_browser(hierarchy_entry_id,expand){$.ajax({url:'/navigation/browse',complete:function(){scroll(0,100);},success:function(response){$('#hierarchy_browser').html(response);},error:function(){$('#classification_browser').html("<p>Sorry, there was an error.</p>");},data:{id:hierarchy_entry_id,expand:expand}});}
function update_browser_stats(hierarchy_entry_id,expand){$.ajax({url:'/navigation/browse_stats',complete:function(request){scroll(0,100);},success:function(response){$('#hierarchy_browser').html(response);},error:function(){$('#classification_browser').html("<p>Sorry, there was an error.</p>");},data:{id:hierarchy_entry_id,expand:expand}});}
$(document).ready(function(){$('#browser_hide a').click(function(){$($(this).attr('href')).slideUp();$('#browser_show').show();$('#browser_hide').hide();return false;});$('#browser_show a').click(function(){$($(this).attr('href')).slideDown();$('#browser_show').hide();$('#browser_hide').show();return false;});$('#browser_clear a').click(function(){clear_clade_of_clade_selector();return false;});EOL.expand_clade_behavior();});if(!EOL.clade_selector_input_field){EOL.clade_selector_input_field=function(){return $("#"+EOL.clade_selector_input_name.replace(/\]/,'').replace(/\[/,'_'));};}
function select_clade_of_clade_selector(clade_id){EOL.clade_selector_input_field().val(clade_id);unselect_all_clades_of_clade_selector();$('li.value_'+clade_id).addClass('selected');}
function clear_clade_of_clade_selector(){EOL.clade_selector_input_field().val('');unselect_all_clades_of_clade_selector();}
function unselect_all_clades_of_clade_selector(){$('div#'+EOL.clade_selector_id+' ul.tree li.selected').removeClass('selected');}