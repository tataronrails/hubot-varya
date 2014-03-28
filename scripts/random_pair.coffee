# Description:
#   Generate random pair for pair programming
#
# Commands:
#   hubot <user> choose random pair
#
# Examples:
#
fs = require 'fs'
moment = require 'moment'

all_users = [ '@Arts', '@Alex', '@Anatoly', '@Koppel', '@Elvir', '@gilmo', '@Ivan', '@alive', '@VladN' ]
history_file_path = '/home/artur/projects/hubot-varya/tmp/history.csv'
monday_at_this_week = moment().day(1).format("DD-MM-YYYY")

module.exports = (robot) ->
  robot.respond /choose random pair for pair programming/i, (msg) ->
    msg.send get_today_pair()

shuffle = (a) ->
  for i in [a.length-1..1]
    j = Math.floor Math.random() * (i + 1)
    [a[i], a[j]] = [a[j], a[i]]
  a

get_random_pair = ->
  shuffle(all_users)
  all_users[0..1]

get_today_pair = ->
  random_pair = get_random_pair()
  records = get_records_amount_week()
  result = false
  option = 'first'
  if records.length is 0
    result = true
  else
    result = for record in records
              if random_pair[0] and random_pair[1] in record
                false
                break
    if result then option = 'append'
  if result
    add_record(option, history_file_path, random_pair)
    message(random_pair)
  else
    get_today_pair()

get_records_amount_week = ->
  all_records = readTextFile(history_file_path)
  records_amount_week = []
  for record in all_records.split('\n') when all_records.length isnt 0
    date = moment(record.split(',')[0]).format("DD-MM-YYYY")
    if date >= monday_at_this_week
      records_amount_week.push record
  records_amount_week

readTextFile = (path) ->
  fs.readFileSync path, 'utf-8'

add_record = (style, file_name, data) ->
  new_record = "#{moment().format("DD-MM-YYYY")}, #{data[0]}, #{data[1]}"
  all_records = switch style
                when 'first' then new_record
                when 'append' then readTextFile(history_file_path) + '\n' + new_record
  fs.writeFile file_name, all_records, (error) ->
    console.error("Error writing file", error) if error

message = (today_pair) ->
  "Сегодня #{today_pair[0]} и #{today_pair[1]} вместе занимаются парным программированием"
