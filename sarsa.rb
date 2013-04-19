# encoding: utf-8

$:.unshift "./"
require "narrays"
require "action"
require "gnuplot"

puts "Ruby #{RUBY_VERSION}"

def sarsa_policy_iteration(iter_limit, episode, options)
  state_num  = 3**9 # 状態数
  action_num = 9    # 行動数
  max_step   = 5    # 最大ステップ数（9マスしかないのでCOMが必ず先手として最大5手まで）
  @rate       = []

  iter_limit.times do |l|
    results = NVector.float(episode)

  end

end
