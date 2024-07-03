require 'curses'

class PingPongGame
  PADDLE_HEIGHT = 5
  PADDLE_CHAR = '|'
  BALL_CHAR = 'O'
  SCORE_POSITION = 1
  SCREEN_TIMEOUT = 30

  def initialize
    @screen = Curses.init_screen
    Curses.start_color
    Curses.curs_set(0)
    Curses.noecho
    Curses.cbreak
    @screen.keypad(true)
    Curses.timeout = SCREEN_TIMEOUT

    init_colors

    @left_paddle = { y: @screen.maxy / 2, x: 1, score: 0 }
    @right_paddle = { y: @screen.maxy / 2, x: @screen.maxx - 2, score: 0 }
    @ball = { y: @screen.maxy / 2, x: @screen.maxx / 2, direction: [1, 1] }
  end

  def init_colors
    Curses.init_pair(1, Curses::COLOR_WHITE, Curses::COLOR_BLACK)
    Curses.init_pair(2, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)
    Curses.init_pair(3, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
    Curses.init_pair(4, Curses::COLOR_RED, Curses::COLOR_BLACK)
  end

  def play
    loop do
      handle_input
      move_ball
      check_collisions
      draw
    end
  ensure
    Curses.close_screen
  end

  def handle_input
    case @screen.getch
    when 'w'
      @left_paddle[:y] -= 1 if @left_paddle[:y] > 0
    when 's'
      @left_paddle[:y] += 1 if @left_paddle[:y] < @screen.maxy - PADDLE_HEIGHT
    when Curses::Key::UP
      @right_paddle[:y] -= 1 if @right_paddle[:y] > 0
    when Curses::Key::DOWN
      @right_paddle[:y] += 1 if @right_paddle[:y] < @screen.maxy - PADDLE_HEIGHT
    when 'q'
      exit
    end
  end

  def move_ball
    @ball[:y] += @ball[:direction][0]
    @ball[:x] += @ball[:direction][1]
  end

  def check_collisions
    # Ball collision with top and bottom
    if @ball[:y] <= 0 || @ball[:y] >= @screen.maxy - 1
      @ball[:direction][0] = -@ball[:direction][0]
    end

    # Ball collision with paddles
    if @ball[:x] == @left_paddle[:x] + 1 && (@left_paddle[:y]..@left_paddle[:y] + PADDLE_HEIGHT).include?(@ball[:y])
      @ball[:direction][1] = -@ball[:direction][1]
    elsif @ball[:x] == @right_paddle[:x] - 1 && (@right_paddle[:y]..@right_paddle[:y] + PADDLE_HEIGHT).include?(@ball[:y])
      @ball[:direction][1] = -@ball[:direction][1]
    end

    # Ball out of bounds
    if @ball[:x] <= 0
      @right_paddle[:score] += 1
      reset_ball
    elsif @ball[:x] >= @screen.maxx - 1
      @left_paddle[:score] += 1
      reset_ball
    end
  end

  def reset_ball
    @ball[:y] = @screen.maxy / 2
    @ball[:x] = @screen.maxx / 2
    @ball[:direction] = [1, 1].map { |d| [1, -1].sample }
  end

  def draw
    @screen.clear

    # Draw paddles
    Curses.attron(Curses.color_pair(2))
    PADDLE_HEIGHT.times do |i|
      @screen.setpos(@left_paddle[:y] + i, @left_paddle[:x])
      @screen.addch(PADDLE_CHAR)
      @screen.setpos(@right_paddle[:y] + i, @right_paddle[:x])
      @screen.addch(PADDLE_CHAR)
    end
    Curses.attroff(Curses.color_pair(2))

    # Draw ball
    Curses.attron(Curses.color_pair(3))
    @screen.setpos(@ball[:y], @ball[:x])
    @screen.addch(BALL_CHAR)
    Curses.attroff(Curses.color_pair(3))

    # Draw scores
    @screen.setpos(SCORE_POSITION, 2)
    @screen.addstr("Player 1: #{@left_paddle[:score]}")
    @screen.setpos(SCORE_POSITION, @screen.maxx - 15)
    @screen.addstr("Player 2: #{@right_paddle[:score]}")

    @screen.refresh
  end
end

PingPongGame.new.play
