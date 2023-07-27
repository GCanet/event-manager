require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phones(phones)
  phones = phones&.gsub(/[^0-9]/, '')
  if phones.nil? 
    '0000000000'
  elsif phones.length < 10
    '0000000000'
  elsif phones.length == 10
    phones
  elsif phones.length >= 11
    if phones[0] == '1'
      phones[1..-1].rjust(10, '0')
    else
      '0000000000'
    end
  end
end

def peak_hour(registrations)
  # Extract the hour component from the registration date and time

  # Count the number of registrations for each hour

  # Find the hour(s) with the highest number of registrations

  #strptime, #strftime, and #hour
end

def peak_day(registrations)
  # Use Date#wday to find out the day of the week.
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  registrations = row[1]
  peak_hours = peak_hour(registrations)
  best_day = peak_day(registrations)
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phones = clean_phones(row[5])
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)

  puts "#{name} #{zipcode} #{phones}"
end

puts "Peak registration hour(s): #{peak_hours}"
puts "Peak registration day(s): #{best_day}"
