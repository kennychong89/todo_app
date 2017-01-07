$(document).ready(function() {
  $('form.delete').click(function(e) {
    e.preventDefault();
    e.stopPropagation();

    var ok = confirm("Are you sure? This cannot be undone!");
    if (ok) {
      
      var form = $(this);
        
      var request = $.ajax({
          url: form.attr("action"),
          method: form.attr("method")
      });

      request.done(function(data, textStatus, jqHXR) {
        if (jqHXR.status == 204) {
          form.parent("li").remove();  
        } else if (jqHXR.status == 200) {
          document.location = data;
        }
      });

      //request.fail(function)
    }
  });
});