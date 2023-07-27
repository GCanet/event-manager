require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

$horas = Array.new(24, 0)
$dias = Array.new(7, 0)

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
  datahoras = DateTime.strptime(registrations, "%m/%d/%y %H:%M").strftime("%H").to_i
  $horas[datahoras] += 1
end

def peak_day(registrations)
  datadias = Date.strptime(registrations, "%m/%d/%y %H:%M").wday
  $dias[datadias] += 1
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
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phones = clean_phones(row[5])
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
  peak_hour(registrations)
  peak_day(registrations)

  puts "#{name} #{zipcode} #{phones}"
end

peak_hora = $horas.index($horas.compact.max)
peak_dia = $dias.index($dias.compact.max)

puts "Peak registration hour(s): #{peak_hora}"
puts "Peak registration day(s): #{peak_dia}"
