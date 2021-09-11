require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
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
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(phone_number)
    phone_number = phone_number.tr('^0-9', '')
    case 
    when phone_number.length < 10 || phone_number.length > 11
        phone_number = 0000000000
    when phone_number.length == 11
        if phone_number[0] == "1"
            phone_number = phone_number[1..-1]
        else
            phone_number = 0000000000
        end
    end
    return phone_number
end

def get_peak_registration_hours(registration_dates)
    times_array = Array.new
    registration_dates.each do |row|
        time = DateTime.strptime(row, "%m/%d/%Y %k:%M")
        times_array << time.hour
    end
    most_frequent_time = [0,-1]
    times_array.each_with_index { |element_time, index|
        if times_array.count(element_time) > times_array.count(times_array[most_frequent_time[1]])
            most_frequent_time = [times_array.count(element_time), index]
        end
    }
    return times_array[most_frequent_time[1]]
end

def get_peak_weekday_registration(registration_dates)
    weekday_array = Array.new
    registration_dates.each do |row|
        weekday = DateTime.strptime(row, "%m/%d/%Y %k:%M")
        weekday_array << weekday.wday
    end
    most_frequent_weekday = [0,-1]
    weekday_array.each_with_index { |element_weekday, index|
        if weekday_array.count(element_weekday) > weekday_array.count(weekday_array[most_frequent_weekday[1]])
            most_frequent_weekday = [weekday_array.count(element_weekday), index]
        end
    }
    case weekday_array[most_frequent_weekday[1]]
    when 0
        return 'Sunday'
    when 1
        return 'Monday'
    when 1
        return 'Tuesday'
    when 1
        return 'Wednesday'
    when 1
        return 'Thursday'
    when 1
        return 'Friday'
    when 1
        return 'Saturday'
    end
end

###########################################################3

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

reg_dates = CSV.read('event_attendees.csv', headers: true, header_converters: :symbol)
peak_registration_hour = get_peak_registration_hours(reg_dates[:regdate])
peak_registration_weekday = get_peak_weekday_registration(reg_dates[:regdate])

puts "The most common registration hour is #{peak_registration_hour} o'clock"
puts "The most common registration weekday is #{peak_registration_weekday}"

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_numbers(row[:homephone])


  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end