require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def find_peak_hours(hours)

  peak_hours = Array.new()

  hours.tally.each do |hour, count|
    #Find the maximum number of counts
    if count == hours.tally.values.max
      #Find the hours with highest count and store into peak hour
      peak_hours.push(hour)
    end
  end

  peak_hours
end

def find_peak_days(days)

  peak_days = Array.new()

  days.tally.each do |day, count|
    #Find the maximum number of counts
    if count == days.tally.values.max
      #Find the hours with highest count and store into peak hour
      peak_days.push(day)
    end
  end

  peak_days
end

def set_days(days, regdate)
  #Set the day in integer
  day = (Date.strptime(regdate, "%m/%d/%y %H:%M").wday)
  #Convert integer to string to show the day
  case day
  when 0
    day = 'Sunday'
  when 1
    day = 'Monday'
  when 2
    day = 'Tuesday'
  when 3
    day = 'Wednesday'
  when 4
    day = 'Thursday'
  when 5
    day = 'Friday'
  when 6
    day = 'Saturday'
  end

  days.push(day)
  days
end

def set_hours(hours, regdate)
  hours.push(Time.strptime(regdate, "%m/%d/%y %H:%M").hour)
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,'0')[0..4]
end

def clean_phone_number(phone_number)
  #If phone number is less than 10 digits or is 11 digits and first number is not 1 or more than 11 digits,
  #assume phone number is invalid
  if phone_number.count('/[0-9]/') < 10 || (phone_number.count('/[0-9]/') == 11 && phone_number[phone_number.index(/[0-9]/)] != '1') ||
  phone_number.count('/[0-9]/') > 11
    phone_number = 'Invalid number'
  #If phone number is 11 digits and first number is 1, trim 1 and only store phone number in 
  #10 previous digits into phone_number
  elsif phone_number.count('/[0-9]/') == 11 && phone_number[phone_number.index(/[0-9]/)] == '1'
    phone_number = phone_number[phone_number.index(/[0-9]/) + 1 .. phone_number.length - 1]
  #This is a phone number that is valid where phone number is 10 digits long
  else
    phone_number
  end
  
end

def legislators_by_zipcode(zip)

  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.com/take-action/find-elected-officials"
  end

end

def save_thank_you_letter(id, form_letter)

  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours = Array.new
days = Array.new

contents.each do |row|
  id = row[0]
  
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  phone_number = clean_phone_number(row[:homephone])

  set_hours(hours, row[:regdate])

  set_days(days,row[:regdate])

  save_thank_you_letter(id, form_letter)

  puts "#{name} #{zipcode} #{phone_number}"

end

peak_hours = find_peak_hours(hours)
peak_days = find_peak_days(days)

puts "Best times to run the ads are #{peak_hours.join(' and ')}"
puts "Best day to run the ads is #{peak_days.join("")}"
