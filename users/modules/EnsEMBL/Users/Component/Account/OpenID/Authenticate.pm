package EnsEMBL::Users::Component::Account::OpenID::Authenticate;

### Page displayed to ask the user to authorise his existing account when he logs in for the very first time using openid and he chooses to link an existing account to openid login
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub caption {
  return 'Authenticate existing account';
}

sub content {
  my $self              = shift;
  my $hub               = $self->hub;
  my $object            = $self->object;
  my $email             = $hub->param('email')                    or return $self->render_message('MESSAGE_UNKNOWN_ERROR',        {'error' => 1});
  my $existing_user     = $object->fetch_user_by_email($email)    or return $self->render_message('MESSAGE_NO_EXISTING_ACCOUNT',  {'error' => 1});
  my $login             = $object->fetch_login_from_url_code(1)   or return $self->render_message('MESSAGE_LOGIN_MISSING',        {'error' => 1});
  my $provider          = $login->provider;
  my $site_name         = $self->site_name;
  my $content           = $self->wrapper_div({'js_panel' => 'AccountForm'});
  my $form              = $content->append_child($self->new_form({'action' => $hub->url({'action' => 'OpenID', 'function' => 'Link'})}));

  $form->add_notes("To enable us to link your $provider account to your existing $site_name account, we need to make sure that the existing account belongs to you.");
  $form->add_hidden({'name' => 'code',            'value' => $login->get_url_code });
  $form->add_hidden({'name' => 'email',           'value' => $email               });
  $form->add_hidden({'name' => 'authentication',  'value' => 'email'              });

  if ($existing_user->get_local_login) {
    $form->add_field({
      'label'       => 'Please choose a method for account verification',
      'type'        => 'radiolist',
      'name'        => 'authentication',
      'values'      => [{
        'value'       => 'email',
        'caption'     => "Send an email on $email", 
        'checked'     => 1
      }, {
        'value'       => 'password',
        'caption'     => "Authenticate via $site_name password for this account",
        'class'       => '_password_auth'
      }]
    });

    $form->add_field({
      'field_class' => 'hidden _password_auth', # displayed by JavaScript only if user chooses for password authentication
      'label'       => 'Password',
      'type'        => 'password',
      'name'        => 'password',
      'notes'       => 'Please enter the password for the existing account.'
    });

  } else {
    $form->add_notes("An email will be sent to $email asking for the verification of this existing $site_name account.");
  }

  $form->add_button({'value' => 'Continue'});

  return $content->render;
}

1;