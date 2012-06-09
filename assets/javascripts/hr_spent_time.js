function issue_pos(url, issue, pos, max)
{
  var new_pos = prompt("Destination No.", pos);
  if(new_pos != null) {
    if((new_pos>=1) && (new_pos<=max))
      location.replace(url+"&issue_pos="+issue+"_"+new_pos);
    else 
      alert("Out of range!");
  }
}

function prj_pos(url, prj, pos, max)
{
  var new_pos = prompt("Destination No.", pos);
  if(new_pos != null) {
    if((new_pos>=1) && (new_pos<=max))
      location.replace(url+"&prj_pos="+prj+"_"+new_pos);
    else 
      alert("Out of range!");
  }
}

function member_pos(url, user_id, pos, max)
{
  var new_pos = prompt("Destination No.", pos);
  if(new_pos != null) {
    if((new_pos>=1) && (new_pos<=max))
      location.replace(url+"&member_pos="+user_id+"_"+new_pos);
    else 
      alert("Out of range!");
  }
}

function set_issue_relay(pop_url, rep_url, child)
{
  var parent = showModalDialog(pop_url, window, "dialogWidth:600px;dialogHeight:480px");
  if(parent!=null) {
      //location.replace(rep_url+"&issue_relay="+child+"_"+id);
      new Ajax.Updater('relay_table', 
                       rep_url+"&issue_relay="+child+"_"+parent, 
                       {asynchronous:true, method:'get'});
  }
}

function update_done_ratio(pop_url, rep_url, issue_id)
{
  var done_ratio = showModalDialog(pop_url+"&issue_id="+issue_id,
        window, "dialogWidth:500px;dialogHeight:150px");
  if(done_ratio!=null){
    new Ajax.Updater('done_ratio'+issue_id,
                     rep_url+"&issue_id="+issue_id+"&done_ratio="+done_ratio,
                     {asynchronous:true, method:'get'});

    var drs = document.getElementsByName("done_ratio"+issue_id);
    for(var i = 0; i < drs.length; i++) {
      drs[i].innerHTML = "["+done_ratio+"&#37;]";
    }
  }

}