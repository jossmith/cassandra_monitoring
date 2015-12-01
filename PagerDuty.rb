#!/usr/bin/env ruby

require 'net/smtp'
require 'rest_client'
require 'json'

pagerduty_servicekey = '588b7510fc2b012ffd6422000af81c0e'

def send_email_module(priority, subject, body, from, contenttype)

   emails=['AutomatedAlertsForSearchDevelopment@careerbuilder.com','sitedbalerts@careerbuilder.com']
   hostname=`hostname | cut -d. -f1`

   message = <<MESSAGE_END
From: <#{from}>
Importance:#{priority}
To: <#{emails}>
MIME-Version: 1.0
Content-type: #{contenttype}
Subject: #{subject}

#{body}
MESSAGE_END

   Net::SMTP.start('relay.careerbuilder.com') do |smtp|
      smtp.send_message message, from, emails
   end
end

def send_pagerduty_event(subject, body)
        opts = {'service_key' => '588b7510fc2b012ffd6422000af81c0e'}
        opts['event_type'] = 'trigger'
        opts['description'] = subject
        opts['incident_key'] = subject
        opts['details'] = { 'message' => body}

        RestClient.post "https://events.pagerduty.com/generic/2010-04-15/create_event.json", opts.to_json, :content_type => :json, :accept => :json
end

def send_email_and_event(priority, subject, body, from, contenttype)
        if priority == "High"
                send_pagerduty_event subject, body
        end
        send_email_module(priority, subject, body, from, contenttype)
end
if __FILE__ == $0
if ARGV.length == 5
        send_email_and_event(ARGV[0], ARGV[1], ARGV[2], ARGV[3], ARGV[4])
else
        puts "it's bananas, b a n a n a s"
end
end
