# encoding: utf-8
$:.unshift "./"
require "sdl"
require "action"

class DrawTicTacToe
  def initialize(q_func)
    # 状態行動価値関数読み込み
    @q_func = q_func

    # フォント初期化
    SDL::TTF.init
    @font = SDL::TTF.open("cinecaption.ttf", 80)
    @mfont = SDL::TTF.open("cinecaption.ttf", 12)

    # ウインドウを作る
    SDL.init(SDL::INIT_EVERYTHING)
    @screen = SDL::Screen.open(500, 500, 16, SDL::SWSURFACE)
    SDL::WM::set_caption "三目並べ", "三目並べ"

    # 色の定義
    format = @screen.format
    @white = format.map_rgb(255, 255, 255)
    @black = format.map_rgb(0, 0, 0)

    # 1マスのサイズ
    @size = 480 / 3.0

    # 状態
    @state = Array.new(9, 0)
    @state[0] = 2

    refresh

    put_cross(0)

    @fin = "continue"

    @screen.flip
  end

  def to_coordinate(pos)
    row = pos / 3
    col = pos % 3
    [10 + @size * col + @size / 2.0, 10 + @size * row + @size / 2.0]
  end

  def put_circle(pos)
    c = to_coordinate(pos)
    @screen.draw_aa_circle(c[0], c[1], @size / 2.3, @black)
    @screen.flip
  end

  def put_cross(pos)
    c = to_coordinate(pos)
    padding = 20.0
    start0 = [c[0] - @size / 2.0 + padding, c[1] - @size / 2.0 + padding]
    end0 = [c[0] + @size / 2.0 - padding, c[1] + @size / 2.0 - padding]
    @screen.draw_aa_line(start0[0], start0[1], end0[0], end0[1], @black)
    start1 = [c[0] + @size / 2.0 - padding, c[1] - @size / 2.0 + padding]
    end1 = [c[0] - @size / 2.0 + padding, c[1] + @size / 2.0 - padding]
    @screen.draw_aa_line(start1[0], start1[1], end1[0], end1[1], @black)
    @screen.flip
  end

  def refresh
    # 外枠を描画
    @screen.draw_rect(0, 0, 500, 500, @white, true)
    @screen.draw_rect(10, 10, 480, 480, @black)

    # マスを描画
    (0..2).each do |i|
      (0..2).each do |j|
        @screen.draw_rect(10 + @size * i, 10 + @size * j, @size, @size, @black)
      end
    end
    @state.each_with_index do |s, i|
      case s
      when 1
        put_circle(i)
      when 2
        put_cross(i)
      end
    end
    @screen.flip
  end

  def loop
    while true
      while event = SDL::Event.poll
        case event
        when SDL::Event::KeyDown, SDL::Event::Quit
          key = event.sym
          exit if key == 113 || key == 27

          # ユーザが打った
        when SDL::Event::MouseButtonDown
          if not @fin == "continue"
            exit
          end

          _state = []

          # 位置
          x, y = event.x - 10, event.y - 10
          x = x.to_i / @size.to_i
          y = y.to_i / @size.to_i
          pos = x + 3 * y

          # ゲーム継続中でそこが空きなら
          if @state[pos] == 0 && @fin == "continue"
            # ユーザが打つ
            @state[pos] = 1
            put_circle(pos)
            finish # => 終了確認

            # エージェントが打つ
            state = encode(@state) # => 状態を圧縮
            _state = @q_func.row(state).to_a # => 価値表示用

            # 相手がリーチなら防ぐ
            @q_func.row(state)

            a_reach = agent_reach(NVector.to_na(@state))
            p_reach = player_reach(NVector.to_na(@state))
            if a_reach != false
              @state[a_reach] = 2
              put_cross(a_reach)
              finish
            elsif p_reach != false
              @state[p_reach] = 2
              put_cross(p_reach)
              finish
            else
              # それ以外は価値最大のところに打つ
              @q_func.row(state).sort_index.to_a.reverse.each do |a|
                if @state[a] == 0
                  @state[a] = 2
                  put_cross(a)
                  finish
                  break
                end
              end
            end
          end

          # 状態行動価値を表示
          if @fin == "continue"
            refresh
            _state.each_with_index do |s, i|
              x, y = to_coordinate(i)
              draw_text(sprintf("%.2f", s), x, y, @mfont)
            end
          end
        end
      end

      sleep 0.2
    end
  end

  def draw_text(text, cx = 250, cy = 250, font = @font)
    w, h = font.text_size(text)
    font.draw_shaded_utf8(@screen,
                          text,
                          cx - w / 2, cy - h / 2,
                          0, 0, 0,
                          255, 255, 255)
    @screen.flip
  end

  def finish
    @fin = check(@state)

    # ゲーム終了なら
    case @fin
    when "lose"
      draw_text("win!")
    when "win"
      draw_text("lose...")
    when "draw"
      draw_text("draw")
    end
  end
end

q_func = NMatrix.ref NArray.load("q_func.csv", ",")

drawer = DrawTicTacToe.new(q_func)
drawer.loop
