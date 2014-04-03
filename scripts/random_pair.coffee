# Description:
#   Generate random pair for pair programming
#   pp - pair programming
#
# Commands:
#   hubot pp pairs today
#   hubot pp pairs
#   hubot pp users
#   hubot pp add user <mention>
#   hubot pp remove user <mention>
#
# Dependencies:
#  "underscore": "1.6.0",
#  "moment": "2.5.1"
#
# Configuration:
#   None
#
# Examples:
#  hubot pp add user @dhh
#

moment = require 'moment'
_ = require 'underscore'

class PairProgramming

  constructor: (@data) ->
    data.pp ?= {}
    data.pp.users ?= []
    data.pp.pairs ?= []
    @pairs = @data.pp.pairs
    @users = @data.pp.users

  generateTodayPair: (count = 0) ->
    if count < 50
      random_pair = _.sample(@users, 2)
      records = @getRecordsAmountWeek()
      result = true
      for record in records
        if _.difference(random_pair, record).length is 0
          result = false
          break
      if result
        @addRecord(random_pair)
        @todayPairMessage(random_pair)
      else
        @generateTodayPair(++count)
    else
      'Not found uniq pair'

  getRecordsAmountWeek: ->
    records_amount_week = []
    for pair in @pairs
      date = moment(pair[0]).format("MM-DD-YYYY")
      monday_at_this_week = moment().day(1).format("MM-DD-YYYY")
      if date >= monday_at_this_week
        records_amount_week.push pair
    records_amount_week

  addRecord: (pair) ->
    new_pair = [moment().format("MM-DD-YYYY"), pair[0], pair[1]]
    @pairs.push new_pair

  addUser: (all_users, mention_name) ->
    users_keys = _.keys(all_users)
    if users_keys.some((key) -> all_users[key]['mention_name'] is mention_name)
      for key in users_keys
        if mention_name is all_users[key]['mention_name']
          if key in @users
            return "User @#{mention_name} already added to pp users list"
          else
            @users.push key
            return "User @#{mention_name} was added to pp users list"
    else
      "No such user with mention name '@#{mention_name}'"

  removeUser: (all_users, mention_name) ->
    users_keys = _.keys(all_users)
    if users_keys.some((key) -> all_users[key]['mention_name'] == mention_name)
      for key in users_keys
        if mention_name is all_users[key]['mention_name'] and key in @users
          result = true
          index = @users.indexOf(key)
          @users.splice(index, 1)
          return "User @#{mention_name} was removed from pp users list"
    unless result
      "No such user with mention name '@#{mention_name}'"

  getUsers: (all_users) ->
    if @users.length is 0
      'pp users list are clear'
    else
      users_list = []
      for user_id in @users
        users_list.push '\n' + all_users[user_id]['mention_name']
      users_list

  getPairs: (all_users) ->

    if @pairs.length is 0
      'Not found records at this period'
    else
      pairs_list = []
      for pair in @pairs
        pairs_list.push '\n' + "Date: #{pair[0]}. Pair: @#{all_users[pair[1]]['mention_name']} and @#{all_users[pair[2]]['mention_name']}"
      pairs_list

  checkTodayPairPresent: ->
    today_date = moment().format("MM-DD-YYYY")
    if @pairs.some((record) -> today_date in record)
      for pair in @pairs
        if today_date == pair[0]
          return true
    false

  todayPairMessage: (all_users, today_pair) ->
    "Today pair for pp: @#{all_users[today_pair[0]]['mention_name']} and @#{all_users[today_pair[1]]['mention_name']}"

module.exports = (robot) ->
  pp = undefined

  robot.brain.on 'loaded', =>
    pp = new PairProgramming(robot.brain.data)
    robot.brain.setAutoSave true

  robot.respond /pp pairs today$/i, (msg) ->
    if pp.checkTodayPairPresent()
      today_pair = _.last(pp.pairs)
      msg.send pp.todayPairMessage(robot.brain.data.users, _.rest(today_pair))
    else
      msg.send pp.generateTodayPair()

  robot.respond /pp pairs$/i, (msg) ->
    msg.send pp.getPairs(robot.brain.data.users)

  robot.respond /pp users$/i, (msg) ->
    msg.send pp.getUsers(robot.brain.data.users)

  robot.respond /pp add user @((?:\d+)?\w+(?:\d+)?)$/i, (msg) ->
    msg.send pp.addUser(robot.brain.data.users, msg.match[1])

  robot.respond /pp remove user @((?:\d+)?\w+(?:\d+)?)$/i, (msg) ->
    msg.send pp.removeUser(robot.brain.data.users, msg.match[1])
