# encoding: utf-8

$:.unshift "./"
require "encode"
require "narrays"
require "action"
require "gnuplot"

puts "Ruby #{RUBY_VERSION}"

def monte_carlo_iteration(iter_limit, episode, options)
  state_num  = 3**9 # 状態数
  action_num = 9    # 行動数
  max_step   = 5    # 最大ステップ数（9マスしかないのでCOMが必ず先手として最大5手まで）
  @rate       = []

  # 状態行動価値関数の初期化
  q_func = NMatrix.float(action_num, state_num).fill(0.0)

  # 政策反復
  iter_limit.times do |l|
    visits  = NMatrix.int(action_num, state_num).fill(1)  # => (s,a)の出現回数
    results = Array.new(episode)                          # => ゲームの結果
    states  = episode.times.inject([]){|a, i| a << []}    # => 状態遷移記録
    actions = episode.times.inject([]){|a, i| a << []}    # => 行動記録
    rewards = episode.times.inject([]){|a, i| a << []}    # => 報酬記録
    returns = episode.times.inject([]){|a, i| a << []}    # => 収益

    # エピソード
    episode.times do |e|
      # 状態の初期化
      state_base_3 = NVector.int(9)

      # ステップ
      max_step.times do |t|
        state  = encode state_base_3        # => 状態の初期化
        policy = NVector.float(action_num)  # => 政策の初期化

        # 政策改善
        case options["pmode"]
        when "greedy"
          q_vec     = q_func.row(state)
          a         = q_vec.sort_index[-1]
          v         = q_vec[a]
          policy[a] = 1
        when "e-greedy"
          q_vec     = q_func.row(state)
          a         = q_vec.sort_index[-1]
          v         = q_vec[a]
          epsilon   = options["epsilon"]
          ones      = NVector.float(action_num).fill(1.0)
          policy    = ones * epsilon / action_num.to_f
          policy[a] = 1 - epsilon + epsilon / action_num.to_f
        when "softmax"
          tau    = options["tau"]
          q_vec  = q_func.row(state)
          policy = (q_vec / tau).in_exp / (q_vec / tau).in_exp.sum
        end

        # 行動して報酬を得る
        action, reward, state_base_3, fin = action_train(policy, t, state_base_3)

        # print sprintf("state:\t%5d\t\taction:\t%d\t\treward:\t%2d\t\tfin:\t%s\n", state, action, reward, fin)

        # 状態・行動・報酬・出現回数の更新
        states[e] << state
        actions[e] << action
        rewards[e] << reward
        visits[action, state] += 1

        # ゲーム終了ならエピソードを終える
        if not fin == "continue"
          results[e] = fin

          # 現在のエピソードで得られた収益の計算
          gamma = options["gamma"] # => 割引率
          returns[e] = rewards[e]
          (rewards[e].size - 1).times do |i|
            pos = rewards[e].size - 2 - i # => 後ろから順に
            returns[e][pos] = gamma * returns[e][pos + 1]
          end
          break # => エピソードを終える
        end
      end
    end

    # 全エピソードを終えたら価値関数を更新
    q_func = NMatrix.float(action_num, state_num).fill(0.0)
    episode.times do |e|
      states[e].size.times do |i|
        # エピソードeのステップiで現れた状態行動対
        s = states[e][i]
        a = actions[e][i]

        # 状態が0=初期状態
        if s == 0
          next
        end

        # 状態行動価値Q(s,a)の更新
        q_func[a, s] = q_func[a, s] + returns[e][i]
      end
    end
    q_func.divide(visits)

    win_num = 0
    results.each do |r|
      if r == "win"
        win_num += 1
      end
    end
    @rate << win_num / results.size.to_f
  end

  q_func.save("q_func.csv", ",")
end

iter_limit = 10
episode = 1000
monte_carlo_iteration(iter_limit, episode, {"pmode" => "e-greedy", "epsilon" => 0.1, "gamma" => 0.9})

def draw_chart(x, y)
  Gnuplot.open do |gp|
    Gnuplot::Plot.new(gp) do |plot|
      y.each do |name, value|
        if x.size == value.size
          plot.data << Gnuplot::DataSet.new([x, value]) do |ds|
            ds.with = "lines"
            ds.title = name
          end
        end
      end
    end
  end
end

draw_chart((0..@rate.size - 1).to_a, {"correct rate" => @rate})
