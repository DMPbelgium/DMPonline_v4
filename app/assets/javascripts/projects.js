$( document ).ready(function() {

  function is_string(str){
    return str != null && str != undefined && typeof(str) == "string" && str.trim() != "";
  }

  function gdpr_enabled(){
    return $("input[name=project_gdpr]:checked").val() == "true" ? true : false;
  }

  $("input[name=project_gdpr]").change(function(){
    var val = $(this).filter(":checked").val();
    if(val == undefined || val == null || val == "") return;

    /*
      force org if gdpr == true
    */
    if( gdpr_enabled() ){

      var org_id = $("#current_user_organisation_id").val();
      $("#project_institution_id").val( org_id ).trigger("change").select2("readonly",true);
      $("#no-institution").hide();

    }
    else {

      $("#project_institution_id").select2("readonly",false);
      $("#no-institution").show();

    }

    update_funder_options();
    $("#funder-control-group").show();
    $("#project_funder_id").trigger("change");
  });

	$("#project_funder_id").change(function () {
		update_template_options();
		update_guidance_options();
		if ($(this).val().length > 0) {
			$("#other-funder-name").hide();
			$("#project_funder_name").val("");
		}
		else {
			$("#other-funder-name").show();
		}
		$("#institution-control-group").show();
		$("#create-plan-button").show();
		$("#confirm-funder").text($("#project_funder_id").select2('data').text);
	});

	$("#no-funder").click(function(e) {
		e.preventDefault();
		$("#project_funder_id").select2("val", "");
		update_template_options();
		update_guidance_options();
		$("#institution-control-group").show();
		$("#create-plan-button").show();
		$("#other-funder-name").show();
		$("#confirm-funder").text("None");
	});

	$("#project_funder_name").change(function(){
		$("#confirm-funder").text($(this).val());
	});

	$("#project_institution_id").change(function () {
		update_template_options();
		update_guidance_options();
		$("#confirm-institution").text($("#project_institution_id").select2('data').text);
	});

	$("#no-institution").click(function(e) {
    e.preventDefault();
		$("#project_institution_id").select2("val", "");
		update_template_options();
		update_guidance_options();
		$("#confirm-institution").text("None");
	});

	$("#project_dmptemplate_id").change(function (f) {
		update_guidance_options();
		$("#confirm-template").text($("#project_dmptemplate_id :selected").text());
	});

	$("#project-confirmation-dialog").on("show", function(){
		if ($("#confirm-institution").text() == "") {
			$("#confirm-institution").text("None");
		}
		if ($("#confirm-funder").text() == "") {
			$("#confirm-funder").text("None");
		}

    var template = $("#project_dmptemplate_id :selected").text();
		if( is_string(template) ){
      $("#confirm-template").css({ color: "inherit" }).text(template);
    }
    else{
			$("#confirm-template").css({ color: "red" }).text("None");
		}

    var confirm_title = $("#confirm-title");
    var title = $("#project_title").val();
    if( is_string(title) ){

      confirm_title.css({ color: "inherit" }).text(title);

    }
    else{

      confirm_title.css({ color: "red" }).text("None");

    }
    var $confirm_guidance = $("#confirm-guidance");
    var $confirm_guidance_none = $("#confirm-guidance-none");
    var $guidances = $("input[name=project\\[guidance_group_ids\\]\\[\\]]").filter(":checked");
    $confirm_guidance.empty().hide();
    $confirm_guidance_none.hide();

    if( $guidances.size() > 0 ){
      $guidances.each(function(){
  			$confirm_guidance.append("<li id='confirm-"+$(this).attr("id")+"'>"+$(this).parent().text()+"</li>");
	  	});
      $confirm_guidance.show();
    }else{
      $confirm_guidance_none.show();
    }
		$('.select2-choice').hide();
	});

	$("#new-project-cancelled").click(function (e){
    e.preventDefault();
		$("#project-confirmation-dialog").modal("hide");
		$('.select2-choice').show();
	});

	$("#new-project-confirmed").click(function (e){
    e.preventDefault();
		$("#new_project").submit();
	});

  function update_funder_options(){
    var gdpr = gdpr_enabled();
    var options = {};
    $.ajax({
      type: 'GET',
      url: "possible_funders.json?gdpr="+gdpr,
      dataType: 'json',
      async: false, //Needs to be synchronous, otherwise end up mixing up answers
      success: function(data) {
        options = data;
      }
    });
    var select_element = $("#project_funder_id");
    select_element.find("option").remove();
    var count = 0;
    select_element.append("<option value=''>--Select your funder--</option>");
    for (var id in options) {
      if (count == 0) {
        select_element.append("<option value='"+id+"' selected='selected'>"+options[id]+"</option>");
      }
      else {
        select_element.append("<option value='"+id+"'>"+options[id]+"</option>");
      }
      count++;
    }
  }

	function update_template_options() {
		var options = {};
		var funder = $("#project_funder_id").select2('val');
    if( funder == undefined || funder == null ){
      funder = "";
    }
		var institution = $("#project_institution_id").select2('val');
    if( institution == undefined || institution == null ){
      institution = "";
    }
    var gdpr = gdpr_enabled();
		$.ajax({
			type: 'GET',
			url: "possible_templates.json?institution="+institution+"&funder="+funder+"&gdpr="+gdpr,
			dataType: 'json',
			async: false, //Needs to be synchronous, otherwise end up mixing up answers
			success: function(data) {
				options = data;
			}
		});
		select_element = $("#project_dmptemplate_id");
		select_element.find("option").remove();
		var count = 0;
		for (var id in options) {
			if (count == 0) {
				select_element.append("<option value='"+id+"' selected='selected'>"+options[id]+"</option>");
			}
			else {
				select_element.append("<option value='"+id+"'>"+options[id]+"</option>");
			}
			count++;
		}
		if (count >= 2) {
			$("#template-control-group").show();
		}
		else {
			$("#template-control-group").hide();
		}
		$("#confirm-template").text("");
		$("#project_dmptemplate_id").change();
	}

	function update_guidance_options() {
		var institution = $("#project_institution_id").select2('val');
		var template = $("#project_dmptemplate_id :selected").val();
		$.ajax({
			type: 'GET',
			url: "possible_guidance.json?institution="+institution+"&template="+template,
			dataType: 'json',
			async: false, //Needs to be synchronous, otherwise end up mixing up answers
			success: function(data) {
				options = data;
			}
		});
		options_container = $("#guidance-control-group");
		options_container = options_container.find(".choices-group");
		options_container.empty();
		var count = 0;
		for (var id in options) {
			options_container.append("<li class='choice'><label for='project_guidance_group_ids_"+id+"'><input id='project_guidance_group_ids_"+id+"' name='project[guidance_group_ids][]' type='checkbox' value='"+id+"' />"+options[id]+"</label></li>");
			count++;
		}
		if (count > 0) {
			$("#guidance-control-group").show();
		}
		else {
			$("#guidance-control-group").hide();
		}
	}

  $("input[name=project_gdpr]").trigger("change");

  $("#create-plan-button").on("click",function(evt){

    evt.preventDefault();

    $("#project-confirmation-dialog").modal("show");

  });
});
