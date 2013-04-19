# encoding: utf-8
$:.unshift "./"
require "narrays"

# 状態圧縮
def encode(state_base_3)
  convert = [[0, 1, 2, 3, 4, 5, 6, 7, 8],
             [2, 1, 0, 5, 4, 3, 8, 7, 6],
             [6, 3, 0, 7, 4, 1, 8, 5, 2],
             [0, 3, 6, 1, 4, 7, 2, 5, 8],
             [8, 7, 6, 5, 4, 3, 2, 1, 0],
             [6, 7, 8, 3, 4, 5, 0, 1, 2],
             [2, 5, 8, 1, 4, 7, 0, 3, 6],
             [8, 5, 2, 7, 4, 1, 6, 3, 0]]

  power = (0..8).inject([]){|a, i| a << 3**i}.reverse
  power = NVector.to_na(power)

  if not state_base_3.instance_of?(NVector)
    state_base_3 = NVector.to_na(state_base_3)
  end

  cands = []
  convert.each do |c|
    perm = state_base_3[c]
    cands << power * NVector.to_na(perm)
  end
  cands.min
end

# 勝敗をチェック
def check(state)
  pos = [[0, 1, 2],
         [3, 4, 5],
         [6, 7, 8],
         [0, 3, 6],
         [1, 4, 7],
         [2, 5, 8],
         [0, 4, 8],
         [2, 4, 6]]

  # ゲーム続行
  fin = "continue"

  pos.size.times do |i|
    val = pos[i].inject(1.0){|s, i| s *= state[i]}

    # エージェントの負け
    if val == 1
      return "lose"

      # エージェントの勝ち
    elsif val == 8
      return "win"
    end
  end

  # 引き分け（全部埋まった）
  if not state.to_a.inject(1.0){|s, i| s *= i} == 0
    return "draw"
  end

  fin
end

# プレイヤーがリーチかどうか
def player_reach(state_base_3)
  reach = false
  pos = [[0, 1, 2],
         [3, 4, 5],
         [6, 7, 8],
         [0, 3, 6],
         [1, 4, 7],
         [2, 5, 8],
         [0, 4, 8],
         [2, 4, 6]]

  pos.size.times do |i|
    val = pos[i].inject(0){|s, n| s += state_base_3[n]}
    num = pos[i].inject(0){|s, n| s += 1 if state_base_3[n] == 0; s}

    # リーチなら
    if val == 2 && num == 1
      reach = pos[i][state_base_3[pos[i]].to_a.index(0)]
      break
    end
  end
  reach
end

def agent_reach(state_base_3)
  reach = false
  pos = [[0, 1, 2],
         [3, 4, 5],
         [6, 7, 8],
         [0, 3, 6],
         [1, 4, 7],
         [2, 5, 8],
         [0, 4, 8],
         [2, 4, 6]]

  pos.size.times do |i|
    val = pos[i].inject(0){|s, n| s += state_base_3[n]}
    num = pos[i].inject(0){|s, n| s += 1 if state_base_3[n] == 0; s}

    # リーチなら
    if val == 4 && num == 1
      reach = pos[i][state_base_3[pos[i]].to_a.index(0)]
      break
    end
  end
  reach
end

def action_train(policy, state_base_3)
  reward = 0.0

  # 学習プレイヤ
  a = nil
  while true
    random = rand

    # 各マスの選択確率によって手を決める
    cprob = 0.0
    (0..8).each do |cell|
      a = cell
      cprob += policy[a]
      if(random < cprob)
        break
      end
    end

    # 既にマスが埋まっていたら飛ばす
    if state_base_3[a] == 0
      break
    end
  end

  action = a
  state_base_3[a] = 2 # マスに☓を置く
  fin = check(state_base_3)

  # 勝ったら報酬10
  if fin == "win"
    reward = 10
    return [action, reward, state_base_3, fin]

    # 引き分けなら報酬0
  elsif fin == "draw"
    reward = 0
    return [action, reward, state_base_3, fin]
  end

  # 学習用対戦相手
  reach = false
  pos = [[0, 1, 2],
         [3, 4, 5],
         [6, 7, 8],
         [0, 3, 6],
         [1, 4, 7],
         [2, 5, 8],
         [0, 4, 8],
         [2, 4, 6]]

  pos.size.times do |i|
    val = pos[i].inject(0){|s, n| s += state_base_3[n]}
    num = pos[i].inject(0){|s, n| s += 1 if state_base_3[n] == 0; s}

    # リーチなら
    if val == 2 && num == 1
      a = pos[i][state_base_3[pos[i]].to_a.index(0)]
      reach = true
      break
    end
  end

  # リーチじゃないなら
  if not reach
    # 空いてるマスをランダムに選ぶ
    while true
      a = rand(0..8)
      if state_base_3[a] == 0
        break
      end
    end
  end

  # 対戦相手の手
  state_base_3[a] = 1

  # 勝敗をチェック
  fin = check(state_base_3)

  # 負けたら報酬-10
  if fin == "lose"
    reward = -10
    return [action, reward, state_base_3, fin]

    # 引き分けなら報酬0
  elsif fin == "draw"
    reward = 0
    return [action, reward, state_base_3, fin]
  end

  return [action, reward, state_base_3, fin]
end
