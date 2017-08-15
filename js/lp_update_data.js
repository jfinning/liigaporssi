$(document).ready(function() {
	show_login();
	get_settings();
});

function show_login() {
	document.getElementById('login').style.display='block';
}

function get_settings() {
	var sub = "get_settings";
	$.ajax({
			type: 'POST',
			url: 'lp_update_data.pl',
			data: {'sub':sub},
			dataType: 'json',
			success: function(res) {
				//$('div.settings').html(res);
				$('div.settings').html(
				'<table class="w3-table w3-striped w3-bordered">' +
				'<tr><th>Sarja</th> <th>Jakso</th> <th>Vuosi</th></tr>' +
				'<tr><td>' + res.nhl.liiga + '</td> <td>' + res.nhl.jakso + '</td> <td>' + res.nhl.vuosi + '</td></tr>' +
				'<tr><td>' + res.sm_liiga.liiga + '</td> <td>' + res.sm_liiga.jakso + '</td> <td>' + res.sm_liiga.vuosi + '</td></tr>' +
				'</table>'
				);
			},
			error: function() {$('div.settings').html("Problems when reading variables");}
	});
}

function update_files() {
	$("div.failures").html('');
	$("label.status").html('');
	var checkboxes = $('input.perl_function');
	jQuery.each(checkboxes, function(i, checkbox) {
		if ($(checkbox).is(":checked")) {
			run_update($(checkbox).attr('id'));
		}
	});
}

function run_update(type) {
	var sub = 'update_given_data';
	var result_element = '#' + type + '_status';
	$(result_element).html('<i class="fa fa-cog fa-spin" style="font-size:30px"></i>');
	$.ajax({
		type: 'POST',
		url: 'lp_update_data.pl',
		data: {'sub':sub,'update_type':type},
		dataType: 'json',
		success: function(res) {
			//$('div.failures').append(res);
			if (res.fail) {
				$(result_element).html("FAIL");
				$('div.failures').append(res.message);
			} else {
				$(result_element).html("OK");
			}
		},
		error: function() {
			$(result_element).html("FAIL");
			$('div.failures').append("Some problem occurred trying to run " + sub + "<br>");
		}
	});
}

function set_checkboxes(liiga, check) {
	if (check == 'check_all') {
		$('input.' + liiga).prop("checked", true);
	} else if (check == 'uncheck_all') {
		$('input.' + liiga).prop("checked", false);
	}
}

function cancel_login () {
	document.getElementById('login').style.display='none';
	document.body.innerHTML = 
		'<div class="w3-display-container w3-black" style="height:300px;">' +
			'<div class="w3-display-middle"><h3>No access to update files</h3></div>' +
		'</div>';
}

function check_user_rights () {
	var sub = 'check_user_rights';
	var username = $("input[name~='username']").val();
	var passwd = $("input[name~='password']").val();
	$('.login_fail').html("");
	$.ajax({
		type: 'POST',
		url: 'lp_update_data.pl',
		data: {'sub':sub,'username':username,'password':passwd},
		dataType: 'json',
		success: function(res) {
			//$('footer.login').append(res);
			if (res.fail) {
				$('.login_fail').html('<div style="width:98%"><h3>Wrong username or password</h3></div>');
			} else {
				$('.login_success').html('<div style="width:98%" class="w3-text-green"><h3>Login success</h3></div>');
				$('footer.login').html('<button style="width:98%" class="w3-btn w3-black w3-border w3-round" onclick="close_modal()">OK</button>');
			}
		},
		error: function() {
			$('.login_fail').html("Some problem occurred trying to run " + sub);
		}
	});
}

function close_modal() {
	document.getElementById('login').style.display='none';
}