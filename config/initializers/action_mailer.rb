Rails.application.configure do
  #Config action mailer
  #http://edgeguides.rubyonrails.org/action_mailer_basics.html
  mailConfiguration = config.APP_CONFIG["mail"] || {}
  mailConfiguration = {:no_reply_mail => "no-reply@europeanars.com", :main_mail => "no-reply@europeanars.com", :type => "SMTP"}.merge(mailConfiguration)

  config.action_mailer.default_url_options = { :host => config.domain }
  
  if mailConfiguration["type"] === "SENDMAIL"
    config.action_mailer.delivery_method = :sendmail
    ActionMailer::Base.default :from => mailConfiguration["no_reply_mail"]
    ActionMailer::Base.sendmail_settings = {
      :location => "/usr/sbin/sendmail",
      :arguments => "-i -t"
    }
  else
    config.action_mailer.delivery_method = :smtp

    unless mailConfiguration["gmail_credentials"].nil?
      #Use Gmail SMTP servers
      config.action_mailer.smtp_settings = {
        address:              'smtp.gmail.com',
        port:                 587,
        domain:               config.domain,
        user_name:            mailConfiguration["gmail_credentials"]["username"],
        password:             mailConfiguration["gmail_credentials"]["password"],
        authentication:       'plain',
        enable_starttls_auto: true  
      }
    else
      #Local SMTP server
      #(Requires you to have a SMTP server on localhost:25)
      ActionMailer::Base.default :from => mailConfiguration["no_reply_mail"]
      config.action_mailer.smtp_settings = {
        :address => "127.0.0.1",
        :port    => "25",
        :domain  => config.domain,
        :enable_starttls_auto => true,
        :openssl_verify_mode  => 'none'
      }
    end
  end
end